-- Brain Reporting DEMO — the four business templates.
-- All brands, campaigns, keywords and numbers are invented. Campaign names follow
-- the agency convention  Naziv (Mkt:XX;Ct:Tip;Ph:Tof/Bof)  so the funnel and
-- budget-bucket classifiers work exactly as they do in production.
--
-- Field reference (see demo.gen_* in the previous migration):
--   dow[7]            Mon..Sun spend/traffic profile
--   trend / cvr_trend relative change from the first to the last day of the month
--   events            day ranges with spend / cvr / traffic multipliers
--   google[]          type, budget (€/day), cpc, ctr, cvr, value (per conversion), is (search IS),
--                     ad_groups | asset_groups [name, weight, cvr×], keywords [text, match, QS, weight, cvr×],
--                     terms [term, keyword#, weight, cvr× (0 = never converts)], competitors [domain, p/day]
--   meta[]            objective, budget, cpm, ctr, cvr, value, freq, view_rate,
--                     adsets [name, weight, cvr×], ads [name, adset#, weight]
--   ga4               platform→GA4 attribution ratios, bounce, organic sources, owned broadcasts/automations
--   plan[]            media plan lines with the pace they should show (actual / plan)
--   report_rows[]     PPC Media Plan report structure

delete from demo.templates;

-- =====================================================================================
-- 1. E-COMMERCE — Moda Market (fashion webshop). Full revenue / ROAS storyline:
--    summer-sale flash (14–17), a Demand Gen launch on the 10th, a zero-conversion
--    display prospecting line, Meta over-reporting vs GA4, PMax overspending the plan.
-- =====================================================================================
insert into demo.templates (slug, sort_order, config) values ('demo-ecommerce', 1, $json$
{
  "slug": "demo-ecommerce",
  "name": "Moda Market · E-commerce",
  "business_type": "ecommerce",
  "sort_order": 1,
  "tagline": "Online prodavnica odeće i obuće · prihod i ROAS",
  "seed": 20260801,
  "dow": [1.0, 0.97, 0.96, 1.0, 1.04, 0.93, 1.1],
  "trend": 0.1,
  "cvr_trend": 0.14,
  "events": [
    {"from": 14, "to": 17, "spend": 1.4, "cvr": 1.35, "traffic": 1.3, "label": "Summer Sale finale"},
    {"from": 27, "to": 31, "spend": 1.08, "cvr": 1.1, "traffic": 1.08, "label": "Back to school"}
  ],
  "google": [
    {
      "name": "Moda Market Brand (Mkt:RS;Ct:Brand_Search;Ph:Bof)", "type": "SEARCH",
      "budget": 42, "cpc": 0.19, "ctr": 0.21, "cvr": 0.078, "value": 64, "is": 0.91, "lost_budget_share": 0.1,
      "ad_groups": [["Brand - Osnovni", 0.7, 1.0], ["Brand - Prodavnice", 0.3, 0.8]],
      "keywords": [
        ["moda market", "EXACT", 10, 0.46, 1.0],
        ["moda market online", "PHRASE", 9, 0.24, 1.1],
        ["modamarket rs", "EXACT", 9, 0.16, 1.05],
        ["moda market prodavnice", "PHRASE", 8, 0.14, 0.6]
      ],
      "terms": [
        ["moda market", 1, 0.8, 1.0], ["moda market srbija", 1, 0.2, 1.0],
        ["moda market online shop", 2, 0.6, 1.1], ["moda market akcija", 2, 0.4, 1.3],
        ["modamarket.rs", 3, 1.0, 1.0],
        ["moda market radno vreme", 4, 0.5, 0.0], ["moda market ušće", 4, 0.5, 0.7]
      ],
      "competitors": [["zara.com", 0.35], ["hm.com", 0.3], ["answear.rs", 0.55], ["aboutyou.rs", 0.4]]
    },
    {
      "name": "Generic Odeća i Obuća (Mkt:RS;Ct:Generic_Search;Ph:Bof)", "type": "SEARCH",
      "budget": 92, "cpc": 0.41, "ctr": 0.057, "cvr": 0.023, "value": 58, "is": 0.47, "lost_budget_share": 0.55,
      "ad_groups": [["Patike", 0.36, 1.1], ["Jakne", 0.2, 0.9], ["Haljine", 0.26, 0.95], ["Farmerke", 0.18, 1.0]],
      "keywords": [
        ["ženske patike", "PHRASE", 7, 0.2, 1.15],
        ["muške patike", "PHRASE", 7, 0.16, 1.1],
        ["patike akcija", "BROAD", 5, 0.12, 0.9],
        ["letnje haljine", "BROAD", 5, 0.15, 0.75],
        ["jakne za jesen", "PHRASE", 6, 0.11, 0.8],
        ["farmerke online", "PHRASE", 6, 0.1, 1.2],
        ["kupovina odeće online", "BROAD", 4, 0.1, 0.55],
        ["ženske patike nike", "EXACT", 8, 0.06, 1.3]
      ],
      "terms": [
        ["ženske patike", 1, 0.45, 1.2], ["bele ženske patike", 1, 0.3, 1.1], ["besplatne patike", 1, 0.12, 0.0],
        ["muške patike", 2, 0.4, 1.1], ["muške patike 44", 2, 0.3, 1.0], ["patike polovne", 2, 0.12, 0.0],
        ["patike na akciji", 3, 0.5, 1.0], ["kako oprati patike", 3, 0.25, 0.0],
        ["letnje haljine duge", 4, 0.4, 0.9], ["haljine za svadbu iznajmljivanje", 4, 0.3, 0.0], ["haljine cene", 4, 0.3, 0.8],
        ["jakna prelazna ženska", 5, 0.6, 0.9], ["jakne kiša", 5, 0.2, 0.6],
        ["farmerke mom fit", 6, 0.6, 1.3], ["farmerke muške slim", 6, 0.4, 1.0],
        ["online prodavnica odeće", 7, 0.5, 0.7], ["besplatna dostava odeća", 7, 0.3, 0.9],
        ["nike air force 1 ženske", 8, 1.0, 1.4]
      ],
      "competitors": [["answear.rs", 0.7], ["zara.com", 0.55], ["hm.com", 0.5], ["aboutyou.rs", 0.6], ["shoppster.rs", 0.35], ["buzzsneakers.rs", 0.45]]
    },
    {
      "name": "PMax Ecomm Katalog (Mkt:RS;Ct:PMax)", "type": "PERFORMANCE_MAX",
      "budget": 205, "cpc": 0.26, "ctr": 0.012, "cvr": 0.021, "value": 61, "freq": 3.1,
      "asset_groups": [["AG_Zene_Odeca", 0.34, 1.05], ["AG_Muskarci_Odeca", 0.22, 0.95], ["AG_Obuca", 0.28, 1.1], ["AG_Sale_Akcija", 0.16, 0.85]]
    },
    {
      "name": "Dinamički Remarketing (Mkt:RS;Ct:Display_Dyn;Ph:Bof)", "type": "DISPLAY",
      "budget": 36, "cpc": 0.16, "ctr": 0.009, "cvr": 0.019, "value": 55, "freq": 4.2,
      "ad_groups": [["RMK_Pregled_Proizvoda_7d", 0.55, 1.0], ["RMK_Korpa_14d", 0.45, 1.5]]
    },
    {
      "name": "Display Prospecting Jesen (Mkt:RS;Ct:Display;Ph:Tof)", "type": "DISPLAY",
      "budget": 30, "cpc": 0.09, "ctr": 0.004, "cvr": 0, "value": 0, "zero_conv": true, "freq": 2.9, "ga4_bounce": 0.71,
      "ad_groups": [["Affinity_Moda_Lifestyle", 0.6, 1.0], ["Custom_Intent_Konkurencija", 0.4, 1.0]]
    },
    {
      "name": "Demand Gen Nova Kolekcija (Mkt:RS;Ct:DemandGen;Ph:Tof)", "type": "DEMAND_GEN",
      "budget": 38, "cpc": 0.14, "ctr": 0.011, "cvr": 0.0065, "value": 57, "view_rate": 0.09, "from": 10,
      "ad_groups": [["DG_YouTube_Shorts", 0.45, 0.8], ["DG_Discover_Gmail", 0.55, 1.15]]
    }
  ],
  "meta": [
    {
      "name": "Prospecting Katalog (Mkt:RS;Ct:Conversions;Ph:Tof)", "objective": "OUTCOME_SALES",
      "budget": 158, "cpm": 3.8, "ctr": 0.013, "cvr": 0.019, "value": 54, "freq": 1.22, "view_rate": 0.06,
      "adsets": [["Broad_25_54 Advantage+ audience", 0.45, 1.0], ["LAL_Kupci_3pct", 0.33, 1.25], ["Interest_Moda_Lifestyle", 0.22, 0.7]],
      "ads": [
        ["Carousel_Jesen_Kolekcija_01", 1, 0.35], ["Video_UGC_Patike_15s", 1, 0.4], ["Static_Sale_do_40pct", 1, 0.25],
        ["Reels_Styling_Tips_Ana", 2, 0.5], ["DPA_Katalog_Bestseleri", 2, 0.5],
        ["Carousel_Jesen_Kolekcija_02", 3, 0.6], ["Static_Nova_Kolekcija", 3, 0.4]
      ]
    },
    {
      "name": "Retargeting DPA (Mkt:RS;Ct:Conversions;Ph:Bof)", "objective": "OUTCOME_SALES",
      "budget": 74, "cpm": 7.6, "ctr": 0.021, "cvr": 0.043, "value": 61, "freq": 1.9,
      "adsets": [["RT_ViewContent_7d", 0.42, 0.9], ["RT_AddToCart_14d", 0.38, 1.4], ["RT_Kupci_180d", 0.2, 0.8]],
      "ads": [
        ["DPA_Pregledani_Proizvodi", 1, 1.0],
        ["DPA_Korpa_Podsetnik", 2, 0.6], ["Static_Besplatna_Dostava", 2, 0.4],
        ["Carousel_Novo_Za_Vas", 3, 1.0]
      ]
    },
    {
      "name": "Advantage Shopping Summer Sale (Mkt:RS;Ct:Conversions;Ph:Tof)", "objective": "OUTCOME_SALES",
      "budget": 215, "cpm": 4.4, "ctr": 0.016, "cvr": 0.024, "value": 52, "freq": 1.35, "from": 13, "to": 17,
      "adsets": [["ASC_Summer_Sale", 1.0, 1.0]],
      "ads": [["Video_Summer_Sale_Countdown", 1, 0.5], ["Static_Sale_do_50pct", 1, 0.3], ["Carousel_Sale_Top_Artikli", 1, 0.2]]
    },
    {
      "name": "Social Brand Awareness (Mkt:RS;Ct:Awareness;Ph:Tof)", "objective": "OUTCOME_AWARENESS",
      "budget": 28, "cpm": 1.6, "ctr": 0.004, "cvr": 0, "value": 0, "freq": 1.7, "view_rate": 0.19,
      "adsets": [["Reach_RS_18_45", 1.0, 1.0]],
      "ads": [["Video_Brand_Film_20s", 1, 0.6], ["Reels_Iza_Kulisa_Snimanja", 1, 0.4]]
    },
    {
      "name": "Moda Market App Installs (Mkt:RS;Ct:App;Ph:Tof)", "objective": "APP_INSTALLS",
      "budget": 24, "cpm": 3.1, "ctr": 0.011, "cvr": 0.23, "value": 0, "freq": 1.3, "ga4_spc": 0.05,
      "adsets": [["App_Android_Broad", 0.62, 1.0], ["App_iOS_Broad", 0.38, 0.85]],
      "ads": [["Video_App_Ekskluzivni_Popusti", 1, 1.0], ["Video_App_Ekskluzivni_Popusti_iOS", 2, 1.0]],
      "placements": [["instagram","mobile_app",0.46,1.1,0.9],["facebook","mobile_app",0.38,1.0,1.0],["audience_network","mobile_app",0.16,0.4,1.6]]
    }
  ],
  "ga4": {
    "google_ratio": 0.9, "meta_ratio": 0.44, "google_bounce": 0.33, "meta_bounce": 0.57, "new_share": 0.62,
    "organic": [
      {"source": "google", "medium": "organic", "campaign": "(organic)", "sessions": 2050, "cvr": 0.016, "aov": 63, "bounce": 0.36, "new_share": 0.55},
      {"source": "(direct)", "medium": "(none)", "campaign": "(direct)", "sessions": 1280, "cvr": 0.022, "aov": 66, "bounce": 0.3, "new_share": 0.34},
      {"source": "instagram", "medium": "social", "campaign": "(not set)", "sessions": 410, "cvr": 0.006, "aov": 52, "bounce": 0.52, "new_share": 0.6},
      {"source": "facebook", "medium": "social", "campaign": "(not set)", "sessions": 170, "cvr": 0.004, "aov": 49, "bounce": 0.55, "new_share": 0.55},
      {"source": "bing", "medium": "organic", "campaign": "(organic)", "sessions": 85, "cvr": 0.015, "aov": 70, "bounce": 0.38, "new_share": 0.6},
      {"source": "l.instagram.com", "medium": "referral", "campaign": "(referral)", "sessions": 105, "cvr": 0.005, "aov": 50, "bounce": 0.5, "new_share": 0.65},
      {"source": "chatgpt.com", "medium": "referral", "campaign": "(referral)", "sessions": 42, "cvr": 0.021, "aov": 72, "bounce": 0.29, "new_share": 0.8}
    ],
    "owned": [
      {"source": "newsletter", "medium": "email", "campaign": "NL_Leto_Nove_Cene_W32", "day": 3, "sessions": 2300, "cvr": 0.026, "aov": 57, "decay": 0.3},
      {"source": "newsletter", "medium": "email", "campaign": "NL_Summer_Sale_Start", "day": 10, "sessions": 2900, "cvr": 0.031, "aov": 55, "decay": 0.32},
      {"source": "newsletter", "medium": "email", "campaign": "NL_Flash_Sale_48h", "day": 14, "sessions": 3900, "cvr": 0.044, "aov": 54, "decay": 0.4},
      {"source": "newsletter", "medium": "email", "campaign": "NL_Poslednja_Sansa_Sale", "day": 17, "sessions": 3100, "cvr": 0.039, "aov": 53, "decay": 0.2},
      {"source": "newsletter", "medium": "email", "campaign": "NL_Jesen_Kolekcija_Preview", "day": 24, "sessions": 2100, "cvr": 0.019, "aov": 68, "decay": 0.3},
      {"source": "newsletter", "medium": "email", "campaign": "NL_Back_To_School", "day": 28, "sessions": 2400, "cvr": 0.028, "aov": 59, "decay": 0.3},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_Vikend_Popust_20pct", "day": 1, "sessions": 1300, "cvr": 0.03, "aov": 51, "decay": 0.2},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_Nova_Kolekcija", "day": 6, "sessions": 980, "cvr": 0.022, "aov": 60, "decay": 0.2},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_Flash_Sale_Start", "day": 14, "sessions": 1850, "cvr": 0.041, "aov": 52, "decay": 0.25},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_Flash_Sale_Poslednji_Dan", "day": 16, "sessions": 1600, "cvr": 0.038, "aov": 50, "decay": 0.15},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_Besplatna_Dostava", "day": 21, "sessions": 1100, "cvr": 0.027, "aov": 55, "decay": 0.2},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_Back_To_School", "day": 27, "sessions": 1250, "cvr": 0.03, "aov": 57, "decay": 0.2},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_Vikend_Jesen", "day": 29, "sessions": 1050, "cvr": 0.024, "aov": 62, "decay": 0.2}
    ],
    "automations": [
      {"source": "newsletter", "medium": "email", "campaign": "AbandCart_1h_Podsetnik", "sessions": 54, "cvr": 0.11, "aov": 71, "bounce": 0.22},
      {"source": "newsletter", "medium": "email", "campaign": "AbandCart_24h_Kupon_10pct", "sessions": 33, "cvr": 0.085, "aov": 66, "bounce": 0.25}
    ]
  },
  "plan": [
    {"network": "google", "flight_type": "Always-on", "ad_set_type": "SEARCH", "label": "Search Brand + Generic", "pace": 0.97},
    {"network": "google", "flight_type": "Always-on", "ad_set_type": "PERFORMANCE_MAX", "label": "Performance Max Katalog", "pace": 1.13},
    {"network": "google", "flight_type": "Always-on", "ad_set_type": "DISPLAY", "label": "Display Remarketing + Prospecting", "pace": 0.95},
    {"network": "google", "flight_type": "Flight", "ad_set_type": "DEMAND_GEN", "label": "Demand Gen - Nova kolekcija", "pace": 0.82, "from": 10},
    {"network": "meta", "flight_type": "Always-on", "ad_set_type": "Bucket", "label": "Prospecting + Retargeting",
      "pace": 1.03, "campaigns": ["Prospecting Katalog (Mkt:RS;Ct:Conversions;Ph:Tof)", "Retargeting DPA (Mkt:RS;Ct:Conversions;Ph:Bof)"]},
    {"network": "meta", "flight_type": "Flight", "ad_set_type": "Bucket", "label": "Summer Sale flight (ASC)",
      "pace": 1.06, "from": 13, "to": 17, "campaigns": ["Advantage Shopping Summer Sale (Mkt:RS;Ct:Conversions;Ph:Tof)"]},
    {"network": "meta", "flight_type": "Always-on", "ad_set_type": "Bucket", "label": "Social - Brand awareness",
      "pace": 0.98, "campaigns": ["Social Brand Awareness (Mkt:RS;Ct:Awareness;Ph:Tof)"]},
    {"network": "meta", "flight_type": "Always-on", "ad_set_type": "Bucket", "label": "App Installs (Ct:App)",
      "pace": 0.9, "campaigns": ["Moda Market App Installs (Mkt:RS;Ct:App;Ph:Tof)"]}
  ],
  "report_rows": [
    {"label": "Search Brend", "channel": "google", "level": "campaign", "campaigns": ["Moda Market Brand (Mkt:RS;Ct:Brand_Search;Ph:Bof)"]},
    {"label": "Search Generic", "channel": "google", "level": "google_ad_group", "campaigns": ["Generic Odeća i Obuća (Mkt:RS;Ct:Generic_Search;Ph:Bof)"], "note": "Demo podaci — po ad grupi"},
    {"label": "Performance Max", "channel": "google", "level": "asset_group", "campaigns": ["PMax Ecomm Katalog (Mkt:RS;Ct:PMax)"], "note": "Demo podaci — po asset grupi"},
    {"label": "Display (remarketing + prospecting)", "channel": "google", "level": "campaign", "campaigns": ["Dinamički Remarketing (Mkt:RS;Ct:Display_Dyn;Ph:Bof)", "Display Prospecting Jesen (Mkt:RS;Ct:Display;Ph:Tof)"]},
    {"label": "Demand Gen", "channel": "google", "level": "campaign", "campaigns": ["Demand Gen Nova Kolekcija (Mkt:RS;Ct:DemandGen;Ph:Tof)"]},
    {"label": "Meta Prospecting", "channel": "meta", "level": "meta_ad_set", "campaigns": ["Prospecting Katalog (Mkt:RS;Ct:Conversions;Ph:Tof)"], "note": "Demo podaci — po ad setu"},
    {"label": "Meta Retargeting", "channel": "meta", "level": "meta_ad_set", "campaigns": ["Retargeting DPA (Mkt:RS;Ct:Conversions;Ph:Bof)"], "note": "Demo podaci — po ad setu"},
    {"label": "Summer Sale flight", "channel": "meta", "level": "campaign", "campaigns": ["Advantage Shopping Summer Sale (Mkt:RS;Ct:Conversions;Ph:Tof)"]},
    {"label": "Social + App", "channel": "meta", "level": "campaign", "campaigns": ["Social Brand Awareness (Mkt:RS;Ct:Awareness;Ph:Tof)", "Moda Market App Installs (Mkt:RS;Ct:App;Ph:Tof)"]}
  ]
}
$json$::jsonb);

-- =====================================================================================
-- 2. LEAD GENERATION — SolarDom (residential solar installs). Conversions are leads,
--    value is the expected value of a qualified lead (search leads worth more than Meta
--    lead-form leads). Story: subsidy news on the 20th spikes demand, CPL improves over
--    the month, generic search is budget-limited, the YouTube line brings no leads.
-- =====================================================================================
insert into demo.templates (slug, sort_order, config) values ('demo-leadgen', 2, $json$
{
  "slug": "demo-leadgen",
  "name": "SolarDom · Lead Generation",
  "business_type": "leadgen",
  "sort_order": 2,
  "tagline": "Solarne elektrane za domaćinstva · leadovi, CPL i vrednost leada",
  "seed": 20260802,
  "dow": [1.1, 1.1, 1.07, 1.04, 0.96, 0.8, 0.86],
  "trend": 0.06,
  "cvr_trend": 0.2,
  "events": [
    {"from": 20, "to": 23, "spend": 1.22, "cvr": 1.25, "traffic": 1.35, "label": "Vest o državnim subvencijama"}
  ],
  "google": [
    {
      "name": "SolarDom Brand (Mkt:RS;Ct:Brand_Search;Ph:Bof)", "type": "SEARCH",
      "budget": 17, "cpc": 0.34, "ctr": 0.19, "cvr": 0.15, "value": 60, "is": 0.88, "lost_budget_share": 0.15,
      "ad_groups": [["Brand", 1.0, 1.0]],
      "keywords": [
        ["solardom", "EXACT", 10, 0.55, 1.0], ["solar dom", "PHRASE", 9, 0.2, 0.9],
        ["solardom cena", "PHRASE", 9, 0.15, 1.3], ["solardom iskustva", "PHRASE", 8, 0.1, 0.6]
      ],
      "terms": [
        ["solardom", 1, 1.0, 1.0], ["solar dom beograd", 2, 1.0, 0.9],
        ["solardom cena elektrane", 3, 1.0, 1.3], ["solardom iskustva forum", 4, 0.6, 0.0], ["solardom recenzije", 4, 0.4, 0.8]
      ],
      "competitors": [["sunceplus.rs", 0.4], ["elektrana-kuca.rs", 0.3]]
    },
    {
      "name": "Solarni Paneli Generic (Mkt:RS;Ct:Generic_Search;Ph:Bof)", "type": "SEARCH",
      "budget": 96, "cpc": 1.24, "ctr": 0.052, "cvr": 0.063, "value": 60, "is": 0.38, "lost_budget_share": 0.72,
      "ad_groups": [["Solarni paneli cena", 0.34, 1.0], ["Solarna elektrana za kuću", 0.3, 1.25], ["Subvencije", 0.2, 0.9], ["Toplotne pumpe", 0.16, 0.55]],
      "keywords": [
        ["solarni paneli cena", "PHRASE", 7, 0.24, 0.95],
        ["solarna elektrana za kuću", "PHRASE", 8, 0.2, 1.3],
        ["solarni paneli za kuću", "BROAD", 6, 0.17, 0.9],
        ["subvencije za solarne panele", "PHRASE", 7, 0.13, 0.85],
        ["kupac proizvođač", "PHRASE", 6, 0.1, 1.2],
        ["toplotna pumpa cena", "BROAD", 5, 0.1, 0.5],
        ["solarni paneli kredit", "PHRASE", 6, 0.06, 1.4]
      ],
      "terms": [
        ["solarni paneli cena", 1, 0.45, 1.0], ["solarni paneli cena po kw", 1, 0.35, 1.1], ["solarni paneli polovni", 1, 0.15, 0.0],
        ["solarna elektrana 10kw cena", 2, 0.55, 1.4], ["solarna elektrana za kuću isplativost", 2, 0.35, 1.1],
        ["solarni paneli za kuću", 3, 0.4, 0.9], ["solarni paneli za vikendicu 12v", 3, 0.3, 0.0], ["solarni paneli posao", 3, 0.12, 0.0],
        ["subvencije za solarne panele 2026", 4, 0.6, 1.0], ["subvencije solarni paneli opština", 4, 0.3, 0.8],
        ["kako postati kupac proizvođač", 5, 0.6, 1.1], ["kupac proizvođač eps", 5, 0.3, 1.2],
        ["toplotna pumpa cena", 6, 0.5, 0.6], ["toplotna pumpa vazduh voda iskustva", 6, 0.3, 0.0],
        ["solarni paneli na kredit", 7, 1.0, 1.4]
      ],
      "competitors": [["sunceplus.rs", 0.75], ["elektrana-kuca.rs", 0.6], ["solarni-sistemi.rs", 0.5], ["energetika-plus.rs", 0.35]]
    },
    {
      "name": "PMax Leads (Mkt:RS;Ct:PMax)", "type": "PERFORMANCE_MAX",
      "budget": 54, "cpc": 0.39, "ctr": 0.011, "cvr": 0.027, "value": 42, "freq": 3.0,
      "asset_groups": [["AG_Domacinstva", 0.7, 1.05], ["AG_Firme_Kupac_Proizvodjac", 0.3, 0.9]]
    },
    {
      "name": "Display Remarketing Leads (Mkt:RS;Ct:Display;Ph:Bof)", "type": "DISPLAY",
      "budget": 19, "cpc": 0.22, "ctr": 0.007, "cvr": 0.012, "value": 50, "freq": 4.5,
      "ad_groups": [["RMK_Posetioci_Kalkulatora", 0.6, 1.3], ["RMK_Svi_Posetioci_30d", 0.4, 0.6]]
    },
    {
      "name": "YouTube Kako Radi Solar (Mkt:RS;Ct:Video;Ph:Tof)", "type": "VIDEO",
      "budget": 22, "cpc": 0.95, "ctr": 0.0045, "cvr": 0, "value": 0, "zero_conv": true, "view_rate": 0.31, "freq": 2.6, "ga4_bounce": 0.66,
      "ad_groups": [["YT_Vlasnici_Kuca_35_65", 0.65, 1.0], ["YT_Custom_Intent_Solari", 0.35, 1.0]]
    }
  ],
  "meta": [
    {
      "name": "Lead Forma Prospecting (Mkt:RS;Ct:Lead;Ph:Tof)", "objective": "OUTCOME_LEADS",
      "budget": 93, "cpm": 5.2, "ctr": 0.011, "cvr": 0.083, "value": 28, "freq": 1.3,
      "adsets": [["Vlasnici_Kuca_35_65", 0.46, 1.1], ["LAL_Leadovi_2pct", 0.32, 1.15], ["Interest_Obnovljiva_Energija", 0.22, 0.65]],
      "ads": [
        ["Video_Ustedite_do_70pct", 1, 0.45], ["Carousel_Realizovani_Projekti", 1, 0.3], ["Static_Besplatna_Procena", 1, 0.25],
        ["Reels_Montaza_Timelapse", 2, 0.55], ["Video_Ustedite_do_70pct_v2", 2, 0.45],
        ["Static_Subvencija_Info", 3, 1.0]
      ]
    },
    {
      "name": "Lead Forma Retargeting (Mkt:RS;Ct:Lead;Ph:Bof)", "objective": "OUTCOME_LEADS",
      "budget": 29, "cpm": 9.1, "ctr": 0.018, "cvr": 0.12, "value": 36, "freq": 2.1,
      "adsets": [["RT_Posetioci_Sajta_30d", 0.6, 1.1], ["RT_Video_Gledaoci_50pct", 0.4, 0.85]],
      "ads": [["Static_Kalkulator_Ustede", 1, 0.55], ["Video_Testimonijal_Porodica_Petrovic", 1, 0.45], ["Carousel_Faq_Solari", 2, 1.0]]
    },
    {
      "name": "Traffic Kalkulator Uštede (Mkt:RS;Ct:Traffic;Ph:Tof)", "objective": "OUTCOME_TRAFFIC",
      "budget": 20, "cpm": 2.8, "ctr": 0.016, "cvr": 0.011, "value": 45, "freq": 1.4,
      "adsets": [["Broad_30_65_Srbija", 1.0, 1.0]],
      "ads": [["Static_Izracunaj_Ustedu", 1, 0.6], ["Video_Kalkulator_Demo", 1, 0.4]]
    }
  ],
  "ga4": {
    "google_ratio": 0.86, "meta_ratio": 0.31, "google_bounce": 0.36, "meta_bounce": 0.49, "new_share": 0.78,
    "organic": [
      {"source": "google", "medium": "organic", "campaign": "(organic)", "sessions": 520, "cvr": 0.012, "aov": 55, "bounce": 0.4, "new_share": 0.75},
      {"source": "(direct)", "medium": "(none)", "campaign": "(direct)", "sessions": 205, "cvr": 0.018, "aov": 58, "bounce": 0.35, "new_share": 0.45},
      {"source": "bing", "medium": "organic", "campaign": "(organic)", "sessions": 24, "cvr": 0.014, "aov": 55, "bounce": 0.42, "new_share": 0.8},
      {"source": "facebook", "medium": "social", "campaign": "(not set)", "sessions": 38, "cvr": 0.006, "aov": 40, "bounce": 0.55, "new_share": 0.7},
      {"source": "solarni-forum.rs", "medium": "referral", "campaign": "(referral)", "sessions": 29, "cvr": 0.022, "aov": 60, "bounce": 0.33, "new_share": 0.85},
      {"source": "chatgpt.com", "medium": "referral", "campaign": "(referral)", "sessions": 17, "cvr": 0.03, "aov": 62, "bounce": 0.28, "new_share": 0.9}
    ],
    "owned": [
      {"source": "newsletter", "medium": "email", "campaign": "NL_Case_Study_Kragujevac", "day": 6, "sessions": 420, "cvr": 0.021, "aov": 58, "decay": 0.3},
      {"source": "newsletter", "medium": "email", "campaign": "NL_Subvencije_Otvorene", "day": 20, "sessions": 780, "cvr": 0.036, "aov": 60, "decay": 0.4},
      {"source": "newsletter", "medium": "email", "campaign": "NL_Kalkulator_Ustede", "day": 27, "sessions": 390, "cvr": 0.019, "aov": 58, "decay": 0.3},
      {"source": "push_notification", "medium": "web_push", "campaign": "Push_Besplatna_Procena_Krova", "day": 11, "sessions": 210, "cvr": 0.018, "aov": 55, "decay": 0.2},
      {"source": "push_notification", "medium": "web_push", "campaign": "Push_Subvencije_Rok_Prijave", "day": 21, "sessions": 340, "cvr": 0.029, "aov": 58, "decay": 0.25}
    ],
    "automations": [
      {"source": "newsletter", "medium": "email", "campaign": "AbandCart_Nedovrsena_Forma_Ponude", "sessions": 12, "cvr": 0.14, "aov": 60, "bounce": 0.2}
    ]
  },
  "plan": [
    {"network": "google", "flight_type": "Always-on", "ad_set_type": "SEARCH", "label": "Search Brand + Generic", "pace": 1.01},
    {"network": "google", "flight_type": "Always-on", "ad_set_type": "PERFORMANCE_MAX", "label": "PMax Leads", "pace": 0.96},
    {"network": "google", "flight_type": "Always-on", "ad_set_type": "DISPLAY", "label": "Display Remarketing", "pace": 0.86},
    {"network": "google", "flight_type": "Always-on", "ad_set_type": "VIDEO", "label": "YouTube edukativni video", "pace": 1.04},
    {"network": "meta", "flight_type": "Always-on", "ad_set_type": "Bucket", "label": "Lead forme Prospecting + Retargeting",
      "pace": 1.07, "campaigns": ["Lead Forma Prospecting (Mkt:RS;Ct:Lead;Ph:Tof)", "Lead Forma Retargeting (Mkt:RS;Ct:Lead;Ph:Bof)"]},
    {"network": "meta", "flight_type": "Always-on", "ad_set_type": "Bucket", "label": "Traffic - Kalkulator uštede",
      "pace": 0.93, "campaigns": ["Traffic Kalkulator Uštede (Mkt:RS;Ct:Traffic;Ph:Tof)"]}
  ],
  "report_rows": [
    {"label": "Search Brend", "channel": "google", "level": "campaign", "campaigns": ["SolarDom Brand (Mkt:RS;Ct:Brand_Search;Ph:Bof)"]},
    {"label": "Search Generic", "channel": "google", "level": "google_ad_group", "campaigns": ["Solarni Paneli Generic (Mkt:RS;Ct:Generic_Search;Ph:Bof)"], "note": "Demo podaci — po ad grupi"},
    {"label": "Performance Max", "channel": "google", "level": "asset_group", "campaigns": ["PMax Leads (Mkt:RS;Ct:PMax)"], "note": "Demo podaci — po asset grupi"},
    {"label": "Display Remarketing", "channel": "google", "level": "campaign", "campaigns": ["Display Remarketing Leads (Mkt:RS;Ct:Display;Ph:Bof)"]},
    {"label": "YouTube", "channel": "google", "level": "campaign", "campaigns": ["YouTube Kako Radi Solar (Mkt:RS;Ct:Video;Ph:Tof)"]},
    {"label": "Meta Lead Forma — Prospecting", "channel": "meta", "level": "meta_ad_set", "campaigns": ["Lead Forma Prospecting (Mkt:RS;Ct:Lead;Ph:Tof)"], "note": "Demo podaci — po ad setu"},
    {"label": "Meta Lead Forma — Retargeting", "channel": "meta", "level": "meta_ad_set", "campaigns": ["Lead Forma Retargeting (Mkt:RS;Ct:Lead;Ph:Bof)"], "note": "Demo podaci — po ad setu"},
    {"label": "Meta Traffic (kalkulator)", "channel": "meta", "level": "campaign", "campaigns": ["Traffic Kalkulator Uštede (Mkt:RS;Ct:Traffic;Ph:Tof)"]}
  ]
}
$json$::jsonb);

-- =====================================================================================
-- 3. APP — FitPuls (fitness app). UAC install + re-engagement campaigns, Meta app
--    installs. Conversions are installs / re-engagements; no revenue anywhere.
--    Story: iOS installs cost ~2x Android, "7 dana besplatno" promo 21–24, Meta
--    install campaign overspends the plan, push notifications drive owned traffic.
-- =====================================================================================
insert into demo.templates (slug, sort_order, config) values ('demo-app', 3, $json$
{
  "slug": "demo-app",
  "name": "FitPuls · App Install",
  "business_type": "app",
  "sort_order": 3,
  "tagline": "Fitness aplikacija · instalacije, CPI i re-engagement (bez prihoda)",
  "seed": 20260803,
  "dow": [0.96, 0.97, 0.97, 0.96, 0.95, 1.06, 1.13],
  "trend": 0.08,
  "cvr_trend": 0.1,
  "events": [
    {"from": 21, "to": 24, "spend": 1.25, "cvr": 1.22, "traffic": 1.2, "label": "Promo: 7 dana Premium besplatno"}
  ],
  "google": [
    {
      "name": "FitPuls UAC Android Installs (Mkt:RS;Ct:App;Ph:Tof)", "type": "MULTI_CHANNEL",
      "budget": 118, "cpc": 0.14, "ctr": 0.018, "cvr": 0.21, "value": 0, "freq": 3.3,
      "ad_groups": [["AG_Video_Treninzi_Kod_Kuce", 0.45, 1.05], ["AG_HTML5_Mini_Trening", 0.2, 1.2], ["AG_Static_Banneri", 0.35, 0.8]]
    },
    {
      "name": "FitPuls UAC iOS Installs (Mkt:RS;Ct:App;Ph:Tof)", "type": "MULTI_CHANNEL",
      "budget": 66, "cpc": 0.24, "ctr": 0.014, "cvr": 0.16, "value": 0, "freq": 3.0,
      "ad_groups": [["AG_iOS_Video_Treninzi", 0.6, 1.0], ["AG_iOS_Static", 0.4, 0.85]]
    },
    {
      "name": "FitPuls UAC Re-engagement (Mkt:RS;Ct:App_Reengage;Ph:Bof)", "type": "MULTI_CHANNEL",
      "budget": 24, "cpc": 0.11, "ctr": 0.012, "cvr": 0.09, "value": 0, "freq": 4.4,
      "ad_groups": [["AG_Neaktivni_14d", 0.55, 1.1], ["AG_Neaktivni_30d", 0.45, 0.85]]
    },
    {
      "name": "FitPuls Brand Search (Mkt:RS;Ct:Brand_Search;Ph:Bof)", "type": "SEARCH",
      "budget": 8, "cpc": 0.12, "ctr": 0.24, "cvr": 0.34, "value": 0, "is": 0.93, "lost_budget_share": 0.1, "ga4_spc": 0.4,
      "ad_groups": [["Brand", 1.0, 1.0]],
      "keywords": [["fitpuls", "EXACT", 10, 0.6, 1.0], ["fit puls aplikacija", "PHRASE", 9, 0.25, 1.0], ["fitpuls premium", "PHRASE", 8, 0.15, 0.9]],
      "terms": [["fitpuls", 1, 1.0, 1.0], ["fit puls app", 2, 0.6, 1.0], ["fitpuls aplikacija download", 2, 0.4, 1.2], ["fitpuls premium cena", 3, 0.6, 0.9], ["fitpuls otkazivanje pretplate", 3, 0.4, 0.0]]
    },
    {
      "name": "Generic Fitness App Search (Mkt:RS;Ct:Generic_Search;Ph:Tof)", "type": "SEARCH",
      "budget": 22, "cpc": 0.28, "ctr": 0.06, "cvr": 0.12, "value": 0, "is": 0.52, "lost_budget_share": 0.45, "ga4_spc": 0.4,
      "ad_groups": [["Vezbanje_Kod_Kuce", 0.5, 1.1], ["Mrsavljenje", 0.3, 0.9], ["Plan_Ishrane", 0.2, 0.8]],
      "keywords": [
        ["aplikacija za vežbanje", "PHRASE", 7, 0.3, 1.1], ["trening kod kuće aplikacija", "PHRASE", 8, 0.22, 1.2],
        ["aplikacija za mršavljenje", "BROAD", 6, 0.2, 0.9], ["plan ishrane aplikacija", "PHRASE", 6, 0.14, 0.8],
        ["fitness app", "BROAD", 5, 0.14, 0.7]
      ],
      "terms": [
        ["aplikacija za vežbanje besplatna", 1, 0.6, 1.1], ["najbolja aplikacija za vežbanje", 1, 0.4, 1.2],
        ["trening kod kuće bez opreme", 2, 0.6, 1.2], ["personalni trener beograd cena", 2, 0.25, 0.0],
        ["aplikacija za mršavljenje besplatna", 3, 0.6, 0.9], ["tablete za mršavljenje", 3, 0.2, 0.0],
        ["plan ishrane za mršavljenje", 4, 1.0, 0.8],
        ["fitness app android", 5, 0.5, 0.9], ["teretana beograd cena", 5, 0.3, 0.0]
      ],
      "competitors": [["fitnessblender.com", 0.3], ["myfitnesspal.com", 0.45], ["gymbeam.rs", 0.35]]
    }
  ],
  "meta": [
    {
      "name": "App Install Prospecting (Mkt:RS;Ct:App;Ph:Tof)", "objective": "APP_INSTALLS",
      "budget": 108, "cpm": 2.9, "ctr": 0.012, "cvr": 0.24, "value": 0, "freq": 1.28, "view_rate": 0.11, "ga4_spc": 0.3,
      "adsets": [["Broad_18_45_Android", 0.36, 1.1], ["Broad_18_45_iOS", 0.24, 0.8], ["Interest_Fitness_Zdrav_Zivot", 0.22, 0.95], ["LAL_Pretplatnici_1pct", 0.18, 1.2]],
      "ads": [
        ["Video_Izazov_30_Dana", 1, 0.5], ["Playable_Mini_Trening", 1, 0.5],
        ["Video_Izazov_30_Dana_iOS", 2, 0.6], ["Static_7_Dana_Besplatno", 2, 0.4],
        ["UGC_Transformacija_Ana", 3, 0.55], ["Reels_Trener_Marko_Jutarnji", 3, 0.45],
        ["UGC_Transformacija_Ana_LAL", 4, 1.0]
      ],
      "placements": [["instagram","mobile_app",0.48,1.1,0.9],["facebook","mobile_app",0.32,1.0,1.0],["audience_network","mobile_app",0.14,0.4,1.6],["threads","mobile_app",0.06,0.8,0.6]]
    },
    {
      "name": "App Install Advantage+ (Mkt:RS;Ct:App;Ph:Tof)", "objective": "APP_INSTALLS",
      "budget": 44, "cpm": 3.2, "ctr": 0.011, "cvr": 0.26, "value": 0, "freq": 1.3, "ga4_spc": 0.3,
      "adsets": [["Advantage_Plus_App_Campaign", 1.0, 1.0]],
      "ads": [["Video_Izazov_30_Dana", 1, 0.4], ["UGC_Transformacija_Ana", 1, 0.35], ["Static_7_Dana_Besplatno", 1, 0.25]],
      "placements": [["instagram","mobile_app",0.46,1.1,0.9],["facebook","mobile_app",0.34,1.0,1.0],["audience_network","mobile_app",0.2,0.4,1.6]]
    },
    {
      "name": "App Re-engagement (Mkt:RS;Ct:App_Reengage;Ph:Bof)", "objective": "OUTCOME_APP_PROMOTION",
      "budget": 34, "cpm": 6.1, "ctr": 0.02, "cvr": 0.11, "value": 0, "freq": 2.2, "ga4_spc": 0.5,
      "adsets": [["RT_Neaktivni_7_30d", 0.6, 1.1], ["RT_Istekao_Trial", 0.4, 0.9]],
      "ads": [["Static_Vrati_Se_Novi_Programi", 1, 0.6], ["Video_Streak_Podsetnik", 1, 0.4], ["Static_Premium_50pct", 2, 1.0]],
      "placements": [["instagram","mobile_app",0.5,1.1,0.9],["facebook","mobile_app",0.5,1.0,1.0]]
    }
  ],
  "ga4": {
    "google_ratio": 0.62, "meta_ratio": 0.55, "google_bounce": 0.24, "meta_bounce": 0.28, "new_share": 0.93,
    "organic": [
      {"source": "(direct)", "medium": "(none)", "campaign": "(direct)", "sessions": 4600, "cvr": 0.003, "aov": 0, "bounce": 0.16, "new_share": 0.05},
      {"source": "google-play", "medium": "organic", "campaign": "(organic)", "sessions": 310, "cvr": 0.3, "aov": 0, "bounce": 0.22, "new_share": 0.96},
      {"source": "(not set)", "medium": "(not set)", "campaign": "(not set)", "sessions": 150, "cvr": 0.08, "aov": 0, "bounce": 0.3, "new_share": 0.7},
      {"source": "google", "medium": "organic", "campaign": "(organic)", "sessions": 255, "cvr": 0.05, "aov": 0, "bounce": 0.45, "new_share": 0.8},
      {"source": "instagram", "medium": "social", "campaign": "(not set)", "sessions": 92, "cvr": 0.04, "aov": 0, "bounce": 0.5, "new_share": 0.75},
      {"source": "tiktok", "medium": "social", "campaign": "(not set)", "sessions": 71, "cvr": 0.035, "aov": 0, "bounce": 0.56, "new_share": 0.85}
    ],
    "owned": [
      {"source": "newsletter", "medium": "email", "campaign": "NL_Mesecni_Napredak_Jul", "day": 2, "sessions": 640, "cvr": 0.012, "aov": 0, "decay": 0.3},
      {"source": "newsletter", "medium": "email", "campaign": "NL_Premium_7_Dana_Besplatno", "day": 21, "sessions": 910, "cvr": 0.034, "aov": 0, "decay": 0.35},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_Novi_Program_Joga", "day": 4, "sessions": 2100, "cvr": 0.01, "aov": 0, "decay": 0.25, "bounce": 0.2},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_Izazov_30_Dana_Start", "day": 8, "sessions": 2900, "cvr": 0.014, "aov": 0, "decay": 0.3, "bounce": 0.18},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_Streak_Nagrada", "day": 12, "sessions": 1700, "cvr": 0.008, "aov": 0, "decay": 0.2, "bounce": 0.2},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_Nedeljni_Izvestaj", "day": 18, "sessions": 1500, "cvr": 0.006, "aov": 0, "decay": 0.2, "bounce": 0.25},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_7_Dana_Premium_Besplatno", "day": 21, "sessions": 3300, "cvr": 0.031, "aov": 0, "decay": 0.35, "bounce": 0.17},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_Novi_Trener_Program", "day": 25, "sessions": 1900, "cvr": 0.011, "aov": 0, "decay": 0.25, "bounce": 0.2},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_Vikend_Izazov", "day": 29, "sessions": 2200, "cvr": 0.012, "aov": 0, "decay": 0.25, "bounce": 0.19}
    ],
    "automations": [
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_Dnevni_Podsetnik_Trening", "sessions": 780, "cvr": 0.004, "aov": 0, "bounce": 0.15},
      {"source": "newsletter", "medium": "email", "campaign": "AbandCart_Premium_Checkout", "sessions": 16, "cvr": 0.17, "aov": 0, "bounce": 0.2}
    ]
  },
  "plan": [
    {"network": "google", "flight_type": "Always-on", "ad_set_type": "MULTI_CHANNEL", "label": "UAC Android + iOS + Re-engagement", "pace": 1.04},
    {"network": "google", "flight_type": "Always-on", "ad_set_type": "SEARCH", "label": "Search Brand + Generic", "pace": 0.86},
    {"network": "meta", "flight_type": "Always-on", "ad_set_type": "Bucket", "label": "App Install Prospecting + Advantage+ (Ct:App)",
      "pace": 1.13, "campaigns": ["App Install Prospecting (Mkt:RS;Ct:App;Ph:Tof)", "App Install Advantage+ (Mkt:RS;Ct:App;Ph:Tof)"]},
    {"network": "meta", "flight_type": "Always-on", "ad_set_type": "Bucket", "label": "App Re-engagement (Ct:App)",
      "pace": 0.97, "campaigns": ["App Re-engagement (Mkt:RS;Ct:App_Reengage;Ph:Bof)"]}
  ],
  "report_rows": [
    {"label": "UAC Android", "channel": "google", "level": "google_ad_group", "campaigns": ["FitPuls UAC Android Installs (Mkt:RS;Ct:App;Ph:Tof)"], "note": "Demo podaci — po ad grupi"},
    {"label": "UAC iOS", "channel": "google", "level": "campaign", "campaigns": ["FitPuls UAC iOS Installs (Mkt:RS;Ct:App;Ph:Tof)"]},
    {"label": "UAC Re-engagement", "channel": "google", "level": "campaign", "campaigns": ["FitPuls UAC Re-engagement (Mkt:RS;Ct:App_Reengage;Ph:Bof)"]},
    {"label": "Search (Brand + Generic)", "channel": "google", "level": "campaign", "campaigns": ["FitPuls Brand Search (Mkt:RS;Ct:Brand_Search;Ph:Bof)", "Generic Fitness App Search (Mkt:RS;Ct:Generic_Search;Ph:Tof)"]},
    {"label": "Meta App Install", "channel": "meta", "level": "meta_ad_set", "campaigns": ["App Install Prospecting (Mkt:RS;Ct:App;Ph:Tof)"], "note": "Demo podaci — po ad setu"},
    {"label": "Meta Advantage+ App", "channel": "meta", "level": "campaign", "campaigns": ["App Install Advantage+ (Mkt:RS;Ct:App;Ph:Tof)"]},
    {"label": "Meta Re-engagement", "channel": "meta", "level": "campaign", "campaigns": ["App Re-engagement (Mkt:RS;Ct:App_Reengage;Ph:Bof)"]}
  ]
}
$json$::jsonb);

-- =====================================================================================
-- 4. AWARENESS / REACH — Izvor Voda (mineral water, new flavour launch). High reach and
--    impressions, cheap CPM, video views / ThruPlays, almost no conversions (store
--    locator searches only). Story: launch burst in week 1, festival sponsorship 20–23.
-- =====================================================================================
insert into demo.templates (slug, sort_order, config) values ('demo-awareness', 4, $json$
{
  "slug": "demo-awareness",
  "name": "Izvor Voda · Awareness",
  "business_type": "awareness",
  "sort_order": 4,
  "tagline": "Lansiranje novih ukusa · reach, CPM, video pregledi",
  "seed": 20260804,
  "dow": [1.0, 1.0, 0.99, 1.0, 1.02, 1.04, 1.03],
  "trend": -0.05,
  "cvr_trend": 0,
  "events": [
    {"from": 1, "to": 7, "spend": 1.38, "cvr": 1.0, "traffic": 1.25, "label": "Lansiranje - udarna nedelja"},
    {"from": 20, "to": 23, "spend": 1.2, "cvr": 1.3, "traffic": 1.45, "label": "Sponzorstvo letnjeg festivala"}
  ],
  "google": [
    {
      "name": "YouTube TrueView Lansiranje (Mkt:RS;Ct:Video;Ph:Tof)", "type": "VIDEO",
      "budget": 92, "cpc": 1.9, "ctr": 0.0024, "cvr": 0, "value": 0, "zero_conv": true, "view_rate": 0.31, "freq": 2.8, "ga4_bounce": 0.62,
      "ad_groups": [["YT_InStream_18_34", 0.55, 1.0], ["YT_InStream_35_54", 0.45, 1.0]]
    },
    {
      "name": "YouTube Bumper Reach (Mkt:RS;Ct:Video;Ph:Tof)", "type": "VIDEO",
      "budget": 54, "cpc": 1.4, "ctr": 0.0018, "cvr": 0, "value": 0, "zero_conv": true, "view_rate": 0, "freq": 3.4, "ga4_bounce": 0.68,
      "ad_groups": [["YT_Bumper_6s_Sirok_Reach", 1.0, 1.0]]
    },
    {
      "name": "Display Reach Izvor (Mkt:RS;Ct:Display;Ph:Tof)", "type": "DISPLAY",
      "budget": 40, "cpc": 0.15, "ctr": 0.0048, "cvr": 0.0012, "value": 0, "freq": 3.1, "ga4_bounce": 0.71,
      "ad_groups": [["Affinity_Zdrav_Zivot", 0.45, 1.0], ["Affinity_Sport_Fitness", 0.35, 1.0], ["Placements_Portali_Vesti", 0.2, 1.0]]
    },
    {
      "name": "Demand Gen Shorts Ukusi (Mkt:RS;Ct:DemandGen;Ph:Tof)", "type": "DEMAND_GEN",
      "budget": 30, "cpc": 0.18, "ctr": 0.009, "cvr": 0.002, "value": 0, "view_rate": 0.12, "freq": 2.4,
      "ad_groups": [["DG_Shorts_Limun_Menta", 0.55, 1.0], ["DG_Discover_Nar_Borovnica", 0.45, 1.0]]
    },
    {
      "name": "Izvor Brand Search (Mkt:RS;Ct:Brand_Search;Ph:Bof)", "type": "SEARCH",
      "budget": 6, "cpc": 0.09, "ctr": 0.15, "cvr": 0.05, "value": 0, "is": 0.94, "lost_budget_share": 0.1,
      "ad_groups": [["Brand", 1.0, 1.0]],
      "keywords": [["izvor voda", "EXACT", 10, 0.4, 0.8], ["izvor ukusi", "PHRASE", 9, 0.3, 1.1], ["izvor limun menta", "PHRASE", 9, 0.18, 1.0], ["gde kupiti izvor vodu", "PHRASE", 8, 0.12, 2.5]],
      "terms": [
        ["izvor voda", 1, 0.7, 0.8], ["izvor voda sastav", 1, 0.3, 0.0],
        ["izvor novi ukusi", 2, 0.6, 1.1], ["izvor voda sa ukusom", 2, 0.4, 1.0],
        ["izvor limun menta", 3, 1.0, 1.0],
        ["gde kupiti izvor vodu", 4, 0.6, 2.5], ["izvor voda maxi", 4, 0.4, 2.0]
      ]
    }
  ],
  "meta": [
    {
      "name": "Social Reach & Frequency Lansiranje (Mkt:RS;Ct:Reach;Ph:Tof)", "objective": "OUTCOME_AWARENESS",
      "budget": 78, "cpm": 1.3, "ctr": 0.0035, "cvr": 0, "value": 0, "freq": 1.9, "view_rate": 0.21, "ga4_bounce": 0.69,
      "adsets": [["Reach_Srbija_18_54", 0.7, 1.0], ["Reach_Beograd_NoviSad_18_34", 0.3, 1.0]],
      "ads": [["Video_15s_Limun_Menta", 1, 0.45], ["Video_6s_Teaser", 1, 0.3], ["Static_Novi_Ukusi_Lineup", 1, 0.25], ["Reels_Festival_Leto", 2, 1.0]]
    },
    {
      "name": "Social Video Views ThruPlay (Mkt:RS;Ct:Video;Ph:Tof)", "objective": "OUTCOME_ENGAGEMENT",
      "budget": 58, "cpm": 1.9, "ctr": 0.004, "cvr": 0, "value": 0, "freq": 1.6, "view_rate": 0.38, "ga4_bounce": 0.64,
      "adsets": [["Uzrast_18_24", 0.34, 1.0], ["Uzrast_25_34", 0.38, 1.0], ["Uzrast_35_54", 0.28, 1.0]],
      "ads": [["Video_15s_Limun_Menta", 1, 0.5], ["Reels_Festival_Leto", 1, 0.5], ["Video_15s_Limun_Menta", 2, 0.6], ["Video_30s_Brand_Story", 2, 0.4], ["Video_30s_Brand_Story", 3, 1.0]]
    },
    {
      "name": "Social Nagradna Igra Engagement (Mkt:RS;Ct:Awareness;Ph:Tof)", "objective": "OUTCOME_ENGAGEMENT",
      "budget": 24, "cpm": 2.4, "ctr": 0.018, "cvr": 0.06, "value": 0, "freq": 1.5, "ga4_bounce": 0.58, "from": 8, "to": 26,
      "adsets": [["Engagement_Fanovi_i_LAL", 1.0, 1.0]],
      "ads": [["Static_Nagradna_Igra_Festival_Karte", 1, 0.6], ["Carousel_Pogodi_Ukus", 1, 0.4]]
    },
    {
      "name": "Traffic Store Locator (Mkt:RS;Ct:Traffic;Ph:Bof)", "objective": "OUTCOME_TRAFFIC",
      "budget": 20, "cpm": 3.1, "ctr": 0.012, "cvr": 0.03, "value": 0, "freq": 1.5, "ga4_bounce": 0.45,
      "adsets": [["RT_Video_Gledaoci_75pct", 0.6, 1.2], ["Geo_5km_Maloprodaja", 0.4, 0.8]],
      "ads": [["Static_Pronadji_Najblizu_Prodavnicu", 1, 1.0], ["Static_Pronadji_Najblizu_Prodavnicu_Geo", 2, 1.0]]
    }
  ],
  "ga4": {
    "google_ratio": 0.8, "meta_ratio": 0.7, "google_bounce": 0.6, "meta_bounce": 0.62, "new_share": 0.88,
    "organic": [
      {"source": "google", "medium": "organic", "campaign": "(organic)", "sessions": 175, "cvr": 0.012, "aov": 0, "bounce": 0.44, "new_share": 0.7},
      {"source": "(direct)", "medium": "(none)", "campaign": "(direct)", "sessions": 88, "cvr": 0.01, "aov": 0, "bounce": 0.4, "new_share": 0.5},
      {"source": "instagram", "medium": "social", "campaign": "(not set)", "sessions": 150, "cvr": 0.004, "aov": 0, "bounce": 0.58, "new_share": 0.8},
      {"source": "facebook", "medium": "social", "campaign": "(not set)", "sessions": 58, "cvr": 0.003, "aov": 0, "bounce": 0.6, "new_share": 0.75},
      {"source": "tiktok", "medium": "social", "campaign": "(not set)", "sessions": 46, "cvr": 0.002, "aov": 0, "bounce": 0.63, "new_share": 0.9}
    ],
    "owned": [
      {"source": "newsletter", "medium": "email", "campaign": "NL_Lansiranje_Novih_Ukusa", "day": 1, "sessions": 520, "cvr": 0.015, "aov": 0, "decay": 0.3},
      {"source": "newsletter", "medium": "email", "campaign": "NL_Festival_Nagradna_Igra", "day": 19, "sessions": 460, "cvr": 0.03, "aov": 0, "decay": 0.35},
      {"source": "newsletter", "medium": "email", "campaign": "NL_Nagradna_Igra_Pobednici", "day": 27, "sessions": 310, "cvr": 0.008, "aov": 0, "decay": 0.3},
      {"source": "push_notification", "medium": "web_push", "campaign": "Push_Festival_Izvor_Stand", "day": 20, "sessions": 240, "cvr": 0.02, "aov": 0, "decay": 0.3}
    ],
    "automations": []
  },
  "plan": [
    {"network": "google", "flight_type": "Always-on", "ad_set_type": "VIDEO", "label": "YouTube TrueView + Bumper", "pace": 1.02},
    {"network": "google", "flight_type": "Always-on", "ad_set_type": "DISPLAY", "label": "Display Reach", "pace": 0.95},
    {"network": "google", "flight_type": "Always-on", "ad_set_type": "DEMAND_GEN", "label": "Demand Gen Shorts", "pace": 1.12},
    {"network": "google", "flight_type": "Always-on", "ad_set_type": "SEARCH", "label": "Brand Search", "pace": 0.8},
    {"network": "meta", "flight_type": "Always-on", "ad_set_type": "Bucket", "label": "Social Reach + Video Views",
      "pace": 1.0, "campaigns": ["Social Reach & Frequency Lansiranje (Mkt:RS;Ct:Reach;Ph:Tof)", "Social Video Views ThruPlay (Mkt:RS;Ct:Video;Ph:Tof)"]},
    {"network": "meta", "flight_type": "Flight", "ad_set_type": "Bucket", "label": "Social Nagradna igra (flight)",
      "pace": 0.92, "from": 8, "to": 26, "campaigns": ["Social Nagradna Igra Engagement (Mkt:RS;Ct:Awareness;Ph:Tof)"]},
    {"network": "meta", "flight_type": "Always-on", "ad_set_type": "Bucket", "label": "Traffic - Store locator",
      "pace": 1.07, "campaigns": ["Traffic Store Locator (Mkt:RS;Ct:Traffic;Ph:Bof)"]}
  ],
  "report_rows": [
    {"label": "YouTube TrueView", "channel": "google", "level": "google_ad_group", "campaigns": ["YouTube TrueView Lansiranje (Mkt:RS;Ct:Video;Ph:Tof)"], "note": "Demo podaci — po ad grupi"},
    {"label": "YouTube Bumper", "channel": "google", "level": "campaign", "campaigns": ["YouTube Bumper Reach (Mkt:RS;Ct:Video;Ph:Tof)"]},
    {"label": "Display Reach", "channel": "google", "level": "campaign", "campaigns": ["Display Reach Izvor (Mkt:RS;Ct:Display;Ph:Tof)"]},
    {"label": "Demand Gen Shorts", "channel": "google", "level": "campaign", "campaigns": ["Demand Gen Shorts Ukusi (Mkt:RS;Ct:DemandGen;Ph:Tof)"]},
    {"label": "Meta Reach & Frequency", "channel": "meta", "level": "campaign", "campaigns": ["Social Reach & Frequency Lansiranje (Mkt:RS;Ct:Reach;Ph:Tof)"]},
    {"label": "Meta Video Views", "channel": "meta", "level": "meta_ad_set", "campaigns": ["Social Video Views ThruPlay (Mkt:RS;Ct:Video;Ph:Tof)"], "note": "Demo podaci — po ad setu (uzrasne grupe)"},
    {"label": "Meta Nagradna igra", "channel": "meta", "level": "campaign", "campaigns": ["Social Nagradna Igra Engagement (Mkt:RS;Ct:Awareness;Ph:Tof)"]},
    {"label": "Meta Store Locator", "channel": "meta", "level": "campaign", "campaigns": ["Traffic Store Locator (Mkt:RS;Ct:Traffic;Ph:Bof)"]}
  ]
}
$json$::jsonb);
