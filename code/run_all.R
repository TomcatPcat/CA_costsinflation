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
source("code/02_macro_series.R")
source("code/01_build_sfs_panel.R")
source("code/03_portfolio_map.R")
source("code/04_inflation_gain.R")
source("code/05_inequality_effects.R")
source("code/06_tables_figures.R")
source("code/07_mortgage_affordability.R")
source("code/08_demo_geo_breakdowns.R")

message("=== Done. See output/tables and output/figures ===")
