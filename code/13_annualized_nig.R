# code/13_annualized_nig.R — annualize period / full-span NIG for cross-spell comparison
#
# Inter-wave spells differ in length (3–7 years; full span 24 years). Raw cumulative
# nig_over_inc = mean_NIG / mean_inc is not comparable across spells. This script
# converts cumulative ratios and dollar means to per-year rates.
#
# Annualization (see docs/09_annualized_nig_notes.md):
#   Ratio (preferred, geometric):  r_ann = (1 + nig_over_inc)^(1/T) - 1
#     when 1 + nig_over_inc > 0; else arithmetic fallback x/T (flagged).
#   Dollars (linear):              mean_NIG_ann = mean_NIG / T
#   Years T:                       year1 - year0 (matches period_rates$n_years).

source("code/00_setup.R")

period_file <- file.path(PATHS$tables, "nig_by_period_wealth_quintile.csv")
full_file <- file.path(PATHS$tables, "nig_by_quintile_1999_2023.csv")
rates_file <- file.path(PATHS$external, "period_rates.csv")

if (!file.exists(period_file) || !file.exists(full_file)) {
  message("Period NIG tables missing; sourcing code/04_inflation_gain.R …")
  source("code/04_inflation_gain.R")
}

nig_per <- readr::read_csv(period_file, show_col_types = FALSE)
nig_full <- readr::read_csv(full_file, show_col_types = FALSE)

# ---- Helpers ---------------------------------------------------------------
# Geometric annualization of a cumulative ratio x over T years.
# Prefer (1+x)^(1/T)-1 when defined on the reals (1+x > 0); otherwise x/T.
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

add_annualized <- function(df) {
  df %>%
    dplyr::mutate(
      T_years = as.integer(year1 - year0),
      nig_over_inc_ann = annualize_ratio(nig_over_inc, T_years),
      nig_over_inc_ann_method = annualize_method(nig_over_inc, T_years),
      # Optional: mean dollar NIG per year (linear; dollars are additive over time)
      mean_NIG_ann = dplyr::if_else(
        is.finite(T_years) & T_years > 0,
        mean_NIG / T_years,
        NA_real_
      ),
      mean_IG_ann = dplyr::if_else(
        is.finite(T_years) & T_years > 0,
        mean_IG / T_years,
        NA_real_
      ),
      mean_IT_ann = dplyr::if_else(
        is.finite(T_years) & T_years > 0,
        mean_IT / T_years,
        NA_real_
      )
    )
}

# Cross-check T against period_rates when available
if (file.exists(rates_file)) {
  rates <- readr::read_csv(rates_file, show_col_types = FALSE) %>%
    dplyr::mutate(period = paste0(year0, "-", year1))
  chk <- nig_per %>%
    dplyr::distinct(period, year0, year1) %>%
    dplyr::mutate(T_years = as.integer(year1 - year0)) %>%
    dplyr::left_join(rates %>% dplyr::select(period, n_years), by = "period")
  bad <- chk %>% dplyr::filter(!is.na(n_years), T_years != as.integer(n_years))
  if (nrow(bad)) {
    warning(
      "T_years != period_rates$n_years for: ",
      paste(bad$period, collapse = ", ")
    )
  }
}

nig_per_ann <- add_annualized(nig_per)
nig_full_ann <- add_annualized(nig_full)

# Combined table (inter-wave + full span) for easy downstream use
nig_all_ann <- dplyr::bind_rows(
  nig_per_ann %>% dplyr::mutate(span_type = "inter_wave"),
  nig_full_ann %>% dplyr::mutate(span_type = "full_span")
)

out_per <- file.path(PATHS$tables, "nig_by_period_wealth_quintile_annualized.csv")
out_full <- file.path(PATHS$tables, "nig_by_quintile_1999_2023_annualized.csv")
out_all <- file.path(PATHS$tables, "nig_annualized_by_quintile.csv")

readr::write_csv(nig_per_ann, out_per)
readr::write_csv(nig_full_ann, out_full)
readr::write_csv(nig_all_ann, out_all)

# ---- Figures ---------------------------------------------------------------
q_levels <- c("Q1", "Q2", "Q3", "Q4", "Q5")
q_fills <- c("#8c2d04", "#cc4c02", "#ec7014", "#fe9929", "#fec44f")

nig_per_ann <- nig_per_ann %>%
  dplyr::mutate(
    wealth_q = factor(wealth_q, levels = q_levels),
    period = factor(period, levels = unique(period[order(year0)]))
  )
nig_full_ann <- nig_full_ann %>%
  dplyr::mutate(wealth_q = factor(wealth_q, levels = q_levels))

# Faceted inter-wave: annualized NIG/income by quintile (comparable y-scale)
p_per <- nig_per_ann %>%
  ggplot2::ggplot(ggplot2::aes(x = wealth_q, y = nig_over_inc_ann, fill = wealth_q)) +
  ggplot2::geom_col() +
  ggplot2::facet_wrap(~period) +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  ggplot2::scale_fill_manual(values = q_fills, guide = "none") +
  ggplot2::labs(
    title = "Annualized period NIG / income by wealth quintile",
    subtitle = "Geometric: (1 + nig/inc)^(1/T) − 1; T = year1 − year0. Fallback x/T if 1+x ≤ 0.",
    x = NULL,
    y = "Annualized NIG / mean income",
    caption = "Comparable across spells of different lengths. See docs/09_annualized_nig_notes.md."
  ) +
  theme_paper() +
  ggplot2::theme(plot.caption = ggplot2::element_text(hjust = 0, size = 8))

ggplot2::ggsave(
  file.path(PATHS$figures, "nig_pct_income_by_quintile_periods_annualized.png"),
  p_per, width = 9, height = 6, dpi = 150
)
ggplot2::ggsave(
  file.path(PATHS$figures, "nig_pct_income_by_quintile_periods_annualized.pdf"),
  p_per, width = 9, height = 6
)

# Full-span annualized
span_lab <- unique(nig_full_ann$period)[1]
p_full <- nig_full_ann %>%
  ggplot2::ggplot(ggplot2::aes(x = wealth_q, y = nig_over_inc_ann)) +
  ggplot2::geom_col(fill = "#1f4e79") +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  ggplot2::labs(
    title = paste0("Annualized NIG / income by wealth quintile (", span_lab, ")"),
    subtitle = paste0(
      "Geometric annualization over T = ",
      unique(nig_full_ann$T_years)[1],
      " years; portfolios fixed at ",
      unique(nig_full_ann$year0)[1]
    ),
    x = "Wealth quintile",
    y = "Annualized NIG / mean income",
    caption = "See docs/09_annualized_nig_notes.md."
  ) +
  theme_paper() +
  ggplot2::theme(plot.caption = ggplot2::element_text(hjust = 0, size = 8))

ggplot2::ggsave(
  file.path(PATHS$figures, "nig_pct_income_by_quintile_1999_2023_annualized.png"),
  p_full, width = 7, height = 4.5, dpi = 150
)
ggplot2::ggsave(
  file.path(PATHS$figures, "nig_pct_income_by_quintile_1999_2023_annualized.pdf"),
  p_full, width = 7, height = 4.5
)

# Dodged comparison: all periods + full span on one panel (optional clarity fig)
p_dodge <- nig_all_ann %>%
  dplyr::mutate(
    wealth_q = factor(wealth_q, levels = q_levels),
    period = factor(period, levels = unique(period[order(year0, period)]))
  ) %>%
  ggplot2::ggplot(ggplot2::aes(x = wealth_q, y = nig_over_inc_ann, fill = period)) +
  ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.85), width = 0.8) +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  ggplot2::labs(
    title = "Annualized NIG / income: periods vs full span",
    subtitle = "Same geometric annualization; Q1–Q5 comparable across spells",
    x = "Wealth quintile",
    y = "Annualized NIG / mean income",
    fill = NULL
  ) +
  theme_paper()

ggplot2::ggsave(
  file.path(PATHS$figures, "nig_pct_income_by_quintile_annualized_dodged.png"),
  p_dodge, width = 10, height = 5, dpi = 150
)

message("Wrote annualized NIG tables and figures.")
message("  ", out_per)
message("  ", out_full)
message("  ", out_all)
