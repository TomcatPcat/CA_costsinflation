# code/03_portfolio_map.R — consolidated STK / BND / LIQ / BUS / HOUS / DBT

source("code/00_setup.R")

panel_file <- file.path(PATHS$processed, "sfs_wolff_panel.rds")
if (!file.exists(panel_file)) source("code/01_build_sfs_panel.R")
sfs <- readRDS(panel_file)

sfs <- sfs %>%
  dplyr::mutate(
    # Direct holdings
    stk_direct = w_stocks,
    bnd_direct = w_bonds,
    liq_direct = w_bank_acc,
    # Mutual funds split
    stk_mf = SHARES$mf_equity * w_mut_funds,
    bnd_mf = SHARES$mf_bond * w_mut_funds,
    # Registered (RRSP + RRIF + TFSA + other retirement) split
    reg_total = w_rrsp + w_rrif + w_tfsa + w_oth_ret_funds,
    stk_reg = SHARES$reg_equity * reg_total,
    bnd_reg = SHARES$reg_bond * reg_total,
    liq_reg = SHARES$reg_liquid * reg_total,
    # Other investments: treat as 50/50 equity/bond
    stk_oth = 0.5 * w_oth_inv,
    bnd_oth = 0.5 * w_oth_inv,
    # Consolidated buckets (Wolff-style)
    STK = stk_direct + stk_mf + stk_reg + stk_oth,
    BND = bnd_direct + bnd_mf + bnd_reg + bnd_oth,
    LIQ = liq_direct + liq_reg,
    BUS = w_bus_val,
    HOUS = w_hous_princ_res_val + w_hous_oth_real_est,
    OTH_NF = w_oth_nonfin,
    DBT = debt_wolff,
    INC = inc_it,
    # Check identity (approx)
    assets_consol = STK + BND + LIQ + BUS + HOUS + OTH_NF,
    nw_consol = assets_consol - DBT
  )

# Wealth class within each survey year (weighted quintiles of w_wolff)
assign_wealth_class <- function(df) {
  df %>%
    dplyr::group_by(year) %>%
    dplyr::group_modify(~ {
      x <- .x
      qs <- tryCatch(
        wtd_quantile(x$w_wolff, x$weight, probs = c(0.2, 0.4, 0.6, 0.8, 0.9, 0.95, 0.99)),
        error = function(e) rep(NA_real_, 7)
      )
      names(qs) <- c("p20", "p40", "p60", "p80", "p90", "p95", "p99")
      x$w_p20 <- qs["p20"]; x$w_p40 <- qs["p40"]; x$w_p60 <- qs["p60"]
      x$w_p80 <- qs["p80"]; x$w_p90 <- qs["p90"]; x$w_p95 <- qs["p95"]
      x$w_p99 <- qs["p99"]
      x$wealth_q <- dplyr::case_when(
        x$w_wolff <= qs["p20"] ~ "Q1",
        x$w_wolff <= qs["p40"] ~ "Q2",
        x$w_wolff <= qs["p60"] ~ "Q3",
        x$w_wolff <= qs["p80"] ~ "Q4",
        TRUE ~ "Q5"
      )
      x$wealth_detail <- dplyr::case_when(
        x$w_wolff <= qs["p20"] ~ "P0-20",
        x$w_wolff <= qs["p40"] ~ "P20-40",
        x$w_wolff <= qs["p60"] ~ "P40-60",
        x$w_wolff <= qs["p80"] ~ "P60-80",
        x$w_wolff <= qs["p90"] ~ "P80-90",
        x$w_wolff <= qs["p95"] ~ "P90-95",
        x$w_wolff <= qs["p99"] ~ "P95-99",
        TRUE ~ "P99-100"
      )
      x
    }) %>%
    dplyr::ungroup()
}

sfs <- assign_wealth_class(sfs)

# Portfolio composition summary by wealth class / year
port_summary <- sfs %>%
  dplyr::group_by(year, wealth_q) %>%
  dplyr::summarise(
    n = dplyr::n(),
    w_sum = sum(weight, na.rm = TRUE),
    mean_nw = wtd_mean(w_wolff, weight),
    mean_STK = wtd_mean(STK, weight),
    mean_BND = wtd_mean(BND, weight),
    mean_LIQ = wtd_mean(LIQ, weight),
    mean_BUS = wtd_mean(BUS, weight),
    mean_HOUS = wtd_mean(HOUS, weight),
    mean_DBT = wtd_mean(DBT, weight),
    mean_INC = wtd_mean(INC, weight),
    debt_asset = wtd_mean(DBT, weight) / pmax(wtd_mean(STK + BND + LIQ + BUS + HOUS + OTH_NF, weight), 1),
    .groups = "drop"
  )

readr::write_csv(port_summary, file.path(PATHS$tables, "portfolio_by_wealth_quintile.csv"))
saveRDS(sfs, file.path(PATHS$processed, "sfs_portfolio.rds"))
message("Wrote portfolio map and output/tables/portfolio_by_wealth_quintile.csv")
