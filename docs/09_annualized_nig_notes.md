# Annualized NIG notes

## Why annualize?

Inter-wave SFS spells differ in length, and the full sample span is much longer:

| Period | \(T\) (years) | Source |
|--------|---------------|--------|
| 1999–2005 | 6 | `year1 − year0` (= `period_rates$n_years`) |
| 2005–2012 | 7 | same |
| 2012–2016 | 4 | same |
| 2016–2019 | 3 | same |
| 2019–2023 | 4 | same |
| 1999–2023 | 24 | same |

Raw cumulative \(NIG / \text{mean income}\) over a long spell is not comparable to a short spell (or to Wolff’s multi-decade tables) without converting to a common per-year scale.

## Formula (chosen)

Let \(x =\) cumulative `nig_over_inc` = `mean_NIG / mean_inc` over the spell, and \(T =\) `year1 − year0`.

**Preferred (geometric) for the ratio:**

\[
r^{\text{ann}} = (1 + x)^{1/T} - 1
\]

when \(1 + x > 0\). This treats \(x\) as a cumulative rate of “NIG relative to income” over the spell and converts it to a constant annual rate—the natural analogue of annualizing a multi-year return.

**Fallback (arithmetic)** when \(1 + x \le 0\) (geometric undefined on the reals), e.g. large negative Q5 spells:

\[
r^{\text{ann}} = x / T
\]

Flagged in tables as `nig_over_inc_ann_method = "arithmetic_fallback"`.

**Dollar means (linear):** `mean_NIG_ann = mean_NIG / T` (and likewise for IG, IT). Dollar flows/levels over calendar time are additive; dividing by \(T\) is the right scale for “average annual dollars,” not geometric compounding.

### Why not always \(x/T\)?

Arithmetic \(x/T\) understates (overstates) the annual rate when cumulative \(x\) is large and positive (negative but \(> -1\)). Geometric preserves the compounding interpretation needed to compare a 3-year spell to a 24-year span or to Wolff’s long windows.

## Pipeline

- Script: `code/13_annualized_nig.R` (after `04` / `06`; wired in `run_all.R`).
- Inputs: `nig_by_period_wealth_quintile.csv`, `nig_by_quintile_1999_2023.csv`.
- Outputs:
  - `output/tables/nig_by_period_wealth_quintile_annualized.csv`
  - `output/tables/nig_by_quintile_1999_2023_annualized.csv`
  - `output/tables/nig_annualized_by_quintile.csv` (inter-wave + full span)
  - `output/figures/nig_pct_income_by_quintile_periods_annualized.{png,pdf}`
  - `output/figures/nig_pct_income_by_quintile_1999_2023_annualized.{png,pdf}`
  - `output/figures/nig_pct_income_by_quintile_annualized_dodged.png`

## Caveats

- Annualization does not change the underlying Wolff period accounting (portfolios fixed at `year0`; cumulative CPI and endpoint rate wedge).
- Geometric annualization of a *ratio of means* is a reporting transform, not a household-level compound path.
- When fallback arithmetic is used, interpret that cell cautiously and prefer within-period quintile rankings over cross-period magnitude comparisons for that cell.
