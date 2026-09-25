-- Typo inherited from production: "Napušteta" -> "Napuštena".
create or replace function public.owned_channel_type_summary(p_client_id uuid, p_start date, p_end date, p_source text)
returns table(campaign_type text, sessions numeric, total_users numeric, conversions numeric, total_revenue numeric, campaign_count bigint)
language sql stable set search_path = public as $$
  select
    case
      when p_source = 'newsletter' and campaign ilike 'AbandCart%' then 'Napuštena korpa (automatizacija)'
      when p_source = 'newsletter' then 'Broadcast newsletter'
      else 'Push kampanja'
    end,
    sum(sessions), sum(total_users), sum(conversions), sum(total_revenue), count(distinct campaign)
  from ga4_metrics
  where client_id = p_client_id and report_date between p_start and p_end and source = p_source
  group by 1
  order by sum(total_revenue) desc;
$$;
