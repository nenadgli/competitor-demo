-- Brain Reporting DEMO — access model.
--
-- Production scopes every row to the logged-in agency/client via app_users.
-- This project only ever holds generated demo data, so it runs as a public,
-- read-only demo: anon and authenticated may SELECT the report tables and
-- nothing may be written through the API. Data is (re)loaded exclusively by
-- the demo_seed() function, which runs as the table owner.

alter table public.data_sources add constraint data_sources_client_provider_key unique (client_id, provider);

do $$
declare
  t text;
begin
  foreach t in array array[
    'agencies', 'clients', 'app_users', 'data_sources', 'report_metrics',
    'google_ads_metrics', 'google_ads_keywords', 'google_ads_search_terms', 'google_ads_competitors',
    'google_ad_group_metrics', 'google_asset_group_metrics',
    'facebook_ads_metrics', 'meta_ad_set_metrics', 'facebook_ads_placements', 'facebook_ads_creatives',
    'ga4_metrics', 'media_plan_lines', 'fashion_rs_report_rows'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke insert, update, delete, truncate on public.%I from anon, authenticated', t);
    -- app_users stays closed: no policy means no rows for anyone.
    if t <> 'app_users' then
      execute format('create policy "demo public read" on public.%I for select to anon, authenticated using (true)', t);
    end if;
  end loop;
end $$;
