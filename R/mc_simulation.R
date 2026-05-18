# Monte Carlo Simulation Runner

# Run MC simulation for one system-subsystem combination
run_mc_simulation <- function(param_specs, corr_matrix = NULL, n_iter = 10000,
                               mms_fractions = NULL, mcf_values = NULL, ef3_values = NULL,
                               gwp = "AR5", seed = NULL, ef_corr_matrix = NULL,
                               # E1, E3: optional IPCC software inputs
                               Tw = 20, pct_calving = 1,
                               # Round 7 R1.13: per-MMS Frac_GasMS / Frac_LeachMS
                               # named vectors. NULL = fall back to IPCC 2019
                               # defaults inside calc_indirect_n2o_mm.
                               frac_gas_values = NULL, frac_leach_values = NULL,
                               # Round 7 T4.3: unified copula across AD + coefficients
                               unified_corr_matrix = NULL,
                               # Round 7 R1.14: pre-sampled coefficient block (trend mode)
                               pre_sampled_coefficients = NULL,
                               # Round 7 T4.21: per-iteration MMS fractions matrix
                               # (n_iter x n_mms). When supplied, overrides the scalar
                               # mms_fractions argument with row i for iteration i.
                               mms_fractions_matrix = NULL) {
  samples <- generate_mc_samples(param_specs, corr_matrix, n_iter, seed, ef_corr_matrix,
                                  unified_corr_matrix = unified_corr_matrix,
                                  pre_sampled_coefficients = pre_sampled_coefficients)

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
    # Andreas 2026-05 #10: PRP-side fractions, distinct from MM (Table 11.3).
    # Falls back to IPCC 2019 Table 11.3 defaults when the template does not
    # provide them (most existing templates won't yet).
    Frac_GASM_PRP  = get_param("Frac_GASM_PRP",  0.21),
    Frac_LEACH_PRP = get_param("Frac_LEACH_PRP", 0.30),
    gwp = gwp,
    Tw = Tw, pct_calving = pct_calving,
    frac_gas_values   = frac_gas_values,
    frac_leach_values = frac_leach_values,
    mms_fractions_matrix = mms_fractions_matrix
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
      pct_calving     = if (!is.null(sys$pct_calving)) sys$pct_calving else pct_calving,
      frac_gas_values   = sys$frac_gas_values,
      frac_leach_values = sys$frac_leach_values,
      unified_corr_matrix      = sys$unified_corr_matrix,
      pre_sampled_coefficients = sys$pre_sampled_coefficients,
      mms_fractions_matrix     = sys$mms_fractions_matrix
    )
    by_system[[sys_name]] <- sim
  }

  # Andreas 2026-05 #33: harden against an empty by_system (or one whose
  # per-iteration result frame has zero rows — which produces the cryptic
  # "replacement has 0 rows, data has 5000" error when downstream code
  # assigns to a pre-allocated column). Bail out with a descriptive error
  # before the rowSums(sapply(...)) call instead.
  if (length(by_system) == 0L) {
    stop("run_inventory_simulation: no systems were simulated. Check that ",
         "Parameters has at least one cattle_type+aggregation_level+sub_category ",
         "group with a non-zero population.")
  }
  row_counts <- vapply(by_system, function(s) nrow(s$results), integer(1))
  if (any(row_counts != n_iter)) {
    stop("run_inventory_simulation: at least one system returned ",
         row_counts[row_counts != n_iter][1], " iterations instead of the ",
         "expected ", n_iter, ". This usually means a sampled parameter ",
         "collapsed to length 0 — re-upload the template after checking ",
         "that every Parameters row has a numeric `mean`.")
  }

  # Sum across systems per iteration. Per-source columns kept *separately* for
  # MM and PRP (Andreas 2026-05 #27, C1 value-boxes) — totals retained for
  # back-compat with consumers that still expect total_direct_n2o /
  # total_indirect_n2o.
  inventory_results <- data.frame(
    total_enteric_ch4    = rowSums(sapply(by_system, function(s) s$results$enteric_ch4_total)),
    total_manure_ch4     = rowSums(sapply(by_system, function(s) s$results$manure_ch4_total)),
    total_direct_n2o_mm  = rowSums(sapply(by_system, function(s) s$results$direct_n2o_mm_total)),
    total_indirect_n2o_mm = rowSums(sapply(by_system, function(s) s$results$indirect_n2o_mm_total)),
    total_direct_n2o_prp  = rowSums(sapply(by_system, function(s) s$results$direct_n2o_prp_total)),
    total_indirect_n2o_prp = rowSums(sapply(by_system, function(s) s$results$indirect_n2o_prp_total)),
    total_direct_n2o     = rowSums(sapply(by_system, function(s) s$results$direct_n2o_mm_total + s$results$direct_n2o_prp_total)),
    total_indirect_n2o   = rowSums(sapply(by_system, function(s) s$results$indirect_n2o_mm_total + s$results$indirect_n2o_prp_total)),
    total_ch4  = rowSums(sapply(by_system, function(s) s$results$total_ch4)),
    total_n2o  = rowSums(sapply(by_system, function(s) s$results$total_n2o)),
    total_co2e = rowSums(sapply(by_system, function(s) s$results$total_co2e))
  )

  list(by_system = by_system, inventory = inventory_results)
}
