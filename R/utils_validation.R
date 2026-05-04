# Input Validation Functions

validate_param_specs <- function(param_specs) {
  errors <- character()
  warnings <- character()

  required_cols <- c("parameter", "mean", "lower", "upper", "distribution", "param_type")
  missing <- setdiff(required_cols, names(param_specs))
  if (length(missing) > 0) {
    errors <- c(errors, paste("Missing columns:", paste(missing, collapse = ", ")))
    return(list(valid = FALSE, errors = errors, warnings = warnings))
  }

  pop_rows <- param_specs$parameter == "cattle_pop"
  if (any(param_specs$mean[pop_rows] < 0, na.rm = TRUE))
    errors <- c(errors, "Cattle population cannot be negative")

  de_rows <- param_specs$parameter == "DE_pct"
  if (any(param_specs$mean[de_rows] > 100 | param_specs$mean[de_rows] < 0, na.rm = TRUE))
    errors <- c(errors, "Digestible energy must be between 0 and 100%")

  bad_bounds <- param_specs$lower >= param_specs$upper &
    !param_specs$distribution %in% c("constant", "const")
  if (any(bad_bounds, na.rm = TRUE))
    errors <- c(errors, paste("Lower >= upper for:",
                               paste(param_specs$parameter[which(bad_bounds)], collapse = ", ")))

  valid_dists <- c("normal", "posnorm", "lognormal", "beta", "triangular", "pert",
                   "uniform", "constant", "const", "tnorm_0_1")
  invalid <- !tolower(param_specs$distribution) %in% valid_dists
  if (any(invalid))
    errors <- c(errors, paste("Invalid distribution:",
                               paste(param_specs$parameter[invalid], collapse = ", ")))

  # -------------------------------------------------------------------------
  # Controlled vocabulary checks (warnings only, backwards compatible)
  # -------------------------------------------------------------------------
  if ("param_type" %in% names(param_specs) && exists("PARAM_TYPES")) {
    bad_pt <- !(tolower(param_specs$param_type) %in% PARAM_TYPES) &
              !is.na(param_specs$param_type) & nzchar(param_specs$param_type)
    if (any(bad_pt))
      errors <- c(errors, paste("Invalid param_type value(s):",
                                 paste(unique(param_specs$param_type[bad_pt]), collapse = ", "),
                                 "- must be 'activity_data' or 'emission_factor'"))
  }

  list(valid = length(errors) == 0, errors = errors, warnings = warnings)
}

# Validate the Inventory_Metadata sheet against controlled vocabularies
validate_inventory_metadata <- function(meta) {
  errors <- character()
  warnings <- character()
  if (is.null(meta) || nrow(meta) == 0) {
    warnings <- c(warnings, "No Inventory_Metadata provided - using defaults.")
    return(list(valid = TRUE, errors = errors, warnings = warnings))
  }
  m <- meta[1, , drop = FALSE]

  if (!is.null(m$species) && nzchar(m$species) && exists("SPECIES_OPTIONS")) {
    if (!(m$species %in% SPECIES_OPTIONS))
      warnings <- c(warnings, paste("species '", m$species,
                                     "' not in controlled list:",
                                     paste(SPECIES_OPTIONS, collapse = ", "), sep = ""))
  }
  if (!is.null(m$ipcc_version) && nzchar(m$ipcc_version) && exists("IPCC_VERSIONS")) {
    if (!(m$ipcc_version %in% IPCC_VERSIONS))
      warnings <- c(warnings, paste("ipcc_version should be one of:",
                                     paste(IPCC_VERSIONS, collapse = ", ")))
  }
  list(valid = length(errors) == 0, errors = errors, warnings = warnings)
}

# Validate Manure_Management rows (fractions sum to 100, controlled MMS types)
validate_manure_sheet <- function(manure_df) {
  errors <- character()
  warnings <- character()
  if (is.null(manure_df) || nrow(manure_df) == 0)
    return(list(valid = TRUE, errors = errors, warnings = warnings))

  # TT.3: MMS list expanded to cover IPCC 2006 + 2019 Refinement
  valid_mms <- if (exists("MMS_DEFAULTS")) MMS_DEFAULTS$id else
    c("pasture", "daily_spread", "solid_storage", "solid_storage_covered",
      "dry_lot", "deep_bedding", "liquid_slurry", "composting", "lagoon",
      "anaerobic_digester", "aerobic_treatment", "burned_for_fuel")
  if ("mms_type" %in% names(manure_df)) {
    bad <- !(manure_df$mms_type %in% valid_mms)
    if (any(bad))
      errors <- c(errors, paste("Invalid mms_type(s):",
                                 paste(unique(manure_df$mms_type[bad]), collapse = ", ")))
  }

  # Support both old column names (backwards compat) and new 3-level naming
  has_new_cols <- all(c("cattle_type", "aggregation_level", "fraction_pct") %in% names(manure_df))
  has_old_cols <- all(c("system", "subsystem", "fraction_pct") %in% names(manure_df))
  if (has_new_cols) {
    sub_col <- if ("sub_category" %in% names(manure_df)) manure_df$sub_category else ""
    key <- paste(manure_df$cattle_type, manure_df$aggregation_level, sub_col, sep = "||")
    sums <- tapply(manure_df$fraction_pct, key, sum, na.rm = TRUE)
    off <- sums[abs(sums - 100) > 1]
    if (length(off) > 0) {
      errors <- c(errors, paste("Manure fractions do not sum to 100% for:",
                                 paste(names(off), collapse = "; "),
                                 "(got", paste(round(off, 1), collapse = ", "), ")"))
    }
  } else if (has_old_cols) {
    key <- paste(manure_df$system, manure_df$subsystem, sep = "||")
    sums <- tapply(manure_df$fraction_pct, key, sum, na.rm = TRUE)
    off <- sums[abs(sums - 100) > 1]
    if (length(off) > 0) {
      errors <- c(errors, paste("Manure fractions do not sum to 100% for:",
                                 paste(names(off), collapse = "; "),
                                 "(got", paste(round(off, 1), collapse = ", "), ")"))
    }
  }

  list(valid = length(errors) == 0, errors = errors, warnings = warnings)
}

validate_corr_matrix <- function(corr_matrix, n_params) {
  errors <- character()
  if (!is.matrix(corr_matrix))
    return(list(valid = FALSE, errors = "Correlation matrix must be a matrix"))
  if (nrow(corr_matrix) != n_params || ncol(corr_matrix) != n_params)
    errors <- c(errors, paste("Matrix dimensions don't match parameters:", n_params))
  if (!isSymmetric(corr_matrix, tol = 1e-8))
    errors <- c(errors, "Correlation matrix is not symmetric")
  eigenvalues <- eigen(corr_matrix, only.values = TRUE)$values
  if (any(eigenvalues < -1e-8))
    errors <- c(errors, "Correlation matrix is not positive semi-definite (can be auto-corrected)")
  list(valid = length(errors) == 0, errors = errors)
}

validate_manure_fractions <- function(fractions) {
  total <- sum(fractions)
  if (abs(total - 1.0) > 0.01)
    return(list(valid = FALSE,
                errors = paste("Manure fractions sum to", round(total * 100, 1), "% (must be ~100%)")))
  list(valid = TRUE, errors = character())
}

# T1.2 / T2.2: completeness check — every defined sub-category must have all
# `core` parameters from the catalogue. Returns a list with $valid, $missing
# (data frame of group × parameter), and $message (human-readable summary).
validate_completeness <- function(param_specs, catalogue = PARAM_CATALOGUE) {
  if (is.null(param_specs) || nrow(param_specs) == 0)
    return(list(valid = FALSE, missing = NULL,
                message = "No parameters loaded."))

  required <- catalogue$parameter[catalogue$param_tier == "core"]

  group_cols <- intersect(c("cattle_type", "aggregation_level", "sub_category"),
                          names(param_specs))
  if (length(group_cols) == 0) {
    # Single-group fallback
    found  <- unique(param_specs$parameter)
    miss   <- setdiff(required, found)
    if (length(miss) == 0) return(list(valid = TRUE, missing = NULL, message = "Complete."))
    return(list(valid = FALSE,
                missing = data.frame(group = "(all)",
                                     parameter = miss,
                                     stringsAsFactors = FALSE),
                message = paste("Missing core parameter(s):",
                                paste(miss, collapse = ", "))))
  }

  groups <- unique(param_specs[, group_cols, drop = FALSE])
  miss_rows <- list()
  for (i in seq_len(nrow(groups))) {
    g     <- groups[i, , drop = FALSE]
    sel   <- Reduce(`&`, lapply(group_cols, function(c) param_specs[[c]] == g[[c]]))
    found <- unique(param_specs$parameter[sel])
    miss  <- setdiff(required, found)
    if (length(miss) > 0) {
      label <- paste(unlist(g), collapse = " / ")
      miss_rows[[length(miss_rows) + 1]] <- data.frame(
        group = label, parameter = miss, stringsAsFactors = FALSE)
    }
  }

  if (length(miss_rows) == 0)
    return(list(valid = TRUE, missing = NULL,
                message = "All sub-categories have the required core parameters."))

  miss_df <- do.call(rbind, miss_rows)
  msg <- paste0("Missing ", nrow(miss_df), " parameter-rows across ",
                length(unique(miss_df$group)), " sub-categor",
                if (length(unique(miss_df$group)) == 1) "y" else "ies",
                ". First few: ",
                paste(head(paste0(miss_df$group, " — ", miss_df$parameter), 3),
                      collapse = "; "), ".")
  list(valid = FALSE, missing = miss_df, message = msg)
}
