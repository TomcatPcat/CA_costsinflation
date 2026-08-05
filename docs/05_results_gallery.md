# Results gallery — inflation tax on Canadian households

This gallery collects every figure under `output/figures/` with a short reading guide. Companion CSVs live in [`output/tables/`](../output/tables/). Evolving interpretation and open issues are in [`paper_notes.md`](paper_notes.md); short and extended abstracts are in [`abstract.md`](abstract.md) and [`extended_abstract.md`](extended_abstract.md).

**Alternative NIG scalings.** Wherever a chart shows \(NIG\)/income, companion panels use **resources** (= INC + Wolff NW) and **cash-on-hand** (= INC + LIQ). Same numerator; ratio of weighted means. Scripts: `code/14_nig_alt_scalings.R` (wealth quintiles), `code/15_nig_alt_scalings_all_cuts.R` (tenure / age / geo / sensitivity). Notes: [`12_nig_alt_scalings.md`](12_nig_alt_scalings.md). Figures marked **N/A for alt scaling** are not \(NIG\)/income incidence charts.

## What the paper does

Edward N. Wolff’s net inflation gain identity \(NIG = IG - IT\) pairs an inflation tax on income with balance-sheet gains from debt devaluation and asset revaluation (NBER WPs 31775 and 29392). This project adapts that accounting to Canada using the Survey of Financial Security (SFS, 1999–2023): Wolff-style marketable net worth, PBO look-through for registered accounts, and 60/40 mutual-fund allocation. Core results are \(NIG\) by wealth quintile, tenure, age, and analytic region. A Survey of Household Spending (SHS) appendix adds recent cash-flow / basket incidence (necessities and shelter shares) for 2017–2023 only; it complements, and does not replace, the SFS balance-sheet history.

## Caveats (read first)

- **PUMF limits.** SFS cannot support reliable ultra-wealthy inference; treat Q5 \(NIG\)/income magnitudes as fragile / upper-bound. No CMA on the EFAM PUMF; geography stops at province / analytic region.
- **Registered mix.** PBO non-registered look-through likely understates equity inside RRSPs/TFSAs. Mutual funds stay at 60/40.
- **Accounting choices.** Real rates floored at 0.5%; equity consol wedge capped. Period results fix portfolios at the start of each inter-wave interval.
- **Mortgage institutions.** Wolff’s 30y FRM affordability curve is a U.S. benchmark beside Canadian amortization schedules; short-term renewal risk and rate pass-through are deferred.
- **SHS ≠ SFS.** SHS cuts are by household income (not wealth); units and concepts differ from EFAM \(NIG\). Never read SHS panels as wealth-quintile results.

---

## 0. Macro context (introduction)

Script: `code/11_macro_context_figure.R`. Table: `data/external/macro_context_annual.csv`. Sources: [`MACRO_CONTEXT_SOURCES.md`](../data/external/MACRO_CONTEXT_SOURCES.md).

**N/A for alt scaling** (macro backdrop, not household \(NIG\)/income).

### Canadian rates, inflation, asset returns, and wages (~1998–present)

![Canadian macro context 1998–present](../output/figures/macro_context_1998_present.png)

Annual series for the paper’s introduction: Bank of Canada **target overnight rate** (policy rate; annual average), StatCan all-items CPI inflation, housing appreciation (BIS residential property prices via FRED, or NHPI fallback), S&P/TSX Composite **price** returns, and SEPH average weekly earnings growth. Dashed lines mark SFS survey years; grey bands approximate recessions (2008–09, 2020). Use this as backdrop only—household \(NIG\) is computed at SFS waves, not from these macro paths alone.

---

## 1. NIG core (wealth quintiles)

Tables: `nig_by_year_wealth_quintile.csv`, `nig_by_period_wealth_quintile.csv`, `portfolio_by_wealth_quintile.csv`, `nig_alt_scalings_*.csv`.

### Latest SFS wave — \(NIG\) by wealth quintile

**Definition:** single-year snapshot on 2023 balance sheets using that year’s YoY CPI inflation (and contemporaneous rates) applied once—not cumulative \(NIG\) from 1999→2023, and not the 2019–2023 inter-wave spell.

| Scale | Figure |
|-------|--------|
| Income | ![NIG / income (latest)](../output/figures/nig_pct_income_latest.png) |
| Resources | ![NIG / resources (latest)](../output/figures/nig_over_resources_by_quintile_latest.png) |
| Cash-on-hand | ![NIG / cash-on-hand (latest)](../output/figures/nig_over_cash_on_hand_by_quintile_latest.png) |

Headline snapshot: \(NIG\) as a share of the chosen denominator by wealth quintile in the latest SFS year. Bars above zero mean balance-sheet inflation gains exceed the income tax on that group’s mean income (ratio of means). Middle quintiles are typically strongly positive—qualitatively echoing Wolff’s “not a tax for the middle class”—while Q1 is near zero on thin balance sheets. Q5’s large **income**-scaled ratios are primarily long-duration equity/business revaluation, not leverage: in 2023, mean STK+BUS is ~$900k (Q5) vs ~$30k (Q3) and ≈85% of Q5 \(IG\); debt/assets are lowest at the top (~0.08 vs ~0.28 for Q3). Resources and CoH compress Q5 relative to income while keeping Q1 finite (unlike \(NIG\)/NW). Magnitudes remain fragile (PUMF top-coding). Q5 diagnostics (tables only, no figures): `q5_nig_interrogation_*.csv`, `q5_vs_q3_nig_decomp.csv` — see [`11_q5_nig_interrogation.md`](11_q5_nig_interrogation.md).

### Full-span period \(NIG\) (1999–2023)

Table: `nig_by_quintile_1999_2023.csv` (+ `nig_alt_scalings_by_quintile_1999_2023.csv`).

| Scale | Figure |
|-------|--------|
| Income | ![Full-span NIG / income](../output/figures/nig_pct_income_by_quintile_1999_2023.png) |
| Resources | ![Full-span NIG / resources](../output/figures/nig_over_resources_by_quintile_1999_2023.png) |
| Cash-on-hand | ![Full-span NIG / cash-on-hand](../output/figures/nig_over_cash_on_hand_by_quintile_1999_2023.png) |

Same Wolff period accounting as the inter-wave facets below, but over the entire SFS window: 1999 portfolios held fixed; cumulative CPI inflation and the 1999→2023 endpoint rate wedge.

### Period \(NIG\) by quintile (inter-wave)

| Scale | Figure |
|-------|--------|
| Income | ![Period NIG / income](../output/figures/nig_period_by_quintile.png) |
| Resources | ![Period NIG / resources](../output/figures/nig_over_resources_by_quintile_periods.png) |
| Cash-on-hand | ![Period NIG / cash-on-hand](../output/figures/nig_over_cash_on_hand_by_quintile_periods.png) |

Each facet is an inter-wave spell with portfolios held fixed at the start of the interval. Compare signs across periods: high-inflation / falling-rate spells (e.g. 1999–2005, 2019–2023) favour middle quintiles; 2016–2019 shows mild inflation with rising real rates, so \(NIG\) often turns negative. Read within-facet quintile gradients rather than comparing absolute levels across periods with very different cumulative CPI.

### Annualized \(NIG\) (cross-spell comparable)

Script: `code/13_annualized_nig.R` (income); alt twins in `14` / `15`. Notes: [`09_annualized_nig_notes.md`](09_annualized_nig_notes.md). Tables: `nig_*_annualized*.csv`, `nig_alt_scalings_*_annualized.csv`.

| Scale | Period facets | Full span 1999–2023 | Dodged (all spells) |
|-------|---------------|---------------------|---------------------|
| Income | ![ann periods income](../output/figures/nig_pct_income_by_quintile_periods_annualized.png) | ![ann full income](../output/figures/nig_pct_income_by_quintile_1999_2023_annualized.png) | ![ann dodged income](../output/figures/nig_pct_income_by_quintile_annualized_dodged.png) |
| Resources | ![ann periods resources](../output/figures/nig_over_resources_by_quintile_periods_annualized.png) | ![ann full resources](../output/figures/nig_over_resources_by_quintile_1999_2023_annualized.png) | ![ann dodged resources](../output/figures/nig_over_resources_by_quintile_annualized_dodged.png) |
| Cash-on-hand | ![ann periods CoH](../output/figures/nig_over_cash_on_hand_by_quintile_periods_annualized.png) | ![ann full CoH](../output/figures/nig_over_cash_on_hand_by_quintile_1999_2023_annualized.png) | ![ann dodged CoH](../output/figures/nig_over_cash_on_hand_by_quintile_annualized_dodged.png) |

Same period accounting as above, but ratios converted to a **per-year** rate: geometric \((1+x)^{1/T}-1\) with \(T=\text{year1}-\text{year0}\) (arithmetic \(x/T\) only if \(1+x\le 0\)). Use these panels—not the raw cumulative bars—when comparing short spells to long ones or to Wolff’s multi-decade windows.

### Debt / assets by wealth quintile

**N/A for alt scaling** (leverage, not \(NIG\)/income).

![Debt-to-asset ratio by wealth quintile](../output/figures/debt_asset_by_quintile.png)

Leverage that feeds the debt-devaluation term of \(IG\). Debt/assets fall sharply from Q1 to Q5. Pair with the \(NIG\) bars above—high leverage alone does not guarantee high \(NIG\)/income.

---

## 2. Inflation sensitivity

Table: `nig_inflation_sensitivity.csv`, `nig_alt_scalings_inflation_sensitivity.csv`.

### Counterfactual inflation and \(NIG\)

| Scale | Figure |
|-------|--------|
| Income | ![NIG / income vs inflation](../output/figures/nig_inflation_sensitivity.png) |
| Resources | ![NIG / resources vs inflation](../output/figures/nig_inflation_sensitivity_resources.png) |
| Cash-on-hand | ![NIG / CoH vs inflation](../output/figures/nig_inflation_sensitivity_cash_on_hand.png) |

Holding the latest-year balance sheets fixed, each line traces \(NIG\)/denominator as assumed annual inflation varies. Slopes show how sensitive each quintile is to the inflation rate used in \(IG\) and \(IT\). Use as a robustness check on the headline snapshot, not as a forecast.

---

## 3. Inequality and revaluation

Tables: `revaluation_contributions_by_period.csv`, `reval_by_quintile_by_period.csv`, `inequality_revaluation_by_period.csv`, `inequality_baseline_by_year.csv`. Interest-rate shares, Gini paths, and shut-offs are in [Section 4](#4-interest-rates-and-revaluation).

**N/A for alt scaling** (dollar revaluation stacks and \(\Delta\)Gini, not \(NIG\)/income).

### Mean revaluation contributions by period

![Mean wealth revaluation contributions by period](../output/figures/revaluation_contributions.png)

Stacked mean dollar contributions (stocks, business, bonds, liquid assets, debt devaluation, housing mortgage-rate channel) with portfolios fixed at period start (WP 29392-style).

### Revaluation contributions by income quintile

![Revaluation contributions by income quintile](../output/figures/reval_by_quintile_panels.png)

Same WP 29392-style stack, faceted by household income quintile. Companion table: `reval_by_quintile_by_period.csv`. Plan: [`08_reval_by_quintile_plan.md`](08_reval_by_quintile_plan.md).

### Change in wealth Gini from revaluation

![Change in wealth Gini from inflation/rate revaluation](../output/figures/gini_change_revaluation.png)

\(\Delta\)Gini from applying the period revaluation to start-of-period wealth. Negative bars are equalizing; positive bars mean the revaluation widened measured wealth inequality.

---

## 4. Interest rates and revaluation

Dedicated WP 29392-style interest-rate / balance-sheet gallery (paper Section `Interest rates and the household balance sheet`). Tables: `revaluation_contribution_shares_by_period.csv`, `revaluation_vs_actual_growth_by_period.csv`, `revaluation_gini_shutoffs_by_period.csv`, `revaluation_by_age_period.csv`. Plan: [`07_interest_rate_implementation_plan.md`](07_interest_rate_implementation_plan.md).

**N/A for alt scaling** (channel shares, Gini paths/shut-offs — not \(NIG\)/income incidence).

### Channel shares of mean revaluation (F-IR2)

![Channel shares of mean revaluation](../output/figures/revaluation_contribution_shares.png)

Stacked **shares** of mean \(\Delta\)NW by channel, with and without the CA 25y housing mortgage-rate channel. Near-zero denominator periods (e.g. 2019–2023 with housing wipeout) are omitted.

### Gini path: actual vs revaluation (F-IR3)

![Gini path actual vs reval](../output/figures/gini_path_actual_vs_reval.png)

Actual SFS wealth Gini versus period revaluation counterfactuals (no housing / +CA 25y / +Wolff 30y). Each spell is independent—start-of-period portfolios only.

### Gini shut-offs by period (T-IR3 companion)

![Gini shut-offs by period](../output/figures/gini_shutoffs_by_period.png)

\(\Delta\)Gini under channel shut-offs (equity+business only, housing only, debt+liquid only, and full packages).

---

## 5. Mortgage affordability and housing channel

Tables: `mortgage_affordability_curves.csv`, `mortgage_affordability_wolff_points.csv`, `mortgage_hp_ratio_sensitivities.csv`, `housing_status_by_year.csv`, `housing_channel_by_tenure_period.csv`.

**N/A for alt scaling** (affordability / \(hp\_ratio\) / housing-channel dollars — not \(NIG\)/income).

### Wolff 30y FRM vs Canadian amortization

![Mortgage affordability: Wolff 30y FRM vs Canadian amortization](../output/figures/mortgage_affordability_wolff_vs_canada.png)

Affordable house-price index at fixed payment and 20% down, normalized to 1 at a 6.5% rate.

### Period house-price affordability ratios (sensitivities)

![Period house-price affordability ratios under rate-path assumptions](../output/figures/mortgage_hp_ratio_sensitivities.png)

For each inter-wave spell, \(hp\_ratio\) = affordable price at end-of-period mortgage rate ÷ start-of-period rate, under alternative assumptions.

### Housing status shares (latest)

![Housing status shares (latest year)](../output/figures/housing_status_shares_latest.png)

Weighted population shares of owner-with-mortgage, free-and-clear owner, and renter in the latest SFS wave.

### Housing / debt channels by tenure (latest period)

![Mean housing / debt channels by tenure](../output/figures/housing_channel_by_tenure.png)

Mean dollar housing affordability and debt-devaluation contributions by tenure for the most recent inter-wave period. Core \(NIG\) excludes this housing HP channel unless noted—see tenure \(NIG\) in [Section 6](#6-tenure-age-and-geography).

---

## 6. Tenure, age, and geography

Script: `code/08_demo_geo_breakdowns.R` (income); `code/15_nig_alt_scalings_all_cuts.R` (resources / CoH). Tables: `nig_portfolio_by_*_latest.csv`, `nig_by_period_age_band.csv`, `nig_by_period_geo_group.csv`, `nig_alt_scalings_latest_*.csv`, `nig_alt_scalings_by_period_*.csv`, `geo_availability_note.csv`.

### \(NIG\) by housing tenure (latest)

| Scale | Figure |
|-------|--------|
| Income | ![NIG / income by tenure](../output/figures/nig_by_tenure_latest.png) |
| Resources | ![NIG / resources by tenure](../output/figures/nig_over_resources_by_tenure_latest.png) |
| Cash-on-hand | ![NIG / CoH by tenure](../output/figures/nig_over_cash_on_hand_by_tenure_latest.png) |

Core \(IG - IT\) (excluding the mortgage-rate house-price channel) by tenure. Free-and-clear owners typically show higher \(NIG\)/income than mortgagors—diverging from a pure leverage narrative—while renters sit lowest.

### \(NIG\) by age band (latest)

| Scale | Figure |
|-------|--------|
| Income | ![NIG / income by age](../output/figures/nig_by_age_latest.png) |
| Resources | ![NIG / resources by age](../output/figures/nig_over_resources_by_age_latest.png) |
| Cash-on-hand | ![NIG / CoH by age](../output/figures/nig_over_cash_on_hand_by_age_latest.png) |

Life-cycle gradient for the major income earner’s age band. Older bands usually post higher \(NIG\)/income as net worth and equity exposure accumulate.

### Debt / assets by age band (latest)

**N/A for alt scaling** (leverage).

![Debt / assets by age band](../output/figures/debt_asset_by_age_latest.png)

Leverage across the same age bands. Contrasts with the rising age \(NIG\)/income profile: middle-age and older gains are more asset-revaluation than debt-devaluation.

### \(NIG\) by age × tenure (latest)

| Scale | Figure |
|-------|--------|
| Income | ![NIG / income by age × tenure](../output/figures/nig_by_age_tenure_latest.png) |
| Resources | ![NIG / resources by age × tenure](../output/figures/nig_over_resources_by_age_tenure_latest.png) |
| Cash-on-hand | ![NIG / CoH by age × tenure](../output/figures/nig_over_cash_on_hand_by_age_tenure_latest.png) |

Dodged bars for mortgage / free-and-clear / renter within each age band.

### \(NIG\) by analytic region (latest)

| Scale | Figure |
|-------|--------|
| Income | ![NIG / income by region](../output/figures/nig_by_geo_group_latest.png) |
| Resources | ![NIG / resources by region](../output/figures/nig_over_resources_by_geo_group_latest.png) |
| Cash-on-hand | ![NIG / CoH by region](../output/figures/nig_over_cash_on_hand_by_geo_group_latest.png) |

Four analytic regions: West Coast (BC); Central (ON/QC/MB); Oil Prairies (AB/SK); East Coast (Atlantic). Province is missing in 2005 on this panel; analytic `geo_group` uses a region fallback that year (Prairies unsplit)—see `geo_availability_note.csv`.

### \(NIG\) by province (latest)

| Scale | Figure |
|-------|--------|
| Income | ![NIG / income by province](../output/figures/nig_by_province_latest.png) |
| Resources | ![NIG / resources by province](../output/figures/nig_over_resources_by_province_latest.png) |
| Cash-on-hand | ![NIG / CoH by province](../output/figures/nig_over_cash_on_hand_by_province_latest.png) |

Finer provincial cut of the same latest-year measure. Territories are not on the PUMF.

### Mean Wolff net worth by province (latest)

**N/A for alt scaling** (wealth levels, not \(NIG\)/income).

![Mean Wolff net worth by province](../output/figures/wealth_by_province_latest.png)

### Mean Wolff net worth by analytic region over time

**N/A for alt scaling** (wealth levels).

![Mean Wolff net worth by analytic region](../output/figures/wealth_by_geo_group_years.png)

### Period \(NIG\) by analytic region

| Scale | Figure |
|-------|--------|
| Income | ![Period NIG / income by region](../output/figures/nig_period_by_geo_group.png) |
| Resources | ![Period NIG / resources by region](../output/figures/nig_over_resources_by_geo_group_periods.png) |
| Cash-on-hand | ![Period NIG / CoH by region](../output/figures/nig_over_cash_on_hand_by_geo_group_periods.png) |

Faceted inter-wave \(NIG\) by analytic region with start-of-period portfolios.

### Period \(NIG\) by age band

| Scale | Figure |
|-------|--------|
| Income | ![Period NIG / income by age](../output/figures/nig_period_by_age.png) |
| Resources | ![Period NIG / resources by age](../output/figures/nig_over_resources_by_age_periods.png) |
| Cash-on-hand | ![Period NIG / CoH by age](../output/figures/nig_over_cash_on_hand_by_age_periods.png) |

Same period design by age band. Life-cycle gaps can compress or widen depending on the rate and inflation path.

---

## 7. SHS consumption appendix

Tables: `shs_consumption_by_income_quintile.csv`, `shs_consumption_by_tenure.csv`, `shs_consumption_by_region.csv`, `shs_sfs_juxtaposition_2019_2023.csv`, `shs_years_loaded.csv`. Plan: [`03_shs_consumption_plan.md`](03_shs_consumption_plan.md).

**N/A for alt scaling** (basket / consumption shares). The SFS–SHS juxtaposition left panel uses \(NIG\)/income by tenure; resources/CoH tenure twins are in [Section 6](#nig-by-housing-tenure-latest) rather than duplicated here.

### Necessities share by income quintile

![Necessities share of current consumption (SHS)](../output/figures/shs_necessities_by_income_quintile.png)

Necessities (food + shelter + health) as a share of current consumption (`TC001`), by within-year household income quintile—not wealth.

### Shelter share by income quintile

![Shelter share of current consumption (SHS)](../output/figures/shs_shelter_by_income_quintile.png)

### Shelter and mortgage-payment exposure by tenure

![Shelter exposure by tenure (SHS)](../output/figures/shs_shelter_mortgage_by_tenure.png)

### Shelter share by analytic region

![Shelter share of consumption by analytic region (SHS)](../output/figures/shs_shelter_by_region.png)

### SFS \(NIG\) vs SHS necessities by tenure (2019 & 2023)

![Two inflation channels by tenure (2019 & 2023)](../output/figures/shs_sfs_tenure_juxtaposition_2019_2023.png)

Side-by-side: left = SFS balance-sheet \(NIG\)/income by tenure; right = SHS necessities share by tenure. Units and universes differ (EFAM vs household)—not a single welfare metric.

---

## Companion table index (selected)

| Theme | Key tables |
|-------|------------|
| Annual / period NIG | `nig_by_year.csv`, `nig_by_year_wealth_quintile.csv`, `nig_by_period_wealth_quintile.csv`, `nig_by_quintile_1999_2023.csv` |
| Annualized period NIG | `nig_by_period_wealth_quintile_annualized.csv`, `nig_by_quintile_1999_2023_annualized.csv`, `nig_annualized_by_quintile.csv` |
| Alt scalings (resources / CoH) | `nig_alt_scalings_*.csv` (quintile, tenure, age, age×tenure, geo, province, period age/geo, inflation sensitivity) |
| Sensitivity | `nig_inflation_sensitivity.csv`, `nig_alt_scalings_inflation_sensitivity.csv` |
| Inequality | `inequality_revaluation_by_period.csv`, `revaluation_contributions_by_period.csv`, `reval_by_quintile_by_period.csv` |
| Interest rates (29392) | `revaluation_contribution_shares_by_period.csv`, `revaluation_vs_actual_growth_by_period.csv`, `revaluation_gini_shutoffs_by_period.csv`, `revaluation_by_age_period.csv` |
| Mortgages / tenure | `mortgage_affordability_*.csv`, `housing_channel_by_tenure_period.csv`, `housing_status_by_year.csv` |
| Demo / geo | `nig_portfolio_by_*`, `nig_by_period_*`, `geo_availability_note.csv` |
| SHS | `shs_consumption_by_*.csv`, `shs_sfs_juxtaposition_2019_2023.csv` |
| Diagnostics | `registered_mix_pbo_diagnostics.csv`, `q5_nig_interrogation_*.csv`, `q5_vs_q3_nig_decomp.csv` |

Regenerate figures with `"C:\Program Files\R\R-4.5.2\bin\Rscript.exe" code/run_all.R` from the repo root (SHS steps skip if local SHS paths are missing).
