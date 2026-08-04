# code/01_build_sfs_panel.R — load SFS and apply Wolff-style wealth definition

source("code/00_setup.R")

panel_path <- find_sfs_panel()
message("Loading SFS panel from: ", panel_path)

if (grepl("\\.rda$", panel_path, ignore.case = TRUE)) {
  e <- new.env()
  load(panel_path, envir = e)
  objs <- ls(e)
  if ("sfs" %in% objs) {
    sfs_raw <- e$sfs
  } else {
    sfs_raw <- e[[objs[[1]]]]
  }
} else {
  sfs_raw <- readr::read_csv(panel_path, show_col_types = FALSE)
}

sfs_raw <- tibble::as_tibble(sfs_raw)

# Rename to analysis names (aligned with SFS_general.R)
rename_map <- c(
  famid = "pefamid",
  weight = "pweight",
  agegrp = "pagemieg",
  age = "pagemie",
  dem_educ = "peducmie",
  inc_net = "pefatinc",
  inc_transfers = "pefgtr",
  inc_source = "pefmjsif",
  inc_gross = "pefmtinc",
  dem_fam_size = "pfsz",
  dem_fam_tenure = "pftenur",
  dem_prov = "ppvres",
  dem_region = "pregion",
  dem_retired = "pretirme",
  dem_sex = "psexmie",
  dem_num_earners = "pnbearg",
  w_oth_ret_funds = "pwaotpen",
  w_hous_princ_res_val = "pwaprval",
  w_pens_employer_val_gc = "pwarppg",
  w_pens_employer_val_tm = "pwarppt",
  w_rrif = "pwarrif",
  w_rrsp = "pwarrspl",
  w_bonds = "pwastbnd",
  w_bank_acc = "pwastdep",
  w_mut_funds = "pwastmui",
  w_oth_inv = "pwastoin",
  w_oth_nonfin = "pwastonf",
  w_hous_oth_real_est = "pwastrst",
  w_stocks = "pwaststk",
  w_vehicles = "pwastvhe",
  w_tfsa = "pwatfs",
  w_tot_incl_pens_gc = "pwatotpg",
  w_tot_incl_pens_tm = "pwatotpt",
  w_bus_val = "pwbuseq",
  debt_mort_princ_res_val = "pwdprmor",
  debt_stud_loans_val = "pwdsloan",
  debt_cc_installment_val = "pwdstcrd",
  debt_loc_val = "pwdstloc",
  debt_oth_val = "pwdstodb",
  debt_mort_oth_real_est_val = "pwdstomr",
  debt_vehicles_val = "pwdstvhn",
  debt_tot_val = "pwdtotal",
  w_networth_gc = "pwnetwpg",
  w_networth_tm = "pwnetwpt",
  visible_min = "pvmfmie",
  gender_mie = "pgdrmie"
)

have <- intersect(unname(rename_map), names(sfs_raw))
use_map <- rename_map[unname(rename_map) %in% have]
sfs <- sfs_raw
for (new in names(use_map)) {
  old <- use_map[[new]]
  sfs[[new]] <- sfs_raw[[old]]
}

stopifnot("year" %in% names(sfs), "weight" %in% names(sfs))

asset_debt_cols <- c(
  "w_bank_acc", "w_bonds", "w_mut_funds", "w_oth_inv", "w_oth_nonfin",
  "w_hous_princ_res_val", "w_hous_oth_real_est", "w_stocks", "w_vehicles",
  "w_tfsa", "w_rrsp", "w_rrif", "w_oth_ret_funds", "w_bus_val",
  "w_pens_employer_val_gc", "w_pens_employer_val_tm",
  "debt_mort_princ_res_val", "debt_mort_oth_real_est_val", "debt_stud_loans_val",
  "debt_cc_installment_val", "debt_loc_val", "debt_oth_val", "debt_vehicles_val",
  "debt_tot_val", "inc_gross", "inc_net", "inc_transfers"
)
for (cl in asset_debt_cols) {
  if (cl %in% names(sfs)) sfs[[cl]] <- na2zero(sfs[[cl]])
}

# Rebuild totals if needed
sfs <- sfs %>%
  dplyr::mutate(
    debt_tot_val = dplyr::if_else(
      is.na(debt_tot_val) | debt_tot_val == 0,
      debt_mort_princ_res_val + debt_mort_oth_real_est_val + debt_stud_loans_val +
        debt_cc_installment_val + debt_loc_val + debt_oth_val + debt_vehicles_val,
      debt_tot_val
    ),
    # Wolff-style assets: exclude vehicles and DB employer pensions
    w_assets_wolff =
      w_bank_acc + w_bonds + w_mut_funds + w_oth_inv + w_oth_nonfin +
      w_hous_princ_res_val + w_hous_oth_real_est + w_stocks +
      w_tfsa + w_rrsp + w_rrif + w_oth_ret_funds + w_bus_val,
    # Debt excl. vehicle loans (consistent with excluding vehicles)
    debt_wolff =
      debt_mort_princ_res_val + debt_mort_oth_real_est_val + debt_stud_loans_val +
      debt_cc_installment_val + debt_loc_val + debt_oth_val,
    w_wolff = w_assets_wolff - debt_wolff,
    # Income used for IT (after-tax / disposable analogue)
    inc_it = dplyr::if_else(inc_net > 0, inc_net, pmax(inc_gross, 0)),
    owner = as.integer(dem_fam_tenure %in% c(1, "1", "Owned", "owned") |
                         (!is.na(w_hous_princ_res_val) & w_hous_princ_res_val > 0)),
    # Tenure × mortgage status (for housing / interest-rate incidence)
    housing_status = dplyr::case_when(
      owner == 1 & debt_mort_princ_res_val > 0 ~ "owner_mortgage",
      owner == 1 ~ "owner_free_clear",
      TRUE ~ "renter"
    ),
    id = dplyr::row_number()
  )

# Keep analysis years
sfs <- sfs %>% dplyr::filter(year %in% SURVEY_YEARS)

message(sprintf(
  "SFS panel: %s households across years %s",
  format(nrow(sfs), big.mark = ","),
  paste(sort(unique(sfs$year)), collapse = ", ")
))

saveRDS(sfs, file.path(PATHS$processed, "sfs_wolff_panel.rds"))
message("Wrote data/processed/sfs_wolff_panel.rds")
