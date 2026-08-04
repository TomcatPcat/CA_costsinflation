# Paper notes — Quantifying the inflation tax on Canadian households

Evolving findings from the SFS-based Wolff adaptation. Regenerate numbers with `Rscript code/run_all.R`.

## Setup

- **Microdata:** SFS EFAM PUMF panel 1999–2023 (`n = 72,295`), Wolff-style net worth (excl. vehicles & DB pensions).
- **Macro:** StatCan all-items CPI (live pull when available) + BoC-style GoC 10y and 5y mortgage rates in `data/external/macro_annual.csv`.
- **Engine:** `IG − IT` (WP 31775) and period revaluation / Gini (WP 29392) in `code/04`–`05`.
- **Registered mix:** PBO method — household non-registered STK/BND/LIQ shares applied to RRSP/RRIF/TFSA/other retirement totals (`code/03`). Likely understates equity inside registered plans (esp. TFSAs) due to tax-location incentives; see `docs/01_wolff_methodology.md`. Diagnostics: `output/tables/registered_mix_pbo_diagnostics.csv`.

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
- Q5 NIG/income is large because equity/business PV wedges scale with holdings even after capping the consol wedge at 50% and flooring real rates at 0.5%. Treat top-tail magnitudes as **upper-bound / fragile** given PUMF top-coding and no high-income oversample.

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
3. Weak ultra-wealthy coverage.
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

## Next iterations

- Optional sensitivity: raise registered equity share above the PBO non-reg proxy (e.g. +10–20 pp for TFSAs) to bound the tax-location bias.
- Bootstrap SEs for 2023.
- Optional SHS consumption-incidence appendix.
- Tighten top-tail presentation (P80–90 vs P99) for the paper’s main tables.
- Compare Teranet house-price *actual* changes vs mortgage-affordability counterfactual.
- Rate pass-through and short-term renewal-risk incidence (postponed).

## Run artifacts

Tables: `output/tables/`  
Figures: `output/figures/`
