# code/07_mortgage_affordability.R
# Wolff 30y FRM affordability benchmark alongside Canadian amort/stress sensitivities.
# Tenure split: owner with mortgage / free-and-clear / renter.
# Scope note: we do NOT model homeowner renewal-risk from short Canadian terms;
# rate pass-through to existing loans is postponed.

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
macro <- readr::read_csv(file.path(PATHS$external, "macro_annual.csv"), show_col_types = FALSE)

# Ensure housing_status exists (rebuild panel if older RDS)
if (!"housing_status" %in% names(sfs)) {
  source("code/01_build_sfs_panel.R")
  source("code/03_portfolio_map.R")
  sfs <- readRDS(port_file)
}

# ---------------------------------------------------------------------------
# 1. Wolff-style affordability curves (price index vs mortgage rate)
# ---------------------------------------------------------------------------
# Normalize so affordable price = 1 at 6.5% (Wolff's illustrative high-rate anchor).
rate_base <- 0.065
rate_grid <- seq(0.03, 0.10, by = 0.0025)

curve_specs <- tibble::tribble(
  ~scenario,                          ~amort_years, ~note,
  "Wolff US 30y FRM (benchmark)",     30L,          "Wolff WP chart analogue; 20% down",
  "Canada 25y amort (baseline)",      25L,          "Payment set off 25y amort (typical CA)",
  "Canada 30y amort",                 30L,          "Longer CA amortization sensitivity",
  "Canada 25y amort (sensitivity)",   25L,          "Same amort; compared via stress rates below"
)

curves <- purrr::pmap_dfr(curve_specs[1:3, ], function(scenario, amort_years, note) {
  tibble::tibble(
    scenario = scenario,
    note = note,
    amort_years = amort_years,
    rate = rate_grid,
    price_index = affordable_price_curve(rate_grid, rate_base, LTV = 0.80, amort_years = amort_years)
  )
})

readr::write_csv(curves, file.path(PATHS$tables, "mortgage_affordability_curves.csv"))

# Illustrative points matching Wolff's narrative (6.5% vs 4.5%)
wolff_points <- tibble::tibble(
  scenario = c("Wolff US 30y FRM", "Canada 25y amort", "Canada 30y amort"),
  amort_years = c(30L, 25L, 30L),
  rate_high = 0.065,
  rate_low = 0.045,
  price_ratio_low_vs_high = c(
    house_price_ratio(0.065, 0.045, 0.80, 30),
    house_price_ratio(0.065, 0.045, 0.80, 25),
    house_price_ratio(0.065, 0.045, 0.80, 30)
  )
)
# At same payment, price at 4.5% / price at 6.5%
readr::write_csv(wolff_points, file.path(PATHS$tables, "mortgage_affordability_wolff_points.csv"))

# ---------------------------------------------------------------------------
# 2. Period hp_ratio sensitivities (contract 5y; 3y proxy; stress; amort)
# ---------------------------------------------------------------------------
# 3y term proxy: subtract 20bp from 5y conventional (rough historical spread);
# pass-through / true 3y series deferred.
TERM3_SPREAD <- 0.002

sens_rows <- list()
for (i in seq_len(nrow(periods))) {
  pr <- periods[i, ]
  m0 <- as.numeric(pr$mort0)
  m1 <- as.numeric(pr$mort1)
  m0_3 <- max(m0 - TERM3_SPREAD, 0.005)
  m1_3 <- max(m1 - TERM3_SPREAD, 0.005)
  m0_s <- stress_mortgage_rate(m0)
  m1_s <- stress_mortgage_rate(m1)

  sens_rows[[i]] <- tibble::tibble(
    period = paste0(pr$year0, "-", pr$year1),
    year0 = pr$year0,
    year1 = pr$year1,
    mort5_0 = m0,
    mort5_1 = m1,
    # Wolff benchmark using period's CA 5y rates but 30y amort (institutional hybrid)
    hp_wolff_30y_amort = house_price_ratio(m0, m1, 0.80, 30),
    hp_ca_25y = house_price_ratio(m0, m1, 0.80, 25),
    hp_ca_30y = house_price_ratio(m0, m1, 0.80, 30),
    hp_ca_3y_proxy_25y = house_price_ratio(m0_3, m1_3, 0.80, 25),
    hp_stress_25y = house_price_ratio(m0_s, m1_s, 0.80, 25),
    d_mort_pp = (m1 - m0) * 100
  )
}
hp_sens <- dplyr::bind_rows(sens_rows)
readr::write_csv(hp_sens, file.path(PATHS$tables, "mortgage_hp_ratio_sensitivities.csv"))

# ---------------------------------------------------------------------------
# 3. Tenure × mortgage status: portfolio and housing-channel incidence
# ---------------------------------------------------------------------------
status_levels <- c("owner_mortgage", "owner_free_clear", "renter")

tenure_stock <- sfs %>%
  dplyr::mutate(
    housing_status = factor(housing_status, levels = status_levels)
  ) %>%
  dplyr::group_by(year, housing_status) %>%
  dplyr::summarise(
    n = dplyr::n(),
    w_share = sum(weight, na.rm = TRUE),
    mean_nw = wtd_mean(w_wolff, weight),
    mean_HOUS = wtd_mean(HOUS, weight),
    mean_mort_pr = wtd_mean(debt_mort_princ_res_val, weight),
    mean_DBT = wtd_mean(DBT, weight),
    mean_INC = wtd_mean(INC, weight),
    debt_asset = wtd_mean(DBT, weight) /
      pmax(wtd_mean(STK + BND + LIQ + BUS + HOUS + OTH_NF, weight), 1),
    .groups = "drop"
  ) %>%
  dplyr::group_by(year) %>%
  dplyr::mutate(w_share = w_share / sum(w_share)) %>%
  dplyr::ungroup()

readr::write_csv(tenure_stock, file.path(PATHS$tables, "housing_status_by_year.csv"))

# Apply baseline CA 25y hp_ratio housing shock by tenure (owners only get HOUS gain)
tenure_reval_rows <- list()
for (i in seq_len(nrow(periods))) {
  pr <- periods[i, ]
  y0 <- pr$year0
  hp <- as.numeric(hp_sens$hp_ca_25y[i])
  hp_w <- as.numeric(hp_sens$hp_wolff_30y_amort[i])
  base <- sfs %>% dplyr::filter(year == y0)
  if (!nrow(base)) next

  base <- base %>%
    dplyr::mutate(
      # Housing price channel: only owners hold HOUS; renters get 0
      d_hous_ca = dplyr::if_else(housing_status %in% c("owner_mortgage", "owner_free_clear"),
                                 HOUS * (hp - 1), 0),
      d_hous_wolff = dplyr::if_else(housing_status %in% c("owner_mortgage", "owner_free_clear"),
                                    HOUS * (hp_w - 1), 0),
      # Debt devaluation still applies to all debt (mortgagors denser)
      infl = as.numeric(pr$infl_cum),
      d_dbt = DBT * infl,
      period = paste0(pr$year0, "-", pr$year1)
    )

  tenure_reval_rows[[length(tenure_reval_rows) + 1]] <- base %>%
    dplyr::group_by(period, housing_status) %>%
    dplyr::summarise(
      year0 = y0,
      n = dplyr::n(),
      hp_ca_25y = hp,
      hp_wolff_30y = hp_w,
      mean_d_hous_ca = wtd_mean(d_hous_ca, weight),
      mean_d_hous_wolff = wtd_mean(d_hous_wolff, weight),
      mean_d_dbt = wtd_mean(d_dbt, weight),
      mean_nw0 = wtd_mean(w_wolff, weight),
      mean_HOUS = wtd_mean(HOUS, weight),
      .groups = "drop"
    )
}

tenure_reval <- dplyr::bind_rows(tenure_reval_rows)
readr::write_csv(tenure_reval, file.path(PATHS$tables, "housing_channel_by_tenure_period.csv"))

# ---------------------------------------------------------------------------
# 4. Figures
# ---------------------------------------------------------------------------
p_curve <- curves %>%
  ggplot2::ggplot(ggplot2::aes(x = rate, y = price_index, colour = scenario)) +
  ggplot2::geom_line(linewidth = 1) +
  ggplot2::geom_vline(xintercept = 0.045, linetype = "dashed", alpha = 0.4) +
  ggplot2::geom_vline(xintercept = 0.065, linetype = "dashed", alpha = 0.4) +
  ggplot2::annotate("text", x = 0.045, y = max(curves$price_index) * 0.98,
                     label = "4.5%", hjust = -0.1, size = 3) +
  ggplot2::annotate("text", x = 0.065, y = max(curves$price_index) * 0.98,
                     label = "6.5% (index=1)", hjust = -0.1, size = 3) +
  ggplot2::scale_x_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  ggplot2::labs(
    title = "Mortgage affordability: Wolff 30y FRM vs Canadian amortization",
    subtitle = "Affordable price index at fixed payment & 20% down; indexed to 1 at 6.5%",
    x = "Mortgage contract rate",
    y = "Relative affordable house price",
    colour = NULL,
    caption = paste(
      "Wolff benchmark retained as evaluation starting point.",
      "Canadian curves use 25y/30y amort (term renewals not modeled).",
      "Homeowner short-term contract risk and rate pass-through deferred."
    )
  ) +
  theme_paper() +
  ggplot2::theme(plot.caption = ggplot2::element_text(hjust = 0, size = 8))

ggplot2::ggsave(
  file.path(PATHS$figures, "mortgage_affordability_wolff_vs_canada.png"),
  p_curve, width = 9, height = 5.5, dpi = 150
)

hp_long <- hp_sens %>%
  tidyr::pivot_longer(
    cols = dplyr::starts_with("hp_"),
    names_to = "assumption",
    values_to = "hp_ratio"
  ) %>%
  dplyr::mutate(
    assumption = dplyr::recode(
      assumption,
      hp_wolff_30y_amort = "Wolff 30y amort",
      hp_ca_25y = "CA 25y amort",
      hp_ca_30y = "CA 30y amort",
      hp_ca_3y_proxy_25y = "CA 3y-rate proxy, 25y amort",
      hp_stress_25y = "Stress rate, 25y amort"
    )
  )

p_sens <- hp_long %>%
  ggplot2::ggplot(ggplot2::aes(x = period, y = hp_ratio, fill = assumption)) +
  ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.85), width = 0.8) +
  ggplot2::geom_hline(yintercept = 1, linewidth = 0.3) +
  ggplot2::labs(
    title = "Period house-price affordability ratios under rate-path assumptions",
    subtitle = "hp_ratio = affordable price at end-of-period rate / start-of-period (portfolios fixed)",
    x = NULL, y = "House-price ratio", fill = NULL,
    caption = paste(
      "T-IR4 / F-IR1 companion. Baseline = 5y conventional + 25y amort, LTV 0.80.",
      "3y proxy = 5y − 20bp. Stress = max(contract+2pp, 5.25%).",
      "Renewal-risk and loan-level pass-through deferred."
    )
  ) +
  theme_paper() +
  ggplot2::theme(
    axis.text.x = ggplot2::element_text(angle = 30, hjust = 1),
    plot.caption = ggplot2::element_text(hjust = 0, size = 8)
  )

ggplot2::ggsave(
  file.path(PATHS$figures, "mortgage_hp_ratio_sensitivities.png"),
  p_sens, width = 10, height = 5.5, dpi = 150
)

latest <- max(tenure_stock$year, na.rm = TRUE)
p_ten <- tenure_stock %>%
  dplyr::filter(year == latest) %>%
  ggplot2::ggplot(ggplot2::aes(x = housing_status, y = w_share, fill = housing_status)) +
  ggplot2::geom_col() +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::scale_x_discrete(labels = c(
    owner_mortgage = "Owner\nwith mortgage",
    owner_free_clear = "Owner\nfree & clear",
    renter = "Renter"
  )) +
  ggplot2::labs(
    title = paste0("Housing status shares (", latest, ")"),
    x = NULL, y = "Population weight share", fill = NULL
  ) +
  theme_paper() +
  ggplot2::guides(fill = "none")

ggplot2::ggsave(
  file.path(PATHS$figures, "housing_status_shares_latest.png"),
  p_ten, width = 7, height = 4.5, dpi = 150
)

# Housing channel by tenure for latest period
last_per <- tenure_reval$period[length(unique(tenure_reval$period))]
# actually get last chronologically
last_per <- tenure_reval %>%
  dplyr::distinct(period, year0) %>%
  dplyr::arrange(year0) %>%
  dplyr::slice_tail(n = 1) %>%
  dplyr::pull(period)

ten_long <- tenure_reval %>%
  dplyr::filter(period == last_per) %>%
  tidyr::pivot_longer(
    cols = c(mean_d_hous_ca, mean_d_hous_wolff, mean_d_dbt),
    names_to = "component",
    values_to = "dollars"
  ) %>%
  dplyr::mutate(
    component = dplyr::recode(
      component,
      mean_d_hous_ca = "Housing (CA 25y)",
      mean_d_hous_wolff = "Housing (Wolff 30y amort)",
      mean_d_dbt = "Debt devaluation"
    ),
    housing_status = factor(housing_status, levels = status_levels)
  )

p_ten_ch <- ten_long %>%
  ggplot2::ggplot(ggplot2::aes(x = housing_status, y = dollars, fill = component)) +
  ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.8), width = 0.75) +
  ggplot2::scale_x_discrete(labels = c(
    owner_mortgage = "Owner\nmortgage",
    owner_free_clear = "Owner\nfree & clear",
    renter = "Renter"
  )) +
  ggplot2::scale_y_continuous(labels = scales::dollar_format(scale = 1e-3, suffix = "k")) +
  ggplot2::labs(
    title = paste0("Mean housing / debt channels by tenure (", last_per, ")"),
    subtitle = "Owners receive house-price affordability shock; renters only debt (usually small)",
    x = NULL, y = "CAD (mean)", fill = NULL
  ) +
  theme_paper()

ggplot2::ggsave(
  file.path(PATHS$figures, "housing_channel_by_tenure.png"),
  p_ten_ch, width = 8.5, height = 5, dpi = 150
)

message("Wrote mortgage affordability tables/figures (Wolff + Canada) and tenure splits")
