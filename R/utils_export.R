# Export Functions - IPCC Table 3.3 and Excel Reports

format_ipcc_table <- function(uncertainty_decomposition, country = "", year = "") {
  combined <- uncertainty_decomposition$combined
  ad_only <- uncertainty_decomposition$ad_only
  ef_only <- uncertainty_decomposition$ef_only

  get_cv <- function(df, var) {
    row <- df[df$variable == var, ]
    if (nrow(row) == 0) return(NA)
    round(row$cv_pct, 1)
  }

  data.frame(
    Source_Category = c(
      "3.A.1 Enteric Fermentation - Cattle",
      "3.A.2 Manure Management - Cattle (CH4)",
      "3.A.2 Manure Management - Cattle (N2O direct)",
      "3.A.2 Manure Management - Cattle (N2O indirect)",
      "Total CH4", "Total N2O", "Total CO2eq"
    ),
    Gas = c("CH4", "CH4", "N2O", "N2O", "CH4", "N2O", "CO2eq"),
    AD_Uncertainty_pct = c(
      get_cv(ad_only, "enteric_ch4_total"), get_cv(ad_only, "manure_ch4_total"),
      get_cv(ad_only, "direct_n2o_mm_total"), get_cv(ad_only, "indirect_n2o_mm_total"),
      get_cv(ad_only, "total_ch4"), get_cv(ad_only, "total_n2o"), get_cv(ad_only, "total_co2e")
    ),
    EF_Uncertainty_pct = c(
      get_cv(ef_only, "enteric_ch4_total"), get_cv(ef_only, "manure_ch4_total"),
      get_cv(ef_only, "direct_n2o_mm_total"), get_cv(ef_only, "indirect_n2o_mm_total"),
      get_cv(ef_only, "total_ch4"), get_cv(ef_only, "total_n2o"), get_cv(ef_only, "total_co2e")
    ),
    Combined_Uncertainty_pct = c(
      get_cv(combined, "enteric_ch4_total"), get_cv(combined, "manure_ch4_total"),
      get_cv(combined, "direct_n2o_mm_total"), get_cv(combined, "indirect_n2o_mm_total"),
      get_cv(combined, "total_ch4"), get_cv(combined, "total_n2o"), get_cv(combined, "total_co2e")
    ),
    stringsAsFactors = FALSE
  )
}

export_results_xlsx <- function(results, uncertainty, sensitivity, ipcc_table, filepath) {
  sheets <- list(
    Summary = ipcc_table,
    Uncertainty_Metrics = uncertainty,
    Sensitivity_SRC = if (!is.null(sensitivity$src)) sensitivity$src else data.frame(),
    Sensitivity_PRCC = if (!is.null(sensitivity$prcc)) sensitivity$prcc else data.frame(),
    Metadata = data.frame(
      Field = c("Generated", "Tool", "Iterations"),
      Value = c(as.character(Sys.time()), "IPCC Tier 2 Uncertainty Calculator v1.0", nrow(results))
    )
  )
  writexl::write_xlsx(sheets, path = filepath)
}

# Round 8: trend export — multi-sheet Excel for the Trend tab.
# Sheets: Trend_summary (year x metrics), Slope_and_delta (per-iter MC summary),
# Sensitivity_per_year_*, Sensitivity_delta_*, Methodology.
export_trend_xlsx <- function(results_table, slope, delta_total,
                               sensitivity_per_year, sensitivity_delta,
                               year_corr, n_iter, filepath) {
  slope_delta_summary <- data.frame(
    Metric = c("Trend slope (t CO2eq / yr)",
               "Trend slope 95% CI lower",
               "Trend slope 95% CI upper",
               "Delta total (Y_N - Y_1, t CO2eq)",
               "Delta total 95% CI lower",
               "Delta total 95% CI upper",
               "Delta percent (vs Y_1)",
               "Delta percent 95% CI lower",
               "Delta percent 95% CI upper"),
    Value  = c(slope$mean, slope$ci[1], slope$ci[2],
               delta_total$mean, delta_total$ci[1], delta_total$ci[2],
               delta_total$pct_mean, delta_total$pct_ci[1], delta_total$pct_ci[2]),
    stringsAsFactors = FALSE
  )
  methodology <- data.frame(
    Field = c("Generated", "Tool", "Iterations per year",
              "Year-to-year correlation mode",
              "IPCC reference"),
    Value = c(as.character(Sys.time()),
              "IPCC Tier 2 Uncertainty Calculator — Trend",
              n_iter, year_corr,
              "IPCC 2019 Refinement Vol 1 Ch 3 §3.2.2.4 (year correlation) + §3.7 (trend reporting)"),
    stringsAsFactors = FALSE
  )

  pull_df <- function(sens, key) {
    if (is.null(sens) || is.null(sens[[key]])) return(data.frame())
    sens[[key]]
  }

  sheets <- list(
    Trend_summary    = results_table,
    Slope_and_delta  = slope_delta_summary,
    Sensitivity_per_year_SRC  = pull_df(sensitivity_per_year, "src"),
    Sensitivity_per_year_PRCC = pull_df(sensitivity_per_year, "prcc"),
    Sensitivity_delta_SRC     = pull_df(sensitivity_delta, "src"),
    Sensitivity_delta_PRCC    = pull_df(sensitivity_delta, "prcc"),
    Methodology      = methodology
  )
  writexl::write_xlsx(sheets, path = filepath)
}
