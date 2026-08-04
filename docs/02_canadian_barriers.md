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
| RRSP / TFSA / RRIF | No direct IRA/401(k) analogue | Treat as DC-like; split into STK/BND/LIQ with transparent shares |
| Mutual funds | Need equity vs bond split | Baseline 60% equity / 40% bonds (sensitivity later) |
| Business equity | Available (`pwbuseq`) | Map to BUS |
| Housing | Principal residence + other RE | Track separately; housing mortgage-rate channel in WP 29392 module, not in core IG |

## Demographics Wolff emphasizes

| Concept | SFS PUMF | Response |
|---------|----------|----------|
| Race / ethnicity | Limited; `pvmfmie` (visible minority) mostly available in recent waves, heavy missingness in early years | Optional recent-wave cut only; no full 1999–2023 racial-gap replication |
| Age | Yes (`pagemie` / `pagemieg`) | Primary substitute stratification |
| Tenure | Yes (`pftenur`) | Owners vs renters (leverage channel) |
| Province / region | Yes | Secondary cuts |

## Macro series (Canadian analogues)

| Wolff input | Canadian series | Source |
|-------------|-----------------|--------|
| CPI-U-RS | All-items CPI | StatCan 18-10-0004 / 18-10-0005 |
| 10y Treasury | GoC 10-year benchmark yield | Bank of Canada (e.g. V39055) |
| Mortgage rate | Chartered bank conventional mortgage rates (5y typical) | BoC / StatCan |
| House prices | Teranet–National Bank HPI or StatCan New Housing Price Index | External CSV |
| Equity discount rate | Real GoC 10y; TSX for optional market-return checks | BoC + market data |

### Mortgage market difference (important)

US analysis leans on **30-year fixed-rate** mortgages. Canadian mortgages are typically **short fixed terms (often 5 years)** with longer amortizations. The affordability → house-price channel must use Canadian term structure assumptions; do not copy US 30-year payment charts literally.

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
