# Master GHG Emissions Calculation
# Combines enteric fermentation, manure CH4, and manure N2O pathways
# C1: variable names IPCC-aligned (DE, CP, Ym, ASH, Frac_GASMS, Frac_LEACH_H)

# Master function for a single animal sub-category - returns named list
ghg_emissions <- function(
  cattle_pop, live_weight, weight_gain, mature_weight,
  milk_yield, milk_fat, pct_lactating,
  hours, DE, Cfi, Ca, C_growth, Cp,
  Ym, Bo, ASH, UE, CP,
  mms_fractions, mcf_values, ef3_values,
  EF3_PRP, Frac_GASMS, EF4, EF5, Frac_LEACH_H,
  gwp = "AR5",
  # E1, E3: optional IPCC-software-aligned inputs
  Tw = 20, pct_calving = 1,
  # Round 7 R1.13: per-MMS Frac_GasMS / Frac_LeachMS named vectors. NULL =
  # use IPCC 2019 defaults from mms_frac_defaults_2019(). For back-compat with
  # callers that haven't been updated, the legacy broadcast Frac_GASMS scalar
  # above is still applied to the manure-management indirect path as a fallback.
  frac_gas_values   = NULL,
  frac_leach_values = NULL,
  # Andreas 2026-05 comment #10: PRP volatilization/leaching fractions are
  # distinct from MM (IPCC 2019 Table 11.3 vs Table 10.22). NULL = fall back
  # to Table 11.3 defaults for back-compat with callers that don't yet pass
  # PRP-specific values.
  Frac_GASM_PRP  = NULL,
  Frac_LEACH_PRP = NULL
) {
  # E1: cold-climate Cfi adjustment via Tw
  nem <- calc_nem(live_weight, Cfi, Tw = Tw)
  nea <- calc_nea(nem, Ca)
  neg <- calc_neg(live_weight, weight_gain, C_growth, mature_weight)
  nel <- calc_nel(milk_yield, milk_fat, pct_lactating)
  new_energy <- calc_new(nem, hours)
  # E3: Cp pro-rated by % of females calving in a year
  nep <- calc_nep(nem, Cp, pct_calving = pct_calving)
  rem <- calc_rem(DE)
  reg <- calc_reg(DE)
  ge <- calc_ge(nem, nea, nel, nep, new_energy, neg, rem, reg, DE)

  # Enteric CH4
  enteric_ch4_head <- calc_enteric_ch4(ge, Ym)
  enteric_ch4_total <- (enteric_ch4_head * cattle_pop) / 1000

  # Manure CH4
  VS <- calc_volatile_solids(ge, DE, UE, ASH)
  manure_ch4_head <- calc_manure_ch4(VS, Bo, mms_fractions, mcf_values)
  manure_ch4_total <- (manure_ch4_head * cattle_pop) / 1000

  # N excretion and N2O
  Nex <- calc_n_excretion(ge, DE, CP, milk_yield, pct_lactating, weight_gain)
  pct_pasture <- ifelse("pasture" %in% names(mms_fractions),
                        mms_fractions["pasture"], 0)

  direct_n2o_mm_head <- calc_direct_n2o_mm(Nex, mms_fractions, ef3_values)
  indirect_n2o_mm_head <- calc_indirect_n2o_mm(
    Nex, mms_fractions,
    frac_gas_values  = frac_gas_values,
    frac_leach_values = frac_leach_values,
    EF4 = EF4, EF5 = EF5,
    frac_gas = Frac_GASMS, frac_leach = Frac_LEACH_H
  )
  direct_n2o_prp_head <- calc_direct_n2o_prp(Nex, pct_pasture, EF3_PRP)
  # Andreas 2026-05 #10: prefer PRP-specific Frac defaults (Table 11.3) when
  # supplied; fall back to the function defaults (0.21 / 0.30) if the caller
  # passed NULL.
  prp_fg <- if (!is.null(Frac_GASM_PRP))  Frac_GASM_PRP  else 0.21
  prp_fl <- if (!is.null(Frac_LEACH_PRP)) Frac_LEACH_PRP else 0.30
  indirect_n2o_prp_head <- calc_indirect_n2o_prp(
    Nex, pct_pasture,
    Frac_GASM_PRP  = prp_fg, EF4 = EF4,
    Frac_LEACH_PRP = prp_fl, EF5 = EF5)

  direct_n2o_mm_total <- (direct_n2o_mm_head * cattle_pop) / 1000
  indirect_n2o_mm_total <- (indirect_n2o_mm_head * cattle_pop) / 1000
  direct_n2o_prp_total <- (direct_n2o_prp_head * cattle_pop) / 1000
  indirect_n2o_prp_total <- (indirect_n2o_prp_head * cattle_pop) / 1000

  total_ch4 <- enteric_ch4_total + manure_ch4_total
  total_n2o <- direct_n2o_mm_total + indirect_n2o_mm_total +
               direct_n2o_prp_total + indirect_n2o_prp_total

  gwp_vals <- GWP_VALUES[[gwp]]
  co2e_ch4 <- total_ch4 * gwp_vals$CH4
  co2e_n2o <- total_n2o * gwp_vals$N2O
  total_co2e <- co2e_ch4 + co2e_n2o

  list(
    ge = ge, enteric_ch4_head = enteric_ch4_head,
    enteric_ch4_total = enteric_ch4_total,
    VS = VS, manure_ch4_head = manure_ch4_head,
    manure_ch4_total = manure_ch4_total,
    Nex = Nex,
    direct_n2o_mm_total = direct_n2o_mm_total,
    indirect_n2o_mm_total = indirect_n2o_mm_total,
    direct_n2o_prp_total = direct_n2o_prp_total,
    indirect_n2o_prp_total = indirect_n2o_prp_total,
    total_ch4 = total_ch4, total_n2o = total_n2o,
    co2e_ch4 = co2e_ch4, co2e_n2o = co2e_n2o,
    total_co2e = total_co2e
  )
}

# Vectorized version for Monte Carlo - returns data.frame
ghg_emissions_vec <- function(
  cattle_pop, live_weight, weight_gain, mature_weight,
  milk_yield, milk_fat, pct_lactating,
  hours, DE, Cfi, Ca, C_growth, Cp,
  Ym, Bo, ASH, UE, CP,
  mms_fractions, mcf_values, ef3_values,
  EF3_PRP, Frac_GASMS, EF4, EF5, Frac_LEACH_H,
  gwp = "AR5",
  Tw = 20, pct_calving = 1,
  frac_gas_values   = NULL,
  frac_leach_values = NULL,
  # Andreas 2026-05 #10: PRP-specific volatilization/leaching fractions
  # (IPCC 2019 Table 11.3). NULL = broadcast a constant from IPCC defaults.
  Frac_GASM_PRP  = NULL,
  Frac_LEACH_PRP = NULL
) {
  n <- length(cattle_pop)
  results <- data.frame(
    enteric_ch4_total = numeric(n),
    manure_ch4_total = numeric(n),
    direct_n2o_mm_total = numeric(n),
    indirect_n2o_mm_total = numeric(n),
    direct_n2o_prp_total = numeric(n),
    indirect_n2o_prp_total = numeric(n),
    total_ch4 = numeric(n),
    total_n2o = numeric(n),
    total_co2e = numeric(n)
  )

  # Andreas 2026-05 follow-up: removed Dirichlet `mms_fractions_matrix` path —
  # MMS% is now deterministic across iterations (matches IPCC Inventory Software).

  # Broadcast PRP fractions to length n if scalar / NULL (back-compat path).
  prp_fg_vec <- if (is.null(Frac_GASM_PRP))  rep(0.21, n) else
                if (length(Frac_GASM_PRP)  == 1) rep(Frac_GASM_PRP,  n) else Frac_GASM_PRP
  prp_fl_vec <- if (is.null(Frac_LEACH_PRP)) rep(0.30, n) else
                if (length(Frac_LEACH_PRP) == 1) rep(Frac_LEACH_PRP, n) else Frac_LEACH_PRP

  for (i in seq_len(n)) {
    r <- ghg_emissions(
      cattle_pop[i], live_weight[i], weight_gain[i], mature_weight[i],
      milk_yield[i], milk_fat[i], pct_lactating[i],
      hours[i], DE[i], Cfi[i], Ca[i], C_growth[i], Cp[i],
      Ym[i], Bo[i], ASH[i], UE[i], CP[i],
      mms_fractions, mcf_values, ef3_values,
      EF3_PRP[i], Frac_GASMS[i], EF4[i], EF5[i], Frac_LEACH_H[i],
      gwp,
      Tw = Tw, pct_calving = if (length(pct_calving) > 1) pct_calving[i] else pct_calving,
      frac_gas_values   = frac_gas_values,
      frac_leach_values = frac_leach_values,
      Frac_GASM_PRP  = prp_fg_vec[i],
      Frac_LEACH_PRP = prp_fl_vec[i]
    )
    results$enteric_ch4_total[i] <- r$enteric_ch4_total
    results$manure_ch4_total[i] <- r$manure_ch4_total
    results$direct_n2o_mm_total[i] <- r$direct_n2o_mm_total
    results$indirect_n2o_mm_total[i] <- r$indirect_n2o_mm_total
    results$direct_n2o_prp_total[i] <- r$direct_n2o_prp_total
    results$indirect_n2o_prp_total[i] <- r$indirect_n2o_prp_total
    results$total_ch4[i] <- r$total_ch4
    results$total_n2o[i] <- r$total_n2o
    results$total_co2e[i] <- r$total_co2e
  }
  results
}
