# code/06_tables_figures.R — figures for NIG and inequality

source("code/00_setup.R")

nig_q <- readr::read_csv(file.path(PATHS$tables, "nig_by_year_wealth_quintile.csv"), show_col_types = FALSE)
nig_per <- readr::read_csv(file.path(PATHS$tables, "nig_by_period_wealth_quintile.csv"), show_col_types = FALSE)
nig_sens <- readr::read_csv(file.path(PATHS$tables, "nig_inflation_sensitivity.csv"), show_col_types = FALSE)
reval <- readr::read_csv(file.path(PATHS$tables, "inequality_revaluation_by_period.csv"), show_col_types = FALSE)
contrib <- readr::read_csv(file.path(PATHS$tables, "revaluation_contributions_by_period.csv"), show_col_types = FALSE)
port <- readr::read_csv(file.path(PATHS$tables, "portfolio_by_wealth_quintile.csv"), show_col_types = FALSE)

nig_q$wealth_q <- factor(nig_q$wealth_q, levels = c("Q1", "Q2", "Q3", "Q4", "Q5"))
nig_per$wealth_q <- factor(nig_per$wealth_q, levels = c("Q1", "Q2", "Q3", "Q4", "Q5"))
nig_sens$wealth_q <- factor(nig_sens$wealth_q, levels = c("Q1", "Q2", "Q3", "Q4", "Q5"))

# Figure 1: NIG as % of income by quintile, latest year
latest <- max(nig_q$year, na.rm = TRUE)
ycol <- if ("nig_over_inc" %in% names(nig_q)) "nig_over_inc" else "mean_NIG_pct_inc"
p1 <- nig_q %>%
  dplyr::filter(year == latest) %>%
  ggplot2::ggplot(ggplot2::aes(x = wealth_q, y = .data[[ycol]])) +
  ggplot2::geom_col(fill = "#1f4e79") +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::labs(
    title = paste0("Net inflation gain as a share of income (", latest, ")"),
    subtitle = "Canadian SFS; Wolff-style IG − IT accounting (ratio of means)",
    x = "Wealth quintile",
    y = "NIG / mean income"
  ) +
  theme_paper()
ggplot2::ggsave(file.path(PATHS$figures, "nig_pct_income_latest.png"), p1, width = 7, height = 4.5, dpi = 150)

# Figure 2: Period NIG % income by quintile
py <- if ("nig_over_inc" %in% names(nig_per)) "nig_over_inc" else "mean_NIG_pct_inc"
p2 <- nig_per %>%
  ggplot2::ggplot(ggplot2::aes(x = wealth_q, y = .data[[py]], fill = wealth_q)) +
  ggplot2::geom_col() +
  ggplot2::facet_wrap(~period) +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::scale_fill_manual(values = c("#8c2d04", "#cc4c02", "#ec7014", "#fe9929", "#fec44f"), guide = "none") +
  ggplot2::labs(
    title = "Period net inflation gain / income by wealth quintile",
    x = NULL, y = "NIG / mean income"
  ) +
  theme_paper()
ggplot2::ggsave(file.path(PATHS$figures, "nig_period_by_quintile.png"), p2, width = 9, height = 6, dpi = 150)

# Figure 2b: Full-span period NIG / income (1999–2023)
nig_full_file <- file.path(PATHS$tables, "nig_by_quintile_1999_2023.csv")
if (file.exists(nig_full_file)) {
  nig_full <- readr::read_csv(nig_full_file, show_col_types = FALSE) %>%
    dplyr::mutate(wealth_q = factor(wealth_q, levels = c("Q1", "Q2", "Q3", "Q4", "Q5")))
  fy <- if ("nig_over_inc" %in% names(nig_full)) "nig_over_inc" else "mean_NIG_pct_inc"
  p2b <- nig_full %>%
    ggplot2::ggplot(ggplot2::aes(x = wealth_q, y = .data[[fy]])) +
    ggplot2::geom_col(fill = "#1f4e79") +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::labs(
      title = "Net inflation gain / income by wealth quintile (1999–2023)",
      subtitle = "Portfolios fixed at 1999; cumulative CPI and endpoint rate wedge",
      x = "Wealth quintile",
      y = "NIG / mean income"
    ) +
    theme_paper()
  ggplot2::ggsave(
    file.path(PATHS$figures, "nig_pct_income_by_quintile_1999_2023.png"),
    p2b, width = 7, height = 4.5, dpi = 150
  )
  ggplot2::ggsave(
    file.path(PATHS$figures, "nig_pct_income_by_quintile_1999_2023.pdf"),
    p2b, width = 7, height = 4.5
  )
}

# Figure 3: Inflation sensitivity (latest year)
sy <- if ("nig_over_inc" %in% names(nig_sens)) "nig_over_inc" else "mean_NIG_pct_inc"
p3 <- nig_sens %>%
  ggplot2::ggplot(ggplot2::aes(x = INF_cf, y = .data[[sy]], colour = wealth_q)) +
  ggplot2::geom_line(linewidth = 1) +
  ggplot2::geom_point(size = 2) +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
  ggplot2::scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::labs(
    title = paste0("NIG / income vs counterfactual inflation (", unique(nig_sens$year), ")"),
    x = "Assumed annual inflation",
    y = "NIG / mean income",
    colour = "Wealth quintile"
  ) +
  theme_paper()
ggplot2::ggsave(file.path(PATHS$figures, "nig_inflation_sensitivity.png"), p3, width = 7.5, height = 4.5, dpi = 150)

# Figure 4: Debt/asset by quintile (leverage channel)
p4 <- port %>%
  dplyr::filter(year == latest) %>%
  dplyr::mutate(wealth_q = factor(wealth_q, levels = c("Q1", "Q2", "Q3", "Q4", "Q5"))) %>%
  ggplot2::ggplot(ggplot2::aes(x = wealth_q, y = debt_asset)) +
  ggplot2::geom_col(fill = "#4d4d4d") +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::labs(
    title = paste0("Debt-to-asset ratio by wealth quintile (", latest, ")"),
    subtitle = "Higher leverage → larger inflation debt-devaluation gains",
    x = "Wealth quintile", y = "Debt / assets"
  ) +
  theme_paper()
ggplot2::ggsave(file.path(PATHS$figures, "debt_asset_by_quintile.png"), p4, width = 7, height = 4.5, dpi = 150)

# Figure 5: Revaluation contributions stacked
contrib_long <- contrib %>%
  tidyr::pivot_longer(
    cols = c(mean_d_stk, mean_d_bus, mean_d_bnd, mean_d_liq, mean_d_dbt, mean_d_hous),
    names_to = "component", values_to = "dollars"
  ) %>%
  dplyr::mutate(
    component = dplyr::recode(
      component,
      mean_d_stk = "Stocks",
      mean_d_bus = "Business",
      mean_d_bnd = "Bonds",
      mean_d_liq = "Liquid assets",
      mean_d_dbt = "Debt devaluation",
      mean_d_hous = "Housing (mortgage-rate)"
    )
  )

p5 <- contrib_long %>%
  ggplot2::ggplot(ggplot2::aes(x = period, y = dollars, fill = component)) +
  ggplot2::geom_col() +
  ggplot2::scale_y_continuous(labels = scales::dollar_format(scale = 1e-3, suffix = "k")) +
  ggplot2::labs(
    title = "Mean wealth revaluation contributions by period",
    subtitle = "WP 29392-style direct effects; portfolios fixed at period start",
    x = NULL, y = "CAD (mean)", fill = NULL
  ) +
  theme_paper() +
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))
ggplot2::ggsave(file.path(PATHS$figures, "revaluation_contributions.png"), p5, width = 9, height = 5, dpi = 150)

# Figure 6: Gini change from revaluation
p6 <- reval %>%
  dplyr::mutate(period = factor(period, levels = period)) %>%
  ggplot2::ggplot(ggplot2::aes(x = period)) +
  ggplot2::geom_col(ggplot2::aes(y = d_gini), fill = "#1f4e79") +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
  ggplot2::labs(
    title = "Change in wealth Gini from inflation/rate revaluation",
    subtitle = "Negative = equalizing",
    x = NULL, y = expression(Delta~Gini)
  ) +
  theme_paper() +
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))
ggplot2::ggsave(file.path(PATHS$figures, "gini_change_revaluation.png"), p6, width = 7.5, height = 4.5, dpi = 150)

# ---------------------------------------------------------------------------
# F-IR2: Stacked contribution *shares* of mean ΔNW (Interest-rates section)
# ---------------------------------------------------------------------------
shares_file <- file.path(PATHS$tables, "revaluation_contribution_shares_by_period.csv")
if (file.exists(shares_file)) {
  shares <- readr::read_csv(shares_file, show_col_types = FALSE) %>%
    dplyr::filter(!grepl("sum", period, ignore.case = TRUE)) %>%
    dplyr::filter(is.na(share_unstable) | !share_unstable)

  share_cols <- c(
    "share_stk", "share_bus", "share_bnd", "share_liq", "share_dbt", "share_hous"
  )
  share_cols <- share_cols[share_cols %in% names(shares)]

  shares_long <- shares %>%
    tidyr::pivot_longer(
      cols = dplyr::all_of(share_cols),
      names_to = "component",
      values_to = "share"
    ) %>%
    dplyr::filter(!is.na(share)) %>%
    dplyr::mutate(
      component = dplyr::recode(
        component,
        share_stk = "Stocks",
        share_bus = "Business",
        share_bnd = "Bonds",
        share_liq = "Liquid assets",
        share_dbt = "Debt devaluation",
        share_hous = "Housing (mortgage-rate)"
      ),
      housing_toggle = dplyr::recode(
        housing_toggle,
        no_housing = "No housing",
        ca25y_housing = "CA 25y housing"
      ),
      period = factor(period, levels = unique(period[order(year0)]))
    )

  p_ir2 <- shares_long %>%
    ggplot2::ggplot(ggplot2::aes(x = period, y = share, fill = component)) +
    ggplot2::geom_col() +
    ggplot2::facet_wrap(~housing_toggle, ncol = 1) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::labs(
      title = "Channel shares of mean revaluation (by period)",
      subtitle = "Share of mean ΔNW; portfolios fixed at period start. Near-zero denom periods omitted.",
      x = NULL, y = "Share of mean ΔNW", fill = NULL,
      caption = "F-IR2. Cumulative 1999–2023 uses sum of period $ (see tables)."
    ) +
    theme_paper() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 30, hjust = 1),
      plot.caption = ggplot2::element_text(hjust = 0, size = 8)
    )
  ggplot2::ggsave(
    file.path(PATHS$figures, "revaluation_contribution_shares.png"),
    p_ir2, width = 9, height = 7, dpi = 150
  )
}

# ---------------------------------------------------------------------------
# F-IR3: Gini path — actual end-of-period vs revalued counterfactuals
# ---------------------------------------------------------------------------
# Path points: start Gini at year0 of first period, then for each spell end:
# actual gini1, and counterfactual gini from applying reval to year0 portfolios.
if (all(c("gini0", "gini1_actual", "gini_reval", "gini_reval_hous") %in% names(reval))) {
  first <- reval %>% dplyr::arrange(year0) %>% dplyr::slice(1)
  path_actual <- dplyr::bind_rows(
    tibble::tibble(year = first$year0, series = "Actual SFS", gini = first$gini0),
    reval %>%
      dplyr::arrange(year0) %>%
      dplyr::transmute(year = year1, series = "Actual SFS", gini = gini1_actual)
  )
  # Counterfactual: apply each spell's reval to that spell's start portfolios;
  # plot end-of-spell counterfactual Gini at year1 (not a chained compound path).
  path_cf <- reval %>%
    dplyr::arrange(year0) %>%
    dplyr::select(year1, gini_reval, gini_reval_hous, gini_reval_wolff) %>%
    tidyr::pivot_longer(
      cols = dplyr::starts_with("gini_reval"),
      names_to = "series",
      values_to = "gini"
    ) %>%
    dplyr::mutate(
      year = year1,
      series = dplyr::recode(
        series,
        gini_reval = "Reval (no housing)",
        gini_reval_hous = "Reval (+ CA 25y housing)",
        gini_reval_wolff = "Reval (+ Wolff 30y housing)"
      )
    ) %>%
    dplyr::select(year, series, gini)

  # Anchor counterfactuals at first year0 with actual gini0
  path_cf_start <- tibble::tibble(
    year = first$year0,
    series = unique(path_cf$series),
    gini = first$gini0
  )
  gini_path <- dplyr::bind_rows(path_actual, path_cf_start, path_cf) %>%
    dplyr::distinct(year, series, .keep_all = TRUE) %>%
    dplyr::arrange(series, year)

  p_ir3 <- gini_path %>%
    ggplot2::ggplot(ggplot2::aes(x = year, y = gini, colour = series, linetype = series)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_point(size = 2) +
    ggplot2::scale_x_continuous(breaks = sort(unique(gini_path$year))) +
    ggplot2::labs(
      title = "Wealth Gini: actual path vs period revaluation counterfactuals",
      subtitle = "Counterfactual points = Gini after applying that spell's rate/inflation package to start-of-period portfolios",
      x = NULL, y = "Wealth Gini", colour = NULL, linetype = NULL,
      caption = "F-IR3. Not a chained compound portfolio path; each spell is independent."
    ) +
    theme_paper() +
    ggplot2::theme(plot.caption = ggplot2::element_text(hjust = 0, size = 8))
  ggplot2::ggsave(
    file.path(PATHS$figures, "gini_path_actual_vs_reval.png"),
    p_ir3, width = 9, height = 5.5, dpi = 150
  )
}

# Optional: shut-off ΔGini bars (companion to T-IR3)
shut_file <- file.path(PATHS$tables, "revaluation_gini_shutoffs_by_period.csv")
if (file.exists(shut_file)) {
  shut <- readr::read_csv(shut_file, show_col_types = FALSE)
  shut_long <- shut %>%
    tidyr::pivot_longer(
      cols = dplyr::starts_with("d_gini_"),
      names_to = "experiment",
      values_to = "d_gini"
    ) %>%
    dplyr::mutate(
      experiment = dplyr::recode(
        experiment,
        d_gini_no_hous = "Full (no housing)",
        d_gini_ca25y = "Full + CA 25y housing",
        d_gini_wolff30y = "Full + Wolff 30y",
        d_gini_eq_bus = "Equity + business only",
        d_gini_hous_only = "Housing only",
        d_gini_debt_liq = "Debt + liquid only"
      ),
      experiment = factor(
        experiment,
        levels = c(
          "Full (no housing)", "Full + CA 25y housing", "Full + Wolff 30y",
          "Equity + business only", "Housing only", "Debt + liquid only"
        )
      ),
      period = factor(period, levels = unique(period[order(year0)]))
    )
  p_shut <- shut_long %>%
    ggplot2::ggplot(ggplot2::aes(x = period, y = d_gini, fill = experiment)) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.85), width = 0.8) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
    ggplot2::labs(
      title = "ΔGini under channel shut-off experiments",
      subtitle = "Negative = equalizing; equity/business often disequalizing when rates fall",
      x = NULL, y = expression(Delta~Gini), fill = NULL
    ) +
    theme_paper() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))
  ggplot2::ggsave(
    file.path(PATHS$figures, "gini_shutoffs_by_period.png"),
    p_shut, width = 10, height = 5.5, dpi = 150
  )
}

message("Wrote figures to output/figures/")
