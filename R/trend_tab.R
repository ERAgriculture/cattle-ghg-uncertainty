# Trend Tab — multi-year inventory uncertainty (F / T4.22 / TT.6)
#
# Reads a long-format CSV (year, parameter, mean, uncertainty_pct), runs a
# separate Monte Carlo simulation per year using the year-specific values, and
# returns a data.frame summarising the per-year mean / 95% CI / margin of error
# and a percent-change column relative to the earliest year.

# Build a parsable param_specs from a single year's slice of the long CSV.
.trend_year_specs <- function(year_df, base_specs, catalogue = PARAM_CATALOGUE) {
  # Start from the user's current param_specs (preserves grouping / param_type)
  ps <- base_specs
  # Apply year-specific mean and uncertainty_pct where the long CSV provides them
  for (i in seq_len(nrow(year_df))) {
    p   <- year_df$parameter[i]
    new_mean <- suppressWarnings(as.numeric(year_df$mean[i]))
    new_pct  <- suppressWarnings(as.numeric(year_df$uncertainty_pct[i]))
    sel <- which(ps$parameter == p)
    if (length(sel) == 0) next
    if (!is.na(new_mean)) ps$mean[sel] <- new_mean
    if (!is.na(new_pct))  ps$uncertainty_pct[sel] <- new_pct
    # Recompute bounds from the new mean and pct
    if (!is.na(new_mean) && !is.na(new_pct)) {
      ps$lower[sel] <- new_mean * (1 - new_pct / 100)
      ps$upper[sel] <- new_mean * (1 + new_pct / 100)
    }
  }
  ps
}

run_trend_analysis <- function(trend_df, base_specs, n_iter = 2000,
                                gwp = "AR5", seed = 42) {
  # Required columns
  req_cols <- c("year", "parameter", "mean", "uncertainty_pct")
  miss <- setdiff(req_cols, names(trend_df))
  if (length(miss) > 0)
    stop("Trend CSV is missing column(s): ", paste(miss, collapse = ", "))

  # Apply legacy parameter aliases (so old DE_pct etc. still work)
  if (exists("PARAM_ALIASES")) {
    aliased <- trend_df$parameter %in% names(PARAM_ALIASES)
    if (any(aliased))
      trend_df$parameter[aliased] <- PARAM_ALIASES[trend_df$parameter[aliased]]
  }

  trend_df$year <- suppressWarnings(as.integer(trend_df$year))
  trend_df <- trend_df[!is.na(trend_df$year), , drop = FALSE]
  years <- sort(unique(trend_df$year))
  if (length(years) < 2)
    stop("Trend CSV must contain at least 2 distinct years.")

  rows <- list()
  for (y in years) {
    year_slice <- trend_df[trend_df$year == y, , drop = FALSE]
    ps <- .trend_year_specs(year_slice, base_specs)

    # Reuse run_inventory_simulation infrastructure: build one minimal system
    sys <- list(
      param_specs    = ps,
      corr_matrix    = NULL,
      mms_fractions  = c(pasture = 0.70, solid_storage = 0.30),
      mcf_values     = c(pasture = 0.015, solid_storage = 0.050),
      ef3_values     = c(pasture = 0.020, solid_storage = 0.005),
      ef_corr_matrix = NULL
    )
    sim <- run_inventory_simulation(
      list(year_run = sys), n_iter = n_iter, gwp = gwp, seed = seed
    )
    co2e <- sim$inventory$total_co2e
    m    <- mean(co2e)
    lo   <- quantile(co2e, 0.025, names = FALSE)
    hi   <- quantile(co2e, 0.975, names = FALSE)
    moe  <- if (m > 0) ((hi - lo) / 2) / m * 100 else NA_real_

    rows[[length(rows) + 1]] <- data.frame(
      Year         = y,
      Mean_t_CO2eq = round(m, 2),
      CI_Lower_t   = round(lo, 2),
      CI_Upper_t   = round(hi, 2),
      MoE_95_pct   = round(moe, 1)
    )
  }

  out <- do.call(rbind, rows)
  base_mean <- out$Mean_t_CO2eq[1]
  out$Delta_vs_base_pct <- round((out$Mean_t_CO2eq - base_mean) / base_mean * 100, 1)
  out
}
