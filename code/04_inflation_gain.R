# code/04_inflation_gain.R — WP 31775 IG, IT, NIG by wealth class

source("code/00_setup.R")
source("code/utils/accounting.R")

port_file <- file.path(PATHS$processed, "sfs_portfolio.rds")
macro_file <- file.path(PATHS$external, "macro_annual.csv")
period_file <- file.path(PATHS$external, "period_rates.csv")

if (!file.exists(macro_file) || !file.exists(period_file)) source("code/02_macro_series.R")
if (!file.exists(port_file)) {
  source("code/01_build_sfs_panel.R")
  source("code/03_portfolio_map.R")
}

sfs <- readRDS(port_file)
macro <- readr::read_csv(macro_file, show_col_types = FALSE)
periods <- readr::read_csv(period_file, show_col_types = FALSE)

# Attach annual macro to households
sfs <- sfs %>%
  dplyr::left_join(
    macro %>% dplyr::select(year, cpi, infl_yoy, goc10, real_goc10, mort5),
    by = "year"
  ) %>%
  dplyr::mutate(
    r_nom = goc10 / 100,
    r_real = real_goc10,
    # Annual inflation rate for single-year snapshot (YoY)
    INF_ann = dplyr::coalesce(infl_yoy, 0)
  )

# ---- Snapshot NIG at each survey year (annual rate applied once) -----------
sfs <- sfs %>%
  dplyr::mutate(
    ig_stk = pv_inflation_wedge(STK, r_nom, r_real),
    ig_bus = pv_inflation_wedge(BUS, r_nom, r_real),
    ig_bnd = pv_inflation_wedge(BND, r_nom, r_real),
    ig_liq = -LIQ * INF_ann,
    ig_dbt = DBT * INF_ann,
    IG_ann = ig_stk + ig_bus + ig_bnd + ig_liq + ig_dbt,
    IT_ann = INC * INF_ann,
    NIG_ann = IG_ann - IT_ann,
    NIG_ann_pct_inc = dplyr::if_else(INC > 0, NIG_ann / INC, NA_real_)
  )

summarise_nig <- function(df, group_vars) {
  df %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) %>%
    dplyr::summarise(
      n = dplyr::n(),
      mean_nw = wtd_mean(w_wolff, weight),
      mean_inc = wtd_mean(INC, weight),
      mean_IG = wtd_mean(IG_ann, weight),
      mean_IT = wtd_mean(IT_ann, weight),
      mean_NIG = wtd_mean(NIG_ann, weight),
      # Ratio of means (stable); avoid mean of household ratios with tiny incomes
      nig_over_inc = mean_NIG / pmax(mean_inc, 1),
      mean_ig_stk = wtd_mean(ig_stk, weight),
      mean_ig_bus = wtd_mean(ig_bus, weight),
      mean_ig_bnd = wtd_mean(ig_bnd, weight),
      mean_ig_liq = wtd_mean(ig_liq, weight),
      mean_ig_dbt = wtd_mean(ig_dbt, weight),
      debt_asset = wtd_mean(DBT, weight) /
        pmax(wtd_mean(STK + BND + LIQ + BUS + HOUS + OTH_NF, weight), 1),
      .groups = "drop"
    )
}

nig_year <- summarise_nig(sfs, "year")
nig_q <- summarise_nig(sfs, c("year", "wealth_q"))
nig_detail <- summarise_nig(sfs, c("year", "wealth_detail"))

readr::write_csv(nig_year, file.path(PATHS$tables, "nig_by_year.csv"))
readr::write_csv(nig_q, file.path(PATHS$tables, "nig_by_year_wealth_quintile.csv"))
readr::write_csv(nig_detail, file.path(PATHS$tables, "nig_by_year_wealth_detail.csv"))

# ---- Between-survey-year cumulative NIG (period analysis) ------------------
# Hold portfolio fixed at year0 composition; apply cumulative INF and rate wedge
# using average rates over the period.

period_nig_rows <- list()
for (i in seq_len(nrow(periods))) {
  pr <- periods[i, ]
  y0 <- pr$year0
  y1 <- pr$year1
  base <- sfs %>% dplyr::filter(year == y0)
  if (!nrow(base)) next

  infl <- as.numeric(pr$infl_cum)
  r_n0 <- as.numeric(pr$goc10_0)
  r_r0 <- as.numeric(pr$real0)
  r_n1 <- as.numeric(pr$goc10_1)
  r_r1 <- as.numeric(pr$real1)

  # Rate-path revaluation (29392/31775 hybrid): change in real discount rate
  # plus inflation wedge on liq/debt over the full period.
  # consol_reval: ratio when both real rates > floor; else duration (avoids
  # dual-floor zeroing the equity channel, e.g. 2012–2016).
  base <- base %>%
    dplyr::mutate(
      d_stk = consol_reval(STK, r_r0, r_r1, r_floor = 0.005, duration = 20),
      d_bus = consol_reval(BUS, r_r0, r_r1, r_floor = 0.005, duration = 20),
      # Bonds: modified duration ~ 8 years
      d_bnd = duration_reval(BND, r_n1 - r_n0, pmax(r_n0, 0.01), duration = 8),
      d_liq = -LIQ * infl,
      d_dbt = DBT * infl,
      IG_per = d_stk + d_bus + d_bnd + d_liq + d_dbt,
      IT_per = INC * infl,
      NIG_per = IG_per - IT_per,
      period = paste0(y0, "-", y1)
    )

  period_nig_rows[[length(period_nig_rows) + 1]] <- base %>%
    dplyr::group_by(period, wealth_q) %>%
    dplyr::summarise(
      year0 = y0, year1 = y1,
      n = dplyr::n(),
      infl_cum = infl,
      mean_IG = wtd_mean(IG_per, weight),
      mean_IT = wtd_mean(IT_per, weight),
      mean_NIG = wtd_mean(NIG_per, weight),
      mean_inc = wtd_mean(INC, weight),
      nig_over_inc = mean_NIG / pmax(mean_inc, 1),
      mean_d_stk = wtd_mean(d_stk, weight),
      mean_d_bus = wtd_mean(d_bus, weight),
      mean_d_bnd = wtd_mean(d_bnd, weight),
      mean_d_liq = wtd_mean(d_liq, weight),
      mean_d_dbt = wtd_mean(d_dbt, weight),
      mean_nw0 = wtd_mean(w_wolff, weight),
      .groups = "drop"
    )
}

nig_periods <- dplyr::bind_rows(period_nig_rows)
readr::write_csv(nig_periods, file.path(PATHS$tables, "nig_by_period_wealth_quintile.csv"))

# ---- Full-span period NIG (first → last SFS wave, e.g. 1999–2023) ----------
# Same Wolff period accounting as inter-wave spells: portfolios fixed at year0;
# cumulative CPI inflation and endpoint rate wedge over the whole sample.
y0_full <- min(SURVEY_YEARS)
y1_full <- max(SURVEY_YEARS)
base_full <- sfs %>% dplyr::filter(year == y0_full)
m0 <- macro %>% dplyr::filter(year == y0_full)
m1 <- macro %>% dplyr::filter(year == y1_full)
if (nrow(base_full) && nrow(m0) && nrow(m1)) {
  infl_full <- as.numeric(m1$cpi[1] / m0$cpi[1] - 1)
  r_n0_f <- as.numeric(m0$goc10[1] / 100)
  r_r0_f <- as.numeric(m0$real_goc10[1])
  r_n1_f <- as.numeric(m1$goc10[1] / 100)
  r_r1_f <- as.numeric(m1$real_goc10[1])

  nig_full <- base_full %>%
    dplyr::mutate(
      d_stk = consol_reval(STK, r_r0_f, r_r1_f, r_floor = 0.005, duration = 20),
      d_bus = consol_reval(BUS, r_r0_f, r_r1_f, r_floor = 0.005, duration = 20),
      d_bnd = duration_reval(BND, r_n1_f - r_n0_f, pmax(r_n0_f, 0.01), duration = 8),
      d_liq = -LIQ * infl_full,
      d_dbt = DBT * infl_full,
      IG_per = d_stk + d_bus + d_bnd + d_liq + d_dbt,
      IT_per = INC * infl_full,
      NIG_per = IG_per - IT_per,
      period = paste0(y0_full, "-", y1_full)
    ) %>%
    dplyr::group_by(period, wealth_q) %>%
    dplyr::summarise(
      year0 = y0_full, year1 = y1_full,
      n = dplyr::n(),
      infl_cum = infl_full,
      mean_IG = wtd_mean(IG_per, weight),
      mean_IT = wtd_mean(IT_per, weight),
      mean_NIG = wtd_mean(NIG_per, weight),
      mean_inc = wtd_mean(INC, weight),
      nig_over_inc = mean_NIG / pmax(mean_inc, 1),
      mean_d_stk = wtd_mean(d_stk, weight),
      mean_d_bus = wtd_mean(d_bus, weight),
      mean_d_bnd = wtd_mean(d_bnd, weight),
      mean_d_liq = wtd_mean(d_liq, weight),
      mean_d_dbt = wtd_mean(d_dbt, weight),
      mean_nw0 = wtd_mean(w_wolff, weight),
      .groups = "drop"
    )

  readr::write_csv(
    nig_full,
    file.path(PATHS$tables, "nig_by_quintile_1999_2023.csv")
  )
} else {
  nig_full <- NULL
  warning("Could not build full-span NIG (", y0_full, "-", y1_full, ").")
}

# ---- Inflation sensitivity (counterfactual constant annual INF) ------------
# Use latest survey year portfolio; hold real income fixed; set r_real = r_nom - INF
sens_year <- max(sfs$year, na.rm = TRUE)
sens_base <- sfs %>% dplyr::filter(year == sens_year)
r_nom_s <- median(sens_base$r_nom, na.rm = TRUE)

sens_rates <- c(0.02, 0.04, 0.06, 0.08, 0.10)
sens_rows <- lapply(sens_rates, function(inf) {
  r_real_s <- r_nom_s - inf
  sens_base %>%
    dplyr::mutate(
      ig_stk = pv_inflation_wedge(STK, r_nom_s, r_real_s),
      ig_bus = pv_inflation_wedge(BUS, r_nom_s, r_real_s),
      ig_bnd = pv_inflation_wedge(BND, r_nom_s, r_real_s),
      ig_liq = -LIQ * inf,
      ig_dbt = DBT * inf,
      IG = ig_stk + ig_bus + ig_bnd + ig_liq + ig_dbt,
      IT = INC * inf,
      NIG = IG - IT,
      INF_cf = inf
    ) %>%
    dplyr::group_by(INF_cf, wealth_q) %>%
    dplyr::summarise(
      year = sens_year,
      mean_IG = wtd_mean(IG, weight),
      mean_IT = wtd_mean(IT, weight),
      mean_NIG = wtd_mean(NIG, weight),
      mean_inc = wtd_mean(INC, weight),
      nig_over_inc = mean_NIG / pmax(mean_inc, 1),
      .groups = "drop"
    )
})
nig_sens <- dplyr::bind_rows(sens_rows)
readr::write_csv(nig_sens, file.path(PATHS$tables, "nig_inflation_sensitivity.csv"))

saveRDS(sfs, file.path(PATHS$processed, "sfs_with_nig.rds"))
message("Wrote NIG tables to output/tables/")
