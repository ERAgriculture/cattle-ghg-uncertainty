# Master GHG Emissions Calculation
# Combines enteric fermentation, manure CH4, and manure N2O pathways

# Master function for a single animal sub-category - returns named list
ghg_emissions <- function(
  cattle_pop, live_weight, weight_gain, mature_weight,
  milk_yield, milk_fat, pct_lactating,
  hours, DE_pct, Cfi, Ca, C_growth, Cp,
  Ym_pct, Bo, ash, UE, CP_pct,
  mms_fractions, mcf_values, ef3_values,
  EF3_PRP, Frac_GASM, EF4, EF5, Frac_LEACH,
  gwp = "AR5"
) {
  nem <- calc_nem(live_weight, Cfi)
  nea <- calc_nea(nem, Ca)
  neg <- calc_neg(live_weight, weight_gain, C_growth, mature_weight)
  nel <- calc_nel(milk_yield, milk_fat, pct_lactating)
  new_energy <- calc_new(nem, hours)
  nep <- calc_nep(nem, Cp)
  rem <- calc_rem(DE_pct)
  reg <- calc_reg(DE_pct)
  ge <- calc_ge(nem, nea, nel, nep, new_energy, neg, rem, reg, DE_pct)

  # Enteric CH4
  enteric_ch4_head <- calc_enteric_ch4(ge, Ym_pct)
  enteric_ch4_total <- (enteric_ch4_head * cattle_pop) / 1000

  # Manure CH4
  VS <- calc_volatile_solids(ge, DE_pct, UE, ash)
  manure_ch4_head <- calc_manure_ch4(VS, Bo, mms_fractions, mcf_values)
  manure_ch4_total <- (manure_ch4_head * cattle_pop) / 1000

  # N excretion and N2O
  Nex <- calc_n_excretion(ge, DE_pct, CP_pct, milk_yield, pct_lactating, weight_gain)
  pct_pasture <- ifelse("pasture" %in% names(mms_fractions), mms_fractions["pasture"], 0)

  direct_n2o_mm_head <- calc_direct_n2o_mm(Nex, mms_fractions, ef3_values)
  indirect_n2o_mm_head <- calc_indirect_n2o_mm(Nex, mms_fractions, 0.20, EF4, 0.02, EF5)
  direct_n2o_prp_head <- calc_direct_n2o_prp(Nex, pct_pasture, EF3_PRP)
  indirect_n2o_prp_head <- calc_indirect_n2o_prp(Nex, pct_pasture, Frac_GASM, EF4, Frac_LEACH, EF5)

  direct_n2o_mm_total <- (direct_n2o_mm_head * cattle_pop) / 1000
  indirect_n2o_mm_total <- (indirect_n2o_mm_head * cattle_pop) / 1000
  direct_n2o_prp_total <- (direct_n2o_prp_head * cattle_pop) / 1000
  indirect_n2o_prp_total <- (indirect_n2o_prp_head * cattle_pop) / 1000

  total_ch4 <- enteric_ch4_total + manure_ch4_total
  total_n2o <- direct_n2o_mm_total + indirect_n2o_mm_total + direct_n2o_prp_total + indirect_n2o_prp_total

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
  hours, DE_pct, Cfi, Ca, C_growth, Cp,
  Ym_pct, Bo, ash, UE, CP_pct,
  mms_fractions, mcf_values, ef3_values,
  EF3_PRP, Frac_GASM, EF4, EF5, Frac_LEACH,
  gwp = "AR5"
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

  for (i in seq_len(n)) {
    r <- ghg_emissions(
      cattle_pop[i], live_weight[i], weight_gain[i], mature_weight[i],
      milk_yield[i], milk_fat[i], pct_lactating[i],
      hours[i], DE_pct[i], Cfi[i], Ca[i], C_growth[i], Cp[i],
      Ym_pct[i], Bo[i], ash[i], UE[i], CP_pct[i],
      mms_fractions, mcf_values, ef3_values,
      EF3_PRP[i], Frac_GASM[i], EF4[i], EF5[i], Frac_LEACH[i],
      gwp
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
