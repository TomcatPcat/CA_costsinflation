# code/08_demo_geo_breakdowns.R
# Age, tenure (housing_status), province, and custom regional groupings
# for NIG / portfolio / wealth. CMA not available on SFS EFAM PUMF.

source("code/00_setup.R")
source("code/utils/accounting.R")

nig_file <- file.path(PATHS$processed, "sfs_with_nig.rds")
port_file <- file.path(PATHS$processed, "sfs_portfolio.rds")
period_file <- file.path(PATHS$external, "period_rates.csv")

if (!file.exists(period_file)) source("code/02_macro_series.R")
if (!file.exists(nig_file)) {
  if (!file.exists(port_file)) {
    source("code/01_build_sfs_panel.R")
    source("code/03_portfolio_map.R")
  }
  source("code/04_inflation_gain.R")
}

sfs <- readRDS(nig_file)
periods <- readr::read_csv(period_file, show_col_types = FALSE)

# Ensure housing_status (older RDS)
if (!"housing_status" %in% names(sfs)) {
  sfs <- sfs %>%
    dplyr::mutate(
      owner = as.integer(
        dem_fam_tenure %in% c(1, "1", "Owned", "owned") |
          (!is.na(w_hous_princ_res_val) & w_hous_princ_res_val > 0)
      ),
      housing_status = dplyr::case_when(
        owner == 1 & debt_mort_princ_res_val > 0 ~ "owner_mortgage",
        owner == 1 ~ "owner_free_clear",
        TRUE ~ "renter"
      )
    )
}

# ---- Harmonized demographics / geography -----------------------------------

prov_labels <- c(
  "10" = "NL", "11" = "PE", "12" = "NS", "13" = "NB",
  "24" = "QC", "35" = "ON", "46" = "MB", "47" = "SK",
  "48" = "AB", "59" = "BC"
)
region_labels <- c(
  "1" = "Atlantic", "2" = "Quebec", "3" = "Ontario",
  "4" = "Prairies", "5" = "British Columbia"
)

# StatCan PREGION codes (PUMF): 1 Atlantic, 2 QC, 3 ON, 4 Prairies, 5 BC
# Custom analytic regions (user-specified; MB with Central, not oil Prairies):
#   West Coast: BC
#   Central: ON, QC, MB
#   Oil-producing Prairies: AB, SK
#   East Coast/Maritimes: NL, PE, NS, NB
# Note: 2005 has dem_region but dem_prov entirely missing on this panel —
# use region fallback; Prairies cannot be split into Central(MB) vs Oil.

# Age bands: prefer continuous age (available through 2016).
# 2019: age missing; agegrp is 14 five-year bands.
# 2023: age missing; agegrp is 7 StatCan groups (PAGEMIEG).
# Detect scheme by year-level max(agegrp), not by individual code (1–7 overlap).
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
      # 2023-style: 1 <25, 2 25-34, 3 35-44, 4 45-54, 5 55-64, 6 65-79, 7 80+
      agegrp_scheme == "g7" & g %in% 1:2 ~ "<35",
      agegrp_scheme == "g7" & g == 3 ~ "35-44",
      agegrp_scheme == "g7" & g == 4 ~ "45-54",
      agegrp_scheme == "g7" & g == 5 ~ "55-64",
      agegrp_scheme == "g7" & g %in% 6:7 ~ "65+",
      # 14 five-year bands: 1=16-19 ... 14=80+
      agegrp_scheme == "g14" & g %in% 1:4 ~ "<35",
      agegrp_scheme == "g14" & g %in% 5:6 ~ "35-44",
      agegrp_scheme == "g14" & g %in% 7:8 ~ "45-54",
      agegrp_scheme == "g14" & g %in% 9:10 ~ "55-64",
      agegrp_scheme == "g14" & g %in% 11:14 ~ "65+",
      TRUE ~ NA_character_
    ),
    age_band = factor(age_band, levels = c("<35", "35-44", "45-54", "55-64", "65+")),
    prov_code = as.character(dem_prov),
    province = dplyr::recode(prov_code, !!!prov_labels, .default = NA_character_),
    sfs_region = dplyr::recode(
      as.character(dem_region), !!!region_labels, .default = NA_character_
    ),
    # Preferred: province-based custom groups
    geo_group = dplyr::case_when(
      dem_prov %in% c(59, "59") ~ "West Coast",
      dem_prov %in% c(35, 24, 46, "35", "24", "46") ~ "Central",
      dem_prov %in% c(48, 47, "48", "47") ~ "Oil Prairies",
      dem_prov %in% c(10, 11, 12, 13, "10", "11", "12", "13") ~ "East Coast",
      # 2005 fallback (no province): unambiguous regions only
      is.na(dem_prov) & dem_region %in% c(5, "5") ~ "West Coast",
      is.na(dem_prov) & dem_region %in% c(1, "1") ~ "East Coast",
      is.na(dem_prov) & dem_region %in% c(2, 3, "2", "3") ~ "Central",
      is.na(dem_prov) & dem_region %in% c(4, "4") ~ "Prairies unsplit",
      TRUE ~ NA_character_
    ),
    geo_group = factor(
      geo_group,
      levels = c("West Coast", "Central", "Oil Prairies", "East Coast", "Prairies unsplit")
    ),
    housing_status = factor(
      housing_status,
      levels = c("owner_mortgage", "owner_free_clear", "renter")
    ),
    assets_tot = STK + BND + LIQ + BUS + HOUS + OTH_NF
  ) %>%
  dplyr::select(-g, -agegrp_max, -agegrp_scheme)

# CMA check (document absence)
cma_cols <- grep("cma|cmaca|pcma", names(sfs), ignore.case = TRUE, value = TRUE)
has_cma <- length(cma_cols) > 0
cma_note <- tibble::tibble(
  variable = "CMA / major city",
  available_on_pumf = has_cma,
  note = if (has_cma) {
    paste("Found columns:", paste(cma_cols, collapse = ", "))
  } else {
    paste(
      "No CMA/city identifier on SFS EFAM PUMF panel (checked colnames).",
      "Geography limited to province (ppvres/dem_prov) and StatCan region",
      "(pregion/dem_region: Atlantic, Quebec, Ontario, Prairies, BC).",
      "Province missing for all 2005 observations in this panel;",
      "custom geo_group uses dem_region fallback (Prairies left unsplit)."
    )
  }
)
readr::write_csv(cma_note, file.path(PATHS$tables, "geo_availability_note.csv"))

# ---- Summarisers -----------------------------------------------------------

summarise_stock <- function(df, group_vars) {
  df %>%
    dplyr::filter(dplyr::if_all(dplyr::all_of(group_vars), ~ !is.na(.x))) %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) %>%
    dplyr::summarise(
      n = dplyr::n(),
      w_sum = sum(weight, na.rm = TRUE),
      mean_nw = wtd_mean(w_wolff, weight),
      median_nw = wtd_quantile(w_wolff, weight, 0.5),
      mean_inc = wtd_mean(INC, weight),
      mean_STK = wtd_mean(STK, weight),
      mean_BND = wtd_mean(BND, weight),
      mean_LIQ = wtd_mean(LIQ, weight),
      mean_BUS = wtd_mean(BUS, weight),
      mean_HOUS = wtd_mean(HOUS, weight),
      mean_DBT = wtd_mean(DBT, weight),
      debt_asset = wtd_mean(DBT, weight) / pmax(wtd_mean(assets_tot, weight), 1),
      mean_IG = wtd_mean(IG_ann, weight),
      mean_IT = wtd_mean(IT_ann, weight),
      mean_NIG = wtd_mean(NIG_ann, weight),
      nig_over_inc = mean_NIG / pmax(mean_inc, 1),
      .groups = "drop"
    )
}

# Snapshot tables: all survey years
cuts <- list(
  age_band = c("year", "age_band"),
  housing_status = c("year", "housing_status"),
  province = c("year", "province"),
  sfs_region = c("year", "sfs_region"),
  geo_group = c("year", "geo_group")
)

for (nm in names(cuts)) {
  tbl <- summarise_stock(sfs, cuts[[nm]])
  readr::write_csv(tbl, file.path(PATHS$tables, paste0("nig_portfolio_by_", nm, "_year.csv")))
}

latest <- max(sfs$year, na.rm = TRUE)
sfs_latest <- sfs %>% dplyr::filter(year == latest)

for (nm in names(cuts)) {
  gvars <- setdiff(cuts[[nm]], "year")
  tbl <- summarise_stock(sfs_latest, gvars) %>%
    dplyr::mutate(year = latest, .before = 1)
  readr::write_csv(tbl, file.path(PATHS$tables, paste0("nig_portfolio_by_", nm, "_latest.csv")))
}

# Age × tenure (latest) — gap view
age_tenure_latest <- summarise_stock(sfs_latest, c("age_band", "housing_status")) %>%
  dplyr::mutate(year = latest, .before = 1)
readr::write_csv(age_tenure_latest, file.path(PATHS$tables, "nig_portfolio_by_age_tenure_latest.csv"))

# Geo group × wealth quintile (latest)
geo_q_latest <- summarise_stock(sfs_latest, c("geo_group", "wealth_q")) %>%
  dplyr::mutate(year = latest, .before = 1)
readr::write_csv(geo_q_latest, file.path(PATHS$tables, "nig_by_geo_group_wealth_q_latest.csv"))

# ---- Period NIG by demo/geo groups -----------------------------------------

period_summarise <- function(base, group_vars, y0, y1, infl) {
  base %>%
    dplyr::filter(dplyr::if_all(dplyr::all_of(group_vars), ~ !is.na(.x))) %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) %>%
    dplyr::summarise(
      period = paste0(y0, "-", y1),
      year0 = y0, year1 = y1,
      n = dplyr::n(),
      infl_cum = infl,
      mean_nw0 = wtd_mean(w_wolff, weight),
      mean_inc = wtd_mean(INC, weight),
      mean_IG = wtd_mean(IG_per, weight),
      mean_IT = wtd_mean(IT_per, weight),
      mean_NIG = wtd_mean(NIG_per, weight),
      nig_over_inc = mean_NIG / pmax(mean_inc, 1),
      debt_asset = wtd_mean(DBT, weight) / pmax(wtd_mean(assets_tot, weight), 1),
      .groups = "drop"
    )
}

period_cuts <- c("age_band", "housing_status", "province", "geo_group", "sfs_region")
period_store <- setNames(vector("list", length(period_cuts)), period_cuts)

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
      d_bnd = duration_reval(BND, r_n1 - r_n0, pmax(r_n0, 0.01), 8),
      d_liq = -LIQ * infl,
      d_dbt = DBT * infl,
      IG_per = d_stk + d_bus + d_bnd + d_liq + d_dbt,
      IT_per = INC * infl,
      NIG_per = IG_per - IT_per
    )

  for (cut in period_cuts) {
    period_store[[cut]][[length(period_store[[cut]]) + 1]] <-
      period_summarise(base, cut, y0, y1, infl)
  }
}

for (cut in period_cuts) {
  tbl <- dplyr::bind_rows(period_store[[cut]])
  readr::write_csv(tbl, file.path(PATHS$tables, paste0("nig_by_period_", cut, ".csv")))
}

# ---- Figures ---------------------------------------------------------------

status_labs <- c(
  owner_mortgage = "Owner\nmortgage",
  owner_free_clear = "Owner\nfree & clear",
  renter = "Renter"
)

# NIG / income by age (latest)
age_lat <- readr::read_csv(
  file.path(PATHS$tables, "nig_portfolio_by_age_band_latest.csv"),
  show_col_types = FALSE
)
p_age <- age_lat %>%
  ggplot2::ggplot(ggplot2::aes(x = age_band, y = nig_over_inc)) +
  ggplot2::geom_col(fill = "#1f4e79") +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::labs(
    title = paste0("NIG / income by age band (", latest, ")"),
    subtitle = "SFS; Wolff-style IG − IT (ratio of means)",
    x = "Age of major income earner", y = "NIG / mean income"
  ) +
  theme_paper()
ggplot2::ggsave(
  file.path(PATHS$figures, "nig_by_age_latest.png"),
  p_age, width = 7, height = 4.5, dpi = 150
)

# Leverage by age (latest)
p_age_lev <- age_lat %>%
  ggplot2::ggplot(ggplot2::aes(x = age_band, y = debt_asset)) +
  ggplot2::geom_col(fill = "#4d4d4d") +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::labs(
    title = paste0("Debt / assets by age band (", latest, ")"),
    x = "Age of major income earner", y = "Debt / assets"
  ) +
  theme_paper()
ggplot2::ggsave(
  file.path(PATHS$figures, "debt_asset_by_age_latest.png"),
  p_age_lev, width = 7, height = 4.5, dpi = 150
)

# NIG by tenure (latest) — complements housing-channel figures in 07
ten_lat <- readr::read_csv(
  file.path(PATHS$tables, "nig_portfolio_by_housing_status_latest.csv"),
  show_col_types = FALSE
) %>%
  dplyr::mutate(housing_status = factor(housing_status, levels = names(status_labs)))
p_ten <- ten_lat %>%
  ggplot2::ggplot(ggplot2::aes(x = housing_status, y = nig_over_inc, fill = housing_status)) +
  ggplot2::geom_col(show.legend = FALSE) +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
  ggplot2::scale_x_discrete(labels = status_labs) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::scale_fill_manual(values = c("#8c2d04", "#ec7014", "#fec44f")) +
  ggplot2::labs(
    title = paste0("NIG / income by housing tenure (", latest, ")"),
    subtitle = "Core IG − IT (excludes mortgage-rate house-price channel)",
    x = NULL, y = "NIG / mean income"
  ) +
  theme_paper()
ggplot2::ggsave(
  file.path(PATHS$figures, "nig_by_tenure_latest.png"),
  p_ten, width = 7, height = 4.5, dpi = 150
)

# NIG by custom geo group (latest)
geo_lat <- readr::read_csv(
  file.path(PATHS$tables, "nig_portfolio_by_geo_group_latest.csv"),
  show_col_types = FALSE
) %>%
  dplyr::filter(geo_group %in% c("West Coast", "Central", "Oil Prairies", "East Coast")) %>%
  dplyr::mutate(
    geo_group = factor(
      geo_group,
      levels = c("West Coast", "Central", "Oil Prairies", "East Coast")
    )
  )
p_geo <- geo_lat %>%
  ggplot2::ggplot(ggplot2::aes(x = geo_group, y = nig_over_inc)) +
  ggplot2::geom_col(fill = "#1f4e79") +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::labs(
    title = paste0("NIG / income by analytic region (", latest, ")"),
    subtitle = "West Coast=BC; Central=ON/QC/MB; Oil Prairies=AB/SK; East Coast=Atlantic",
    x = NULL, y = "NIG / mean income"
  ) +
  theme_paper() +
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 20, hjust = 1))
ggplot2::ggsave(
  file.path(PATHS$figures, "nig_by_geo_group_latest.png"),
  p_geo, width = 7.5, height = 4.5, dpi = 150
)

# Wealth (mean) by province (latest)
prov_lat <- readr::read_csv(
  file.path(PATHS$tables, "nig_portfolio_by_province_latest.csv"),
  show_col_types = FALSE
) %>%
  dplyr::mutate(
    province = factor(
      province,
      levels = c("BC", "AB", "SK", "MB", "ON", "QC", "NB", "NS", "PE", "NL")
    )
  )
p_prov_w <- prov_lat %>%
  ggplot2::ggplot(ggplot2::aes(x = province, y = mean_nw)) +
  ggplot2::geom_col(fill = "#2c7fb8") +
  ggplot2::scale_y_continuous(labels = scales::dollar_format(scale = 1e-3, suffix = "k")) +
  ggplot2::labs(
    title = paste0("Mean Wolff net worth by province (", latest, ")"),
    x = NULL, y = "Mean net worth (CAD)"
  ) +
  theme_paper()
ggplot2::ggsave(
  file.path(PATHS$figures, "wealth_by_province_latest.png"),
  p_prov_w, width = 8, height = 4.5, dpi = 150
)

p_prov_nig <- prov_lat %>%
  ggplot2::ggplot(ggplot2::aes(x = province, y = nig_over_inc)) +
  ggplot2::geom_col(fill = "#1f4e79") +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::labs(
    title = paste0("NIG / income by province (", latest, ")"),
    x = NULL, y = "NIG / mean income"
  ) +
  theme_paper()
ggplot2::ggsave(
  file.path(PATHS$figures, "nig_by_province_latest.png"),
  p_prov_nig, width = 8, height = 4.5, dpi = 150
)

# Period NIG by geo group (facet)
geo_per <- readr::read_csv(
  file.path(PATHS$tables, "nig_by_period_geo_group.csv"),
  show_col_types = FALSE
) %>%
  dplyr::filter(geo_group %in% c("West Coast", "Central", "Oil Prairies", "East Coast")) %>%
  dplyr::mutate(
    geo_group = factor(
      geo_group,
      levels = c("West Coast", "Central", "Oil Prairies", "East Coast")
    )
  )
p_geo_per <- geo_per %>%
  ggplot2::ggplot(ggplot2::aes(x = geo_group, y = nig_over_inc, fill = geo_group)) +
  ggplot2::geom_col(show.legend = FALSE) +
  ggplot2::facet_wrap(~period) +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::labs(
    title = "Period NIG / income by analytic region",
    subtitle = "Portfolios fixed at period start",
    x = NULL, y = "NIG / mean income"
  ) +
  theme_paper() +
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 35, hjust = 1, size = 8))
ggplot2::ggsave(
  file.path(PATHS$figures, "nig_period_by_geo_group.png"),
  p_geo_per, width = 9.5, height = 6, dpi = 150
)

# Period NIG by age
age_per <- readr::read_csv(
  file.path(PATHS$tables, "nig_by_period_age_band.csv"),
  show_col_types = FALSE
) %>%
  dplyr::mutate(age_band = factor(age_band, levels = c("<35", "35-44", "45-54", "55-64", "65+")))
p_age_per <- age_per %>%
  ggplot2::ggplot(ggplot2::aes(x = age_band, y = nig_over_inc, fill = age_band)) +
  ggplot2::geom_col(show.legend = FALSE) +
  ggplot2::facet_wrap(~period) +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::labs(
    title = "Period NIG / income by age band",
    x = NULL, y = "NIG / mean income"
  ) +
  theme_paper() +
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 35, hjust = 1, size = 8))
ggplot2::ggsave(
  file.path(PATHS$figures, "nig_period_by_age.png"),
  p_age_per, width = 9.5, height = 6, dpi = 150
)

# Age × tenure NIG heatmap-style bars (latest)
p_at <- age_tenure_latest %>%
  dplyr::mutate(
    housing_status = factor(housing_status, levels = names(status_labs))
  ) %>%
  ggplot2::ggplot(ggplot2::aes(x = age_band, y = nig_over_inc, fill = housing_status)) +
  ggplot2::geom_col(position = "dodge") +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  ggplot2::scale_fill_manual(
    values = c(owner_mortgage = "#8c2d04", owner_free_clear = "#ec7014", renter = "#fec44f"),
    labels = c(owner_mortgage = "Mortgage", owner_free_clear = "Free & clear", renter = "Renter")
  ) +
  ggplot2::labs(
    title = paste0("NIG / income by age × tenure (", latest, ")"),
    x = "Age band", y = "NIG / mean income", fill = NULL
  ) +
  theme_paper()
ggplot2::ggsave(
  file.path(PATHS$figures, "nig_by_age_tenure_latest.png"),
  p_at, width = 8.5, height = 4.8, dpi = 150
)

# Mean NW by geo over survey years
geo_yr <- readr::read_csv(
  file.path(PATHS$tables, "nig_portfolio_by_geo_group_year.csv"),
  show_col_types = FALSE
) %>%
  dplyr::filter(geo_group %in% c("West Coast", "Central", "Oil Prairies", "East Coast")) %>%
  dplyr::mutate(
    geo_group = factor(
      geo_group,
      levels = c("West Coast", "Central", "Oil Prairies", "East Coast")
    )
  )
p_geo_w <- geo_yr %>%
  ggplot2::ggplot(ggplot2::aes(x = year, y = mean_nw, colour = geo_group)) +
  ggplot2::geom_line(linewidth = 1) +
  ggplot2::geom_point(size = 2) +
  ggplot2::scale_y_continuous(labels = scales::dollar_format(scale = 1e-3, suffix = "k")) +
  ggplot2::scale_x_continuous(breaks = SURVEY_YEARS) +
  ggplot2::labs(
    title = "Mean Wolff net worth by analytic region",
    x = NULL, y = "Mean net worth (CAD)", colour = NULL
  ) +
  theme_paper()
ggplot2::ggsave(
  file.path(PATHS$figures, "wealth_by_geo_group_years.png"),
  p_geo_w, width = 8, height = 4.5, dpi = 150
)

message("Wrote demo/geo NIG-portfolio tables and figures (age, tenure, province, geo_group)")
message("CMA on PUMF: ", if (has_cma) "YES" else "NO (documented in geo_availability_note.csv)")
