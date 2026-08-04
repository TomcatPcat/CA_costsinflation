# Paper notes — Quantifying the inflation tax on Canadian households

Evolving findings from the SFS-based Wolff adaptation. Regenerate numbers with `Rscript code/run_all.R`.

Editable abstracts: [`abstract.md`](abstract.md) (short) and [`extended_abstract.md`](extended_abstract.md) (Canada vs Wolff detail); TeX short abstract synced in `paper/inflation_tax_canada.tex`.

## Setup

- **Microdata:** SFS EFAM PUMF panel 1999–2023 (`n = 72,295`), Wolff-style net worth (excl. vehicles & DB pensions).
- **Macro:** StatCan all-items CPI (live pull when available) + BoC-style GoC 10y and 5y mortgage rates in `data/external/macro_annual.csv`.
- **Engine:** `IG − IT` (WP 31775) and period revaluation / Gini (WP 29392) in `code/04`–`05`.
- **Registered mix:** PBO method — household non-registered STK/BND/LIQ shares applied to RRSP/RRIF/TFSA/other retirement totals (`code/03`). Likely understates equity inside registered plans (esp. TFSAs) due to tax-location incentives; see `docs/01_wolff_methodology.md`. Diagnostics: `output/tables/registered_mix_pbo_diagnostics.csv`.
- **Mutual funds:** Keep traditional 60/40 equity/bond look-through (`SHARES$mf_equity = 0.60`); no further write-up on industry AUM or ETF products.

## Snapshot results (2023)

Annual NIG / mean income by wealth quintile (`nig_over_inc`):

| Quintile | Debt/assets | NIG / income |
|----------|-------------|--------------|
| Q1 | ~1.07 | ~1.5% |
| Q2 | ~0.44 | ~19% |
| Q3 | ~0.28 | ~54% |
| Q4 | ~0.16 | ~111% |
| Q5 | ~0.08 | ~417% |

Interpretation (first pass):

- Middle quintiles (Q2–Q3) show **positive** net inflation gains relative to income, consistent with Wolff’s qualitative message that leveraged owners gain on the balance sheet.
- Q1 has high leverage but low asset bases and incomes that make the **income tax** compete with debt devaluation; NIG/income is near zero / small.
- **Q5 large NIG gains/losses are equity/business revaluation, not leverage.** In 2023, mean STK+BUS is ~$900k in Q5 vs ~$30k in Q3; STK+BUS ≈ 85% of Q5 IG. Q5 has the lowest debt/asset ratio (~0.08 vs ~0.28 for Q3), so debt devaluation is a small share of IG at the top and IT barely offsets IG. Middle/lower quintiles rely relatively more on debt devaluation. The 2016–2019 Q5 loss is the same STK/BUS channel with the sign flipped when real rates rose. Magnitudes remain **fragile** (PUMF top-coding; no high-income oversample; consol wedge capped / real rates floored).

## Period results (portfolios fixed at start of interval)

Cumulative inflation between SFS waves:

| Period | Cum. CPI inflation |
|--------|-------------------|
| 1999–2005 | 13.8% |
| 2005–2012 | 12.9% |
| 2012–2016 | 5.9% |
| 2016–2019 | 4.4% |
| 2019–2023 | 14.4% |

Patterns:

- **1999–2005, 2005–2012, 2019–2023:** middle quintiles often have positive period NIG/income; Q1 sometimes negative when income tax dominates thin balance sheets.
- **2016–2019:** real rates *rose* (negative equity revaluation) while inflation was mild → NIG turns negative for several quintiles — a useful contrast to Wolff’s long US disinflation/rate-decline era.
- Debt devaluation is the most robust equalizing / middle-class channel; equity/business terms dominate means at the top.

### Accounting note: real-rate floor and 2012–2016

Near-zero 2012–2016 equity/business revaluation was a **bug**, not an economic feature. Raw real GoC10 rates were `real0≈0.33%` and `real1≈−0.32%`; both were floored to 0.5% before the consol ratio `V*(r0/r1−1)`, so STK/BUS contributions were exactly zero. Mild cumulative inflation (~5.9%) and a small nominal yield move (Δgoc10≈−62bp) do legitimately shrink IT, debt/liq, and bond terms, but they do not justify wiping the equity channel. Fix (`consol_reval` in `code/utils/accounting.R`): use the consol ratio only when both real rates exceed the 0.5% floor; otherwise apply the duration approximation so the observed Δr is preserved. Same helper is used in `04`, `05`, and `08`. Side effect: 2005–2012 and 2019–2023 equity gains shrink vs the old path, which had inflated consol ratios by flooring only the low end-rate.

## Inequality module (WP 29392-style)

From `inequality_revaluation_by_period.csv`:

- Rate declines (1999–2012) produce large positive mean wealth revaluation; Gini sometimes **rises** when equity gains concentrate at the top (unlike Wolff’s US finding that monetary effects were strongly equalizing — worth exploring further with housing-only vs equity-only decompositions).
- 2016–2019 rate *increases* cut mean wealth and slightly lower Gini in the no-housing revaluation.
- Housing affordability channel (Canadian 25y amort baseline) moves with mortgage rates; **Wolff 30y FRM curve retained as benchmark** and plotted alongside Canada (`output/figures/mortgage_affordability_wolff_vs_canada.png`). Sensitivities: 30y amort, 3y-rate proxy, stress rate.
- Results split by **owner-mortgage / free-and-clear / renter** (`housing_channel_by_tenure_period.csv`).
- **Not in scope yet:** distribution of homeowner risk from short Canadian terms; detailed rate pass-through to existing loans (postponed).

## Barriers confirmed in practice

See [02_canadian_barriers.md](02_canadian_barriers.md). Most binding for interpretation:

1. Sparse waves + low-rate floor assumptions.
2. Registered-account mix (PBO non-registered imputation; equity share likely understated).
3. Weak ultra-wealthy coverage — see draft top-tail commentary in [04_top_tail_commentary.md](04_top_tail_commentary.md) (also in `paper/inflation_tax_canada.tex`, §Barriers).
4. No full racial-gap series (`pvmfmie` incomplete historically).
5. Mortgage institutions (Wolff 30y FRM vs CA short term / long amort) — benchmark + Canada curves; renewal risk / pass-through postponed.

## Demographic / geographic breakdowns (`code/08`)

NIG, leverage, and wealth cuts by:

| Cut | Source | Outputs (prefix) |
|-----|--------|------------------|
| Age band | `pagemie` / `pagemieg` → `<35`…`65+` | `nig_portfolio_by_age_band_*`, `nig_by_period_age_band` |
| Tenure | `housing_status` (mortgage / free-clear / renter) | `nig_portfolio_by_housing_status_*` (+ age×tenure) |
| Province | `ppvres` / `dem_prov` | `nig_portfolio_by_province_*` |
| StatCan region | `pregion` (Atlantic, QC, ON, Prairies, BC) | `nig_portfolio_by_sfs_region_*` |
| Analytic region | BC; ON/QC/MB; AB/SK; Atlantic | `nig_portfolio_by_geo_group_*`, period facets |

Figures: `nig_by_age_latest.png`, `nig_by_tenure_latest.png`, `nig_by_geo_group_latest.png`, `nig_by_province_latest.png`, `nig_period_by_geo_group.png`, `nig_period_by_age.png`, `nig_by_age_tenure_latest.png`, `wealth_by_province_latest.png`, `wealth_by_geo_group_years.png`, `debt_asset_by_age_latest.png`.

**Data limitations**

- **CMA / major cities:** not on the SFS EFAM PUMF (no CMA column in the panel). Geography stops at province / StatCan region. See `geo_availability_note.csv`.
- **Province missing in 2005** on this panel (`dem_prov` all NA); `dem_region` still present. Analytic `geo_group` uses a region fallback that year; Prairies cannot be split into Central (MB) vs Oil (AB/SK) → coded `Prairies unsplit`.
- Territories not on PUMF. Age continuous missing in 2019/2023 (use grouped `agegrp`; 2023 has 7 bands, earlier years 14 five-year bands).

## SHS consumption appendix (`code/09`–`10`)

Complementary **cash-flow / basket** channel for recent years only (2017, 2019, 2023). Core NIG remains SFS-only. Scripts skip if local SHS paths are missing.

| Cut | Proxy note | Key outputs |
|-----|------------|-------------|
| Income quintile | Within-year weighted on `HHTOTINC` — **not** wealth | `shs_consumption_by_income_quintile.csv` |
| Tenure | Mortgage / free-clear / rent | `shs_consumption_by_tenure.csv` |
| Income × tenure | Best stand-in for “balance-sheet class” | `shs_consumption_by_income_x_tenure.csv` |
| Age (SHS bands) | `<30`…`75+` (coarser than SFS) | `shs_consumption_by_age.csv` |
| Analytic region | BC \| ON+QC+MB \| AB+SK \| Atlantic | `shs_consumption_by_region.csv` |
| SFS juxtaposition | 2019/2023 tenure, age, region | `shs_sfs_juxtaposition_2019_2023.csv` |

**Snapshot (2023, weighted):** necessities share of `TC001` falls with income (Q1 ~59% vs Q5 ~51%); renters and low-income mortgagors show the highest necessities/shelter shares; mortgagors’ mean mortgage-payment/income ~32%. Free-and-clear owners have the *lowest* SHS necessities share but (in SFS) the *highest* NIG/income — stock vs flow channels diverge. BC has the highest regional shelter share; Atlantic the lowest among the four analytic regions.

Caveats: household (SHS) ≠ EFAM (SFS); shelter concepts include SHS owner-cost definitions; 2017 clothing=`CL001` and taxes=`TX001` (harmonized names); no CMA; never claim wealth-quintile SHS results.

## Next iterations

- Optional sensitivity: raise registered equity share above the PBO non-reg proxy (e.g. +10–20 pp for TFSAs) to bound the tax-location bias.
- Bootstrap SEs for 2023.
- Tighten top-tail presentation (P80–90 vs P99) for the paper’s main tables.
- Compare Teranet house-price *actual* changes vs mortgage-affordability counterfactual.
- Rate pass-through and short-term renewal-risk incidence (postponed).
- Optional Phase 2: SHS–SFS margin matching for 2019/2023 (not in v1).

## Run artifacts

Tables: `output/tables/`  
Figures: `output/figures/`
