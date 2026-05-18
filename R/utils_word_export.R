# Word run-summary exports.
#
# Two public entry points:
#   build_run_summary_docx()    - single-year MC run (Round 6b, redesigned R8)
#   build_trend_summary_docx()  - multi-year trend run (Round 8)
#
# Both share a design vocabulary mirroring the AW response document:
#   H1 / H2 dark green (#1B4332), H3 mid green (#2D6A4F), tables with green
#   header + alternating rows + width-constrained layout. Wide tables are
#   wrapped in landscape sections so they don't overflow the page.
#
# Plotly renderers in the live app are untouched; ggplot2 versions of every
# chart are rebuilt here so the doc renders deterministically on shinyapps.io
# without a Chromium binary (which webshot2 would require).

# ============================================================================
# DESIGN VOCABULARY (shared)
# ============================================================================

.GREEN_DARK <- "#1B4332"
.GREEN_MID  <- "#2D6A4F"
.GREEN_BG   <- "#D8F3DC"
.ROW_ALT    <- "#F2F2F2"
.BORDER     <- "#B0B0B0"

# Apply the AW-doc visual style to a flextable: green header + alternating
# rows + 0.5pt grey borders + width=1 (fill 100% of available text width so
# the table never overflows the page).
.styled_flextable <- function(ft) {
  if (is.null(ft)) return(NULL)
  ncols <- length(ft$col_keys)
  ft <- flextable::theme_box(ft)
  ft <- flextable::bg(ft, bg = .GREEN_MID, part = "header")
  ft <- flextable::color(ft, color = "white", part = "header")
  ft <- flextable::bold(ft, bold = TRUE, part = "header")
  ft <- flextable::fontsize(ft, size = 9, part = "header")
  ft <- flextable::fontsize(ft, size = 8, part = "body")
  ft <- flextable::padding(ft, padding = 3, part = "all")
  ft <- flextable::border_inner(ft, officer::fp_border(color = .BORDER, width = 0.5))
  ft <- flextable::border_outer(ft, officer::fp_border(color = .BORDER, width = 0.5))
  # Alternating row backgrounds (skip if there are no body rows)
  body_rows <- nrow(ft$body$dataset)
  if (body_rows > 0L) {
    even_rows <- seq(2, body_rows, by = 2)
    if (length(even_rows) > 0L)
      ft <- flextable::bg(ft, i = even_rows, bg = .ROW_ALT, part = "body")
  }
  # Constrain width to page width so columns shrink to fit instead of overflow
  ft <- flextable::set_table_properties(ft, layout = "autofit", width = 1)
  ft
}

# Headings — use officer's default 'heading N' styles (which Word renders with
# the document's heading style) but coerced to our green colour via fp_par.
.add_h1 <- function(doc, text) {
  officer::body_add_fpar(doc, officer::fpar(
    officer::ftext(text, prop = officer::fp_text(
      bold = TRUE, font.size = 18, color = .GREEN_DARK,
      font.family = "Calibri")),
    fp_p = officer::fp_par(padding.top = 12, padding.bottom = 4)
  ))
}

.add_h2 <- function(doc, text) {
  officer::body_add_fpar(doc, officer::fpar(
    officer::ftext(text, prop = officer::fp_text(
      bold = TRUE, font.size = 13, color = .GREEN_DARK,
      font.family = "Calibri")),
    fp_p = officer::fp_par(padding.top = 10, padding.bottom = 4)
  ))
}

.add_h3 <- function(doc, text) {
  officer::body_add_fpar(doc, officer::fpar(
    officer::ftext(text, prop = officer::fp_text(
      bold = TRUE, font.size = 11, color = .GREEN_MID,
      font.family = "Calibri")),
    fp_p = officer::fp_par(padding.top = 8, padding.bottom = 2)
  ))
}

.add_p <- function(doc, text) {
  officer::body_add_par(doc, text, style = "Normal")
}

# Wrap the *preceding* content in a landscape section. Officer applies the
# section break AFTER the block_section call, so call this immediately after
# the wide table you want in landscape.
.add_landscape_break <- function(doc) {
  ps <- officer::prop_section(
    page_size = officer::page_size(orient = "landscape", width = 11.69, height = 8.27),
    page_margins = officer::page_mar(top = 0.6, bottom = 0.6, left = 0.7, right = 0.7,
                                       header = 0.3, footer = 0.3, gutter = 0)
  )
  officer::body_end_block_section(doc,
    value = officer::block_section(property = ps))
}

.add_portrait_break <- function(doc) {
  ps <- officer::prop_section(
    page_size = officer::page_size(orient = "portrait", width = 8.27, height = 11.69),
    page_margins = officer::page_mar(top = 0.8, bottom = 0.8, left = 0.9, right = 0.9,
                                       header = 0.3, footer = 0.3, gutter = 0)
  )
  officer::body_end_block_section(doc,
    value = officer::block_section(property = ps))
}

.add_flextable_safe <- function(doc, ft) {
  if (is.null(ft)) return(doc)
  flextable::body_add_flextable(doc, ft, align = "left")
}

.fmt_int <- function(x) {
  if (is.null(x) || length(x) == 0 || is.na(x)) return("(unset)")
  format(as.integer(x), big.mark = ",")
}

.fmt_num <- function(x, digits = 1) {
  if (is.null(x) || length(x) == 0 || is.na(x)) return("—")
  formatC(x, digits = digits, format = "f", big.mark = ",")
}

.fmt_signed <- function(x, digits = 1) {
  if (is.null(x) || length(x) == 0 || is.na(x)) return("—")
  s <- formatC(x, digits = digits, format = "f")
  if (x > 0) paste0("+", s) else s
}

.as_str <- function(x, default = "") {
  if (is.null(x) || length(x) == 0) return(default)
  if (is.na(x))                      return(default)
  if (!nzchar(as.character(x)))      return(default)
  as.character(x)
}

.pretty_var <- function(v) {
  # Andreas 2026-05 #37, #39: every IPCC emission source must appear as its
  # own row in the Word Section 4 table — including pasture direct and
  # indirect, which were missing.
  map <- c(
    total_co2e             = "Total CO2eq",
    total_ch4              = "Total CH4",
    total_n2o              = "Total N2O",
    enteric_ch4_total      = "Enteric fermentation CH4",
    manure_ch4_total       = "Manure management CH4",
    direct_n2o_mm_total    = "Manure management N2O direct",
    indirect_n2o_mm_total  = "Manure management N2O indirect",
    direct_n2o_prp_total   = "Pasture deposition N2O direct",
    indirect_n2o_prp_total = "Pasture deposition N2O indirect",
    total_enteric_ch4      = "Enteric fermentation CH4 (inventory)",
    total_manure_ch4       = "Manure management CH4 (inventory)",
    total_direct_n2o_mm    = "Manure management N2O direct (inventory)",
    total_indirect_n2o_mm  = "Manure management N2O indirect (inventory)",
    total_direct_n2o_prp   = "Pasture deposition N2O direct (inventory)",
    total_indirect_n2o_prp = "Pasture deposition N2O indirect (inventory)"
  )
  out <- map[v]
  out[is.na(out)] <- v[is.na(out)]
  unname(out)
}

# Andreas 2026-05 #37, #39, C11: unit lookup for the Word Section 4 table
# (and reusable elsewhere).
.unit_for_var <- function(v) {
  ch4_vars <- c("total_ch4","enteric_ch4_total","manure_ch4_total",
                "total_enteric_ch4","total_manure_ch4")
  n2o_vars <- c("total_n2o","direct_n2o_mm_total","indirect_n2o_mm_total",
                "direct_n2o_prp_total","indirect_n2o_prp_total",
                "total_direct_n2o_mm","total_indirect_n2o_mm",
                "total_direct_n2o_prp","total_indirect_n2o_prp",
                "total_direct_n2o","total_indirect_n2o")
  ifelse(v %in% ch4_vars, "t CH4",
         ifelse(v %in% n2o_vars, "t N2O",
                ifelse(v == "total_co2e", "t CO2eq", "")))
}

# ============================================================================
# SINGLE-YEAR REPORT — build_run_summary_docx() (redesigned)
# ============================================================================

build_run_summary_docx <- function(path,
                                   settings,
                                   param_specs,
                                   mc_results,
                                   uncertainty,
                                   sensitivity = NULL,
                                   ipcc_table  = NULL,
                                   ipcc_meta   = NULL,
                                   app_version = NULL) {

  doc <- officer::read_docx()

  # ---- Title block --------------------------------------------------------
  doc <- .add_h1(doc, "Cattle GHG Tier 2 Uncertainty — Single-year run")
  meta_line <- paste(
    sprintf("Generated %s.", format(Sys.time(), "%Y-%m-%d %H:%M %Z")),
    if (!is.null(ipcc_meta) && !is.null(ipcc_meta$ipcc_version))
      sprintf("IPCC guidelines: %s.", ipcc_meta$ipcc_version) else NULL,
    if (!is.null(ipcc_meta) && !is.null(ipcc_meta$region) && nzchar(ipcc_meta$region))
      sprintf("Region: %s.", ipcc_meta$region) else NULL,
    "Approach 2 Monte Carlo simulation per IPCC Vol 1 Ch 3."
  )
  doc <- .add_p(doc, paste(stats::na.omit(meta_line), collapse = " "))

  # ---- Executive summary --------------------------------------------------
  doc <- .add_h2(doc, "Executive summary")
  doc <- .add_p(doc, .build_single_exec_summary(uncertainty, sensitivity, settings))

  # ---- Run settings -------------------------------------------------------
  doc <- .add_h2(doc, "1. What was run")
  doc <- .add_flextable_safe(doc, .styled_flextable(.settings_flextable(settings)))

  # ---- Auto-filled parameters --------------------------------------------
  imputed_ft <- .imputed_flextable(param_specs)
  if (!is.null(imputed_ft)) {
    doc <- .add_h2(doc, "2. Auto-filled parameters")
    doc <- .add_p(doc,
      "These parameters were not in the upload and were filled with IPCC defaults so the simulation could run. Override with country-specific data when available.")
    doc <- .add_flextable_safe(doc, .styled_flextable(imputed_ft))
  }

  # ---- IPCC Table 3.3 results (LANDSCAPE) --------------------------------
  if (!is.null(ipcc_table) && is.data.frame(ipcc_table) && nrow(ipcc_table) > 0) {
    doc <- .add_h2(doc, "3. IPCC Table 3.3 — uncertainty decomposition")
    doc <- .add_p(doc,
      "Combined % uncertainty (CV%) per emission source decomposed into the activity-data and emission-factor contributions, formatted for Annex 7 of a national inventory submission.")
    doc <- .add_flextable_safe(doc, .styled_flextable(.ipcc_flextable(ipcc_table)))
    doc <- .add_landscape_break(doc)
  }

  # ---- Headline by-source results ----------------------------------------
  doc <- .add_h2(doc, "4. Headline results — by source")
  doc <- .add_p(doc,
    "Mean total emissions per source with the 95% confidence interval, coefficient of variation (CV%) and 95% margin of error (MoE%) from the Monte Carlo run.")
  doc <- .add_flextable_safe(doc, .styled_flextable(.results_flextable(uncertainty)))
  doc <- .add_portrait_break(doc)

  # ---- Sensitivity ranking ------------------------------------------------
  sens_ft <- .sensitivity_flextable(sensitivity)
  if (!is.null(sens_ft)) {
    doc <- .add_h2(doc, "5. Sensitivity ranking — top 10 drivers")
    doc <- .add_p(doc,
      "Standardised regression coefficient (SRC) and partial rank correlation (PRCC) of each input parameter against total CO2eq. Larger absolute values dominate the output uncertainty.")
    doc <- .add_flextable_safe(doc, .styled_flextable(sens_ft))
  }

  # ---- Charts -------------------------------------------------------------
  doc <- .add_h2(doc, "6. Charts")

  hist_plot <- .gg_total_co2e_hist(mc_results)
  if (!is.null(hist_plot)) {
    doc <- .add_h3(doc, "Total CO2eq — Monte Carlo distribution")
    doc <- officer::body_add_gg(doc, value = hist_plot, width = 5.5, height = 3.0)
  }

  tornado_plot <- .gg_tornado(sensitivity)
  if (!is.null(tornado_plot)) {
    doc <- .add_h3(doc, "Sensitivity tornado")
    doc <- officer::body_add_gg(doc, value = tornado_plot, width = 5.5, height = 3.5)
  }

  src_plot <- .gg_source_grid(mc_results)
  if (!is.null(src_plot)) {
    doc <- .add_h3(doc, "Per-source emission distributions")
    doc <- officer::body_add_gg(doc, value = src_plot, width = 5.5, height = 4.0)
  }

  # ---- IPCC reporting context --------------------------------------------
  doc <- .add_h2(doc, "7. IPCC reporting context")
  doc <- .add_p(doc,
    "This run follows IPCC 2006 Vol 1 Ch 3 Approach 2 (Monte Carlo) for combined uncertainty estimation. The headline CV% in section 4 is the value to enter in column J of the national inventory uncertainty table (Annex 7 / IPCC Table 3.3). The activity-data vs emission-factor split in section 3 follows the convention adopted in this tool — AD = animal population (N) only; coefficient (EF) = the 23 IPCC equation parameters that combine into the per-head emission factor.")
  doc <- .add_p(doc,
    "Where parameters were auto-filled (section 2), the IPCC default carries the uncertainty bounds suggested by Penman et al. (2000) and Monni et al. (2007). For parameters with country-specific values, the uncertainty bounds entered on the Uncertainty tab of the app drive the Monte Carlo distribution.")

  # ---- Footer -------------------------------------------------------------
  doc <- .add_p(doc, "")
  footer_bits <- c(
    "Generated by Cattle GHG Uncertainty Calculator",
    if (!is.null(app_version)) sprintf("v%s", app_version) else NULL,
    sprintf("on %s.", format(Sys.Date(), "%Y-%m-%d")),
    "CGIAR Alliance / Bioversity-CIAT — funded by the Global Methane Hub."
  )
  doc <- .add_p(doc, paste(footer_bits, collapse = " "))

  print(doc, target = path)
  invisible(path)
}

.build_single_exec_summary <- function(uncertainty, sensitivity, settings) {
  total_row <- if (!is.null(uncertainty) && "variable" %in% names(uncertainty))
    uncertainty[uncertainty$variable == "total_co2e", , drop = FALSE]
  else NULL
  if (is.null(total_row) || nrow(total_row) == 0) {
    return("Total CO2eq could not be summarised — no result row found.")
  }
  m   <- total_row$mean
  lo  <- total_row$ci_lower
  hi  <- total_row$ci_upper
  cv  <- total_row$cv_pct
  moe <- total_row$moe_pct

  # Top driver from sensitivity (SRC if available)
  driver_text <- ""
  base <- if (!is.null(sensitivity$src) && nrow(sensitivity$src) > 0) sensitivity$src
          else if (!is.null(sensitivity$prcc) && nrow(sensitivity$prcc) > 0) sensitivity$prcc
          else NULL
  if (!is.null(base) && nrow(base) > 0) {
    val_col <- if ("src" %in% names(base)) "src" else "prcc"
    top <- base[order(-abs(base[[val_col]])), , drop = FALSE][1, ]
    driver_text <- sprintf(
      " The single dominant uncertainty driver is %s (%s = %s).",
      top$parameter, toupper(val_col),
      formatC(top[[val_col]], digits = 2, format = "f"))
  }

  n_iter_str <- .fmt_int(settings$n_iter)
  sprintf(
    "Total emissions: %s t CO2eq with a 95%% confidence interval of [%s, %s]. Coefficient of variation: %s%%; 95%% margin of error: %s%%.%s These figures are based on %s Monte Carlo iterations under the IPCC Approach 2 method.",
    .fmt_num(m, 0), .fmt_num(lo, 0), .fmt_num(hi, 0),
    .fmt_num(cv, 1), .fmt_num(moe, 1),
    driver_text, n_iter_str
  )
}

# ============================================================================
# TREND REPORT — build_trend_summary_docx() (new, Round 8)
# ============================================================================

build_trend_summary_docx <- function(path,
                                      trend_results,
                                      slope,
                                      delta_total,
                                      sensitivity_per_year = NULL,
                                      sensitivity_delta    = NULL,
                                      year_corr   = "full",
                                      years       = NULL,
                                      n_iter      = 2000,
                                      ipcc_meta   = NULL,
                                      param_specs = NULL,
                                      app_version = NULL) {

  doc <- officer::read_docx()
  yrs <- if (!is.null(years)) range(years) else range(trend_results$Year)

  # ---- Title block --------------------------------------------------------
  doc <- .add_h1(doc, sprintf("Cattle GHG Tier 2 Uncertainty — Trend %d–%d",
                                yrs[1], yrs[2]))
  meta_line <- paste(
    sprintf("Generated %s.", format(Sys.time(), "%Y-%m-%d %H:%M %Z")),
    sprintf("Year-to-year correlation mode: %s.", year_corr),
    if (!is.null(ipcc_meta) && !is.null(ipcc_meta$ipcc_version))
      sprintf("IPCC guidelines: %s.", ipcc_meta$ipcc_version) else NULL,
    if (!is.null(ipcc_meta) && !is.null(ipcc_meta$region) && nzchar(ipcc_meta$region))
      sprintf("Region: %s.", ipcc_meta$region) else NULL,
    "Approach 2 Monte Carlo per IPCC Vol 1 Ch 3 §3.2.2.4 + §3.7."
  )
  doc <- .add_p(doc, paste(stats::na.omit(meta_line), collapse = " "))

  # ---- Executive summary --------------------------------------------------
  doc <- .add_h2(doc, "Executive summary")
  doc <- .add_p(doc, .build_trend_exec_summary(trend_results, slope, delta_total,
                                                 sensitivity_delta, year_corr, n_iter))

  # ---- Run settings -------------------------------------------------------
  doc <- .add_h2(doc, "1. What was run")
  doc <- .add_flextable_safe(doc,
    .styled_flextable(.trend_settings_flextable(year_corr, n_iter, yrs, ipcc_meta)))

  # ---- Trend table (LANDSCAPE) -------------------------------------------
  doc <- .add_h2(doc, "2. Year-by-year trend")
  doc <- .add_p(doc,
    "Per-year mean total emissions, 95% confidence interval, CV%, margin of error, and the percent change relative to the base year and to the previous year.")
  doc <- .add_flextable_safe(doc, .styled_flextable(.trend_table_flextable(trend_results)))
  doc <- .add_landscape_break(doc)

  # ---- Trend chart --------------------------------------------------------
  doc <- .add_h2(doc, "3. Trend chart")
  trend_plot <- .gg_trend_chart(trend_results)
  if (!is.null(trend_plot)) {
    doc <- officer::body_add_gg(doc, value = trend_plot, width = 5.5, height = 3.2)
  }

  # ---- Slope + delta mini-table ------------------------------------------
  doc <- .add_h2(doc, "4. Trend slope and Δ Y_N − Y_1")
  doc <- .add_p(doc,
    "The slope is fitted via least-squares per Monte Carlo iteration; the 95% CI is the [2.5%, 97.5%] of that distribution. ΔY_N−Y_1 is the per-iteration difference between the last and first year, with its own 95% CI and percent of the base year.")
  doc <- .add_flextable_safe(doc,
    .styled_flextable(.slope_delta_flextable(slope, delta_total)))

  # ---- Sensitivity drivers -----------------------------------------------
  doc <- .add_h2(doc, "5. Sensitivity drivers")
  doc <- .add_p(doc,
    "Two views: per-year drivers identify what dominates the uncertainty in the most recent year, while trend drivers (Δ across years) identify what drives the change between Y_1 and Y_N. The latter is the methodologically correct answer to 'what makes the trend uncertain' per IPCC Vol 1 Ch 3 §3.7.")

  py_ft <- .sensitivity_flextable(sensitivity_per_year)
  if (!is.null(py_ft)) {
    doc <- .add_h3(doc, "Per-year (latest year)")
    doc <- .add_flextable_safe(doc, .styled_flextable(py_ft))
    py_plot <- .gg_tornado(sensitivity_per_year)
    if (!is.null(py_plot))
      doc <- officer::body_add_gg(doc, value = py_plot, width = 5.5, height = 3.0)
  }

  dl_ft <- .sensitivity_flextable(sensitivity_delta)
  if (!is.null(dl_ft)) {
    doc <- .add_h3(doc, "Trend driver (Δ Y_N − Y_1)")
    doc <- .add_flextable_safe(doc, .styled_flextable(dl_ft))
    dl_plot <- .gg_tornado(sensitivity_delta)
    if (!is.null(dl_plot))
      doc <- officer::body_add_gg(doc, value = dl_plot, width = 5.5, height = 3.0)
  }

  # ---- Methodological notes ----------------------------------------------
  doc <- .add_h2(doc, "6. Methodological notes")
  yc_text <- switch(
    year_corr,
    full    = "Coefficient draws (the 23 IPCC equation parameters) are sampled once and reused across every year, while activity data (animal population N) is re-drawn fresh for each year. This is the IPCC 2019 Refinement Vol 1 Ch 3 §3.2.2.4 default for emission-factor uncertainty: same EF every year, AD re-estimated annually. The trend uncertainty in this configuration reflects only the AD changes between years.",
    partial = "Coefficient draws are correlated across years via an AR(1) Gaussian copula with ρ = 0.7. This represents partial year-to-year correlation per IPCC §3.2.2.4 — a moderate assumption for cases where coefficients drift over time but neighbouring years share most of the same observational basis.",
    none    = "Coefficient draws and activity-data draws are both independent for each year. This is the most conservative assumption and tends to inflate trend uncertainty; per IPCC §3.2.2.4 it is appropriate only when each year's emission factors come from genuinely independent measurement campaigns."
  )
  doc <- .add_p(doc, yc_text)
  doc <- .add_p(doc,
    "All uncertainty quantification follows IPCC 2006 Vol 1 Ch 3 Approach 2 (Monte Carlo). The trend slope is computed via per-iteration least-squares fit; the slope's 95% CI is therefore the empirical 2.5%/97.5% quantiles of the slope distribution, not a parametric CI. ΔY_N−Y_1 reports the difference between the per-iteration totals at the last and first years, preserving the year-to-year correlation structure imposed above.")

  # ---- IPCC reporting context --------------------------------------------
  doc <- .add_h2(doc, "7. IPCC reporting context")
  doc <- .add_p(doc,
    "Per IPCC Vol 1 Ch 3 §3.7, trend uncertainty should be reported alongside the level of emissions in any national inventory submission that covers more than a single year. The Δ vs base year column in section 2 maps to the trend uncertainty cells of the IPCC Table 3.3 trend annex; the slope in section 4 supports the §3.7.2 'trend assessment' text typical of biennial transparency reports under the Paris Agreement Enhanced Transparency Framework.")
  doc <- .add_p(doc,
    "If the trend is reported with a year-correlation assumption other than 'fully correlated coefficients', that choice should be documented in the methods section of the national inventory report — the year-correlation setting recorded in section 1 of this document is the one to cite.")

  # ---- Footer -------------------------------------------------------------
  doc <- .add_p(doc, "")
  footer_bits <- c(
    "Generated by Cattle GHG Uncertainty Calculator — Trend report.",
    if (!is.null(app_version)) sprintf("v%s.", app_version) else NULL,
    sprintf("Built on %s.", format(Sys.Date(), "%Y-%m-%d")),
    "CGIAR Alliance / Bioversity-CIAT — funded by the Global Methane Hub."
  )
  doc <- .add_p(doc, paste(footer_bits, collapse = " "))

  print(doc, target = path)
  invisible(path)
}

.build_trend_exec_summary <- function(trend_results, slope, delta_total,
                                        sensitivity_delta, year_corr, n_iter) {
  yrs <- range(trend_results$Year)
  delta_pct_str <- sprintf("%s%% (95%% CI %s%%, %s%%)",
                            .fmt_signed(delta_total$pct_mean, 1),
                            .fmt_signed(delta_total$pct_ci[1], 1),
                            .fmt_signed(delta_total$pct_ci[2], 1))
  slope_str <- sprintf("%s t CO2eq/yr (95%% CI %s, %s)",
                        .fmt_signed(slope$mean, 0),
                        .fmt_signed(slope$ci[1], 0),
                        .fmt_signed(slope$ci[2], 0))

  driver_text <- ""
  base <- if (!is.null(sensitivity_delta$src) && nrow(sensitivity_delta$src) > 0)
    sensitivity_delta$src
  else if (!is.null(sensitivity_delta$prcc) && nrow(sensitivity_delta$prcc) > 0)
    sensitivity_delta$prcc
  else NULL
  if (!is.null(base) && nrow(base) > 0) {
    val_col <- if ("src" %in% names(base)) "src" else "prcc"
    top <- base[order(-abs(base[[val_col]])), , drop = FALSE][1, ]
    driver_text <- sprintf(
      " The dominant trend driver is %s (%s = %s).",
      top$parameter, toupper(val_col),
      formatC(top[[val_col]], digits = 2, format = "f"))
  }

  yc_short <- switch(
    year_corr,
    full    = "fully correlated coefficients across years (IPCC 2019 default)",
    partial = "partial year-to-year correlation (AR(1), ρ = 0.7)",
    none    = "independent years"
  )

  sprintf(
    "Between %d and %d, total cattle emissions changed by %s. The annualised trend slope is %s.%s These figures are based on %s Monte Carlo iterations per year, with %s.",
    yrs[1], yrs[2], delta_pct_str, slope_str, driver_text,
    .fmt_int(n_iter), yc_short
  )
}

# ============================================================================
# Flextable builders
# ============================================================================

.settings_flextable <- function(s) {
  rows <- list(
    c("Iterations",            .fmt_int(s$n_iter)),
    c("AD correlations",       .as_str(s$corr_mode,    "none")),
    c("EF correlations",       .as_str(s$ef_corr_mode, "none")),
    c("Comparison run (no corr.)", if (isTRUE(s$run_comparison)) "yes" else "no"),
    c("GWP basis",             .as_str(s$gwp_version,  "AR5")),
    c("Seed",                  .as_str(s$seed,         "(random)")),
    c("Analysis mode",         .as_str(s$analysis_mode, "single-year")),
    c("Emission sources",
      if (length(s$emission_sources)) paste(s$emission_sources, collapse = ", ") else "(none)")
  )
  df <- do.call(rbind.data.frame, c(rows, list(stringsAsFactors = FALSE)))
  names(df) <- c("Setting", "Value")
  flextable::flextable(df)
}

.trend_settings_flextable <- function(year_corr, n_iter, yrs, ipcc_meta) {
  yc_label <- switch(
    year_corr,
    full    = "Full (coefficients reused across years; AD redrawn) — IPCC 2019 default",
    partial = "Partial (AR(1), ρ = 0.7)",
    none    = "Independent (no year-to-year correlation)"
  )
  rows <- list(
    c("Year range",              sprintf("%d – %d", yrs[1], yrs[2])),
    c("Iterations per year",     .fmt_int(n_iter)),
    c("Year-to-year correlation", yc_label),
    c("IPCC guidelines version",
      if (!is.null(ipcc_meta) && !is.null(ipcc_meta$ipcc_version))
        ipcc_meta$ipcc_version else "(not set)"),
    c("Region",
      if (!is.null(ipcc_meta) && !is.null(ipcc_meta$region) &&
          nzchar(ipcc_meta$region)) ipcc_meta$region else "(not set)")
  )
  df <- do.call(rbind.data.frame, c(rows, list(stringsAsFactors = FALSE)))
  names(df) <- c("Setting", "Value")
  flextable::flextable(df)
}

.imputed_flextable <- function(param_specs) {
  if (is.null(param_specs) || !"imputed" %in% names(param_specs)) return(NULL)
  flag <- param_specs$imputed
  flag[is.na(flag)] <- FALSE
  rows <- param_specs[as.logical(flag), , drop = FALSE]
  if (nrow(rows) == 0) return(NULL)

  cat_lookup <- PARAM_CATALOGUE[, c("parameter", "unit", "ipcc_ref")]
  names(cat_lookup)[2:3] <- c("unit_cat", "ipcc_ref_cat")
  rows <- merge(rows, cat_lookup, by = "parameter", all.x = TRUE, sort = FALSE)
  unit_user <- if ("unit" %in% names(rows)) rows$unit else rep(NA_character_, nrow(rows))
  ref_user  <- if ("ipcc_ref" %in% names(rows)) rows$ipcc_ref else rep(NA_character_, nrow(rows))

  pick <- function(primary, fallback) {
    out <- as.character(primary)
    miss <- is.na(out) | !nzchar(out)
    out[miss] <- as.character(fallback)[miss]
    out
  }

  df <- data.frame(
    Parameter        = rows$parameter,
    Value            = formatC(rows$mean, digits = 4, format = "g"),
    Unit             = pick(unit_user, rows$unit_cat),
    `IPCC ref`       = pick(ref_user,  rows$ipcc_ref_cat),
    Source           = if ("data_source" %in% names(rows)) rows$data_source
                       else rep("AUTO-FILLED (IPCC default)", nrow(rows)),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  flextable::flextable(df)
}

.results_flextable <- function(uncertainty) {
  # Andreas 2026-05 #37, #39, C11: Section 4 must report every IPCC emission
  # source as its own row (was previously gas-only) and every numeric column
  # must carry its unit. Order matches IPCC Table 3.3 reporting flow.
  if (is.null(uncertainty) || !is.data.frame(uncertainty) || nrow(uncertainty) == 0) {
    return(flextable::flextable(data.frame(Note = "No uncertainty results available.")))
  }
  # Prefer per-system (singular) columns when present (rv$mc_results$by_system),
  # otherwise fall back to inventory totals (run_inventory_simulation output).
  primary_vars <- c("enteric_ch4_total", "manure_ch4_total",
                    "direct_n2o_mm_total", "indirect_n2o_mm_total",
                    "direct_n2o_prp_total", "indirect_n2o_prp_total",
                    "total_ch4", "total_n2o", "total_co2e")
  fallback_vars <- c("total_enteric_ch4", "total_manure_ch4",
                     "total_direct_n2o_mm", "total_indirect_n2o_mm",
                     "total_direct_n2o_prp", "total_indirect_n2o_prp",
                     "total_ch4", "total_n2o", "total_co2e")
  display_vars <- if (any(primary_vars %in% uncertainty$variable))
    primary_vars else fallback_vars
  keep <- uncertainty[match(display_vars, uncertainty$variable), , drop = FALSE]
  keep <- keep[!is.na(keep$variable), , drop = FALSE]
  if (nrow(keep) == 0) keep <- uncertainty

  df <- data.frame(
    `Emission category` = .pretty_var(keep$variable),
    Unit                = .unit_for_var(keep$variable),
    Mean                = formatC(keep$mean,     digits = 4, format = "g"),
    `CI lower`          = formatC(keep$ci_lower, digits = 4, format = "g"),
    `CI upper`          = formatC(keep$ci_upper, digits = 4, format = "g"),
    `CV (%)`            = formatC(keep$cv_pct,   digits = 3, format = "g"),
    `MoE 95% (%)`       = formatC(keep$moe_pct,  digits = 3, format = "g"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  flextable::flextable(df)
}

.ipcc_flextable <- function(ipcc_table) {
  flextable::flextable(ipcc_table)
}

.trend_table_flextable <- function(trend_results) {
  cols <- intersect(
    c("Year", "Mean_t_CO2eq", "CI_Lower_t", "CI_Upper_t",
      "CV_pct", "MoE_95_pct", "Delta_vs_base_pct", "YoY_pct"),
    names(trend_results)
  )
  df <- trend_results[, cols, drop = FALSE]
  pretty <- c(Year = "Year",
              Mean_t_CO2eq = "Mean (t CO2eq)",
              CI_Lower_t   = "CI lower",
              CI_Upper_t   = "CI upper",
              CV_pct       = "CV %",
              MoE_95_pct   = "MoE %",
              Delta_vs_base_pct = "Δ vs base (%)",
              YoY_pct      = "YoY (%)")
  names(df) <- pretty[names(df)]
  flextable::flextable(df)
}

.slope_delta_flextable <- function(slope, delta_total) {
  df <- data.frame(
    Metric = c("Trend slope (t CO2eq / yr)",
               "Δ total Y_N − Y_1 (t CO2eq)",
               "Δ percent (vs Y_1)"),
    Mean   = c(.fmt_signed(slope$mean, 0),
               .fmt_signed(delta_total$mean, 0),
               paste0(.fmt_signed(delta_total$pct_mean, 1), "%")),
    `95% CI lower` = c(.fmt_signed(slope$ci[1], 0),
                       .fmt_signed(delta_total$ci[1], 0),
                       paste0(.fmt_signed(delta_total$pct_ci[1], 1), "%")),
    `95% CI upper` = c(.fmt_signed(slope$ci[2], 0),
                       .fmt_signed(delta_total$ci[2], 0),
                       paste0(.fmt_signed(delta_total$pct_ci[2], 1), "%")),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  flextable::flextable(df)
}

.sensitivity_flextable <- function(sens) {
  if (is.null(sens) || length(sens) == 0) return(NULL)
  src  <- sens$src
  prcc <- sens$prcc
  if ((is.null(src)  || nrow(src) == 0) &&
      (is.null(prcc) || nrow(prcc) == 0)) return(NULL)

  base <- if (!is.null(src) && nrow(src) > 0) src else prcc
  val_col <- if ("src" %in% names(base)) "src"
             else if ("prcc" %in% names(base)) "prcc"
             else names(base)[2]
  base <- base[order(-abs(base[[val_col]])), , drop = FALSE]
  base <- utils::head(base, 10)

  src_disp  <- if ("src" %in% names(base))
                 formatC(base$src,  digits = 3, format = "f") else NULL
  prcc_disp <- if (!is.null(prcc) && "prcc" %in% names(prcc))
                 formatC(prcc$prcc[match(base$parameter, prcc$parameter)],
                         digits = 3, format = "f") else NULL

  df <- data.frame(Parameter = base$parameter, stringsAsFactors = FALSE)
  if (!is.null(src_disp))  df$SRC  <- src_disp
  if (!is.null(prcc_disp)) df$PRCC <- prcc_disp
  flextable::flextable(df)
}

# ============================================================================
# ggplot helpers
# ============================================================================

.gg_total_co2e_hist <- function(mc_results) {
  if (is.null(mc_results) || is.null(mc_results$inventory)) return(NULL)
  inv <- mc_results$inventory
  if (!"total_co2e" %in% names(inv)) return(NULL)
  x <- inv$total_co2e
  if (length(x) == 0 || all(is.na(x))) return(NULL)
  q025 <- stats::quantile(x, 0.025, names = FALSE)
  q975 <- stats::quantile(x, 0.975, names = FALSE)

  ggplot2::ggplot(data.frame(value = x), ggplot2::aes(x = value)) +
    ggplot2::geom_histogram(bins = 40, fill = .GREEN_MID, colour = "white") +
    ggplot2::geom_vline(xintercept = c(q025, q975),
                        linetype = "dashed", colour = "#C1121F") +
    ggplot2::geom_vline(xintercept = mean(x), colour = "black") +
    ggplot2::labs(x = "Total CO2eq (t CO2eq)", y = "Frequency") +
    ggplot2::theme_minimal(base_size = 10)
}

.gg_tornado <- function(sens) {
  if (is.null(sens) || length(sens) == 0) return(NULL)
  base <- if (!is.null(sens$src) && is.data.frame(sens$src) && nrow(sens$src) > 0) {
    sens$src
  } else if (!is.null(sens$prcc) && is.data.frame(sens$prcc) && nrow(sens$prcc) > 0) {
    sens$prcc
  } else NULL
  if (is.null(base)) return(NULL)
  val_col <- if ("src" %in% names(base)) "src" else "prcc"
  if (!val_col %in% names(base) || !"parameter" %in% names(base)) return(NULL)

  top <- utils::head(base[order(-abs(base[[val_col]])), , drop = FALSE], 10)
  top <- top[order(top[[val_col]]), , drop = FALSE]
  top$parameter <- factor(top$parameter, levels = top$parameter)

  ggplot2::ggplot(top, ggplot2::aes(x = .data[[val_col]], y = parameter,
                                     fill = .data[[val_col]] > 0)) +
    ggplot2::geom_col() +
    ggplot2::scale_fill_manual(values = c(`TRUE` = .GREEN_MID, `FALSE` = "#C1121F"),
                                guide = "none") +
    ggplot2::labs(x = toupper(val_col), y = NULL) +
    ggplot2::theme_minimal(base_size = 10)
}

.gg_source_grid <- function(mc_results) {
  if (is.null(mc_results) || is.null(mc_results$inventory)) return(NULL)
  inv <- mc_results$inventory
  picks <- c(
    "Enteric CH4"          = "enteric_ch4_total",
    "Manure CH4"           = "manure_ch4_total",
    "Manure N2O (direct)"  = "direct_n2o_mm_total",
    "Manure N2O (indirect)"= "indirect_n2o_mm_total",
    "Total CO2eq"          = "total_co2e"
  )
  parts <- list()
  for (lab in names(picks)) {
    col <- picks[[lab]]
    if (col %in% names(inv)) {
      v <- inv[[col]]
      if (length(v) > 0 && stats::sd(v, na.rm = TRUE) > 0) {
        parts[[length(parts) + 1L]] <- data.frame(value = v, source = lab)
      }
    }
  }
  if (length(parts) == 0) return(NULL)
  df <- do.call(rbind, parts)
  df$source <- factor(df$source, levels = unique(df$source))

  ggplot2::ggplot(df, ggplot2::aes(x = value)) +
    ggplot2::geom_histogram(bins = 30, fill = .GREEN_MID, colour = "white") +
    ggplot2::facet_wrap(~ source, scales = "free", ncol = 3) +
    ggplot2::labs(x = NULL, y = "Frequency") +
    ggplot2::theme_minimal(base_size = 9) +
    ggplot2::theme(strip.text = ggplot2::element_text(face = "bold"))
}

# Round 8: trend chart for the trend Word doc — line + 95% CI ribbon
.gg_trend_chart <- function(trend_results) {
  if (is.null(trend_results) || nrow(trend_results) == 0) return(NULL)
  ggplot2::ggplot(trend_results,
                   ggplot2::aes(x = Year, y = Mean_t_CO2eq)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = CI_Lower_t, ymax = CI_Upper_t),
                          fill = .GREEN_MID, alpha = 0.25) +
    ggplot2::geom_line(colour = .GREEN_DARK, linewidth = 1) +
    ggplot2::geom_point(colour = .GREEN_DARK, size = 2.5) +
    ggplot2::labs(x = "Inventory year", y = "Total CO2eq (t)",
                   title = "Trend in total CO2eq emissions (95% CI)") +
    ggplot2::theme_minimal(base_size = 10)
}
