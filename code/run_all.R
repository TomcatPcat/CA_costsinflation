# code/run_all.R — full pipeline from repo root
# Usage: Rscript code/run_all.R

args_ok <- TRUE
setwd_to_root <- function() {
  # If launched via Rscript path, setwd to repo root (parent of code/)
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", cmd_args, value = TRUE)
  if (length(file_arg)) {
    script <- normalizePath(sub("^--file=", "", file_arg))
    root <- dirname(dirname(script))
    setwd(root)
  }
}
setwd_to_root()

message("=== CA_costsinflation pipeline ===")
message("Working directory: ", getwd())

source("code/00_setup.R")
source("code/11_macro_context_figure.R")
source("code/02_macro_series.R")
source("code/01_build_sfs_panel.R")
source("code/03_portfolio_map.R")
source("code/04_inflation_gain.R")
source("code/05_inequality_effects.R")
source("code/06_tables_figures.R")
source("code/12_reval_by_quintile.R")
source("code/13_annualized_nig.R")
source("code/14_nig_alt_scalings.R")
source("code/07_mortgage_affordability.R")
source("code/08_demo_geo_breakdowns.R")

# Optional SHS consumption-incidence appendix (Tier A: 2017/2019/2023).
# Skips gracefully when local SHS PUMF paths are unavailable.
run_shs <- TRUE
if (isTRUE(run_shs)) {
  shs_paths <- find_shs_paths()
  shs_available <- isTRUE(dir.exists(shs_paths$ry2023)) || isTRUE(dir.exists(shs_paths$data_edm))
  if (!shs_available) {
    message("=== Skipping SHS steps (no ../SHS/RY2023 or ../dataSHS/3508_SHS_EDM) ===")
  } else {
    message("=== SHS consumption incidence (optional) ===")
    tryCatch(
      {
        source("code/09_shs_load.R")
        source("code/10_shs_consumption_incidence.R")
      },
      error = function(e) {
        message("SHS steps failed (continuing): ", conditionMessage(e))
      }
    )
  }
}

message("=== Done. See output/tables and output/figures ===")
