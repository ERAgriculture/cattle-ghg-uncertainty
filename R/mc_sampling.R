# Monte Carlo Sampling Engine
# Gaussian copula approach: MASS::mvrnorm for correlations + probability integral transform

# Build an n x n uniform correlation matrix (all off-diagonal entries = rho).
# Used for the "uniform EF correlation" option where a single rho represents
# shared systematic bias across all emission factors.
make_uniform_corr <- function(n, rho) {
  if (n <= 1) return(diag(max(n, 1L)))
  m <- matrix(rho, n, n)
  diag(m) <- 1.0
  as.matrix(Matrix::nearPD(m, corr = TRUE)$mat)
}

# Gaussian copula sampling for one block of parameters (shared helper)
.copula_sample <- function(n_iter, params, corr_mat) {
  corr_mat <- as.matrix(Matrix::nearPD(corr_mat, corr = TRUE)$mat)
  z <- MASS::mvrnorm(n_iter, mu = rep(0, nrow(corr_mat)), Sigma = corr_mat)
  u <- pnorm(z)
  samp <- matrix(NA, nrow = n_iter, ncol = nrow(params))
  for (j in seq_len(nrow(params))) {
    samp[, j] <- transform_marginal(
      u[, j], params$distribution[j],
      params$mean[j], params$lower[j], params$upper[j]
    )
  }
  colnames(samp) <- params$parameter
  samp
}

# Independent sampling for one block (no copula)
.indep_sample <- function(n_iter, params) {
  samp <- matrix(NA, nrow = n_iter, ncol = nrow(params))
  for (j in seq_len(nrow(params))) {
    samp[, j] <- sample_distribution(
      n_iter, params$distribution[j],
      params$mean[j], params$lower[j], params$upper[j]
    )
  }
  colnames(samp) <- params$parameter
  samp
}

# Generate MC samples.
#   corr_matrix    – optional correlation matrix for activity data (n_AD x n_AD)
#   ef_corr_matrix – optional correlation matrix for emission factors (n_EF x n_EF).
#                    Pass make_uniform_corr(n_ef, rho) for a uniform assumption.
generate_mc_samples <- function(param_specs, corr_matrix = NULL, n_iter = 10000,
                                 seed = NULL, ef_corr_matrix = NULL,
                                 # Round 7 T4.3: unified copula across AD + coefficients
                                 # so cross-block correlations (e.g. N <-> W) are honoured.
                                 # When supplied, this is a square named matrix covering
                                 # the union of AD and coefficient parameter names. Falls
                                 # back to the two-pass behaviour when NULL.
                                 unified_corr_matrix = NULL,
                                 # Round 7 R1.14: pre-sampled coefficient block matrix
                                 # (n_iter x n_coef) used by the trend tab to share the
                                 # same coefficient draws across years. Overrides the
                                 # coefficient-block sampler when supplied.
                                 pre_sampled_coefficients = NULL) {
  if (!is.null(seed)) set.seed(seed)

  ad_params <- param_specs[param_specs$param_type == "activity_data", ]
  ef_params <- param_specs[param_specs$param_type == "coefficient", ]
  n_ad <- nrow(ad_params)
  n_ef <- nrow(ef_params)

  # Round 7 T4.3: single-pass unified copula path
  if (!is.null(unified_corr_matrix) && (n_ad + n_ef) > 0) {
    all_params <- rbind(ad_params, ef_params)
    nm <- all_params$parameter
    M  <- diag(length(nm))
    rownames(M) <- colnames(M) <- nm
    common <- intersect(rownames(unified_corr_matrix), nm)
    if (length(common) >= 2) {
      M[common, common] <- unified_corr_matrix[common, common]
      M <- as.matrix(Matrix::nearPD(M, corr = TRUE)$mat)
      rownames(M) <- colnames(M) <- nm
      samp <- .copula_sample(n_iter, all_params, M)
      out  <- as.data.frame(samp)
      # If the trend tab supplied pre-sampled coefficients, override that block
      if (!is.null(pre_sampled_coefficients) && n_ef > 0) {
        for (cn in intersect(colnames(pre_sampled_coefficients), names(out))) {
          out[[cn]] <- pre_sampled_coefficients[, cn]
        }
      }
      return(out)
    }
    # If unified matrix has < 2 overlapping params, fall through to two-pass
  }

  # Activity data: correlated or independent
  if (n_ad > 0) {
    use_ad_corr <- !is.null(corr_matrix) &&
                   nrow(corr_matrix) == n_ad && ncol(corr_matrix) == n_ad
    ad_samples <- if (use_ad_corr) {
      .copula_sample(n_iter, ad_params, corr_matrix)
    } else {
      .indep_sample(n_iter, ad_params)
    }
  } else {
    ad_samples <- matrix(nrow = n_iter, ncol = 0)
  }

  # Emission factors: correlated, independent, or pre-sampled (R1.14 trend mode)
  if (n_ef > 0) {
    if (!is.null(pre_sampled_coefficients) &&
        nrow(pre_sampled_coefficients) == n_iter &&
        all(ef_params$parameter %in% colnames(pre_sampled_coefficients))) {
      ef_samples <- pre_sampled_coefficients[, ef_params$parameter, drop = FALSE]
    } else {
      use_ef_corr <- !is.null(ef_corr_matrix) &&
                     nrow(ef_corr_matrix) == n_ef && ncol(ef_corr_matrix) == n_ef
      ef_samples <- if (use_ef_corr) {
        .copula_sample(n_iter, ef_params, ef_corr_matrix)
      } else {
        .indep_sample(n_iter, ef_params)
      }
    }
  } else {
    ef_samples <- matrix(nrow = n_iter, ncol = 0)
  }

  as.data.frame(cbind(ad_samples, ef_samples))
}

# Compute a named correlation matrix from a time series data frame.
# Only numeric columns are used. Returns a named matrix so expand_corr_matrix()
# can later slot it into the full AD parameter space.
compute_correlation_from_timeseries <- function(pop_data) {
  numeric_cols <- sapply(pop_data, is.numeric)
  pop_numeric  <- pop_data[, numeric_cols, drop = FALSE]
  if (ncol(pop_numeric) < 2)
    stop("Time series must contain at least 2 numeric columns.")
  cor_matrix <- cor(pop_numeric, use = "complete.obs")
  as.matrix(Matrix::nearPD(cor_matrix, corr = TRUE)$mat)
}

# Dirichlet MMS-allocation sampling (introduced in Round 7 T4.21) was removed
# in the Andreas 2026-05 follow-up: it is not explicitly cited in IPCC 2006 /
# 2019 Refinement guidance, and the diagnostic run-through proved it leaves
# the mean of every emission source unchanged (Dirichlet preserves marginal
# means when per-MMS coefficients are constant). MMS% is now deterministic,
# matching the IPCC Inventory Software's behaviour. If the feature ever needs
# to come back, the previous `sample_dirichlet_simplex` implementation lives
# in git history at commit 4191b73.

# Round 7 R1.15: build the IPCC-guidance preset correlation matrix.
# Pure function — no rv dependency. Returns a named partial matrix containing
# only the pairs whose endpoints exist in `all_param_names`. Pairs missing from
# the spec are silently dropped.
#
# Existing pairs (kept from the inline observer that had the post-R1.6 bug):
#   W <-> MW (0.85), W <-> WG (0.40),
#   Milk <-> Fat (-0.30), Milk <-> pct_lactating (0.20),
#   DE <-> CP (0.50), DE <-> Ym (-0.40)
# New in Round 7:
#   Cfi <-> Ca (0.60)         R1.15: structural breed/physiology pairing
#   N   <-> W  (0.30)         T4.3: cross-block AD <-> coefficient pair
#
# Note: the post-Round-4 IPCC rename means the documented pairs use the new
# variable names directly (DE not DE_pct, Ym not Ym_pct, CP not CP_pct).
# Legacy aliases are accepted via the lookup helper below.
PRESET_PAIRS <- list(
  list(a = "W",    b = "MW",            rho = 0.85),
  list(a = "W",    b = "WG",            rho = 0.40),
  list(a = "Milk", b = "Fat",           rho = -0.30),
  list(a = "Milk", b = "pct_lactating", rho = 0.20),
  list(a = "DE",   b = "CP",            rho = 0.50),
  list(a = "DE",   b = "Ym",            rho = -0.40),
  list(a = "Cfi",  b = "Ca",            rho = 0.60),
  list(a = "N",    b = "W",             rho = 0.30)
)

# Legacy alias table — accept Round-3 names so the helper finds pairs even if
# the user uploaded a pre-rename template.
.PRESET_ALIASES <- list(
  DE_pct = "DE", Ym_pct = "Ym", CP_pct = "CP",
  cattle_pop = "N", live_weight = "W", mature_weight = "MW",
  weight_gain = "WG", milk_yield = "Milk", milk_fat = "Fat"
)

build_ipcc_preset_corr <- function(all_param_names) {
  if (length(all_param_names) < 2) return(NULL)
  # Map any legacy aliases to the canonical IPCC name for matching
  resolve <- function(nm) {
    a <- .PRESET_ALIASES[[nm]]
    if (!is.null(a)) a else nm
  }
  canonical <- vapply(all_param_names, resolve, character(1))

  m <- diag(length(all_param_names))
  rownames(m) <- colnames(m) <- all_param_names

  applied <- 0L
  for (p in PRESET_PAIRS) {
    i <- which(canonical == p$a)
    j <- which(canonical == p$b)
    if (length(i) >= 1 && length(j) >= 1) {
      m[i[1], j[1]] <- p$rho
      m[j[1], i[1]] <- p$rho
      applied <- applied + 1L
    }
  }
  if (applied == 0L) return(NULL)
  as.matrix(Matrix::nearPD(m, corr = TRUE)$mat)
}

# Expand a partial (named) correlation matrix to the full set of AD parameters.
# Parameters present in partial_corr get their pairwise correlations copied in;
# parameters absent are treated as uncorrelated with everything else (identity rows/cols).
# Returns NULL if fewer than 2 parameters overlap (correlation would be meaningless).
expand_corr_matrix <- function(partial_corr, all_param_names) {
  n      <- length(all_param_names)
  full   <- diag(n)
  rownames(full) <- colnames(full) <- all_param_names

  common <- intersect(rownames(partial_corr), all_param_names)
  if (length(common) < 2) return(NULL)

  full[common, common] <- partial_corr[common, common]
  as.matrix(Matrix::nearPD(full, corr = TRUE)$mat)
}
