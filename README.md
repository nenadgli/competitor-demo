# Brain Reporting Platform — DEMO

Samostalna demo verzija Brain Reporting platforme (Pilot Agencija) za prezentacije potencijalnim
klijentima i partnerima. Isti frontend i isti izveštaji kao produkcija
([nenadgli/brain-reporting](https://github.com/nenadgli/brain-reporting)), ali nad **potpuno
odvojenom Supabase bazom sa izmišljenim podacima**.

React + Vite + TypeScript + Supabase + Tailwind v4 + Recharts.

| | Produkcija | Demo |
|---|---|---|
| Supabase | `yryclxxuueupuruowjvn` | `cxzgnhfcndlzmfnyqajp` (competitors demo) |
| Podaci | Windsor.ai sync | deterministički generator (`demo.seed()`) |
| Pristup | magic link + RLS po agenciji/klijentu | javno, samo čitanje |
| Klijenti | pravi | 4 izmišljena "business template" klijenta |

## Demo klijenti (avgust 2026, ceo mesec)

| Klijent | Template | Priča u podacima |
|---|---|---|
| **Urban Style · Fashion (RS/HR/BA)** | veliki fashion retailer, ~€78k/mes | 3 tržišta, Summer Sale finale (1–9), lansiranje FW26 pre-kolekcije (18–20), back to school (26–31); letnji asortiman pada dok FW raste, konkurent ModaHub odgovara jesenjim popustom (20–24), summer sale video kreativa se "istroši" (CTR −46%), HR ima najveću korpu |
| **Moda Market · E-commerce** | prihod / ROAS | Summer Sale flash (14–17), Demand Gen lansiran 10. u mesecu, Display prospecting bez konverzija, Meta prijavljuje ~2× više prihoda nego GA4, PMax prebacuje plan (113%) |
| **SolarDom · Lead Generation** | leadovi, CPL, vrednost leada | vest o subvencijama (20–23) diže potražnju, CPL pada tokom meseca, generic search ograničen budžetom (IS ~38%), YouTube bez leadova, Meta lead forme jeftinije ali manje vredne |
| **FitPuls · App Install** | instalacije, CPI, re-engagement, bez prihoda | UAC Android/iOS/Re-engagement, iOS CPI ~2× Android, promo "7 dana Premium" (21–24), push notifikacije nose owned saobraćaj |
| **Izvor Voda · Awareness** | reach, CPM, video pregledi | udarna nedelja lansiranja (1–7), festival (20–23), YouTube TrueView/Bumper, Meta Reach & ThruPlay, skoro bez konverzija |

Svaki klijent ima podatke za **sve** stranice: Sažetak za direktora, Agencijski izveštaj, Po klijentu,
Google Ads (kampanje, uređaji, ključne reči, search termini, konkurencija, impression share),
Facebook Ads (ciljevi, plasmani, uređaji, kreative), Blended (uklj. Brandformance vs Pure Performance
funnel), GA4, Push & Newsletter, PPC Media Plan i Budget Pacing.

Fashion klijent (`clients.vertical = 'fashion'`) dodatno ima stranicu **Fashion insights**:
tržišta (po `Mkt:` tagu i GA4 prodavnici), kategorije i bestseleri iz product feed-a (Shopping/PMax),
kolekcije i sezona (SS/FW/core/back-to-school), efekat sale kalendara (lift naspram dana van akcija),
umor kreativa (CTR prvih vs poslednjih 7 dana) i konkurencija (cenovni indeks po kategoriji, udeo
popusta, novi artikli, aktivni oglasi, auction insights).

`data_sources.provider` je za svakog klijenta tačno `google_ads`, `facebook`, `ga4` — i to je
zaključano CHECK constraint-om u bazi, pa pogrešan string (`google`, `googleanalytics4`…) ne može ni
da se upiše.

## Generator podataka

Sve je u `supabase/migrations/`:

- `…01_schema.sql` — iste tabele kao produkcija (+ `clients.business_type/sort_order/tagline`, `video_views`)
- `…02_rls_public_demo.sql` — RLS: `anon`/`authenticated` smeju samo SELECT; nijedan upis kroz API
- `…03_report_functions.sql` — sve produkcione RPC funkcije; funnel funkcije primaju `p_client_id`
  umesto hardkodovanog `fashion-friends-rs` slug-a
- `…05_demo_seeder.sql` — generator u šemi `demo` (nije izložena kroz API)
- `…06_demo_templates.sql`, `…11_fashion_template.sql` — 5 business template-a kao JSON (kampanje, ključne reči, ad setovi,
  GA4 izvori, owned kanali, media plan, struktura PPC izveštaja)

Slučajnost je LCG `seed = (seed * 9301 + 49297) % 233280`, sa posebnim seed-om po klijentu, pa svako
pokretanje daje identične brojeve. Kampanja-dan se generiše po uređaju, a zatim deli na ad grupe /
asset grupe / ključne reči / search termine (Google) i ad setove / oglase / plasmane (Meta) tako da se
zbirovi na svim nivoima tačno poklapaju. GA4 paid redovi se izvode iz istih klikova i konverzija sa
atribucionim odnosom po template-u. Budžet u media planu se računa unazad iz stvarne potrošnje i
zadatog tempa (npr. `pace: 1.13` → "Prekoračen budžet").

Ponovno generisanje (npr. za drugi mesec) — u Supabase SQL editoru demo projekta:

```sql
select * from demo.seed('2026-08-01');   -- prvi dan meseca
```

Izmena priče = izmena JSON-a u `demo.templates` pa ponovo `demo.seed(...)`.

## Pokretanje lokalno

```
npm install
npm run dev
```

Nisu potrebne env varijable: demo URL i publishable ključ su ugrađeni kao podrazumevani u
`src/lib/supabase.ts` (baza je samo za čitanje i sadrži samo izmišljene podatke). Po želji se mogu
pregaziti sa `VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY`.

## Deploy na Vercel

1. vercel.com → **Add New… → Project** → Import `nenadgli/competitor-demo`
2. Framework se prepoznaje kao Vite (build `npm run build`, output `dist`) — env varijable nisu potrebne
3. Project name: `brain-reporting-demo` → URL `https://brain-reporting-demo.vercel.app`

## Razlike u odnosu na produkciju

- nema prijave — javni demo mod, stalni žuti **DEMO** baner i oznaka u navigaciji, `noindex`
- AI Chat tab je izostavljen (zahteva produkcionu `chat` Edge funkciju i LLM ključ)
- upload media plana (CSV) je onemogućen — baza je samo za čitanje, plan je unapred učitan
- oznake se prilagođavaju template-u (Kupovine / Leadovi + CPL / Instalacije + CPI / CPM i video
  metrike); ROAS se ne prikazuje gde nema prihoda
- budžetski raspon `Ecomm` je preimenovan u "Performance (glavni budžet)"
- `report_metrics` se čita stranično (PostgREST vraća najviše 1000 redova po zahtevu)
