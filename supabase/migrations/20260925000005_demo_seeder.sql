-- Brain Reporting DEMO — deterministic data generator.
--
-- Everything lives in the `demo` schema, which PostgREST does not expose, so
-- none of it is reachable from the browser. Business templates are rows in
-- demo.templates (see the next migration); `select demo.seed('2026-08-01')`
-- wipes the demo agency's clients and regenerates a full month for each one.
--
-- Randomness is the classic LCG  seed = (seed * 9301 + 49297) % 233280,
-- re-seeded per client from its template, so every run produces identical
-- numbers. Consistency rules:
--   * google: campaign-day is generated per device; ad groups, asset groups,
--     keywords and search terms are integer/money splits of the campaign-day
--     totals (search terms cover ~80% of keyword traffic, like the real report)
--   * meta: campaign-day totals are split into ad sets, ad sets into ads, and
--     the campaign-day into placements
--   * GA4 paid rows are derived from the same clicks/conversions with a
--     per-template attribution ratio (GA4 usually sees less than the platform)

create schema if not exists demo;
revoke all on schema demo from public, anon, authenticated;

create table if not exists demo.templates (
  slug text primary key,
  sort_order int not null,
  config jsonb not null
);

-- ------------------------------------------------------------------ randomness
create or replace function demo.rand() returns float8
language plpgsql volatile as $$
declare
  s bigint := current_setting('demo.seed')::bigint;
begin
  s := (s * 9301 + 49297) % 233280;
  perform set_config('demo.seed', s::text, true);
  return s / 233280.0;
end;
$$;

-- 1 ± amp, uniformly
create or replace function demo.noise(amp float8) returns float8
language plpgsql volatile as $$
begin
  return 1 + (demo.rand() * 2 - 1) * amp;
end;
$$;

-- Stochastic rounding: 2.3 becomes 3 with probability 0.3, so small daily
-- conversion counts still add up to the right monthly total.
create or replace function demo.sround(x float8) returns bigint
language plpgsql volatile as $$
begin
  if x <= 0 then return 0; end if;
  return floor(x + demo.rand())::bigint;
end;
$$;

-- ------------------------------------------------------------------ array helpers
-- Column idx (0-based) of a jsonb array of arrays, as float8[].
create or replace function demo.col(arr jsonb, idx int, dflt float8 default 1) returns float8[]
language sql immutable as $$
  select coalesce(array_agg(coalesce((e->>idx)::float8, dflt) order by o), '{}')
  from jsonb_array_elements(coalesce(arr, '[]'::jsonb)) with ordinality t(e, o)
$$;

create or replace function demo.mul(a float8[], b float8[]) returns float8[]
language sql immutable as $$
  select coalesce(array_agg(x * coalesce(b[o], 1) order by o), '{}')
  from unnest(a) with ordinality t(x, o)
$$;

-- Multiply each weight by 1 ± amp and normalise to sum 1.
create or replace function demo.jitter(w float8[], amp float8) returns float8[]
language plpgsql volatile as $$
declare
  r float8[] := '{}';
  s float8 := 0;
  n int := coalesce(array_length(w, 1), 0);
  i int;
begin
  for i in 1..n loop
    r[i] := greatest(w[i], 0) * demo.noise(amp);
    s := s + r[i];
  end loop;
  if s > 0 then
    for i in 1..n loop r[i] := r[i] / s; end loop;
  end if;
  return r;
end;
$$;

-- Split an integer total by weights; floors first, remainder handed out by weighted draw.
create or replace function demo.split_int(total bigint, w float8[]) returns bigint[]
language plpgsql volatile as $$
declare
  n int := coalesce(array_length(w, 1), 0);
  r bigint[] := '{}';
  sw float8 := 0;
  s bigint := 0;
  rem bigint;
  x float8;
  acc float8;
  i int;
  j int;
begin
  if n = 0 then return r; end if;
  for i in 1..n loop sw := sw + greatest(w[i], 0); end loop;
  for i in 1..n loop
    r[i] := case when sw > 0 then floor(total * greatest(w[i], 0) / sw) else 0 end;
    s := s + r[i];
  end loop;
  rem := total - s;
  if sw = 0 then
    r[n] := r[n] + rem;
    return r;
  end if;
  while rem > 0 loop
    x := demo.rand() * sw;
    j := 1;
    acc := greatest(w[1], 0);
    while x >= acc and j < n loop
      j := j + 1;
      acc := acc + greatest(w[j], 0);
    end loop;
    r[j] := r[j] + 1;
    rem := rem - 1;
  end loop;
  return r;
end;
$$;

-- Split money by weights to the cent; the last bucket takes the rounding remainder.
create or replace function demo.split_money(total numeric, w float8[]) returns numeric[]
language plpgsql immutable as $$
declare
  n int := coalesce(array_length(w, 1), 0);
  r numeric[] := '{}';
  sw float8 := 0;
  s numeric := 0;
  i int;
begin
  if n = 0 then return r; end if;
  for i in 1..n loop sw := sw + greatest(w[i], 0); end loop;
  for i in 1..n - 1 loop
    r[i] := case when sw > 0 then round(total * (greatest(w[i], 0) / sw)::numeric, 2) else 0 end;
    s := s + r[i];
  end loop;
  r[n] := greatest(total - s, 0);
  return r;
end;
$$;

-- Value follows conversions: bucket i gets total * conv_i / sum(conv).
create or replace function demo.split_value(total numeric, conv bigint[]) returns numeric[]
language plpgsql immutable as $$
declare
  n int := coalesce(array_length(conv, 1), 0);
  r numeric[] := '{}';
  sc bigint := 0;
  s numeric := 0;
  last_nonzero int := 0;
  i int;
begin
  for i in 1..n loop
    sc := sc + conv[i];
    r[i] := 0;
    if conv[i] > 0 then last_nonzero := i; end if;
  end loop;
  if sc = 0 or total = 0 then return r; end if;
  for i in 1..n loop
    if i <> last_nonzero then
      r[i] := round(total * conv[i] / sc, 2);
      s := s + r[i];
    end if;
  end loop;
  r[last_nonzero] := greatest(total - s, 0);
  return r;
end;
$$;

-- ------------------------------------------------------------------ GA4 paid row
create or replace function demo.ga4_paid_row(
  p_client uuid, p_ds uuid, p_date date, p_source text, p_medium text, p_campaign text,
  p_clicks bigint, p_conv bigint, p_value numeric,
  p_spc float8, p_ratio float8, p_bounce float8, p_new_share float8
) returns void
language plpgsql volatile set search_path = public as $$
declare
  s bigint;
  u bigint;
  b float8;
  e bigint;
begin
  s := round(p_clicks * p_spc * demo.noise(0.08));
  if s <= 0 then return; end if;
  u := greatest(1, round(s * 0.87));
  b := least(0.95, greatest(0.05, p_bounce * demo.noise(0.08)));
  e := round(s * (1 - b));
  insert into ga4_metrics (client_id, data_source_id, report_date, source, medium, campaign, sessions, total_users, new_users,
    engaged_sessions, engagement_rate, bounce_rate, conversions, total_revenue)
  values (p_client, p_ds, p_date, p_source, p_medium, p_campaign, s, u, round(u * p_new_share), e,
    round((e::numeric / s), 4), round(b::numeric, 4),
    demo.sround(p_conv * p_ratio * demo.noise(0.12)),
    round((p_value * (p_ratio * demo.noise(0.1))::numeric), 2));
end;
$$;

-- ------------------------------------------------------------------ Google Ads
create or replace function demo.gen_google(
  p_client uuid, p_ds uuid, p_ds_ga4 uuid, cfg jsonb, p_month date, dayf float8[], cvrf float8[]
) returns void
language plpgsql volatile set search_path = public as $$
declare
  n int := array_length(dayf, 1);
  ga4 jsonb := coalesce(cfg->'ga4', '{}'::jsonb);
  c jsonb;
  i int; k int; m int; q int;
  d date;
  ctype text; cname text;
  budget float8; cpc float8; ctr float8; cvr float8; val float8; freq float8; vrate float8; is_base float8;
  act_from int; act_to int; zero boolean; ctrend float8;
  devs jsonb; dw float8[]; dn int;
  spend_day float8; sp numeric; im bigint; cl bigint; cv bigint; vl numeric; vv bigint; uu bigint; cpm float8; isv float8;
  t_sp numeric; t_im bigint; t_cl bigint; t_cv bigint; t_vl numeric; t_uu bigint;
  gw float8[]; gm float8[]; g_im bigint[]; g_cl bigint[]; g_cv bigint[]; g_sp numeric[]; g_vl numeric[]; g_uu bigint[];
  groups jsonb; gtable text;
  kws jsonb; terms jsonb; kw_im bigint[]; kw_cl bigint[]; kw_cv bigint[]; kw_sp numeric[]; kw_vl numeric[];
  tw float8[]; tm float8[]; tidx int[]; t_names text[]; tt_im bigint[]; tt_cl bigint[]; tt_cv bigint[]; tt_sp numeric[];
  comp jsonb;
  spc float8;
begin
  for c in select e from jsonb_array_elements(coalesce(cfg->'google', '[]'::jsonb)) with ordinality t(e, o) order by o loop
    cname := c->>'name';
    ctype := c->>'type';
    budget := (c->>'budget')::float8;
    cpc := (c->>'cpc')::float8;
    ctr := (c->>'ctr')::float8;
    cvr := coalesce((c->>'cvr')::float8, 0);
    val := coalesce((c->>'value')::float8, 0);
    freq := coalesce((c->>'freq')::float8, 2.6);
    vrate := coalesce((c->>'view_rate')::float8, 0);
    is_base := coalesce((c->>'is')::float8, 0.6);
    act_from := coalesce((c->>'from')::int, 1);
    act_to := coalesce((c->>'to')::int, n);
    zero := coalesce((c->>'zero_conv')::boolean, false);
    ctrend := coalesce((c->>'trend')::float8, 0);
    spc := coalesce((c->>'ga4_spc')::float8, case ctype
      when 'SEARCH' then 0.9 when 'PERFORMANCE_MAX' then 0.78 when 'DISPLAY' then 0.62
      when 'DEMAND_GEN' then 0.66 when 'VIDEO' then 0.55 when 'MULTI_CHANNEL' then 0.3 else 0.7 end);

    -- [device, share, cpm multiplier, ctr multiplier, cvr multiplier]
    devs := coalesce(c->'devices', case ctype
      when 'SEARCH' then '[["MOBILE",0.56,0.92,1.0,0.85],["DESKTOP",0.36,1.12,1.05,1.3],["TABLET",0.08,0.85,0.9,0.9]]'
      when 'VIDEO' then '[["MOBILE",0.58,1.0,1.0,1.0],["CONNECTED_TV",0.22,1.35,0.15,0.3],["DESKTOP",0.13,1.1,1.2,1.2],["TABLET",0.07,0.9,1.0,1.0]]'
      when 'MULTI_CHANNEL' then '[["MOBILE",0.94,1.0,1.0,1.0],["TABLET",0.06,0.85,0.9,0.8]]'
      else '[["MOBILE",0.68,0.95,1.0,0.9],["DESKTOP",0.24,1.1,1.1,1.3],["TABLET",0.08,0.9,0.95,0.9]]'
    end::jsonb);
    dn := jsonb_array_length(devs);

    groups := coalesce(c->'ad_groups', c->'asset_groups');
    gtable := case when c ? 'asset_groups' then 'asset' else 'ad' end;
    kws := c->'keywords';
    terms := c->'terms';
    comp := c->'competitors';

    for i in 1..n loop
      d := p_month + (i - 1);
      if i < act_from or i > act_to then continue; end if;

      spend_day := budget * dayf[i] * (1 + ctrend * ((i - 1)::float8 / greatest(n - 1, 1) - 0.5)) * demo.noise(0.1);
      dw := demo.jitter(demo.col(devs, 1), 0.08);
      t_sp := 0; t_im := 0; t_cl := 0; t_cv := 0; t_vl := 0; t_uu := 0;

      for k in 1..dn loop
        sp := round((spend_day * dw[k])::numeric, 2);
        if sp <= 0 then continue; end if;
        cpm := cpc * ctr * 1000 * (devs->(k - 1)->>2)::float8 * demo.noise(0.06);
        im := greatest(1, round(sp / cpm::numeric * 1000));
        cl := demo.sround(im * ctr * (devs->(k - 1)->>3)::float8 * demo.noise(0.08));
        cv := case when zero then 0 else demo.sround(cl * cvr * (devs->(k - 1)->>4)::float8 * cvrf[i] * demo.noise(0.15)) end;
        vl := round((cv * val * demo.noise(0.12))::numeric, 2);
        vv := round(im * vrate * demo.noise(0.08));
        uu := round(im / (freq * demo.noise(0.05)));
        isv := case when ctype = 'SEARCH' then least(0.97, is_base * demo.noise(0.05) / greatest(dayf[i], 1) ^ 0.5) end;

        insert into google_ads_metrics (client_id, data_source_id, report_date, campaign, campaign_type, device,
          impressions, clicks, spend, conversions, conversion_value,
          search_impression_share, search_lost_is_budget, search_lost_is_rank, unique_users, video_views)
        values (p_client, p_ds, d, cname, ctype, devs->(k - 1)->>0, im, cl, sp, cv, vl,
          round(isv::numeric, 4),
          case when isv is not null then round(((1 - isv) * coalesce((c->>'lost_budget_share')::float8, 0.4))::numeric, 4) end,
          case when isv is not null then round(((1 - isv) * (1 - coalesce((c->>'lost_budget_share')::float8, 0.4)))::numeric, 4) end,
          uu, vv);

        t_sp := t_sp + sp; t_im := t_im + im; t_cl := t_cl + cl; t_cv := t_cv + cv; t_vl := t_vl + vl; t_uu := t_uu + uu;
      end loop;

      -- Dashboard / agency report feed
      insert into report_metrics (client_id, data_source_id, report_date, channel, campaign, metric_name, metric_value) values
        (p_client, p_ds, d, 'google', cname, 'spend', t_sp),
        (p_client, p_ds, d, 'google', cname, 'clicks', t_cl),
        (p_client, p_ds, d, 'google', cname, 'impressions', t_im);

      -- GA4 sees the paid click as google / cpc with utm_campaign = campaign name
      perform demo.ga4_paid_row(p_client, p_ds_ga4, d, 'google', 'cpc', cname, t_cl, t_cv, t_vl, spc,
        coalesce((ga4->>'google_ratio')::float8, 0.85),
        coalesce((c->>'ga4_bounce')::float8, (ga4->>'google_bounce')::float8, 0.35),
        coalesce((ga4->>'new_share')::float8, 0.6));

      -- ad groups / asset groups: [name, weight, cvr multiplier]
      if groups is not null then
        gw := demo.jitter(demo.col(groups, 1), 0.15);
        gm := demo.mul(gw, demo.col(groups, 2));
        g_im := demo.split_int(t_im, gw);
        g_cl := demo.split_int(t_cl, gw);
        g_cv := demo.split_int(t_cv, gm);
        g_sp := demo.split_money(t_sp, gw);
        g_vl := demo.split_value(t_vl, g_cv);
        g_uu := demo.split_int(t_uu, gw);
        for m in 1..jsonb_array_length(groups) loop
          if gtable = 'asset' then
            insert into google_asset_group_metrics (client_id, data_source_id, report_date, campaign, asset_group_name,
              impressions, clicks, spend, conversions, conversion_value, unique_users)
            values (p_client, p_ds, d, cname, groups->(m - 1)->>0, g_im[m], g_cl[m], g_sp[m], g_cv[m], g_vl[m], g_uu[m]);
          else
            insert into google_ad_group_metrics (client_id, data_source_id, report_date, campaign, ad_group_name,
              impressions, clicks, spend, conversions, conversion_value, unique_users)
            values (p_client, p_ds, d, cname, groups->(m - 1)->>0, g_im[m], g_cl[m], g_sp[m], g_cv[m], g_vl[m], g_uu[m]);
          end if;
        end loop;
      end if;

      -- keywords: [text, match type, quality score, weight, cvr multiplier]
      if kws is not null then
        gw := demo.jitter(demo.col(kws, 3), 0.15);
        gm := demo.mul(gw, demo.col(kws, 4));
        kw_im := demo.split_int(t_im, gw);
        kw_cl := demo.split_int(t_cl, gw);
        kw_cv := demo.split_int(t_cv, gm);
        kw_sp := demo.split_money(t_sp, gw);
        kw_vl := demo.split_value(t_vl, kw_cv);
        for m in 1..jsonb_array_length(kws) loop
          insert into google_ads_keywords (client_id, data_source_id, report_date, campaign, keyword_text, keyword_match_type,
            impressions, clicks, spend, conversions, conversion_value, quality_score)
          values (p_client, p_ds, d, cname, kws->(m - 1)->>0, kws->(m - 1)->>1,
            kw_im[m], kw_cl[m], kw_sp[m], kw_cv[m], kw_vl[m], (kws->(m - 1)->>2)::numeric);

          -- search terms matched by this keyword: [term, keyword index (1-based), weight, cvr multiplier];
          -- a trailing "long tail" bucket keeps ~20% of traffic out of the visible list
          if terms is not null then
            select coalesce(array_agg(e->>0 order by o), '{}'),
                   coalesce(array_agg(coalesce((e->>2)::float8, 1) order by o), '{}'),
                   coalesce(array_agg(coalesce((e->>3)::float8, 1) order by o), '{}')
              into t_names, tw, tm
              from jsonb_array_elements(terms) with ordinality t(e, o)
              where (e->>1)::int = m;
            q := coalesce(array_length(t_names, 1), 0);
            if q > 0 then
              tw := demo.jitter(tw || 0.25::float8, 0.2);
              tm := demo.mul(tw, tm || 1::float8);
              tt_im := demo.split_int(kw_im[m], tw);
              tt_cl := demo.split_int(kw_cl[m], tw);
              tt_cv := demo.split_int(kw_cv[m], tm);
              tt_sp := demo.split_money(kw_sp[m], tw);
              for k in 1..q loop
                if tt_im[k] > 0 then
                  insert into google_ads_search_terms (client_id, data_source_id, report_date, campaign, search_term,
                    impressions, clicks, spend, conversions)
                  values (p_client, p_ds, d, cname, t_names[k], tt_im[k], tt_cl[k], tt_sp[k], tt_cv[k]);
                end if;
              end loop;
            end if;
          end if;
        end loop;
      end if;

      -- auction insights presence: [domain, daily probability]
      if comp is not null then
        for m in 1..jsonb_array_length(comp) loop
          if demo.rand() < (comp->(m - 1)->>1)::float8 then
            insert into google_ads_competitors (client_id, data_source_id, report_date, campaign, domain)
            values (p_client, p_ds, d, cname, comp->(m - 1)->>0);
          end if;
        end loop;
      end if;
    end loop;
  end loop;
end;
$$;

-- ------------------------------------------------------------------ Meta Ads
create or replace function demo.gen_meta(
  p_client uuid, p_ds uuid, p_ds_ga4 uuid, cfg jsonb, p_month date, dayf float8[], cvrf float8[]
) returns void
language plpgsql volatile set search_path = public as $$
declare
  n int := array_length(dayf, 1);
  ga4 jsonb := coalesce(cfg->'ga4', '{}'::jsonb);
  c jsonb;
  i int; k int; m int; q int;
  d date;
  cname text; obj text;
  budget float8; cpm float8; ctr float8; cvr float8; val float8; freq float8; vrate float8;
  act_from int; act_to int; ctrend float8;
  sp numeric; im bigint; cl bigint; cv bigint; vl numeric; vv bigint; rc bigint; fr float8;
  adsets jsonb; ads jsonb; plc jsonb;
  aw float8[]; am float8[]; a_im bigint[]; a_cl bigint[]; a_cv bigint[]; a_sp numeric[]; a_vl numeric[];
  ad_names text[]; adw float8[]; ad_im bigint[]; ad_cl bigint[]; ad_sp numeric[];
  pw float8[]; p_im bigint[]; p_cl bigint[]; p_sp numeric[];
begin
  for c in select e from jsonb_array_elements(coalesce(cfg->'meta', '[]'::jsonb)) with ordinality t(e, o) order by o loop
    cname := c->>'name';
    obj := c->>'objective';
    budget := (c->>'budget')::float8;
    cpm := (c->>'cpm')::float8;
    ctr := (c->>'ctr')::float8;
    cvr := coalesce((c->>'cvr')::float8, 0);
    val := coalesce((c->>'value')::float8, 0);
    freq := coalesce((c->>'freq')::float8, 1.3);
    vrate := coalesce((c->>'view_rate')::float8, 0);
    act_from := coalesce((c->>'from')::int, 1);
    act_to := coalesce((c->>'to')::int, n);
    ctrend := coalesce((c->>'trend')::float8, 0);
    adsets := c->'adsets';   -- [name, weight, cvr multiplier]
    ads := c->'ads';         -- [name, adset index (1-based), weight]
    -- [publisher_platform, device_platform, impression share, cpm multiplier, ctr multiplier]
    plc := coalesce(c->'placements', cfg->'meta_placements',
      '[["instagram","mobile_app",0.40,1.1,0.9],["facebook","mobile_app",0.30,1.0,1.0],["audience_network","mobile_app",0.10,0.4,1.6],["facebook","desktop",0.08,1.3,1.4],["facebook","mobile_web",0.05,0.9,0.9],["threads","mobile_app",0.04,0.8,0.6],["messenger","mobile_app",0.03,0.7,0.7]]'::jsonb);

    for i in 1..n loop
      d := p_month + (i - 1);
      if i < act_from or i > act_to then continue; end if;

      sp := round((budget * dayf[i] * (1 + ctrend * ((i - 1)::float8 / greatest(n - 1, 1) - 0.5)) * demo.noise(0.1))::numeric, 2);
      im := greatest(1, round(sp / (cpm * demo.noise(0.07))::numeric * 1000));
      cl := demo.sround(im * ctr * demo.noise(0.09));
      fr := freq * demo.noise(0.05);
      rc := greatest(1, round(im / fr));
      cv := demo.sround(cl * cvr * cvrf[i] * demo.noise(0.15));
      vl := round((cv * val * demo.noise(0.12))::numeric, 2);
      vv := round(im * vrate * demo.noise(0.08));

      insert into facebook_ads_metrics (client_id, data_source_id, report_date, campaign, objective,
        impressions, clicks, spend, reach, frequency, conversions, conversion_value, roas, video_views)
      values (p_client, p_ds, d, cname, obj, im, cl, sp, rc, round(im::numeric / rc, 2), cv, vl,
        case when sp > 0 then round(vl / sp, 2) end, vv);

      insert into report_metrics (client_id, data_source_id, report_date, channel, campaign, metric_name, metric_value) values
        (p_client, p_ds, d, 'facebook', cname, 'spend', sp),
        (p_client, p_ds, d, 'facebook', cname, 'clicks', cl),
        (p_client, p_ds, d, 'facebook', cname, 'impressions', im);

      -- ad sets
      aw := demo.jitter(demo.col(adsets, 1), 0.12);
      am := demo.mul(aw, demo.col(adsets, 2));
      a_im := demo.split_int(im, aw);
      a_cl := demo.split_int(cl, aw);
      a_cv := demo.split_int(cv, am);
      a_sp := demo.split_money(sp, aw);
      a_vl := demo.split_value(vl, a_cv);
      for m in 1..jsonb_array_length(adsets) loop
        insert into meta_ad_set_metrics (client_id, data_source_id, report_date, campaign, adset_name,
          impressions, clicks, spend, conversions, conversion_value, reach)
        values (p_client, p_ds, d, cname, adsets->(m - 1)->>0, a_im[m], a_cl[m], a_sp[m], a_cv[m], a_vl[m], round(a_im[m] / fr));

        -- GA4: utm_campaign = <campaign>--<ad set prefix>, which is what the PPC report matches on
        perform demo.ga4_paid_row(p_client, p_ds_ga4, d, 'facebook', 'paid',
          cname || '--' || substring(adsets->(m - 1)->>0 from '^[A-Za-z0-9_]+'),
          a_cl[m], a_cv[m], a_vl[m],
          coalesce((c->>'ga4_spc')::float8, (ga4->>'meta_spc')::float8, 0.72),
          coalesce((ga4->>'meta_ratio')::float8, 0.6),
          coalesce((c->>'ga4_bounce')::float8, (ga4->>'meta_bounce')::float8, 0.5),
          coalesce((ga4->>'new_share')::float8, 0.6));

        -- ads in this ad set
        select coalesce(array_agg(e->>0 order by o), '{}'), coalesce(array_agg(coalesce((e->>2)::float8, 1) order by o), '{}')
          into ad_names, adw
          from jsonb_array_elements(coalesce(ads, '[]'::jsonb)) with ordinality t(e, o)
          where (e->>1)::int = m;
        q := coalesce(array_length(ad_names, 1), 0);
        if q > 0 then
          adw := demo.jitter(adw, 0.2);
          ad_im := demo.split_int(a_im[m], adw);
          ad_cl := demo.split_int(a_cl[m], adw);
          ad_sp := demo.split_money(a_sp[m], adw);
          for k in 1..q loop
            insert into facebook_ads_creatives (client_id, data_source_id, report_date, campaign, adset_name, ad_name,
              impressions, clicks, spend)
            values (p_client, p_ds, d, cname, adsets->(m - 1)->>0, ad_names[k], ad_im[k], ad_cl[k], ad_sp[k]);
          end loop;
        end if;
      end loop;

      -- placements
      pw := demo.jitter(demo.col(plc, 2), 0.08);
      p_im := demo.split_int(im, pw);
      p_sp := demo.split_money(sp, demo.mul(pw, demo.col(plc, 3)));
      p_cl := demo.split_int(cl, demo.mul(pw, demo.col(plc, 4)));
      for m in 1..jsonb_array_length(plc) loop
        insert into facebook_ads_placements (client_id, data_source_id, report_date, campaign, publisher_platform, device_platform,
          impressions, clicks, spend, reach)
        values (p_client, p_ds, d, cname, plc->(m - 1)->>0, plc->(m - 1)->>1, p_im[m], p_cl[m], p_sp[m], round(p_im[m] / fr));
      end loop;
    end loop;
  end loop;
end;
$$;

-- ------------------------------------------------------------------ GA4 organic + owned channels
create or replace function demo.gen_ga4_other(
  p_client uuid, p_ds uuid, cfg jsonb, p_month date, trf float8[], cvrf float8[]
) returns void
language plpgsql volatile set search_path = public as $$
declare
  n int := array_length(trf, 1);
  ga4 jsonb := coalesce(cfg->'ga4', '{}'::jsonb);
  src jsonb;
  i int; k int;
  d date;
  s bigint; u bigint; e bigint; cv bigint; b float8; ns float8;
begin
  -- organic / direct / referral: {source, medium, campaign, sessions, cvr, aov, bounce, new_share}
  for i in 1..n loop
    d := p_month + (i - 1);
    for src in select x from jsonb_array_elements(coalesce(ga4->'organic', '[]'::jsonb)) with ordinality t(x, o) order by o loop
      s := round((src->>'sessions')::float8 * trf[i] * demo.noise(0.1));
      if s <= 0 then continue; end if;
      ns := coalesce((src->>'new_share')::float8, 0.5);
      u := greatest(1, round(s * 0.84));
      b := least(0.95, (src->>'bounce')::float8 * demo.noise(0.07));
      e := round(s * (1 - b));
      cv := demo.sround(s * (src->>'cvr')::float8 * cvrf[i] * demo.noise(0.15));
      insert into ga4_metrics (client_id, data_source_id, report_date, source, medium, campaign, sessions, total_users, new_users,
        engaged_sessions, engagement_rate, bounce_rate, conversions, total_revenue)
      values (p_client, p_ds, d, src->>'source', src->>'medium', src->>'campaign', s, u, round(u * ns), e,
        round(e::numeric / s, 4), round(b::numeric, 4), cv,
        round((cv * coalesce((src->>'aov')::float8, 0) * demo.noise(0.12))::numeric, 2));
    end loop;
  end loop;

  -- owned broadcasts: {source, medium, campaign, day, sessions, cvr, aov, decay, bounce}; tail over the next 2 days
  for src in select x from jsonb_array_elements(coalesce(ga4->'owned', '[]'::jsonb)) with ordinality t(x, o) order by o loop
    for k in 0..2 loop
      i := (src->>'day')::int + k;
      exit when i > n;
      d := p_month + (i - 1);
      s := round((src->>'sessions')::float8 * coalesce((src->>'decay')::float8, 0.3) ^ k * demo.noise(0.1));
      if s <= 0 then continue; end if;
      u := greatest(1, round(s * 0.9));
      b := least(0.95, coalesce((src->>'bounce')::float8, 0.4) * demo.noise(0.07));
      e := round(s * (1 - b));
      cv := demo.sround(s * (src->>'cvr')::float8 * cvrf[i] * demo.noise(0.15));
      insert into ga4_metrics (client_id, data_source_id, report_date, source, medium, campaign, sessions, total_users, new_users,
        engaged_sessions, engagement_rate, bounce_rate, conversions, total_revenue)
      values (p_client, p_ds, d, src->>'source', src->>'medium', src->>'campaign', s, u, round(u * 0.08), e,
        round(e::numeric / s, 4), round(b::numeric, 4), cv,
        round((cv * coalesce((src->>'aov')::float8, 0) * demo.noise(0.12))::numeric, 2));
    end loop;
  end loop;

  -- owned automations (every day): {source, medium, campaign, sessions, cvr, aov, bounce}
  for i in 1..n loop
    d := p_month + (i - 1);
    for src in select x from jsonb_array_elements(coalesce(ga4->'automations', '[]'::jsonb)) with ordinality t(x, o) order by o loop
      s := round((src->>'sessions')::float8 * demo.noise(0.25));
      if s <= 0 then continue; end if;
      u := greatest(1, round(s * 0.95));
      b := least(0.95, coalesce((src->>'bounce')::float8, 0.3) * demo.noise(0.07));
      e := round(s * (1 - b));
      cv := demo.sround(s * (src->>'cvr')::float8 * cvrf[i] * demo.noise(0.2));
      insert into ga4_metrics (client_id, data_source_id, report_date, source, medium, campaign, sessions, total_users, new_users,
        engaged_sessions, engagement_rate, bounce_rate, conversions, total_revenue)
      values (p_client, p_ds, d, src->>'source', src->>'medium', src->>'campaign', s, u, round(u * 0.05), e,
        round(e::numeric / s, 4), round(b::numeric, 4), cv,
        round((cv * coalesce((src->>'aov')::float8, 0) * demo.noise(0.12))::numeric, 2));
    end loop;
  end loop;
end;
$$;

-- ------------------------------------------------------------------ one client
create or replace function demo.seed_client(cfg jsonb, p_month date) returns void
language plpgsql volatile set search_path = public as $$
declare
  v_slug text := cfg->>'slug';
  v_client uuid := md5('brain-demo:client:' || v_slug)::uuid;
  v_ds_g uuid := md5('brain-demo:google_ads:' || v_slug)::uuid;
  v_ds_f uuid := md5('brain-demo:facebook:' || v_slug)::uuid;
  v_ds_a uuid := md5('brain-demo:ga4:' || v_slug)::uuid;
  month_end date := (p_month + interval '1 month' - interval '1 day')::date;
  n int := extract(day from month_end)::int;
  dayf float8[] := '{}';
  cvrf float8[] := '{}';
  trf float8[] := '{}';
  base float8; tpos float8;
  ev jsonb; pl jsonb; rr jsonb;
  i int;
  d date;
  actual numeric;
begin
  perform set_config('demo.seed', (cfg->>'seed'), true);

  insert into clients (id, agency_id, name, slug, business_type, sort_order, tagline)
  values (v_client, '00000000-0000-0000-0000-000000000001', cfg->>'name', v_slug, cfg->>'business_type',
    (cfg->>'sort_order')::int, cfg->>'tagline');

  -- Exactly the provider strings the report pages filter on.
  insert into data_sources (id, client_id, provider, windsor_connection_id, status, last_synced_at) values
    (v_ds_g, v_client, 'google_ads', 'demo-' || v_slug || '-google-ads', 'active', month_end + interval '1 day 6 hours'),
    (v_ds_f, v_client, 'facebook', 'demo-' || v_slug || '-facebook', 'active', month_end + interval '1 day 6 hours'),
    (v_ds_a, v_client, 'ga4', 'demo-' || v_slug || '-ga4', 'active', month_end + interval '1 day 6 hours');

  -- Shared daily factors: weekday profile x month trend x market noise x events.
  for i in 1..n loop
    d := p_month + (i - 1);
    tpos := (i - 1)::float8 / greatest(n - 1, 1) - 0.5;
    base := (cfg->'dow'->>(extract(isodow from d)::int - 1))::float8
      * (1 + coalesce((cfg->>'trend')::float8, 0) * tpos) * demo.noise(0.05);
    dayf[i] := base;
    trf[i] := base;
    cvrf[i] := 1 + coalesce((cfg->>'cvr_trend')::float8, 0) * tpos;
    for ev in select x from jsonb_array_elements(coalesce(cfg->'events', '[]'::jsonb)) with ordinality t(x, o) order by o loop
      if i between (ev->>'from')::int and (ev->>'to')::int then
        dayf[i] := dayf[i] * coalesce((ev->>'spend')::float8, 1);
        cvrf[i] := cvrf[i] * coalesce((ev->>'cvr')::float8, 1);
        trf[i] := trf[i] * coalesce((ev->>'traffic')::float8, 1);
      end if;
    end loop;
  end loop;

  perform demo.gen_google(v_client, v_ds_g, v_ds_a, cfg, p_month, dayf, cvrf);
  perform demo.gen_meta(v_client, v_ds_f, v_ds_a, cfg, p_month, dayf, cvrf);
  perform demo.gen_ga4_other(v_client, v_ds_a, cfg, p_month, trf, cvrf);

  -- Media plan: each line states how it should pace (actual / plan), and the plan
  -- budget is back-computed from actual spend and rounded to €50 like a real plan.
  -- {network, flight_type, ad_set_type, label, pace, from, to, campaigns}
  for pl in select x from jsonb_array_elements(coalesce(cfg->'plan', '[]'::jsonb)) with ordinality t(x, o) order by o loop
    if pl->>'network' = 'google' then
      select coalesce(sum(spend), 0) into actual from google_ads_metrics
      where client_id = v_client and campaign_type = pl->>'ad_set_type'
        and report_date between p_month + (coalesce((pl->>'from')::int, 1) - 1) and p_month + (coalesce((pl->>'to')::int, n) - 1);
    else
      select coalesce(sum(spend), 0) into actual from facebook_ads_metrics
      where client_id = v_client and campaign in (select jsonb_array_elements_text(pl->'campaigns'))
        and report_date between p_month + (coalesce((pl->>'from')::int, 1) - 1) and p_month + (coalesce((pl->>'to')::int, n) - 1);
    end if;
    insert into media_plan_lines (client_id, month, network, flight_type, ad_set_type, campaign_label, start_date, end_date,
      budget_regular, budget_flash, budget_total)
    select v_client, p_month, pl->>'network', pl->>'flight_type', pl->>'ad_set_type', pl->>'label',
      p_month + (coalesce((pl->>'from')::int, 1) - 1), p_month + (coalesce((pl->>'to')::int, n) - 1),
      case when pl->>'flight_type' = 'Flight' then 0 else b end,
      case when pl->>'flight_type' = 'Flight' then b else 0 end,
      b
    from (select greatest(50, round(actual / (pl->>'pace')::numeric / 50) * 50) as b) x;
  end loop;

  -- PPC media report structure: {label, channel, level, campaigns, note}
  i := 0;
  for rr in select x from jsonb_array_elements(coalesce(cfg->'report_rows', '[]'::jsonb)) with ordinality t(x, o) order by o loop
    i := i + 1;
    insert into fashion_rs_report_rows (client_id, row_order, row_label, channel, level, campaign_names, note)
    values (v_client, i, rr->>'label', rr->>'channel', rr->>'level',
      array(select jsonb_array_elements_text(rr->'campaigns')), coalesce(rr->>'note', 'Demo podaci'));
  end loop;
end;
$$;

-- ------------------------------------------------------------------ entry point
create or replace function demo.seed(p_month date default '2026-08-01') returns table(out_slug text, out_table text, out_rows bigint)
language plpgsql volatile set search_path = public as $$
declare
  tpl record;
  v_agency uuid := '00000000-0000-0000-0000-000000000001';
begin
  if p_month <> date_trunc('month', p_month)::date then
    raise exception 'p_month must be the first day of a month, got %', p_month;
  end if;

  insert into agencies (id, name) values (v_agency, 'Pilot Agencija')
  on conflict (id) do update set name = excluded.name;

  -- Cascades to data_sources, every metrics table, media plan and report rows.
  delete from clients where agency_id = v_agency;

  for tpl in select * from demo.templates order by sort_order loop
    perform demo.seed_client(tpl.config, p_month);
  end loop;

  return query
  select c.slug, x.t, x.cnt from clients c
  cross join lateral (values
    ('google_ads_metrics', (select count(*) from google_ads_metrics g where g.client_id = c.id)),
    ('google_ads_keywords', (select count(*) from google_ads_keywords g where g.client_id = c.id)),
    ('google_ads_search_terms', (select count(*) from google_ads_search_terms g where g.client_id = c.id)),
    ('facebook_ads_metrics', (select count(*) from facebook_ads_metrics g where g.client_id = c.id)),
    ('meta_ad_set_metrics', (select count(*) from meta_ad_set_metrics g where g.client_id = c.id)),
    ('ga4_metrics', (select count(*) from ga4_metrics g where g.client_id = c.id)),
    ('media_plan_lines', (select count(*) from media_plan_lines g where g.client_id = c.id))
  ) x(t, cnt)
  where c.agency_id = v_agency
  order by c.sort_order, x.t;
end;
$$;
