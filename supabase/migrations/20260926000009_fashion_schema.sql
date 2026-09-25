-- Brain Reporting DEMO — fashion vertical: product feed, competition, sale calendar.
-- Feeds the "Fashion insights" page (markets, categories, bestsellers, collections,
-- sale-calendar impact, creative fatigue, competition). All additive; read-only for
-- the public key like the rest of the demo.

alter table public.clients add column if not exists vertical text;

-- Shopping / PMax performance per product (a split of the campaign-day totals).
create table public.shopping_product_metrics (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  report_date date not null,
  campaign text not null,
  market text,
  product_id text not null,
  product_title text not null,
  category text not null,
  season text not null,           -- SS / FW / core / BTS
  price numeric not null,
  impressions numeric not null default 0,
  clicks numeric not null default 0,
  spend numeric not null default 0,
  conversions numeric not null default 0,
  conversion_value numeric not null default 0
);
create index on public.shopping_product_metrics (client_id, report_date);

-- Sales, collection launches and holidays that shape the month.
create table public.demo_calendar_events (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  name text not null,
  event_type text not null check (event_type in ('sale', 'launch', 'holiday', 'other')),
  market text,
  start_date date not null,
  end_date date not null
);
create index on public.demo_calendar_events (client_id);

-- Competitor market signals per day and category (price index vs. the client = 1.00).
create table public.demo_competitor_daily (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  report_date date not null,
  competitor text not null,
  domain text not null,
  category text not null,
  price_index numeric not null,
  discount_share numeric not null,
  new_arrivals int not null default 0,
  active_ads int not null default 0
);
create index on public.demo_competitor_daily (client_id, report_date);

do $$
declare
  t text;
begin
  foreach t in array array['shopping_product_metrics', 'demo_calendar_events', 'demo_competitor_daily'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke insert, update, delete, truncate on public.%I from anon, authenticated', t);
    execute format('create policy "demo public read" on public.%I for select to anon, authenticated using (true)', t);
  end loop;
end $$;

-- Funnel classifier: standard Shopping campaigns (Ct:Shopping) are bottom-funnel performance.
create or replace function public.fashion_rs_classify(p_campaign text, p_native_type text)
returns table(campaign_subtype text, funnel_group text, funnel_stage text)
language plpgsql immutable set search_path = public as $$
declare
  ct text := fashion_rs_extract_tag(p_campaign, 'Ct');
  ph text := fashion_rs_extract_tag(p_campaign, 'Ph');
begin
  if ct ilike '%Display_Dyn%' or ct ilike '%Dyn%' then
    if ph ilike 'Bof' then
      return query select 'Dynamic remarketing'::text, 'Pure Performance'::text, 'BOF'::text;
    else
      return query select 'Dynamic prospecting'::text, 'Pure Performance'::text, 'TOF'::text;
    end if;
    return;
  end if;
  if ct ilike '%Display%' then
    return query select 'Display'::text, 'Brandformance'::text, coalesce(nullif(upper(ph), ''), 'TOF')::text;
    return;
  end if;
  if ct ilike '%PMax%' or ct ilike '%Pmax%' then
    return query select 'Performance Max'::text, 'Brandformance'::text, 'Full-funnel'::text;
    return;
  end if;
  if ct ilike '%DemandGen%' or ct ilike '%Demand_Gen%' or ct ilike '%DemanGen%' then
    return query select 'Demand Gen'::text, 'Brandformance'::text, 'TOF'::text;
    return;
  end if;
  if ct ilike '%Brand_Search%' then
    return query select 'Brand Search'::text, 'Pure Performance'::text, 'BOF'::text;
    return;
  end if;
  if ct ilike '%Generic_Search%' then
    return query select 'Generic Search'::text, 'Pure Performance'::text, 'BOF'::text;
    return;
  end if;
  if ct ilike '%Shopping%' then
    return query select 'Shopping'::text, 'Pure Performance'::text, 'BOF'::text;
    return;
  end if;
  if ct ilike '%Reengage%' then
    return query select 'App Re-engagement'::text, 'Pure Performance'::text, 'BOF'::text;
    return;
  end if;
  if ct ilike '%App%' then
    return query select 'App Install'::text, 'Brandformance'::text, 'TOF'::text;
    return;
  end if;
  if ct ilike '%Lead%' then
    if ph ilike 'Bof' then
      return query select 'Lead Gen (remarketing)'::text, 'Pure Performance'::text, 'BOF'::text;
    else
      return query select 'Lead Gen (prospecting)'::text, 'Pure Performance'::text, 'TOF'::text;
    end if;
    return;
  end if;
  if ct ilike '%Video%' or ct ilike '%View%' then
    return query select 'Video / View'::text, 'Brandformance'::text, 'TOF'::text;
    return;
  end if;
  if ct ilike '%Conversions%' then
    if ph ilike 'Bof' then
      return query select 'Catalog Sales (remarketing)'::text, 'Pure Performance'::text, 'BOF'::text;
    else
      return query select 'Catalog Sales (prospecting)'::text, 'Pure Performance'::text, 'TOF'::text;
    end if;
    return;
  end if;
  if ct ilike '%Traffic%' or ct ilike '%Awareness%' or ct ilike '%Reach%' then
    return query select 'Reach/Traffic'::text, 'Brandformance'::text, 'TOF'::text;
    return;
  end if;
  if p_native_type ilike '%AWARENESS%' or p_native_type ilike '%LINK_CLICKS%' then
    return query select 'Reach/Traffic (legacy)'::text, 'Brandformance'::text, 'TOF'::text;
    return;
  end if;
  if p_native_type ilike '%APP_INSTALLS%' then
    return query select 'App Install (legacy)'::text, 'Brandformance'::text, 'TOF'::text;
    return;
  end if;
  return query select coalesce(p_native_type, 'Nekategorisano')::text, 'Nekategorisano'::text, 'Nepoznato'::text;
end;
$$;

-- ------------------------------------------------------------------ Fashion insights RPCs

-- Per market (Mkt: tag in the campaign name; GA4 `store`).
create or replace function public.demo_market_summary(p_client_id uuid, p_start date, p_end date)
returns table(market text, spend numeric, google_spend numeric, meta_spend numeric, impressions numeric, clicks numeric,
  conversions numeric, conversion_value numeric, sessions numeric, total_users numeric, new_users numeric, ga4_revenue numeric)
language sql stable set search_path = public as $$
  with ads as (
    select fashion_rs_extract_tag(campaign, 'Mkt') as mkt, 'google' as ch, spend, impressions, clicks, conversions, conversion_value
    from google_ads_metrics where client_id = p_client_id and report_date between p_start and p_end
    union all
    select fashion_rs_extract_tag(campaign, 'Mkt'), 'meta', spend, impressions, clicks, conversions, conversion_value
    from facebook_ads_metrics where client_id = p_client_id and report_date between p_start and p_end
  ),
  a as (
    select coalesce(mkt, '—') as market, sum(spend) spend,
      sum(spend) filter (where ch = 'google') google_spend, sum(spend) filter (where ch = 'meta') meta_spend,
      sum(impressions) impressions, sum(clicks) clicks, sum(conversions) conversions, sum(conversion_value) conversion_value
    from ads group by 1
  ),
  g as (
    select coalesce(store, '—') as market, sum(sessions) sessions, sum(total_users) total_users, sum(new_users) new_users, sum(total_revenue) ga4_revenue
    from ga4_metrics where client_id = p_client_id and report_date between p_start and p_end group by 1
  )
  select coalesce(a.market, g.market), coalesce(a.spend, 0), coalesce(a.google_spend, 0), coalesce(a.meta_spend, 0),
    coalesce(a.impressions, 0), coalesce(a.clicks, 0), coalesce(a.conversions, 0), coalesce(a.conversion_value, 0),
    coalesce(g.sessions, 0), coalesce(g.total_users, 0), coalesce(g.new_users, 0), coalesce(g.ga4_revenue, 0)
  from a full outer join g on g.market = a.market
  order by 2 desc;
$$;

create or replace function public.demo_category_summary(p_client_id uuid, p_start date, p_end date)
returns table(category text, spend numeric, clicks numeric, conversions numeric, conversion_value numeric, products bigint)
language sql stable set search_path = public as $$
  select category, sum(spend), sum(clicks), sum(conversions), sum(conversion_value), count(distinct product_id)
  from shopping_product_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by category order by sum(conversion_value) desc;
$$;

create or replace function public.demo_top_products(p_client_id uuid, p_start date, p_end date, p_limit int default 15)
returns table(product_id text, product_title text, category text, season text, price numeric,
  spend numeric, clicks numeric, conversions numeric, conversion_value numeric)
language sql stable set search_path = public as $$
  select product_id, max(product_title), max(category), max(season), max(price),
    sum(spend), sum(clicks), sum(conversions), sum(conversion_value)
  from shopping_product_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by product_id order by sum(conversion_value) desc limit p_limit;
$$;

create or replace function public.demo_season_trend(p_client_id uuid, p_start date, p_end date)
returns table(report_date date, season text, conversion_value numeric, conversions numeric)
language sql stable set search_path = public as $$
  select report_date, season, sum(conversion_value), sum(conversions)
  from shopping_product_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by report_date, season order by report_date, season;
$$;

create or replace function public.demo_calendar(p_client_id uuid)
returns table(name text, event_type text, market text, start_date date, end_date date)
language sql stable set search_path = public as $$
  select name, event_type, market, start_date, end_date from demo_calendar_events
  where client_id = p_client_id order by start_date;
$$;

-- Event lift vs. the average of days that are not inside any event (GA4 revenue = site-side truth).
create or replace function public.demo_event_impact(p_client_id uuid, p_start date, p_end date)
returns table(name text, event_type text, start_date date, end_date date, days int,
  avg_daily_revenue numeric, baseline_daily_revenue numeric, revenue_lift_pct numeric,
  avg_daily_spend numeric, baseline_daily_spend numeric, roas numeric)
language sql stable set search_path = public as $$
  with days as (
    select d::date as d from generate_series(p_start, p_end, interval '1 day') d
  ),
  rev as (
    select report_date d, sum(total_revenue) rev from ga4_metrics
    where client_id = p_client_id and report_date between p_start and p_end group by 1
  ),
  sp as (
    select report_date d, sum(spend) spend, sum(conversion_value) value from (
      select report_date, spend, conversion_value from google_ads_metrics where client_id = p_client_id and report_date between p_start and p_end
      union all
      select report_date, spend, conversion_value from facebook_ads_metrics where client_id = p_client_id and report_date between p_start and p_end
    ) x group by 1
  ),
  daily as (
    select days.d, coalesce(rev.rev, 0) rev, coalesce(sp.spend, 0) spend, coalesce(sp.value, 0) value,
      exists (select 1 from demo_calendar_events e where e.client_id = p_client_id and days.d between e.start_date and e.end_date) in_event
    from days left join rev on rev.d = days.d left join sp on sp.d = days.d
  ),
  base as (select avg(rev) rev, avg(spend) spend from daily where not in_event)
  select e.name, e.event_type, e.start_date, e.end_date, (e.end_date - e.start_date + 1)::int,
    round(avg(dl.rev), 2), round(max(base.rev), 2),
    round(100 * (avg(dl.rev) / nullif(max(base.rev), 0) - 1), 1),
    round(avg(dl.spend), 2), round(max(base.spend), 2),
    round(sum(dl.value) / nullif(sum(dl.spend), 0), 2)
  from demo_calendar_events e
  join daily dl on dl.d between e.start_date and e.end_date
  cross join base
  where e.client_id = p_client_id and e.end_date >= p_start and e.start_date <= p_end
  group by e.name, e.event_type, e.start_date, e.end_date
  order by e.start_date;
$$;

-- Creative fatigue: CTR in each ad's first 7 active days vs. its last 7 in the period.
create or replace function public.demo_creative_fatigue(p_client_id uuid, p_start date, p_end date, p_limit int default 15)
returns table(ad_name text, campaign text, days_active int, spend numeric, impressions numeric,
  ctr_first numeric, ctr_last numeric, ctr_change_pct numeric)
language sql stable set search_path = public as $$
  with daily as (
    select ad_name, max(campaign) campaign, report_date, sum(impressions) im, sum(clicks) cl, sum(spend) sp
    from facebook_ads_creatives
    where client_id = p_client_id and report_date between p_start and p_end and impressions > 0
    group by ad_name, report_date
  ),
  ranked as (
    select *, row_number() over (partition by ad_name order by report_date) rn_first,
      row_number() over (partition by ad_name order by report_date desc) rn_last
    from daily
  ),
  agg as (
    select ad_name, max(campaign) campaign, count(*)::int days_active, sum(sp) spend, sum(im) impressions,
      sum(cl) filter (where rn_first <= 7) / nullif(sum(im) filter (where rn_first <= 7), 0) * 100 ctr_first,
      sum(cl) filter (where rn_last <= 7) / nullif(sum(im) filter (where rn_last <= 7), 0) * 100 ctr_last
    from ranked group by ad_name
  )
  select ad_name, campaign, days_active, round(spend, 2), impressions,
    round(ctr_first, 3), round(ctr_last, 3),
    round(100 * (ctr_last / nullif(ctr_first, 0) - 1), 1)
  from agg where days_active >= 10
  order by spend desc limit p_limit;
$$;

create or replace function public.demo_competitor_overview(p_client_id uuid, p_start date, p_end date)
returns table(competitor text, domain text, price_index numeric, discount_share numeric, new_arrivals bigint,
  active_ads numeric, auction_days bigint)
language sql stable set search_path = public as $$
  with c as (
    select competitor, max(domain) domain, avg(price_index) price_index, avg(discount_share) discount_share,
      sum(new_arrivals) new_arrivals
    from demo_competitor_daily
    where client_id = p_client_id and report_date between p_start and p_end
    group by competitor
  ),
  ads as (
    select competitor, avg(active_ads) active_ads from (
      select competitor, report_date, max(active_ads) active_ads from demo_competitor_daily
      where client_id = p_client_id and report_date between p_start and p_end group by 1, 2
    ) x group by 1
  )
  select c.competitor, c.domain, round(c.price_index, 3), round(c.discount_share, 3), c.new_arrivals, round(ads.active_ads, 0),
    (select count(distinct report_date) from google_ads_competitors g
      where g.client_id = p_client_id and g.report_date between p_start and p_end and g.domain = c.domain)
  from c join ads using (competitor)
  order by c.new_arrivals desc;
$$;

create or replace function public.demo_competitor_price_by_category(p_client_id uuid, p_start date, p_end date)
returns table(competitor text, category text, price_index numeric, discount_share numeric)
language sql stable set search_path = public as $$
  select competitor, category, round(avg(price_index), 3), round(avg(discount_share), 3)
  from demo_competitor_daily
  where client_id = p_client_id and report_date between p_start and p_end
  group by competitor, category order by competitor, category;
$$;

create or replace function public.demo_competitor_trend(p_client_id uuid, p_start date, p_end date)
returns table(report_date date, competitor text, discount_share numeric, active_ads numeric, new_arrivals bigint)
language sql stable set search_path = public as $$
  select report_date, competitor, round(avg(discount_share), 3), max(active_ads), sum(new_arrivals)
  from demo_competitor_daily
  where client_id = p_client_id and report_date between p_start and p_end
  group by report_date, competitor order by report_date, competitor;
$$;
