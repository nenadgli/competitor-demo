-- Brain Reporting DEMO — 5th template: large multi-market fashion retailer.
-- Urban Style (invented): ~€70k/month across RS / HR / BA, Google + Meta, app, push and
-- newsletter. August story: end of the summer sale (1–9), FW26 pre-collection launch
-- (18–20), back to school (26–31); summer lines fade while FW ramps up; a competitor
-- (ModaHub) answers the launch with an autumn promo (20–24); the summer sale video
-- creative wears out; HR has the highest AOV, BA the cheapest traffic.

insert into demo.templates (slug, sort_order, config) values ('demo-fashion', 0, $json$
{
  "slug": "demo-fashion",
  "name": "Urban Style · Fashion (RS/HR/BA)",
  "business_type": "ecommerce",
  "vertical": "fashion",
  "sort_order": 0,
  "tagline": "Fashion retailer · 3 tržišta · webshop, aplikacija i 42 prodavnice",
  "seed": 20260805,
  "dow": [1.0, 0.97, 0.96, 1.0, 1.05, 0.95, 1.12],
  "trend": 0.05,
  "cvr_trend": 0.06,
  "launch_day": 18,
  "bts_day": 24,
  "market_price": {"RS": 1.0, "HR": 1.12, "BA": 0.94},
  "events": [
    {"from": 1, "to": 9, "spend": 1.22, "cvr": 1.38, "traffic": 1.28, "label": "Summer Sale finale do -50%", "type": "sale"},
    {"from": 18, "to": 20, "spend": 1.25, "cvr": 1.08, "traffic": 1.3, "label": "Lansiranje FW26 pre-kolekcije", "type": "launch"},
    {"from": 26, "to": 31, "spend": 1.1, "cvr": 1.14, "traffic": 1.12, "label": "Back to school", "type": "sale"}
  ],
  "google": [
    {
      "name": "Urban Style Brand RS (Mkt:RS;Ct:Brand_Search;Ph:Bof)", "type": "SEARCH",
      "budget": 68, "cpc": 0.17, "ctr": 0.22, "cvr": 0.074, "value": 71, "is": 0.92, "lost_budget_share": 0.1,
      "ad_groups": [["Brand - Webshop", 0.72, 1.0], ["Brand - Prodavnice", 0.28, 0.7]],
      "keywords": [
        ["urban style", "EXACT", 10, 0.5, 1.0], ["urban style online", "PHRASE", 9, 0.22, 1.15],
        ["urbanstyle rs", "EXACT", 9, 0.14, 1.05], ["urban style prodavnice", "PHRASE", 8, 0.14, 0.55]
      ],
      "terms": [
        ["urban style", 1, 0.8, 1.0], ["urban style srbija", 1, 0.2, 1.0],
        ["urban style online shop", 2, 0.6, 1.15], ["urban style akcija", 2, 0.4, 1.35],
        ["urbanstyle.rs", 3, 1.0, 1.0],
        ["urban style radno vreme", 4, 0.45, 0.0], ["urban style ušće", 4, 0.3, 0.6], ["urban style novi sad", 4, 0.25, 0.6]
      ],
      "competitors": [["modahub.rs", 0.45], ["fastfit.rs", 0.25], ["zara.com", 0.3]]
    },
    {
      "name": "Generic Moda RS (Mkt:RS;Ct:Generic_Search;Ph:Bof)", "type": "SEARCH",
      "budget": 148, "cpc": 0.38, "ctr": 0.056, "cvr": 0.021, "value": 63, "is": 0.49, "lost_budget_share": 0.55,
      "ad_groups": [["Jakne i kaputi", 0.26, 1.0], ["Obuća", 0.3, 1.15], ["Džemperi i trikotaža", 0.18, 0.95], ["Torbe", 0.14, 0.9], ["Sport", 0.12, 0.85]],
      "keywords": [
        ["ženske jakne", "PHRASE", 7, 0.16, 1.0], ["kožne čizme", "PHRASE", 7, 0.13, 1.15],
        ["bele patike ženske", "PHRASE", 8, 0.14, 1.3], ["muški džemper", "BROAD", 5, 0.1, 0.85],
        ["trench kaput", "PHRASE", 7, 0.09, 1.05], ["ženske torbe", "BROAD", 5, 0.12, 0.8],
        ["trenerke komplet", "PHRASE", 6, 0.1, 0.9], ["odeća online prodavnica", "BROAD", 4, 0.1, 0.55],
        ["dečje patike", "PHRASE", 7, 0.06, 1.2]
      ],
      "terms": [
        ["ženske jakne", 1, 0.45, 1.0], ["prelazne jakne ženske", 1, 0.35, 1.05], ["jakne polovne", 1, 0.12, 0.0],
        ["kožne čizme ženske", 2, 0.55, 1.2], ["chelsea čizme", 2, 0.3, 1.1],
        ["bele patike ženske", 3, 0.6, 1.3], ["bele patike kako očistiti", 3, 0.2, 0.0],
        ["muški džemper merino", 4, 0.5, 0.9], ["muški džemper pletenje šema", 4, 0.2, 0.0],
        ["trench kaput bež", 5, 0.7, 1.1],
        ["ženske torbe kožne", 6, 0.5, 0.9], ["torbe replike", 6, 0.2, 0.0],
        ["trenerke komplet ženske", 7, 0.6, 0.9],
        ["odeća online prodavnica", 8, 0.5, 0.6], ["besplatna dostava odeća", 8, 0.3, 0.8],
        ["dečje patike za školu", 9, 1.0, 1.3]
      ],
      "competitors": [["modahub.rs", 0.8], ["fastfit.rs", 0.55], ["zara.com", 0.5], ["hm.com", 0.45], ["aboutyou.rs", 0.5]]
    },
    {
      "name": "PMax Katalog RS (Mkt:RS;Ct:PMax)", "type": "PERFORMANCE_MAX",
      "budget": 470, "cpc": 0.25, "ctr": 0.013, "cvr": 0.022, "value": 66, "freq": 3.2, "products": true,
      "asset_groups": [["AG_Zenska_Odeca", 0.3, 1.0], ["AG_Muska_Odeca", 0.2, 0.95], ["AG_Obuca", 0.26, 1.1], ["AG_Torbe_Aksesoari", 0.12, 0.95], ["AG_FW26_Kolekcija", 0.12, 1.05]]
    },
    {
      "name": "Shopping Bestseleri RS (Mkt:RS;Ct:Shopping;Ph:Bof)", "type": "SHOPPING",
      "budget": 118, "cpc": 0.21, "ctr": 0.011, "cvr": 0.026, "value": 61, "products": true,
      "ad_groups": [["Bestseleri - Svi proizvodi", 1.0, 1.0]]
    },
    {
      "name": "Dinamički Remarketing RS (Mkt:RS;Ct:Display_Dyn;Ph:Bof)", "type": "DISPLAY",
      "budget": 58, "cpc": 0.15, "ctr": 0.009, "cvr": 0.019, "value": 60, "freq": 4.3,
      "ad_groups": [["RMK_Pregled_Proizvoda_7d", 0.55, 1.0], ["RMK_Korpa_14d", 0.45, 1.5]]
    },
    {
      "name": "Demand Gen FW26 Lansiranje (Mkt:RS;Ct:DemandGen;Ph:Tof)", "type": "DEMAND_GEN",
      "budget": 96, "cpc": 0.14, "ctr": 0.011, "cvr": 0.006, "value": 74, "view_rate": 0.1, "from": 16,
      "ad_groups": [["DG_Shorts_FW26_Lookbook", 0.5, 0.8], ["DG_Discover_Gmail_FW26", 0.5, 1.2]]
    },
    {
      "name": "YouTube FW26 Kampanja (Mkt:RS;Ct:Video;Ph:Tof)", "type": "VIDEO",
      "budget": 72, "cpc": 1.8, "ctr": 0.0026, "cvr": 0, "value": 0, "zero_conv": true, "view_rate": 0.32, "freq": 2.7, "from": 18, "ga4_bounce": 0.64,
      "ad_groups": [["YT_InStream_FW26_18_34", 0.55, 1.0], ["YT_InStream_FW26_35_54", 0.45, 1.0]]
    },
    {
      "name": "Urban Style Brand HR (Mkt:HR;Ct:Brand_Search;Ph:Bof)", "type": "SEARCH",
      "budget": 34, "cpc": 0.27, "ctr": 0.2, "cvr": 0.068, "value": 88, "is": 0.9, "lost_budget_share": 0.12,
      "ad_groups": [["Brand HR", 1.0, 1.0]],
      "keywords": [["urban style", "EXACT", 10, 0.6, 1.0], ["urban style hrvatska", "PHRASE", 9, 0.25, 1.1], ["urban style zagreb", "PHRASE", 8, 0.15, 0.7]],
      "terms": [["urban style", 1, 1.0, 1.0], ["urban style hr webshop", 2, 1.0, 1.1], ["urban style arena zagreb", 3, 0.6, 0.6], ["urban style zagreb radno vrijeme", 3, 0.4, 0.0]],
      "competitors": [["stylecorner.hr", 0.55], ["zara.com", 0.3]]
    },
    {
      "name": "Generic Moda HR (Mkt:HR;Ct:Generic_Search;Ph:Bof)", "type": "SEARCH",
      "budget": 84, "cpc": 0.54, "ctr": 0.05, "cvr": 0.019, "value": 80, "is": 0.44, "lost_budget_share": 0.6,
      "ad_groups": [["Jakne i kaputi HR", 0.34, 1.0], ["Obuća HR", 0.38, 1.1], ["Torbe HR", 0.28, 0.9]],
      "keywords": [
        ["ženske jakne", "PHRASE", 7, 0.25, 1.0], ["kožne čizme", "PHRASE", 7, 0.22, 1.1],
        ["bijele tenisice", "PHRASE", 8, 0.2, 1.25], ["ženske torbe", "BROAD", 5, 0.18, 0.8], ["muški puloveri", "BROAD", 5, 0.15, 0.85]
      ],
      "terms": [
        ["ženske jakne online", 1, 0.6, 1.0], ["ženske jakne rasprodaja", 1, 0.3, 1.2],
        ["kožne čizme ženske", 2, 0.7, 1.1], ["čizme second hand", 2, 0.2, 0.0],
        ["bijele tenisice ženske", 3, 1.0, 1.25],
        ["ženske torbe kožne", 4, 0.6, 0.85], ["muški puloveri vuna", 5, 0.7, 0.85]
      ],
      "competitors": [["stylecorner.hr", 0.85], ["zara.com", 0.5], ["aboutyou.hr", 0.55]]
    },
    {
      "name": "PMax Katalog HR (Mkt:HR;Ct:PMax)", "type": "PERFORMANCE_MAX",
      "budget": 300, "cpc": 0.34, "ctr": 0.012, "cvr": 0.02, "value": 82, "freq": 3.0, "products": true,
      "asset_groups": [["AG_HR_Zenska_Odeca", 0.34, 1.0], ["AG_HR_Obuca", 0.3, 1.1], ["AG_HR_Muska_Odeca", 0.2, 0.95], ["AG_HR_FW26", 0.16, 1.0]]
    },
    {
      "name": "Dinamički Remarketing HR (Mkt:HR;Ct:Display_Dyn;Ph:Bof)", "type": "DISPLAY",
      "budget": 34, "cpc": 0.2, "ctr": 0.0085, "cvr": 0.017, "value": 79, "freq": 4.1,
      "ad_groups": [["RMK_HR_Pregled_7d", 0.55, 1.0], ["RMK_HR_Korpa_14d", 0.45, 1.4]]
    },
    {
      "name": "Urban Style Brand BA (Mkt:BA;Ct:Brand_Search;Ph:Bof)", "type": "SEARCH",
      "budget": 12, "cpc": 0.1, "ctr": 0.21, "cvr": 0.06, "value": 57, "is": 0.95, "lost_budget_share": 0.1,
      "ad_groups": [["Brand BA", 1.0, 1.0]],
      "keywords": [["urban style", "EXACT", 10, 0.7, 1.0], ["urban style sarajevo", "PHRASE", 9, 0.3, 0.8]],
      "terms": [["urban style", 1, 1.0, 1.0], ["urban style sarajevo scc", 2, 0.6, 0.8], ["urban style banja luka", 2, 0.4, 0.8]],
      "competitors": [["trendybox.ba", 0.5]]
    },
    {
      "name": "PMax Katalog BA (Mkt:BA;Ct:PMax)", "type": "PERFORMANCE_MAX",
      "budget": 108, "cpc": 0.16, "ctr": 0.014, "cvr": 0.014, "value": 55, "freq": 3.3, "products": true,
      "asset_groups": [["AG_BA_Svi_Proizvodi", 0.7, 1.0], ["AG_BA_Obuca", 0.3, 1.1]]
    }
  ],
  "meta": [
    {
      "name": "Katalog Prospecting RS (Mkt:RS;Ct:Conversions;Ph:Tof)", "objective": "OUTCOME_SALES",
      "budget": 255, "cpm": 3.9, "ctr": 0.013, "cvr": 0.019, "value": 58, "freq": 1.24, "view_rate": 0.06,
      "adsets": [["Broad_22_55 Advantage+ audience", 0.46, 1.0], ["LAL_Kupci_180d_3pct", 0.32, 1.25], ["Interest_Moda_Shopping", 0.22, 0.75]],
      "ads": [
        ["Video_Summer_Sale_do_50pct", 1, 0.45, 0.7, 1], ["Carousel_Bestseleri_Leto", 1, 0.3, 0.3, 1], ["Reels_FW26_Lookbook", 1, 0.55, 0.1, 18],
        ["Reels_UGC_Styling_Ana", 2, 0.5, 0.2, 1], ["DPA_Katalog_Bestseleri", 2, 0.5, 0.1, 1], ["Carousel_FW26_Novo", 2, 0.45, 0.05, 18],
        ["Static_Besplatna_Dostava", 3, 0.5, 0.35, 1], ["Video_Back_To_School", 3, 0.45, 0.0, 24]
      ]
    },
    {
      "name": "DPA Retargeting RS (Mkt:RS;Ct:Conversions;Ph:Bof)", "objective": "OUTCOME_SALES",
      "budget": 118, "cpm": 7.4, "ctr": 0.021, "cvr": 0.043, "value": 63, "freq": 1.95,
      "adsets": [["RT_ViewContent_7d", 0.42, 0.9], ["RT_AddToCart_14d", 0.38, 1.4], ["RT_Kupci_180d", 0.2, 0.8]],
      "ads": [
        ["DPA_Pregledani_Proizvodi", 1, 1.0, 0.1, 1],
        ["DPA_Korpa_Podsetnik", 2, 0.6, 0.15, 1], ["Static_Kupon_10pct_Korpa", 2, 0.4, 0.25, 1],
        ["Carousel_Novo_Za_Vas_FW26", 3, 1.0, 0.05, 1]
      ]
    },
    {
      "name": "Katalog Prospecting HR (Mkt:HR;Ct:Conversions;Ph:Tof)", "objective": "OUTCOME_SALES",
      "budget": 168, "cpm": 5.3, "ctr": 0.012, "cvr": 0.018, "value": 79, "freq": 1.22,
      "adsets": [["HR_Broad_22_55 Advantage+", 0.6, 1.0], ["HR_LAL_Kupci_3pct", 0.4, 1.2]],
      "ads": [
        ["HR_Video_Summer_Sale", 1, 0.5, 0.65, 1], ["HR_Reels_FW26_Lookbook", 1, 0.5, 0.1, 18],
        ["HR_DPA_Bestseleri", 2, 1.0, 0.1, 1]
      ]
    },
    {
      "name": "DPA Retargeting HR (Mkt:HR;Ct:Conversions;Ph:Bof)", "objective": "OUTCOME_SALES",
      "budget": 70, "cpm": 9.0, "ctr": 0.02, "cvr": 0.04, "value": 84, "freq": 2.0,
      "adsets": [["HR_RT_ViewContent_AddToCart_14d", 1.0, 1.0]],
      "ads": [["HR_DPA_Pregledani_Proizvodi", 1, 1.0, 0.1, 1]]
    },
    {
      "name": "Advantage Plus Shopping BA (Mkt:BA;Ct:Conversions;Ph:Tof)", "objective": "OUTCOME_SALES",
      "budget": 60, "cpm": 2.2, "ctr": 0.015, "cvr": 0.013, "value": 54, "freq": 1.3,
      "adsets": [["BA_ASC_Svi_Kupci", 1.0, 1.0]],
      "ads": [["BA_Video_Sale", 1, 0.5, 0.5, 1], ["BA_DPA_Katalog", 1, 0.5, 0.1, 1]]
    },
    {
      "name": "Social FW26 Lansiranje Reach (Mkt:RS;Ct:Awareness;Ph:Tof)", "objective": "OUTCOME_AWARENESS",
      "budget": 92, "cpm": 1.5, "ctr": 0.004, "cvr": 0, "value": 0, "freq": 1.8, "view_rate": 0.24, "from": 17, "ga4_bounce": 0.66,
      "adsets": [["Reach_RS_HR_BA_18_45", 1.0, 1.0]],
      "ads": [["Video_FW26_Brand_Film_30s", 1, 0.6, 0.0, 17], ["Reels_FW26_Backstage", 1, 0.4, 0.0, 17]]
    },
    {
      "name": "Urban Style App Installs (Mkt:RS;Ct:App;Ph:Tof)", "objective": "APP_INSTALLS",
      "budget": 34, "cpm": 3.0, "ctr": 0.011, "cvr": 0.24, "value": 0, "freq": 1.3, "ga4_spc": 0.05,
      "adsets": [["App_Android_Broad", 0.6, 1.0], ["App_iOS_Broad", 0.4, 0.85]],
      "ads": [["Video_App_Clanski_Popusti", 1, 1.0, 0.2, 1], ["Video_App_Clanski_Popusti_iOS", 2, 1.0, 0.2, 1]],
      "placements": [["instagram","mobile_app",0.46,1.1,0.9],["facebook","mobile_app",0.38,1.0,1.0],["audience_network","mobile_app",0.16,0.4,1.6]]
    }
  ],
  "catalog": [
    ["US-W-101", "Lanena haljina midi", "Ženska odeća", 49, 0.05, 1.0, "SS"],
    ["US-W-102", "Trench kaput bež", "Ženska odeća", 129, 0.04, 0.9, "FW"],
    ["US-W-103", "Pleteni džemper oversize", "Ženska odeća", 59, 0.045, 1.0, "FW"],
    ["US-W-104", "Mom fit farmerke", "Ženska odeća", 45, 0.06, 1.1, "core"],
    ["US-W-105", "Satenska bluza", "Ženska odeća", 39, 0.03, 0.9, "core"],
    ["US-W-106", "Kožna jakna crna", "Ženska odeća", 149, 0.035, 0.85, "FW"],
    ["US-W-107", "Letnji kombinezon", "Ženska odeća", 42, 0.03, 0.9, "SS"],
    ["US-M-201", "Slim fit farmerke", "Muška odeća", 49, 0.05, 1.0, "core"],
    ["US-M-202", "Lanena košulja", "Muška odeća", 39, 0.035, 0.95, "SS"],
    ["US-M-203", "Prošivena jakna", "Muška odeća", 119, 0.035, 0.85, "FW"],
    ["US-M-204", "Merino džemper", "Muška odeća", 69, 0.03, 0.95, "FW"],
    ["US-M-205", "Basic majice 3-pack", "Muška odeća", 25, 0.05, 1.2, "core"],
    ["US-S-301", "Bele kožne patike", "Obuća", 79, 0.07, 1.25, "core"],
    ["US-S-302", "Chelsea čizme", "Obuća", 119, 0.04, 0.95, "FW"],
    ["US-S-303", "Sandale na platformu", "Obuća", 55, 0.035, 0.9, "SS"],
    ["US-S-304", "Running patike", "Obuća", 95, 0.04, 1.0, "core"],
    ["US-S-305", "Kožne mokasine", "Obuća", 89, 0.02, 0.85, "core"],
    ["US-A-401", "Kožna tote torba", "Torbe i aksesoari", 89, 0.035, 0.9, "core"],
    ["US-A-402", "Crossbody torbica", "Torbe i aksesoari", 45, 0.04, 1.05, "core"],
    ["US-A-403", "Vuneni šal", "Torbe i aksesoari", 25, 0.02, 0.9, "FW"],
    ["US-A-404", "Sunčane naočare", "Torbe i aksesoari", 35, 0.025, 0.85, "SS"],
    ["US-P-501", "Trenerka komplet", "Sport", 69, 0.035, 1.0, "core"],
    ["US-P-502", "Helanke za trening", "Sport", 32, 0.03, 1.05, "core"],
    ["US-P-503", "Sportski grudnjak", "Sport", 28, 0.02, 1.0, "core"],
    ["US-K-601", "Dečji ranac", "Dečji program", 35, 0.03, 1.1, "BTS"],
    ["US-K-602", "Dečje patike", "Dečji program", 45, 0.035, 1.15, "BTS"],
    ["US-K-603", "Dečja jakna", "Dečji program", 55, 0.02, 0.9, "FW"]
  ],
  "competition": {
    "categories": ["Ženska odeća", "Muška odeća", "Obuća", "Torbe i aksesoari", "Sport", "Dečji program"],
    "competitors": [
      {"name": "ModaHub", "domain": "modahub.rs", "price_index": 0.95, "discount": 0.3, "arrivals": 140, "ads": 46,
        "promo": {"from": 20, "to": 24, "boost": 0.28, "label": "Jesenji popust -30%"}},
      {"name": "StyleCorner", "domain": "stylecorner.hr", "price_index": 1.09, "discount": 0.22, "arrivals": 85, "ads": 28},
      {"name": "FastFit", "domain": "fastfit.rs", "price_index": 0.8, "discount": 0.38, "arrivals": 210, "ads": 64},
      {"name": "Trendy Box", "domain": "trendybox.ba", "price_index": 0.9, "discount": 0.26, "arrivals": 40, "ads": 12}
    ]
  },
  "ga4": {
    "google_ratio": 0.88, "meta_ratio": 0.47, "google_bounce": 0.34, "meta_bounce": 0.55, "new_share": 0.58,
    "organic": [
      {"source": "google", "medium": "organic", "campaign": "(organic)", "store": "RS", "sessions": 3150, "cvr": 0.016, "aov": 66, "bounce": 0.36, "new_share": 0.52},
      {"source": "(direct)", "medium": "(none)", "campaign": "(direct)", "store": "RS", "sessions": 2050, "cvr": 0.023, "aov": 69, "bounce": 0.29, "new_share": 0.3},
      {"source": "google", "medium": "organic", "campaign": "(organic)", "store": "HR", "sessions": 1650, "cvr": 0.015, "aov": 84, "bounce": 0.37, "new_share": 0.55},
      {"source": "(direct)", "medium": "(none)", "campaign": "(direct)", "store": "HR", "sessions": 1050, "cvr": 0.021, "aov": 86, "bounce": 0.3, "new_share": 0.32},
      {"source": "google", "medium": "organic", "campaign": "(organic)", "store": "BA", "sessions": 580, "cvr": 0.012, "aov": 55, "bounce": 0.4, "new_share": 0.6},
      {"source": "(direct)", "medium": "(none)", "campaign": "(direct)", "store": "BA", "sessions": 330, "cvr": 0.017, "aov": 57, "bounce": 0.33, "new_share": 0.36},
      {"source": "instagram", "medium": "social", "campaign": "(not set)", "store": "RS", "sessions": 720, "cvr": 0.006, "aov": 58, "bounce": 0.52, "new_share": 0.6},
      {"source": "pinterest.com", "medium": "referral", "campaign": "(referral)", "store": "RS", "sessions": 95, "cvr": 0.012, "aov": 72, "bounce": 0.41, "new_share": 0.78},
      {"source": "chatgpt.com", "medium": "referral", "campaign": "(referral)", "store": "RS", "sessions": 68, "cvr": 0.022, "aov": 75, "bounce": 0.28, "new_share": 0.8},
      {"source": "tiktok", "medium": "social", "campaign": "(not set)", "store": "RS", "sessions": 180, "cvr": 0.003, "aov": 44, "bounce": 0.61, "new_share": 0.82}
    ],
    "owned": [
      {"source": "newsletter", "medium": "email", "campaign": "NL_RS_Summer_Sale_Finale", "store": "RS", "day": 1, "sessions": 4200, "cvr": 0.041, "aov": 55, "decay": 0.35},
      {"source": "newsletter", "medium": "email", "campaign": "NL_HR_Summer_Sale_Finale", "store": "HR", "day": 1, "sessions": 2300, "cvr": 0.038, "aov": 74, "decay": 0.35},
      {"source": "newsletter", "medium": "email", "campaign": "NL_BA_Summer_Sale", "store": "BA", "day": 2, "sessions": 900, "cvr": 0.03, "aov": 50, "decay": 0.3},
      {"source": "newsletter", "medium": "email", "campaign": "NL_RS_Poslednji_Dani_Sale", "store": "RS", "day": 8, "sessions": 3600, "cvr": 0.044, "aov": 52, "decay": 0.25},
      {"source": "newsletter", "medium": "email", "campaign": "NL_RS_FW26_Pre_Kolekcija", "store": "RS", "day": 18, "sessions": 3900, "cvr": 0.027, "aov": 84, "decay": 0.4},
      {"source": "newsletter", "medium": "email", "campaign": "NL_HR_FW26_Pre_Kolekcija", "store": "HR", "day": 18, "sessions": 2100, "cvr": 0.025, "aov": 102, "decay": 0.4},
      {"source": "newsletter", "medium": "email", "campaign": "NL_RS_Back_To_School", "store": "RS", "day": 26, "sessions": 3000, "cvr": 0.031, "aov": 58, "decay": 0.3},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_Sale_Poslednja_3_Dana", "store": "RS", "day": 7, "sessions": 2400, "cvr": 0.043, "aov": 51, "decay": 0.2},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_FW26_Stiglo_Novo", "store": "RS", "day": 18, "sessions": 2900, "cvr": 0.026, "aov": 81, "decay": 0.3},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_Clanovi_Rani_Pristup_FW26", "store": "RS", "day": 17, "sessions": 1900, "cvr": 0.034, "aov": 88, "decay": 0.2},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_Vikend_Besplatna_Dostava", "store": "RS", "day": 22, "sessions": 1700, "cvr": 0.028, "aov": 63, "decay": 0.2},
      {"source": "push_notification", "medium": "mobile_app", "campaign": "Push_Back_To_School_Deca", "store": "RS", "day": 26, "sessions": 2100, "cvr": 0.033, "aov": 49, "decay": 0.25}
    ],
    "automations": [
      {"source": "newsletter", "medium": "email", "campaign": "AbandCart_RS_1h", "store": "RS", "sessions": 95, "cvr": 0.11, "aov": 72, "bounce": 0.22},
      {"source": "newsletter", "medium": "email", "campaign": "AbandCart_HR_1h", "store": "HR", "sessions": 48, "cvr": 0.1, "aov": 91, "bounce": 0.23},
      {"source": "newsletter", "medium": "email", "campaign": "AbandCart_BA_1h", "store": "BA", "sessions": 16, "cvr": 0.09, "aov": 58, "bounce": 0.25}
    ]
  },
  "plan": [
    {"network": "google", "flight_type": "Always-on", "ad_set_type": "SEARCH", "label": "Search Brand + Generic (RS/HR/BA)", "pace": 0.99},
    {"network": "google", "flight_type": "Always-on", "ad_set_type": "PERFORMANCE_MAX", "label": "PMax Katalog (RS/HR/BA)", "pace": 1.07},
    {"network": "google", "flight_type": "Always-on", "ad_set_type": "SHOPPING", "label": "Shopping Bestseleri RS", "pace": 0.93},
    {"network": "google", "flight_type": "Always-on", "ad_set_type": "DISPLAY", "label": "Dinamički remarketing RS + HR", "pace": 0.97},
    {"network": "google", "flight_type": "Flight", "ad_set_type": "DEMAND_GEN", "label": "Demand Gen - FW26 lansiranje", "pace": 0.86, "from": 16},
    {"network": "google", "flight_type": "Flight", "ad_set_type": "VIDEO", "label": "YouTube - FW26 kampanja", "pace": 1.02, "from": 18},
    {"network": "meta", "flight_type": "Always-on", "ad_set_type": "Bucket", "label": "Katalog + DPA (RS/HR/BA)", "pace": 1.04,
      "campaigns": ["Katalog Prospecting RS (Mkt:RS;Ct:Conversions;Ph:Tof)", "DPA Retargeting RS (Mkt:RS;Ct:Conversions;Ph:Bof)",
        "Katalog Prospecting HR (Mkt:HR;Ct:Conversions;Ph:Tof)", "DPA Retargeting HR (Mkt:HR;Ct:Conversions;Ph:Bof)",
        "Advantage Plus Shopping BA (Mkt:BA;Ct:Conversions;Ph:Tof)"]},
    {"network": "meta", "flight_type": "Flight", "ad_set_type": "Bucket", "label": "Social - FW26 lansiranje", "pace": 0.96, "from": 17,
      "campaigns": ["Social FW26 Lansiranje Reach (Mkt:RS;Ct:Awareness;Ph:Tof)"]},
    {"network": "meta", "flight_type": "Always-on", "ad_set_type": "Bucket", "label": "App Installs (Ct:App)", "pace": 0.91,
      "campaigns": ["Urban Style App Installs (Mkt:RS;Ct:App;Ph:Tof)"]}
  ],
  "report_rows": [
    {"label": "Search Brend (RS/HR/BA)", "channel": "google", "level": "campaign", "campaigns": ["Urban Style Brand RS (Mkt:RS;Ct:Brand_Search;Ph:Bof)", "Urban Style Brand HR (Mkt:HR;Ct:Brand_Search;Ph:Bof)", "Urban Style Brand BA (Mkt:BA;Ct:Brand_Search;Ph:Bof)"]},
    {"label": "Search Generic RS", "channel": "google", "level": "google_ad_group", "campaigns": ["Generic Moda RS (Mkt:RS;Ct:Generic_Search;Ph:Bof)"], "note": "Demo podaci — po ad grupi"},
    {"label": "Search Generic HR", "channel": "google", "level": "campaign", "campaigns": ["Generic Moda HR (Mkt:HR;Ct:Generic_Search;Ph:Bof)"]},
    {"label": "PMax Katalog RS", "channel": "google", "level": "asset_group", "campaigns": ["PMax Katalog RS (Mkt:RS;Ct:PMax)"], "note": "Demo podaci — po asset grupi"},
    {"label": "PMax Katalog HR + BA", "channel": "google", "level": "campaign", "campaigns": ["PMax Katalog HR (Mkt:HR;Ct:PMax)", "PMax Katalog BA (Mkt:BA;Ct:PMax)"]},
    {"label": "Shopping Bestseleri RS", "channel": "google", "level": "campaign", "campaigns": ["Shopping Bestseleri RS (Mkt:RS;Ct:Shopping;Ph:Bof)"]},
    {"label": "Dinamički remarketing", "channel": "google", "level": "campaign", "campaigns": ["Dinamički Remarketing RS (Mkt:RS;Ct:Display_Dyn;Ph:Bof)", "Dinamički Remarketing HR (Mkt:HR;Ct:Display_Dyn;Ph:Bof)"]},
    {"label": "FW26 lansiranje (Demand Gen + YouTube)", "channel": "google", "level": "campaign", "campaigns": ["Demand Gen FW26 Lansiranje (Mkt:RS;Ct:DemandGen;Ph:Tof)", "YouTube FW26 Kampanja (Mkt:RS;Ct:Video;Ph:Tof)"]},
    {"label": "Meta Katalog RS", "channel": "meta", "level": "meta_ad_set", "campaigns": ["Katalog Prospecting RS (Mkt:RS;Ct:Conversions;Ph:Tof)"], "note": "Demo podaci — po ad setu"},
    {"label": "Meta DPA RS + HR", "channel": "meta", "level": "campaign", "campaigns": ["DPA Retargeting RS (Mkt:RS;Ct:Conversions;Ph:Bof)", "DPA Retargeting HR (Mkt:HR;Ct:Conversions;Ph:Bof)"]},
    {"label": "Meta Katalog HR", "channel": "meta", "level": "meta_ad_set", "campaigns": ["Katalog Prospecting HR (Mkt:HR;Ct:Conversions;Ph:Tof)"], "note": "Demo podaci — po ad setu"},
    {"label": "Meta Advantage+ BA", "channel": "meta", "level": "campaign", "campaigns": ["Advantage Plus Shopping BA (Mkt:BA;Ct:Conversions;Ph:Tof)"]},
    {"label": "Social FW26 + App", "channel": "meta", "level": "campaign", "campaigns": ["Social FW26 Lansiranje Reach (Mkt:RS;Ct:Awareness;Ph:Tof)", "Urban Style App Installs (Mkt:RS;Ct:App;Ph:Tof)"]}
  ]
}
$json$::jsonb)
on conflict (slug) do update set sort_order = excluded.sort_order, config = excluded.config;
