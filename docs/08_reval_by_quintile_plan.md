# Plan: revaluation contributions by income quintile

## Goal

Extend the WP 29392-style revaluation contribution chart (`revaluation_contributions.png`) with a **panel figure and companion table** that break the same asset/liability channels out by **household income quintile** (Q1–Q5), with **Q5 as the top row**.

## What already exists

| Piece | Location | Notes |
|-------|----------|--------|
| Reval helpers | `code/utils/accounting.R` | `consol_reval`, `duration_reval`, `house_price_ratio` |
| Period reval (aggregate means) | `code/05_inequality_effects.R` | Writes `revaluation_contributions_by_period.csv` |
| Aggregate stacked chart | `code/06_tables_figures.R` | `revaluation_contributions.png` |
| Period NIG by **wealth** Q | `code/04_inflation_gain.R` | `d_stk`…`d_dbt` by `wealth_q` (no housing channel; no income-Q cut) |
| Portfolio + `wealth_q` | `code/03_portfolio_map.R` | Within-year weighted quintiles of `w_wolff`; `INC = inc_it` |

### Revaluation components (same as `05`)

Portfolios fixed at period start (`year0`). For each inter-wave spell in `period_rates.csv`:

| Component | Formula |
|-----------|---------|
| Stocks | `consol_reval(STK, real0, real1)` (duration fallback if rates ≤ floor) |
| Business | `consol_reval(BUS, real0, real1)` |
| Bonds | `duration_reval(BND, Δgoc10, goc10_0, D=8)` |
| Liquid assets | `-LIQ × infl_cum` |
| Debt devaluation | `DBT × infl_cum` |
| Housing (mortgage-rate) | owners: `HOUS × (hp_ratio − 1)` with Canadian 25y amort, LTV 0.80 |

`d_total_no_hous` = sum of the first five; `d_total` adds housing.

## Quintile definition (this deliverable)

- **Income quintiles**, not wealth: within each survey year, weighted quintiles of `INC` (`inc_it`) using household weights.
- Labels `Q1`…`Q5` (lowest → highest income).
- Households with non-finite `INC` are dropped from quintile assignment.
- Core NIG / wealth-inequality cuts elsewhere remain on `wealth_q`; this figure is explicitly an **income** cut so it can be juxtaposed with SHS income-quintile basket results without implying wealth classes.

## Implementation (one pass)

New script: `code/12_reval_by_quintile.R`

1. Load `sfs_portfolio.rds` + `period_rates.csv` (build upstream if missing).
2. Attach `income_q` within year.
3. Loop periods; compute household reval components (mirror `05`).
4. Summarise weighted means by `period × income_q`.
5. Write:
   - `output/tables/reval_by_quintile_by_period.csv`
   - `output/figures/reval_by_quintile_panels.png` (+ `.pdf`)
6. Facet order: `Q5`, `Q4`, `Q3`, `Q2`, `Q1` (top → bottom).

Wire: `source("code/12_reval_by_quintile.R")` after `05` / `06` in `code/run_all.R`.

## Status

Implemented in this pass (data present via `data/processed/sfs_portfolio.rds`).
