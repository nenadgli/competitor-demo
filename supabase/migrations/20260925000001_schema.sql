-- Brain Reporting DEMO — schema.
-- Mirrors the production brain-reporting schema table for table, plus a few
-- demo-only columns (clients.business_type / sort_order / tagline and
-- video_views on the ad tables) that let the UI tell the four business
-- templates apart.

create table public.agencies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table public.clients (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id) on delete cascade,
  name text not null,
  slug text not null unique,
  created_at timestamptz not null default now(),
  enable_bare_adset_revenue_match boolean not null default false,
  -- demo-only
  business_type text not null default 'ecommerce'
    check (business_type in ('ecommerce', 'leadgen', 'app', 'awareness')),
  sort_order int not null default 0,
  tagline text
);

create table public.app_users (
  id uuid primary key references auth.users(id) on delete cascade,
  agency_id uuid not null references public.agencies(id) on delete cascade,
  client_id uuid references public.clients(id) on delete cascade,
  role text not null default 'client_viewer'
    check (role in ('agency_admin', 'agency_member', 'client_viewer')),
  email text not null,
  created_at timestamptz not null default now()
);

create table public.data_sources (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  -- The report pages filter on these exact strings.
  provider text not null check (provider in ('google_ads', 'facebook', 'ga4')),
  windsor_connection_id text,
  status text not null default 'pending' check (status in ('pending', 'syncing', 'active', 'error')),
  last_synced_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.report_metrics (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  data_source_id uuid references public.data_sources(id) on delete set null,
  report_date date not null,
  channel text not null,
  metric_name text not null,
  metric_value numeric not null default 0,
  created_at timestamptz not null default now(),
  campaign text
);

create table public.google_ads_metrics (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  data_source_id uuid references public.data_sources(id) on delete set null,
  report_date date not null,
  campaign text not null,
  campaign_type text,
  device text,
  impressions numeric not null default 0,
  clicks numeric not null default 0,
  spend numeric not null default 0,
  conversions numeric not null default 0,
  conversion_value numeric not null default 0,
  search_impression_share numeric,
  search_lost_is_budget numeric,
  search_lost_is_rank numeric,
  quality_score numeric,
  created_at timestamptz not null default now(),
  unique_users numeric default 0,
  video_views numeric not null default 0
);

create table public.google_ads_keywords (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  data_source_id uuid references public.data_sources(id) on delete set null,
  report_date date not null,
  campaign text not null,
  keyword_text text not null,
  keyword_match_type text,
  impressions numeric not null default 0,
  clicks numeric not null default 0,
  spend numeric not null default 0,
  conversions numeric not null default 0,
  conversion_value numeric not null default 0,
  quality_score numeric,
  created_at timestamptz not null default now()
);

create table public.google_ads_search_terms (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  data_source_id uuid references public.data_sources(id) on delete set null,
  report_date date not null,
  campaign text not null,
  search_term text not null,
  impressions numeric not null default 0,
  clicks numeric not null default 0,
  spend numeric not null default 0,
  conversions numeric not null default 0,
  created_at timestamptz not null default now()
);

create table public.google_ads_competitors (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  data_source_id uuid references public.data_sources(id) on delete set null,
  report_date date not null,
  campaign text not null,
  domain text not null,
  created_at timestamptz not null default now()
);

create table public.google_ad_group_metrics (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  data_source_id uuid references public.data_sources(id) on delete set null,
  report_date date not null,
  campaign text not null,
  ad_group_name text,
  impressions numeric not null default 0,
  clicks numeric not null default 0,
  spend numeric not null default 0,
  conversions numeric not null default 0,
  conversion_value numeric not null default 0,
  created_at timestamptz not null default now(),
  unique_users numeric default 0
);

create table public.google_asset_group_metrics (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  data_source_id uuid references public.data_sources(id) on delete set null,
  report_date date not null,
  campaign text not null,
  asset_group_name text,
  impressions numeric not null default 0,
  clicks numeric not null default 0,
  spend numeric not null default 0,
  conversions numeric not null default 0,
  conversion_value numeric not null default 0,
  created_at timestamptz not null default now(),
  unique_users numeric default 0
);

create table public.facebook_ads_metrics (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  data_source_id uuid references public.data_sources(id) on delete set null,
  report_date date not null,
  campaign text not null,
  objective text,
  impressions numeric not null default 0,
  clicks numeric not null default 0,
  spend numeric not null default 0,
  reach numeric not null default 0,
  frequency numeric,
  conversions numeric not null default 0,
  conversion_value numeric not null default 0,
  roas numeric,
  created_at timestamptz not null default now(),
  video_views numeric not null default 0
);

create table public.meta_ad_set_metrics (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  data_source_id uuid references public.data_sources(id) on delete set null,
  report_date date not null,
  campaign text not null,
  adset_name text,
  impressions numeric not null default 0,
  clicks numeric not null default 0,
  spend numeric not null default 0,
  conversions numeric not null default 0,
  conversion_value numeric not null default 0,
  created_at timestamptz not null default now(),
  reach numeric default 0
);

create table public.facebook_ads_placements (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  data_source_id uuid references public.data_sources(id) on delete set null,
  report_date date not null,
  campaign text not null,
  device_platform text,
  publisher_platform text,
  impressions numeric not null default 0,
  clicks numeric not null default 0,
  spend numeric not null default 0,
  reach numeric not null default 0,
  created_at timestamptz not null default now()
);

create table public.facebook_ads_creatives (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  data_source_id uuid references public.data_sources(id) on delete set null,
  report_date date not null,
  campaign text not null,
  adset_name text,
  ad_name text,
  impressions numeric not null default 0,
  clicks numeric not null default 0,
  spend numeric not null default 0,
  created_at timestamptz not null default now()
);

create table public.ga4_metrics (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  data_source_id uuid references public.data_sources(id) on delete set null,
  report_date date not null,
  source text,
  campaign text,
  store text,
  sessions numeric not null default 0,
  total_users numeric not null default 0,
  new_users numeric not null default 0,
  engaged_sessions numeric not null default 0,
  engagement_rate numeric,
  bounce_rate numeric,
  conversions numeric not null default 0,
  total_revenue numeric not null default 0,
  created_at timestamptz not null default now(),
  medium text
);

create table public.media_plan_lines (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  month date not null,
  network text not null,
  flight_type text not null,
  ad_set_type text,
  campaign_label text not null,
  start_date date,
  end_date date,
  budget_regular numeric not null default 0,
  budget_flash numeric not null default 0,
  budget_total numeric not null default 0,
  created_at timestamptz not null default now()
);

create table public.fashion_rs_report_rows (
  id uuid primary key default gen_random_uuid(),
  row_order int not null,
  row_label text not null,
  channel text not null,
  level text not null check (level in ('campaign', 'meta_ad_set', 'google_ad_group', 'asset_group')),
  campaign_names text[] not null,
  note text,
  client_id uuid not null references public.clients(id) on delete cascade
);

-- Every report query filters on (client_id, report_date).
create index on public.report_metrics (client_id, report_date);
create index on public.google_ads_metrics (client_id, report_date);
create index on public.google_ads_keywords (client_id, report_date);
create index on public.google_ads_search_terms (client_id, report_date);
create index on public.google_ads_competitors (client_id, report_date);
create index on public.google_ad_group_metrics (client_id, report_date);
create index on public.google_asset_group_metrics (client_id, report_date);
create index on public.facebook_ads_metrics (client_id, report_date);
create index on public.meta_ad_set_metrics (client_id, report_date);
create index on public.facebook_ads_placements (client_id, report_date);
create index on public.facebook_ads_creatives (client_id, report_date);
create index on public.ga4_metrics (client_id, report_date);
create index on public.media_plan_lines (client_id, month);
create index on public.fashion_rs_report_rows (client_id);
create index on public.data_sources (client_id);
create index on public.clients (agency_id);
