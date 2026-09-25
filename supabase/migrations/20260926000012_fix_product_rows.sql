-- Product split must sum exactly to the campaign-day totals: keep rows whose only
-- non-zero field is spend or a click, and give value rounding cents to the largest bucket.
-- Like demo.split_money, but the rounding remainder goes to the largest bucket, so a
-- zero-weight last bucket can never swallow (and clamp away) the leftover cents.
create or replace function demo.split_money_max(total numeric, w float8[]) returns numeric[]
language plpgsql immutable set search_path = demo, public as $f$
declare
  n int := coalesce(array_length(w, 1), 0);
  r numeric[] := '{}';
  sw float8 := 0;
  s numeric := 0;
  top int := 1;
  i int;
begin
  if n = 0 then return r; end if;
  for i in 1..n loop
    sw := sw + greatest(w[i], 0);
    if w[i] > w[top] then top := i; end if;
  end loop;
  for i in 1..n loop
    r[i] := case when sw > 0 then round(total * (greatest(w[i], 0) / sw)::numeric, 2) else 0 end;
    s := s + r[i];
  end loop;
  r[top] := r[top] + (total - s);
  return r;
end;
$f$;

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
        p_vl := demo.split_money_max(t_vl, vw);
      else
        p_vl := array_fill(0::numeric, array[np]);
      end if;

      for k in 1..np loop
        if p_im[k] > 0 or p_cl[k] > 0 or p_sp[k] > 0 or p_cv[k] > 0 then
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
