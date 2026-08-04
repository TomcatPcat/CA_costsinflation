# code/10_shs_consumption_incidence.R
# Weighted SHS consumption-incidence tables and figures (Tier A: 2017–2023).
# Numbering: plan said 09_shs_consumption_incidence; 08 taken → use 10.
# Proxies: income quintiles and income×tenure — NOT wealth quintiles.

source("code/00_setup.R")
source("code/utils/shs_baskets.R")

rds <- file.path(PATHS$processed, "shs_2017_2023.rds")
if (!file.exists(rds)) {
  message("SHS processed file missing; sourcing code/09_shs_load.R …")
  source("code/09_shs_load.R")
}
shs <- readRDS(rds)

# Analytic sample: drop territories from regional cuts (keep in other cuts)
shs_reg <- shs %>% dplyr::filter(!is.na(region), region != "Territories")

# ---- Cell summarizer -------------------------------------------------------

summarise_consumption <- function(df, group_vars) {
  df %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) %>%
    dplyr::summarise(
      n = dplyr::n(),
      w_sum = sum(WEIGHTD, na.rm = TRUE),
      mean_tc001 = wtd_mean(TC001, WEIGHTD),
      median_tc001 = {
        ok <- is.finite(TC001) & is.finite(WEIGHTD) & WEIGHTD > 0
        if (!any(ok)) NA_real_ else as.numeric(Hmisc::wtd.quantile(TC001[ok], weights = WEIGHTD[ok], probs = 0.5))
      },
      mean_hhtotinc = wtd_mean(HHTOTINC, WEIGHTD),
      median_hhtotinc = {
        ok <- is.finite(HHTOTINC) & is.finite(WEIGHTD) & WEIGHTD > 0
        if (!any(ok)) NA_real_ else as.numeric(Hmisc::wtd.quantile(HHTOTINC[ok], weights = WEIGHTD[ok], probs = 0.5))
      },
      mean_cy_ratio = wtd_mean(cy_ratio, WEIGHTD),
      mean_share_necessities = wtd_mean(share_necessities, WEIGHTD),
      mean_share_shelter = wtd_mean(share_shelter, WEIGHTD),
      mean_share_discretionary = wtd_mean(share_discretionary, WEIGHTD),
      mean_share_food = wtd_mean(share_food, WEIGHTD),
      mean_share_health = wtd_mean(share_health, WEIGHTD),
      mean_share_clothing = wtd_mean(share_clothing, WEIGHTD),
      mean_share_transport = wtd_mean(share_transport, WEIGHTD),
      mean_shelter_over_inc = wtd_mean(shelter_over_inc, WEIGHTD),
      mean_mortpay_over_inc = wtd_mean(mortpay_over_inc, WEIGHTD),
      mean_cy_ratio_at = wtd_mean(cy_ratio_at, WEIGHTD),
      .groups = "drop"
    )
}

by_inc <- summarise_consumption(
  shs %>% dplyr::filter(!is.na(inc_q)),
  c("year", "inc_q")
)
by_tenure <- summarise_consumption(
  shs %>% dplyr::filter(!is.na(tenure)),
  c("year", "tenure")
)
by_age <- summarise_consumption(
  shs %>% dplyr::filter(!is.na(age_band)),
  c("year", "age_band")
)
by_region <- summarise_consumption(
  shs_reg,
  c("year", "region")
)
by_inc_tenure <- summarise_consumption(
  shs %>% dplyr::filter(!is.na(inc_q), !is.na(tenure)),
  c("year", "inc_q", "tenure")
)

readr::write_csv(by_inc, file.path(PATHS$tables, "shs_consumption_by_income_quintile.csv"))
readr::write_csv(by_tenure, file.path(PATHS$tables, "shs_consumption_by_tenure.csv"))
readr::write_csv(by_age, file.path(PATHS$tables, "shs_consumption_by_age.csv"))
readr::write_csv(by_region, file.path(PATHS$tables, "shs_consumption_by_region.csv"))
readr::write_csv(by_inc_tenure, file.path(PATHS$tables, "shs_consumption_by_income_x_tenure.csv"))
message("Wrote SHS consumption tables")

# ---- SFS juxtaposition (2019 / 2023 shared cells) --------------------------
# Household (SHS) vs economic family (SFS) — not identical units.

juxt_parts <- list()

sfs_tenure <- file.path(PATHS$tables, "nig_portfolio_by_housing_status_year.csv")
if (file.exists(sfs_tenure)) {
  st <- readr::read_csv(sfs_tenure, show_col_types = FALSE) %>%
    dplyr::filter(year %in% c(2019L, 2023L)) %>%
    dplyr::select(year, tenure = housing_status, sfs_nig_over_inc = nig_over_inc, sfs_debt_asset = debt_asset)
  sh <- by_tenure %>%
    dplyr::filter(year %in% c(2019L, 2023L)) %>%
    dplyr::select(year, tenure, shs_share_necessities = mean_share_necessities,
                  shs_share_shelter = mean_share_shelter, shs_cy_ratio = mean_cy_ratio)
  juxt_parts$tenure <- dplyr::full_join(sh, st, by = c("year", "tenure")) %>%
    dplyr::mutate(cut = "tenure", cell = as.character(tenure))
}

sfs_age <- file.path(PATHS$tables, "nig_portfolio_by_age_band_year.csv")
if (file.exists(sfs_age)) {
  # SHS bands differ from SFS (<35, 35-44, …). Map SHS → closest SFS for join only.
  sa <- readr::read_csv(sfs_age, show_col_types = FALSE) %>%
    dplyr::filter(year %in% c(2019L, 2023L)) %>%
    dplyr::select(year, age_band_sfs = age_band, sfs_nig_over_inc = nig_over_inc, sfs_debt_asset = debt_asset)
  sh_age <- by_age %>%
    dplyr::filter(year %in% c(2019L, 2023L)) %>%
    dplyr::mutate(
      # Closest SFS bands for juxtaposition only (primary SHS tables keep native bands)
      age_band_sfs = dplyr::case_when(
        age_band == "<30" ~ "<35",
        age_band == "30-39" ~ "35-44",
        age_band == "40-54" ~ "45-54",
        age_band == "55-64" ~ "55-64",
        age_band %in% c("65-74", "75+") ~ "65+",
        TRUE ~ NA_character_
      )
    ) %>%
    dplyr::group_by(year, age_band_sfs) %>%
    dplyr::summarise(
      shs_share_necessities = stats::weighted.mean(mean_share_necessities, w_sum, na.rm = TRUE),
      shs_share_shelter = stats::weighted.mean(mean_share_shelter, w_sum, na.rm = TRUE),
      shs_cy_ratio = stats::weighted.mean(mean_cy_ratio, w_sum, na.rm = TRUE),
      .groups = "drop"
    )
  juxt_parts$age <- dplyr::full_join(sh_age, sa, by = c("year", "age_band_sfs")) %>%
    dplyr::mutate(cut = "age", cell = as.character(age_band_sfs), tenure = NA_character_)
}

sfs_geo <- file.path(PATHS$tables, "nig_portfolio_by_geo_group_year.csv")
if (file.exists(sfs_geo)) {
  sg <- readr::read_csv(sfs_geo, show_col_types = FALSE) %>%
    dplyr::filter(year %in% c(2019L, 2023L)) %>%
    dplyr::mutate(
      region = dplyr::case_when(
        geo_group == "West Coast" ~ "BC",
        geo_group == "Central" ~ "ON+QC+MB",
        geo_group == "Oil Prairies" ~ "AB+SK",
        geo_group == "East Coast" ~ "Atlantic",
        TRUE ~ NA_character_
      )
    ) %>%
    dplyr::filter(!is.na(region)) %>%
    dplyr::select(year, region, sfs_nig_over_inc = nig_over_inc, sfs_debt_asset = debt_asset)
  sh_g <- by_region %>%
    dplyr::filter(year %in% c(2019L, 2023L)) %>%
    dplyr::select(year, region, shs_share_necessities = mean_share_necessities,
                  shs_share_shelter = mean_share_shelter, shs_cy_ratio = mean_cy_ratio)
  juxt_parts$region <- dplyr::full_join(sh_g, sg, by = c("year", "region")) %>%
    dplyr::mutate(cut = "region", cell = as.character(region), tenure = NA_character_)
}

if (length(juxt_parts)) {
  # Align columns
  juxt <- dplyr::bind_rows(lapply(juxt_parts, function(d) {
    if (!"tenure" %in% names(d)) d$tenure <- NA_character_
    if (!"region" %in% names(d)) d$region <- NA_character_
    if (!"age_band_sfs" %in% names(d)) d$age_band_sfs <- NA_character_
    d %>% dplyr::select(
      cut, year, cell,
      dplyr::any_of(c(
        "tenure", "region", "age_band_sfs",
        "shs_share_necessities", "shs_share_shelter", "shs_cy_ratio",
        "sfs_nig_over_inc", "sfs_debt_asset"
      ))
    )
  }))
  readr::write_csv(juxt, file.path(PATHS$tables, "shs_sfs_juxtaposition_2019_2023.csv"))
  message("Wrote shs_sfs_juxtaposition_2019_2023.csv")
} else {
  message("SFS juxtaposition tables not found; skipping juxtaposition CSV")
}

# ---- Figures ---------------------------------------------------------------

p_nec <- by_inc %>%
  ggplot2::ggplot(ggplot2::aes(x = inc_q, y = mean_share_necessities, fill = factor(year))) +
  ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.8), width = 0.75) +
  ggplot2::facet_wrap(~year) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::labs(
    title = "Necessities share of current consumption (SHS)",
    subtitle = "Necessities = food + shelter + health; income quintiles (not wealth)",
    x = "Household income quintile",
    y = "Share of TC001",
    fill = "Year"
  ) +
  theme_paper() +
  ggplot2::theme(legend.position = "none")

ggplot2::ggsave(
  file.path(PATHS$figures, "shs_necessities_by_income_quintile.png"),
  p_nec, width = 9, height = 5, dpi = 150
)

p_shel_inc <- by_inc %>%
  ggplot2::ggplot(ggplot2::aes(x = inc_q, y = mean_share_shelter, fill = factor(year))) +
  ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.8), width = 0.75) +
  ggplot2::facet_wrap(~year) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::labs(
    title = "Shelter share of current consumption (SHS)",
    subtitle = "By household income quintile",
    x = "Household income quintile",
    y = "SH001 / TC001"
  ) +
  theme_paper() +
  ggplot2::theme(legend.position = "none")

ggplot2::ggsave(
  file.path(PATHS$figures, "shs_shelter_by_income_quintile.png"),
  p_shel_inc, width = 9, height = 5, dpi = 150
)

p_tenure <- dplyr::bind_rows(
  by_tenure %>%
    dplyr::transmute(year, tenure, metric = "Shelter / TC001", value = mean_share_shelter),
  by_tenure %>%
    dplyr::filter(tenure == "owner_mortgage") %>%
    dplyr::transmute(year, tenure, metric = "Mortgage payment / income", value = mean_mortpay_over_inc)
) %>%
  ggplot2::ggplot(ggplot2::aes(x = tenure, y = value, fill = factor(year))) +
  ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.8), width = 0.75) +
  ggplot2::facet_wrap(~metric, scales = "free_y") +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::labs(
    title = "Shelter exposure by tenure (SHS)",
    subtitle = "Mortgage-payment/income only for owners with mortgage",
    x = NULL, y = NULL, fill = "Year"
  ) +
  theme_paper() +
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 25, hjust = 1))

ggplot2::ggsave(
  file.path(PATHS$figures, "shs_shelter_mortgage_by_tenure.png"),
  p_tenure, width = 10, height = 5, dpi = 150
)

p_region <- by_region %>%
  ggplot2::ggplot(ggplot2::aes(x = region, y = mean_share_shelter, fill = factor(year))) +
  ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.8), width = 0.75) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::labs(
    title = "Shelter share of consumption by analytic region (SHS)",
    subtitle = "BC | ON+QC+MB | AB+SK | Atlantic",
    x = NULL, y = "SH001 / TC001", fill = "Year"
  ) +
  theme_paper()

ggplot2::ggsave(
  file.path(PATHS$figures, "shs_shelter_by_region.png"),
  p_region, width = 9, height = 5, dpi = 150
)

# Side-by-side 2019/2023: SFS NIG/income vs SHS necessities by tenure
if (file.exists(file.path(PATHS$tables, "shs_sfs_juxtaposition_2019_2023.csv"))) {
  j <- readr::read_csv(
    file.path(PATHS$tables, "shs_sfs_juxtaposition_2019_2023.csv"),
    show_col_types = FALSE
  ) %>%
    dplyr::filter(cut == "tenure", year %in% c(2019L, 2023L))

  if (nrow(j)) {
    j_long <- j %>%
      tidyr::pivot_longer(
        cols = c(sfs_nig_over_inc, shs_share_necessities),
        names_to = "series",
        values_to = "value"
      ) %>%
      dplyr::mutate(
        series = dplyr::recode(
          series,
          sfs_nig_over_inc = "SFS mean NIG / income",
          shs_share_necessities = "SHS necessities / TC001"
        )
      )

    p_jux <- j_long %>%
      ggplot2::ggplot(ggplot2::aes(x = cell, y = value, fill = factor(year))) +
      ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.8), width = 0.75) +
      ggplot2::facet_wrap(~series, scales = "free_y") +
      ggplot2::labs(
        title = "Two inflation channels by tenure (2019 & 2023)",
        subtitle = "Left: SFS balance-sheet NIG/income; right: SHS basket necessities share\nUnits differ (EFAM vs household); not a single welfare metric",
        x = NULL, y = NULL, fill = "Year"
      ) +
      theme_paper() +
      ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 25, hjust = 1))

    ggplot2::ggsave(
      file.path(PATHS$figures, "shs_sfs_tenure_juxtaposition_2019_2023.png"),
      p_jux, width = 10, height = 5.5, dpi = 150
    )
  }
}

message("Wrote SHS figures to ", PATHS$figures)
message("=== SHS consumption incidence done ===")
