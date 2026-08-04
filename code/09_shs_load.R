# code/09_shs_load.R
# Load SHS Tier A years (2017, 2019, 2023), harmonize, attach baskets / demos / income Q.
# Writes data/processed/shs_2017_2023.rds (gitignored).
# Numbering: plan said 08_shs_load; 08 is taken by demo_geo_breakdowns → use 09.

source("code/00_setup.R")
source("code/utils/shs_baskets.R")

paths <- find_shs_paths()
message("SHS paths: RY2023=", paths$ry2023, " | EDM=", paths$data_edm)

# ---- FWF readers ------------------------------------------------------------

read_fwf_cols <- function(path, col_df, encoding = "latin1") {
  # col_df: name, start (1-indexed), end (inclusive)
  stopifnot(file.exists(path))
  positions <- readr::fwf_positions(
    start = col_df$start,
    end = col_df$end,
    col_names = col_df$name
  )
  readr::read_fwf(
    path,
    positions,
    col_types = readr::cols(.default = readr::col_character()),
    locale = readr::locale(encoding = encoding),
    na = character(),
    trim_ws = TRUE,
    progress = FALSE,
    show_col_types = FALSE
  )
}

# 2023 diary PUMF positions (pumf_SHS_2023.dct, 1-indexed inclusive)
COLS_2023 <- tibble::tribble(
  ~name,      ~start, ~end,
  "CASEID",        1,    6,
  "WEIGHTD",       7,   24,
  "PROV",         25,   26,
  "RP_AGEGP",     36,   37,
  "TENURE",       47,   47,
  "HHTOTINC",     66,   76,
  "CL030",       210,  220,
  "FD001",       408,  418,
  "HC001",      2146, 2156,
  "RE001",      2729, 2739,
  "SH001",      3268, 3278,
  "SH011",      3323, 3333,
  "TC001",      3664, 3674,
  "TE001",      3697, 3707,
  "TR001",      3730, 3740,
  "TX010",      3994, 4004
)

# 2017 diary PUMF (PUMF_SHS2017_Diary.lay). Clothing=CL001; taxes=TX001.
COLS_2017 <- tibble::tribble(
  ~name,      ~start, ~end,
  "CASEID",        1,    6,
  "WEIGHTD",       7,   24,
  "PROV",         25,   26,
  "RP_AGEGP",     37,   38,
  "TENURE",       49,   49,
  "HHTOTINC",    236,  246,
  "CL030",       347,  357, # CL001 clothing aggregate → harmonized name
  "FD001",       666,  676,
  "HC001",      2404, 2414,
  "RE001",      3020, 3030,
  "SH001",      3614, 3624,
  "SH011",      3669, 3679,
  "TC001",      3988, 3998,
  "TE001",      4021, 4031,
  "TR001",      4054, 4064,
  "TX010",      4362, 4372  # TX001 → harmonized name
)

harmonize_shs <- function(df, year) {
  num_vars <- c(
    "WEIGHTD", "HHTOTINC", "CL030", "FD001", "HC001", "RE001",
    "SH001", "SH011", "TC001", "TE001", "TR001", "TX010"
  )
  chr_vars <- c("CASEID", "PROV", "RP_AGEGP", "TENURE")
  for (v in chr_vars) {
    if (!v %in% names(df)) df[[v]] <- NA_character_
    df[[v]] <- trimws(as.character(df[[v]]))
  }
  for (v in num_vars) {
    if (!v %in% names(df)) df[[v]] <- NA_real_
    df[[v]] <- shs_na_sentinels(df[[v]])
  }
  df %>%
    dplyr::transmute(
      year = as.integer(year),
      CASEID = CASEID,
      WEIGHTD = WEIGHTD,
      PROV = PROV,
      RP_AGEGP = RP_AGEGP,
      TENURE = TENURE,
      HHTOTINC = HHTOTINC,
      CL030 = CL030,
      FD001 = FD001,
      HC001 = HC001,
      RE001 = RE001,
      SH001 = SH001,
      SH011 = SH011,
      TC001 = TC001,
      TE001 = TE001,
      TR001 = TR001,
      TX010 = TX010,
      age_band = factor(
        shs_age_band(RP_AGEGP),
        levels = c("<30", "30-39", "40-54", "55-64", "65-74", "75+")
      ),
      tenure = factor(
        shs_tenure_label(TENURE),
        levels = c("owner_mortgage", "owner_free_clear", "renter")
      ),
      region = factor(
        shs_region_from_prov(PROV),
        levels = c("BC", "ON+QC+MB", "AB+SK", "Atlantic", "Territories")
      )
    ) %>%
    shs_attach_baskets()
}

load_shs_2023 <- function(ry2023) {
  if (is.na(ry2023)) return(NULL)
  f <- file.path(ry2023, "Data", "TXT", "PUMF_SHS_2023.txt")
  if (!file.exists(f)) {
    message("SHS 2023 TXT not found: ", f)
    return(NULL)
  }
  message("Reading SHS 2023 FWF: ", f)
  raw <- read_fwf_cols(f, COLS_2023)
  harmonize_shs(raw, 2023L)
}

load_shs_2019 <- function(edm) {
  if (is.na(edm)) return(NULL)
  f <- file.path(edm, "2019", "shs_2019.csv")
  if (!file.exists(f)) {
    message("SHS 2019 CSV not found: ", f)
    return(NULL)
  }
  message("Reading SHS 2019 CSV: ", f)
  raw <- readr::read_csv(f, show_col_types = FALSE, progress = FALSE)
  # Harmonize mixed-case 2019 names
  rename_map <- c(
    CaseID = "CASEID", WeightD = "WEIGHTD", Prov = "PROV",
    RP_AgeGrp = "RP_AGEGP", Tenure = "TENURE", HH_TotInc = "HHTOTINC"
  )
  for (old in names(rename_map)) {
    if (old %in% names(raw) && !rename_map[[old]] %in% names(raw)) {
      names(raw)[names(raw) == old] <- rename_map[[old]]
    }
  }
  keep <- unique(c("CASEID", "WEIGHTD", "PROV", "RP_AGEGP", "TENURE", "HHTOTINC",
                   "CL030", "FD001", "HC001", "RE001", "SH001", "SH011",
                   "TC001", "TE001", "TR001", "TX010"))
  miss <- setdiff(keep, names(raw))
  if (length(miss)) {
    warning("SHS 2019 missing columns: ", paste(miss, collapse = ", "))
    for (m in miss) raw[[m]] <- NA
  }
  harmonize_shs(raw[, keep], 2019L)
}

load_shs_2017 <- function(edm) {
  if (is.na(edm)) return(NULL)
  zip_path <- file.path(edm, "2017", "data", "RAW.zip")
  member <- "RAW/pumf_shs2017_diary_flatfile.txt"
  if (!file.exists(zip_path)) {
    message("SHS 2017 RAW.zip not found: ", zip_path)
    return(NULL)
  }
  message("Reading SHS 2017 diary FWF from zip: ", zip_path)
  exdir <- tempfile("shs2017_")
  dir.create(exdir)
  on.exit(unlink(exdir, recursive = TRUE), add = TRUE)
  utils::unzip(zip_path, files = member, exdir = exdir)
  extracted <- file.path(exdir, member)
  if (!file.exists(extracted)) {
    message("Could not extract ", member)
    return(NULL)
  }
  raw <- read_fwf_cols(extracted, COLS_2017)
  # Note: 2017 Prov uses "14" = Atlantic provinces (collapsed)
  # Clothing from CL001, taxes from TX001 (mapped into CL030 / TX010 slots)
  message("  2017 notes: CL030<-CL001; TX010<-TX001; Prov 14=Atlantic collapsed")
  harmonize_shs(raw, 2017L)
}

# ---- Load all available years ----------------------------------------------

pieces <- list(
  load_shs_2017(paths$data_edm),
  load_shs_2019(paths$data_edm),
  load_shs_2023(paths$ry2023)
)
names(pieces) <- c("2017", "2019", "2023")
loaded <- pieces[!vapply(pieces, is.null, logical(1))]

if (!length(loaded)) {
  stop(
    "No SHS Tier A years could be loaded. Check paths in data/raw/DATA_PATHS.md ",
    "(../SHS/RY2023, ../dataSHS/3508_SHS_EDM)."
  )
}

shs <- dplyr::bind_rows(loaded) %>%
  dplyr::filter(is.finite(WEIGHTD), WEIGHTD > 0) %>%
  shs_attach_income_quintile()

# Drop territorial capitals from primary analytic region factor (keep column)
message(
  "SHS loaded years: ", paste(sort(unique(shs$year)), collapse = ", "),
  " | n=", nrow(shs)
)

# Smoke-test weighted means
for (y in sort(unique(shs$year))) {
  g <- shs[shs$year == y, ]
  message(sprintf(
    "  %d: n=%d  mean TC001=%.0f  FD001=%.0f  SH001=%.0f  necessities/TC=%.3f",
    y, nrow(g),
    wtd_mean(g$TC001, g$WEIGHTD),
    wtd_mean(g$FD001, g$WEIGHTD),
    wtd_mean(g$SH001, g$WEIGHTD),
    wtd_mean(g$share_necessities, g$WEIGHTD)
  ))
}

out_rds <- file.path(PATHS$processed, "shs_2017_2023.rds")
saveRDS(shs, out_rds)
message("Wrote ", out_rds)

# Also a tiny year inventory for docs / run_all messaging
yr_tab <- as.data.frame(table(year = shs$year), stringsAsFactors = FALSE)
names(yr_tab) <- c("year", "n")
yr_tab$year <- as.integer(as.character(yr_tab$year))
yr_tab$n <- as.integer(yr_tab$n)
yr_tab$source <- dplyr::case_when(
  yr_tab$year == 2017L ~ "dataSHS/3508_SHS_EDM/2017 RAW.zip diary",
  yr_tab$year == 2019L ~ "dataSHS/3508_SHS_EDM/2019/shs_2019.csv",
  yr_tab$year == 2023L ~ "SHS/RY2023 Data/TXT PUMF",
  TRUE ~ NA_character_
)
readr::write_csv(yr_tab, file.path(PATHS$tables, "shs_years_loaded.csv"))
message("Wrote shs_years_loaded.csv")
