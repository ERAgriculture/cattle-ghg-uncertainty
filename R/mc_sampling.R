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
                                 seed = NULL, ef_corr_matrix = NULL) {
  if (!is.null(seed)) set.seed(seed)

  ad_params <- param_specs[param_specs$param_type == "activity_data", ]
  ef_params <- param_specs[param_specs$param_type == "coefficient", ]
  n_ad <- nrow(ad_params)
  n_ef <- nrow(ef_params)

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

  # Emission factors: correlated or independent
  if (n_ef > 0) {
    use_ef_corr <- !is.null(ef_corr_matrix) &&
                   nrow(ef_corr_matrix) == n_ef && ncol(ef_corr_matrix) == n_ef
    ef_samples <- if (use_ef_corr) {
      .copula_sample(n_iter, ef_params, ef_corr_matrix)
    } else {
      .indep_sample(n_iter, ef_params)
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
