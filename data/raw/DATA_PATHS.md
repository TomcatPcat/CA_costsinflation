# Local data paths (microdata is not in git)

## SFS (Survey of Financial Security)

Scripts look for the cleaned multi-year panel in this order:

1. `data/raw/sfs/sfs1999_2023.rda` (junction to `../SFS/data` when created locally)
2. `../SFS/data/sfs1999_2023.rda`
3. Environment variable `SFS_PANEL_PATH`

Optional SHS paths (not required for core NIG):

- `../SHS/RY2023/`
- `../dataSHS/`

## External macro series

Small CSVs under `data/external/` are committed. Rebuild with `code/02_macro_series.R`.
