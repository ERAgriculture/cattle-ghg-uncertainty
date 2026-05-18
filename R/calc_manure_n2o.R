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
# Round 7 R1.13: per-MMS Frac_GasMS and Frac_LeachMS per IPCC 2019 Refinement
# Vol 4 Ch 10 Eq 10.26 / 10.28. EF4 and EF5 stay broadcast scalars (per IPCC
# 2019 they are invariant by MMS).
#
# Accepts EITHER:
#   (a) `frac_gas_values` / `frac_leach_values` as named vectors keyed by
#       mms_type (post-Round-7 calling convention), OR
#   (b) `frac_gas` / `frac_leach` as scalars (pre-Round-7 broadcast convention,
#       still accepted for back-compat — the wrapper builds constant vectors).
calc_indirect_n2o_mm <- function(Nex, mms_fractions,
                                  frac_gas_values  = NULL,
                                  frac_leach_values = NULL,
                                  EF4 = 0.010, EF5 = 0.0075,
                                  frac_gas   = 0.20,
                                  frac_leach = 0.02) {
  total <- 0
  for (mms in names(mms_fractions)) {
    if (mms == "pasture") next
    frac <- mms_fractions[mms]
    fg <- if (!is.null(frac_gas_values) && mms %in% names(frac_gas_values)
              && !is.na(frac_gas_values[mms])) {
      frac_gas_values[mms]
    } else {
      # NA fallback to IPCC 2019 default per MMS, then to broadcast scalar
      def <- mms_frac_defaults_2019(mms)
      if (!is.na(def$frac_gas)) def$frac_gas else frac_gas
    }
    fl <- if (!is.null(frac_leach_values) && mms %in% names(frac_leach_values)
              && !is.na(frac_leach_values[mms])) {
      frac_leach_values[mms]
    } else {
      def <- mms_frac_defaults_2019(mms)
      if (!is.na(def$frac_leach)) def$frac_leach else frac_leach
    }
    total <- total + Nex * frac * fg * EF4 * (44 / 28)
    total <- total + Nex * frac * fl * EF5 * (44 / 28)
  }
  total
}

# Direct N2O from pasture/range/paddock (PRP) - kg N2O/head/year
calc_direct_n2o_prp <- function(Nex, pct_pasture, EF3_PRP = 0.02) {
  N_prp <- Nex * pct_pasture
  N_prp * EF3_PRP * (44 / 28)
}

# Indirect N2O from PRP - kg N2O/head/year
# Andreas 2026-05 comment #10: PRP volatilisation and leaching use IPCC 2019
# Vol 4 Ch 11 Table 11.3 defaults (FracGASM ≈ 0.21, Frac_leach-(H) ≈ 0.30) —
# distinct from the MM-side fractions in Table 10.22. Earlier versions reused
# Frac_GASMS / Frac_LEACH_H for both pathways, conflating the two.
calc_indirect_n2o_prp <- function(Nex, pct_pasture,
                                   Frac_GASM_PRP = 0.21, EF4 = 0.010,
                                   Frac_LEACH_PRP = 0.30, EF5 = 0.0075) {
  N_prp <- Nex * pct_pasture
  volatilization <- N_prp * Frac_GASM_PRP * EF4 * (44 / 28)
  leaching <- N_prp * Frac_LEACH_PRP * EF5 * (44 / 28)
  volatilization + leaching
}
