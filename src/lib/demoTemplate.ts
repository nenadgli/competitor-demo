import type { BusinessType, Client } from './supabase'

// Per-business-template wording for the report pages. Production only ever shows
// e-commerce language (Konverzije / ROAS); the demo also carries lead-gen, app and
// awareness clients, where "ROAS 0.00x" would be misleading.
export type TemplateLabels = {
  badge: string
  conv: string // count of the primary action
  convShort: string // table column
  value: string // monetary value of those actions
  cpa: string // cost per action
  hasValue: boolean // is conversion_value meaningful (ROAS etc.)
  valueNote?: string
}

const LABELS: Record<BusinessType, TemplateLabels> = {
  ecommerce: {
    badge: 'E-commerce',
    conv: 'Kupovine',
    convShort: 'Kupov.',
    value: 'Prihod (vrednost konverzija)',
    cpa: 'CPA',
    hasValue: true,
  },
  leadgen: {
    badge: 'Lead Generation',
    conv: 'Leadovi',
    convShort: 'Leadovi',
    value: 'Vrednost leadova',
    cpa: 'CPL',
    hasValue: true,
    valueNote: 'Vrednost leada = očekivana vrednost kvalifikovanog leada po izvoru (search lead vredi više od Meta lead forme).',
  },
  app: {
    badge: 'App Install',
    conv: 'Instalacije',
    convShort: 'Inst.',
    value: 'Vrednost',
    cpa: 'CPI',
    hasValue: false,
    valueNote: 'App kampanje se optimizuju na instalacije i re-engagement — prihod se ne meri kroz oglasne platforme.',
  },
  awareness: {
    badge: 'Awareness / Reach',
    conv: 'Akcije (store locator)',
    convShort: 'Akcije',
    value: 'Vrednost',
    cpa: 'Cena po akciji',
    hasValue: false,
    valueNote: 'Awareness kampanje se mere dosegom, CPM-om i video pregledima — konverzije su sporedna metrika.',
  },
}

export function businessType(client: Pick<Client, 'business_type'> | null | undefined): BusinessType {
  return client?.business_type ?? 'ecommerce'
}

export function labelsFor(client: Pick<Client, 'business_type'> | null | undefined): TemplateLabels {
  return LABELS[businessType(client)]
}
