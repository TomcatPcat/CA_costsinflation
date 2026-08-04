# Wolff methodology summary (WP 31775 & WP 29392)

This note summarizes Edward N. Wolff’s accounting framework as adapted in this project. It is not a substitute for the papers.

## Data and wealth concept (both papers)

- **US source:** Federal Reserve Survey of Consumer Finances (SCF), primarily 1983–2019.
- **Wealth (marketable net worth):** assets that can be sold or otherwise realized, net of debts.
  - **Included:** housing and other real estate, businesses, stocks, bonds, deposits, DC pensions / IRAs (consolidated into underlying assets), valuables.
  - **Excluded:** vehicles (and other durables), defined-benefit pension wealth, Social Security wealth.
- **Consolidated portfolio:** stocks and bonds held indirectly through mutual funds and DC accounts are allocated to equity vs fixed-income buckets.
- **Canadian registered accounts (RRSP / RRIF / TFSA / other retirement):** SFS reports account *totals* only. Following the Parliamentary Budget Officer’s TFSA methodology, each household’s registered look-through mix (equity / bonds / liquid) is set equal to that household’s **non-registered** financial mix in the SFS (stocks, bonds, mutual funds unpacked 60/40, deposits). Households with no non-registered financial assets use a fixed fallback (60/30/10). See Office of the Parliamentary Budget Officer, *The Tax-Free Savings Account* (quote: “TFSA portfolio composition is assumed to be identical to those observed in non-registered investment accounts of the Survey of Financial Security”).
- **Bias note:** Tax-efficient asset *location* encourages holding higher-growth / higher-risk equities in TFSAs (and often growth assets in RRSPs) while leaving taxable accounts more deposit- or Canadian-dividend-heavy. Copying the non-registered mix therefore likely **understates** the equity share inside registered accounts—**especially TFSAs**—and overstates their liquid/bond share relative to true holdings. Equity-sensitive IG terms are accordingly conservative on the stock channel.

## WP 31775 — Net inflation gain

### Channels

Inflation affects households through:

1. **Income (always a tax when inflation > 0):** real purchasing power of income falls.
2. **Balance sheet:** real value of nominal debt falls; real value of liquid nominal assets falls; asset prices that are discounted at the *real* interest rate rise when inflation lowers the real rate relative to the nominal rate (Fisher wedge).

House-price responses to *nominal* mortgage rates are discussed in the papers but are **not** part of the inflation-gain (IG) term; they belong to the broader interest-rate / monetary analysis (closer to WP 29392).

### Definitions

Let `INF` be CPI inflation over the period, `INC` household income, `LIQ` liquid assets, `DBT` total debt, and `STK`, `BUS`, `BND` the present-value functions of stock, business, and bond holdings at a given interest rate.

- **Inflation gain on wealth**

  `IG = [STK(r_n) − STK(r)] + [BUS(r_n) − BUS(r)] + [BND(r_n) − BND(r)] − LIQ·INF + DBT·INF`

  In the papers, `r` is the **real** interest rate and `r_n` the **nominal** rate. Empirically, the equity/bond/business terms contribute *positively* to IG when inflation lowers the real discount rate relative to the nominal rate. This project implements the economically consistent wedge:

  `PV_gain ≈ holdings × (1 − r / r_n)` when `r = r_n − INF` (consol / perpetual approximation), plus period-to-period revaluation from observed changes in real yields (WP 29392 style).

- **Inflation tax on income**

  `IT = INC · INF`

  Equivalent to the gap between nominal and real income growth when real income is held fixed in counterfactuals.

- **Net inflation gain**

  `NIG = IG − IT`

  Positive NIG means balance-sheet gains from inflation outweigh the income tax; negative NIG means the reverse.

### Main US findings (Wolff)

- Middle wealth quintiles are highly leveraged (high debt/assets) → large debt-devaluation gains → **large positive NIG**.
- Bottom wealth groups hold little debt relative to income and more of their limited assets in liquid form → **negative NIG**.
- Top groups hold equities/businesses but little leverage relative to income → NIG often small or negative despite asset gains.
- Inflation reduced measured wealth inequality and the racial wealth gap in the US SCF.

### Sensitivity

Wolff resimulates at higher constant inflation rates (e.g. 4%, 6%, 8%, 10%). Both IG and IT scale up; the sign of NIG by class is the object of interest.

## WP 29392 — Interest rates, inflation, and wealth inequality

Focus: **direct** balance-sheet effects of declining interest rates and inflation moderation on mean/median wealth and the Gini — *not* full general-equilibrium monetary-policy identification.

### Mechanisms coded here

| Channel | Direction when rates fall / inflation rises |
|--------|-----------------------------------------------|
| Stock / business PV | ↑ when real discount rates fall |
| Bond PV | ↑ when yields fall (duration-dependent) |
| House prices | ↑ when *nominal* mortgage rates fall (affordability); separate from IG |
| Liquid assets | Face value fixed; real value ↓ with inflation |
| Debt | Face value fixed; real value ↓ with inflation (equalizing if leverage falls with wealth) |

Portfolios are held fixed at initial-period composition; savings and portfolio reshuffling are out of scope (direct effects only).

### Inequality metrics

- Mean and median net worth with vs without revaluation
- Gini of net worth
- Percentile ratios (e.g. P99 / median) when sample size allows
- Breakdown of contributions: debt, liquid assets, stocks, bonds, business, (optional) housing

## Implementation mapping in this repo

| Script | Role |
|--------|------|
| `code/01_build_sfs_panel.R` | Load SFS; Wolff-style wealth definition |
| `code/02_macro_series.R` | Canadian CPI, GoC 10y, mortgage rates |
| `code/03_portfolio_map.R` | Consolidated STK / BND / LIQ / BUS / DBT / HOUS (PBO registered mix) |
| `code/04_inflation_gain.R` | IG, IT, NIG by wealth class (31775) |
| `code/05_inequality_effects.R` | Revaluation → mean/median/Gini (29392) |
| `code/06_tables_figures.R` | Write `output/` |

## References

- Wolff, E. N. (2023). NBER Working Paper 31775.
- Wolff, E. N. (2021). NBER Working Paper 29392.
- Office of the Parliamentary Budget Officer. *The Tax-Free Savings Account*. Ottawa. (Registered-account portfolio mix imputed from SFS non-registered holdings.)
