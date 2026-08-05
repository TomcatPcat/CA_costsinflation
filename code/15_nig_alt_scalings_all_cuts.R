# code/15_nig_alt_scalings_all_cuts.R
# Resources / cash-on-hand scalings for every NIG/income group-cut in the gallery
# (tenure, age, age×tenure, geo, province, period-by-group, inflation sensitivity,
#  annualized dodged). Quintile core figures remain in code/14_nig_alt_scalings.R.
#
# Definitions (same as 14 / docs/12_nig_alt_scalings.md):
#   Resources    = INC + NW,  NW = w_wolff
#   Cash-on-hand = INC + LIQ

source("code/00_setup.R")
source("code/utils/accounting.R")

nig_rds <- file.path(PATHS$processed, "sfs_with_nig.rds")
period_file <- file.path(PATHS$external, "period_rates.csv")

if (!file.exists(period_file)) source("code/02_macro_series.R")
if (!file.exists(nig_rds)) {
  message("sfs_with_nig.rds missing; sourcing code/04_inflation_gain.R …")
  source("code/04_inflation_gain.R")
}

sfs <- readRDS(nig_rds)
periods <- readr::read_csv(period_file, show_col_types = FALSE)

# ---- Household denominators ------------------------------------------------
sfs <- sfs %>%
  dplyr::mutate(
    NW = w_wolff,
    resources = INC + NW,
    cash_on_hand = INC + LIQ
  )

# ---- Demographics / geography (same rules as code/08_demo_geo_breakdowns.R) -
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

prov_labels <- c(
  "10" = "NL", "11" = "PE", "12" = "NS", "13" = "NB",
  "24" = "QC", "35" = "ON", "46" = "MB", "47" = "SK",
  "48" = "AB", "59" = "BC"
)

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
    age_band = factor(age_band, levels = c("<35", "35-44", "45-54", "55-64", "65+")),
    province = dplyr::recode(as.character(dem_prov), !!!prov_labels, .default = NA_character_),
    geo_group = dplyr::case_when(
      dem_prov %in% c(59, "59") ~ "West Coast",
      dem_prov %in% c(35, 24, 46, "35", "24", "46") ~ "Central",
      dem_prov %in% c(48, 47, "48", "47") ~ "Oil Prairies",
      dem_prov %in% c(10, 11, 12, 13, "10", "11", "12", "13") ~ "East Coast",
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
    )
  ) %>%
  dplyr::select(-g, -agegrp_max, -agegrp_scheme)

# ---- Helpers (mirror 14) ---------------------------------------------------
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

summarise_alt <- function(df, nig_col, group_vars, year0 = NULL, year1 = NULL, infl = NULL) {
  nig_sym <- rlang::sym(nig_col)
  out <- df %>%
    dplyr::filter(dplyr::if_all(dplyr::all_of(group_vars), ~ !is.na(.x))) %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) %>%
    dplyr::summarise(
      n = dplyr::n(),
      mean_NIG = wtd_mean(!!nig_sym, weight),
      mean_inc = wtd_mean(INC, weight),
      mean_nw = wtd_mean(NW, weight),
      mean_LIQ = wtd_mean(LIQ, weight),
      mean_resources = wtd_mean(resources, weight),
      mean_coh = wtd_mean(cash_on_hand, weight),
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

save_fig <- function(p, outfile_base, width, height) {
  ggplot2::ggsave(
    file.path(PATHS$figures, paste0(outfile_base, ".png")),
    p, width = width, height = height, dpi = 150
  )
  ggplot2::ggsave(
    file.path(PATHS$figures, paste0(outfile_base, ".pdf")),
    p, width = width, height = height
  )
  invisible(p)
}

status_labs <- c(
  owner_mortgage = "Owner\nmortgage",
  owner_free_clear = "Owner\nfree & clear",
  renter = "Renter"
)
geo_levels_main <- c("West Coast", "Central", "Oil Prairies", "East Coast")
prov_levels <- c("BC", "AB", "SK", "MB", "ON", "QC", "NB", "NS", "PE", "NL")
age_levels <- c("<35", "35-44", "45-54", "55-64", "65+")

scale_meta <- list(
  resources = list(
    y = "nig_over_resources",
    ylab = "NIG / mean resources",
    label = "resources",
    file_tag = "resources",
    subtitle_snap = "Resources = mean income + mean Wolff NW (ratio of means)"
  ),
  coh = list(
    y = "nig_over_coh",
    ylab = "NIG / mean cash-on-hand",
    label = "cash-on-hand",
    file_tag = "cash_on_hand",
    subtitle_snap = "Cash-on-hand = mean income + mean LIQ (ratio of means)"
  )
)

# ---- Latest-year group cuts ------------------------------------------------
latest <- max(sfs$year, na.rm = TRUE)
sfs_latest <- sfs %>% dplyr::filter(year == latest)

latest_cuts <- list(
  tenure = list(
    vars = "housing_status",
    file = "nig_alt_scalings_latest_tenure.csv",
    fig_stub = "by_tenure_latest"
  ),
  age = list(
    vars = "age_band",
    file = "nig_alt_scalings_latest_age.csv",
    fig_stub = "by_age_latest"
  ),
  age_tenure = list(
    vars = c("age_band", "housing_status"),
    file = "nig_alt_scalings_latest_age_tenure.csv",
    fig_stub = "by_age_tenure_latest"
  ),
  geo_group = list(
    vars = "geo_group",
    file = "nig_alt_scalings_latest_geo_group.csv",
    fig_stub = "by_geo_group_latest"
  ),
  province = list(
    vars = "province",
    file = "nig_alt_scalings_latest_province.csv",
    fig_stub = "by_province_latest"
  )
)

latest_tables <- list()
for (nm in names(latest_cuts)) {
  cut <- latest_cuts[[nm]]
  tbl <- summarise_alt(sfs_latest, "NIG_ann", cut$vars) %>%
    dplyr::mutate(year = latest, .before = 1)
  readr::write_csv(tbl, file.path(PATHS$tables, cut$file))
  latest_tables[[nm]] <- tbl
}

# Tenure bars
ten <- latest_tables$tenure %>%
  dplyr::mutate(housing_status = factor(housing_status, levels = names(status_labs)))
for (sc in scale_meta) {
  p <- ten %>%
    ggplot2::ggplot(ggplot2::aes(x = housing_status, y = .data[[sc$y]], fill = housing_status)) +
    ggplot2::geom_col(show.legend = FALSE) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
    ggplot2::scale_x_discrete(labels = status_labs) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    ggplot2::scale_fill_manual(values = c("#8c2d04", "#ec7014", "#fec44f")) +
    ggplot2::labs(
      title = paste0("NIG / ", sc$label, " by housing tenure (", latest, ")"),
      subtitle = paste0(sc$subtitle_snap, "; core IG − IT"),
      x = NULL, y = sc$ylab
    ) +
    theme_paper()
  save_fig(p, paste0("nig_over_", sc$file_tag, "_by_tenure_latest"), 7, 4.5)
}

# Age bars
age_lat <- latest_tables$age %>%
  dplyr::mutate(age_band = factor(age_band, levels = age_levels))
for (sc in scale_meta) {
  p <- age_lat %>%
    ggplot2::ggplot(ggplot2::aes(x = age_band, y = .data[[sc$y]])) +
    ggplot2::geom_col(fill = "#1f4e79") +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    ggplot2::labs(
      title = paste0("NIG / ", sc$label, " by age band (", latest, ")"),
      subtitle = sc$subtitle_snap,
      x = "Age of major income earner", y = sc$ylab
    ) +
    theme_paper()
  save_fig(p, paste0("nig_over_", sc$file_tag, "_by_age_latest"), 7, 4.5)
}

# Age × tenure dodged
at <- latest_tables$age_tenure %>%
  dplyr::mutate(
    age_band = factor(age_band, levels = age_levels),
    housing_status = factor(housing_status, levels = names(status_labs))
  )
for (sc in scale_meta) {
  p <- at %>%
    ggplot2::ggplot(ggplot2::aes(x = age_band, y = .data[[sc$y]], fill = housing_status)) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    ggplot2::scale_fill_manual(
      values = c(owner_mortgage = "#8c2d04", owner_free_clear = "#ec7014", renter = "#fec44f"),
      labels = c(owner_mortgage = "Mortgage", owner_free_clear = "Free & clear", renter = "Renter")
    ) +
    ggplot2::labs(
      title = paste0("NIG / ", sc$label, " by age × tenure (", latest, ")"),
      subtitle = sc$subtitle_snap,
      x = "Age band", y = sc$ylab, fill = NULL
    ) +
    theme_paper()
  save_fig(p, paste0("nig_over_", sc$file_tag, "_by_age_tenure_latest"), 8.5, 4.8)
}

# Analytic region
geo_lat <- latest_tables$geo_group %>%
  dplyr::filter(as.character(geo_group) %in% geo_levels_main) %>%
  dplyr::mutate(geo_group = factor(as.character(geo_group), levels = geo_levels_main))
for (sc in scale_meta) {
  p <- geo_lat %>%
    ggplot2::ggplot(ggplot2::aes(x = geo_group, y = .data[[sc$y]])) +
    ggplot2::geom_col(fill = "#1f4e79") +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    ggplot2::labs(
      title = paste0("NIG / ", sc$label, " by analytic region (", latest, ")"),
      subtitle = paste0(
        sc$subtitle_snap, "; West Coast=BC; Central=ON/QC/MB; Oil Prairies=AB/SK; East Coast=Atlantic"
      ),
      x = NULL, y = sc$ylab
    ) +
    theme_paper() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 20, hjust = 1))
  save_fig(p, paste0("nig_over_", sc$file_tag, "_by_geo_group_latest"), 7.5, 4.5)
}

# Province
prov_lat <- latest_tables$province %>%
  dplyr::mutate(province = factor(province, levels = prov_levels))
for (sc in scale_meta) {
  p <- prov_lat %>%
    ggplot2::ggplot(ggplot2::aes(x = province, y = .data[[sc$y]])) +
    ggplot2::geom_col(fill = "#1f4e79") +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    ggplot2::labs(
      title = paste0("NIG / ", sc$label, " by province (", latest, ")"),
      subtitle = sc$subtitle_snap,
      x = NULL, y = sc$ylab
    ) +
    theme_paper()
  save_fig(p, paste0("nig_over_", sc$file_tag, "_by_province_latest"), 8, 4.5)
}

# ---- Period cuts (age, geo; portfolios fixed at year0) ---------------------
period_cuts <- c("age_band", "geo_group")
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
      d_bnd = duration_reval(BND, r_n1 - r_n0, pmax(r_n0, 0.01), duration = 8),
      d_liq = -LIQ * infl,
      d_dbt = DBT * infl,
      IG_per = d_stk + d_bus + d_bnd + d_liq + d_dbt,
      IT_per = INC * infl,
      NIG_per = IG_per - IT_per,
      period = paste0(y0, "-", y1)
    )

  for (cut in period_cuts) {
    period_store[[cut]][[length(period_store[[cut]]) + 1]] <-
      summarise_alt(base, "NIG_per", c("period", cut), year0 = y0, year1 = y1, infl = infl)
  }
}

age_per <- dplyr::bind_rows(period_store$age_band) %>%
  dplyr::mutate(age_band = factor(age_band, levels = age_levels))
readr::write_csv(
  age_per,
  file.path(PATHS$tables, "nig_alt_scalings_by_period_age.csv")
)

geo_per <- dplyr::bind_rows(period_store$geo_group) %>%
  dplyr::filter(as.character(geo_group) %in% geo_levels_main) %>%
  dplyr::mutate(geo_group = factor(as.character(geo_group), levels = geo_levels_main))
readr::write_csv(
  dplyr::bind_rows(period_store$geo_group),
  file.path(PATHS$tables, "nig_alt_scalings_by_period_geo_group.csv")
)

for (sc in scale_meta) {
  p <- age_per %>%
    ggplot2::ggplot(ggplot2::aes(x = age_band, y = .data[[sc$y]], fill = age_band)) +
    ggplot2::geom_col(show.legend = FALSE) +
    ggplot2::facet_wrap(~period) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    ggplot2::labs(
      title = paste0("Period NIG / ", sc$label, " by age band"),
      subtitle = paste0(sc$label, "; portfolios fixed at period start"),
      x = NULL, y = sc$ylab
    ) +
    theme_paper() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 35, hjust = 1, size = 8))
  save_fig(p, paste0("nig_over_", sc$file_tag, "_by_age_periods"), 9.5, 6)

  p <- geo_per %>%
    ggplot2::ggplot(ggplot2::aes(x = geo_group, y = .data[[sc$y]], fill = geo_group)) +
    ggplot2::geom_col(show.legend = FALSE) +
    ggplot2::facet_wrap(~period) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    ggplot2::labs(
      title = paste0("Period NIG / ", sc$label, " by analytic region"),
      subtitle = paste0(sc$label, "; portfolios fixed at period start"),
      x = NULL, y = sc$ylab
    ) +
    theme_paper() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 35, hjust = 1, size = 8))
  save_fig(p, paste0("nig_over_", sc$file_tag, "_by_geo_group_periods"), 9.5, 6)
}

# ---- Inflation sensitivity (latest portfolios; alt denominators) -----------
sens_year <- latest
sens_base <- sfs_latest
r_nom_s <- median(sens_base$r_nom, na.rm = TRUE)
sens_rates <- c(0.02, 0.04, 0.06, 0.08, 0.10)

sens_rows <- lapply(sens_rates, function(inf) {
  r_real_s <- r_nom_s - inf
  tmp <- sens_base %>%
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
    )
  summarise_alt(tmp, "NIG", c("INF_cf", "wealth_q")) %>%
    dplyr::mutate(year = sens_year)
})
nig_sens_alt <- dplyr::bind_rows(sens_rows)
readr::write_csv(
  nig_sens_alt,
  file.path(PATHS$tables, "nig_alt_scalings_inflation_sensitivity.csv")
)

q_levels <- c("Q1", "Q2", "Q3", "Q4", "Q5")
for (sc in scale_meta) {
  p <- nig_sens_alt %>%
    dplyr::mutate(wealth_q = factor(wealth_q, levels = q_levels)) %>%
    ggplot2::ggplot(ggplot2::aes(x = INF_cf, y = .data[[sc$y]], colour = wealth_q)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_point(size = 2) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
    ggplot2::scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    ggplot2::labs(
      title = paste0("NIG / ", sc$label, " vs counterfactual inflation (", sens_year, ")"),
      subtitle = sc$subtitle_snap,
      x = "Assumed annual inflation",
      y = sc$ylab,
      colour = "Wealth quintile"
    ) +
    theme_paper()
  save_fig(p, paste0("nig_inflation_sensitivity_", sc$file_tag), 7.5, 4.5)
}

# ---- Annualized dodged (quintile; from 14 tables) --------------------------
ann_file <- file.path(PATHS$tables, "nig_alt_scalings_annualized_by_quintile.csv")
if (file.exists(ann_file)) {
  nig_all_ann <- readr::read_csv(ann_file, show_col_types = FALSE)
  for (sc in list(
    list(y = "nig_over_resources_ann", label = "resources", file_tag = "resources", ylab = "Annualized NIG / mean resources"),
    list(y = "nig_over_coh_ann", label = "cash-on-hand", file_tag = "cash_on_hand", ylab = "Annualized NIG / mean cash-on-hand")
  )) {
    if (!sc$y %in% names(nig_all_ann)) next
    p <- nig_all_ann %>%
      dplyr::mutate(
        wealth_q = factor(wealth_q, levels = q_levels),
        period = factor(period, levels = unique(period[order(year0, period)]))
      ) %>%
      ggplot2::ggplot(ggplot2::aes(x = wealth_q, y = .data[[sc$y]], fill = period)) +
      ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.85), width = 0.8) +
      ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
      ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
      ggplot2::labs(
        title = paste0("Annualized NIG / ", sc$label, ": periods vs full span"),
        subtitle = "Same geometric annualization as income charts; see docs/12_nig_alt_scalings.md",
        x = "Wealth quintile",
        y = sc$ylab,
        fill = NULL
      ) +
      theme_paper()
    save_fig(p, paste0("nig_over_", sc$file_tag, "_by_quintile_annualized_dodged"), 10, 5)
  }
} else {
  warning("Missing ", ann_file, "; skip annualized dodged alt figures (run 14 first).")
}

message("Wrote demo/geo/sensitivity NIG alternative-scaling tables and figures.")
message("  See docs/12_nig_alt_scalings.md")
