# Plan: Interest rates and the household balance sheet (Canada)

Paper section plan for the relative role of interest-rate changes in Canadian wealth developments, adapting Wolff NBER WP 29392 (*Inflation, Interest, and the Secular Rise in Wealth Inequality*) and the interest-rate / housing material in WP 31775 (*Is There Really an Inflation Tax?*). Stub TeX section points here: `paper/inflation_tax_canada.tex`.

**Sources used:** text extracts of w29392 / w31775 under `agent-tools/`; existing methodology in [`01_wolff_methodology.md`](01_wolff_methodology.md), barriers in [`02_canadian_barriers.md`](02_canadian_barriers.md), notes in [`paper_notes.md`](paper_notes.md); code `05_inequality_effects.R`, `07_mortgage_affordability.R`, `04_inflation_gain.R`.

---

## 1. Summary of Wolff’s interest-rate channels

Wolff’s monetary accounting (especially WP 29392 §4; parallel language in WP 31775 §4) isolates **direct** balance-sheet effects of interest rates and inflation. Portfolios are held fixed at the start of each sub-period; savings, portfolio reshuffling, and full general-equilibrium monetary identification are out of scope.

### Included channels

| Channel | Discount / price object | Direction when rates fall (or inflation raises real-debt relief) |
|--------|-------------------------|------------------------------------------------------------------|
| **Stocks** | PV of future real earnings / profits; discount at **real** rate | ↑ when real discount rate falls (`p ∝ 1/r` consol logic) |
| **Unincorporated business** | Same real-rate PV logic as equities | ↑ with stocks |
| **Bonds** | Coupon PV; duration / maturity matter; **real** coupon logic in theory | ↑ when yields fall (rich hold more bonds → inequality-relevant) |
| **Housing / other RE (affordability)** | Affordable price at fixed payment, **nominal** mortgage rate (US: 30y FRM, 20% down) | ↑ when nominal mortgage rates fall; middle class housing-heavy |
| **Liquid assets** | Face value fixed w.r.t. rate changes; **real** value falls with CPI | Rate-driven deposit-yield effects excluded in base case; inflation depreciation included |
| **Debt** | Face value fixed; **real** burden falls with inflation | Equalizing when leverage falls with wealth |

**Real vs nominal (critical):** Stocks, businesses, and bonds are revalued with the **real** interest rate (earnings/coupons in real terms). House prices respond to the **nominal** mortgage rate via monthly payment affordability. WP 31775 is explicit: the house-price–nominal-mortgage link is **not** a factor in computing the inflation tax / \(IG\).

**Illustrative affordability:** At fixed payment and 20% down, a 6.5% 30y FRM supports the same payment as a house ~25% more expensive at 4.5% (Wolff’s Figure 8 / WP 31775 Figure 4).

### Explicitly excluded (or base-case omitted)

1. **Cash-flow / expenditure effects of lower mortgage payments.** Reduced carrying costs (ARM resets, refinancing) are an **expenditure** effect, not a change in net worth: outstanding principal is unchanged, so NW is unaffected in the accounting. (Enhanced savings would show up only via later asset purchases.)
2. **Indirect / GE effects of Fed (or BoC) policy.** Changes in expected earnings streams, employment, wages, output, capital-gains expectations for housing beyond the affordability schedule, etc.
3. **Deposit-rate / liquid-asset accumulation effects of policy rates** in the base case (optional sensitivity in Wolff’s Appendix / §10).
4. **Portfolio rebalancing and new saving** between survey dates.
5. **Vehicles, DB pensions, Social Security wealth** (wealth concept), consistent with both papers.

**WP 31775 vs WP 29392 division of labour**

- **31775:** \(IG\), \(IT\), \(NIG = IG - IT\). Asset terms are Fisher-wedge PV gains on STK/BUS/BND plus \(-\mathrm{LIQ}\cdot INF + \mathrm{DBT}\cdot INF\). Housing affordability **excluded** from \(IG\).
- **29392:** Full monetary revaluation package for mean/median/Gini and racial gaps — including the **nominal-mortgage affordability house-price channel** alongside real-rate PV and inflation on LIQ/DBT.

Canadian paper should keep the same partition: core \(NIG\) sections stay 31775-style; **this section** is the 29392-style relative-role analysis (with housing as a separate toggle).

---

## 2. Key US empirical claims (WP 29392, 1983–2019 SCF)

Actual US wealth inequality **rose** (Gini +0.070, 0.799 → 0.869; top-decile share 68.2% → 78.1%). Wolff’s counterfactual asks whether declining rates + inflation moderation **caused** that rise. Answer: **no** — direct monetary balance-sheet effects were **strongly equalizing**.

### Headline quantities (full period)

| Claim | Magnitude |
|-------|-----------|
| Monetary revaluation effect on **Gini** | **−0.045** (equalizing; decline in all six SCF sub-periods) |
| Share of **mean** NW advance explained by asset-price + debt-devaluation channels | **72.6%** of +127.6% mean NW |
| Counterfactual **median** NW gain from those channels | **+204.9%** vs actual **+23.4%** |
| Racial wealth gap | Monetary effects **narrow** Black/white and Hispanic/white ratios relative to actual path |

### Contribution shares to mean NW advance (1983–2019)

Approximate attribution of the “Fed / monetary” package to mean wealth growth:

| Component | Share of mean NW rise |
|-----------|----------------------|
| Home prices (mortgage-rate affordability) | **36.5%** |
| Debt deflation (CPI) | **18.6%** |
| Non-home real estate | **14.6%** |
| Bonds | **6.3%** |
| Businesses | **5.2%** |
| Stocks | **4.9%** |
| Liquid assets | **−13.5%** |

Median story is even more housing + debt: home prices alone ~**+131%** of median; debt devaluation ~**+76%**; liquid assets ~**−27%**; other financial terms small.

### Inequality and race (selected)

- Top-1% / median ratio: Fed-linked asset prices **reduce** the ratio in every sub-period; actual ratio rose in five of six periods.
- Black/white mean wealth ratio: actual fell ~0.051 (27%) over 1983–2019; Fed package would have **raised** the ratio by ~0.093 (~49%) — counterfactual ratio ~0.230 vs actual 0.137 in 2019. Mechanism: minorities’ higher housing share and leverage vs whites’ equity/business share.
- Age: middle-aged mortgagors gain relative to the young/old (parallel to older Wolff 1979 inflation results).

### Methodological contrast with literature

Wolff emphasizes **direct** mapping from rates → PV / affordability → fixed portfolios, vs VAR/QE impulse responses and duration-calibration studies (e.g. Greenwald et al.) that often find disequalizing or mixed effects. Canadian section should state the same scope: accounting decomposition, not BoC causal identification.

---

## 3. What CA_costsinflation already computes vs what is missing

### Already in place

| Deliverable | Where |
|-------------|--------|
| Period revaluation: STK/BUS (real-rate consol + duration fallback), BND (duration ~8), LIQ/DBT inflation | `code/05_inequality_effects.R`, `utils/accounting.R` |
| Mean / median / Gini with vs without revaluation; with vs without housing | `inequality_revaluation_by_period.csv` |
| Channel contribution means by period | `revaluation_contributions_by_period.csv` |
| CA 25y amort baseline + Wolff 30y amort hybrid `hp_ratio` | `05`, `07` |
| Affordability curves (Wolff 30y vs CA 25y/30y); 6.5%→4.5% points | `07`, figures/tables under `output/` |
| Period `hp_ratio` sensitivities: 3y-rate proxy (−20 bp), stress rate | `mortgage_hp_ratio_sensitivities.csv` |
| Tenure splits: mortgage / free-and-clear / renter housing + debt channels | `housing_channel_by_tenure_period.csv` |
| Macro: CPI, GoC 10y, 5y conventional mortgage; SFS waves 1999–2023 | `02_macro_series.R`, period_rates |
| Age wealth snapshot (racial-gap substitute) | `wealth_by_age_latest.csv` |
| Core \(NIG\) (housing **out** of IG) | `04_inflation_gain.R` |

### Suggestive Canadian patterns already visible (not yet paper-ready)

From current period tables (re-run with `run_all.R` before citing):

- Rate-decline eras (esp. 1999–2012): large positive mean revaluation **without** housing; **Gini can rise** when equity/business gains dominate at the top — a tension with Wolff’s US equalizing headline.
- 2016–2019: real yields up → mean NW revaluation negative; Gini slightly down (no-housing).
- 2019–2023: positive non-housing revaluation but **housing affordability channel negative** (mortgage rates up) — can wipe mean gains when housing is included.
- Free-and-clear vs mortgagor incidence already differs from a pure US leverage narrative (also in \(NIG\) tenure cuts).

### Missing for a complete “relative role” section

1. **Wolff-style contribution *shares*** of period (or cumulative) mean/median changes attributable to each channel (not only mean dollar contributions).
2. **Cumulative 1999–2023 chain** (compound start-of-wave portfolios, or chained period effects) comparable to Wolff’s 1983–2019 full-span table.
3. **Housing-only vs equity-only vs debt-only Gini decompositions** — needed to explain why CA Gini sometimes moves opposite to Wolff.
4. **Share of *actual* mean/median wealth change** explained by the monetary package (Wolff’s 72.6% / median counterfactual style), using actual SFS mean/median growth between waves.
5. **Quintile (or P80–90) incidence** of the 29392 package, not only aggregate Gini.
6. **Age-group incidence of the rate package** (29392 §9 analogue); optional recent-wave visible-minority cut only.
7. **Actual house-price check:** Teranet / NHPI Δ vs affordability `hp_ratio` counterfactual (listed in `paper_notes` next iterations).
8. **Bond-duration / equity-duration sensitivities** analogous to Wolff §10 (20y/30y bond rates).
9. Paper prose + polished tables/figures (TeX stub only so far).

---

## 4. Proposed paper section outline

**Suggested title:** Interest rates and the household balance sheet  
**Placement:** After core \(NIG\) results; before (or alongside) barriers / top-tail discussion. Keep renewal/pass-through deferred (see §5).

### Research questions

1. Over SFS waves 1999–2023, how much of Canadian mean and median marketable net worth change is accounted for by Wolff-style direct revaluation (real GoC yields, bond duration, inflation on LIQ/DBT, and optionally mortgage-affordability housing)?
2. Did these channels compress or widen the Canadian wealth Gini (and top/median ratios the SFS can support)?
3. How does the **housing affordability** channel compare to the **equity/business** channel in driving inequality — and does Canada diverge from Wolff’s housing-led equalizing US story?
4. How sensitive are answers to Canadian mortgage institutions (5y contract rates, 25y vs 30y amort, stress/3y proxies) and to the consol vs duration fallback at low real rates?
5. How do tenure and age reshape incidence relative to aggregate results?

### Subsection sketch

1. **Wolff’s channels and what we exclude** (short; point to methodology appendix).
2. **Canadian rate and inflation backdrop** (GoC 10y real/nominal, 5y mortgage, CPI; sparse SFS dates).
3. **Aggregate revaluation: mean, median, Gini** with/without housing.
4. **Contribution decomposition** (table mirroring Wolff Table 8 shares).
5. **Canadian adaptations and sensitivities** (amort, term proxy, stress, duration floors).
6. **Tenure and age** (and optional recent visible-minority note).
7. **Relative role vs \(NIG\)** — same macro rates, different object (\(NIG\) excludes housing affordability; this section includes it as a toggle).
8. **Limits** — no BoC causal claim; deferred renewal/pass-through; SFS top-tail and race limits.

### Tables / figures to produce

| ID | Content | Build from |
|----|---------|------------|
| **T-IR1** | Period mean/median/Gini: actual Δ vs reval (no hous / +CA25y / +Wolff30y amort) | extend `05` |
| **T-IR2** | Contribution *shares* of mean (and median) revaluation by channel × period + cumulative | extend `05` |
| **T-IR3** | Gini Δ under channel shut-offs (equity+bus only; housing only; debt+liq only; full) | new block in `05` or `06` |
| **T-IR4** | `hp_ratio` sensitivities by period (already partly exists) | `07` → polish |
| **F-IR1** | Affordability curves Wolff vs CA (exists) | `07` |
| **F-IR2** | Stacked contributions to mean ΔNW by period | `06` from contrib shares |
| **F-IR3** | Gini path: actual vs revalued counterfactual | `06` |
| **F-IR4** | Tenure housing/debt channels (exists; refresh) | `07` |
| **F-IR5** *(optional)* | Actual HPI vs affordability-implied price path | new small script / `02`+`07` |

### Canadian adaptations (must state in text)

| Wolff US | Canada adaptation |
|----------|-------------------|
| SCF ~triennial 1983–2019 | SFS waves **1999, 2005, 2012, 2016, 2019, 2023** (longer gaps) |
| 10y Treasury real rate | **GoC 10y** real = nominal − CPI |
| 30y FRM affordability | Benchmark retained; baseline **5y conventional rate + 25y amort**; 30y amort sensitivity |
| Continuous FRM / refinance narrative | Short **fixed terms**; do **not** model renewal payment shock (deferred) |
| Racial gap central | **Age + tenure (+ region)** primary; race only if recent-wave coverage allows a footnote |
| Consol/PV equity | Same + **duration fallback** when real rates near/below floor (`consol_reval`) |
| Bond duration assumptions | Keep ~8y; sensitivity later |
| High-income list sample | PUMF limits; prefer quintiles / P80–90, not P99, for inequality ratios |

---

## 5. Explicit deferrals vs what THIS section should still deliver

### Already chosen deferrals (do **not** expand here)

Documented in `02_canadian_barriers.md`, `07` header comments, extended abstract, and TeX:

- **Renewal-risk incidence** — distribution of payment shock from short Canadian terms at renewal.
- **Detailed rate pass-through** — mapping policy/market rates into existing loan payments and renegotiation.

These remain postponed; the section should **restate** that once, then move on.

### What this section **should** still deliver

Despite those deferrals, the section is not empty:

1. Full **29392-style relative-role** accounting for Canada (mean/median/Gini + contribution shares).
2. Clear **with/without housing** results under CA 25y baseline and Wolff 30y amort benchmark.
3. Published **sensitivities already coded** (30y amort, 3y-rate proxy, stress) as robustness — not as a pass-through model.
4. **Tenure** incidence of the housing channel (owners get HOUS shock; renters do not).
5. Explicit contrast: Canadian episodes where **equity concentration raises Gini** even as debt/housing would equalize.
6. Boundary statements: expenditure/cash-flow omitted (Wolff); GE omitted; \(NIG\) still excludes housing affordability.

---

## 6. Implementation checklist (order of work)

Estimated effort assumes tables/figures + draft prose; not a full empirical re-architecture.

| Step | Task | Script / file | Priority |
|------|------|---------------|----------|
| 1 | Add contribution **shares** (channel / Δ mean NW; optional median) and cumulative 1999–2023 summary row | extend `code/05_inequality_effects.R` | P0 |
| 2 | Channel shut-off Gini experiments (housing off/on already partial; add equity-only, debt+liq-only) | `05` → new CSV; plot in `06_tables_figures.R` | P0 |
| 3 | Actual vs revalued mean/median **growth rates** by period (Wolff “% of advance explained”) | `05` + baseline inequality CSV | P0 |
| 4 | Quintile (and P80–90) mean revaluation incidence for the 29392 package | `05` or thin `08` hook | P1 |
| 5 | Age-band revaluation incidence (period loop) | extend `05` or `08` | P1 |
| 6 | Wire polished figures F-IR2, F-IR3 into `06`; refresh F-IR1/F-IR4 captions for paper | `06`, `07` | P1 |
| 7 | Optional: Teranet/NHPI vs `hp_ratio` comparison table | `02` + small `07` block | P2 |
| 8 | Optional: bond duration / GoC maturity sensitivity (Wolff §10 lite) | `05` | P2 |
| 9 | Draft section prose in TeX (replace TODOs); sync 1-paragraph abstract sentence if needed | `paper/inflation_tax_canada.tex` | P1 after tables |
| 10 | Cross-link methodology docs; update `paper_notes.md` gallery pointers | `docs/` | P2 |

**Do not** in this pass: implement renewal schedules, loan-level pass-through, or BoC shock identification.

**Suggested coding order:** (1)–(3) first so the section’s headline numbers exist; then figures; then tenure/age polish; Teranet last.

---

## References

- Wolff, E. N. (2021). *Inflation, Interest, and the Secular Rise in Wealth Inequality in the U.S.: Is the Fed Responsible?* NBER Working Paper 29392.
- Wolff, E. N. (2023). *Is There Really an Inflation Tax? Not For the Middle Class and the Ultra-Wealthy.* NBER Working Paper 31775.
- Project notes: [`01_wolff_methodology.md`](01_wolff_methodology.md), [`02_canadian_barriers.md`](02_canadian_barriers.md), [`paper_notes.md`](paper_notes.md).
