# Local data paths (microdata is not in git)

## SFS (Survey of Financial Security)

Scripts look for the cleaned multi-year panel in this order:

1. `data/raw/sfs/sfs1999_2023.rda` (junction to `../SFS/data` when created locally)
2. `../SFS/data/sfs1999_2023.rda`
3. Environment variable `SFS_PANEL_PATH`

Optional SHS paths (not required for core NIG; used by `code/09_shs_load.R`):

Resolved by `find_shs_paths()` in this order (first existing directory wins):

| Role | Candidates |
|------|------------|
| 2023 PUMF (`ry2023`) | `SHS_RY2023_PATH` env; `../SHS/RY2023/`; `data/raw/shs/RY2023/` |
| Historical EDM (`data_edm`) | `SHS_EDM_PATH` env; `../dataSHS/3508_SHS_EDM/`; `data/raw/shs/3508_SHS_EDM/` |
| Cache (unused in v1) | `../SHS/cache/` |

Tier A years: **2017** (`2017/data/RAW.zip` diary FWF), **2019** (`2019/shs_2019.csv`), **2023** (`Data/TXT/PUMF_SHS_2023.txt`). Pre-2010 EDM waves are out of scope for the consumption appendix.

## External macro series

Small CSVs under `data/external/` are committed. Rebuild with `code/02_macro_series.R`.
