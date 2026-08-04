# Paper notes — Quantifying the inflation tax on Canadian households

Evolving findings from the SFS-based Wolff adaptation. Regenerate numbers with `Rscript code/run_all.R`.

## Setup

- **Microdata:** SFS EFAM PUMF panel 1999–2023 (`n = 72,295`), Wolff-style net worth (excl. vehicles & DB pensions).
- **Macro:** StatCan all-items CPI (live pull when available) + BoC-style GoC 10y and 5y mortgage rates in `data/external/macro_annual.csv`.
- **Engine:** `IG − IT` (WP 31775) and period revaluation / Gini (WP 29392) in `code/04`–`05`.

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
- Housing affordability channel (Canadian 5y mortgage / 25y amort) moves with mortgage rates; included as a separate column, not in core IG.

## Barriers confirmed in practice

See [02_canadian_barriers.md](02_canadian_barriers.md). Most binding for interpretation:

1. Sparse waves + low-rate floor assumptions.
2. Registered-account stock/bond splits (60/30/10 baseline).
3. Weak ultra-wealthy coverage.
4. No full racial-gap series (`pvmfmie` incomplete historically).

## Next iterations

- Sensitivity on registered equity share (40/60/80).
- Bootstrap SEs for 2023.
- Optional SHS consumption-incidence appendix.
- Tighten top-tail presentation (P80–90 vs P99) for the paper’s main tables.
- Compare Teranet house-price *actual* changes vs mortgage-affordability counterfactual.

## Run artifacts

Tables: `output/tables/`  
Figures: `output/figures/`
