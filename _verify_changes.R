source("R/utils_template.R")
source("R/utils_qaqc.R")
cat("EF3_PRP lo/hi:", PARAM_CATALOGUE[PARAM_CATALOGUE$parameter=="EF3_PRP","suggested_lower_bound"],
    "/", PARAM_CATALOGUE[PARAM_CATALOGUE$parameter=="EF3_PRP","suggested_upper_bound"], "\n")
cat("EF4 lo/hi:", PARAM_CATALOGUE[PARAM_CATALOGUE$parameter=="EF4","suggested_lower_bound"],
    "/", PARAM_CATALOGUE[PARAM_CATALOGUE$parameter=="EF4","suggested_upper_bound"], "\n")
cat("Frac_GASMS lo/hi:", PARAM_CATALOGUE[PARAM_CATALOGUE$parameter=="Frac_GASMS","suggested_lower_bound"],
    "/", PARAM_CATALOGUE[PARAM_CATALOGUE$parameter=="Frac_GASMS","suggested_upper_bound"], "\n")
cat("Frac_GASM_PRP lo/hi:", PARAM_CATALOGUE[PARAM_CATALOGUE$parameter=="Frac_GASM_PRP","suggested_lower_bound"],
    "/", PARAM_CATALOGUE[PARAM_CATALOGUE$parameter=="Frac_GASM_PRP","suggested_upper_bound"], "\n")
cat("MONNI_BENCHMARK_PARAMS exists:", exists("MONNI_BENCHMARK_PARAMS"), "\n")
cat("ASYMMETRIC_PARAMS:", paste(ASYMMETRIC_PARAMS, collapse=", "), "\n")
