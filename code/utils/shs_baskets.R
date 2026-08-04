# code/utils/shs_baskets.R
# Frozen SHS basket definitions, region collapse, and age/tenure maps.
# Necessities_0 = food + shelter + health (CL030 / TR001 are memo lines only).

SHS_MISSING <- 99999999.96

#' Province / geography codes → project analytic regions
#' BC | ON+QC+MB | AB+SK | Atlantic (PE,NS,NL,NB; 2017 collapsed "14")
shs_region_from_prov <- function(prov) {
  p <- trimws(as.character(prov))
  # Normalize to 1–2 digit character codes ("10","59","14", …)
  pi <- suppressWarnings(as.integer(p))
  p2 <- ifelse(is.na(pi), p, sprintf("%02d", pi))
  dplyr::case_when(
    p2 == "59" ~ "BC",
    p2 %in% c("35", "24", "46") ~ "ON+QC+MB",
    p2 %in% c("48", "47") ~ "AB+SK",
    p2 %in% c("10", "11", "12", "13", "14") ~ "Atlantic",
    p2 == "63" ~ "Territories",
    TRUE ~ NA_character_
  )
}

shs_age_band <- function(agegp) {
  g <- suppressWarnings(as.integer(trimws(as.character(agegp))))
  dplyr::case_when(
    g == 1L ~ "<30",
    g == 2L ~ "30-39",
    g == 3L ~ "40-54",
    g == 4L ~ "55-64",
    g == 5L ~ "65-74",
    g == 6L ~ "75+",
    TRUE ~ NA_character_
  )
}

shs_tenure_label <- function(tenure) {
  t <- suppressWarnings(as.integer(trimws(as.character(tenure))))
  dplyr::case_when(
    t == 1L ~ "owner_mortgage",
    t == 2L ~ "owner_free_clear",
    t == 3L ~ "renter",
    TRUE ~ NA_character_
  )
}

#' Replace SHS missing sentinels with NA
shs_na_sentinels <- function(x, missing = SHS_MISSING) {
  x <- as.numeric(x)
  x[!is.finite(x) | x >= missing - 1e-6] <- NA_real_
  x
}

#' Attach basket aggregates (frozen v1 definitions)
shs_attach_baskets <- function(df) {
  df %>%
    dplyr::mutate(
      necessities = FD001 + SH001 + HC001,
      discretionary = TC001 - necessities,
      share_necessities = dplyr::if_else(is.finite(TC001) & TC001 > 0, necessities / TC001, NA_real_),
      share_shelter = dplyr::if_else(is.finite(TC001) & TC001 > 0, SH001 / TC001, NA_real_),
      share_discretionary = dplyr::if_else(is.finite(TC001) & TC001 > 0, discretionary / TC001, NA_real_),
      share_food = dplyr::if_else(is.finite(TC001) & TC001 > 0, FD001 / TC001, NA_real_),
      share_health = dplyr::if_else(is.finite(TC001) & TC001 > 0, HC001 / TC001, NA_real_),
      share_clothing = dplyr::if_else(is.finite(TC001) & TC001 > 0 & is.finite(CL030), CL030 / TC001, NA_real_),
      share_transport = dplyr::if_else(is.finite(TC001) & TC001 > 0 & is.finite(TR001), TR001 / TC001, NA_real_),
      cy_ratio = dplyr::if_else(is.finite(HHTOTINC) & HHTOTINC > 0, TC001 / HHTOTINC, NA_real_),
      shelter_over_inc = dplyr::if_else(is.finite(HHTOTINC) & HHTOTINC > 0, SH001 / HHTOTINC, NA_real_),
      mortpay_over_inc = dplyr::if_else(
        tenure == "owner_mortgage" & is.finite(HHTOTINC) & HHTOTINC > 0 & is.finite(SH011),
        SH011 / HHTOTINC,
        NA_real_
      ),
      income_at = dplyr::if_else(is.finite(HHTOTINC) & is.finite(TX010), HHTOTINC - TX010, NA_real_),
      cy_ratio_at = dplyr::if_else(is.finite(income_at) & income_at > 0, TC001 / income_at, NA_real_)
    )
}

#' Within-year weighted income quintiles (not wealth)
shs_attach_income_quintile <- function(df) {
  years <- sort(unique(df$year))
  out <- vector("list", length(years))
  for (i in seq_along(years)) {
    g <- df[df$year == years[[i]], , drop = FALSE]
    ok <- is.finite(g$HHTOTINC) & is.finite(g$WEIGHTD) & g$WEIGHTD > 0
    g$inc_q <- NA_integer_
    if (sum(ok) >= 20L) {
      brks <- as.numeric(Hmisc::wtd.quantile(
        g$HHTOTINC[ok],
        weights = g$WEIGHTD[ok],
        probs = c(0, 0.2, 0.4, 0.6, 0.8, 1),
        na.rm = TRUE
      ))
      for (j in 2:length(brks)) {
        if (!is.finite(brks[j]) || brks[j] <= brks[j - 1]) {
          brks[j] <- brks[j - 1] + 1e-6
        }
      }
      g$inc_q[ok] <- as.integer(cut(
        g$HHTOTINC[ok],
        breaks = brks,
        include.lowest = TRUE,
        labels = FALSE
      ))
    }
    out[[i]] <- g
  }
  dplyr::bind_rows(out) %>%
    dplyr::mutate(
      inc_q = factor(inc_q, levels = 1:5, labels = paste0("Q", 1:5))
    )
}
