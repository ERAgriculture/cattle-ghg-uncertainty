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
