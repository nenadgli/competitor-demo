-- Brain Reporting DEMO — generator extensions for the fashion template.
--   * ads can have a launch day and creative fatigue (CTR decays with age)
--   * GA4 rows carry the market in `store` (paid: from the Mkt: tag; organic: from config)
--   * product-level Shopping/PMax split with seasonality (SS fades, FW ramps after launch)
--   * competitor market signals and the sale/launch calendar
-- None of this draws extra random numbers for templates that do not use it, so the
-- existing four clients regenerate with identical numbers (they also gain calendar
-- rows from their labelled events, and zero-impression ad rows are no longer stored).

-- ------------------------------------------------------------------ Meta: ad launch day + fatigue
-- ads: [name, adset# (1-based), weight, fatigue 0..1, launch day]
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
  ad_names text[]; adw float8[]; ad_fat float8[]; ad_start int[]; clw float8[];
  ad_im bigint[]; ad_cl bigint[]; ad_sp numeric[];
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
    adsets := c->'adsets';
    ads := c->'ads';
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

        perform demo.ga4_paid_row(p_client, p_ds_ga4, d, 'facebook', 'paid',
          cname || '--' || substring(adsets->(m - 1)->>0 from '^[A-Za-z0-9_]+'),
          a_cl[m], a_cv[m], a_vl[m],
          coalesce((c->>'ga4_spc')::float8, (ga4->>'meta_spc')::float8, 0.72),
          coalesce((ga4->>'meta_ratio')::float8, 0.6),
          coalesce((c->>'ga4_bounce')::float8, (ga4->>'meta_bounce')::float8, 0.5),
          coalesce((ga4->>'new_share')::float8, 0.6));

        select coalesce(array_agg(e->>0 order by o), '{}'),
               coalesce(array_agg(case when i < coalesce((e->>4)::int, 1) then 0 else coalesce((e->>2)::float8, 1) end order by o), '{}'),
               coalesce(array_agg(coalesce((e->>3)::float8, 0) order by o), '{}'),
               coalesce(array_agg(coalesce((e->>4)::int, 1) order by o), '{}')
          into ad_names, adw, ad_fat, ad_start
          from jsonb_array_elements(coalesce(ads, '[]'::jsonb)) with ordinality t(e, o)
          where (e->>1)::int = m;
        q := coalesce(array_length(ad_names, 1), 0);
        if q > 0 then
          adw := demo.jitter(adw, 0.2);
          -- fatigue: an ad's click share decays with its age in the month
          clw := '{}';
          for k in 1..q loop
            clw[k] := adw[k] * greatest(0.15, 1 - ad_fat[k] * greatest(i - ad_start[k], 0)::float8 / greatest(n - 1, 1));
          end loop;
          ad_im := demo.split_int(a_im[m], adw);
          ad_cl := demo.split_int(a_cl[m], clw);
          ad_sp := demo.split_money(a_sp[m], adw);
          for k in 1..q loop
            if ad_im[k] > 0 then
              insert into facebook_ads_creatives (client_id, data_source_id, report_date, campaign, adset_name, ad_name,
                impressions, clicks, spend)
              values (p_client, p_ds, d, cname, adsets->(m - 1)->>0, ad_names[k], ad_im[k], ad_cl[k], ad_sp[k]);
            end if;
          end loop;
        end if;
      end loop;

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

-- ------------------------------------------------------------------ GA4 organic/owned: optional store (market)
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
      insert into ga4_metrics (client_id, data_source_id, report_date, source, medium, campaign, store, sessions, total_users, new_users,
        engaged_sessions, engagement_rate, bounce_rate, conversions, total_revenue)
      values (p_client, p_ds, d, src->>'source', src->>'medium', src->>'campaign', src->>'store', s, u, round(u * ns), e,
        round(e::numeric / s, 4), round(b::numeric, 4), cv,
        round((cv * coalesce((src->>'aov')::float8, 0) * demo.noise(0.12))::numeric, 2));
    end loop;
  end loop;

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
      insert into ga4_metrics (client_id, data_source_id, report_date, source, medium, campaign, store, sessions, total_users, new_users,
        engaged_sessions, engagement_rate, bounce_rate, conversions, total_revenue)
      values (p_client, p_ds, d, src->>'source', src->>'medium', src->>'campaign', src->>'store', s, u, round(u * 0.08), e,
        round(e::numeric / s, 4), round(b::numeric, 4), cv,
        round((cv * coalesce((src->>'aov')::float8, 0) * demo.noise(0.12))::numeric, 2));
    end loop;
  end loop;

  for i in 1..n loop
    d := p_month + (i - 1);
    for src in select x from jsonb_array_elements(coalesce(ga4->'automations', '[]'::jsonb)) with ordinality t(x, o) order by o loop
      s := round((src->>'sessions')::float8 * demo.noise(0.25));
      if s <= 0 then continue; end if;
      u := greatest(1, round(s * 0.95));
      b := least(0.95, coalesce((src->>'bounce')::float8, 0.3) * demo.noise(0.07));
      e := round(s * (1 - b));
      cv := demo.sround(s * (src->>'cvr')::float8 * cvrf[i] * demo.noise(0.2));
      insert into ga4_metrics (client_id, data_source_id, report_date, source, medium, campaign, store, sessions, total_users, new_users,
        engaged_sessions, engagement_rate, bounce_rate, conversions, total_revenue)
      values (p_client, p_ds, d, src->>'source', src->>'medium', src->>'campaign', src->>'store', s, u, round(u * 0.05), e,
        round(e::numeric / s, 4), round(b::numeric, 4), cv,
        round((cv * coalesce((src->>'aov')::float8, 0) * demo.noise(0.12))::numeric, 2));
    end loop;
  end loop;
end;
$$;

-- ------------------------------------------------------------------ products
-- Seasonality multiplier for a product on day i: summer lines fade out, the FW
-- collection ramps up and jumps at its launch, back-to-school spikes at month end.
create or replace function demo.season_factor(p_season text, i int, n int, p_launch int, p_bts int)
returns float8 language sql immutable set search_path = demo, public as $$
  select case p_season
    when 'SS' then 1.5 - 1.25 * (i - 1)::float8 / greatest(n - 1, 1)
    when 'FW' then (0.25 + 1.1 * (i - 1)::float8 / greatest(n - 1, 1)) * (case when i >= p_launch then 1.6 else 1 end)
    when 'BTS' then case when i >= p_bts then 2.4 else 0.45 end
    else 1
  end
$$;

-- catalog: [product_id, title, category, price, weight, cvr×, season]
create or replace function demo.gen_products(p_client uuid, cfg jsonb, p_month date, n int) returns void
language plpgsql volatile set search_path = public as $$
declare
  cat jsonb := cfg->'catalog';
  np int := jsonb_array_length(cfg->'catalog');
  launch int := coalesce((cfg->>'launch_day')::int, n + 1);
  bts int := coalesce((cfg->>'bts_day')::int, n + 1);
  c jsonb;
  i int; k int;
  d date;
  mkt text;
  pm float8;
  t_im bigint; t_cl bigint; t_cv bigint; t_sp numeric; t_vl numeric;
  w float8[]; cm float8[]; vw float8[];
  p_im bigint[]; p_cl bigint[]; p_cv bigint[]; p_sp numeric[]; p_vl numeric[];
begin
  for c in select e from jsonb_array_elements(coalesce(cfg->'google', '[]'::jsonb)) with ordinality t(e, o)
           where coalesce((e->>'products')::boolean, false) order by o loop
    mkt := fashion_rs_extract_tag(c->>'name', 'Mkt');
    pm := coalesce((cfg->'market_price'->>mkt)::float8, 1);
    for i in 1..n loop
      d := p_month + (i - 1);
      select sum(impressions), sum(clicks), sum(conversions), sum(spend), sum(conversion_value)
        into t_im, t_cl, t_cv, t_sp, t_vl
        from google_ads_metrics where client_id = p_client and report_date = d and campaign = c->>'name';
      if coalesce(t_im, 0) = 0 then continue; end if;

      w := '{}';
      for k in 1..np loop
        w[k] := (cat->(k - 1)->>4)::float8 * demo.season_factor(cat->(k - 1)->>6, i, n, launch, bts);
      end loop;
      w := demo.jitter(w, 0.2);
      cm := demo.mul(w, demo.col(cat, 5));
      p_im := demo.split_int(t_im, w);
      p_cl := demo.split_int(t_cl, w);
      p_cv := demo.split_int(t_cv, cm);
      p_sp := demo.split_money(t_sp, w);
      vw := '{}';
      for k in 1..np loop vw[k] := p_cv[k] * (cat->(k - 1)->>3)::float8; end loop;
      if t_cv > 0 then
        p_vl := demo.split_money(t_vl, vw);
      else
        p_vl := array_fill(0::numeric, array[np]);
      end if;

      for k in 1..np loop
        if p_im[k] > 0 then
          insert into shopping_product_metrics (client_id, report_date, campaign, market, product_id, product_title, category, season,
            price, impressions, clicks, spend, conversions, conversion_value)
          values (p_client, d, c->>'name', mkt, cat->(k - 1)->>0, cat->(k - 1)->>1, cat->(k - 1)->>2, cat->(k - 1)->>6,
            round(((cat->(k - 1)->>3)::float8 * pm)::numeric, 2), p_im[k], p_cl[k], p_sp[k], p_cv[k], p_vl[k]);
        end if;
      end loop;
    end loop;
  end loop;
end;
$$;

-- ------------------------------------------------------------------ competition
-- competition: {categories: [...], competitors: [{name, domain, price_index, discount, arrivals, ads,
--   promo: {from, to, boost, label}}]}
create or replace function demo.gen_competition(p_client uuid, cfg jsonb, p_month date, n int) returns void
language plpgsql volatile set search_path = public as $$
declare
  comp jsonb := cfg->'competition';
  cats jsonb := comp->'categories';
  nc int := jsonb_array_length(comp->'categories');
  launch int := coalesce((cfg->>'launch_day')::int, n + 1);
  cc jsonb;
  i int; k int;
  d date;
  t01 float8;
  cat_idx float8[];
  disc float8; base_disc float8; ads int; in_promo boolean;
begin
  for cc in select e from jsonb_array_elements(comp->'competitors') with ordinality t(e, o) order by o loop
    -- a competitor is cheaper in some categories and pricier in others; fixed for the month
    cat_idx := '{}';
    for k in 1..nc loop
      cat_idx[k] := (cc->>'price_index')::float8 * demo.noise(0.07);
    end loop;
    base_disc := (cc->>'discount')::float8;

    for i in 1..n loop
      d := p_month + (i - 1);
      t01 := (i - 1)::float8 / greatest(n - 1, 1);
      in_promo := cc ? 'promo' and i between (cc->'promo'->>'from')::int and (cc->'promo'->>'to')::int;
      ads := round((cc->>'ads')::float8 * (case when i >= launch then 1.35 else 1 end) * (case when in_promo then 1.4 else 1 end) * demo.noise(0.08));
      for k in 1..nc loop
        -- summer sale winds down through August; a competitor promo pushes discounts back up
        disc := least(0.85, base_disc * (1.35 - 0.9 * t01) + (case when in_promo then coalesce((cc->'promo'->>'boost')::float8, 0.25) else 0 end))
          * demo.noise(0.05);
        insert into demo_competitor_daily (client_id, report_date, competitor, domain, category, price_index, discount_share,
          new_arrivals, active_ads)
        values (p_client, d, cc->>'name', cc->>'domain', cats->>(k - 1),
          round((cat_idx[k] * (1 - 0.35 * (disc - base_disc)) * demo.noise(0.01))::numeric, 3),
          round(disc::numeric, 3),
          demo.sround((cc->>'arrivals')::float8 / 7 / nc * (case when i >= launch then 2.2 else 0.8 end) * demo.noise(0.3)),
          ads);
      end loop;
    end loop;
  end loop;
end;
$$;

-- ------------------------------------------------------------------ one client (adds vertical, calendar, products, competition, GA4 store)
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

  insert into clients (id, agency_id, name, slug, business_type, sort_order, tagline, vertical)
  values (v_client, '00000000-0000-0000-0000-000000000001', cfg->>'name', v_slug, cfg->>'business_type',
    (cfg->>'sort_order')::int, cfg->>'tagline', cfg->>'vertical');

  insert into data_sources (id, client_id, provider, windsor_connection_id, status, last_synced_at) values
    (v_ds_g, v_client, 'google_ads', 'demo-' || v_slug || '-google-ads', 'active', month_end + interval '1 day 6 hours'),
    (v_ds_f, v_client, 'facebook', 'demo-' || v_slug || '-facebook', 'active', month_end + interval '1 day 6 hours'),
    (v_ds_a, v_client, 'ga4', 'demo-' || v_slug || '-ga4', 'active', month_end + interval '1 day 6 hours');

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

  -- paid GA4 rows: the market is the campaign's Mkt: tag (utm_campaign carries it)
  update ga4_metrics set store = fashion_rs_extract_tag(campaign, 'Mkt')
  where client_id = v_client and store is null and medium in ('cpc', 'paid');

  if cfg ? 'catalog' then
    perform demo.gen_products(v_client, cfg, p_month, n);
  end if;
  if cfg ? 'competition' then
    perform demo.gen_competition(v_client, cfg, p_month, n);
  end if;

  -- calendar: every template event with a label
  insert into demo_calendar_events (client_id, name, event_type, market, start_date, end_date)
  select v_client, x->>'label', coalesce(x->>'type', 'sale'), coalesce(x->>'market', 'Sva tržišta'),
    p_month + ((x->>'from')::int - 1), p_month + ((x->>'to')::int - 1)
  from jsonb_array_elements(coalesce(cfg->'events', '[]'::jsonb)) x
  where x ? 'label';

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

  i := 0;
  for rr in select x from jsonb_array_elements(coalesce(cfg->'report_rows', '[]'::jsonb)) with ordinality t(x, o) order by o loop
    i := i + 1;
    insert into fashion_rs_report_rows (client_id, row_order, row_label, channel, level, campaign_names, note)
    values (v_client, i, rr->>'label', rr->>'channel', rr->>'level',
      array(select jsonb_array_elements_text(rr->'campaigns')), coalesce(rr->>'note', 'Demo podaci'));
  end loop;
end;
$$;
