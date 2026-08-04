# code/02_macro_series.R — Canadian CPI, yields, mortgage rates
# Writes data/external/macro_annual.csv and period_inflation.csv

source("code/00_setup.R")

#' Try StatCan WDS vector download; return NULL on failure
fetch_statcan_vector <- function(vector_id, start = 1990) {
  # Statistics Canada Web Data Service (JSON)
  url <- sprintf(
    "https://www150.statcan.gc.ca/t1/wds/rest/getDataFromVectorByReferencePeriodRange/%s/%s-01-01/%s-12-31",
    vector_id, start, format(Sys.Date(), "%Y")
  )
  tryCatch({
    raw <- jsonlite::fromJSON(url, flatten = TRUE)
    # Response shapes vary; handle common "object" list
    df <- raw
    if (is.list(raw) && !is.data.frame(raw)) {
      if (!is.null(raw$object)) df <- raw$object
      if (is.list(df) && !is.data.frame(df) && length(df)) {
        df <- tryCatch(dplyr::bind_rows(df), error = function(e) NULL)
      }
    }
    if (is.null(df) || !NROW(df)) return(NULL)
    df
  }, error = function(e) {
    message("StatCan fetch failed for ", vector_id, ": ", conditionMessage(e))
    NULL
  })
}

#' Built-in annual macro series (Canada), used if live download fails.
#' Sources approximated from BoC / StatCan published annual averages.
#' Units: CPI index 2002=100; yields and mortgage rates in percent.
build_fallback_macro <- function() {
  tibble::tibble(
    year = 1990:2023,
    # All-items CPI annual average (2002=100) — approximate published levels
    cpi = c(
      78.4, 82.8, 84.0, 85.6, 86.0, 87.6, 88.9, 90.4, 91.3, 92.9,
      95.4, 97.8, 100.0, 102.8, 104.7, 107.0, 109.1, 111.5, 114.1, 114.4,
      116.5, 119.9, 121.7, 122.8, 125.2, 126.6, 128.4, 130.4, 133.4, 136.0,
      137.0, 141.6, 151.2, 157.1
    ),
    # GoC 10-year benchmark yield, annual average (%)
    goc10 = c(
      10.85, 9.76, 8.77, 7.85, 8.63, 8.28, 7.59, 6.43, 5.45, 5.69,
      5.89, 5.80, 5.29, 4.80, 4.58, 4.07, 4.21, 4.27, 3.61, 3.30,
      3.24, 2.78, 1.87, 2.26, 2.23, 1.52, 1.25, 1.78, 2.28, 1.59,
      0.75, 1.39, 2.79, 3.36
    ),
    # Chartered bank 5-year conventional mortgage rate, annual avg (%)
    mort5 = c(
      13.20, 11.14, 9.52, 8.70, 9.52, 9.22, 7.91, 7.07, 6.80, 7.40,
      8.20, 7.40, 6.85, 6.10, 6.05, 5.95, 6.40, 7.10, 6.90, 5.60,
      5.40, 5.20, 5.00, 5.10, 4.90, 4.70, 4.60, 4.70, 5.10, 5.20,
      4.90, 3.40, 5.30, 6.40
    )
  ) %>%
    dplyr::mutate(
      infl_yoy = c(NA, diff(cpi) / cpi[-length(cpi)]),
      real_goc10 = goc10 / 100 - dplyr::coalesce(infl_yoy, 0),
      real_goc10_pct = real_goc10 * 100
    )
}

# Prefer packages for download
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  try(install.packages("jsonlite", repos = "https://cloud.r-project.org"), silent = TRUE)
}

macro <- build_fallback_macro()

# Attempt live CPI enrichment via open StatCan CSV zip (all-items Canada)
try_live_cpi <- function() {
  zip_url <- "https://www150.statcan.gc.ca/n1/tbl/csv/18100005-eng.zip"
  tmp <- tempfile(fileext = ".zip")
  ok <- tryCatch({
    download.file(zip_url, tmp, mode = "wb", quiet = TRUE)
    TRUE
  }, error = function(e) FALSE)
  if (!ok) return(NULL)
  ex <- file.path(tempdir(), "statcan_cpi")
  dir.create(ex, showWarnings = FALSE)
  utils::unzip(tmp, exdir = ex)
  csvs <- list.files(ex, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
  if (!length(csvs)) return(NULL)
  # Usually two files; pick the data file (larger / not "MetaData")
  data_csv <- csvs[!grepl("MetaData", csvs, ignore.case = TRUE)][1]
  if (is.na(data_csv)) data_csv <- csvs[1]
  d <- readr::read_csv(data_csv, show_col_types = FALSE)
  # Expect columns like REF_DATE, GEO, Products and product groups, VALUE
  nm <- names(d)
  date_col <- nm[grepl("REF_DATE|Ref_Date", nm, ignore.case = TRUE)][1]
  geo_col  <- nm[grepl("^GEO$|Geography", nm, ignore.case = TRUE)][1]
  prod_col <- nm[grepl("Product|Products", nm, ignore.case = TRUE)][1]
  val_col  <- nm[grepl("^VALUE$|Value", nm, ignore.case = TRUE)][1]
  if (any(is.na(c(date_col, val_col)))) return(NULL)
  d2 <- d
  if (!is.na(geo_col)) {
    d2 <- dplyr::filter(d2, .data[[geo_col]] == "Canada" | grepl("^Canada$", .data[[geo_col]]))
  }
  if (!is.na(prod_col)) {
    d2 <- dplyr::filter(d2, grepl("All-items", .data[[prod_col]], ignore.case = TRUE))
  }
  d2 <- d2 %>%
    dplyr::mutate(
      year = as.integer(substr(as.character(.data[[date_col]]), 1, 4)),
      cpi_live = as.numeric(.data[[val_col]])
    ) %>%
    dplyr::filter(year >= 1990, year <= 2023) %>%
    dplyr::group_by(year) %>%
    dplyr::summarise(cpi_live = mean(cpi_live, na.rm = TRUE), .groups = "drop")
  if (nrow(d2) < 20) return(NULL)
  d2
}

live <- tryCatch(try_live_cpi(), error = function(e) NULL)
if (!is.null(live) && nrow(live) > 0) {
  message("Merged live StatCan annual CPI (", nrow(live), " years).")
  macro <- macro %>%
    dplyr::left_join(live, by = "year") %>%
    dplyr::arrange(year) %>%
    dplyr::mutate(
      cpi = dplyr::coalesce(cpi_live, cpi),
      infl_yoy = (cpi / dplyr::lag(cpi)) - 1,
      real_goc10 = goc10 / 100 - dplyr::coalesce(infl_yoy, 0),
      real_goc10_pct = real_goc10 * 100
    ) %>%
    dplyr::select(-dplyr::any_of("cpi_live"))
} else {
  message("Using fallback macro series (CPI / GoC10 / mortgage).")
}

# Cumulative inflation and average rates between SFS survey years
periods <- tibble::tibble(
  year0 = SURVEY_YEARS[-length(SURVEY_YEARS)],
  year1 = SURVEY_YEARS[-1]
) %>%
  dplyr::rowwise() %>%
  dplyr::mutate(
    n_years = year1 - year0,
    cpi0 = macro$cpi[macro$year == year0],
    cpi1 = macro$cpi[macro$year == year1],
    infl_cum = cpi1 / cpi0 - 1,
    infl_ann = (cpi1 / cpi0)^(1 / n_years) - 1,
    goc10_0 = macro$goc10[macro$year == year0] / 100,
    goc10_1 = macro$goc10[macro$year == year1] / 100,
    real0 = macro$real_goc10[macro$year == year0],
    real1 = macro$real_goc10[macro$year == year1],
    mort0 = macro$mort5[macro$year == year0] / 100,
    mort1 = macro$mort5[macro$year == year1] / 100,
    d_real = real1 - real0,
    d_nom = goc10_1 - goc10_0,
    d_mort = mort1 - mort0
  ) %>%
  dplyr::ungroup()

readr::write_csv(macro, file.path(PATHS$external, "macro_annual.csv"))
readr::write_csv(periods, file.path(PATHS$external, "period_rates.csv"))

message("Wrote data/external/macro_annual.csv and period_rates.csv")
