# code/05_inequality_effects.R — WP 29392-style revaluation → mean/median/Gini

source("code/00_setup.R")
source("code/utils/accounting.R")

port_file <- file.path(PATHS$processed, "sfs_portfolio.rds")
period_file <- file.path(PATHS$external, "period_rates.csv")
if (!file.exists(period_file)) source("code/02_macro_series.R")
if (!file.exists(port_file)) {
  source("code/01_build_sfs_panel.R")
  source("code/03_portfolio_map.R")
}

sfs <- readRDS(port_file)
periods <- readr::read_csv(period_file, show_col_types = FALSE)

# Baseline inequality by year
ineq_base <- sfs %>%
  dplyr::group_by(year) %>%
  dplyr::summarise(
    n = dplyr::n(),
    mean_nw = wtd_mean(w_wolff, weight),
    median_nw = wtd_quantile(w_wolff, weight, 0.5),
    gini = wtd_gini(w_wolff, weight),
    p90 = wtd_quantile(w_wolff, weight, 0.9),
    p99 = wtd_quantile(w_wolff, weight, 0.99),
    p99_med = p99 / pmax(median_nw, 1),
    .groups = "drop"
  )
readr::write_csv(ineq_base, file.path(PATHS$tables, "inequality_baseline_by_year.csv"))

# Counterfactual: apply only rate/inflation revaluation to year0 portfolios
reval_rows <- list()
contrib_rows <- list()

for (i in seq_len(nrow(periods))) {
  pr <- periods[i, ]
  y0 <- pr$year0
  y1 <- pr$year1
  base <- sfs %>% dplyr::filter(year == y0)
  if (!nrow(base)) next

  infl <- as.numeric(pr$infl_cum)
  r_n0 <- as.numeric(pr$goc10_0)
  r_n1 <- as.numeric(pr$goc10_1)
  r_r0 <- as.numeric(pr$real0)
  r_r1 <- as.numeric(pr$real1)
  m0 <- as.numeric(pr$mort0)
  m1 <- as.numeric(pr$mort1)
  hp_ratio <- tryCatch(house_price_ratio(m0, m1), error = function(e) 1)

  use_consol <- is.finite(r_r0) && is.finite(r_r1)
  r0e <- max(r_r0, 0.005)
  r1e <- max(r_r1, 0.005)
  base <- base %>%
    dplyr::mutate(
      d_stk = if (use_consol) STK * (r0e / r1e - 1) else duration_reval(STK, r_r1 - r_r0, pmax(r_r0, 0.01), 20),
      d_bus = if (use_consol) BUS * (r0e / r1e - 1) else duration_reval(BUS, r_r1 - r_r0, pmax(r_r0, 0.01), 20),
      d_bnd = duration_reval(BND, r_n1 - r_n0, pmax(r_n0, 0.01), 8),
      d_liq = -LIQ * infl,
      d_dbt = DBT * infl,
      # Housing affordability channel (interest-rate, not IG)
      d_hous = HOUS * (hp_ratio - 1),
      d_total_no_hous = d_stk + d_bus + d_bnd + d_liq + d_dbt,
      d_total = d_total_no_hous + d_hous,
      nw_reval = w_wolff + d_total_no_hous,
      nw_reval_hous = w_wolff + d_total,
      period = paste0(y0, "-", y1)
    )

  reval_rows[[length(reval_rows) + 1]] <- tibble::tibble(
    period = paste0(y0, "-", y1),
    year0 = y0, year1 = y1,
    infl_cum = infl,
    hp_ratio = hp_ratio,
    mean_nw0 = wtd_mean(base$w_wolff, base$weight),
    median_nw0 = wtd_quantile(base$w_wolff, base$weight, 0.5),
    gini0 = wtd_gini(base$w_wolff, base$weight),
    mean_nw_reval = wtd_mean(base$nw_reval, base$weight),
    median_nw_reval = wtd_quantile(base$nw_reval, base$weight, 0.5),
    gini_reval = wtd_gini(base$nw_reval, base$weight),
    mean_nw_reval_hous = wtd_mean(base$nw_reval_hous, base$weight),
    median_nw_reval_hous = wtd_quantile(base$nw_reval_hous, base$weight, 0.5),
    gini_reval_hous = wtd_gini(base$nw_reval_hous, base$weight),
    d_mean = wtd_mean(base$nw_reval, base$weight) - wtd_mean(base$w_wolff, base$weight),
    d_gini = wtd_gini(base$nw_reval, base$weight) - wtd_gini(base$w_wolff, base$weight)
  )

  contrib_rows[[length(contrib_rows) + 1]] <- tibble::tibble(
    period = paste0(y0, "-", y1),
    year0 = y0, year1 = y1,
    mean_d_stk = wtd_mean(base$d_stk, base$weight),
    mean_d_bus = wtd_mean(base$d_bus, base$weight),
    mean_d_bnd = wtd_mean(base$d_bnd, base$weight),
    mean_d_liq = wtd_mean(base$d_liq, base$weight),
    mean_d_dbt = wtd_mean(base$d_dbt, base$weight),
    mean_d_hous = wtd_mean(base$d_hous, base$weight),
    mean_d_total_no_hous = wtd_mean(base$d_total_no_hous, base$weight),
    mean_d_total = wtd_mean(base$d_total, base$weight)
  )
}

reval_tbl <- dplyr::bind_rows(reval_rows)
contrib_tbl <- dplyr::bind_rows(contrib_rows)

readr::write_csv(reval_tbl, file.path(PATHS$tables, "inequality_revaluation_by_period.csv"))
readr::write_csv(contrib_tbl, file.path(PATHS$tables, "revaluation_contributions_by_period.csv"))

# Age-group cut for latest year (substitute for race)
if ("age" %in% names(sfs) || "agegrp" %in% names(sfs)) {
  latest <- max(sfs$year)
  age_df <- sfs %>% dplyr::filter(year == latest)
  if ("age" %in% names(age_df) && any(is.finite(age_df$age))) {
    age_df <- age_df %>%
      dplyr::mutate(age_band = dplyr::case_when(
        age < 35 ~ "<35",
        age < 45 ~ "35-44",
        age < 55 ~ "45-54",
        age < 65 ~ "55-64",
        TRUE ~ "65+"
      ))
  } else {
    age_df <- age_df %>% dplyr::mutate(age_band = as.character(agegrp))
  }
  age_tbl <- age_df %>%
    dplyr::group_by(year, age_band) %>%
    dplyr::summarise(
      n = dplyr::n(),
      mean_nw = wtd_mean(w_wolff, weight),
      median_nw = wtd_quantile(w_wolff, weight, 0.5),
      mean_debt_asset = wtd_mean(DBT, weight) /
        pmax(wtd_mean(STK + BND + LIQ + BUS + HOUS + OTH_NF, weight), 1),
      .groups = "drop"
    )
  readr::write_csv(age_tbl, file.path(PATHS$tables, "wealth_by_age_latest.csv"))
}

message("Wrote inequality / revaluation tables to output/tables/")
