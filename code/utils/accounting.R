# code/utils/accounting.R — IG / IT / NIG and revaluation helpers

#' Consol / perpetual PV wedge from nominal vs real rate
#' Observed holding V is treated as valued at real rate r.
#' Value at nominal rn would be V * r / rn; gain = V*(1 - r/rn).
#' Floors avoid explosive 1/r when real rates are near zero (Canada 2010s–2020s).
pv_inflation_wedge <- function(V, r_nom, r_real, r_floor = 0.005, max_wedge = 0.50) {
  V <- na2zero(V)
  n <- length(V)
  if (length(r_nom) == 1L) r_nom <- rep(as.numeric(r_nom), n)
  if (length(r_real) == 1L) r_real <- rep(as.numeric(r_real), n)
  r_n <- pmax(r_nom, r_floor)
  r_r <- pmax(r_real, r_floor)
  # Keep Fisher ordering when possible
  r_n <- pmax(r_n, r_r + 1e-4)
  wedge_frac <- pmin(pmax(1 - r_r / r_n, 0), max_wedge)
  V * wedge_frac
}

#' Duration-style revaluation from a change in yield: dP/P ≈ -D * dr / (1+r)
duration_reval <- function(V, dr, r, duration) {
  V <- na2zero(V)
  scale <- -duration * dr / pmax(1 + r, 0.5)
  V * scale
}

#' Mortgage affordability house-price factor (Canadian 5y term, 25y amort proxy)
#' Payment on loan L at rate m, amort A years, monthly.
mortgage_payment <- function(L, m_annual, amort_years = 25) {
  i <- m_annual / 12
  n <- amort_years * 12
  ifelse(i <= 0, L / n, L * i * (1 + i)^n / ((1 + i)^n - 1))
}

#' Relative house price affordable at same payment when mortgage rate changes
house_price_ratio <- function(m0, m1, LTV = 0.80, amort_years = 25) {
  # Price P, loan = LTV*P; fix payment at m0 for P=1, solve P' at m1
  pay0 <- mortgage_payment(LTV, m0, amort_years)
  # At m1, loan' = LTV * P'; payment(loan', m1) = pay0 => loan' from payment inversion
  # Approximate: P1/P0 ≈ payment factor inverse
  # For small changes use numerical ratio with P0=1
  pay_at <- function(P, m) mortgage_payment(LTV * P, m, amort_years)
  # Find P1 such that pay_at(P1,m1) = pay_at(1,m0)
  target <- pay_at(1, m0)
  # Binary search
  lo <- 0.2; hi <- 3
  for (k in 1:40) {
    mid <- (lo + hi) / 2
    if (pay_at(mid, m1) > target) hi <- mid else lo <- mid
  }
  (lo + hi) / 2
}
