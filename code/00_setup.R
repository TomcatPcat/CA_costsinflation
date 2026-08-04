# code/00_setup.R — project paths, packages, helpers
# Source from repo root: source("code/00_setup.R")

suppressPackageStartupMessages({
  req <- c(
    "tidyverse", "data.table", "Hmisc", "scales", "ggplot2",
    "readr", "stringr", "glue", "here"
  )
  missing <- req[!vapply(req, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    message("Installing missing packages: ", paste(missing, collapse = ", "))
    install.packages(missing, repos = "https://cloud.r-project.org")
  }
  library(tidyverse)
  library(data.table)
  library(Hmisc)
})

# ---- Project root ----------------------------------------------------------
# Prefer here::here(); fall back to getwd() if .Rproj / .git detection fails
if (requireNamespace("here", quietly = TRUE)) {
  ROOT <- tryCatch(here::here(), error = function(e) getwd())
} else {
  ROOT <- getwd()
}
# If sourced from code/, step up
if (basename(ROOT) == "code") ROOT <- dirname(ROOT)
if (!dir.exists(file.path(ROOT, "code")) && dir.exists(file.path(getwd(), "code"))) {
  ROOT <- getwd()
}

PATHS <- list(
  root      = ROOT,
  code      = file.path(ROOT, "code"),
  utils     = file.path(ROOT, "code", "utils"),
  raw       = file.path(ROOT, "data", "raw"),
  external  = file.path(ROOT, "data", "external"),
  processed = file.path(ROOT, "data", "processed"),
  tables    = file.path(ROOT, "output", "tables"),
  figures   = file.path(ROOT, "output", "figures"),
  docs      = file.path(ROOT, "docs")
)

for (p in PATHS) dir.create(p, recursive = TRUE, showWarnings = FALSE)

#' Resolve path to cleaned SFS panel (.rda or .csv)
find_sfs_panel <- function() {
  env <- Sys.getenv("SFS_PANEL_PATH", unset = "")
  candidates <- c(
    env,
    file.path(PATHS$raw, "sfs", "sfs1999_2023.rda"),
    file.path(PATHS$raw, "sfs1999_2023.rda"),
    file.path(dirname(PATHS$root), "SFS", "data", "sfs1999_2023.rda"),
    file.path(PATHS$raw, "sfs", "sfs1999_2023.csv"),
    file.path(dirname(PATHS$root), "SFS", "data", "sfs1999_2023.csv")
  )
  candidates <- candidates[nzchar(candidates)]
  hit <- candidates[file.exists(candidates)]
  if (!length(hit)) {
    stop(
      "Cannot find sfs1999_2023.rda/.csv. Set SFS_PANEL_PATH or place file under data/raw/sfs/. ",
      "See data/raw/DATA_PATHS.md"
    )
  }
  hit[[1]]
}

na2zero <- function(x) {
  x[is.na(x)] <- 0
  x
}

wtd_mean <- function(x, w) {
  ok <- is.finite(x) & is.finite(w) & w > 0
  if (!any(ok)) return(NA_real_)
  sum(x[ok] * w[ok]) / sum(w[ok])
}

wtd_quantile <- function(x, w, probs) {
  ok <- is.finite(x) & is.finite(w) & w > 0
  as.numeric(Hmisc::wtd.quantile(x[ok], weights = w[ok], probs = probs, na.rm = TRUE))
}

#' Weighted Gini (allows negative wealth via mean-normalized Brown formula)
wtd_gini <- function(x, w) {
  ok <- is.finite(x) & is.finite(w) & w > 0
  x <- x[ok]; w <- w[ok]
  if (!length(x)) return(NA_real_)
  ord <- order(x)
  x <- x[ord]; w <- w[ord]
  sw <- sum(w)
  wx <- sum(w * x)
  if (sw <= 0 || wx == 0) return(NA_real_)
  # Brown (weighted): G = 1 - 2 * sum_i w_i * (cumsum(w*x) - w*x/2) / (sw * wx)
  g <- 1 - 2 * sum(w * (cumsum(w * x) - w * x / 2)) / (sw * wx)
  as.numeric(g)
}

theme_paper <- function() {
  ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold"),
      legend.position = "bottom"
    )
}

SURVEY_YEARS <- c(1999L, 2005L, 2012L, 2016L, 2019L, 2023L)

# Mutual-fund look-through (non-registered funds and residual when needed).
# Registered-account STK/BND/LIQ shares: PBO method in code/03_portfolio_map.R
# (copy each household's non-registered mix). SHARES$reg_* are fallbacks only
# when non-registered financial assets are zero/missing.
SHARES <- list(
  mf_equity  = 0.60,
  mf_bond    = 0.40,
  reg_equity = 0.60,
  reg_bond   = 0.30,
  reg_liquid = 0.10
)

message("CA_costsinflation setup OK. ROOT = ", PATHS$root)
