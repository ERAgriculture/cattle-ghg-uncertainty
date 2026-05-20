source("R/utils_distributions.R")
set.seed(42)
n <- 100000

# Test 1: lognormal — is the realised mean equal to mean_val, or biased?
ln <- sample_distribution(n, "lognormal", mean_val = 0.02,
                          lower = 0.003, upper = 0.040)
cat("LOGNORMAL with mean_val = 0.020, lower=0.003, upper=0.040\n")
cat("  realised arithmetic mean:", round(mean(ln), 5), "\n")
cat("  realised median:         ", round(median(ln), 5), "\n")
cat("  realised q025/q975:      ", round(quantile(ln, c(.025,.975)), 5), "\n")
cat("  expected behaviour: arithmetic mean SHOULD be 0.020 if mean_val is the arithmetic mean\n\n")

# Test 2: beta — is the realised mean and 95% CI as expected?
be <- sample_distribution(n, "beta", mean_val = 0.81,
                          lower = 0.77, upper = 0.85)
cat("BETA with mean_val = 0.81, lower=0.77, upper=0.85\n")
cat("  realised arithmetic mean:", round(mean(be), 5), "\n")
cat("  realised q025/q975:      ", round(quantile(be, c(.025,.975)), 5), "\n")
cat("  expected: mean ≈ 0.81, q025/q975 ≈ 0.77 / 0.85\n\n")

# Test 3: normal as sanity check
no <- sample_distribution(n, "normal", mean_val = 100,
                          lower = 80, upper = 120)
cat("NORMAL with mean_val = 100, lower=80, upper=120\n")
cat("  realised arithmetic mean:", round(mean(no), 2), "\n")
cat("  realised q025/q975:      ", round(quantile(no, c(.025,.975)), 2), "\n")
