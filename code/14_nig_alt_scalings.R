# code/14_nig_alt_scalings.R — NIG scaled by resources and cash-on-hand
#
# Motivation (see docs/12_nig_alt_scalings.md):
#   - NIG/NW is unstable for Q1 (near-zero / negative Wolff NW).
#   - NIG/income exaggerates Q5 (high NW/income; equity revaluation ÷ flow).
#
# Alternative denominators (ratio of weighted means):
#   Resources     = INC + NW,  NW = w_wolff (Wolff-style marketable net worth)
#   Cash-on-hand  = INC + LIQ  (Kaplan–Violante–Weidner style; LIQ = project LIQ)
#
# Edge cases: do not floor tiny positive denominators. Report NA when group-mean
# denominator ≤ 0; flag weighted share with household denom ≤ 0 by quintile.

source("code/00_setup.R")
source("code/utils/accounting.R")

nig_rds <- file.path(PATHS$processed, "sfs_with_nig.rds")
port_file <- file.path(PATHS$processed, "sfs_portfolio.rds")
macro_file <- file.path(PATHS$external, "macro_annual.csv")
period_file <- file.path(PATHS$external, "period_rates.csv")

if (!file.exists(macro_file) || !file.exists(period_file)) source("code/02_macro_series.R")
if (!file.exists(nig_rds)) {
  message("sfs_with_nig.rds missing; sourcing code/04_inflation_gain.R …")
  source("code/04_inflation_gain.R")
}

sfs <- readRDS(nig_rds)
macro <- readr::read_csv(macro_file, show_col_types = FALSE)
periods <- readr::read_csv(period_file, show_col_types = FALSE)

# Household-level denominators
sfs <- sfs %>%
  dplyr::mutate(
    NW = w_wolff,
    resources = INC + NW,
    cash_on_hand = INC + LIQ
  )

# ---- Helpers ---------------------------------------------------------------
ratio_of_means <- function(num_mean, den_mean) {
  dplyr::if_else(
    is.finite(num_mean) & is.finite(den_mean) & den_mean > 0,
    num_mean / den_mean,
    NA_real_
  )
}

wtd_share_le0 <- function(x, w) {
  ok <- is.finite(x) & is.finite(w) & w > 0
  if (!any(ok)) return(NA_real_)
  sum(w[ok & x <= 0]) / sum(w[ok])
}

# Geometric annualization (same rule as code/13_annualized_nig.R)
annualize_ratio <- function(x, T) {
  T <- as.numeric(T)
  x <- as.numeric(x)
  if (length(T) == 1L) T <- rep(T, length(x))
  stopifnot(length(T) == length(x))
  out <- rep(NA_real_, length(x))
  ok_geo <- is.finite(x) & is.finite(T) & T > 0 & (1 + x) > 0
  ok_arith <- is.finite(x) & is.finite(T) & T > 0 & !ok_geo
  out[ok_geo] <- (1 + x[ok_geo])^(1 / T[ok_geo]) - 1
  out[ok_arith] <- x[ok_arith] / T[ok_arith]
  out
}

annualize_method <- function(x, T) {
  x <- as.numeric(x)
  T <- as.numeric(T)
  dplyr::case_when(
    !is.finite(x) | !is.finite(T) | T <= 0 ~ NA_character_,
    (1 + x) > 0 ~ "geometric",
    TRUE ~ "arithmetic_fallback"
  )
}

summarise_alt <- function(df, nig_col, group_vars, year0 = NULL, year1 = NULL, infl = NULL) {
  nig_sym <- rlang::sym(nig_col)
  out <- df %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) %>%
    dplyr::summarise(
      n = dplyr::n(),
      mean_NIG = wtd_mean(!!nig_sym, weight),
      mean_inc = wtd_mean(INC, weight),
      mean_nw = wtd_mean(NW, weight),
      mean_LIQ = wtd_mean(LIQ, weight),
      mean_resources = wtd_mean(resources, weight),
      mean_coh = wtd_mean(cash_on_hand, weight),
      # Diagnostic: NIG/NW (unstable for Q1 when mean NW ≤ 0)
      nig_over_nw = ratio_of_means(mean_NIG, mean_nw),
      nig_over_inc = ratio_of_means(mean_NIG, mean_inc),
      nig_over_resources = ratio_of_means(mean_NIG, mean_resources),
      nig_over_coh = ratio_of_means(mean_NIG, mean_coh),
      share_w_resources_le0 = wtd_share_le0(resources, weight),
      share_w_coh_le0 = wtd_share_le0(cash_on_hand, weight),
      share_w_nw_le0 = wtd_share_le0(NW, weight),
      .groups = "drop"
    )
  if (!is.null(year0)) out$year0 <- year0
  if (!is.null(year1)) out$year1 <- year1
  if (!is.null(infl)) out$infl_cum <- infl
  out
}

add_annualized_alt <- function(df) {
  df %>%
    dplyr::mutate(
      T_years = as.integer(year1 - year0),
      nig_over_resources_ann = annualize_ratio(nig_over_resources, T_years),
      nig_over_resources_ann_method = annualize_method(nig_over_resources, T_years),
      nig_over_coh_ann = annualize_ratio(nig_over_coh, T_years),
      nig_over_coh_ann_method = annualize_method(nig_over_coh, T_years),
      nig_over_inc_ann = annualize_ratio(nig_over_inc, T_years),
      mean_NIG_ann = dplyr::if_else(
        is.finite(T_years) & T_years > 0,
        mean_NIG / T_years,
        NA_real_
      )
    )
}

q_levels <- c("Q1", "Q2", "Q3", "Q4", "Q5")
q_fills <- c("#8c2d04", "#cc4c02", "#ec7014", "#fe9929", "#fec44f")

# ---- (a) Snapshot YoY by survey year ---------------------------------------
nig_year_alt <- summarise_alt(sfs, "NIG_ann", c("year", "wealth_q"))
readr::write_csv(
  nig_year_alt,
  file.path(PATHS$tables, "nig_alt_scalings_by_year_wealth_quintile.csv")
)

latest <- max(nig_year_alt$year, na.rm = TRUE)
nig_latest <- nig_year_alt %>% dplyr::filter(year == latest)
readr::write_csv(
  nig_latest,
  file.path(PATHS$tables, "nig_alt_scalings_latest_wealth_quintile.csv")
)

# ---- (b) Inter-wave periods ------------------------------------------------
period_rows <- list()
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

  base <- base %>%
    dplyr::mutate(
      d_stk = consol_reval(STK, r_r0, r_r1, r_floor = 0.005, duration = 20),
      d_bus = consol_reval(BUS, r_r0, r_r1, r_floor = 0.005, duration = 20),
      d_bnd = duration_reval(BND, r_n1 - r_n0, pmax(r_n0, 0.01), duration = 8),
      d_liq = -LIQ * infl,
      d_dbt = DBT * infl,
      IG_per = d_stk + d_bus + d_bnd + d_liq + d_dbt,
      IT_per = INC * infl,
      NIG_per = IG_per - IT_per,
      period = paste0(y0, "-", y1)
    )

  period_rows[[length(period_rows) + 1]] <- summarise_alt(
    base, "NIG_per", c("period", "wealth_q"),
    year0 = y0, year1 = y1, infl = infl
  )
}
nig_per_alt <- dplyr::bind_rows(period_rows)
readr::write_csv(
  nig_per_alt,
  file.path(PATHS$tables, "nig_alt_scalings_by_period_wealth_quintile.csv")
)

# ---- (c) Full span 1999–2023 -----------------------------------------------
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

  base_full <- base_full %>%
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
    )

  nig_full_alt <- summarise_alt(
    base_full, "NIG_per", c("period", "wealth_q"),
    year0 = y0_full, year1 = y1_full, infl = infl_full
  )
  readr::write_csv(
    nig_full_alt,
    file.path(PATHS$tables, "nig_alt_scalings_by_quintile_1999_2023.csv")
  )
} else {
  nig_full_alt <- NULL
  warning("Could not build full-span alt scalings.")
}

# ---- Annualized period / full-span -----------------------------------------
nig_per_ann <- add_annualized_alt(nig_per_alt)
readr::write_csv(
  nig_per_ann,
  file.path(PATHS$tables, "nig_alt_scalings_by_period_wealth_quintile_annualized.csv")
)

if (!is.null(nig_full_alt)) {
  nig_full_ann <- add_annualized_alt(nig_full_alt)
  readr::write_csv(
    nig_full_ann,
    file.path(PATHS$tables, "nig_alt_scalings_by_quintile_1999_2023_annualized.csv")
  )
  nig_all_ann <- dplyr::bind_rows(
    nig_per_ann %>% dplyr::mutate(span_type = "inter_wave"),
    nig_full_ann %>% dplyr::mutate(span_type = "full_span")
  )
  readr::write_csv(
    nig_all_ann,
    file.path(PATHS$tables, "nig_alt_scalings_annualized_by_quintile.csv")
  )
}

# ---- Figures ---------------------------------------------------------------
plot_bar_q <- function(df, y, title, subtitle, ylab, outfile_base, fill = "#1f4e79") {
  p <- df %>%
    dplyr::mutate(wealth_q = factor(wealth_q, levels = q_levels)) %>%
    ggplot2::ggplot(ggplot2::aes(x = wealth_q, y = .data[[y]])) +
    ggplot2::geom_col(fill = fill) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = "Wealth quintile",
      y = ylab
    ) +
    theme_paper()
  ggplot2::ggsave(
    file.path(PATHS$figures, paste0(outfile_base, ".png")),
    p, width = 7, height = 4.5, dpi = 150
  )
  ggplot2::ggsave(
    file.path(PATHS$figures, paste0(outfile_base, ".pdf")),
    p, width = 7, height = 4.5
  )
  invisible(p)
}

plot_period_facet <- function(df, y, title, subtitle, ylab, outfile_base) {
  p <- df %>%
    dplyr::mutate(
      wealth_q = factor(wealth_q, levels = q_levels),
      period = factor(period, levels = unique(period[order(year0)]))
    ) %>%
    ggplot2::ggplot(ggplot2::aes(x = wealth_q, y = .data[[y]], fill = wealth_q)) +
    ggplot2::geom_col() +
    ggplot2::facet_wrap(~period) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    ggplot2::scale_fill_manual(values = q_fills, guide = "none") +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = NULL,
      y = ylab
    ) +
    theme_paper()
  ggplot2::ggsave(
    file.path(PATHS$figures, paste0(outfile_base, ".png")),
    p, width = 9, height = 6, dpi = 150
  )
  ggplot2::ggsave(
    file.path(PATHS$figures, paste0(outfile_base, ".pdf")),
    p, width = 9, height = 6
  )
  invisible(p)
}

# Latest YoY
plot_bar_q(
  nig_latest, "nig_over_resources",
  title = paste0("NIG / resources by wealth quintile (", latest, ")"),
  subtitle = "Resources = mean income + mean Wolff NW (ratio of means)",
  ylab = "NIG / mean resources",
  outfile_base = "nig_over_resources_by_quintile_latest"
)
plot_bar_q(
  nig_latest, "nig_over_coh",
  title = paste0("NIG / cash-on-hand by wealth quintile (", latest, ")"),
  subtitle = "Cash-on-hand = mean income + mean LIQ (ratio of means)",
  ylab = "NIG / mean cash-on-hand",
  outfile_base = "nig_over_cash_on_hand_by_quintile_latest"
)

# Inter-wave periods
plot_period_facet(
  nig_per_alt, "nig_over_resources",
  title = "Period NIG / resources by wealth quintile",
  subtitle = "Resources = INC + NW; portfolios fixed at period start",
  ylab = "NIG / mean resources",
  outfile_base = "nig_over_resources_by_quintile_periods"
)
plot_period_facet(
  nig_per_alt, "nig_over_coh",
  title = "Period NIG / cash-on-hand by wealth quintile",
  subtitle = "Cash-on-hand = INC + LIQ; portfolios fixed at period start",
  ylab = "NIG / mean cash-on-hand",
  outfile_base = "nig_over_cash_on_hand_by_quintile_periods"
)

# Full span
if (!is.null(nig_full_alt)) {
  plot_bar_q(
    nig_full_alt, "nig_over_resources",
    title = paste0("NIG / resources by wealth quintile (", y0_full, "–", y1_full, ")"),
    subtitle = "Portfolios fixed at 1999; cumulative CPI and endpoint rate wedge",
    ylab = "NIG / mean resources",
    outfile_base = "nig_over_resources_by_quintile_1999_2023"
  )
  plot_bar_q(
    nig_full_alt, "nig_over_coh",
    title = paste0("NIG / cash-on-hand by wealth quintile (", y0_full, "–", y1_full, ")"),
    subtitle = "Portfolios fixed at 1999; cumulative CPI and endpoint rate wedge",
    ylab = "NIG / mean cash-on-hand",
    outfile_base = "nig_over_cash_on_hand_by_quintile_1999_2023"
  )

  # Annualized full-span
  plot_bar_q(
    nig_full_ann, "nig_over_resources_ann",
    title = paste0("Annualized NIG / resources (", y0_full, "–", y1_full, ")"),
    subtitle = "Geometric (1+x)^(1/T)−1; T = year1−year0",
    ylab = "Annualized NIG / mean resources",
    outfile_base = "nig_over_resources_by_quintile_1999_2023_annualized"
  )
  plot_bar_q(
    nig_full_ann, "nig_over_coh_ann",
    title = paste0("Annualized NIG / cash-on-hand (", y0_full, "–", y1_full, ")"),
    subtitle = "Geometric (1+x)^(1/T)−1; T = year1−year0",
    ylab = "Annualized NIG / mean cash-on-hand",
    outfile_base = "nig_over_cash_on_hand_by_quintile_1999_2023_annualized"
  )
}

# Annualized period facets
plot_period_facet(
  nig_per_ann, "nig_over_resources_ann",
  title = "Annualized period NIG / resources by wealth quintile",
  subtitle = "Geometric annualization; comparable across spell lengths",
  ylab = "Annualized NIG / mean resources",
  outfile_base = "nig_over_resources_by_quintile_periods_annualized"
)
plot_period_facet(
  nig_per_ann, "nig_over_coh_ann",
  title = "Annualized period NIG / cash-on-hand by wealth quintile",
  subtitle = "Geometric annualization; comparable across spell lengths",
  ylab = "Annualized NIG / mean cash-on-hand",
  outfile_base = "nig_over_cash_on_hand_by_quintile_periods_annualized"
)

# Preview: Q1/Q3/Q5 for latest and full span
preview_cols <- c(
  "wealth_q", "mean_NIG", "mean_inc", "mean_nw", "mean_LIQ",
  "mean_resources", "mean_coh",
  "nig_over_inc", "nig_over_nw", "nig_over_resources", "nig_over_coh",
  "share_w_nw_le0", "share_w_resources_le0", "share_w_coh_le0"
)
message("=== Preview: ", latest, " YoY (Q1/Q3/Q5) ===")
print(
  nig_latest %>%
    dplyr::filter(wealth_q %in% c("Q1", "Q3", "Q5")) %>%
    dplyr::select(dplyr::any_of(preview_cols)),
  width = 200
)
if (!is.null(nig_full_alt)) {
  message("=== Preview: ", y0_full, "-", y1_full, " (Q1/Q3/Q5) ===")
  print(
    nig_full_alt %>%
      dplyr::filter(wealth_q %in% c("Q1", "Q3", "Q5")) %>%
      dplyr::select(dplyr::any_of(preview_cols)),
    width = 200
  )
}

message("Wrote NIG alternative-scaling tables and figures.")
message("  See docs/12_nig_alt_scalings.md")
