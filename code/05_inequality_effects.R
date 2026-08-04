# code/05_inequality_effects.R — WP 29392-style revaluation → mean/median/Gini
# Interest-rate section deliverables (T-IR1–T-IR3): contribution shares,
# actual vs revalued growth (% of advance), Gini channel shut-offs, Wolff-30y
# columns, and age-band period incidence. Cumulative 1999–2023 = sum of period $.

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

# Age bands (aligned with 08_demo_geo_breakdowns.R)
age_scheme <- sfs %>%
  dplyr::group_by(year) %>%
  dplyr::summarise(
    agegrp_max = suppressWarnings(max(as.integer(agegrp), na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  dplyr::mutate(
    agegrp_scheme = dplyr::if_else(is.finite(agegrp_max) & agegrp_max <= 7, "g7", "g14")
  )

sfs <- sfs %>%
  dplyr::left_join(age_scheme, by = "year") %>%
  dplyr::mutate(
    g = suppressWarnings(as.integer(agegrp)),
    age_band = dplyr::case_when(
      is.finite(age) & age < 35 ~ "<35",
      is.finite(age) & age < 45 ~ "35-44",
      is.finite(age) & age < 55 ~ "45-54",
      is.finite(age) & age < 65 ~ "55-64",
      is.finite(age) ~ "65+",
      agegrp_scheme == "g7" & g %in% 1:2 ~ "<35",
      agegrp_scheme == "g7" & g == 3 ~ "35-44",
      agegrp_scheme == "g7" & g == 4 ~ "45-54",
      agegrp_scheme == "g7" & g == 5 ~ "55-64",
      agegrp_scheme == "g7" & g %in% 6:7 ~ "65+",
      agegrp_scheme == "g14" & g %in% 1:4 ~ "<35",
      agegrp_scheme == "g14" & g %in% 5:6 ~ "35-44",
      agegrp_scheme == "g14" & g %in% 7:8 ~ "45-54",
      agegrp_scheme == "g14" & g %in% 9:10 ~ "55-64",
      agegrp_scheme == "g14" & g %in% 11:14 ~ "65+",
      TRUE ~ NA_character_
    ),
    age_band = factor(age_band, levels = c("<35", "35-44", "45-54", "55-64", "65+"))
  )

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
shutoff_rows <- list()
age_rows <- list()

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
  # Housing affordability: baseline Canada 25y amort; also store Wolff 30y amort
  hp_ratio <- tryCatch(house_price_ratio(m0, m1, 0.80, 25), error = function(e) 1)
  hp_ratio_wolff <- tryCatch(house_price_ratio(m0, m1, 0.80, 30), error = function(e) 1)

  base <- base %>%
    dplyr::mutate(
      d_stk = consol_reval(STK, r_r0, r_r1, r_floor = 0.005, duration = 20),
      d_bus = consol_reval(BUS, r_r0, r_r1, r_floor = 0.005, duration = 20),
      d_bnd = duration_reval(BND, r_n1 - r_n0, pmax(r_n0, 0.01), 8),
      d_liq = -LIQ * infl,
      d_dbt = DBT * infl,
      # Housing affordability channel (interest-rate, not IG); owners only
      d_hous = dplyr::if_else(
        housing_status %in% c("owner_mortgage", "owner_free_clear"),
        HOUS * (hp_ratio - 1),
        0
      ),
      d_hous_wolff = dplyr::if_else(
        housing_status %in% c("owner_mortgage", "owner_free_clear"),
        HOUS * (hp_ratio_wolff - 1),
        0
      ),
      d_eq_bus = d_stk + d_bus,
      d_debt_liq = d_liq + d_dbt,
      d_total_no_hous = d_stk + d_bus + d_bnd + d_liq + d_dbt,
      d_total = d_total_no_hous + d_hous,
      d_total_wolff = d_total_no_hous + d_hous_wolff,
      nw_reval = w_wolff + d_total_no_hous,
      nw_reval_hous = w_wolff + d_total,
      nw_reval_wolff = w_wolff + d_total_wolff,
      nw_eq_bus = w_wolff + d_eq_bus,
      nw_hous_only = w_wolff + d_hous,
      nw_debt_liq = w_wolff + d_debt_liq,
      period = paste0(y0, "-", y1)
    )

  mean0 <- wtd_mean(base$w_wolff, base$weight)
  med0 <- wtd_quantile(base$w_wolff, base$weight, 0.5)
  g0 <- wtd_gini(base$w_wolff, base$weight)

  mean_nh <- wtd_mean(base$nw_reval, base$weight)
  med_nh <- wtd_quantile(base$nw_reval, base$weight, 0.5)
  g_nh <- wtd_gini(base$nw_reval, base$weight)

  mean_h <- wtd_mean(base$nw_reval_hous, base$weight)
  med_h <- wtd_quantile(base$nw_reval_hous, base$weight, 0.5)
  g_h <- wtd_gini(base$nw_reval_hous, base$weight)

  mean_w <- wtd_mean(base$nw_reval_wolff, base$weight)
  med_w <- wtd_quantile(base$nw_reval_wolff, base$weight, 0.5)
  g_w <- wtd_gini(base$nw_reval_wolff, base$weight)

  g_eq <- wtd_gini(base$nw_eq_bus, base$weight)
  g_ho <- wtd_gini(base$nw_hous_only, base$weight)
  g_dl <- wtd_gini(base$nw_debt_liq, base$weight)

  # Actual end-of-period wealth from observed SFS wave
  act1 <- ineq_base %>% dplyr::filter(year == y1)
  mean1 <- if (nrow(act1)) act1$mean_nw[[1]] else NA_real_
  med1 <- if (nrow(act1)) act1$median_nw[[1]] else NA_real_
  gini1 <- if (nrow(act1)) act1$gini[[1]] else NA_real_

  reval_rows[[length(reval_rows) + 1]] <- tibble::tibble(
    period = paste0(y0, "-", y1),
    year0 = y0, year1 = y1,
    infl_cum = infl,
    hp_ratio = hp_ratio,
    hp_ratio_wolff_30y = hp_ratio_wolff,
    mean_nw0 = mean0,
    median_nw0 = med0,
    gini0 = g0,
    mean_nw1_actual = mean1,
    median_nw1_actual = med1,
    gini1_actual = gini1,
    mean_nw_reval = mean_nh,
    median_nw_reval = med_nh,
    gini_reval = g_nh,
    mean_nw_reval_hous = mean_h,
    median_nw_reval_hous = med_h,
    gini_reval_hous = g_h,
    mean_nw_reval_wolff = mean_w,
    median_nw_reval_wolff = med_w,
    gini_reval_wolff = g_w,
    d_mean = mean_nh - mean0,
    d_median = med_nh - med0,
    d_gini = g_nh - g0,
    d_mean_hous = mean_h - mean0,
    d_median_hous = med_h - med0,
    d_gini_hous = g_h - g0,
    d_mean_wolff = mean_w - mean0,
    d_median_wolff = med_w - med0,
    d_gini_wolff = g_w - g0
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
    mean_d_hous_wolff = wtd_mean(base$d_hous_wolff, base$weight),
    mean_d_total_no_hous = wtd_mean(base$d_total_no_hous, base$weight),
    mean_d_total = wtd_mean(base$d_total, base$weight),
    mean_d_total_wolff = wtd_mean(base$d_total_wolff, base$weight)
  )

  shutoff_rows[[length(shutoff_rows) + 1]] <- tibble::tibble(
    period = paste0(y0, "-", y1),
    year0 = y0, year1 = y1,
    gini0 = g0,
    gini_no_hous = g_nh,
    gini_ca25y = g_h,
    gini_wolff30y = g_w,
    gini_eq_bus = g_eq,
    gini_hous_only = g_ho,
    gini_debt_liq = g_dl,
    d_gini_no_hous = g_nh - g0,
    d_gini_ca25y = g_h - g0,
    d_gini_wolff30y = g_w - g0,
    d_gini_eq_bus = g_eq - g0,
    d_gini_hous_only = g_ho - g0,
    d_gini_debt_liq = g_dl - g0
  )

  age_rows[[length(age_rows) + 1]] <- base %>%
    dplyr::filter(!is.na(age_band)) %>%
    dplyr::group_by(period, age_band) %>%
    dplyr::summarise(
      year0 = y0,
      year1 = y1,
      n = dplyr::n(),
      mean_nw0 = wtd_mean(w_wolff, weight),
      median_nw0 = wtd_quantile(w_wolff, weight, 0.5),
      mean_d_stk = wtd_mean(d_stk, weight),
      mean_d_bus = wtd_mean(d_bus, weight),
      mean_d_bnd = wtd_mean(d_bnd, weight),
      mean_d_liq = wtd_mean(d_liq, weight),
      mean_d_dbt = wtd_mean(d_dbt, weight),
      mean_d_hous = wtd_mean(d_hous, weight),
      mean_d_total_no_hous = wtd_mean(d_total_no_hous, weight),
      mean_d_total = wtd_mean(d_total, weight),
      .groups = "drop"
    )
}

reval_tbl <- dplyr::bind_rows(reval_rows)
contrib_tbl <- dplyr::bind_rows(contrib_rows)
shutoff_tbl <- dplyr::bind_rows(shutoff_rows)
age_tbl_period <- dplyr::bind_rows(age_rows)

readr::write_csv(reval_tbl, file.path(PATHS$tables, "inequality_revaluation_by_period.csv"))
readr::write_csv(contrib_tbl, file.path(PATHS$tables, "revaluation_contributions_by_period.csv"))
readr::write_csv(shutoff_tbl, file.path(PATHS$tables, "revaluation_gini_shutoffs_by_period.csv"))
readr::write_csv(age_tbl_period, file.path(PATHS$tables, "revaluation_by_age_period.csv"))

# ---------------------------------------------------------------------------
# T-IR2: Contribution shares (channel $ / mean ΔNW); cumulative = sum of period $
# ---------------------------------------------------------------------------
# Shares undefined when |mean ΔNW| is tiny relative to channels (e.g. 2019–2023
# with housing ≈ wipeout). Require |denom| ≥ $5k.
SHARE_DENOM_FLOOR <- 5000

share_one <- function(df, denom_col, channels, housing_toggle) {
  denom <- df[[denom_col]]
  out <- df %>%
    dplyr::select(period, year0, year1, dplyr::all_of(channels)) %>%
    dplyr::mutate(
      housing_toggle = housing_toggle,
      denom_mean_dnw = denom,
      share_unstable = abs(denom) < SHARE_DENOM_FLOOR,
      dplyr::across(
        dplyr::all_of(channels),
        ~ dplyr::if_else(abs(denom) >= SHARE_DENOM_FLOOR, .x / denom, NA_real_),
        .names = "share_{.col}"
      )
    )
  # Rename share_mean_d_stk → share_stk etc.
  for (ch in channels) {
    old <- paste0("share_", ch)
    new <- sub("^share_mean_d_", "share_", old)
    if (old %in% names(out) && old != new) {
      names(out)[names(out) == old] <- new
    }
  }
  out
}

chan_no_hous <- c("mean_d_stk", "mean_d_bus", "mean_d_bnd", "mean_d_liq", "mean_d_dbt")
chan_hous <- c(chan_no_hous, "mean_d_hous")

shares_nh <- share_one(contrib_tbl, "mean_d_total_no_hous", chan_no_hous, "no_housing")
shares_h <- share_one(contrib_tbl, "mean_d_total", chan_hous, "ca25y_housing")

# Cumulative row: sum of period mean channel $ / sum of period mean ΔNW
cum_from <- function(df, denom_col, channels, housing_toggle) {
  denom_sum <- sum(df[[denom_col]], na.rm = TRUE)
  ch_sums <- vapply(channels, function(ch) sum(df[[ch]], na.rm = TRUE), numeric(1))
  row <- tibble::tibble(
    period = "1999-2023 (sum)",
    year0 = 1999L,
    year1 = 2023L,
    housing_toggle = housing_toggle,
    denom_mean_dnw = denom_sum,
    share_unstable = abs(denom_sum) < SHARE_DENOM_FLOOR
  )
  for (ch in channels) {
    row[[ch]] <- ch_sums[[ch]]
    row[[sub("^mean_d_", "share_", ch)]] <- if (abs(denom_sum) >= SHARE_DENOM_FLOOR) {
      ch_sums[[ch]] / denom_sum
    } else {
      NA_real_
    }
  }
  row
}

cum_nh <- cum_from(contrib_tbl, "mean_d_total_no_hous", chan_no_hous, "no_housing")
cum_h <- cum_from(contrib_tbl, "mean_d_total", chan_hous, "ca25y_housing")

shares_tbl <- dplyr::bind_rows(shares_nh, cum_nh, shares_h, cum_h) %>%
  dplyr::arrange(housing_toggle, year0)
readr::write_csv(
  shares_tbl,
  file.path(PATHS$tables, "revaluation_contribution_shares_by_period.csv")
)

# ---------------------------------------------------------------------------
# Actual vs revalued growth (% of actual advance explained)
# ---------------------------------------------------------------------------
growth_tbl <- reval_tbl %>%
  dplyr::mutate(
    actual_d_mean = mean_nw1_actual - mean_nw0,
    actual_d_median = median_nw1_actual - median_nw0,
    actual_mean_growth = actual_d_mean / pmax(abs(mean_nw0), 1),
    actual_median_growth = actual_d_median / pmax(abs(median_nw0), 1),
    reval_mean_growth_no_hous = d_mean / pmax(abs(mean_nw0), 1),
    reval_median_growth_no_hous = d_median / pmax(abs(median_nw0), 1),
    reval_mean_growth_hous = d_mean_hous / pmax(abs(mean_nw0), 1),
    reval_median_growth_hous = d_median_hous / pmax(abs(median_nw0), 1),
    reval_mean_growth_wolff = d_mean_wolff / pmax(abs(mean_nw0), 1),
    reval_median_growth_wolff = d_median_wolff / pmax(abs(median_nw0), 1),
    # Wolff-style share of actual advance; flag when actual Δ small/negative
    pct_advance_mean_no_hous = dplyr::if_else(
      abs(actual_d_mean) > 1000, d_mean / actual_d_mean, NA_real_
    ),
    pct_advance_median_no_hous = dplyr::if_else(
      abs(actual_d_median) > 1000, d_median / actual_d_median, NA_real_
    ),
    pct_advance_mean_hous = dplyr::if_else(
      abs(actual_d_mean) > 1000, d_mean_hous / actual_d_mean, NA_real_
    ),
    pct_advance_median_hous = dplyr::if_else(
      abs(actual_d_median) > 1000, d_median_hous / actual_d_median, NA_real_
    ),
    pct_advance_mean_wolff = dplyr::if_else(
      abs(actual_d_mean) > 1000, d_mean_wolff / actual_d_mean, NA_real_
    ),
    flag_small_actual_mean = abs(actual_d_mean) <= 1000 | actual_d_mean < 0,
    flag_small_actual_median = abs(actual_d_median) <= 1000 | actual_d_median < 0
  ) %>%
  dplyr::select(
    period, year0, year1,
    mean_nw0, median_nw0, mean_nw1_actual, median_nw1_actual,
    actual_d_mean, actual_d_median,
    actual_mean_growth, actual_median_growth,
    d_mean, d_median, d_mean_hous, d_median_hous, d_mean_wolff, d_median_wolff,
    reval_mean_growth_no_hous, reval_median_growth_no_hous,
    reval_mean_growth_hous, reval_median_growth_hous,
    reval_mean_growth_wolff, reval_median_growth_wolff,
    pct_advance_mean_no_hous, pct_advance_median_no_hous,
    pct_advance_mean_hous, pct_advance_median_hous,
    pct_advance_mean_wolff,
    flag_small_actual_mean, flag_small_actual_median
  )

# Cumulative % of advance: sum reval Δ / sum actual Δ
cum_act_mean <- sum(growth_tbl$actual_d_mean, na.rm = TRUE)
cum_act_med <- sum(growth_tbl$actual_d_median, na.rm = TRUE)
cum_growth <- tibble::tibble(
  period = "1999-2023 (sum)",
  year0 = 1999L,
  year1 = 2023L,
  mean_nw0 = growth_tbl$mean_nw0[growth_tbl$year0 == 1999][1],
  median_nw0 = growth_tbl$median_nw0[growth_tbl$year0 == 1999][1],
  mean_nw1_actual = growth_tbl$mean_nw1_actual[growth_tbl$year1 == 2023][1],
  median_nw1_actual = growth_tbl$median_nw1_actual[growth_tbl$year1 == 2023][1],
  actual_d_mean = cum_act_mean,
  actual_d_median = cum_act_med,
  actual_mean_growth = NA_real_,
  actual_median_growth = NA_real_,
  d_mean = sum(growth_tbl$d_mean, na.rm = TRUE),
  d_median = sum(growth_tbl$d_median, na.rm = TRUE),
  d_mean_hous = sum(growth_tbl$d_mean_hous, na.rm = TRUE),
  d_median_hous = sum(growth_tbl$d_median_hous, na.rm = TRUE),
  d_mean_wolff = sum(growth_tbl$d_mean_wolff, na.rm = TRUE),
  d_median_wolff = sum(growth_tbl$d_median_wolff, na.rm = TRUE),
  reval_mean_growth_no_hous = NA_real_,
  reval_median_growth_no_hous = NA_real_,
  reval_mean_growth_hous = NA_real_,
  reval_median_growth_hous = NA_real_,
  reval_mean_growth_wolff = NA_real_,
  reval_median_growth_wolff = NA_real_,
  pct_advance_mean_no_hous = if (abs(cum_act_mean) > 1000) {
    sum(growth_tbl$d_mean, na.rm = TRUE) / cum_act_mean
  } else {
    NA_real_
  },
  pct_advance_median_no_hous = if (abs(cum_act_med) > 1000) {
    sum(growth_tbl$d_median, na.rm = TRUE) / cum_act_med
  } else {
    NA_real_
  },
  pct_advance_mean_hous = if (abs(cum_act_mean) > 1000) {
    sum(growth_tbl$d_mean_hous, na.rm = TRUE) / cum_act_mean
  } else {
    NA_real_
  },
  pct_advance_median_hous = if (abs(cum_act_med) > 1000) {
    sum(growth_tbl$d_median_hous, na.rm = TRUE) / cum_act_med
  } else {
    NA_real_
  },
  pct_advance_mean_wolff = if (abs(cum_act_mean) > 1000) {
    sum(growth_tbl$d_mean_wolff, na.rm = TRUE) / cum_act_mean
  } else {
    NA_real_
  },
  flag_small_actual_mean = FALSE,
  flag_small_actual_median = FALSE
)

growth_out <- dplyr::bind_rows(growth_tbl, cum_growth)
readr::write_csv(
  growth_out,
  file.path(PATHS$tables, "revaluation_vs_actual_growth_by_period.csv")
)

# Age-group cut for latest year (substitute for race) — stock snapshot
latest <- max(sfs$year)
age_stock <- sfs %>%
  dplyr::filter(year == latest, !is.na(age_band)) %>%
  dplyr::group_by(year, age_band) %>%
  dplyr::summarise(
    n = dplyr::n(),
    mean_nw = wtd_mean(w_wolff, weight),
    median_nw = wtd_quantile(w_wolff, weight, 0.5),
    mean_debt_asset = wtd_mean(DBT, weight) /
      pmax(wtd_mean(STK + BND + LIQ + BUS + HOUS + OTH_NF, weight), 1),
    .groups = "drop"
  )
readr::write_csv(age_stock, file.path(PATHS$tables, "wealth_by_age_latest.csv"))

message("Wrote inequality / revaluation tables to output/tables/")
message(
  "  + shares, vs-actual growth, Gini shut-offs, age-period incidence"
)
