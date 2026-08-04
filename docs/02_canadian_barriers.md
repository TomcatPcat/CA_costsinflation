# Barriers to applying Wolff’s methods to Canadian data

## Survey design

| Issue | US SCF | Canadian SFS | Implication |
|-------|--------|--------------|-------------|
| Frequency | Roughly triennial, dense 1983–2019 | 1999, 2005, 2012, 2016, 2019, 2023 | Longer sub-periods; coarser attribution |
| Top tail | High-income oversample | PUMF without SCF-style list sample; top-coding | Weak “ultra-wealthy” inference; prefer quintiles / P80–90 |
| Unit | Household | Economic family (EFAM PUMF) | Close but not identical |
| Weights | Design + replicate | `pweight`; bootstrap weights in some years | Use `pweight`; optional 2023 bootstrap later |

## Wealth and portfolio measurement

| Issue | Barrier | Project response |
|-------|---------|------------------|
| Vehicles | Wolff excludes; SFS reports vehicles | Exclude from `w_wolff` |
| DB pensions | Wolff excludes; SFS has employer pension GC/TM | Exclude `pwarppg` / `pwarppt` from Wolff wealth |
| RRSP / TFSA / RRIF | No asset-class mix inside accounts on SFS PUMF | **PBO imputation:** copy each household’s non-registered STK/BND/LIQ mix into registered totals (PBO, *The Tax-Free Savings Account*). Fallback 60/30/10 if non-reg financial assets = 0. Likely **understates** equity share in registered plans (esp. TFSAs) given tax-location incentives. |
| Mutual funds | Need equity vs bond split | Baseline 60% equity / 40% bonds (sensitivity later) |
| Business equity | Available (`pwbuseq`) | Map to BUS |
| Housing | Principal residence + other RE | Track separately; housing mortgage-rate channel in WP 29392 module, not in core IG |

## Demographics Wolff emphasizes

| Concept | SFS PUMF | Response |
|---------|----------|----------|
| Race / ethnicity | Limited; `pvmfmie` (visible minority) mostly available in recent waves, heavy missingness in early years | Optional recent-wave cut only; no full 1999–2023 racial-gap replication |
| Age | Yes (`pagemie` / `pagemieg`) | Primary substitute stratification (`code/08`) |
| Tenure | Yes (`pftenur` → `housing_status`) | Owners with mortgage / free-and-clear / renters (`code/07`–`08`) |
| Province / region | Yes (`ppvres`, `pregion`) | Province + analytic regions in `code/08`; province missing in 2005 on this panel |
| CMA / city | **No** on EFAM PUMF | Not available; do not attempt CMA cuts without RDC access |

## Macro series (Canadian analogues)

| Wolff input | Canadian series | Source |
|-------------|-----------------|--------|
| CPI-U-RS | All-items CPI | StatCan 18-10-0004 / 18-10-0005 |
| 10y Treasury | GoC 10-year benchmark yield | Bank of Canada (e.g. V39055) |
| Mortgage rate | Chartered bank conventional mortgage rates (5y typical) | BoC / StatCan |
| House prices | Teranet–National Bank HPI or StatCan New Housing Price Index | External CSV |
| Equity discount rate | Real GoC 10y; TSX for optional market-return checks | BoC + market data |

### Mortgage market difference (important)

Wolff’s US charts use a **30-year fixed-rate mortgage (FRM)** affordability schedule (20% down). Canadian mortgages typically use a **short fixed term (often 3–5 years)** with a longer **amortization** (25–30 years).

**How we handle this**

- **Retain Wolff’s 30y FRM affordability curve as a benchmark** and present **Canadian 25y/30y amortization** curves alongside (`code/07_mortgage_affordability.R`, figure `mortgage_affordability_wolff_vs_canada.png`).
- Period sensitivities: CA 25y (baseline), CA 30y, 3y-rate proxy (−20 bp vs 5y), and OSFI-style stress rate; see `mortgage_hp_ratio_sensitivities.csv`.
- Split results by **owner with mortgage / owner free-and-clear / renter**.
- Core **IG / NIG** still excludes the house-price affordability term (debt devaluation only).

**Explicitly out of scope (for now)**

- We are **not** evaluating the distribution of **renewal / short-term contract risk** to homeowners (payment shock at term renewal).
- **Pass-through** of policy and market rates into existing loan payments and renegotiation is **postponed** for later work.

## Role of SHS

The Survey of Household Spending is **not required** for core IG / IT / NIG (those need income + balance sheets from SFS). SHS is reserved for optional extensions:

- Consumption baskets / inflation incidence by income
- Mortgage payment and debt-service shares
- Cross-checks on liquid spending vs liquid assets

## Non-goals for the first pass

- Numerical replication of Wolff’s US tables
- Causal identification of Bank of Canada policy (VAR / QE)
- Full racial wealth-gap series 1999–2023
- Committing restricted microdata to GitHub

## Practical data locations (this machine)

- Cleaned panel: `../SFS/data/sfs1999_2023.rda` (also via `data/raw/sfs/` junction)
- Variable guide: `../SFS/SFS_general.R`
- SHS 2023: `../SHS/RY2023/`
- Historical SHS: `../dataSHS/`
