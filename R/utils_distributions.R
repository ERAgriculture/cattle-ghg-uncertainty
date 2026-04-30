# Distribution Sampling Utilities
# Supports: normal, lognormal, beta, triangular, PERT, uniform, constant

sample_distribution <- function(n, type, mean_val, lower, upper) {
  type <- tolower(type)

  switch(type,
    "normal" = , "posnorm" = {
      sd_est <- (upper - lower) / (2 * 1.96)
      samples <- rnorm(n, mean = mean_val, sd = sd_est)
      if (type == "posnorm") samples <- pmax(samples, 0)
      samples
    },
    "lognormal" = {
      mu_log <- log(mean_val)
      sd_log <- (log(upper) - log(lower)) / (2 * 1.96)
      rlnorm(n, meanlog = mu_log, sdlog = sd_log)
    },
    "beta" = {
      mu <- (mean_val - lower) / (upper - lower)
      var_est <- ((upper - lower) / (2 * 1.96 * (upper - lower)))^2
      var_est <- min(var_est, mu * (1 - mu) * 0.99)
      alpha <- max(mu * (mu * (1 - mu) / var_est - 1), 0.1)
      beta_param <- max((1 - mu) * (mu * (1 - mu) / var_est - 1), 0.1)
      lower + (upper - lower) * rbeta(n, alpha, beta_param)
    },
    "triangular" = {
      mc2d::rtriang(n, min = lower, mode = mean_val, max = upper)
    },
    "pert" = {
      mc2d::rpert(n, min = lower, mode = mean_val, max = upper, shape = 4)
    },
    "uniform" = {
      runif(n, min = lower, max = upper)
    },
    "constant" = , "const" = {
      rep(mean_val, n)
    },
    "tnorm_0_1" = {
      sd_est <- (upper - lower) / (2 * 1.96)
      samples <- rnorm(n, mean = mean_val, sd = sd_est)
      pmin(pmax(samples, 0), 1)
    },
    stop(paste("Unknown distribution type:", type))
  )
}

# Transform uniform [0,1] to target distribution (for Gaussian copula)
transform_marginal <- function(u, distribution, mean_val, lower, upper) {
  type <- tolower(distribution)

  switch(type,
    "normal" = , "posnorm" = {
      sd_est <- (upper - lower) / (2 * 1.96)
      samples <- qnorm(u, mean = mean_val, sd = sd_est)
      if (type == "posnorm") samples <- pmax(samples, 0)
      samples
    },
    "lognormal" = {
      mu_log <- log(mean_val)
      sd_log <- (log(upper) - log(lower)) / (2 * 1.96)
      qlnorm(u, meanlog = mu_log, sdlog = sd_log)
    },
    "beta" = {
      mu <- (mean_val - lower) / (upper - lower)
      var_est <- ((upper - lower) / (2 * 1.96 * (upper - lower)))^2
      var_est <- min(var_est, mu * (1 - mu) * 0.99)
      alpha <- max(mu * (mu * (1 - mu) / var_est - 1), 0.1)
      beta_param <- max((1 - mu) * (mu * (1 - mu) / var_est - 1), 0.1)
      lower + (upper - lower) * qbeta(u, alpha, beta_param)
    },
    "triangular" = {
      mc2d::qtriang(u, min = lower, mode = mean_val, max = upper)
    },
    "pert" = {
      mc2d::qpert(u, min = lower, mode = mean_val, max = upper, shape = 4)
    },
    "uniform" = {
      qunif(u, min = lower, max = upper)
    },
    "constant" = , "const" = {
      rep(mean_val, length(u))
    },
    "tnorm_0_1" = {
      sd_est <- (upper - lower) / (2 * 1.96)
      samples <- qnorm(u, mean = mean_val, sd = sd_est)
      pmin(pmax(samples, 0), 1)
    },
    stop(paste("Unknown distribution type:", type))
  )
}

# Compute lower/upper from mean and uncertainty percentage
calc_bounds <- function(mean_val, uncertainty_pct) {
  half_range <- mean_val * (uncertainty_pct / 100)
  list(lower = mean_val - half_range, upper = mean_val + half_range)
}
