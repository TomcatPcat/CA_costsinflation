# code/12_reval_by_quintile.R — revaluation contributions by income quintile
#
# WP 29392-style channels (same as code/05_inequality_effects.R), summarised
# by within-year weighted income quintiles of INC. Panels: Q5 (top) … Q1.

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

# Within-year weighted income quintiles (INC = inc_it from portfolio map)
assign_income_q <- function(df) {
  df %>%
    dplyr::group_by(year) %>%
    dplyr::group_modify(~ {
      x <- .x
      ok <- is.finite(x$INC) & is.finite(x$weight) & x$weight > 0
      x$income_q <- NA_character_
      if (sum(ok) < 20L) return(x)
      qs <- tryCatch(
        wtd_quantile(x$INC[ok], x$weight[ok], probs = c(0.2, 0.4, 0.6, 0.8)),
        error = function(e) rep(NA_real_, 4)
      )
      if (any(!is.finite(qs))) return(x)
      x$income_q[ok] <- dplyr::case_when(
        x$INC[ok] <= qs[1] ~ "Q1",
        x$INC[ok] <= qs[2] ~ "Q2",
        x$INC[ok] <= qs[3] ~ "Q3",
        x$INC[ok] <= qs[4] ~ "Q4",
        TRUE ~ "Q5"
      )
      x
    }) %>%
    dplyr::ungroup()
}

sfs <- assign_income_q(sfs)

contrib_q_rows <- list()

for (i in seq_len(nrow(periods))) {
  pr <- periods[i, ]
  y0 <- as.integer(pr$year0)
  y1 <- as.integer(pr$year1)
  base <- sfs %>% dplyr::filter(year == y0, !is.na(income_q))
  if (!nrow(base)) next

  infl <- as.numeric(pr$infl_cum)
  r_n0 <- as.numeric(pr$goc10_0)
  r_n1 <- as.numeric(pr$goc10_1)
  r_r0 <- as.numeric(pr$real0)
  r_r1 <- as.numeric(pr$real1)
  m0 <- as.numeric(pr$mort0)
  m1 <- as.numeric(pr$mort1)
  hp_ratio <- tryCatch(house_price_ratio(m0, m1, 0.80, 25), error = function(e) 1)

  base <- base %>%
    dplyr::mutate(
      d_stk = consol_reval(STK, r_r0, r_r1, r_floor = 0.005, duration = 20),
      d_bus = consol_reval(BUS, r_r0, r_r1, r_floor = 0.005, duration = 20),
      d_bnd = duration_reval(BND, r_n1 - r_n0, pmax(r_n0, 0.01), 8),
      d_liq = -LIQ * infl,
      d_dbt = DBT * infl,
      d_hous = dplyr::if_else(
        housing_status %in% c("owner_mortgage", "owner_free_clear"),
        HOUS * (hp_ratio - 1),
        0
      ),
      d_total_no_hous = d_stk + d_bus + d_bnd + d_liq + d_dbt,
      d_total = d_total_no_hous + d_hous,
      period = paste0(y0, "-", y1)
    )

  contrib_q_rows[[length(contrib_q_rows) + 1]] <- base %>%
    dplyr::group_by(period, income_q) %>%
    dplyr::summarise(
      year0 = y0,
      year1 = y1,
      infl_cum = infl,
      hp_ratio = hp_ratio,
      n = dplyr::n(),
      mean_inc = wtd_mean(INC, weight),
      mean_nw0 = wtd_mean(w_wolff, weight),
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

contrib_q <- dplyr::bind_rows(contrib_q_rows) %>%
  dplyr::mutate(
    income_q = factor(income_q, levels = c("Q1", "Q2", "Q3", "Q4", "Q5"))
  ) %>%
  dplyr::arrange(year0, income_q)

tbl_path <- file.path(PATHS$tables, "reval_by_quintile_by_period.csv")
readr::write_csv(contrib_q, tbl_path)

# Long form for stacked bars
comp_levels <- c(
  "Stocks", "Business", "Bonds", "Liquid assets",
  "Debt devaluation", "Housing (mortgage-rate)"
)
contrib_long <- contrib_q %>%
  tidyr::pivot_longer(
    cols = c(mean_d_stk, mean_d_bus, mean_d_bnd, mean_d_liq, mean_d_dbt, mean_d_hous),
    names_to = "component",
    values_to = "dollars"
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
    ),
    component = factor(component, levels = comp_levels),
    # Facet order: Q5 on top
    income_q_panel = factor(income_q, levels = c("Q5", "Q4", "Q3", "Q2", "Q1")),
    period = factor(period, levels = unique(period[order(year0)]))
  )

comp_cols <- c(
  "Stocks" = "#1f4e79",
  "Business" = "#2e7d32",
  "Bonds" = "#6a3d9a",
  "Liquid assets" = "#b15928",
  "Debt devaluation" = "#e66101",
  "Housing (mortgage-rate)" = "#5e4fa2"
)

p <- contrib_long %>%
  ggplot2::ggplot(ggplot2::aes(x = period, y = dollars, fill = component)) +
  ggplot2::geom_col() +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
  ggplot2::facet_grid(income_q_panel ~ ., scales = "free_y", switch = "y") +
  ggplot2::scale_y_continuous(labels = scales::dollar_format(scale = 1e-3, suffix = "k")) +
  ggplot2::scale_fill_manual(values = comp_cols) +
  ggplot2::labs(
    title = "Mean wealth revaluation by income quintile",
    subtitle = "WP 29392-style direct effects; portfolios fixed at period start; Q5 (top) to Q1",
    x = NULL,
    y = "CAD (mean)",
    fill = NULL
  ) +
  theme_paper() +
  ggplot2::theme(
    axis.text.x = ggplot2::element_text(angle = 30, hjust = 1),
    strip.text.y.left = ggplot2::element_text(angle = 0, face = "bold"),
    strip.placement = "outside",
    legend.position = "bottom"
  ) +
  ggplot2::guides(fill = ggplot2::guide_legend(nrow = 2, byrow = TRUE))

fig_png <- file.path(PATHS$figures, "reval_by_quintile_panels.png")
fig_pdf <- file.path(PATHS$figures, "reval_by_quintile_panels.pdf")
ggplot2::ggsave(fig_png, p, width = 10, height = 11, dpi = 150)
ggplot2::ggsave(fig_pdf, p, width = 10, height = 11)

message("Wrote ", tbl_path)
message("Wrote ", fig_png)
message("Wrote ", fig_pdf)
