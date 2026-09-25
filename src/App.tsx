import { useState } from 'react'
import Dashboard from './pages/Dashboard'
import AgencyReport from './pages/AgencyReport'
import GoogleAdsReport from './pages/GoogleAdsReport'
import FacebookAdsReport from './pages/FacebookAdsReport'
import BlendedReport from './pages/BlendedReport'
import Ga4Report from './pages/Ga4Report'
import ExecutiveSummary from './pages/ExecutiveSummary'
import OwnedChannelsReport from './pages/OwnedChannelsReport'
import PpcMediaReport from './pages/PpcMediaReport'
import BudgetPacingReport from './pages/BudgetPacingReport'
import './index.css'

// DEMO build: public, read-only, no login. Production gates everything behind a
// Supabase magic link and scopes rows per agency/client; the demo database only
// holds generated data, so there is nothing to protect. The AI Chat tab is left
// out because it needs the production `chat` Edge Function and an LLM key.
type View = 'summary' | 'client' | 'agency' | 'google_ads' | 'facebook_ads' | 'blended' | 'ga4' | 'owned' | 'ppc' | 'pacing'

function App() {
  const [view, setView] = useState<View>('summary')

  const tabs: { key: View; label: string }[] = [
    { key: 'summary', label: 'Sažetak za direktora' },
    { key: 'agency', label: 'Agencijski izveštaj' },
    { key: 'client', label: 'Po klijentu' },
    { key: 'google_ads', label: 'Google Ads' },
    { key: 'facebook_ads', label: 'Facebook Ads' },
    { key: 'blended', label: 'Blended' },
    { key: 'ga4', label: 'GA4' },
    { key: 'owned', label: 'Push & Newsletter' },
    { key: 'ppc', label: 'PPC Media Plan' },
    { key: 'pacing', label: 'Budget Pacing' },
  ]

  return (
    <div className="min-h-screen bg-[var(--color-paper)]">
      <div className="demo-banner">
        <strong>DEMO</strong> &middot; Brain Reporting Platform &mdash; svi klijenti, kampanje i brojevi su izmišljeni i služe
        isključivo za prezentaciju. Ovo nisu podaci stvarnih klijenata agencije.
      </div>
      <nav className="bg-[var(--color-bar)]">
        <div className="mx-auto flex max-w-5xl items-center justify-between gap-6 px-8">
          <div className="flex gap-6 overflow-x-auto">
            {tabs.map((tab) => (
              <button
                key={tab.key}
                onClick={() => setView(tab.key)}
                className={`whitespace-nowrap border-b-2 py-4 text-sm font-medium ${
                  view === tab.key
                    ? 'border-[var(--color-indigo)] text-white'
                    : 'border-transparent text-slate-400 hover:text-slate-200'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>
          <span className="demo-pill" title="Demo okruženje sa izmišljenim podacima">DEMO</span>
        </div>
      </nav>
      <div className="mx-auto max-w-5xl px-8 py-10">
        {view === 'summary' && <ExecutiveSummary />}
        {view === 'agency' && <AgencyReport />}
        {view === 'client' && <Dashboard />}
        {view === 'google_ads' && <GoogleAdsReport />}
        {view === 'facebook_ads' && <FacebookAdsReport />}
        {view === 'blended' && <BlendedReport />}
        {view === 'ga4' && <Ga4Report />}
        {view === 'owned' && <OwnedChannelsReport />}
        {view === 'ppc' && <PpcMediaReport />}
        {view === 'pacing' && <BudgetPacingReport />}
      </div>
    </div>
  )
}

export default App
