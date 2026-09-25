import { createClient } from '@supabase/supabase-js'

// DEMO project (competitors demo). It only holds generated data and every table is
// read-only for the public key, so the key is safe to ship as a fallback — this
// lets the Vercel project build without any environment variables.
const DEMO_URL = 'https://cxzgnhfcndlzmfnyqajp.supabase.co'
const DEMO_PUBLISHABLE_KEY = 'sb_publishable_AD7-RFwUjKbLR1yFtdNDTg_NhjjA9WI'

export const SUPABASE_URL = (import.meta.env.VITE_SUPABASE_URL as string | undefined) || DEMO_URL
const anonKey = (import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined) || DEMO_PUBLISHABLE_KEY

export const supabase = createClient(SUPABASE_URL, anonKey, {
  auth: { persistSession: false, autoRefreshToken: false },
})

export type BusinessType = 'ecommerce' | 'leadgen' | 'app' | 'awareness'

export type Client = {
  id: string
  agency_id: string
  name: string
  slug: string
  business_type?: BusinessType
  sort_order?: number
  tagline?: string | null
}

export type ReportMetric = {
  id: string
  client_id: string
  report_date: string
  channel: string
  campaign: string | null
  metric_name: string
  metric_value: number
}

export type GoogleAdsMetric = {
  id: string
  client_id: string
  report_date: string
  campaign: string
  campaign_type: string | null
  device: string | null
  impressions: number
  clicks: number
  spend: number
  conversions: number
  conversion_value: number
  search_impression_share: number | null
  search_lost_is_budget: number | null
  search_lost_is_rank: number | null
  quality_score: number | null
}

export type GoogleAdsKeyword = {
  id: string
  client_id: string
  report_date: string
  campaign: string
  keyword_text: string
  keyword_match_type: string | null
  impressions: number
  clicks: number
  spend: number
  conversions: number
  conversion_value: number
  quality_score: number | null
}

export type GoogleAdsSearchTerm = {
  id: string
  client_id: string
  report_date: string
  campaign: string
  search_term: string
  impressions: number
  clicks: number
  spend: number
  conversions: number
}

export type GoogleAdsCompetitor = {
  id: string
  client_id: string
  report_date: string
  campaign: string
  domain: string
}

// Facebook Ads types are handled via RPC return rows typed inline in FacebookAdsReport.tsx

// PostgREST returns at most 1000 rows per request. report_metrics holds one row per
// campaign/day/metric, so a month for all demo clients is well over that — page
// through it instead of silently truncating.
export async function fetchReportMetrics(clientIds: string[]): Promise<{ data: ReportMetric[]; error: unknown }> {
  const pageSize = 1000
  const rows: ReportMetric[] = []
  for (let from = 0; ; from += pageSize) {
    const { data, error } = await supabase
      .from('report_metrics')
      .select('*')
      .in('client_id', clientIds)
      .order('report_date', { ascending: true })
      .order('id', { ascending: true })
      .range(from, from + pageSize - 1)
    if (error) return { data: rows, error }
    rows.push(...((data ?? []) as ReportMetric[]))
    if (!data || data.length < pageSize) return { data: rows, error: null }
  }
}
