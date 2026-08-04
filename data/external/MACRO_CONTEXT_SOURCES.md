# Macro context series — sources and definitions

Used by `code/11_macro_context_figure.R` to build `macro_context_annual.csv` and
`output/figures/macro_context_1998_present.png` (and `.pdf`).

Live downloads are preferred. If a download fails, the script reads the matching
`fallback_*.csv` in this folder (and may splice early wage years from fallback
even when SEPH live data start later).

## 1. Bank of Canada policy rate

| Item | Detail |
|------|--------|
| **Series** | **Target for the overnight rate** (policy interest rate) |
| **Not** | Bank Rate (`V122530`), which equals the target + 0.25 percentage points |
| **Primary** | BoC Valet `STATIC_ATABLE_V39079` (monthly), annual average |
| **URL** | `https://www.bankofcanada.ca/valet/observations/STATIC_ATABLE_V39079/csv` |
| **Fallback splice** | Pre-2009: Bank Rate − 0.25 pp (`V122530`); from 2009: daily target `V39079` |
| **Offline** | `fallback_policy_rate.csv` |
| **Units** | Percent (annual average level) |

## 2. CPI inflation

| Item | Detail |
|------|--------|
| **Series** | Canada all-items CPI, year-over-year % change of the **annual average** index |
| **Primary** | Statistics Canada table **18-10-0005** (CSV zip) |
| **URL** | `https://www150.statcan.gc.ca/n1/tbl/csv/18100005-eng.zip` |
| **Project reuse** | `macro_annual.csv` `infl_yoy` if the zip pull fails |
| **Offline** | `fallback_cpi_inflation.csv` |
| **Units** | Percent |

## 3. Housing market returns

| Item | Detail |
|------|--------|
| **Preferred** | BIS residential property price index for Canada, YoY % of annual-average index |
| **Primary** | FRED **`QCAN628BIS`** (BIS RPP, Canada) |
| **URL** | `https://fred.stlouisfed.org/graph/fredgraph.csv?id=QCAN628BIS` |
| **Alt (new housing)** | StatCan NHPI **18-10-0205**, Canada, Total (house and land) |
| **URL (alt)** | `https://www150.statcan.gc.ca/n1/tbl/csv/18100205-eng.zip` |
| **Offline** | `fallback_housing_return.csv` |
| **Note** | Teranet–National Bank HPI / CREA MLS® HPI are common market references but are not used as the primary series here because free bulk CSV access is less reliable than FRED/StatCan. NHPI covers **new** house+land prices, not resale. |
| **Units** | Percent (approximate annual house-price appreciation) |

## 4. Stock market returns

| Item | Detail |
|------|--------|
| **Series** | Prefer **S&P/TSX Composite** calendar-year **price** return (not total return) |
| **Primary** | Yahoo Finance chart API `^GSPTSE`, monthly closes → year-end price return |
| **Alt (often used)** | FRED **`SPASTT01CAM661N`** (OECD share prices, Canada), YoY % of annual avg — used when Yahoo returns 401/blocked |
| **Offline** | `fallback_equity_return.csv` |
| **Units** | Percent |
| **Note** | Figure legend/caption switch automatically when the OECD/FRED series is used |

## 5. Nominal wage growth

| Item | Detail |
|------|--------|
| **Series** | SEPH average weekly earnings including overtime, all employees, industrial aggregate excluding unclassified businesses |
| **Primary** | Statistics Canada table **14-10-0223** |
| **URL** | `https://www150.statcan.gc.ca/n1/tbl/csv/14100223-eng.zip` |
| **Coverage** | Live SEPH often starts ~2001; 1998–2000 filled from `fallback_wage_growth.csv` when present |
| **Offline** | `fallback_wage_growth.csv` |
| **Units** | Percent (YoY of annual-average earnings) |

## Figure annotations

- **SFS survey years** (vertical dashed lines): 1999, 2005, 2012, 2016, 2019, 2023.
- **Recession shading** (approximate calendar years): 2008–2009, 2020.

## Outputs

- Cleaned panel: `data/external/macro_context_annual.csv`
- Provenance of last run: `data/external/macro_context_sources_used.txt`
- Figure: `output/figures/macro_context_1998_present.png` / `.pdf`
