# Re-run sensitivity on Andreas's pilot AFTER the per-MMS MC sampling fix.
# Now MCF / EF3 / Frac_GasMS / Frac_LeachMS uncertainty should propagate
# and surface in the MM CH4 and MM N2O tornadoes (closing C4 / C6).
suppressPackageStartupMessages({ library(MASS); library(readxl) })
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)

path <- "uncertainty_template_ipcc2019_ZIM_v2.xlsx"
parsed <- parse_uploaded_template(path)
ps     <- fill_bounds(parsed$param_specs)
manure <- parsed$manure
if (!is.null(manure) && "sub_category" %in% names(manure))
  manure$sub_category[manure$sub_category == "DINT_heifer"] <- "DINT_heif"

make_group_key <- function(df) {
  sub <- if ("sub_category" %in% names(df)) df$sub_category else rep("", nrow(df))
  paste(df$cattle_type, df$aggregation_level, sub, sep = "||")
}
group_key  <- make_group_key(ps)
manure_key <- make_group_key(manure)

sg <- "dairy||Intensive||DINT_cow"
sys_specs <- ps[group_key == sg, ]
mms_rows  <- manure[manure_key == sg, ]
fp_num  <- suppressWarnings(as.numeric(mms_rows$fraction_pct))
mcf_num <- suppressWarnings(as.numeric(mms_rows$MCF_pct))
ef3_num <- suppressWarnings(as.numeric(mms_rows$EF3))
mms_fracs <- setNames(fp_num / 100,  mms_rows$mms_type)
mcf_vals  <- setNames(mcf_num / 100, mms_rows$mms_type)
ef3_vals  <- setNames(ef3_num,       mms_rows$mms_type)
keep <- !is.na(mms_fracs)
mms_fracs <- mms_fracs[keep]; mcf_vals <- mcf_vals[keep]; ef3_vals <- ef3_vals[keep]

n_iter <- 10000

# Build the per-MMS uncertainty matrices (mirrors app_server.R logic).
mr_mcf_scaled <- mms_rows
for (col in c("MCF_pct", "lower_mcf", "upper_mcf"))
  if (col %in% names(mr_mcf_scaled))
    mr_mcf_scaled[[col]] <- suppressWarnings(as.numeric(mr_mcf_scaled[[col]])) / 100
mcf_samples <- sample_per_mms_param(mr_mcf_scaled, "MCF_pct",
                                     "lower_mcf", "upper_mcf",
                                     "distribution_mcf", n_iter, "pert")
ef3_samples <- sample_per_mms_param(mms_rows, "EF3",
                                     "lower_ef3", "upper_ef3",
                                     "distribution_ef3", n_iter, "pert")
ord <- names(mms_fracs)
if (!is.null(mcf_samples)) mcf_samples <- mcf_samples[, ord, drop = FALSE]
if (!is.null(ef3_samples)) ef3_samples <- ef3_samples[, ord, drop = FALSE]

set.seed(42)
sim <- run_mc_simulation(
  param_specs = sys_specs, n_iter = n_iter,
  mms_fractions = mms_fracs, mcf_values = mcf_vals, ef3_values = ef3_vals,
  gwp = "AR5", seed = 42,
  mcf_samples = mcf_samples, ef3_samples = ef3_samples)

cat("\nSamples columns count:", ncol(sim$samples), "\n")
cat("MMS-related sample columns now in `samples`:\n")
print(grep("^(MCF|EF3|Frac_GasMS|Frac_LeachMS)_", names(sim$samples), value = TRUE))

for (target in c("manure_ch4_total",
                 "direct_n2o_mm_total",
                 "indirect_n2o_mm_total")) {
  if (!target %in% names(sim$results)) next
  s <- sensitivity_analysis(sim$samples, sim$results[[target]], method = "src")
  cat("\n[", target, "]  mean =", round(mean(sim$results[[target]]), 3),
      "  top 10 SRC:\n", sep = "")
  print(head(s$src[, c("parameter", "src", "abs_src", "rank")], 10))
}
