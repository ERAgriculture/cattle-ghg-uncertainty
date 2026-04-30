# Monte Carlo Simulation Runner

# Run MC simulation for one system-subsystem combination
run_mc_simulation <- function(param_specs, corr_matrix = NULL, n_iter = 10000,
                               mms_fractions = NULL, mcf_values = NULL, ef3_values = NULL,
                               gwp = "AR5", seed = NULL, ef_corr_matrix = NULL) {
  samples <- generate_mc_samples(param_specs, corr_matrix, n_iter, seed, ef_corr_matrix)

  get_param <- function(name, default = 0) {
    if (name %in% names(samples)) samples[[name]] else rep(default, n_iter)
  }

  if (is.null(mms_fractions)) mms_fractions <- c(pasture = 1.0)
  if (is.null(mcf_values)) mcf_values <- c(pasture = 0.015)
  if (is.null(ef3_values)) ef3_values <- c(pasture = 0.02)

  results <- ghg_emissions_vec(
    cattle_pop = get_param("cattle_pop"),
    live_weight = get_param("live_weight"),
    weight_gain = get_param("weight_gain"),
    mature_weight = get_param("mature_weight"),
    milk_yield = get_param("milk_yield"),
    milk_fat = get_param("milk_fat"),
    pct_lactating = get_param("pct_lactating", 1),
    hours = get_param("hours"),
    DE_pct = get_param("DE_pct", 55),
    Cfi = get_param("Cfi", 0.322),
    Ca = get_param("Ca", 0.17),
    C_growth = get_param("C_growth", 0.8),
    Cp = get_param("Cp", 0.10),
    Ym_pct = get_param("Ym_pct", 6.5),
    Bo = get_param("Bo", 0.10),
    ash = get_param("ash", 0.08),
    UE = get_param("UE", 0.04),
    CP_pct = get_param("CP_pct", 10),
    mms_fractions = mms_fractions,
    mcf_values = mcf_values,
    ef3_values = ef3_values,
    EF3_PRP = get_param("EF3_PRP", 0.02),
    Frac_GASM = get_param("Frac_GASM", 0.20),
    EF4 = get_param("EF4", 0.010),
    EF5 = get_param("EF5", 0.0075),
    Frac_LEACH = get_param("Frac_LEACH", 0.02),
    gwp = gwp
  )

  list(samples = samples, results = results)
}

# Run simulation across multiple systems/subsystems
run_inventory_simulation <- function(systems_data, n_iter = 10000, gwp = "AR5", seed = NULL) {
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
      ef_corr_matrix  = sys$ef_corr_matrix
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
