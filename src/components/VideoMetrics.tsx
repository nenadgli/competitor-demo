import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'

// Demo-only: view-based metrics for video / reach campaigns (YouTube views,
// Meta ThruPlays). Renders nothing when the client has no video views, so it
// only shows up where it tells a story (mainly the awareness template).
type Row = { channel: string; campaign: string; impressions: number; reach: number; video_views: number; spend: number }

const fmtEUR = (n: number, d = 2) => `€${n.toLocaleString('sr-RS', { minimumFractionDigits: d, maximumFractionDigits: d })}`
const fmtInt = (n: number) => n.toLocaleString('sr-RS', { maximumFractionDigits: 0 })
const fmtPct = (n: number) => `${n.toLocaleString('sr-RS', { minimumFractionDigits: 1, maximumFractionDigits: 1 })}%`

export default function VideoMetrics({ clientId, start, end, channel }: { clientId: string; start: string; end: string; channel: 'google' | 'meta' }) {
  const [rows, setRows] = useState<Row[]>([])

  useEffect(() => {
    let cancelled = false
    supabase.rpc('demo_video_summary', { p_client_id: clientId, p_start: start, p_end: end }).then(({ data }) => {
      if (!cancelled) setRows(((data ?? []) as Row[]).filter((r) => r.channel === channel))
    })
    return () => {
      cancelled = true
    }
  }, [clientId, start, end, channel])

  if (rows.length === 0) return null

  const t = rows.reduce(
    (a, r) => ({ impressions: a.impressions + r.impressions, views: a.views + r.video_views, spend: a.spend + r.spend }),
    { impressions: 0, views: 0, spend: 0 },
  )
  const viewLabel = channel === 'meta' ? 'ThruPlay pregledi' : 'Video pregledi'

  return (
    <section className="mb-10">
      <h2 className="font-display mb-4 text-lg font-medium">Video i view-based metrike</h2>
      <div className="kpi-grid mb-4 grid-cols-4">
        <div className="kpi-card kpi-dark">
          <p className="kpi-label">{viewLabel}</p>
          <p className="kpi-value">{fmtInt(t.views)}</p>
        </div>
        <div className="kpi-card kpi-dark">
          <p className="kpi-label">View rate (VTR)</p>
          <p className="kpi-value">{fmtPct(t.impressions > 0 ? (t.views / t.impressions) * 100 : 0)}</p>
        </div>
        <div className="kpi-card kpi-dark">
          <p className="kpi-label">CPV</p>
          <p className="kpi-value">{fmtEUR(t.views > 0 ? t.spend / t.views : 0, 3)}</p>
        </div>
        <div className="kpi-card kpi-dark">
          <p className="kpi-label">CPM (video kampanje)</p>
          <p className="kpi-value">{fmtEUR(t.impressions > 0 ? (t.spend / t.impressions) * 1000 : 0)}</p>
        </div>
      </div>
      <table className="w-full border-collapse text-sm">
        <thead>
          <tr className="border-b border-[var(--color-line)] text-left text-[var(--color-ink-soft)]">
            <th className="py-2 pr-3 font-normal">Kampanja</th>
            <th className="py-2 pr-3 text-right font-normal">Impr.</th>
            <th className="py-2 pr-3 text-right font-normal">Doseg</th>
            <th className="py-2 pr-3 text-right font-normal">{viewLabel}</th>
            <th className="py-2 pr-3 text-right font-normal">VTR</th>
            <th className="py-2 text-right font-normal">CPV</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.campaign} className="border-b border-[var(--color-line)]">
              <td className="py-2 pr-3 max-w-[260px] truncate" title={r.campaign}>{r.campaign}</td>
              <td className="py-2 pr-3 text-right font-mono">{fmtInt(r.impressions)}</td>
              <td className="py-2 pr-3 text-right font-mono">{fmtInt(r.reach)}</td>
              <td className="py-2 pr-3 text-right font-mono">{fmtInt(r.video_views)}</td>
              <td className="py-2 pr-3 text-right font-mono">{fmtPct(r.impressions > 0 ? (r.video_views / r.impressions) * 100 : 0)}</td>
              <td className="py-2 text-right font-mono">{fmtEUR(r.video_views > 0 ? r.spend / r.video_views : 0, 3)}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <p className="mt-2 text-xs text-[var(--color-ink-soft)]">Doseg je zbir dnevnih jedinstvenih korisnika (isto kao u ostatku izveštaja).</p>
    </section>
  )
}
