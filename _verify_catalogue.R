source("R/utils_distributions.R")
source("R/utils_ipcc_defaults.R")
source("R/utils_template.R")
cat("rows:", nrow(PARAM_CATALOGUE), "\n")
print(sapply(PARAM_CATALOGUE, length))
print(table(PARAM_CATALOGUE$param_type))
# Last row should be Tw with param_type "coefficient"
cat("\nLast row:\n")
print(PARAM_CATALOGUE[28, c("parameter", "param_type", "param_tier")])
