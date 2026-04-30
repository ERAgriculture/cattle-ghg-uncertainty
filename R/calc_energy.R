# IPCC Tier 2 Energy Requirement Calculations
# Source: IPCC 2006 Guidelines, Volume 4, Chapter 10

# Net Energy for Maintenance (Eq 10.3) - MJ/head/day
calc_nem <- function(live_weight, Cfi) {
  Cfi * (live_weight ^ 0.75)
}

# Net Energy for Activity (Eq 10.4) - MJ/head/day
calc_nea <- function(nem, Ca) {
  Ca * nem
}

# Net Energy for Growth (Eq 10.6) - MJ/head/day
calc_neg <- function(live_weight, weight_gain, C, mature_weight) {
  if (weight_gain <= 0 || mature_weight <= 0) return(0)
  22.02 * ((live_weight / (C * mature_weight)) ^ 0.75) * (weight_gain ^ 1.097)
}

# Net Energy for Lactation (Eq 10.8) - MJ/head/day
calc_nel <- function(milk_yield, milk_fat, pct_lactating = 1) {
  milk_yield * (1.47 + 0.40 * milk_fat) * pct_lactating
}

# Net Energy for Work (Eq 10.11) - MJ/head/day
calc_new <- function(nem, hours) {
  0.10 * nem * hours
}

# Net Energy for Pregnancy (Eq 10.13) - MJ/head/day
calc_nep <- function(nem, Cp) {
  Cp * nem
}

# REM - Ratio of NE for maintenance to DE consumed (Eq 10.14)
calc_rem <- function(DE_pct) {
  1.123 - (4.092e-3 * DE_pct) + (1.126e-5 * DE_pct^2) - (25.4 / DE_pct)
}

# REG - Ratio of NE for growth to DE consumed (Eq 10.15)
calc_reg <- function(DE_pct) {
  1.164 - (5.160e-3 * DE_pct) + (1.308e-5 * DE_pct^2) - (37.4 / DE_pct)
}

# Gross Energy intake (Eq 10.16) - MJ/head/day
calc_ge <- function(nem, nea, nel, nep, new_energy, neg, rem, reg, DE_pct) {
  GE_num <- (nem + nea + nel + new_energy + nep) / rem + neg / reg
  GE_num / (DE_pct / 100)
}
