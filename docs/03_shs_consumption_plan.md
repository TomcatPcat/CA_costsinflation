# Plan: SHS consumption incidence alongside the SFS inflation-tax project

**Status:** planning only (no analysis implementation yet)  
**Role in project:** optional appendix / complementary channel — core IG / IT / NIG remains SFS-only ([`02_canadian_barriers.md`](02_canadian_barriers.md)).  
**Local data:** `../SHS/RY2023/` (2023 PUMF) and `../dataSHS/3508_SHS_EDM/` (historical + 2017/2019). Prior exploratory work lives in `../SHS/code/` and `../SHS/outputs/` (income–consumption / CC imputation); that is **not** the inflation-incidence appendix planned here.

---

## 0. Why SHS, and what it cannot do

| Question | SFS (this repo) | SHS (this plan) |
|----------|-----------------|-----------------|
| Net inflation gain on balance sheets | Yes (NIG = IG − IT) | No wealth / debt stocks (except mortgage *payments* in shelter) |
| Who spends on necessities / shelter | Weak / none | Yes — detailed expenditure hierarchy |
| Long Canadian history (1999–2023) | Yes (sparse waves) | **No** for a comparable series — see §1 |
| Link to wealth quintiles | Direct | **Not linkable** — use proxies (§3) |

SHS answers: *given recent CPI, which demographic cells have consumption baskets most exposed to necessities and shelter inflation?*  
SFS answers: *given portfolios and leverage, who gains or loses on the balance sheet when inflation and real rates move?*  
Together they frame incidence as **cash-flow / basket** vs **stock / NIG**, not a single net welfare number.

---

## 1. Which SHS years are usable and comparable

### 1.1 Inventory on this machine

| Source | Years present | Form |
|--------|---------------|------|
| `../dataSHS/3508_SHS_EDM/` | 1997–2009 | Pre-redesign EDM PUMF packages (`data`/`doc`) |
| `../dataSHS/3508_SHS_EDM/` | 2017, 2019 | Post-redesign; 2019 already as `shs_2019.csv` |
| `../SHS/RY2023/` | 2023 | Full PUMF (TXT + reading cards + hierarchy + codebook) |

### 1.2 Comparability judgment (binding)

Statistics Canada’s post-2010 SHS redesign (interview + diary, revised concepts) creates a **hard break** with 1997–2009. For this project:

| Tier | Years | Use |
|------|-------|-----|
| **A — primary** | **2017, 2019, 2023** | Cross-section levels and shares; limited change over a short window; align demos to SFS cuts |
| **B — optional context** | 1997–2009 | Only if needed for “pre-redesign illustration”; **do not** splice into Tier A trends or claim SFS-period coverage |
| **C — not local / skip for v1** | 2010–2016, 2021, etc. | Do not block on acquiring more waves unless Tier A proves insufficient |

### 1.3 Overlap with SFS (explicit limitation)

SFS waves in the panel: **1999, 2005, 2012, 2016, 2019, 2023**.

- SHS Tier A overlaps SFS only at **2019** and **2023** for same-year side-by-side tables.
- Period NIG for 1999–2005 … 2016–2019 **cannot** be paired with comparable SHS consumption for those intervals.
- Narrative framing: SHS is a **recent-window consumption lens** on groups that also appear in the SFS NIG story — not a 1999–2023 consumption parallel to Wolff/SFS.

### 1.4 Survey unit and weight

- Unit: **household** (SHS) vs **economic family** (SFS EFAM PUMF) — close but not identical; document when comparing.
- Weight: `WEIGHTD` / `WeightD` (diary file weight). Prefer design weight for means/shares; 2023 bootstrap weights (`pumf_shs2023_bsw_*`) optional later, same spirit as deferred SFS bootstrap.

---

## 2. Key consumption aggregates and income

Use the 2023 expenditure hierarchy (`PUMF2023_expendiuture hierarchy.xlsx`) as the naming standard; 2017/2019 codes are largely parallel (confirmed for 2019 CSV: `TC001`, `TE001`, `FD001`, `SH001`, `TR001`, …).

### 2.1 Preferred totals

| Concept | Variable | Role |
|---------|----------|------|
| **Total current consumption** | `TC001` | Primary consumption aggregate (excludes personal taxes, gifts, many insurance/pension contributions) |
| **Total expenditure** | `TE001` | Secondary; includes `TX010` taxes, `EP011` insurance/pension, `MG001` gifts — useful for budget identity, not “consumption incidence” |
| **Household total income** | `HHTOTINC` / `HH_TotInc` | Denominator for C/Y and income quintiles |
| **Income taxes (paid)** | `TX010` | Build rough after-tax income: `HHTOTINC − TX010` (sensitivity; not StatCan disposable income) |

Prefer **`TC001` / income** for relative consumption stats. Keep `TE001` for diagnostics (mortgage principal / taxes inflate expenditure relative to consumption).

### 2.2 Basket aggregates (v1 definitions)

Define once in a small helper and freeze for all three years:

| Aggregate | Construction (2023 codes) | Interpretation |
|-----------|---------------------------|----------------|
| **Necessities** | `FD001 + SH001 + HC001` (+ optional `CL030`) | Food + shelter + out-of-pocket health (+ clothing if included) |
| **Housing / shelter** | `SH001` | Headline shelter; also report `SH011` mortgage payments for owners |
| **Transport** | `TR001` (and optionally fuel `TR036`) | Semi-necessity; report separately rather than forcing into necessities |
| **Discretionary** | `RE001` + residual `TC001 − necessities − TR001` **or** simply `TC001 − necessities` | Document the residual definition; recreation alone understates “discretionary” |
| **Debt-service-ish** | `SH011` / income (owners with mortgage) | Cash-flow complement to SFS leverage — not a wealth measure |

**Recommended v1 freeze**

- Necessities₀ = food + shelter + health (`FD001 + SH001 + HC001`)
- Discretionary₀ = `TC001 − Necessities₀`
- Report clothing (`CL030`) and transport (`TR001`) as separate memo lines

### 2.3 Relative statistics (by cell)

For each grouping cell × year (weighted):

1. Mean / median `TC001`, `HHTOTINC`
2. `TC001 / HHTOTINC` (consumption–income ratio; watch top-coding / outliers)
3. Necessities₀ / `TC001`, shelter / `TC001`, discretionary₀ / `TC001`
4. Shelter / income; mortgage payment / income (tenure = owned with mortgage)
5. Optional: after-tax variants using `TX010`

Missing codes (`99999999.96` style) → NA then exclude from ratios; do not zero-fill consumption.

---

## 3. Groupings aligned with SFS — and wealth quintiles

### 3.1 Feasible alignments (do these)

| Grouping | SHS 2023 fields | Alignment notes |
|----------|-----------------|-----------------|
| **Age** | `RP_AGEGP`: &lt;30, 30–39, 40–54, 55–64, 65–74, 75+ | Coarser than SFS `&lt;35, 35–44, …`. Map SFS continuous/agegrp into closest SHS bands for side-by-side; do **not** invent midpoints for primary tables |
| **Tenure** | `TENURE`: 1 owned w/ mortgage, 2 owned free-and-clear, 3 rented | **Excellent** match to SFS `housing_status` in `code/01` / `code/07` |
| **Province** | `PROV` (10 provinces + “Territorial capitals”) | Province-level OK; drop or isolate territories |
| **Regions (project taxonomy)** | Collapse `PROV` → **BC** \| **ON+QC+MB** \| **AB+SK** \| **Atlantic (PE,NS,NL,NB)** | Same four-way cut as requested; document QC+ON+MB bundling |
| **CMA** | **Not on 2023 PUMF** (no CMA/CMACA in layout) | **Infeasible** on public PUMF without RDC; skip CMA for v1 |

### 3.2 Wealth quintiles — not directly linkable

SHS PUMF has **no net worth**. Households cannot be placed into SFS `w_wolff` quintiles.

**Do not claim** SHS results are “by wealth quintile.”

**Proxy ladder (recommended)**

1. **Income quintiles** within each SHS year (weighted on `HHTOTINC`) — primary “class” cut for consumption.
2. **Tenure × age** cells — closest structural parallel to leverage / life-cycle story in SFS.
3. **Income quintile × tenure** — best available stand-in for “balance-sheet class” (renters & low income ≈ thin wealth; mortgagors in mid income ≈ leveraged middle).
4. **Phase 2 (optional, not v1):** coarsened exact matching / reweighting of SHS to SFS joint margins on age × tenure × region × income band for 2019 and 2023 only. Costly and assumption-heavy; only if the appendix needs a closer narrative bridge.

### 3.3 SFS side tables to prepare for juxtaposition

Reuse existing SFS outputs where possible; add thin extracts if missing:

- NIG / income by **tenure** and by **age** for **2019** and **2023** (not only wealth quintile)
- Debt/asset by tenure × age (latest years)
- Same four **regions** on SFS via `dem_prov` / `ppvres` if not already tabulated

---

## 4. What light this sheds on inflation incidence vs the SFS NIG story

### 4.1 Two channels, one inflation

```text
CPI inflation
    ├─ Cash-flow / basket (SHS): high necessities & shelter shares
    │     → larger real consumption loss for a given all-items CPI
    │     → renters & low-income cells typically more exposed
    │
    └─ Balance sheet (SFS): debt devaluation − income tax ± asset PV wedges
          → NIG/income often largest for leveraged middle owners (Q2–Q3)
```

### 4.2 Hypotheses to test (descriptive, not causal)

1. **Renters:** high shelter share of consumption (SHS) *and* little mortgage debt stock (SFS) → consumption channel hurts, NIG channel weak → inflation looks clearly adverse on both margins.
2. **Owners with mortgage:** SFS NIG often favourable (debt devaluation); SHS shows high `SH011`/income — cash-flow stress can coexist with positive NIG (stock vs flow).
3. **Older free-and-clear owners:** lower leverage → smaller NIG; SHS may show lower shelter shares but higher health shares — basket composition differs by age.
4. **Regional cut:** whether Atlantic / Prairies / BC differ more in **shelter shares** (SHS) than in **NIG** (SFS) for 2019–2023 — useful if housing markets dominate the story.

### 4.3 What SHS does *not* settle

- Does **not** overturn or validate Wolff-style NIG magnitudes.
- Does **not** measure capital gains, rate wedges, or Gini from revaluation.
- Does **not** deliver a household-level “full inflation tax” combining stocks and flows without a joint model (out of scope).

**Paper use:** short appendix or subsection — “Consumption exposure by group (SHS 2017–2023)” next to tenure/age NIG charts for 2019/2023, with an explicit non-comparability note on the long SFS history.

---

## 5. Deliverables and script location

### 5.1 Scripts (under `code/`, R to match the pipeline)

| Script | Purpose |
|--------|---------|
| `code/08_shs_load.R` | Resolve paths (`../SHS/RY2023`, `../dataSHS/...`); read 2017/2019/2023; harmonize names; attach age bands, tenure, region, income quintile; write `data/processed/shs_2017_2023.rds` (gitignored) |
| `code/09_shs_consumption_incidence.R` | Weighted tables/figures for aggregates in §2–3; optional thin SFS juxtaposition pulls from existing `output/tables/` |
| `code/utils/shs_baskets.R` | Frozen basket definitions + region collapse + age-band maps |
| `code/00_setup.R` | Add `find_shs_paths()` analogous to `find_sfs_panel()`; document in `data/raw/DATA_PATHS.md` |
| `code/run_all.R` | **Do not** auto-source 08–09 in the core run (SHS optional); document `run_shs` snippet or flagged block |

Reuse lessons from `../SHS/code/shs_income_consumption_analysis.py` (FWF colspecs, missing sentinel) but keep **this repo’s** analysis in R for consistency with SFS scripts.

### 5.2 Tables (`output/tables/`)

- `shs_consumption_by_income_quintile.csv`
- `shs_consumption_by_tenure.csv`
- `shs_consumption_by_age.csv`
- `shs_consumption_by_region.csv`
- `shs_consumption_by_income_x_tenure.csv` (flagship proxy for “class”)
- `shs_sfs_juxtaposition_2019_2023.csv` — SHS shares + SFS NIG/income for shared cells (tenure, age, region)

### 5.3 Figures (`output/figures/`)

- Necessities and shelter shares of `TC001` by income quintile (facet year)
- Shelter share and mortgage-payment/income by tenure
- Side-by-side 2019/2023: SFS mean NIG/income vs SHS necessities share by tenure (two panels)
- Optional: regional bar chart of shelter / `TC001`

### 5.4 Docs touch-ups (when implementing)

- One paragraph in [`paper_notes.md`](paper_notes.md) pointing to SHS appendix results
- Path note already sketched in [`02_canadian_barriers.md`](02_canadian_barriers.md) § Role of SHS — refresh after first tables exist

### 5.5 Implementation order (when greenlit)

1. Path helpers + load 2023 only → smoke-test weighted means of `TC001`, `FD001`, `SH001`.
2. Add 2019 CSV, then 2017; assert code presence for basket vars.
3. Grouping tables + figures (§5.2–5.3).
4. SFS juxtaposition for 2019/2023 tenure/age/region.
5. Stop. No CPI micro-reweighting or SFS–SHS statistical matching unless a follow-on asks for it.

---

## 6. Risks and guardrails

- **Time span:** never imply SHS covers the full SFS 1999–2023 NIG history.
- **Redesign:** do not pool 1997–2009 with 2017–2023 for trends.
- **Wealth language:** income/tenure proxies only.
- **CMA:** unavailable on PUMF — province/region only.
- **Household vs EFAM:** footnote in any SFS–SHS comparison table.
- **Shelter in SHS:** includes imputed aspects / owner costs per SHS concepts — read User Guide before over-interpreting owner–renter shelter gaps; prefer shares and rankings over dollar gaps if concepts are fuzzy.
- **Microdata:** do not commit PUMF; aggregated `output/` only (same policy as SFS).

---

## 7. Is a fuller formal Cursor plan warranted?

**Recommendation: No** — not before starting implementation.

This note is already a concrete enough build spec (years, variables, groupings, proxies, deliverables, script names). A separate Cursor Plan-mode document would add process overhead without resolving open design forks: the only real forks (necessities definition; whether to pursue SFS–SHS matching) are small and can be decided in the first implementation PR.

**Revisit Plan mode only if** you expand scope to (a) CPI subcategory reweighting / household-specific inflation rates, or (b) formal statistical matching of SHS to SFS wealth-adjacent margins.

---

## 8. Decision checklist (for the user)

- [ ] Accept Tier A years only (2017, 2019, 2023) for v1
- [ ] Accept no CMA and no wealth quintiles; use income × tenure proxies
- [ ] Freeze Necessities₀ = food + shelter + health
- [ ] Keep SHS scripts optional (not in default `run_all.R`)
- [ ] Proceed to implement `code/08`–`09` when ready (no further formal plan doc)
