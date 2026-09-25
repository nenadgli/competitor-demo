import { useEffect, useMemo, useState } from 'react'
import {
  AreaChart,
  Area,
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  Legend,
  ResponsiveContainer,
  CartesianGrid,
  ReferenceArea,
} from 'recharts'
import { supabase, type Client } from '../lib/supabase'

// DEMO-only page: the extra report set for a large fashion retailer (markets, categories,
// bestsellers, collections, sale calendar, creative fatigue, competition). Backed by the
// demo_* RPCs; shown for clients with vertical = 'fashion'.
const AGENCY_ID = '00000000-0000-0000-0000-000000000001'

const fmtEUR = (n: number) => `€${n.toLocaleString('sr-RS', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`
const fmtEUR2 = (n: number) => `€${n.toLocaleString('sr-RS', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
const fmtInt = (n: number) => n.toLocaleString('sr-RS', { maximumFractionDigits: 0 })
const fmtPct = (n: number, d = 1) => `${n.toLocaleString('sr-RS', { minimumFractionDigits: d, maximumFractionDigits: d })}%`
const fmtSigned = (n: number) => `${n >= 0 ? '+' : '−'}${fmtPct(Math.abs(n))}`
const fmtX = (n: number) => `${n.toLocaleString('sr-RS', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}x`

// Categorical order validated with the dataviz palette checker against the white surface
// (teal, blue, amber, purple). Color follows the entity, never its rank.
const SEASON_META: Record<string, { label: string; color: string }> = {
  core: { label: 'Core asortiman', color: '#0ea678' },
  FW: { label: 'FW26 kolekcija', color: '#3b6fd8' },
  SS: { label: 'Leto (SS26)', color: '#d99a1e' },
  BTS: { label: 'Back to school', color: '#8a6fb0' },
}
const SEASON_ORDER = ['core', 'FW', 'SS', 'BTS']
const COMPETITOR_COLORS = ['#0ea678', '#3b6fd8', '#d99a1e', '#8a6fb0']
const MARKET_LABEL: Record<string, string> = { RS: 'Srbija', HR: 'Hrvatska', BA: 'BiH' }
const EVENT_TYPE_LABEL: Record<string, string> = { sale: 'Sale', launch: 'Lansiranje', holiday: 'Praznik', other: 'Ostalo' }

type MarketRow = { market: string; spend: number; google_spend: number; meta_spend: number; impressions: number; clicks: number; conversions: number; conversion_value: number; sessions: number; total_users: number; new_users: number; ga4_revenue: number }
type CategoryRow = { category: string; spend: number; clicks: number; conversions: number; conversion_value: number; products: number }
type ProductRow = { product_id: string; product_title: string; category: string; season: string; price: number; spend: number; clicks: number; conversions: number; conversion_value: number }
type SeasonRow = { report_date: string; season: string; conversion_value: number }
type EventRow = { name: string; event_type: string; start_date: string; end_date: string; days: number; avg_daily_revenue: number; baseline_daily_revenue: number; revenue_lift_pct: number; avg_daily_spend: number; baseline_daily_spend: number; roas: number | null }
type FatigueRow = { ad_name: string; campaign: string; days_active: number; spend: number; impressions: number; ctr_first: number | null; ctr_last: number | null; ctr_change_pct: number | null }
type CompetitorRow = { competitor: string; domain: string; price_index: number; discount_share: number; new_arrivals: number; active_ads: number; auction_days: number }
type CompPriceRow = { competitor: string; category: string; price_index: number; discount_share: number }
type CompTrendRow = { report_date: string; competitor: string; discount_share: number; active_ads: number; new_arrivals: number }

export default function FashionInsights() {
  const [clients, setClients] = useState<Client[]>([])
  const [selectedId, setSelectedId] = useState('')
  const [range, setRange] = useState<[string, string] | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const [markets, setMarkets] = useState<MarketRow[]>([])
  const [categories, setCategories] = useState<CategoryRow[]>([])
  const [products, setProducts] = useState<ProductRow[]>([])
  const [seasonRows, setSeasonRows] = useState<SeasonRow[]>([])
  const [events, setEvents] = useState<EventRow[]>([])
  const [fatigue, setFatigue] = useState<FatigueRow[]>([])
  const [competitors, setCompetitors] = useState<CompetitorRow[]>([])
  const [compPrices, setCompPrices] = useState<CompPriceRow[]>([])
  const [compTrend, setCompTrend] = useState<CompTrendRow[]>([])

  useEffect(() => {
    async function loadClients() {
      const { data, error: err } = await supabase
        .from('clients').select('*').eq('agency_id', AGENCY_ID).eq('vertical', 'fashion').order('sort_order')
      if (err || !data || data.length === 0) {
        setError('Nijedan fashion klijent nije pronađen.')
        setLoading(false)
        return
      }
      setClients(data)
      setSelectedId(data[0].id)
    }
    loadClients()
  }, [])

  useEffect(() => {
    if (!selectedId) return
    async function findRange() {
      const { data, error: err } = await supabase.rpc('blended_date_range', { p_client_id: selectedId })
      const row = data?.[0]
      if (err || !row?.min_date) {
        setError('Nema podataka za ovog klijenta još uvek.')
        setLoading(false)
        return
      }
      setRange([row.min_date as string, row.max_date as string])
    }
    findRange()
  }, [selectedId])

  useEffect(() => {
    if (!selectedId || !range) return
    async function loadAll() {
      setLoading(true)
      setError(null)
      const p = { p_client_id: selectedId, p_start: range![0], p_end: range![1] }
      const [m, c, pr, s, e, f, co, cp, ct] = await Promise.all([
        supabase.rpc('demo_market_summary', p),
        supabase.rpc('demo_category_summary', p),
        supabase.rpc('demo_top_products', { ...p, p_limit: 12 }),
        supabase.rpc('demo_season_trend', p),
        supabase.rpc('demo_event_impact', p),
        supabase.rpc('demo_creative_fatigue', { ...p, p_limit: 10 }),
        supabase.rpc('demo_competitor_overview', p),
        supabase.rpc('demo_competitor_price_by_category', p),
        supabase.rpc('demo_competitor_trend', p),
      ])
      if (m.error || c.error) {
        setError('Nije moguće učitati fashion izveštaj.')
        setLoading(false)
        return
      }
      setMarkets(((m.data ?? []) as MarketRow[]).filter((r) => r.market !== '—'))
      setCategories(c.data ?? [])
      setProducts(pr.data ?? [])
      setSeasonRows(s.data ?? [])
      setEvents(e.data ?? [])
      setFatigue(f.data ?? [])
      setCompetitors(co.data ?? [])
      setCompPrices(cp.data ?? [])
      setCompTrend(ct.data ?? [])
      setLoading(false)
    }
    loadAll()
  }, [selectedId, range])

  const client = clients.find((c) => c.id === selectedId)

  const totals = useMemo(() => {
    const t = markets.reduce(
      (a, r) => ({ spend: a.spend + r.spend, value: a.value + r.conversion_value, conv: a.conv + r.conversions, ga4: a.ga4 + r.ga4_revenue }),
      { spend: 0, value: 0, conv: 0, ga4: 0 },
    )
    return { ...t, roas: t.spend > 0 ? t.value / t.spend : 0, aov: t.conv > 0 ? t.value / t.conv : 0 }
  }, [markets])

  // Share of product revenue from the FW collection in the last 7 days vs the first 7.
  const fwShare = useMemo(() => {
    if (seasonRows.length === 0) return null
    const dates = [...new Set(seasonRows.map((r) => r.report_date))].sort()
    const share = (ds: string[]) => {
      const rows = seasonRows.filter((r) => ds.includes(r.report_date))
      const all = rows.reduce((a, r) => a + r.conversion_value, 0)
      const fw = rows.filter((r) => r.season === 'FW').reduce((a, r) => a + r.conversion_value, 0)
      return all > 0 ? (fw / all) * 100 : 0
    }
    return { first: share(dates.slice(0, 7)), last: share(dates.slice(-7)) }
  }, [seasonRows])

  const seasonChart = useMemo(() => {
    const byDate: Record<string, Record<string, number | string>> = {}
    seasonRows.forEach((r) => {
      byDate[r.report_date] ??= { date: r.report_date }
      byDate[r.report_date][r.season] = r.conversion_value
    })
    return Object.values(byDate).sort((a, b) => String(a.date).localeCompare(String(b.date)))
  }, [seasonRows])
  const seasons = SEASON_ORDER.filter((s) => seasonRows.some((r) => r.season === s))

  const seasonWeeks = useMemo(() => {
    const dates = [...new Set(seasonRows.map((r) => r.report_date))].sort()
    const sum = (ds: string[], s: string) => seasonRows.filter((r) => r.season === s && ds.includes(r.report_date)).reduce((a, r) => a + r.conversion_value, 0)
    return seasons.map((s) => ({ season: s, first: sum(dates.slice(0, 7), s), last: sum(dates.slice(-7), s) }))
  }, [seasonRows, seasons])

  const competitorNames = useMemo(() => competitors.map((c) => c.competitor).sort(), [competitors])
  const compColor = (name: string) => COMPETITOR_COLORS[competitorNames.indexOf(name) % COMPETITOR_COLORS.length]
  const compChart = useMemo(() => {
    const byDate: Record<string, Record<string, number | string>> = {}
    compTrend.forEach((r) => {
      byDate[r.report_date] ??= { date: r.report_date }
      byDate[r.report_date][r.competitor] = Math.round(r.discount_share * 1000) / 10
    })
    return Object.values(byDate).sort((a, b) => String(a.date).localeCompare(String(b.date)))
  }, [compTrend])
  const priceCategories = useMemo(() => [...new Set(compPrices.map((r) => r.category))], [compPrices])

  const topCategoryValue = categories[0]?.conversion_value || 1
  const totalMarketSpend = totals.spend || 1

  if (error && clients.length === 0) return <p className="text-[var(--color-rust)]">{error}</p>

  return (
    <div>
      <header className="mb-10 flex items-end justify-between border-b border-[var(--color-line)] pb-6">
        <div>
          <p className="eyebrow-label">Fashion insights &middot; tržišta, asortiman, kolekcije, konkurencija</p>
          <h1 className="font-display mt-1 text-4xl font-medium">{client?.name ?? '…'}</h1>
          <p className="mt-2 text-[var(--color-ink-soft)]">
            {range ? `Period: ${range[0].slice(5)} – ${range[1].slice(5)}` : 'Učitavanje perioda…'}
            {client?.tagline && <span className="template-chip">{client.tagline}</span>}
          </p>
        </div>
        {clients.length > 1 && (
          <label className="text-sm">
            <span className="mr-2 text-[var(--color-ink-soft)]">Klijent</span>
            <select value={selectedId} onChange={(e) => setSelectedId(e.target.value)} className="rounded border border-[var(--color-line)] bg-white px-3 py-1.5">
              {clients.map((c) => (
                <option key={c.id} value={c.id}>{c.name}</option>
              ))}
            </select>
          </label>
        )}
      </header>

      {error && <p className="text-[var(--color-rust)]">{error}</p>}
      {loading && !error && <p className="text-[var(--color-ink-soft)]">Učitavanje…</p>}

      {!loading && !error && (
        <>
          <section className="mb-12 kpi-grid grid-cols-4">
            <div className="kpi-card">
              <p className="kpi-label">Prihod iz oglasa (platforme)</p>
              <p className="kpi-value">{fmtEUR(totals.value)}</p>
            </div>
            <div className="kpi-card">
              <p className="kpi-label">Blended ROAS</p>
              <p className="kpi-value">{fmtX(totals.roas)}</p>
            </div>
            <div className="kpi-card">
              <p className="kpi-label">Prosečna korpa (AOV)</p>
              <p className="kpi-value">{fmtEUR2(totals.aov)}</p>
            </div>
            <div className="kpi-card kpi-dark">
              <p className="kpi-label">FW26 udeo u prodaji (poslednjih 7 dana)</p>
              <p className="kpi-value">{fwShare ? fmtPct(fwShare.last, 0) : '—'}</p>
              {fwShare && <p className="mt-1 font-mono text-xs text-white/70">prvih 7 dana: {fmtPct(fwShare.first, 0)}</p>}
            </div>
          </section>

          {/* 1. Markets */}
          <section className="mb-12">
            <h2 className="font-display mb-1 text-lg font-medium">Tržišta</h2>
            <p className="mb-4 text-xs text-[var(--color-ink-soft)]">
              Tržište se čita iz <span className="font-mono">Mkt:</span> taga u nazivu kampanje (oglasi) i iz GA4 prodavnice (sajt). GA4 prihod
              uključuje i organski, direktni i owned saobraćaj.
            </p>
            <table className="w-full border-collapse text-sm">
              <thead>
                <tr className="border-b border-[var(--color-line)] text-left text-[var(--color-ink-soft)]">
                  <th className="py-2 pr-3 font-normal">Tržište</th>
                  <th className="py-2 pr-3 font-normal">Udeo budžeta</th>
                  <th className="py-2 pr-3 text-right font-normal">Potrošnja</th>
                  <th className="py-2 pr-3 text-right font-normal">Google / Meta</th>
                  <th className="py-2 pr-3 text-right font-normal">Kupovine</th>
                  <th className="py-2 pr-3 text-right font-normal">ROAS</th>
                  <th className="py-2 pr-3 text-right font-normal">CPA</th>
                  <th className="py-2 pr-3 text-right font-normal">AOV</th>
                  <th className="py-2 pr-3 text-right font-normal">GA4 prihod</th>
                  <th className="py-2 text-right font-normal">Novi korisnici</th>
                </tr>
              </thead>
              <tbody>
                {markets.map((r) => {
                  const share = (r.spend / totalMarketSpend) * 100
                  return (
                    <tr key={r.market} className="border-b border-[var(--color-line)]">
                      <td className="py-2.5 pr-3 font-medium">{MARKET_LABEL[r.market] ?? r.market} <span className="font-mono text-xs text-[var(--color-ink-soft)]">{r.market}</span></td>
                      <td className="py-2.5 pr-3">
                        <div className="flex items-center gap-2">
                          <div className="h-1.5 w-24 bg-[var(--color-indigo-soft)]">
                            <div className="h-1.5 rounded-r bg-[var(--color-indigo)]" style={{ width: `${share}%` }} />
                          </div>
                          <span className="font-mono text-xs text-[var(--color-ink-soft)]">{fmtPct(share, 0)}</span>
                        </div>
                      </td>
                      <td className="py-2.5 pr-3 text-right font-mono">{fmtEUR(r.spend)}</td>
                      <td className="py-2.5 pr-3 text-right font-mono text-[var(--color-ink-soft)]">{fmtPct((r.google_spend / (r.spend || 1)) * 100, 0)} / {fmtPct((r.meta_spend / (r.spend || 1)) * 100, 0)}</td>
                      <td className="py-2.5 pr-3 text-right font-mono">{fmtInt(r.conversions)}</td>
                      <td className="py-2.5 pr-3 text-right font-mono">{r.spend > 0 ? fmtX(r.conversion_value / r.spend) : '—'}</td>
                      <td className="py-2.5 pr-3 text-right font-mono">{r.conversions > 0 ? fmtEUR2(r.spend / r.conversions) : '—'}</td>
                      <td className="py-2.5 pr-3 text-right font-mono">{r.conversions > 0 ? fmtEUR2(r.conversion_value / r.conversions) : '—'}</td>
                      <td className="py-2.5 pr-3 text-right font-mono">{fmtEUR(r.ga4_revenue)}</td>
                      <td className="py-2.5 text-right font-mono">{r.total_users > 0 ? fmtPct((r.new_users / r.total_users) * 100, 0) : '—'}</td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </section>

          {/* 2. Categories + 3. bestsellers */}
          <div className="mb-12 grid grid-cols-2 gap-10">
            <section>
              <h2 className="font-display mb-1 text-lg font-medium">Kategorije</h2>
              <p className="mb-4 text-xs text-[var(--color-ink-soft)]">Prihod iz Shopping i Performance Max kampanja po kategoriji proizvoda (product feed).</p>
              <div className="space-y-3">
                {categories.map((r) => (
                  <div key={r.category}>
                    <div className="mb-1 flex justify-between text-sm">
                      <span>{r.category} <span className="text-xs text-[var(--color-ink-soft)]">&middot; {r.products} proizvoda</span></span>
                      <span className="font-mono text-[var(--color-ink-soft)]">{fmtEUR(r.conversion_value)} &middot; ROAS {fmtX(r.spend > 0 ? r.conversion_value / r.spend : 0)}</span>
                    </div>
                    <div className="h-1.5 w-full bg-[var(--color-indigo-soft)]">
                      <div className="h-1.5 rounded-r bg-[var(--color-indigo)]" style={{ width: `${(r.conversion_value / topCategoryValue) * 100}%` }} />
                    </div>
                  </div>
                ))}
              </div>
            </section>

            <section>
              <h2 className="font-display mb-1 text-lg font-medium">Bestseleri</h2>
              <p className="mb-4 text-xs text-[var(--color-ink-soft)]">Top proizvodi po prihodu iz oglasa, sa kolekcijom kojoj pripadaju.</p>
              <table className="w-full border-collapse text-sm">
                <thead>
                  <tr className="border-b border-[var(--color-line)] text-left text-[var(--color-ink-soft)]">
                    <th className="py-2 pr-3 font-normal">Proizvod</th>
                    <th className="py-2 pr-3 font-normal">Kolekcija</th>
                    <th className="py-2 pr-3 text-right font-normal">Kupovine</th>
                    <th className="py-2 text-right font-normal">Prihod</th>
                  </tr>
                </thead>
                <tbody>
                  {products.map((r) => (
                    <tr key={r.product_id} className="border-b border-[var(--color-line)]">
                      <td className="py-2 pr-3">
                        {r.product_title}
                        <span className="block font-mono text-xs text-[var(--color-ink-soft)]">{r.product_id} &middot; {r.category}</span>
                      </td>
                      <td className="py-2 pr-3">
                        <span className="inline-flex items-center gap-1.5 whitespace-nowrap text-xs">
                          <span className="h-2 w-2 rounded-full" style={{ background: SEASON_META[r.season]?.color }} />
                          {SEASON_META[r.season]?.label ?? r.season}
                        </span>
                      </td>
                      <td className="py-2 pr-3 text-right font-mono">{fmtInt(r.conversions)}</td>
                      <td className="py-2 text-right font-mono">{fmtEUR(r.conversion_value)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </section>
          </div>

          {/* 4. Collections & season */}
          <section className="mb-12">
            <h2 className="font-display mb-1 text-lg font-medium">Kolekcije i sezona</h2>
            <p className="mb-4 text-xs text-[var(--color-ink-soft)]">
              Dnevni prihod iz oglasa po kolekciji. Osenčeni periodi su akcije i lansiranja iz kalendara ispod.
            </p>
            <div className="h-72 rounded border border-[var(--color-line)] bg-white p-4">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={seasonChart}>
                  <CartesianGrid stroke="var(--color-line)" vertical={false} />
                  <XAxis dataKey="date" tickFormatter={(d) => String(d).slice(5)} tick={{ fontSize: 12, fill: 'var(--color-ink-soft)' }} axisLine={{ stroke: 'var(--color-line)' }} tickLine={false} />
                  <YAxis tickFormatter={(v) => fmtEUR(Number(v))} tick={{ fontSize: 12, fill: 'var(--color-ink-soft)' }} axisLine={false} tickLine={false} width={70} />
                  <Tooltip contentStyle={{ fontSize: 13, borderRadius: 4, border: '1px solid var(--color-line)' }} formatter={(v, name) => [fmtEUR(Number(v)), SEASON_META[String(name)]?.label ?? name]} />
                  <Legend wrapperStyle={{ fontSize: 12 }} formatter={(v) => SEASON_META[String(v)]?.label ?? v} />
                  {events.map((e) => (
                    <ReferenceArea key={e.name} x1={e.start_date} x2={e.end_date} fill="var(--color-ink-soft)" fillOpacity={0.07} ifOverflow="extendDomain" />
                  ))}
                  {seasons.map((s) => (
                    <Area key={s} type="monotone" dataKey={s} stackId="1" stroke={SEASON_META[s].color} strokeWidth={2} fill={SEASON_META[s].color} fillOpacity={0.85} />
                  ))}
                </AreaChart>
              </ResponsiveContainer>
            </div>
            <table className="mt-4 w-full max-w-2xl border-collapse text-sm">
              <thead>
                <tr className="border-b border-[var(--color-line)] text-left text-[var(--color-ink-soft)]">
                  <th className="py-2 pr-3 font-normal">Kolekcija</th>
                  <th className="py-2 pr-3 text-right font-normal">Prvih 7 dana</th>
                  <th className="py-2 pr-3 text-right font-normal">Poslednjih 7 dana</th>
                  <th className="py-2 text-right font-normal">Promena</th>
                </tr>
              </thead>
              <tbody>
                {seasonWeeks.map((r) => (
                  <tr key={r.season} className="border-b border-[var(--color-line)]">
                    <td className="py-2 pr-3">
                      <span className="inline-flex items-center gap-1.5">
                        <span className="h-2 w-2 rounded-full" style={{ background: SEASON_META[r.season].color }} />
                        {SEASON_META[r.season].label}
                      </span>
                    </td>
                    <td className="py-2 pr-3 text-right font-mono">{fmtEUR(r.first)}</td>
                    <td className="py-2 pr-3 text-right font-mono">{fmtEUR(r.last)}</td>
                    <td className="py-2 text-right font-mono">{r.first > 0 ? fmtSigned((r.last / r.first - 1) * 100) : '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </section>

          {/* 5. Sale calendar impact */}
          <section className="mb-12">
            <h2 className="font-display mb-1 text-lg font-medium">Sale kalendar i efekat akcija</h2>
            <p className="mb-4 text-xs text-[var(--color-ink-soft)]">
              Prosečan dnevni prihod na sajtu (GA4, svi kanali) tokom akcije naspram prosečnog dana van akcija.
            </p>
            <table className="w-full border-collapse text-sm">
              <thead>
                <tr className="border-b border-[var(--color-line)] text-left text-[var(--color-ink-soft)]">
                  <th className="py-2 pr-3 font-normal">Događaj</th>
                  <th className="py-2 pr-3 font-normal">Tip</th>
                  <th className="py-2 pr-3 font-normal">Period</th>
                  <th className="py-2 pr-3 text-right font-normal">Prihod / dan</th>
                  <th className="py-2 pr-3 text-right font-normal">Van akcija / dan</th>
                  <th className="py-2 pr-3 text-right font-normal">Lift</th>
                  <th className="py-2 pr-3 text-right font-normal">Potrošnja / dan</th>
                  <th className="py-2 text-right font-normal">ROAS</th>
                </tr>
              </thead>
              <tbody>
                {events.map((e) => (
                  <tr key={e.name} className="border-b border-[var(--color-line)]">
                    <td className="py-2.5 pr-3 font-medium">{e.name}</td>
                    <td className="py-2.5 pr-3 text-[var(--color-ink-soft)]">{EVENT_TYPE_LABEL[e.event_type] ?? e.event_type}</td>
                    <td className="py-2.5 pr-3 font-mono text-xs text-[var(--color-ink-soft)]">{e.start_date.slice(5)} – {e.end_date.slice(5)} ({e.days} d)</td>
                    <td className="py-2.5 pr-3 text-right font-mono">{fmtEUR(e.avg_daily_revenue)}</td>
                    <td className="py-2.5 pr-3 text-right font-mono text-[var(--color-ink-soft)]">{fmtEUR(e.baseline_daily_revenue)}</td>
                    <td className="py-2.5 pr-3 text-right font-mono font-semibold">{fmtSigned(e.revenue_lift_pct)}</td>
                    <td className="py-2.5 pr-3 text-right font-mono">{fmtEUR(e.avg_daily_spend)}</td>
                    <td className="py-2.5 text-right font-mono">{e.roas != null ? fmtX(e.roas) : '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </section>

          {/* 6. Creative fatigue */}
          <section className="mb-12">
            <h2 className="font-display mb-1 text-lg font-medium">Kreative i umor kreativa (Meta)</h2>
            <p className="mb-4 text-xs text-[var(--color-ink-soft)]">
              CTR u prvih 7 aktivnih dana kreative naspram poslednjih 7. Pad veći od 25% = kreativu treba osvežiti ili zameniti.
            </p>
            <table className="w-full border-collapse text-sm">
              <thead>
                <tr className="border-b border-[var(--color-line)] text-left text-[var(--color-ink-soft)]">
                  <th className="py-2 pr-3 font-normal">Kreativa</th>
                  <th className="py-2 pr-3 text-right font-normal">Dana aktivna</th>
                  <th className="py-2 pr-3 text-right font-normal">Potrošnja</th>
                  <th className="py-2 pr-3 text-right font-normal">CTR prvih 7</th>
                  <th className="py-2 pr-3 text-right font-normal">CTR poslednjih 7</th>
                  <th className="py-2 pr-3 text-right font-normal">Promena</th>
                  <th className="py-2 font-normal">Status</th>
                </tr>
              </thead>
              <tbody>
                {fatigue.map((r) => {
                  const chg = r.ctr_change_pct ?? 0
                  const status = chg <= -25 ? { label: '⚠ Umor kreative', color: 'var(--color-rust)' } : chg <= -10 ? { label: '↘ Pratiti', color: '#b7791f' } : { label: '✓ Stabilna', color: 'var(--color-indigo)' }
                  return (
                    <tr key={r.ad_name} className="border-b border-[var(--color-line)]">
                      <td className="py-2 pr-3 max-w-[260px] truncate" title={`${r.ad_name} · ${r.campaign}`}>
                        {r.ad_name}
                        <span className="block truncate text-xs text-[var(--color-ink-soft)]">{r.campaign}</span>
                      </td>
                      <td className="py-2 pr-3 text-right font-mono">{r.days_active}</td>
                      <td className="py-2 pr-3 text-right font-mono">{fmtEUR(r.spend)}</td>
                      <td className="py-2 pr-3 text-right font-mono">{r.ctr_first != null ? fmtPct(r.ctr_first, 2) : '—'}</td>
                      <td className="py-2 pr-3 text-right font-mono">{r.ctr_last != null ? fmtPct(r.ctr_last, 2) : '—'}</td>
                      <td className="py-2 pr-3 text-right font-mono">{r.ctr_change_pct != null ? fmtSigned(r.ctr_change_pct) : '—'}</td>
                      <td className="py-2 text-xs font-medium" style={{ color: status.color }}>{status.label}</td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </section>

          {/* 7. Competition */}
          <section className="mb-4">
            <h2 className="font-display mb-1 text-lg font-medium">Konkurencija</h2>
            <p className="mb-4 text-xs text-[var(--color-ink-soft)]">
              Cenovni indeks: prosečna cena konkurenta za uporedive artikle, gde je {client?.name?.split(' · ')[0] ?? 'klijent'} = 1,00 (ispod 1 = konkurent je jeftiniji).
              Novi artikli i aktivni oglasi iz praćenja sajtova i Meta Ad Library; aukcije iz Google Ads auction insights.
            </p>
            <table className="mb-6 w-full border-collapse text-sm">
              <thead>
                <tr className="border-b border-[var(--color-line)] text-left text-[var(--color-ink-soft)]">
                  <th className="py-2 pr-3 font-normal">Konkurent</th>
                  <th className="py-2 pr-3 text-right font-normal">Cenovni indeks</th>
                  <th className="py-2 pr-3 text-right font-normal">Asortiman na popustu</th>
                  <th className="py-2 pr-3 text-right font-normal">Novi artikli</th>
                  <th className="py-2 pr-3 text-right font-normal">Aktivni oglasi (prosek)</th>
                  <th className="py-2 text-right font-normal">Dana u istim aukcijama</th>
                </tr>
              </thead>
              <tbody>
                {competitors.map((r) => (
                  <tr key={r.competitor} className="border-b border-[var(--color-line)]">
                    <td className="py-2.5 pr-3">
                      <span className="inline-flex items-center gap-1.5 font-medium">
                        <span className="h-2 w-2 rounded-full" style={{ background: compColor(r.competitor) }} />
                        {r.competitor}
                      </span>
                      <span className="block font-mono text-xs text-[var(--color-ink-soft)]">{r.domain}</span>
                    </td>
                    <td className="py-2.5 pr-3 text-right font-mono">{r.price_index.toLocaleString('sr-RS', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>
                    <td className="py-2.5 pr-3 text-right font-mono">{fmtPct(r.discount_share * 100, 0)}</td>
                    <td className="py-2.5 pr-3 text-right font-mono">{fmtInt(r.new_arrivals)}</td>
                    <td className="py-2.5 pr-3 text-right font-mono">{fmtInt(r.active_ads)}</td>
                    <td className="py-2.5 text-right font-mono">{r.auction_days}</td>
                  </tr>
                ))}
              </tbody>
            </table>

            <div className="grid grid-cols-2 gap-8">
              <div>
                <p className="mb-2 text-sm font-medium text-[var(--color-ink-soft)]">Udeo asortimana na popustu, po danu</p>
                <div className="h-64 rounded border border-[var(--color-line)] bg-white p-3">
                  <ResponsiveContainer width="100%" height="100%">
                    <LineChart data={compChart}>
                      <CartesianGrid stroke="var(--color-line)" vertical={false} />
                      <XAxis dataKey="date" tickFormatter={(d) => String(d).slice(5)} tick={{ fontSize: 11, fill: 'var(--color-ink-soft)' }} axisLine={{ stroke: 'var(--color-line)' }} tickLine={false} />
                      <YAxis tickFormatter={(v) => `${v}%`} tick={{ fontSize: 11, fill: 'var(--color-ink-soft)' }} axisLine={false} tickLine={false} width={40} />
                      <Tooltip contentStyle={{ fontSize: 12, borderRadius: 4, border: '1px solid var(--color-line)' }} formatter={(v) => `${Number(v).toLocaleString('sr-RS')}%`} />
                      <Legend wrapperStyle={{ fontSize: 11 }} />
                      {competitorNames.map((n) => (
                        <Line key={n} type="monotone" dataKey={n} stroke={compColor(n)} strokeWidth={2} dot={false} />
                      ))}
                    </LineChart>
                  </ResponsiveContainer>
                </div>
              </div>
              <div>
                <p className="mb-2 text-sm font-medium text-[var(--color-ink-soft)]">Cenovni indeks po kategoriji</p>
                <table className="w-full border-collapse text-sm">
                  <thead>
                    <tr className="border-b border-[var(--color-line)] text-left text-[var(--color-ink-soft)]">
                      <th className="py-2 pr-2 font-normal">Kategorija</th>
                      {competitorNames.map((n) => (
                        <th key={n} className="py-2 pr-2 text-right font-normal">{n}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {priceCategories.map((cat) => (
                      <tr key={cat} className="border-b border-[var(--color-line)]">
                        <td className="py-2 pr-2">{cat}</td>
                        {competitorNames.map((n) => {
                          const v = compPrices.find((r) => r.competitor === n && r.category === cat)?.price_index
                          return (
                            <td key={n} className="py-2 pr-2 text-right font-mono" style={{ color: v != null && v < 0.9 ? 'var(--color-rust)' : undefined }}>
                              {v != null ? v.toLocaleString('sr-RS', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : '—'}
                            </td>
                          )
                        })}
                      </tr>
                    ))}
                  </tbody>
                </table>
                <p className="mt-2 text-xs text-[var(--color-ink-soft)]">Crveno = konkurent je više od 10% jeftiniji u toj kategoriji.</p>
              </div>
            </div>
          </section>
        </>
      )}
    </div>
  )
}
