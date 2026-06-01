# =============================================================================
# End-to-end ZIM diagnostic — what each correlation mode actually produces
# =============================================================================
#
# Andreas (May 2026) ran the ZIM intensive-dairy upload through four correlation
# modes (none / auto-template / population scope / intake scope) and saw
# identical results across all four. Inspecting his upload revealed the
# Parameter_TimeSeries sheet was completely empty -- so the "auto from template"
# mode silently fell back to no correlations, and the scope filters compounded
# that NULL. All four runs were effectively the same "no correlations" run.
#
# This script reproduces the diagnostic by parsing the actual ZIM Excel file
# and reporting, for each of the four corr_mode values, what the run-button
# observer in R/app_server.R would have done. It is the test that would have
# flagged the silent no-op early.
#
# Run with:  Rscript R/_test_zim_correlation_modes.R
# =============================================================================

options(warn = 1)
suppressMessages({
  for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) {
    if (!grepl("^_", basename(f))) source(f)
  }
})

ZIM_FILE <- "uncertainty_template_ipcc2019_ZIM_v2.xlsx"
if (!file.exists(ZIM_FILE)) {
  stop("Expected to find ", ZIM_FILE, " in the repo root.")
}

cat("\n=============================================================\n")
cat("END-TO-END CORRELATION-MODE DIAGNOSTIC ON ZIM TEMPLATE\n")
cat("=============================================================\n\n")
cat("Source:", ZIM_FILE, "\n\n")

parsed <- parse_uploaded_template(ZIM_FILE)
cat("Parameters loaded:", if (is.null(parsed$param_specs)) 0L else nrow(parsed$param_specs), "\n")
cat("Has Parameter_TimeSeries:",
    !is.null(parsed$population) && nrow(parsed$population) > 0, "\n")
cat("compute_corr_from_population() produced a matrix:",
    !is.null(parsed$corr_matrix), "\n\n")

# Reconstruct the rv$corr_matrix that each mode would produce, mirroring the
# observers in R/app_server.R.
all_param_names <- parsed$param_specs$parameter

# Mode 1: none
m_none <- NULL

# Mode 2: timeseries -- mirrors .compute_corr_now()
m_timeseries <- parsed$corr_matrix     # NULL for ZIM (TS sheet empty)

# Mode 3: preset -- mirrors observeEvent(input$corr_mode == "preset")
m_preset <- build_ipcc_preset_corr(all_param_names)

# Mode 4: manual -- the user would have to upload a CSV; here we simulate
# "user hasn't uploaded anything yet", same as Andreas' workflow.
m_manual <- NULL

count_nz_off_diag <- function(m) {
  if (is.null(m)) return(0L)
  k <- nrow(m)
  if (k < 2) return(0L)
  upper <- m[upper.tri(m)]
  sum(abs(upper) > 1e-10)
}

rows <- list(
  list(mode = "none",       matrix_ok = "n/a", n_pairs = "n/a",
       gate_in_app = "always available", correlations_applied = "No (by design)"),
  list(mode = "timeseries", matrix_ok = !is.null(m_timeseries),
       n_pairs = count_nz_off_diag(m_timeseries),
       gate_in_app = if (!is.null(m_timeseries)) "available"
                     else "BLOCKED (radio greyed out by corr_mode_ui)",
       correlations_applied = if (!is.null(m_timeseries)) "Yes"
                              else "*** No (silent no-op without the new gate) ***"),
  list(mode = "preset",     matrix_ok = !is.null(m_preset),
       n_pairs = count_nz_off_diag(m_preset),
       gate_in_app = if (!is.null(m_preset)) "available" else "BLOCKED",
       correlations_applied = if (!is.null(m_preset)) "Yes" else "No"),
  list(mode = "manual",     matrix_ok = FALSE, n_pairs = 0L,
       gate_in_app = "BLOCKED until user uploads a CSV matrix",
       correlations_applied = "No (no upload)")
)

cat("WHAT EACH MODE PRODUCES ON THIS UPLOAD\n")
cat("---------------------------------------\n\n")
fmt <- "%-12s | %-10s | %-7s | %-50s | %s\n"
cat(sprintf(fmt, "mode", "matrix?", "n_pairs", "gate (after June 2026 UI fix)", "correlations applied"))
cat(strrep("-", 130), "\n")
for (r in rows) {
  cat(sprintf(fmt,
              r$mode,
              as.character(r$matrix_ok),
              as.character(r$n_pairs),
              r$gate_in_app,
              r$correlations_applied))
}
cat("\n")

# --- End-to-end headline check: preset vs none ------------------------------
# Andreas' question is "would I see ANY difference if I tick the working
# correlations option?" Answer: yes, the preset mode produces a measurable
# (small) shift on total CO2eq vs the no-correlations baseline.

cat("HEADLINE SHIFT: preset vs no-correlations (single MC run, n_iter=2000)\n")
cat("---------------------------------------------------------------------\n\n")

# Build the same systems_data structure the run-button observer would.
# Only run the test if we have valid param_specs.
if (is.null(parsed$param_specs) || nrow(parsed$param_specs) == 0) {
  cat("Cannot run end-to-end test: param_specs not parsed.\n")
} else {
  # Need a populated mean for every parameter; ZIM template ships with IPCC
  # defaults pre-filled for orange (coefficient) rows and the user-supplied
  # values for yellow (activity_data) rows. If any are NA, fill with the
  # IPCC defaults via ensure_completeness().
  comp <- ensure_completeness(parsed$param_specs, region = parsed$metadata$region)
  ps   <- if (isTRUE(comp$valid) && !is.null(comp$param_specs)) comp$param_specs
          else parsed$param_specs

  # Build a minimal manure structure; the ZIM template's Manure_Management
  # sheet may not be filled out in a way that's directly usable here, so we
  # fall back to a 100%-pasture default (matches IPCC simplest case).
  default_mms <- list(
    fracs = c(pasture = 1.0),
    mcf   = c(pasture = 0.015),
    ef3   = c(pasture = 0.020)
  )

  build_system <- function(corr) {
    list("dairy||all||cows" = list(
      param_specs         = ps,
      corr_matrix         = NULL,
      ef_corr_matrix      = NULL,
      unified_corr_matrix = corr,
      mms_fractions       = default_mms$fracs,
      mcf_values          = default_mms$mcf,
      ef3_values          = default_mms$ef3,
      frac_gas_values     = NULL,
      frac_leach_values   = NULL,
      mcf_samples = NULL, ef3_samples = NULL,
      frac_gas_samples = NULL, frac_leach_samples = NULL
    ))
  }

  # expand_corr_matrix lifts the preset (which only contains some pairs) to
  # the full parameter space -- same path the run-button observer uses.
  preset_unified <- if (!is.null(m_preset))
    expand_corr_matrix(m_preset, ps$parameter)
  else NULL

  run_one <- function(corr, seed = 2026) {
    set.seed(seed)
    tryCatch(
      run_inventory_simulation(build_system(corr), n_iter = 2000,
                                gwp = "AR5", seed = seed, pct_pregnant = 1),
      error = function(e) { cat("  Sim error:", conditionMessage(e), "\n"); NULL }
    )
  }

  sim_none   <- run_one(NULL)
  sim_preset <- run_one(preset_unified)

  if (!is.null(sim_none) && !is.null(sim_preset)) {
    co2e_none   <- sim_none$inventory$total_co2e
    co2e_preset <- sim_preset$inventory$total_co2e
    cat(sprintf("  mode='none':   mean=%9.1f t CO2eq   sd=%8.1f   95%% CI half-width=%8.1f\n",
                mean(co2e_none),  sd(co2e_none),
                1.96 * sd(co2e_none)  / sqrt(length(co2e_none))))
    cat(sprintf("  mode='preset': mean=%9.1f t CO2eq   sd=%8.1f   95%% CI half-width=%8.1f\n",
                mean(co2e_preset), sd(co2e_preset),
                1.96 * sd(co2e_preset) / sqrt(length(co2e_preset))))
    cat(sprintf("  -> mean shift: %+0.2f%%   sd shift: %+0.2f%%\n",
                100 * (mean(co2e_preset) - mean(co2e_none)) / mean(co2e_none),
                100 * (sd(co2e_preset)   - sd(co2e_none))   / sd(co2e_none)))
    cat("\n")
    cat("If Andreas now picks 'Structural defaults', he WILL see a small but real\n")
    cat("shift in the headline -- the preset includes Milk x BW and Milk x DE\n")
    cat("(added June 2026) plus DE x Ym = -0.50 (cross-block, biggest mover).\n")
  } else {
    cat("End-to-end run did not complete -- skipping headline-shift block.\n")
  }
}

cat("\n=============================================================\n")
cat("WHAT THE NEW UI GATE DOES\n")
cat("=============================================================\n\n")
cat("Before June 2026:\n")
cat("  Andreas could pick 'From template (auto, time-series)' on this upload\n")
cat("  even though the TS sheet is empty. The MC ran with corr_matrix=NULL,\n")
cat("  identical to 'No correlations'. No visible warning at run time.\n\n")
cat("After June 2026:\n")
cat("  The corr_mode_ui radio greys out 'From template (auto, time-series)'\n")
cat("  with an inline explanation. Same for 'Advanced - manual entry' until\n")
cat("  a CSV is uploaded. If a stale state somehow reaches the run button,\n")
cat("  a pre-run validation in observeEvent(input$run_sim) blocks with an\n")
cat("  explicit error message instead of silently no-op'ing.\n\n")
