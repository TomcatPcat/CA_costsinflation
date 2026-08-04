# code/11_macro_context_figure.R
# Intro macro backdrop: policy rate, CPI inflation, housing / equity returns, wage growth.
# Writes: data/external/macro_context_annual.csv
#         output/figures/macro_context_1998_present.png (.pdf)
# See also: data/external/MACRO_CONTEXT_SOURCES.md
#
# Series definitions (annual, Canada, ~1998–latest available):
# 1. Bank of Canada target overnight rate (policy rate), annual average of monthly
#    STATIC_ATABLE_V39079 via Valet API — NOT Bank Rate (Bank Rate = target + 0.25 pp).
# 2. CPI all-items inflation: YoY % change in annual-average CPI (StatCan 18-10-0005).
# 3. Housing market return: YoY % change in BIS residential property price index for
#    Canada (FRED QCAN628BIS); fallback StatCan NHPI total house+land (18-10-0205).
# 4. Equity return: calendar-year price return on S&P/TSX Composite (^GSPTSE) from
#    Yahoo chart API; fallback FRED SPASTT01CAM661N (OECD Canada share prices).
# 5. Nominal wage growth: YoY % change in SEPH average weekly earnings incl. overtime,
#    industrial aggregate excl. unclassified (StatCan 14-10-0223). Coverage typically
#    from 2001; earlier years filled from fallback CSV if present.

# If launched via Rscript, setwd to repo root (parent of code/)
if (!interactive()) {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", cmd_args, value = TRUE)
  if (length(file_arg)) {
    script <- normalizePath(sub("^--file=", "", file_arg))
    setwd(dirname(dirname(script)))
  }
}

source("code/00_setup.R")

options(timeout = 180)

START_YEAR <- 1998L
SFS_YEARS <- SURVEY_YEARS
FALLBACK_DIR <- PATHS$external
OUT_CSV <- file.path(PATHS$external, "macro_context_annual.csv")
OUT_PNG <- file.path(PATHS$figures, "macro_context_1998_present.png")
OUT_PDF <- file.path(PATHS$figures, "macro_context_1998_present.pdf")

# Canadian recessions (approx calendar years for annual shading)
RECESSIONS <- tibble::tibble(
  start = c(2008L, 2020L),
  end   = c(2009L, 2020L)
)

# ---- helpers ----------------------------------------------------------------

safe_download <- function(url, dest, quiet = TRUE, user_agent = NULL) {
  tryCatch({
    headers <- if (!is.null(user_agent)) c("User-Agent" = user_agent) else NULL
    if (is.null(headers)) {
      utils::download.file(url, dest, mode = "wb", quiet = quiet)
    } else {
      utils::download.file(url, dest, mode = "wb", quiet = quiet, headers = headers)
    }
    file.exists(dest) && isTRUE(file.size(dest) > 50)
  }, error = function(e) {
    message("Download failed: ", url, " — ", conditionMessage(e))
    FALSE
  })
}

read_boc_valet_csv <- function(series_id, start_date = "1990-01-01") {
  url <- sprintf(
    "https://www.bankofcanada.ca/valet/observations/%s/csv?start_date=%s",
    series_id, start_date
  )
  tmp <- tempfile(fileext = ".csv")
  if (!safe_download(url, tmp)) return(NULL)
  lines <- readLines(tmp, warn = FALSE)
  hdr <- which(grepl("^\"date\"|^date,", lines))[1]
  if (is.na(hdr)) return(NULL)
  df <- utils::read.csv(text = paste(lines[hdr:length(lines)], collapse = "\n"),
                        stringsAsFactors = FALSE, check.names = FALSE)
  if (ncol(df) < 2) return(NULL)
  names(df)[1:2] <- c("date", "value")
  df$value <- as.numeric(df$value)
  df$date <- as.Date(df$date)
  df <- df[!is.na(df$value) & !is.na(df$date), ]
  if (!nrow(df)) return(NULL)
  df
}

read_statcan_table_zip <- function(table_id) {
  url <- sprintf("https://www150.statcan.gc.ca/n1/tbl/csv/%s-eng.zip", table_id)
  tmp <- tempfile(fileext = ".zip")
  if (!safe_download(url, tmp)) return(NULL)
  ex <- file.path(tempdir(), paste0("statcan_", table_id))
  unlink(ex, recursive = TRUE)
  dir.create(ex, showWarnings = FALSE)
  utils::unzip(tmp, exdir = ex)
  csvs <- list.files(ex, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
  data_csv <- csvs[!grepl("MetaData", csvs, ignore.case = TRUE)][1]
  if (is.na(data_csv)) return(NULL)
  readr::read_csv(data_csv, show_col_types = FALSE)
}

read_fallback_series <- function(filename, value_col) {
  path <- file.path(FALLBACK_DIR, filename)
  if (!file.exists(path)) return(NULL)
  d <- readr::read_csv(path, show_col_types = FALSE, comment = "#")
  if (!all(c("year", value_col) %in% names(d))) return(NULL)
  d %>%
    dplyr::transmute(year = as.integer(.data$year), value = as.numeric(.data[[value_col]])) %>%
    dplyr::filter(is.finite(year), is.finite(value))
}

annual_mean_from_monthly <- function(df_date_value) {
  df_date_value %>%
    dplyr::mutate(year = as.integer(format(.data$date, "%Y"))) %>%
    dplyr::group_by(year) %>%
    dplyr::summarise(value = mean(.data$value, na.rm = TRUE), .groups = "drop")
}

yoy_pct_from_index <- function(df_year_index) {
  df_year_index %>%
    dplyr::arrange(year) %>%
    dplyr::mutate(value = 100 * (.data$index / dplyr::lag(.data$index) - 1)) %>%
    dplyr::select(year, value) %>%
    dplyr::filter(is.finite(value))
}

# ---- 1. Policy rate (target overnight) --------------------------------------

fetch_policy_rate <- function() {
  message("Fetching BoC target overnight rate (STATIC_ATABLE_V39079)...")
  raw <- read_boc_valet_csv("STATIC_ATABLE_V39079", start_date = "1996-01-01")
  if (!is.null(raw) && nrow(raw) >= 12) {
    ann <- annual_mean_from_monthly(raw) %>%
      dplyr::filter(year >= START_YEAR) %>%
      dplyr::rename(policy_rate_pct = value)
    if (nrow(ann) >= 10) {
      message("  Policy rate: live Valet monthly → annual avg (", min(ann$year), "–", max(ann$year), ")")
      return(list(data = ann, source = "BoC Valet STATIC_ATABLE_V39079 (target overnight; annual avg of monthly)"))
    }
  }
  # Daily target from 2009 only — splice with Bank Rate minus 25 bp if needed
  daily <- read_boc_valet_csv("V39079", start_date = "1998-01-01")
  bank <- read_boc_valet_csv("V122530", start_date = "1998-01-01")
  pieces <- list()
  if (!is.null(bank)) {
    pieces[[1]] <- annual_mean_from_monthly(bank) %>%
      dplyr::mutate(policy_rate_pct = value - 0.25) %>%
      dplyr::select(year, policy_rate_pct) %>%
      dplyr::filter(year < 2009L)
  }
  if (!is.null(daily)) {
    pieces[[length(pieces) + 1]] <- annual_mean_from_monthly(daily) %>%
      dplyr::rename(policy_rate_pct = value) %>%
      dplyr::filter(year >= 2009L)
  }
  if (length(pieces)) {
    ann <- dplyr::bind_rows(pieces) %>%
      dplyr::filter(year >= START_YEAR) %>%
      dplyr::arrange(year) %>%
      dplyr::distinct(year, .keep_all = TRUE)
    message("  Policy rate: spliced Bank Rate−0.25 / V39079 (", min(ann$year), "–", max(ann$year), ")")
    return(list(data = ann, source = "BoC Valet splice: V122530 Bank Rate − 0.25 pp (pre-2009) + V39079 target (from 2009)"))
  }
  fb <- read_fallback_series("fallback_policy_rate.csv", "policy_rate_pct")
  if (!is.null(fb)) {
    message("  Policy rate: FALLBACK CSV")
    return(list(
      data = fb %>% dplyr::rename(policy_rate_pct = value) %>% dplyr::filter(year >= START_YEAR),
      source = "fallback_policy_rate.csv (see MACRO_CONTEXT_SOURCES.md)"
    ))
  }
  stop("Could not obtain policy rate series")
}

# ---- 2. CPI inflation -------------------------------------------------------

fetch_cpi_inflation <- function() {
  message("Fetching StatCan CPI all-items...")
  d <- read_statcan_table_zip("18100005")
  if (!is.null(d)) {
    nm <- names(d)
    date_col <- nm[grepl("REF_DATE", nm, ignore.case = TRUE)][1]
    geo_col  <- nm[grepl("^GEO$", nm)][1]
    prod_col <- nm[grepl("Product", nm, ignore.case = TRUE)][1]
    val_col  <- nm[grepl("^VALUE$", nm)][1]
    d2 <- d
    if (!is.na(geo_col)) d2 <- dplyr::filter(d2, .data[[geo_col]] == "Canada")
    if (!is.na(prod_col)) {
      d2 <- dplyr::filter(d2, grepl("^All-items$", .data[[prod_col]], ignore.case = TRUE))
    }
    ann <- d2 %>%
      dplyr::mutate(
        year = as.integer(substr(as.character(.data[[date_col]]), 1, 4)),
        cpi = as.numeric(.data[[val_col]])
      ) %>%
      dplyr::filter(year >= START_YEAR - 1L, is.finite(cpi)) %>%
      dplyr::group_by(year) %>%
      dplyr::summarise(cpi = mean(cpi, na.rm = TRUE), .groups = "drop") %>%
      dplyr::arrange(year) %>%
      dplyr::mutate(cpi_infl_yoy_pct = 100 * (cpi / dplyr::lag(cpi) - 1)) %>%
      dplyr::filter(year >= START_YEAR, is.finite(cpi_infl_yoy_pct)) %>%
      dplyr::select(year, cpi_infl_yoy_pct)
    if (nrow(ann) >= 10) {
      message("  CPI inflation: live StatCan 18-10-0005 (", min(ann$year), "–", max(ann$year), ")")
      return(list(data = ann, source = "StatCan 18-10-0005 all-items Canada; YoY % of annual-average CPI"))
    }
  }
  # Reuse project macro_annual.csv if present
  macro_path <- file.path(PATHS$external, "macro_annual.csv")
  if (file.exists(macro_path)) {
    m <- readr::read_csv(macro_path, show_col_types = FALSE)
    if ("infl_yoy" %in% names(m)) {
      ann <- m %>%
        dplyr::filter(year >= START_YEAR, is.finite(infl_yoy)) %>%
        dplyr::transmute(year = as.integer(year), cpi_infl_yoy_pct = 100 * infl_yoy)
      message("  CPI inflation: from data/external/macro_annual.csv")
      return(list(data = ann, source = "macro_annual.csv infl_yoy (StatCan CPI / project fallback)"))
    }
  }
  fb <- read_fallback_series("fallback_cpi_inflation.csv", "cpi_infl_yoy_pct")
  if (!is.null(fb)) {
    message("  CPI inflation: FALLBACK CSV")
    return(list(
      data = fb %>% dplyr::rename(cpi_infl_yoy_pct = value) %>% dplyr::filter(year >= START_YEAR),
      source = "fallback_cpi_inflation.csv"
    ))
  }
  stop("Could not obtain CPI inflation")
}

# ---- 3. Housing returns -----------------------------------------------------

fetch_housing_returns <- function() {
  message("Fetching housing prices (FRED/BIS QCAN628BIS)...")
  tmp <- tempfile(fileext = ".csv")
  url <- "https://fred.stlouisfed.org/graph/fredgraph.csv?id=QCAN628BIS"
  if (safe_download(url, tmp)) {
    d <- tryCatch(readr::read_csv(tmp, show_col_types = FALSE), error = function(e) NULL)
    if (!is.null(d) && ncol(d) >= 2) {
      names(d)[1:2] <- c("date", "index")
      d$date <- as.Date(d$date)
      d$index <- as.numeric(d$index)
      # Annual average of quarterly index, then YoY %
      ann_idx <- d %>%
        dplyr::filter(is.finite(index), !is.na(date)) %>%
        dplyr::mutate(year = as.integer(format(date, "%Y"))) %>%
        dplyr::group_by(year) %>%
        dplyr::summarise(index = mean(index, na.rm = TRUE), .groups = "drop")
      ann <- yoy_pct_from_index(ann_idx) %>%
        dplyr::filter(year >= START_YEAR) %>%
        dplyr::rename(housing_return_pct = value)
      if (nrow(ann) >= 10) {
        message("  Housing: FRED QCAN628BIS BIS RPP (", min(ann$year), "–", max(ann$year), ")")
        return(list(
          data = ann,
          source = "FRED QCAN628BIS (BIS residential property prices, Canada); YoY % of annual-avg index"
        ))
      }
    }
  }

  message("  Trying StatCan NHPI 18-10-0205...")
  d <- read_statcan_table_zip("18100205")
  if (!is.null(d)) {
    d2 <- d %>%
      dplyr::filter(
        .data$GEO == "Canada",
        grepl("Total \\(house and land\\)", .data[["New housing price indexes"]], ignore.case = TRUE)
      ) %>%
      dplyr::mutate(
        year = as.integer(substr(as.character(REF_DATE), 1, 4)),
        index = as.numeric(VALUE)
      ) %>%
      dplyr::filter(is.finite(index), year >= START_YEAR - 1L) %>%
      dplyr::group_by(year) %>%
      dplyr::summarise(index = mean(index, na.rm = TRUE), .groups = "drop")
    ann <- yoy_pct_from_index(d2) %>%
      dplyr::filter(year >= START_YEAR) %>%
      dplyr::rename(housing_return_pct = value)
    if (nrow(ann) >= 10) {
      message("  Housing: StatCan NHPI (", min(ann$year), "–", max(ann$year), ")")
      return(list(
        data = ann,
        source = "StatCan 18-10-0205 NHPI Canada total (house and land); YoY % of annual-avg index (new housing)"
      ))
    }
  }

  fb <- read_fallback_series("fallback_housing_return.csv", "housing_return_pct")
  if (!is.null(fb)) {
    message("  Housing: FALLBACK CSV")
    return(list(
      data = fb %>% dplyr::rename(housing_return_pct = value) %>% dplyr::filter(year >= START_YEAR),
      source = "fallback_housing_return.csv"
    ))
  }
  stop("Could not obtain housing returns")
}

# ---- 4. Equity returns (S&P/TSX) --------------------------------------------

fetch_equity_returns <- function() {
  message("Fetching S&P/TSX Composite (^GSPTSE) via Yahoo chart API...")
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    try(install.packages("jsonlite", repos = "https://cloud.r-project.org"), silent = TRUE)
  }
  period1 <- as.integer(as.POSIXct("1997-01-01", tz = "UTC"))
  period2 <- as.integer(as.POSIXct(Sys.Date(), tz = "UTC"))
  url <- sprintf(
    "https://query1.finance.yahoo.com/v8/finance/chart/%%5EGSPTSE?period1=%d&period2=%d&interval=1mo",
    period1, period2
  )
  tmp <- tempfile(fileext = ".json")
  ua <- "Mozilla/5.0 (compatible; CA_costsinflation/1.0; research)"
  if (requireNamespace("jsonlite", quietly = TRUE) &&
      safe_download(url, tmp, user_agent = ua)) {
    j <- tryCatch(jsonlite::fromJSON(tmp, simplifyVector = FALSE), error = function(e) NULL)
    res <- tryCatch(j$chart$result[[1]], error = function(e) NULL)
    if (!is.null(res)) {
      ts <- unlist(res$timestamp)
      cl <- unlist(res$indicators$quote[[1]]$close)
      if (length(ts) && length(cl) && length(ts) == length(cl)) {
        d <- tibble::tibble(
          date = as.Date(as.POSIXct(ts, origin = "1970-01-01", tz = "UTC")),
          close = as.numeric(cl)
        ) %>% dplyr::filter(is.finite(close))
        # Calendar-year price return from Dec (or last available) closes
        ann_close <- d %>%
          dplyr::mutate(year = as.integer(format(date, "%Y")),
                        month = as.integer(format(date, "%m"))) %>%
          dplyr::group_by(year) %>%
          dplyr::summarise(
            close = dplyr::last(close[order(date)]),
            .groups = "drop"
          ) %>%
          dplyr::arrange(year)
        ann <- ann_close %>%
          dplyr::mutate(equity_return_pct = 100 * (close / dplyr::lag(close) - 1)) %>%
          dplyr::filter(year >= START_YEAR, is.finite(equity_return_pct)) %>%
          dplyr::select(year, equity_return_pct)
        if (nrow(ann) >= 10) {
          message("  Equity: Yahoo ^GSPTSE price return (", min(ann$year), "–", max(ann$year), ")")
          return(list(
            data = ann,
            source = "Yahoo Finance ^GSPTSE (S&P/TSX Composite); calendar-year price return (not total return)"
          ))
        }
      }
    }
  }

  message("  Trying FRED SPASTT01CAM661N (OECD Canada share prices)...")
  tmpf <- tempfile(fileext = ".csv")
  if (safe_download("https://fred.stlouisfed.org/graph/fredgraph.csv?id=SPASTT01CAM661N", tmpf)) {
    d <- tryCatch(readr::read_csv(tmpf, show_col_types = FALSE), error = function(e) NULL)
    if (!is.null(d) && ncol(d) >= 2) {
      names(d)[1:2] <- c("date", "index")
      d$date <- as.Date(d$date)
      d$index <- as.numeric(d$index)
      ann_idx <- d %>%
        dplyr::filter(is.finite(index)) %>%
        dplyr::mutate(year = as.integer(format(date, "%Y"))) %>%
        dplyr::group_by(year) %>%
        dplyr::summarise(index = mean(index, na.rm = TRUE), .groups = "drop")
      ann <- yoy_pct_from_index(ann_idx) %>%
        dplyr::filter(year >= START_YEAR) %>%
        dplyr::rename(equity_return_pct = value)
      if (nrow(ann) >= 10) {
        message("  Equity: FRED SPASTT01CAM661N (", min(ann$year), "–", max(ann$year), ")")
        return(list(
          data = ann,
          source = "FRED SPASTT01CAM661N (OECD share prices, Canada); YoY % of annual-avg index"
        ))
      }
    }
  }

  fb <- read_fallback_series("fallback_equity_return.csv", "equity_return_pct")
  if (!is.null(fb)) {
    message("  Equity: FALLBACK CSV")
    return(list(
      data = fb %>% dplyr::rename(equity_return_pct = value) %>% dplyr::filter(year >= START_YEAR),
      source = "fallback_equity_return.csv"
    ))
  }
  stop("Could not obtain equity returns")
}

# ---- 5. Wage growth ---------------------------------------------------------

fetch_wage_growth <- function() {
  message("Fetching SEPH average weekly earnings (StatCan 14-10-0223)...")
  d <- read_statcan_table_zip("14100223")
  live <- NULL
  if (!is.null(d)) {
    naics_col <- names(d)[grepl("NAICS|North American", names(d), ignore.case = TRUE)][1]
    d2 <- d %>%
      dplyr::filter(
        GEO == "Canada",
        grepl("Average weekly earnings including overtime for all employees", Estimate, ignore.case = TRUE)
      )
    if (!is.na(naics_col)) {
      d2 <- dplyr::filter(
        d2,
        grepl("Industrial aggregate excluding unclassified", .data[[naics_col]], ignore.case = TRUE)
      )
    }
    ann_idx <- d2 %>%
      dplyr::mutate(
        year = as.integer(substr(as.character(REF_DATE), 1, 4)),
        index = as.numeric(VALUE)
      ) %>%
      dplyr::filter(is.finite(index), year >= 1990L) %>%
      dplyr::group_by(year) %>%
      dplyr::summarise(index = mean(index, na.rm = TRUE), .groups = "drop")
    live <- yoy_pct_from_index(ann_idx) %>%
      dplyr::filter(year >= START_YEAR) %>%
      dplyr::rename(wage_growth_pct = value)
    if (nrow(live) >= 5) {
      message("  Wages: live SEPH (", min(live$year), "–", max(live$year), ")")
    } else {
      live <- NULL
    }
  }

  fb <- read_fallback_series("fallback_wage_growth.csv", "wage_growth_pct")
  if (!is.null(live)) {
    src <- "StatCan 14-10-0223 SEPH avg weekly earnings incl. OT, industrial aggregate excl. unclassified; YoY % of annual avg"
    if (!is.null(fb)) {
      # Fill pre-SEPH years from fallback
      miss_years <- setdiff(START_YEAR:max(live$year, na.rm = TRUE), live$year)
      early <- fb %>%
        dplyr::filter(year %in% miss_years | year < min(live$year, na.rm = TRUE)) %>%
        dplyr::rename(wage_growth_pct = value)
      if (nrow(early)) {
        live <- dplyr::bind_rows(early, live) %>%
          dplyr::arrange(year) %>%
          dplyr::distinct(year, .keep_all = TRUE)
        src <- paste0(src, "; early years from fallback_wage_growth.csv")
        message("  Wages: spliced fallback for early years")
      }
    }
    return(list(data = live, source = src))
  }
  if (!is.null(fb)) {
    message("  Wages: FALLBACK CSV")
    return(list(
      data = fb %>% dplyr::rename(wage_growth_pct = value) %>% dplyr::filter(year >= START_YEAR),
      source = "fallback_wage_growth.csv"
    ))
  }
  stop("Could not obtain wage growth")
}

# ---- Assemble ---------------------------------------------------------------

pol <- fetch_policy_rate()
cpi <- fetch_cpi_inflation()
hou <- fetch_housing_returns()
eq  <- fetch_equity_returns()
wag <- fetch_wage_growth()

years <- sort(unique(c(
  pol$data$year, cpi$data$year, hou$data$year, eq$data$year, wag$data$year
)))
years <- years[years >= START_YEAR]

macro_ctx <- tibble::tibble(year = years) %>%
  dplyr::left_join(pol$data, by = "year") %>%
  dplyr::left_join(cpi$data, by = "year") %>%
  dplyr::left_join(hou$data, by = "year") %>%
  dplyr::left_join(eq$data, by = "year") %>%
  dplyr::left_join(wag$data, by = "year") %>%
  dplyr::arrange(year)

# Drop incomplete current calendar year (partial averages distort YoY returns)
cur_year <- as.integer(format(Sys.Date(), "%Y"))
macro_ctx <- dplyr::filter(macro_ctx, year < cur_year)

# Drop trailing years with almost no series
value_cols <- c("policy_rate_pct", "cpi_infl_yoy_pct", "housing_return_pct",
                "equity_return_pct", "wage_growth_pct")
macro_ctx <- macro_ctx %>%
  dplyr::mutate(n_obs = rowSums(dplyr::across(dplyr::all_of(value_cols), ~ is.finite(.x)))) %>%
  dplyr::filter(n_obs >= 2L) %>%
  dplyr::select(-n_obs)

# Legend labels reflect the equity source actually used
equity_is_tsx <- grepl("GSPTSE|TSX|Yahoo", eq$source, ignore.case = TRUE)
equity_label <- if (equity_is_tsx) {
  "S&P/TSX price return"
} else {
  "Equity prices (OECD/FRED YoY)"
}
series_labels <- c(
  "BoC policy rate (target overnight)",
  "CPI inflation (all-items YoY)",
  "Housing return (BIS RPP YoY)",
  equity_label,
  "Nominal wage growth (SEPH AWE)"
)

readr::write_csv(macro_ctx, OUT_CSV)
message("Wrote ", OUT_CSV)

sources_note <- c(
  paste0("policy_rate: ", pol$source),
  paste0("cpi_inflation: ", cpi$source),
  paste0("housing: ", hou$source),
  paste0("equity: ", eq$source),
  paste0("wages: ", wag$source),
  paste0("coverage: ", min(macro_ctx$year), "–", max(macro_ctx$year))
)
writeLines(sources_note, file.path(PATHS$external, "macro_context_sources_used.txt"))
message(paste(sources_note, collapse = "\n"))

# ---- Figure ------------------------------------------------------------------

long <- macro_ctx %>%
  tidyr::pivot_longer(
    cols = dplyr::all_of(value_cols),
    names_to = "series",
    values_to = "pct"
  ) %>%
  dplyr::mutate(
    series = factor(series, levels = value_cols, labels = series_labels)
  )

yr_min <- min(macro_ctx$year, na.rm = TRUE)
yr_max <- max(macro_ctx$year, na.rm = TRUE)
recess <- RECESSIONS %>%
  dplyr::filter(end >= yr_min, start <= yr_max) %>%
  dplyr::mutate(
    xmin = pmax(start - 0.5, yr_min - 0.5),
    xmax = pmin(end + 0.5, yr_max + 0.5)
  )

pal <- stats::setNames(
  c("#1b4f72", "#c0392b", "#196f3d", "#6c3483", "#b9770e"),
  series_labels
)
equity_caption <- if (equity_is_tsx) {
  "Equities: S&P/TSX Composite price return."
} else {
  "Equities: OECD Canada share prices (FRED SPASTT01CAM661N; TSX Yahoo unavailable)."
}

p <- ggplot2::ggplot(long, ggplot2::aes(x = year, y = pct, colour = series)) +
  ggplot2::geom_rect(
    data = recess,
    ggplot2::aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
    inherit.aes = FALSE,
    fill = "grey80",
    alpha = 0.45
  ) +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.35, colour = "grey40") +
  ggplot2::geom_vline(
    xintercept = SFS_YEARS[SFS_YEARS >= yr_min & SFS_YEARS <= yr_max],
    linetype = "dashed",
    colour = "grey50",
    linewidth = 0.4
  ) +
  ggplot2::geom_line(linewidth = 0.85, na.rm = TRUE) +
  ggplot2::geom_point(size = 1.1, na.rm = TRUE) +
  ggplot2::scale_colour_manual(values = pal, name = NULL) +
  ggplot2::scale_x_continuous(breaks = seq(yr_min, yr_max, by = 2)) +
  ggplot2::scale_y_continuous(labels = function(x) paste0(x, "%")) +
  ggplot2::labs(
    title = "Canadian macro backdrop for the inflation-tax analysis",
    subtitle = paste0(
      "Annual series, ", yr_min, "–", yr_max,
      ". Dashed lines = SFS survey years; grey bands ≈ recessions (2008–09, 2020)."
    ),
    x = NULL,
    y = "Percent",
    caption = paste(
      "Policy: BoC target overnight (annual avg).",
      "CPI: StatCan all-items YoY of annual avg.",
      "Housing: BIS RPP via FRED (or NHPI fallback).",
      equity_caption,
      "Wages: SEPH average weekly earnings YoY.",
      sep = " "
    )
  ) +
  theme_paper() +
  ggplot2::theme(
    legend.position = "bottom",
    legend.text = ggplot2::element_text(size = 8.5),
    plot.caption = ggplot2::element_text(size = 7.5, hjust = 0, colour = "grey30"),
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
  ) +
  ggplot2::guides(colour = ggplot2::guide_legend(nrow = 3, byrow = TRUE))

ggplot2::ggsave(OUT_PNG, p, width = 10, height = 6.2, dpi = 160)
ggplot2::ggsave(OUT_PDF, p, width = 10, height = 6.2)
message("Wrote ", OUT_PNG, " and ", OUT_PDF)
message("=== 11_macro_context_figure.R done ===")
