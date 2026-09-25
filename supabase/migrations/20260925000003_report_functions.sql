-- Brain Reporting DEMO — report RPCs.
-- Copied from production brain-reporting. Differences, all additive:
--   * every function pins search_path = public
--   * fashion_rs_funnel_summary / _funnel_group_totals / _ppc_campaign_detail take
--     p_client_id instead of hardcoding the 'fashion-friends-rs' slug
--   * fashion_rs_classify knows the Lead / Reengage / Video / View tags used by the
--     lead-gen, app and awareness templates
--   * demo_video_summary feeds the view-based metrics block on the awareness template

-- ---------------------------------------------------------------- auth helpers
create or replace function public.current_user_agency_id() returns uuid
language sql stable security definer set search_path = public as $$
  select agency_id from app_users where id = auth.uid()
$$;

create or replace function public.current_user_client_id() returns uuid
language sql stable security definer set search_path = public as $$
  select client_id from app_users where id = auth.uid()
$$;

create or replace function public.current_user_role() returns text
language sql stable security definer set search_path = public as $$
  select role from app_users where id = auth.uid()
$$;

-- ---------------------------------------------------------------- blended
create or replace function public.blended_campaign_summary(p_client_id uuid, p_start date, p_end date)
returns table(channel text, campaign text, impressions numeric, clicks numeric, spend numeric, conversions numeric, conversion_value numeric)
language sql stable set search_path = public as $$
  select 'google'::text, campaign, sum(impressions), sum(clicks), sum(spend), sum(conversions), sum(conversion_value)
  from google_ads_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by campaign
  union all
  select 'meta'::text, campaign, sum(impressions), sum(clicks), sum(spend), sum(conversions), sum(conversion_value)
  from facebook_ads_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by campaign
  order by 5 desc;
$$;

create or replace function public.blended_channel_summary(p_client_id uuid, p_start date, p_end date)
returns table(channel text, impressions numeric, clicks numeric, spend numeric, conversions numeric, conversion_value numeric)
language sql stable set search_path = public as $$
  select 'google'::text, coalesce(sum(impressions),0), coalesce(sum(clicks),0), coalesce(sum(spend),0), coalesce(sum(conversions),0), coalesce(sum(conversion_value),0)
  from google_ads_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  union all
  select 'meta'::text, coalesce(sum(impressions),0), coalesce(sum(clicks),0), coalesce(sum(spend),0), coalesce(sum(conversions),0), coalesce(sum(conversion_value),0)
  from facebook_ads_metrics
  where client_id = p_client_id and report_date between p_start and p_end;
$$;

create or replace function public.blended_daily_trend(p_client_id uuid, p_start date, p_end date)
returns table(report_date date, channel text, spend numeric, conversions numeric, conversion_value numeric)
language sql stable set search_path = public as $$
  select report_date, 'google'::text, sum(spend), sum(conversions), sum(conversion_value)
  from google_ads_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by report_date
  union all
  select report_date, 'meta'::text, sum(spend), sum(conversions), sum(conversion_value)
  from facebook_ads_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by report_date
  order by 1;
$$;

create or replace function public.blended_date_range(p_client_id uuid)
returns table(min_date date, max_date date)
language sql stable set search_path = public as $$
  select min(d), max(d) from (
    select min(report_date) as d from google_ads_metrics where client_id = p_client_id
    union all select max(report_date) from google_ads_metrics where client_id = p_client_id
    union all select min(report_date) from facebook_ads_metrics where client_id = p_client_id
    union all select max(report_date) from facebook_ads_metrics where client_id = p_client_id
  ) t;
$$;

-- ---------------------------------------------------------------- facebook
create or replace function public.facebook_ads_campaign_summary(p_client_id uuid, p_start date, p_end date)
returns table(campaign text, objective text, impressions numeric, clicks numeric, spend numeric, reach numeric, conversions numeric, conversion_value numeric)
language sql stable set search_path = public as $$
  select campaign, max(objective), sum(impressions), sum(clicks), sum(spend), sum(reach), sum(conversions), sum(conversion_value)
  from facebook_ads_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by campaign order by sum(spend) desc;
$$;

create or replace function public.facebook_ads_daily_trend(p_client_id uuid, p_start date, p_end date)
returns table(report_date date, spend numeric, conversions numeric)
language sql stable set search_path = public as $$
  select report_date, sum(spend), sum(conversions)
  from facebook_ads_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by report_date order by report_date;
$$;

create or replace function public.facebook_ads_device_summary(p_client_id uuid, p_start date, p_end date)
returns table(device_platform text, spend numeric, clicks numeric, impressions numeric)
language sql stable set search_path = public as $$
  select coalesce(device_platform, 'other'), sum(spend), sum(clicks), sum(impressions)
  from facebook_ads_placements
  where client_id = p_client_id and report_date between p_start and p_end
  group by coalesce(device_platform, 'other') order by sum(spend) desc;
$$;

create or replace function public.facebook_ads_objective_summary(p_client_id uuid, p_start date, p_end date)
returns table(objective text, spend numeric, clicks numeric, conversions numeric, conversion_value numeric)
language sql stable set search_path = public as $$
  select coalesce(objective, 'OSTALO'), sum(spend), sum(clicks), sum(conversions), sum(conversion_value)
  from facebook_ads_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by coalesce(objective, 'OSTALO') order by sum(spend) desc;
$$;

create or replace function public.facebook_ads_period_totals(p_client_id uuid, p_start date, p_end date)
returns table(impressions numeric, clicks numeric, spend numeric, reach numeric, conversions numeric, conversion_value numeric)
language sql stable set search_path = public as $$
  select coalesce(sum(impressions),0), coalesce(sum(clicks),0), coalesce(sum(spend),0), coalesce(sum(reach),0),
         coalesce(sum(conversions),0), coalesce(sum(conversion_value),0)
  from facebook_ads_metrics
  where client_id = p_client_id and report_date between p_start and p_end;
$$;

create or replace function public.facebook_ads_platform_summary(p_client_id uuid, p_start date, p_end date)
returns table(publisher_platform text, spend numeric, clicks numeric, impressions numeric, reach numeric)
language sql stable set search_path = public as $$
  select coalesce(publisher_platform, 'other'), sum(spend), sum(clicks), sum(impressions), sum(reach)
  from facebook_ads_placements
  where client_id = p_client_id and report_date between p_start and p_end
  group by coalesce(publisher_platform, 'other') order by sum(spend) desc;
$$;

create or replace function public.facebook_ads_top_creatives(p_client_id uuid, p_start date, p_end date, p_limit integer default 20)
returns table(ad_name text, adset_name text, campaign text, impressions numeric, clicks numeric, spend numeric)
language sql stable set search_path = public as $$
  select coalesce(ad_name, '(bez imena)'), max(adset_name), max(campaign), sum(impressions), sum(clicks), sum(spend)
  from facebook_ads_creatives
  where client_id = p_client_id and report_date between p_start and p_end
  group by coalesce(ad_name, '(bez imena)')
  order by sum(spend) desc
  limit p_limit;
$$;

-- ---------------------------------------------------------------- google
create or replace function public.google_ads_campaign_summary(p_client_id uuid, p_start date, p_end date)
returns table(campaign text, campaign_type text, impressions numeric, clicks numeric, spend numeric, conversions numeric, conversion_value numeric)
language sql stable set search_path = public as $$
  select campaign, max(campaign_type), sum(impressions), sum(clicks), sum(spend), sum(conversions), sum(conversion_value)
  from google_ads_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by campaign
  order by sum(spend) desc;
$$;

create or replace function public.google_ads_campaign_type_summary(p_client_id uuid, p_start date, p_end date)
returns table(campaign_type text, spend numeric, clicks numeric, conversions numeric, conversion_value numeric)
language sql stable set search_path = public as $$
  select coalesce(campaign_type, 'OSTALO'), sum(spend), sum(clicks), sum(conversions), sum(conversion_value)
  from google_ads_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by coalesce(campaign_type, 'OSTALO')
  order by sum(spend) desc;
$$;

create or replace function public.google_ads_daily_trend(p_client_id uuid, p_start date, p_end date)
returns table(report_date date, spend numeric, conversions numeric)
language sql stable set search_path = public as $$
  select report_date, sum(spend), sum(conversions)
  from google_ads_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by report_date
  order by report_date;
$$;

create or replace function public.google_ads_device_summary(p_client_id uuid, p_start date, p_end date)
returns table(device text, spend numeric, clicks numeric, impressions numeric, conversions numeric)
language sql stable set search_path = public as $$
  select coalesce(device, 'OTHER'), sum(spend), sum(clicks), sum(impressions), sum(conversions)
  from google_ads_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by coalesce(device, 'OTHER')
  order by sum(spend) desc;
$$;

create or replace function public.google_ads_impression_share(p_client_id uuid, p_start date, p_end date)
returns table(avg_share numeric)
language sql stable set search_path = public as $$
  select case when sum(impressions) > 0
    then sum(search_impression_share * impressions) / sum(impressions) * 100
    else null end
  from google_ads_metrics
  where client_id = p_client_id and report_date between p_start and p_end
    and campaign_type = 'SEARCH' and search_impression_share is not null;
$$;

create or replace function public.google_ads_period_totals(p_client_id uuid, p_start date, p_end date)
returns table(impressions numeric, clicks numeric, spend numeric, conversions numeric, conversion_value numeric)
language sql stable set search_path = public as $$
  select coalesce(sum(impressions),0), coalesce(sum(clicks),0), coalesce(sum(spend),0),
         coalesce(sum(conversions),0), coalesce(sum(conversion_value),0)
  from google_ads_metrics
  where client_id = p_client_id and report_date between p_start and p_end;
$$;

create or replace function public.google_ads_top_competitors(p_client_id uuid, p_start date, p_end date, p_limit integer default 12)
returns table(domain text, campaign_count bigint, occurrences bigint)
language sql stable set search_path = public as $$
  select domain, count(distinct campaign), count(*)
  from google_ads_competitors
  where client_id = p_client_id and report_date between p_start and p_end
  group by domain
  order by count(*) desc
  limit p_limit;
$$;

create or replace function public.google_ads_top_keywords(p_client_id uuid, p_start date, p_end date, p_limit integer default 20)
returns table(keyword_text text, keyword_match_type text, impressions numeric, clicks numeric, spend numeric, conversions numeric, avg_quality_score numeric)
language sql stable set search_path = public as $$
  select keyword_text, max(keyword_match_type), sum(impressions), sum(clicks), sum(spend), sum(conversions), avg(quality_score)
  from google_ads_keywords
  where client_id = p_client_id and report_date between p_start and p_end
  group by keyword_text
  order by sum(spend) desc
  limit p_limit;
$$;

create or replace function public.google_ads_top_search_terms(p_client_id uuid, p_start date, p_end date, p_zero_conv_only boolean default false, p_limit integer default 25)
returns table(search_term text, impressions numeric, clicks numeric, spend numeric, conversions numeric)
language sql stable set search_path = public as $$
  select search_term, sum(impressions), sum(clicks), sum(spend), sum(conversions)
  from google_ads_search_terms
  where client_id = p_client_id and report_date between p_start and p_end
  group by search_term
  having (not p_zero_conv_only) or (sum(conversions) = 0 and sum(clicks) > 0)
  order by sum(spend) desc
  limit p_limit;
$$;

-- ---------------------------------------------------------------- ga4 / owned
create or replace function public.ga4_campaign_summary(p_client_id uuid, p_start date, p_end date, p_limit integer default 20)
returns table(campaign text, source text, sessions numeric, total_users numeric, conversions numeric, total_revenue numeric)
language sql stable set search_path = public as $$
  select campaign, max(source), sum(sessions), sum(total_users), sum(conversions), sum(total_revenue)
  from ga4_metrics
  where client_id = p_client_id and report_date between p_start and p_end
    and campaign is not null and campaign not in ('(direct)', '(not set)')
  group by campaign
  order by sum(sessions) desc
  limit p_limit;
$$;

create or replace function public.ga4_daily_trend(p_client_id uuid, p_start date, p_end date)
returns table(report_date date, sessions numeric, conversions numeric, total_revenue numeric)
language sql stable set search_path = public as $$
  select report_date, sum(sessions), sum(conversions), sum(total_revenue)
  from ga4_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by report_date order by report_date;
$$;

create or replace function public.ga4_date_range(p_client_id uuid)
returns table(min_date date, max_date date)
language sql stable set search_path = public as $$
  select min(report_date), max(report_date) from ga4_metrics where client_id = p_client_id;
$$;

create or replace function public.ga4_engagement_by_channel(p_client_id uuid, p_start date, p_end date, p_limit integer default 8)
returns table(source text, sessions numeric, engaged_sessions numeric, bounce_rate numeric, conversions numeric)
language sql stable set search_path = public as $$
  select coalesce(source, '(not set)'), sum(sessions), sum(engaged_sessions),
    case when sum(sessions) > 0 then sum(bounce_rate * sessions) / sum(sessions) else null end,
    sum(conversions)
  from ga4_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by coalesce(source, '(not set)')
  order by sum(sessions) desc
  limit p_limit;
$$;

create or replace function public.ga4_new_vs_returning_trend(p_client_id uuid, p_start date, p_end date)
returns table(report_date date, new_users numeric, returning_users numeric)
language sql stable set search_path = public as $$
  select report_date, sum(new_users), greatest(sum(total_users) - sum(new_users), 0)
  from ga4_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by report_date order by report_date;
$$;

create or replace function public.ga4_paid_channel_verification(p_client_id uuid, p_start date, p_end date)
returns table(channel text, sessions numeric, total_users numeric, engaged_sessions numeric, conversions numeric, total_revenue numeric)
language sql stable set search_path = public as $$
  select
    case when source = 'google' then 'google' when source = 'facebook' then 'meta' else source end,
    sum(sessions), sum(total_users), sum(engaged_sessions), sum(conversions), sum(total_revenue)
  from ga4_metrics
  where client_id = p_client_id and report_date between p_start and p_end
    and source in ('google', 'facebook')
    and medium in ('cpc', 'paid', 'paid_social')
  group by case when source = 'google' then 'google' when source = 'facebook' then 'meta' else source end;
$$;

create or replace function public.ga4_period_totals(p_client_id uuid, p_start date, p_end date)
returns table(sessions numeric, total_users numeric, new_users numeric, engaged_sessions numeric, conversions numeric, total_revenue numeric)
language sql stable set search_path = public as $$
  select coalesce(sum(sessions),0), coalesce(sum(total_users),0), coalesce(sum(new_users),0),
         coalesce(sum(engaged_sessions),0), coalesce(sum(conversions),0), coalesce(sum(total_revenue),0)
  from ga4_metrics
  where client_id = p_client_id and report_date between p_start and p_end;
$$;

create or replace function public.ga4_source_summary(p_client_id uuid, p_start date, p_end date, p_limit integer default 15)
returns table(source text, sessions numeric, total_users numeric, engaged_sessions numeric, conversions numeric, total_revenue numeric)
language sql stable set search_path = public as $$
  select coalesce(source, '(not set)'), sum(sessions), sum(total_users), sum(engaged_sessions), sum(conversions), sum(total_revenue)
  from ga4_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by coalesce(source, '(not set)')
  order by sum(sessions) desc
  limit p_limit;
$$;

create or replace function public.owned_channel_daily_trend(p_client_id uuid, p_start date, p_end date)
returns table(report_date date, source text, sessions numeric, conversions numeric, total_revenue numeric)
language sql stable set search_path = public as $$
  select report_date, source, sum(sessions), sum(conversions), sum(total_revenue)
  from ga4_metrics
  where client_id = p_client_id and report_date between p_start and p_end
    and source in ('push_notification', 'newsletter')
  group by report_date, source
  order by report_date;
$$;

create or replace function public.owned_channel_date_range(p_client_id uuid)
returns table(min_date date, max_date date)
language sql stable set search_path = public as $$
  select min(report_date), max(report_date) from ga4_metrics
  where client_id = p_client_id and source in ('push_notification', 'newsletter');
$$;

create or replace function public.owned_channel_period_totals(p_client_id uuid, p_start date, p_end date)
returns table(source text, sessions numeric, total_users numeric, engaged_sessions numeric, conversions numeric, total_revenue numeric, campaign_count bigint)
language sql stable set search_path = public as $$
  select source, sum(sessions), sum(total_users), sum(engaged_sessions), sum(conversions), sum(total_revenue), count(distinct campaign)
  from ga4_metrics
  where client_id = p_client_id and report_date between p_start and p_end
    and source in ('push_notification', 'newsletter')
  group by source;
$$;

create or replace function public.owned_channel_top_campaigns(p_client_id uuid, p_start date, p_end date, p_source text, p_limit integer default 20)
returns table(campaign text, sessions numeric, total_users numeric, engaged_sessions numeric, conversions numeric, total_revenue numeric)
language sql stable set search_path = public as $$
  select campaign, sum(sessions), sum(total_users), sum(engaged_sessions), sum(conversions), sum(total_revenue)
  from ga4_metrics
  where client_id = p_client_id and report_date between p_start and p_end and source = p_source
  group by campaign
  order by sum(total_revenue) desc, sum(sessions) desc
  limit p_limit;
$$;

create or replace function public.owned_channel_type_summary(p_client_id uuid, p_start date, p_end date, p_source text)
returns table(campaign_type text, sessions numeric, total_users numeric, conversions numeric, total_revenue numeric, campaign_count bigint)
language sql stable set search_path = public as $$
  select
    case
      when p_source = 'newsletter' and campaign ilike 'AbandCart%' then 'Napušteta korpa (automatizacija)'
      when p_source = 'newsletter' then 'Broadcast newsletter'
      else 'Push kampanja'
    end,
    sum(sessions), sum(total_users), sum(conversions), sum(total_revenue), count(distinct campaign)
  from ga4_metrics
  where client_id = p_client_id and report_date between p_start and p_end and source = p_source
  group by 1
  order by sum(total_revenue) desc;
$$;

-- ---------------------------------------------------------------- naming convention: Name (Mkt:XX;Ct:Type;Ph:Tof/Bof)
create or replace function public.fashion_rs_extract_tag(p_campaign text, p_tag text) returns text
language sql immutable set search_path = public as $$
  select (regexp_match(p_campaign, p_tag || ':([^;)]+)'))[1];
$$;

create or replace function public.fashion_rs_budget_bucket(p_campaign text, p_native_type text) returns text
language sql immutable set search_path = public as $$
  select case
    when p_campaign ilike 'Social%' or p_campaign ilike '%Page Likes%' then 'Social'
    when p_campaign ilike '%Ct:App%' or p_native_type ilike '%APP_INSTALLS%' then 'Loyalty'
    else 'Ecomm'
  end;
$$;

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

  -- demo: app re-engagement is a performance (BOF) play, not install volume
  if ct ilike '%Reengage%' then
    return query select 'App Re-engagement'::text, 'Pure Performance'::text, 'BOF'::text;
    return;
  end if;

  if ct ilike '%App%' then
    return query select 'App Install'::text, 'Brandformance'::text, 'TOF'::text;
    return;
  end if;

  -- demo: lead-gen forms / lead campaigns
  if ct ilike '%Lead%' then
    if ph ilike 'Bof' then
      return query select 'Lead Gen (remarketing)'::text, 'Pure Performance'::text, 'BOF'::text;
    else
      return query select 'Lead Gen (prospecting)'::text, 'Pure Performance'::text, 'TOF'::text;
    end if;
    return;
  end if;

  -- demo: YouTube / video view campaigns
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

create or replace function public.fashion_rs_funnel_summary(p_client_id uuid, p_start date, p_end date)
returns table(funnel_group text, funnel_stage text, campaign_subtype text, channel text, spend numeric, clicks numeric, conversions numeric, conversion_value numeric)
language sql stable set search_path = public as $$
  with google_rows as (
    select (fashion_rs_classify(g.campaign, g.campaign_type)).*, 'google'::text as channel,
      sum(g.spend) as spend, sum(g.clicks) as clicks, sum(g.conversions) as conversions, sum(g.conversion_value) as conversion_value
    from google_ads_metrics g
    where g.client_id = p_client_id and g.report_date between p_start and p_end
    group by g.campaign, g.campaign_type
  ),
  meta_rows as (
    select (fashion_rs_classify(m.campaign, m.objective)).*, 'meta'::text as channel,
      sum(m.spend) as spend, sum(m.clicks) as clicks, sum(m.conversions) as conversions, sum(m.conversion_value) as conversion_value
    from facebook_ads_metrics m
    where m.client_id = p_client_id and m.report_date between p_start and p_end
    group by m.campaign, m.objective
  ),
  combined as (select * from google_rows union all select * from meta_rows)
  select funnel_group, funnel_stage, campaign_subtype, channel,
    sum(spend), sum(clicks), sum(conversions), sum(conversion_value)
  from combined
  group by funnel_group, funnel_stage, campaign_subtype, channel
  order by sum(spend) desc;
$$;

create or replace function public.fashion_rs_funnel_group_totals(p_client_id uuid, p_start date, p_end date)
returns table(funnel_group text, spend numeric, conversions numeric, conversion_value numeric)
language sql stable set search_path = public as $$
  select funnel_group, sum(spend), sum(conversions), sum(conversion_value)
  from fashion_rs_funnel_summary(p_client_id, p_start, p_end)
  group by funnel_group
  order by sum(spend) desc;
$$;

create or replace function public.fashion_rs_ppc_campaign_detail(p_client_id uuid, p_start date, p_end date)
returns table(channel text, bucket text, campaign text, spend numeric, reach numeric, impressions numeric, clicks numeric, conversions numeric, conversion_value numeric)
language sql stable set search_path = public as $$
  with google_rows as (
    select 'google'::text as channel, fashion_rs_budget_bucket(g.campaign, g.campaign_type) as bucket, g.campaign,
      sum(g.spend) as spend, 0::numeric as reach, sum(g.impressions) as impressions, sum(g.clicks) as clicks,
      sum(g.conversions) as conversions, sum(g.conversion_value) as conversion_value
    from google_ads_metrics g
    where g.client_id = p_client_id and g.report_date between p_start and p_end
    group by g.campaign, fashion_rs_budget_bucket(g.campaign, g.campaign_type)
  ),
  meta_rows as (
    select 'meta'::text as channel, fashion_rs_budget_bucket(m.campaign, m.objective) as bucket, m.campaign,
      sum(m.spend) as spend, sum(m.reach) as reach, sum(m.impressions) as impressions, sum(m.clicks) as clicks,
      sum(m.conversions) as conversions, sum(m.conversion_value) as conversion_value
    from facebook_ads_metrics m
    where m.client_id = p_client_id and m.report_date between p_start and p_end
    group by m.campaign, fashion_rs_budget_bucket(m.campaign, m.objective)
  )
  select * from google_rows union all select * from meta_rows
  order by spend desc;
$$;

create or replace function public.fashion_rs_ppc_channel_summary(p_client_id uuid, p_start date, p_end date)
returns table(channel text, bucket text, spend numeric, reach numeric, impressions numeric, clicks numeric, conversions numeric, conversion_value numeric)
language plpgsql stable set search_path = public as $$
declare
  b record;
  mkt_tag text;
  use_fallback boolean;
begin
  select enable_bare_adset_revenue_match into use_fallback from clients where id = p_client_id;

  return query
  select 'google'::text, fashion_rs_budget_bucket(g.campaign, g.campaign_type),
    sum(g.spend), sum(g.unique_users), sum(g.impressions), sum(g.clicks), sum(g.conversions),
    (select coalesce(sum(ga.total_revenue),0) from ga4_metrics ga
      where ga.client_id = p_client_id and ga.report_date between p_start and p_end
      and ga.campaign = any(array_agg(distinct g.campaign)))
  from google_ads_metrics g
  where g.client_id = p_client_id and g.report_date between p_start and p_end
  group by fashion_rs_budget_bucket(g.campaign, g.campaign_type);

  for b in
    select fashion_rs_budget_bucket(m.campaign, m.objective) as bucket,
      array_agg(distinct m.campaign) as campaigns,
      sum(m.spend) as spend, sum(m.reach) as reach, sum(m.impressions) as impressions,
      sum(m.clicks) as clicks, sum(m.conversions) as conversions
    from facebook_ads_metrics m
    where m.client_id = p_client_id and m.report_date between p_start and p_end
    group by fashion_rs_budget_bucket(m.campaign, m.objective)
  loop
    mkt_tag := substring(b.campaigns[1] from 'Mkt:[A-Za-z]+');
    return query
    select 'meta'::text, b.bucket, b.spend, b.reach, b.impressions, b.clicks, b.conversions,
      coalesce((select sum(ga.total_revenue) from ga4_metrics ga where ga.client_id = p_client_id
        and ga.report_date between p_start and p_end
        and (
          exists (select 1 from unnest(b.campaigns) cn where ga.campaign like cn || '--%')
          or (
            use_fallback and mkt_tag is not null and ga.campaign like '%' || mkt_tag || '%' and exists (
              select 1 from meta_ad_set_metrics ms
              where ms.client_id = p_client_id and ms.campaign = any(b.campaigns)
              and ga.campaign like substring(ms.adset_name from '^[A-Za-z0-9_]+') || '%'
            )
          )
        )), 0);
  end loop;
end;
$$;

create or replace function public.fashion_rs_report_structure(p_client_id uuid, p_start date, p_end date)
returns table(row_order integer, row_label text, channel text, level text, sub_dimension text, spend numeric, reach numeric, impressions numeric, clicks numeric, conversions numeric, conversion_value numeric, revenue_source text)
language plpgsql stable set search_path = public as $$
declare
  r record;
  cname text;
  mkt_tag text;
  use_fallback boolean;
begin
  select enable_bare_adset_revenue_match into use_fallback from clients where id = p_client_id;

  for r in select * from fashion_rs_report_rows where fashion_rs_report_rows.client_id = p_client_id order by fashion_rs_report_rows.row_order loop
    if r.level = 'campaign' then
      if r.channel = 'google' then
        return query
        select r.row_order, r.row_label, r.channel, r.level, null::text,
          coalesce(sum(g.spend),0),
          case when bool_and(g.campaign_type = 'SEARCH') then null else coalesce(sum(g.unique_users),0) end,
          coalesce(sum(g.impressions),0), coalesce(sum(g.clicks),0),
          coalesce(sum(g.conversions),0),
          coalesce((select sum(ga.total_revenue) from ga4_metrics ga where ga.client_id = p_client_id
            and ga.report_date between p_start and p_end and ga.campaign = any(r.campaign_names)), 0),
          'GA4'::text
        from google_ads_metrics g
        where g.client_id = p_client_id and g.report_date between p_start and p_end
          and g.campaign = any(r.campaign_names);
      else
        mkt_tag := substring(r.campaign_names[1] from 'Mkt:[A-Za-z]+');
        return query
        select r.row_order, r.row_label, r.channel, r.level, null::text,
          coalesce(sum(m.spend),0), coalesce(sum(m.reach),0), coalesce(sum(m.impressions),0), coalesce(sum(m.clicks),0),
          coalesce(sum(m.conversions),0),
          coalesce((select sum(ga.total_revenue) from ga4_metrics ga where ga.client_id = p_client_id
            and ga.report_date between p_start and p_end
            and (
              exists (select 1 from unnest(r.campaign_names) cn where ga.campaign like cn || '--%')
              or (
                use_fallback and mkt_tag is not null and ga.campaign like '%' || mkt_tag || '%' and exists (
                  select 1 from meta_ad_set_metrics ms
                  where ms.client_id = p_client_id and ms.campaign = any(r.campaign_names)
                  and ga.campaign like substring(ms.adset_name from '^[A-Za-z0-9_]+') || '%'
                )
              )
            )), 0),
          'GA4'::text
        from facebook_ads_metrics m
        where m.client_id = p_client_id and m.report_date between p_start and p_end
          and m.campaign = any(r.campaign_names);
      end if;

    elsif r.level = 'meta_ad_set' then
      cname := r.campaign_names[1];
      mkt_tag := substring(cname from 'Mkt:[A-Za-z]+');
      return query
      with grouped as (
        select coalesce(a.adset_name, '(bez ad seta)') as adset_name,
          sum(a.spend) as spend, sum(a.reach) as reach, sum(a.impressions) as impressions, sum(a.clicks) as clicks, sum(a.conversions) as conversions
        from meta_ad_set_metrics a
        where a.client_id = p_client_id and a.report_date between p_start and p_end
          and a.campaign = any(r.campaign_names)
        group by coalesce(a.adset_name, '(bez ad seta)')
        having sum(a.spend) > 0
      )
      select r.row_order, r.row_label, r.channel, r.level, gr.adset_name,
        gr.spend, gr.reach, gr.impressions, gr.clicks, gr.conversions,
        coalesce((select sum(ga.total_revenue) from ga4_metrics ga where ga.client_id = p_client_id
          and ga.report_date between p_start and p_end
          and (
            ga.campaign like cname || '--' || substring(gr.adset_name from '^[A-Za-z0-9_]+') || '%'
            or (use_fallback and mkt_tag is not null and ga.campaign like '%' || mkt_tag || '%'
                and ga.campaign like substring(gr.adset_name from '^[A-Za-z0-9_]+') || '%')
          )), 0),
        'GA4'::text
      from grouped gr
      order by gr.spend desc;

    elsif r.level = 'google_ad_group' then
      return query
      select r.row_order, r.row_label, r.channel, r.level, coalesce(a.ad_group_name, '(bez ad grupe)'),
        sum(a.spend), null::numeric, sum(a.impressions), sum(a.clicks), sum(a.conversions), sum(a.conversion_value),
        'Platforma (GA4 nema ovu granularnost)'::text
      from google_ad_group_metrics a
      where a.client_id = p_client_id and a.report_date between p_start and p_end
        and a.campaign = any(r.campaign_names)
      group by coalesce(a.ad_group_name, '(bez ad grupe)')
      having sum(a.spend) > 0
      order by sum(a.spend) desc;

    elsif r.level = 'asset_group' then
      return query
      select r.row_order, r.row_label, r.channel, r.level, coalesce(a.asset_group_name, '(bez asset grupe)'),
        sum(a.spend), null::numeric, sum(a.impressions), sum(a.clicks), sum(a.conversions), sum(a.conversion_value),
        'Platforma (GA4 nema ovu granularnost)'::text
      from google_asset_group_metrics a
      where a.client_id = p_client_id and a.report_date between p_start and p_end
        and a.campaign = any(r.campaign_names)
      group by coalesce(a.asset_group_name, '(bez asset grupe)')
      having sum(a.spend) > 0
      order by sum(a.spend) desc;
    end if;
  end loop;
end;
$$;

-- ---------------------------------------------------------------- budget pacing
create or replace function public.fashion_rs_daily_pacing(p_client_id uuid, p_month date)
returns table(report_date date, network text, planned_daily numeric, actual_daily numeric, planned_cum numeric, actual_cum numeric)
language plpgsql stable set search_path = public as $$
declare
  month_end date := (p_month + interval '1 month' - interval '1 day')::date;
begin
  return query
  with days as (select generate_series(p_month, month_end, interval '1 day')::date as d),
  networks as (select unnest(array['google','meta']) as network),
  planned_daily as (
    select d.d as report_date, n.network,
      coalesce(sum(pl.budget_total / nullif(pl.end_date - pl.start_date + 1, 0)), 0) as planned
    from days d cross join networks n
    left join media_plan_lines pl
      on pl.client_id = p_client_id and pl.month = p_month and pl.network = n.network
      and pl.start_date is not null and d.d between pl.start_date and pl.end_date
    group by d.d, n.network
  ),
  actual_daily as (
    select g.report_date, 'google'::text as network, sum(g.spend) as actual
    from google_ads_metrics g where g.client_id = p_client_id and g.report_date between p_month and month_end
    group by g.report_date
    union all
    select m.report_date, 'meta'::text, sum(m.spend)
    from facebook_ads_metrics m where m.client_id = p_client_id and m.report_date between p_month and month_end
    group by m.report_date
  )
  select pd.report_date, pd.network, pd.planned, coalesce(ad.actual, 0),
    sum(pd.planned) over (partition by pd.network order by pd.report_date),
    sum(coalesce(ad.actual, 0)) over (partition by pd.network order by pd.report_date)
  from planned_daily pd
  left join actual_daily ad on ad.report_date = pd.report_date and ad.network = pd.network
  order by pd.network, pd.report_date;
end;
$$;

create or replace function public.fashion_rs_google_pacing(p_client_id uuid, p_month date)
returns table(ad_set_type text, campaign_label text, start_date date, end_date date, budget_total numeric, actual_spend numeric, days_total integer, days_elapsed integer, pct_time_elapsed numeric)
language plpgsql stable set search_path = public as $$
declare
  today date := current_date;
begin
  return query
  with grouped_plan as (
    select pl.ad_set_type,
      string_agg(distinct pl.campaign_label, ' + ' order by pl.campaign_label) as campaign_label,
      pl.start_date, pl.end_date, sum(pl.budget_total) as budget_total
    from media_plan_lines pl
    where pl.month = p_month and pl.client_id = p_client_id and pl.network = 'google' and pl.start_date is not null
    group by pl.ad_set_type, pl.start_date, pl.end_date
  )
  select gp.ad_set_type, gp.campaign_label, gp.start_date, gp.end_date, gp.budget_total,
    coalesce((select sum(g.spend) from google_ads_metrics g
      where g.client_id = p_client_id and g.report_date between gp.start_date and gp.end_date
        and (gp.ad_set_type is null or g.campaign_type = gp.ad_set_type)), 0) as actual_spend,
    (gp.end_date - gp.start_date + 1)::int,
    greatest(0, least(gp.end_date, today) - gp.start_date + 1)::int,
    round(100.0 * greatest(0, least(gp.end_date, today) - gp.start_date + 1) / nullif(gp.end_date - gp.start_date + 1, 0), 1)
  from grouped_plan gp
  order by gp.start_date;
end;
$$;

create or replace function public.fashion_rs_meta_pacing(p_client_id uuid, p_month date)
returns table(bucket text, budget_planned numeric, actual_spend numeric)
language sql stable set search_path = public as $$
  with planned as (
    select fashion_rs_budget_bucket(pl.campaign_label, null) as bucket, sum(pl.budget_total) as budget_planned
    from media_plan_lines pl
    where pl.month = p_month and pl.client_id = p_client_id and pl.network = 'meta'
    group by fashion_rs_budget_bucket(pl.campaign_label, null)
  ),
  actual as (
    select bucket, spend as actual_spend from fashion_rs_ppc_channel_summary(p_client_id, p_month, (p_month + interval '1 month' - interval '1 day')::date)
    where channel = 'meta'
  )
  select coalesce(p.bucket, a.bucket), coalesce(p.budget_planned, 0), coalesce(a.actual_spend, 0)
  from planned p full outer join actual a on p.bucket = a.bucket;
$$;

-- ---------------------------------------------------------------- demo-only: view-based metrics
create or replace function public.demo_video_summary(p_client_id uuid, p_start date, p_end date)
returns table(channel text, campaign text, impressions numeric, reach numeric, video_views numeric, spend numeric)
language sql stable set search_path = public as $$
  select 'google'::text, campaign, sum(impressions), sum(unique_users), sum(video_views), sum(spend)
  from google_ads_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by campaign having sum(video_views) > 0
  union all
  select 'meta'::text, campaign, sum(impressions), sum(reach), sum(video_views), sum(spend)
  from facebook_ads_metrics
  where client_id = p_client_id and report_date between p_start and p_end
  group by campaign having sum(video_views) > 0
  order by 5 desc;
$$;
