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

#' Mortgage affordability house-price factor
#' Payment on loan L at annual rate m, amort A years, monthly compounding.
#' @param amort_years Amortization length (Wolff US FRM: 30; Canada baseline: 25)
#' @param LTV Loan-to-value (Wolff often ~0.80 with 20% down)
mortgage_payment <- function(L, m_annual, amort_years = 25) {
  i <- m_annual / 12
  n <- amort_years * 12
  ifelse(i <= 0, L / n, L * i * (1 + i)^n / ((1 + i)^n - 1))
}

#' Relative house price affordable at same payment when mortgage rate changes
#' Term length does not enter the payment formula under standard amortization
#' accounting (Canadian renewals reprice the rate; amortization sets the payment).
#' Use different *rate series* (e.g. 3y vs 5y) to reflect term choice; use
#' amort_years to compare Wolff 30y FRM vs Canadian 25/30y amort schedules.
house_price_ratio <- function(m0, m1, LTV = 0.80, amort_years = 25) {
  pay_at <- function(P, m) mortgage_payment(LTV * P, m, amort_years)
  target <- pay_at(1, m0)
  lo <- 0.2
  hi <- 3
  for (k in 1:40) {
    mid <- (lo + hi) / 2
    if (pay_at(mid, m1) > target) hi <- mid else lo <- mid
  }
  (lo + hi) / 2
}

#' OSFI-style qualifying (stress) rate proxy: max(contract + 2pp, floor)
stress_mortgage_rate <- function(m_contract, add = 0.02, floor = 0.0525) {
  pmax(m_contract + add, floor)
}

#' Affordable price index across a grid of rates (Wolff-style chart input)
#' Normalizes so price = 1 at rate_base.
affordable_price_curve <- function(rates, rate_base, LTV = 0.80, amort_years = 30) {
  vapply(rates, function(m) house_price_ratio(rate_base, m, LTV, amort_years), numeric(1))
}
