# QA/QC checks for uploaded parameter specifications
# run_qaqc() returns a tidy data.frame: one row per (group x parameter x check)

# C1: IPCC-aligned names; legacy names auto-renamed by parse_uploaded_template.
# Andreas 2026-05-27: EF3_S / Frac_GASMS / Frac_LEACH_H removed from the
# Parameters sheet (now specified per-MMS in Manure_Management), so they are
# no longer Parameters-tab QA/QC targets. Kept as legacy aliases tolerated on
# upload but not benchmarked here.
ASYMMETRIC_PARAMS <- c("EF3_PRP", "EF4", "EF5",
                        "Frac_GASM_PRP", "Frac_LEACH_PRP")
FRACTION_PARAMS   <- c("pct_calving", "ASH", "UE",
                        "Frac_GASM_PRP", "Frac_LEACH_PRP")

# IPCC alignment audit (2026-05): for parameters whose IPCC default depends
# on a contextual choice the inventory compiler should make (climate zone,
# production system, animal class), the auto-fill notification appends an
# explicit hint so users know to review the value rather than accept it.
CONTEXT_DEPENDENT_HINTS <- list(
  EF3_PRP        = "DEFAULT IS THE 2019R AGGREGATED VALUE. Climate-disaggregated values are available in Vol.4 Ch.11 Table 11.1: cattle/poultry/pigs = 0.006 (wet climate) / 0.002 (dry climate). Set the value that matches your country's climate.",
  EF4            = "DEFAULT IS THE 2019R AGGREGATED VALUE (0.010). Climate-disaggregated values in Vol.4 Ch.11 Table 11.3: 0.014 (wet) / 0.005 (dry). Set the value that matches your country's climate.",
  Frac_LEACH_PRP = "DEFAULT IS THE 2019R WET-CLIMATE VALUE (0.24). In dry climates the IPCC default is 0. Vol.4 Ch.11 Table 11.3.",
  Bo             = "DEFAULT IS THE 2019R 'OTHER REGIONS, LOW PRODUCTIVITY' CATTLE VALUE (0.13). For intensive dairy in North America / Western Europe, Vol.4 Ch.10 Table 10.16(a) gives 0.24; consult the table for your production system.",
  MCF            = "DEFAULT IS PER-MMS x CLIMATE ZONE. Pick the row that matches BOTH your manure-management system AND your climate zone (Vol.4 Ch.10 Table 10.17). Tropical lagoon MCF (80%) differs sharply from temperate solid storage (4%).",
  Ym             = "DEFAULT IS 6.5% (Vol.4 Ch.10 Table 10.12, low-productivity cattle on forage). Other Table 10.12 rows: high-DE dairy = 5.7-6.0%; feedlot = 3.0-4.0%. Pick the row that matches your diet quality.",
  Cfi            = "DEFAULT IS THE LACTATING-COW VALUE (0.386, Vol.4 Ch.10 Table 10.4). For non-lactating cattle/buffalo = 0.322; for bulls = 0.370. Pick the row that matches your sub-category.",
  Ca             = "DEFAULT IS THE PASTURE-FLAT VALUE (0.17, Vol.4 Ch.10 Table 10.5). For stall-fed = 0; for hilly grazing = 0.36. Pick the row that matches the feeding situation."
)

run_qaqc <- function(param_specs, catalogue = PARAM_CATALOGUE, region = "global") {
  ps <- param_specs

  # Build reference lookup from catalogue
  ref <- catalogue[, c("parameter", "ipcc_default", "suggested_lower_bound",
                        "suggested_upper_bound", "param_tier",
                        "unit", "ipcc_ref")]
  # Rename catalogue's unit/ipcc_ref to avoid clobbering values already on ps
  names(ref)[names(ref) == "unit"]     <- "unit_cat"
  names(ref)[names(ref) == "ipcc_ref"] <- "ipcc_ref_cat"
  ps <- merge(ps, ref, by = "parameter", all.x = TRUE, sort = FALSE)

  # G2: override ipcc_default with region-specific value where available
  if (exists("get_regional_default")) {
    for (i in seq_len(nrow(ps))) {
      reg_val <- get_regional_default(ps$parameter[i], region)
      if (!is.na(reg_val)) ps$ipcc_default[i] <- reg_val
    }
  }

  # Optional group label for multi-group uploads
  has_group_cols <- all(c("cattle_type", "sub_category") %in% names(ps))
  if (has_group_cols) {
    ps$group <- paste(ps$cattle_type, ps$sub_category, sep = " / ")
  } else {
    ps$group <- ps$parameter
  }

  rows <- vector("list", nrow(ps) * 6L)
  k <- 0L

  add <- function(grp, par, chk, sta, msg) {
    k <<- k + 1L
    rows[[k]] <<- list(group = grp, parameter = par, check = chk,
                       status = sta, message = msg)
  }

  for (i in seq_len(nrow(ps))) {
    p   <- ps$parameter[i]
    grp <- ps$group[i]
    mu  <- ps$mean[i]
    lo  <- ps$lower[i]
    hi  <- ps$upper[i]
    d   <- if ("distribution" %in% names(ps)) ps$distribution[i] else NA_character_
    ipcc_def <- ps$ipcc_default[i]

    # ------------------------------------------------------------------
    # Check 1: bounds order — lower < mean < upper
    # ------------------------------------------------------------------
    is_constant <- !is.na(d) && d %in% c("constant", "const")
    # Zero-mean parameters (hours=0 when no work, weight_gain=0 for adults, etc.)
    # are degenerate constants — pass silently rather than flagging as failure.
    is_zero_mean <- !is.na(mu) && mu == 0 && !is.na(lo) && lo == 0 &&
                    !is.na(hi) && hi == 0
    if (!is_constant && !is_zero_mean && !is.na(lo) && !is.na(hi) && !is.na(mu)) {
      if (lo > mu) {
        add(grp, p, "bounds_order", "fail",
            sprintf("Lower (%.4g) > mean (%.4g). Bounds must bracket the mean.", lo, mu))
      } else if (mu > hi) {
        add(grp, p, "bounds_order", "fail",
            sprintf("Mean (%.4g) > upper (%.4g). Bounds must bracket the mean.", mu, hi))
      } else {
        add(grp, p, "bounds_order", "pass", "Lower <= mean <= upper")
      }
    } else if (is_zero_mean) {
      add(grp, p, "bounds_order", "pass", "Zero-mean parameter (degenerate constant)")
    }

    # ------------------------------------------------------------------
    # Check 2: non-negative lower bound
    # ------------------------------------------------------------------
    if (!is.na(lo)) {
      if (lo < 0) {
        add(grp, p, "non_negative", "warn",
            sprintf("Lower bound (%.4g) is negative. All IPCC livestock parameters should be >= 0.", lo))
      } else {
        add(grp, p, "non_negative", "pass", "Lower bound >= 0")
      }
    }

    # ------------------------------------------------------------------
    # Check 3: known range constraints
    # ------------------------------------------------------------------
    if (!is.na(mu)) {
      if (p == "DE_pct") {
        if (mu < 1 || mu > 100) {
          add(grp, p, "range_check", "fail",
              sprintf("DE_pct = %.1f%%. Must be in [1, 100].", mu))
        } else {
          add(grp, p, "range_check", "pass",
              sprintf("DE_pct = %.1f%% (valid range 1-100%%)", mu))
        }
      }
      if (p == "Ym_pct") {
        if (mu < 1 || mu > 15) {
          add(grp, p, "range_check", "warn",
              sprintf("Ym_pct = %.1f%%. Typical IPCC range is 3-12%%; values outside 1-15%% are unusual.", mu))
        } else {
          add(grp, p, "range_check", "pass",
              sprintf("Ym_pct = %.1f%% (within typical IPCC range)", mu))
        }
      }
      if (p %in% FRACTION_PARAMS) {
        if (mu < 0 || mu > 1) {
          add(grp, p, "range_check", "fail",
              sprintf("%s = %.4g. Must be a fraction in [0, 1].", p, mu))
        } else {
          add(grp, p, "range_check", "pass",
              sprintf("%s = %.4g (valid fraction in [0, 1])", p, mu))
        }
      }
    }

    # ------------------------------------------------------------------
    # Check 4: distribution suitability
    # ------------------------------------------------------------------
    if (!is.na(d) && !is.na(mu)) {
      if (d == "beta") {
        if (mu <= 0 || mu >= 1) {
          add(grp, p, "dist_suitability", "fail",
              sprintf("Beta distribution requires mean in (0,1). Got %.4g.", mu))
        } else if (!is.na(lo) && !is.na(hi) && (lo < 0 || hi > 1)) {
          add(grp, p, "dist_suitability", "fail",
              sprintf("Beta distribution requires bounds in [0,1]. Got [%.4g, %.4g].", lo, hi))
        } else {
          add(grp, p, "dist_suitability", "pass", "Beta: mean in (0,1) and bounds in [0,1]")
        }
      } else if (d == "lognormal") {
        if (mu <= 0) {
          add(grp, p, "dist_suitability", "fail",
              sprintf("Log-normal requires a strictly positive mean. Got %.4g.", mu))
        } else {
          add(grp, p, "dist_suitability", "pass", "Log-normal: mean > 0")
        }
      } else if (d == "tnorm_0_1") {
        if (!is.na(lo) && !is.na(hi) && (lo < 0 || hi > 1)) {
          add(grp, p, "dist_suitability", "warn",
              sprintf("tnorm_0_1 clips to [0,1]; bounds [%.4g, %.4g] extend beyond this.", lo, hi))
        } else {
          add(grp, p, "dist_suitability", "pass", "tnorm_0_1: bounds within [0,1]")
        }
      }
    }

    # ------------------------------------------------------------------
    # Check 5: benchmark deviation from IPCC default
    # Benchmarks for all parameters are now sourced from IPCC 2006/2019
    # guideline tables (see PARAM_CATALOGUE$ipcc_ref). Country-specific
    # overrides are always expected — flag large deviations as warn/fail
    # so the user documents the source, not as errors requiring correction.
    # ------------------------------------------------------------------
    if (!is.na(ipcc_def) && ipcc_def != 0 && !is.na(mu)) {
      pct_dev <- abs(mu - ipcc_def) / abs(ipcc_def) * 100
      if (pct_dev > 200) {
        add(grp, p, "benchmark_deviation", "fail",
            sprintf("Mean (%.4g) deviates %.0f%% from IPCC guideline default (%.4g). Verify the value or document the country-specific source.",
                    mu, pct_dev, ipcc_def))
      } else if (pct_dev > 50) {
        add(grp, p, "benchmark_deviation", "warn",
            sprintf("Mean (%.4g) deviates %.0f%% from IPCC guideline default (%.4g). Large deviation — please document the source.",
                    mu, pct_dev, ipcc_def))
      } else {
        add(grp, p, "benchmark_deviation", "pass",
            sprintf("Mean (%.4g) within 50%% of IPCC guideline default (%.4g)", mu, ipcc_def))
      }
    }

    # ------------------------------------------------------------------
    # Round 7 R1.16: defensive check on user-overridden param_type values.
    # ------------------------------------------------------------------
    if ("param_type" %in% names(ps) && !is.na(ps$param_type[i])) {
      ptype <- tolower(trimws(as.character(ps$param_type[i])))
      if (!ptype %in% c("activity_data", "coefficient", "emission_factor")) {
        add(grp, p, "param_type_invalid", "fail",
            sprintf("param_type = '%s' is not recognised. Use 'activity_data' or 'coefficient'.",
                    ps$param_type[i]))
      }
    }

    # ------------------------------------------------------------------
    # Check 4b (R1.3 / Round 6b): missing parameter — auto-filled from IPCC default
    # Reported as a dedicated "missing" severity so reviewers see exactly which
    # parameters were not supplied and what default value+reference was used.
    # ------------------------------------------------------------------
    if ("imputed" %in% names(ps) && isTRUE(ps$imputed[i])) {
      unit_str <- if ("unit" %in% names(ps) && !is.na(ps$unit[i]) && nzchar(ps$unit[i])) {
        ps$unit[i]
      } else if (!is.na(ps$unit_cat[i])) {
        ps$unit_cat[i]
      } else ""
      ref_str <- if ("ipcc_ref" %in% names(ps) && !is.na(ps$ipcc_ref[i]) && nzchar(ps$ipcc_ref[i])) {
        ps$ipcc_ref[i]
      } else if (!is.na(ps$ipcc_ref_cat[i])) {
        ps$ipcc_ref_cat[i]
      } else "IPCC default"
      context_hint <- CONTEXT_DEPENDENT_HINTS[[p]]
      base_msg <- sprintf(
        "%s not supplied in upload - auto-filled with IPCC default %.4g %s (%s). Override in template if local data is available.",
        p, mu, unit_str, ref_str)
      msg <- if (!is.null(context_hint)) paste0(base_msg, " ", context_hint) else base_msg
      add(grp, p, "missing_parameter", "missing", msg)
    }

    # ------------------------------------------------------------------
    # Check 5b (T2.3): fractional parameter with unbounded distribution
    # If a fractional parameter (must lie in [0,1]) uses an unbounded
    # continuous distribution (normal, lognormal), MC samples can fall outside
    # the legal range. Recommend tnorm_0_1 or beta instead.
    # ------------------------------------------------------------------
    UNBOUNDED_DISTS <- c("normal", "lognormal", "posnorm")
    if (p %in% FRACTION_PARAMS && !is.na(d) && tolower(d) %in% UNBOUNDED_DISTS) {
      add(grp, p, "fraction_distribution", "warn",
          sprintf(
            "%s must lie in [0,1] but uses '%s' which can produce out-of-range samples. Use 'tnorm_0_1' or 'beta' instead.",
            p, d))
    } else if (p %in% FRACTION_PARAMS && !is.na(d)) {
      add(grp, p, "fraction_distribution", "pass",
          sprintf("%s: bounded distribution '%s' used", p, d))
    }

    # ------------------------------------------------------------------
    # Check 6: asymmetric bound check for right-skewed IPCC parameters
    # EF3, EF4, EF5 and Frac_* have right-skewed uncertainty documented in
    # IPCC 2006/2019 guideline tables; symmetric bounds underestimate upper tail.
    # ------------------------------------------------------------------
    if (p %in% ASYMMETRIC_PARAMS && !is.na(lo) && !is.na(hi) && !is.na(mu) && mu > 0) {
      lower_span <- mu - lo
      upper_span <- hi - mu
      if (lower_span > 0 && upper_span > 0) {
        ratio <- upper_span / lower_span
        if (ratio < 1.5) {
          add(grp, p, "asymmetric_bounds", "warn",
              sprintf(
                "%s has right-skewed uncertainty (IPCC 2006/2019 guideline tables). Detected near-symmetric bounds (upper span / lower span = %.1f). Consider using the IPCC-recommended asymmetric bounds from the blank template.",
                p, ratio))
        } else {
          add(grp, p, "asymmetric_bounds", "pass",
              sprintf("%s: asymmetric bounds applied (upper/lower span ratio = %.1f)", p, ratio))
        }
      }
    }
  }

  rows <- rows[seq_len(k)]
  if (k == 0L) {
    return(data.frame(group = character(), parameter = character(),
                      check = character(), status = character(),
                      message = character(), stringsAsFactors = FALSE))
  }

  result <- do.call(rbind, lapply(rows, as.data.frame, stringsAsFactors = FALSE))
  param_order <- unique(ps$parameter)
  # Sort: missing → fail → warn → info → pass, then by parameter and check name
  status_rank <- c(missing = 1L, fail = 2L, warn = 3L, info = 4L, pass = 5L)
  result <- result[order(
    status_rank[result$status],
    match(result$parameter, param_order),
    result$check
  ), ]
  rownames(result) <- NULL
  result
}

qaqc_summary <- function(qaqc_df) {
  list(
    n_pass    = sum(qaqc_df$status == "pass", na.rm = TRUE),
    n_info    = sum(qaqc_df$status == "info", na.rm = TRUE),
    n_warn    = sum(qaqc_df$status == "warn", na.rm = TRUE),
    n_fail    = sum(qaqc_df$status == "fail", na.rm = TRUE),
    n_missing = sum(qaqc_df$status == "missing", na.rm = TRUE)
  )
}

qaqc_icon <- function(status) {
  switch(status,
    pass    = '<span style="color:#2D6A4F;font-weight:bold;">&#10003; pass</span>',
    info    = '<span style="color:#1565C0;font-weight:bold;">&#9432; info</span>',
    warn    = '<span style="color:#B45309;font-weight:bold;">&#9651; warn</span>',
    fail    = '<span style="color:#C1121F;font-weight:bold;">&#10007; fail</span>',
    missing = '<span style="color:#92400E;font-weight:bold;background-color:#FEF3C7;padding:1px 6px;border-radius:3px;">&#9888; missing</span>',
    status
  )
}
