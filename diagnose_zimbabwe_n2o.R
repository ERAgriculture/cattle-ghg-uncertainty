# Diagnosis script for Andreas's 2026-05-15 finding (Section A1/A2):
#   Tool's simulated mean for direct N2O MM (24.77 t) is ~25% below the
#   Excel/@Risk mean (33.23 t); for indirect N2O MM, ~43% below.
#
# Approach: reproduce his intensive-dairy run with his source data (from
# 22-07-2023 Zimbabwe Uncertanity Analysis input data_WSv_SWa.xlsx), then
# compute the same outputs three ways:
#   A. Deterministic point estimate (no Monte Carlo)
#   B. Monte Carlo with Dirichlet MMS% sampling OFF
#   C. Monte Carlo with Dirichlet MMS% sampling ON (concentration = 50,
#      the app's default)
#
# Decision tree:
#   - If A disagrees with Excel ~33 t → equations themselves are wrong.
#   - If A agrees with Excel but B disagrees → MC sampling bias unrelated
#     to Dirichlet.
#   - If A and B agree but C disagrees → Dirichlet is the cause.

suppressPackageStartupMessages({
  library(MASS)
})

# ---------- load app code ----------
src_files <- c(
  "R/utils_distributions.R", "R/utils_ipcc_defaults.R",
  "R/utils_template.R", "R/utils_validation.R",
  "R/calc_energy.R", "R/calc_enteric.R", "R/calc_manure_ch4.R",
  "R/calc_manure_n2o.R", "R/calc_ghg_master.R",
  "R/mc_sampling.R", "R/mc_simulation.R"
)
for (f in src_files) source(f)

# ---------- intensive-dairy inputs from Andreas's source data ----------
# 5 sub-categories. Values from "UNC" sheet rows 4-8 (intensive dairy).
# Highveld DE / CP used. Population split from 1996 dairy total (97,649).
# Population split is a guess — Andreas didn't share his exact allocation.
dairy_total_1996 <- 97649
pop_share <- c(cows = 0.40, bulls = 0.02, heifers = 0.20,
               growing_males = 0.18, calves = 0.20)
N <- round(dairy_total_1996 * pop_share)

# Per-sub-category inputs (means)
sub_pars <- list(
  cows = list(
    W = 539.29, WG = 0,        Milk = 22.05, Fat = 3.8,
    DE = 74.44, CP = 14.15,    pct_lactating = 0.60, pct_pregnant = 0.813,
    Cfi = 0.386, Ca = 0.00,    C_growth = 0.8, Cp = 0.10, hours = 0
  ),
  bulls = list(
    W = 650, WG = 0,           Milk = 0, Fat = 4.0,
    DE = 67.47, CP = 10.70,    pct_lactating = 0, pct_pregnant = 0,
    Cfi = 0.370, Ca = 0.00,    C_growth = 1.2, Cp = 0,    hours = 0
  ),
  heifers = list(
    W = 404.29, WG = 0.5,      Milk = 0, Fat = 4.0,
    DE = 67.47, CP = 10.70,    pct_lactating = 0, pct_pregnant = 0.16,
    Cfi = 0.322, Ca = 0.00,    C_growth = 0.8, Cp = 0.10, hours = 0
  ),
  growing_males = list(
    W = 417.44, WG = 0.512,    Milk = 0, Fat = 4.0,
    DE = 67.47, CP = 10.70,    pct_lactating = 0, pct_pregnant = 0,
    Cfi = 0.370, Ca = 0.00,    C_growth = 1.0, Cp = 0,    hours = 0
  ),
  calves = list(
    W = 198.93, WG = 0.656,    Milk = 0, Fat = 4.0,
    DE = 67.40, CP = 11.30,    pct_lactating = 0, pct_pregnant = 0,
    Cfi = 0.322, Ca = 0.00,    C_growth = 0.9, Cp = 0,    hours = 0
  )
)

# Common parameters (IPCC defaults — Andreas didn't supply these)
common <- list(
  MW = 600,    # mature cow weight, dairy
  Ym = 6.5,    # methane conversion factor (IPCC Africa default)
  Bo = 0.13,   # cattle dairy, IPCC 2019 Africa
  ASH = 0.08, UE = 0.04,
  EF3_PRP = 0.02, EF4 = 0.010, EF5 = 0.0075,
  Frac_GASMS = 0.20, Frac_LEACH_H = 0.02,
  Frac_GASM_PRP = 0.21, Frac_LEACH_PRP = 0.30
)

# Intensive dairy MMS allocation — Andreas didn't share this for sure.
# Assumption (typical intensive dairy): 70 % liquid slurry, 30 % solid storage,
# 0 % pasture (animals confined).
mms_fractions <- c(liquid_slurry = 0.70, solid_storage = 0.30)
mcf_values    <- c(liquid_slurry = 0.80, solid_storage = 0.04)   # tropical
ef3_values    <- c(liquid_slurry = 0.005, solid_storage = 0.005)

# ---------- A. deterministic point estimate ----------
cat("\n========== A. Deterministic (no Monte Carlo) ==========\n")
det_per_subcat <- list()
for (sub in names(sub_pars)) {
  p <- sub_pars[[sub]]
  r <- ghg_emissions(
    cattle_pop = N[[sub]],
    live_weight = p$W, weight_gain = p$WG, mature_weight = common$MW,
    milk_yield = p$Milk, milk_fat = p$Fat, pct_lactating = p$pct_lactating,
    hours = p$hours, DE = p$DE, Cfi = p$Cfi, Ca = p$Ca,
    C_growth = p$C_growth, Cp = p$Cp,
    Ym = common$Ym, Bo = common$Bo, ASH = common$ASH, UE = common$UE,
    CP = p$CP,
    mms_fractions = mms_fractions, mcf_values = mcf_values, ef3_values = ef3_values,
    EF3_PRP = common$EF3_PRP, Frac_GASMS = common$Frac_GASMS,
    EF4 = common$EF4, EF5 = common$EF5, Frac_LEACH_H = common$Frac_LEACH_H,
    Frac_GASM_PRP = common$Frac_GASM_PRP, Frac_LEACH_PRP = common$Frac_LEACH_PRP,
    gwp = "AR5"
  )
  det_per_subcat[[sub]] <- r
  cat(sprintf("  %-15s N=%6d  Nex=%5.1f  direct_MM=%8.3f  indirect_MM=%8.3f t\n",
              sub, N[[sub]], r$Nex,
              r$direct_n2o_mm_total, r$indirect_n2o_mm_total))
}
A_direct  <- sum(sapply(det_per_subcat, `[[`, "direct_n2o_mm_total"))
A_indir   <- sum(sapply(det_per_subcat, `[[`, "indirect_n2o_mm_total"))
cat(sprintf("\n  TOTAL deterministic direct N2O MM   = %8.3f t\n", A_direct))
cat(sprintf("  TOTAL deterministic indirect N2O MM = %8.3f t\n", A_indir))
cat(sprintf("  Andreas's Excel point estimate      = 33.23 t (direct)\n"))
cat(sprintf("  Andreas's Excel point estimate      = 16.89 t (indirect)\n"))

# ---------- helper to build param_specs for run_mc_simulation ----------
build_specs <- function(sub, p, n_pop) {
  pars <- list(
    list("N",   n_pop,        10,  "normal",       "activity_data"),
    list("W",   p$W,          15,  "normal",       "coefficient"),
    list("WG",  max(p$WG, 1e-6), 30, "pert",       "coefficient"),
    list("MW",  common$MW,    10,  "normal",       "coefficient"),
    list("Milk", max(p$Milk, 1e-6), 20, "normal",  "coefficient"),
    list("Fat",  p$Fat,        10, "normal",       "coefficient"),
    list("pct_lactating", max(p$pct_lactating, 1e-6), 20, "beta", "coefficient"),
    list("DE",  p$DE,          15, "normal",       "coefficient"),
    list("Cfi", p$Cfi,         30, "pert",         "coefficient"),
    list("Ca",  max(p$Ca, 1e-6), 30, "triangular", "coefficient"),
    list("C",   p$C_growth,    30, "triangular",   "coefficient"),
    list("Cp",  max(p$Cp, 1e-6), 10, "beta",       "coefficient"),
    list("hours", max(p$hours, 1e-6), 20, "pert",  "coefficient"),
    list("CP",  p$CP,          15, "normal",       "coefficient"),
    list("Ym",  common$Ym,      8, "pert",         "coefficient"),
    list("Bo",  common$Bo,     20, "pert",         "coefficient"),
    list("ASH", common$ASH,    25, "pert",         "coefficient"),
    list("UE",  common$UE,     25, "pert",         "coefficient"),
    list("EF3_PRP", common$EF3_PRP, 40, "pert",    "coefficient"),
    list("Frac_GASMS", common$Frac_GASMS, 40, "pert", "coefficient"),
    list("EF4", common$EF4,    40, "lognormal",    "coefficient"),
    list("EF5", common$EF5,    40, "lognormal",    "coefficient"),
    list("Frac_LEACH_H", common$Frac_LEACH_H, 40, "lognormal", "coefficient"),
    list("Frac_GASM_PRP", common$Frac_GASM_PRP, 50, "pert", "coefficient"),
    list("Frac_LEACH_PRP", common$Frac_LEACH_PRP, 50, "pert", "coefficient")
  )
  df <- data.frame(
    parameter        = sapply(pars, `[[`, 1),
    mean             = as.numeric(sapply(pars, `[[`, 2)),
    uncertainty_pct  = as.numeric(sapply(pars, `[[`, 3)),
    distribution     = sapply(pars, `[[`, 4),
    param_type       = sapply(pars, `[[`, 5),
    lower = NA_real_, upper = NA_real_,
    stringsAsFactors = FALSE
  )
  fill_bounds(df)
}

# ---------- B. MC with Dirichlet OFF ----------
cat("\n========== B. Monte Carlo, Dirichlet OFF ==========\n")
set.seed(42)
n_iter <- 10000
mc_b <- list()
for (sub in names(sub_pars)) {
  specs <- build_specs(sub, sub_pars[[sub]], N[[sub]])
  sim <- run_mc_simulation(
    param_specs   = specs, n_iter = n_iter,
    mms_fractions = mms_fractions, mcf_values = mcf_values, ef3_values = ef3_values,
    gwp = "AR5", seed = 42,
    mms_fractions_matrix = NULL    # ← Dirichlet OFF
  )
  mc_b[[sub]] <- sim$results
}
B_direct_v <- Reduce(`+`, lapply(mc_b, `[[`, "direct_n2o_mm_total"))
B_indir_v  <- Reduce(`+`, lapply(mc_b, `[[`, "indirect_n2o_mm_total"))
cat(sprintf("  Direct N2O MM  : mean=%.3f t, 95%% CI=[%.3f, %.3f]\n",
            mean(B_direct_v), quantile(B_direct_v, .025),
            quantile(B_direct_v, .975)))
cat(sprintf("  Indirect N2O MM: mean=%.3f t, 95%% CI=[%.3f, %.3f]\n",
            mean(B_indir_v), quantile(B_indir_v, .025),
            quantile(B_indir_v, .975)))

# ---------- C. MC with Dirichlet ON (concentration = 50, app default) ----------
cat("\n========== C. Monte Carlo, Dirichlet ON (concentration=50) ==========\n")
set.seed(42)
mc_c <- list()
for (sub in names(sub_pars)) {
  specs <- build_specs(sub, sub_pars[[sub]], N[[sub]])
  mms_mat <- sample_dirichlet_simplex(
    p = as.numeric(mms_fractions), n_iter = n_iter,
    names_vec = names(mms_fractions), concentration = 50)
  sim <- run_mc_simulation(
    param_specs   = specs, n_iter = n_iter,
    mms_fractions = mms_fractions, mcf_values = mcf_values, ef3_values = ef3_values,
    gwp = "AR5", seed = 42,
    mms_fractions_matrix = mms_mat   # ← Dirichlet ON
  )
  mc_c[[sub]] <- sim$results
}
C_direct_v <- Reduce(`+`, lapply(mc_c, `[[`, "direct_n2o_mm_total"))
C_indir_v  <- Reduce(`+`, lapply(mc_c, `[[`, "indirect_n2o_mm_total"))
cat(sprintf("  Direct N2O MM  : mean=%.3f t, 95%% CI=[%.3f, %.3f]\n",
            mean(C_direct_v), quantile(C_direct_v, .025),
            quantile(C_direct_v, .975)))
cat(sprintf("  Indirect N2O MM: mean=%.3f t, 95%% CI=[%.3f, %.3f]\n",
            mean(C_indir_v), quantile(C_indir_v, .025),
            quantile(C_indir_v, .975)))

cat("\n========== Comparison summary ==========\n")
cat(sprintf("                              | direct N2O MM  | indirect N2O MM\n"))
cat(sprintf("Excel/@Risk (Andreas)         | 33.23 t        | 16.89 t\n"))
cat(sprintf("rShiny simulated (Andreas)    | 24.77 t        |  9.69 t\n"))
cat(sprintf("A. Deterministic              | %6.2f t       | %6.2f t\n",  A_direct,  A_indir))
cat(sprintf("B. MC, Dirichlet OFF (mean)   | %6.2f t       | %6.2f t\n",
            mean(B_direct_v), mean(B_indir_v)))
cat(sprintf("C. MC, Dirichlet ON  (mean)   | %6.2f t       | %6.2f t\n",
            mean(C_direct_v), mean(C_indir_v)))
