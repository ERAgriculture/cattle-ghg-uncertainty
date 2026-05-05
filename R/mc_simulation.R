# Monte Carlo Simulation Runner

# Run MC simulation for one system-subsystem combination
run_mc_simulation <- function(param_specs, corr_matrix = NULL, n_iter = 10000,
                               mms_fractions = NULL, mcf_values = NULL, ef3_values = NULL,
                               gwp = "AR5", seed = NULL, ef_corr_matrix = NULL,
                               # E1, E3: optional IPCC software inputs
                               Tw = 20, pct_calving = 1) {
  samples <- generate_mc_samples(param_specs, corr_matrix, n_iter, seed, ef_corr_matrix)

  get_param <- function(name, default = 0) {
    if (name %in% names(samples)) samples[[name]] else rep(default, n_iter)
  }

  if (is.null(mms_fractions)) mms_fractions <- c(pasture = 1.0)
  if (is.null(mcf_values)) mcf_values <- c(pasture = 0.015)
  if (is.null(ef3_values)) ef3_values <- c(pasture = 0.02)

  # C1: parameter names IPCC-aligned (DE, CP, Ym, ASH, Frac_GASMS, Frac_LEACH_H).
  # get_param() falls back to legacy names so old templates still work.
  get_param_alt <- function(new_name, old_name, default = 0) {
    if (new_name %in% names(samples)) samples[[new_name]]
    else if (old_name %in% names(samples)) samples[[old_name]]
    else rep(default, n_iter)
  }

  # R1.6: full IPCC variable rename — look up new IPCC names first, fall back to legacy
  results <- ghg_emissions_vec(
    cattle_pop    = get_param_alt("N",       "cattle_pop",    0),
    live_weight   = get_param_alt("W",       "live_weight",   275),
    weight_gain   = get_param_alt("WG",      "weight_gain",   0),
    mature_weight = get_param_alt("MW",      "mature_weight", 300),
    milk_yield    = get_param_alt("Milk",    "milk_yield",    0),
    milk_fat      = get_param_alt("Fat",     "milk_fat",      4),
    pct_lactating = get_param("pct_lactating", 1),
    hours         = get_param("hours", 0),
    DE            = get_param_alt("DE",      "DE_pct",        55),
    Cfi           = get_param("Cfi", 0.322),
    Ca            = get_param("Ca", 0.17),
    C_growth      = get_param_alt("C",       "C_growth",      0.8),
    Cp            = get_param("Cp", 0.10),
    Ym            = get_param_alt("Ym",      "Ym_pct",        6.5),
    Bo            = get_param("Bo", 0.10),
    ASH           = get_param_alt("ASH",     "ash",           0.08),
    UE            = get_param("UE", 0.04),
    CP            = get_param_alt("CP",      "CP_pct",        10),
    mms_fractions = mms_fractions,
    mcf_values    = mcf_values,
    ef3_values    = ef3_values,
    EF3_PRP       = get_param("EF3_PRP", 0.02),
    Frac_GASMS    = get_param_alt("Frac_GASMS",   "Frac_GASM",  0.20),
    EF4           = get_param("EF4", 0.010),
    EF5           = get_param("EF5", 0.0075),
    Frac_LEACH_H  = get_param_alt("Frac_LEACH_H", "Frac_LEACH", 0.02),
    gwp = gwp,
    Tw = Tw, pct_calving = pct_calving
  )

  list(samples = samples, results = results)
}

# Run simulation across multiple systems/subsystems
run_inventory_simulation <- function(systems_data, n_iter = 10000, gwp = "AR5",
                                      seed = NULL, Tw = 20, pct_calving = 1) {
  by_system <- list()

  for (sys_name in names(systems_data)) {
    sys <- systems_data[[sys_name]]
    sim <- run_mc_simulation(
      param_specs     = sys$param_specs,
      corr_matrix     = sys$corr_matrix,
      n_iter          = n_iter,
      mms_fractions   = sys$mms_fractions,
      mcf_values      = sys$mcf_values,
      ef3_values      = sys$ef3_values,
      gwp             = gwp,
      seed            = if (!is.null(seed)) seed + which(names(systems_data) == sys_name) else NULL,
      ef_corr_matrix  = sys$ef_corr_matrix,
      Tw              = if (!is.null(sys$Tw)) sys$Tw else Tw,
      pct_calving     = if (!is.null(sys$pct_calving)) sys$pct_calving else pct_calving
    )
    by_system[[sys_name]] <- sim
  }

  # Sum across systems per iteration
  inventory_results <- data.frame(
    total_enteric_ch4 = rowSums(sapply(by_system, function(s) s$results$enteric_ch4_total)),
    total_manure_ch4 = rowSums(sapply(by_system, function(s) s$results$manure_ch4_total)),
    total_direct_n2o = rowSums(sapply(by_system, function(s) s$results$direct_n2o_mm_total + s$results$direct_n2o_prp_total)),
    total_indirect_n2o = rowSums(sapply(by_system, function(s) s$results$indirect_n2o_mm_total + s$results$indirect_n2o_prp_total)),
    total_ch4 = rowSums(sapply(by_system, function(s) s$results$total_ch4)),
    total_n2o = rowSums(sapply(by_system, function(s) s$results$total_n2o)),
    total_co2e = rowSums(sapply(by_system, function(s) s$results$total_co2e))
  )

  list(by_system = by_system, inventory = inventory_results)
}
