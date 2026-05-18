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

  # Andreas 2026-05 #36, C10: pasture direct + indirect must appear as
  # separate IPCC reporting lines, not collapsed into "total N2O".
  vars <- c("enteric_ch4_total", "manure_ch4_total",
            "direct_n2o_mm_total", "indirect_n2o_mm_total",
            "direct_n2o_prp_total", "indirect_n2o_prp_total",
            "total_ch4", "total_n2o", "total_co2e")

  data.frame(
    `Emission category` = c(
      "3.A.1 Enteric Fermentation — Cattle",
      "3.A.2 Manure Management — Cattle (CH₄)",
      "3.A.2 Manure Management — Cattle (N₂O direct)",
      "3.A.2 Manure Management — Cattle (N₂O indirect)",
      "3.C.4 Direct N₂O — Pasture/Range/Paddock",
      "3.C.5 Indirect N₂O — Pasture/Range/Paddock",
      "Total CH₄", "Total N₂O", "Total CO₂eq"
    ),
    Gas = c("CH₄", "CH₄", "N₂O", "N₂O", "N₂O", "N₂O", "CH₄", "N₂O", "CO₂eq"),
    `AD uncertainty (%)`       = sapply(vars, function(v) get_cv(ad_only, v)),
    `EF uncertainty (%)`       = sapply(vars, function(v) get_cv(ef_only, v)),
    `Combined uncertainty (%)` = sapply(vars, function(v) get_cv(combined, v)),
    check.names = FALSE,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}

export_results_xlsx <- function(results, uncertainty, sensitivity, ipcc_table, filepath,
                                settings = NULL) {
  # Andreas 2026-05 #38: previously crashed when ipcc_table was NULL (which
  # happens whenever AD/EF decomposition didn't run, e.g. for custom uploads
  # — see app_server.R line 982). Replace NULL/empty inputs with placeholder
  # data frames so the writer always succeeds.
  placeholder <- function(msg)
    data.frame(Note = msg, stringsAsFactors = FALSE)

  summary_df <- if (is.null(ipcc_table) || !is.data.frame(ipcc_table) || nrow(ipcc_table) == 0)
    placeholder("IPCC summary unavailable. Enable 'Run uncertainty decomposition (AD/EF/Combined)' on Tab 5 and re-run to populate this sheet.")
  else ipcc_table

  uncertainty_df <- if (is.null(uncertainty) || !is.data.frame(uncertainty) || nrow(uncertainty) == 0)
    placeholder("No uncertainty metrics available. Run a Monte Carlo simulation on Tab 5 first.")
  else uncertainty

  src_df <- if (!is.null(sensitivity) && is.data.frame(sensitivity$src) && nrow(sensitivity$src) > 0)
    sensitivity$src
  else placeholder(if (!is.null(attr(sensitivity, "message"))) attr(sensitivity, "message")
                    else "Sensitivity (SRC) unavailable for this run.")

  prcc_df <- if (!is.null(sensitivity) && is.data.frame(sensitivity$prcc) && nrow(sensitivity$prcc) > 0)
    sensitivity$prcc
  else placeholder(if (!is.null(attr(sensitivity, "message"))) attr(sensitivity, "message")
                    else "Sensitivity (PRCC) unavailable for this run.")

  n_iter <- if (is.data.frame(results)) nrow(results) else NA_integer_

  run_settings_df <- if (!is.null(settings)) {
    data.frame(
      Setting = c("Iterations", "AD correlations", "EF correlations",
                  "Comparison run (no corr.)", "GWP basis", "Seed",
                  "Analysis mode", "Emission sources"),
      Value   = c(
        as.character(settings$n_iter %||% NA),
        as.character(settings$corr_mode %||% "none"),
        as.character(settings$ef_corr_mode %||% "none"),
        if (isTRUE(settings$run_comparison)) "yes" else "no",
        as.character(settings$gwp_version %||% NA),
        as.character(settings$seed %||% NA),
        as.character(settings$analysis_mode %||% NA),
        paste(settings$emission_sources %||% character(0), collapse = ", ")
      ),
      stringsAsFactors = FALSE
    )
  } else {
    data.frame(Note = "Settings not recorded (re-download after running a simulation).",
               stringsAsFactors = FALSE)
  }

  sheets <- list(
    Run_Settings        = run_settings_df,
    Summary             = summary_df,
    Uncertainty_Metrics = uncertainty_df,
    Sensitivity_SRC     = src_df,
    Sensitivity_PRCC    = prcc_df,
    Metadata = data.frame(
      Field = c("Generated", "Tool", "Iterations"),
      Value = c(as.character(Sys.time()),
                "IPCC Tier 2 Uncertainty Calculator v1.1",
                as.character(n_iter)),
      stringsAsFactors = FALSE
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
