# Sensitivity check for Andreas's pilot — confirm C4 (MCF should rank in MM CH4)
# and C6 (Frac_GASMS / Frac_LEACH_H should rank in MM indirect N2O).
suppressPackageStartupMessages({ library(MASS); library(readxl) })
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)

path <- "uncertainty_template_ipcc2019_ZIM_v2.xlsx"
parsed <- parse_uploaded_template(path)
ps <- fill_bounds(parsed$param_specs)
manure <- parsed$manure

# Heifer name patch (same as diagnose_zimbabwe_v2.R).
if (!is.null(manure) && "sub_category" %in% names(manure))
  manure$sub_category[manure$sub_category == "DINT_heifer"] <- "DINT_heif"

make_group_key <- function(df) {
  sub <- if ("sub_category" %in% names(df)) df$sub_category else rep("", nrow(df))
  paste(df$cattle_type, df$aggregation_level, sub, sep = "||")
}
group_key <- make_group_key(ps)
sys_groups <- unique(group_key)

# Just analyse the cow system (DINT_cow) — that's the dominant contributor.
sg <- "dairy||Intensive||DINT_cow"
sys_specs <- ps[group_key == sg, ]
manure_key <- make_group_key(manure)
mms_rows <- manure[manure_key == sg, ]
fp_num  <- suppressWarnings(as.numeric(mms_rows$fraction_pct))
mcf_num <- suppressWarnings(as.numeric(mms_rows$MCF_pct))
ef3_num <- suppressWarnings(as.numeric(mms_rows$EF3))
mms_fracs <- setNames(fp_num / 100,  mms_rows$mms_type)
mcf_vals  <- setNames(mcf_num / 100, mms_rows$mms_type)
ef3_vals  <- setNames(ef3_num,       mms_rows$mms_type)
keep <- !is.na(mms_fracs)
mms_fracs <- mms_fracs[keep]; mcf_vals <- mcf_vals[keep]; ef3_vals <- ef3_vals[keep]

set.seed(42)
sim <- run_mc_simulation(
  param_specs = sys_specs, n_iter = 10000,
  mms_fractions = mms_fracs, mcf_values = mcf_vals, ef3_values = ef3_vals,
  gwp = "AR5", seed = 42)

cat("\n--- DINT_cow sensitivity rankings (top 10 SRC) ---\n\n")
for (target in c("manure_ch4_total",
                 "direct_n2o_mm_total",
                 "indirect_n2o_mm_total")) {
  if (!target %in% names(sim$results)) next
  s <- sensitivity_analysis(sim$samples, sim$results[[target]], method = "src")
  if (is.null(s$src) || nrow(s$src) == 0) {
    cat("[", target, "] no sensitivity output\n", sep = ""); next
  }
  cat("[", target, "]\n", sep = "")
  print(head(s$src[, c("parameter", "src", "abs_src", "rank")], 10))
  cat("\n")
}
