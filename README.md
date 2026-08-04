# Quantifying the inflation tax on Canadian households

Replication-style adaptation of Edward Wolff’s NBER working papers on inflation, interest rates, and household balance sheets — using the Canadian Survey of Financial Security (SFS) instead of the US SCF.

- **WP 31775:** [Is There Really an Inflation Tax? Not For the Middle Class and the Ultra-Wealthy](https://www.nber.org/papers/w31775)
- **WP 29392:** [Inflation, Interest, and the Secular Rise in Wealth Inequality in the U.S.: Is the Fed Responsible?](https://www.nber.org/papers/w29392)

Working paper title: *Quantifying the inflation tax on Canadian households*.

## Repo layout

```
code/           R scripts (run 00 → 06)
data/raw/       Local microdata (gitignored; see DATA_PATHS.md)
data/external/  CPI, yields, and other macro CSVs (committed)
data/processed/ Analysis extracts (gitignored)
docs/           Methodology, barriers, evolving notes
output/tables/  CSV tables
output/figures/ Figures
paper/          LaTeX / Quarto draft
```

## Quick start

1. Place or junction the cleaned SFS panel so that `data/raw/sfs/sfs1999_2023.rda` exists  
   (this repo expects a junction to `../SFS/data`, or set `SFS_PANEL_PATH`).
2. Install R packages listed in `code/00_setup.R`.
3. From the repo root, run:

```r
source("code/00_setup.R")
source("code/02_macro_series.R")
source("code/01_build_sfs_panel.R")
source("code/03_portfolio_map.R")
source("code/04_inflation_gain.R")
source("code/05_inequality_effects.R")
source("code/06_tables_figures.R")
```

Or, with Rscript:

```bat
"C:\Program Files\R\R-4.5.2\bin\Rscript.exe" code/run_all.R
```

## Data policy

Household-level SFS/SHS PUMF files are **not** committed. Only scripts, documentation, small external macro series, and aggregated `output/` tables/figures belong in git.

## Documentation

- [docs/01_wolff_methodology.md](docs/01_wolff_methodology.md) — Wolff’s accounting framework; **PBO registered-mix imputation**
- [docs/02_canadian_barriers.md](docs/02_canadian_barriers.md) — SCF → SFS barriers
- [docs/paper_notes.md](docs/paper_notes.md) — findings and open issues

Registered RRSP/TFSA/RRIF look-through follows the Parliamentary Budget Officer (*The Tax-Free Savings Account*): each household’s registered equity/bond/liquid shares match its non-registered SFS mix. This likely understates equity inside registered plans (especially TFSAs) given tax-location incentives.

## Licence note

SFS PUMF use is subject to Statistics Canada’s End-use Licence. Do not redistribute microdata via this repository.
