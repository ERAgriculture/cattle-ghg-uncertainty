# Diagnosis script v2 — loads Andreas's actual populated template
# (uncertainty_template_ipcc2019_ZIM_v2.xlsx) through parse_uploaded_template
# and runs it through run_inventory_simulation. Compares the result to
# Andreas's @Risk/Excel values for the intensive dairy system.

suppressPackageStartupMessages({
  library(MASS); library(readxl)
})

src_files <- c(
  "R/utils_distributions.R", "R/utils_ipcc_defaults.R",
  "R/utils_template.R",       "R/utils_validation.R",
  "R/utils_qaqc.R",
  "R/calc_energy.R", "R/calc_enteric.R", "R/calc_manure_ch4.R",
  "R/calc_manure_n2o.R", "R/calc_ghg_master.R",
  "R/mc_sampling.R", "R/mc_simulation.R", "R/mc_uncertainty.R"
)
for (f in src_files) source(f)

# ---- load Andreas's template ----
path <- "uncertainty_template_ipcc2019_ZIM_v2.xlsx"
cat("Parsing:", path, "\n")
parsed <- parse_uploaded_template(path)
ps <- parsed$param_specs
manure <- parsed$manure   # NOT `parsed$manure_data` — that's the rv state field

# Andreas's template uses `DINT_heifer` in the Manure_Management sheet but
# `DINT_heif` in Parameters. Patch the mismatch so the heifer MMS allocation
# applies to the heifer Parameters group. (Real fix: the app should warn the
# user when a Parameters group has no matching MMS rows; that's a follow-up.)
if (!is.null(manure) && "sub_category" %in% names(manure)) {
  before <- sum(manure$sub_category == "DINT_heifer", na.rm = TRUE)
  manure$sub_category[manure$sub_category == "DINT_heifer"] <- "DINT_heif"
  cat("  patched", before, "DINT_heifer -> DINT_heif rows in manure data\n")
}
cat("  Parameters rows:", nrow(ps), " | Manure_Management rows:",
    if (is.null(manure)) 0 else nrow(manure), "\n")
cat("  cattle_type values:",
    paste(unique(ps$cattle_type), collapse=", "), "\n")
cat("  sub_category values:",
    paste(unique(ps$sub_category), collapse=", "), "\n")

# Fill bounds and validate
ps <- fill_bounds(ps)

# ---- build systems_data the same way app_server.R does ----
make_group_key <- function(df) {
  sub <- if ("sub_category" %in% names(df)) df$sub_category else rep("", nrow(df))
  paste(df$cattle_type, df$aggregation_level, sub, sep = "||")
}
group_key  <- make_group_key(ps)
sys_groups <- unique(group_key)
cat("  systems:", length(sys_groups), "\n")
cat("  group keys:\n   ", paste(sys_groups, collapse="\n    "), "\n\n")

systems_data <- list()
for (sg in sys_groups) {
  sys_specs <- ps[group_key == sg, ]
  # Build MMS from manure sheet
  if (!is.null(manure) && nrow(manure) > 0 &&
      all(c("mms_type", "fraction_pct", "MCF_pct", "EF3") %in% names(manure))) {
    manure_key <- make_group_key(manure)
    mms_rows   <- manure[manure_key == sg, ]
    fp_num   <- suppressWarnings(as.numeric(mms_rows$fraction_pct))
    mcf_num  <- suppressWarnings(as.numeric(mms_rows$MCF_pct))
    ef3_num  <- suppressWarnings(as.numeric(mms_rows$EF3))
    mms_fracs <- setNames(fp_num / 100,  mms_rows$mms_type)
    mcf_vals  <- setNames(mcf_num / 100, mms_rows$mms_type)
    ef3_vals  <- setNames(ef3_num,       mms_rows$mms_type)
    keep <- !is.na(mms_fracs)
    mms_fracs <- mms_fracs[keep]; mcf_vals <- mcf_vals[keep]; ef3_vals <- ef3_vals[keep]
    frac_gas_vals <- if ("Frac_GasMS_pct" %in% names(mms_rows))
      setNames(suppressWarnings(as.numeric(mms_rows$Frac_GasMS_pct)) / 100,
               mms_rows$mms_type)[keep] else NULL
    frac_leach_vals <- if ("Frac_LeachMS_pct" %in% names(mms_rows))
      setNames(suppressWarnings(as.numeric(mms_rows$Frac_LeachMS_pct)) / 100,
               mms_rows$mms_type)[keep] else NULL
  } else {
    mms_fracs <- c(pasture = 1.0)
    mcf_vals  <- c(pasture = 0.015)
    ef3_vals  <- c(pasture = 0.02)
    frac_gas_vals <- frac_leach_vals <- NULL
  }
  systems_data[[sg]] <- list(
    param_specs = sys_specs, corr_matrix = NULL, ef_corr_matrix = NULL,
    mms_fractions = mms_fracs, mcf_values = mcf_vals, ef3_values = ef3_vals,
    frac_gas_values = frac_gas_vals, frac_leach_values = frac_leach_vals
  )
  cat(sprintf("  [%s] N parameters=%d, MMS=%s, MMS%%=%s\n",
              sg, nrow(sys_specs), paste(names(mms_fracs), collapse="/"),
              paste(round(mms_fracs*100,1), collapse="/")))
}

# ---- run simulation ----
n_iter <- 10000
cat("\nRunning Monte Carlo (", n_iter, " iterations)...\n", sep="")
set.seed(42)
sim <- run_inventory_simulation(systems_data, n_iter = n_iter,
                                  gwp = "AR5", seed = 42)
unc <- calc_all_uncertainty(sim$inventory)

cat("\n========== Inventory-level results ==========\n")
keep_vars <- c("total_enteric_ch4", "total_manure_ch4",
               "total_direct_n2o_mm", "total_indirect_n2o_mm",
               "total_direct_n2o_prp", "total_indirect_n2o_prp",
               "total_ch4", "total_n2o", "total_co2e")
for (v in keep_vars) {
  row <- unc[unc$variable == v, ]
  if (nrow(row) == 0) next
  cat(sprintf("  %-26s mean=%9.3f  95%% CI=[%9.3f, %9.3f]\n",
              v, row$mean, row$ci_lower, row$ci_upper))
}

cat("\n========== Compare to Andreas's Excel/@Risk values ==========\n")
cat(sprintf("Source                | Excel mean | Tool mean | %% diff\n"))
mm_dir  <- unc[unc$variable == "total_direct_n2o_mm",   ]$mean
mm_ind  <- unc[unc$variable == "total_indirect_n2o_mm", ]$mean
ent_ch4 <- unc[unc$variable == "total_enteric_ch4",     ]$mean
mm_ch4  <- unc[unc$variable == "total_manure_ch4",      ]$mean
cat(sprintf("Direct N2O MM         |   33.23 t  | %7.3f t | %+5.1f%%\n",
            mm_dir,  (mm_dir  - 33.23)/33.23*100))
cat(sprintf("Indirect N2O MM       |   16.89 t  | %7.3f t | %+5.1f%%\n",
            mm_ind,  (mm_ind  - 16.89)/16.89*100))
cat(sprintf("Enteric CH4           | 2660.88 t  | %7.3f t | %+5.1f%%\n",
            ent_ch4, (ent_ch4 - 2660.88)/2660.88*100))
cat(sprintf("Manure CH4            |  573.20 t  | %7.3f t | %+5.1f%%\n",
            mm_ch4,  (mm_ch4  - 573.20)/573.20*100))
