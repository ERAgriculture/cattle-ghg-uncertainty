# IPCC Tier 2 Energy Requirement Calculations
# Source: IPCC 2006 Guidelines, Volume 4, Chapter 10

# Net Energy for Maintenance (Eq 10.3) - MJ/head/day
# E1: Tw cold-climate adjustment described in IPCC 2006 Vol.4 Ch.10 alongside
# Eq 10.3 (and retained in the 2019 Refinement). No separate equation number
# is assigned; the IPCC Inventory Software v2.95 implements the same formula.
# Cfi(in_cold) = Cfi + 0.0048 * (20 - Tw) when Tw < 20°C; otherwise no adjustment.
# Andreas 2026-05 audit follow-up: warn on extreme Tw values which would
# inflate Cfi by >50%. The linear adjustment is validated for roughly
# -50°C ≤ Tw < 20°C; outside that range it isn't validated.
calc_nem <- function(live_weight, Cfi, Tw = 20) {
  if (!is.na(Tw) && Tw < -50)
    warning("Tw = ", Tw, "°C is extremely cold; cold-climate Cfi adjustment ",
            "(IPCC Vol.4 Ch.10 modifier of Eq 10.3) is only validated for Tw >= -50°C.")
  Cfi_adj <- if (!is.na(Tw) && Tw < 20) Cfi + 0.0048 * (20 - Tw) else Cfi
  Cfi_adj * (live_weight ^ 0.75)
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
calc_nel <- function(milk_yield, milk_fat, pct_calving = 1) {
  milk_yield * (1.47 + 0.40 * milk_fat) * pct_calving
}

# Net Energy for Work (Eq 10.11) - MJ/head/day
calc_new <- function(nem, hours) {
  0.10 * nem * hours
}

# Net Energy for Pregnancy (Eq 10.13) - MJ/head/day
# E3: pct_calving pro-rates Cp for cattle that don't all calve in the same year.
# Default 1.0 = no pro-rating (all females pregnant); IPCC software allows 0-1.
calc_nep <- function(nem, Cp, pct_calving = 1) {
  Cp * pct_calving * nem
}

# REM - Ratio of NE for maintenance to DE consumed (Eq 10.14)
calc_rem <- function(DE) {
  if (any(DE <= 0, na.rm = TRUE))
    stop("calc_rem: DE must be > 0 (got ", DE, "). Check DE_pct in the Parameters sheet.")
  1.123 - (4.092e-3 * DE) + (1.126e-5 * DE^2) - (25.4 / DE)
}

# REG - Ratio of NE for growth to DE consumed (Eq 10.15)
calc_reg <- function(DE) {
  if (any(DE <= 0, na.rm = TRUE))
    stop("calc_reg: DE must be > 0 (got ", DE, "). Check DE_pct in the Parameters sheet.")
  1.164 - (5.160e-3 * DE) + (1.308e-5 * DE^2) - (37.4 / DE)
}

# Gross Energy intake (Eq 10.16) - MJ/head/day
calc_ge <- function(nem, nea, nel, nep, new_energy, neg, rem, reg, DE) {
  GE_num <- (nem + nea + nel + new_energy + nep) / rem + neg / reg
  GE_num / (DE / 100)
}
