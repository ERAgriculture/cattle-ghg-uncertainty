# IPCC Tier 2 Manure Management N2O Emissions
# Source: IPCC 2006 Guidelines, Volume 4, Chapter 10 (Eq 10.25-10.34) & Chapter 11

# Nitrogen excretion rate - kg N/head/year (simplified from Eq 10.31-10.34)
# C1: DE (was DE_pct), CP (was CP_pct) — IPCC software-aligned names
calc_n_excretion <- function(ge, DE, CP, milk_yield = 0, pct_lactating = 0, weight_gain = 0) {
  DMI <- (ge * DE / 100) / 18.45
  N_intake <- DMI * (CP / 100) / 6.25

  N_retained <- 0
  if (milk_yield > 0 && pct_lactating > 0) {
    milk_protein <- 3.3
    N_retained <- milk_yield * pct_lactating * milk_protein / 100 / 6.38
  }
  if (weight_gain > 0) {
    N_retained <- N_retained + weight_gain * 0.032
  }

  max(0, (N_intake - N_retained) * 365)
}

# Direct N2O from manure management (Eq 10.25) - kg N2O/head/year
# Excludes pasture (handled separately as PRP)
calc_direct_n2o_mm <- function(Nex, mms_fractions, ef3_values) {
  total <- 0
  for (mms in names(mms_fractions)) {
    if (mms == "pasture") next
    frac <- mms_fractions[mms]
    ef3 <- ef3_values[mms]
    total <- total + Nex * frac * ef3 * (44 / 28)
  }
  total
}

# Indirect N2O from manure management - kg N2O/head/year
calc_indirect_n2o_mm <- function(Nex, mms_fractions, frac_gas = 0.20, EF4 = 0.010,
                                  frac_leach = 0.02, EF5 = 0.0075) {
  total <- 0
  for (mms in names(mms_fractions)) {
    if (mms == "pasture") next
    frac <- mms_fractions[mms]
    total <- total + Nex * frac * frac_gas * EF4 * (44 / 28)
    total <- total + Nex * frac * frac_leach * EF5 * (44 / 28)
  }
  total
}

# Direct N2O from pasture/range/paddock (PRP) - kg N2O/head/year
calc_direct_n2o_prp <- function(Nex, pct_pasture, EF3_PRP = 0.02) {
  N_prp <- Nex * pct_pasture
  N_prp * EF3_PRP * (44 / 28)
}

# Indirect N2O from PRP - kg N2O/head/year
# C1: Frac_GASMS (was Frac_GASM), Frac_LEACH_H (was Frac_LEACH) — IPCC software-aligned
calc_indirect_n2o_prp <- function(Nex, pct_pasture, Frac_GASMS = 0.20, EF4 = 0.010,
                                   Frac_LEACH_H = 0.02, EF5 = 0.0075) {
  N_prp <- Nex * pct_pasture
  volatilization <- N_prp * Frac_GASMS * EF4 * (44 / 28)
  leaching <- N_prp * Frac_LEACH_H * EF5 * (44 / 28)
  volatilization + leaching
}
