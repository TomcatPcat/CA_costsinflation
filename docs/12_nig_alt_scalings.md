# Alternative NIG scalings: resources and cash-on-hand

## Motivation

Two standard normalizers misbehave at the wealth extremes:

| Scale | Problem |
|-------|---------|
| **NIG / NW** | Q1 Wolff net worth (`w_wolff`) is often near zero or **negative** (high leverage). Ratio of means is undefined or explosive; household-level NIG/NW is worse. |
| **NIG / income** | Q5 has high NW/income (~19× in 2023). Equity/business revaluation of order 10–20% of NW becomes multi-hundred-percent of income (see [`11_q5_nig_interrogation.md`](11_q5_nig_interrogation.md)). |

This note documents two **stock+flow** denominators that keep Q1 finite and put Q5 on a more wealth-relevant scale without discarding income entirely.

## Definitions

Household variables (from `sfs_with_nig.rds` / portfolio map):

| Symbol | Project variable | Definition |
|--------|------------------|------------|
| Income | `INC` (= `inc_it`) | Economic-family income used in \(IT = INC \cdot INF\) |
| Net worth | `NW` (= `w_wolff`) | Wolff-style marketable NW (excl. vehicles & DB pensions); same concept as wealth-quintile ranking |
| Liquid assets | `LIQ` | Consolidated liquid bucket (`liq_direct + liq_reg` from `03_portfolio_map.R`) |

**Resources**

\[
\text{Resources} = INC + NW
\]

**Cash-on-hand (Kaplan–Violante–Weidner style)**

\[
\text{CoH} = INC + LIQ
\]

Reported ratios are **ratios of weighted means** (same convention as `nig_over_inc`):

\[
\frac{\overline{NIG}}{\overline{\text{Resources}}},\qquad
\frac{\overline{NIG}}{\overline{\text{CoH}}}
\]

not means of household ratios. This matches the core NIG/income tables and avoids tiny-denominator blow-ups at the household level.

## Edge cases

- **Group-mean denominator ≤ 0:** ratio cell is `NA` (no `pmax(., 1)` floor). Documented in table columns; figures omit those bars as missing.
- **Household mass with denom ≤ 0:** tables report weighted shares:
  - `share_w_nw_le0`
  - `share_w_resources_le0`
  - `share_w_coh_le0`
- **No winsorization / no dropping** of households for the means themselves: all finite weighted observations enter `mean_NIG` and the denominator means. The share flags are diagnostics for how much Q1 (especially) sits on non-positive NW or resources.
- Diagnostic column `nig_over_nw` is retained so Q1 NW failures remain visible beside the preferred scalings.

## Annualization

For inter-wave and full-span cumulative ratios, optional annualization reuses the rule in [`09_annualized_nig_notes.md`](09_annualized_nig_notes.md) / `code/13_annualized_nig.R`:

\[
r^{\text{ann}} = (1+x)^{1/T}-1 \quad\text{if }1+x>0;\quad\text{else }x/T
\]

with \(T = \text{year1}-\text{year0}\). Applied to `nig_over_resources` and `nig_over_coh` (and `nig_over_inc` for side-by-side).

## Pipeline

- Scripts: `code/14_nig_alt_scalings.R` (wealth quintiles; after `04` / `13`); `code/15_nig_alt_scalings_all_cuts.R` (tenure, age, age×tenure, geo, province, period-by-group, inflation sensitivity, annualized dodged). Both wired in `run_all.R`.
- **Coverage:** resources / CoH twins now exist for every gallery \(NIG\)/income group-cut (quintile, tenure, age, age×tenure, analytic region, province, period age/geo, inflation sensitivity, and annualized companions). See [`05_results_gallery.md`](05_results_gallery.md).
- NIG accounting unchanged (Wolff \(IG - IT\); period portfolios fixed at `year0`).

### Tables (`output/tables/`)

| File | Content |
|------|---------|
| `nig_alt_scalings_by_year_wealth_quintile.csv` | All survey years, YoY snapshot |
| `nig_alt_scalings_latest_wealth_quintile.csv` | Latest year only (2023) |
| `nig_alt_scalings_by_period_wealth_quintile.csv` | Inter-wave spells |
| `nig_alt_scalings_by_quintile_1999_2023.csv` | Full span |
| `nig_alt_scalings_by_period_wealth_quintile_annualized.csv` | Inter-wave, annualized |
| `nig_alt_scalings_by_quintile_1999_2023_annualized.csv` | Full span, annualized |
| `nig_alt_scalings_annualized_by_quintile.csv` | Inter-wave + full span |
| `nig_alt_scalings_latest_{tenure,age,age_tenure,geo_group,province}.csv` | Latest-year demo/geo cuts |
| `nig_alt_scalings_by_period_{age,geo_group}.csv` | Inter-wave age / geo |
| `nig_alt_scalings_inflation_sensitivity.csv` | Counterfactual INF × quintile |

### Figures (`output/figures/`)

| Pattern | Span |
|---------|------|
| `nig_over_resources_by_quintile_latest.{png,pdf}` | 2023 YoY |
| `nig_over_cash_on_hand_by_quintile_latest.{png,pdf}` | 2023 YoY |
| `nig_over_resources_by_quintile_periods.{png,pdf}` | Inter-wave |
| `nig_over_cash_on_hand_by_quintile_periods.{png,pdf}` | Inter-wave |
| `nig_over_resources_by_quintile_1999_2023.{png,pdf}` | Full span |
| `nig_over_cash_on_hand_by_quintile_1999_2023.{png,pdf}` | Full span |
| `*_periods_annualized.*` / `*_1999_2023_annualized.*` / `*_annualized_dodged.*` | Annualized companions |
| `nig_over_{resources,cash_on_hand}_by_{tenure,age,age_tenure,geo_group,province}_latest.*` | Demo/geo latest |
| `nig_over_{resources,cash_on_hand}_by_{age,geo_group}_periods.*` | Period facets |
| `nig_inflation_sensitivity_{resources,cash_on_hand}.*` | Sensitivity |

Layouts parallel the existing NIG/income charts in `06_tables_figures.R` / `08_demo_geo_breakdowns.R` / `13_annualized_nig.R`.

## Reading guide

- **Q1:** Prefer resources or CoH over NW. Check `share_w_nw_le0` and `mean_nw` — negative mean NW makes `nig_over_nw` `NA` or meaningless.
- **Q5:** Resources and CoH compress the income-scaled ratios toward wealth-relevant magnitudes while still including the income tax in the numerator via \(NIG\).
- **Comparability:** Use annualized panels when comparing spells of different length; raw cumulative bars remain useful within a single spell.
