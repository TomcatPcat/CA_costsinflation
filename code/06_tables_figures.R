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

message("Wrote figures to output/figures/")
