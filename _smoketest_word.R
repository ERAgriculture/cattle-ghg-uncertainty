suppressPackageStartupMessages({
  library(officer); library(flextable); library(ggplot2)
})
source('R/utils_word_export.R')

# 1) Source-grid extension: ensures the pasture sources are included
fn_body <- deparse(.gg_source_grid)
stopifnot(any(grepl('direct_n2o_prp_total', fn_body)))
stopifnot(any(grepl('indirect_n2o_prp_total', fn_body)))
cat('OK: .gg_source_grid includes pasture sources\n')

# 2) Decomposition chart
decomp <- list(
  ad_only  = data.frame(variable = c('total_co2e','total_ch4','total_n2o'), cv_pct = c( 8, 12, 14)),
  ef_only  = data.frame(variable = c('total_co2e','total_ch4','total_n2o'), cv_pct = c(25, 22, 30)),
  combined = data.frame(variable = c('total_co2e','total_ch4','total_n2o'), cv_pct = c(27, 25, 33))
)
p <- .gg_decomposition(decomp)
stopifnot(inherits(p, 'ggplot'))
cat('OK: .gg_decomposition produces a ggplot\n')

# 3) Comparison chart
u_with    <- data.frame(variable = c('total_co2e','total_ch4','total_n2o'), cv_pct = c(27, 25, 33))
u_without <- data.frame(variable = c('total_co2e','total_ch4','total_n2o'), cv_pct = c(20, 18, 28))
p <- .gg_comparison(u_with, u_without)
stopifnot(inherits(p, 'ggplot'))
cat('OK: .gg_comparison produces a ggplot\n')

# 4) Convergence plot
diagnostics <- list(
  n = 5000, mcse_pct = 0.3, drift_pct = 1.2, ci_drift_pct = 3.1, skew_val = 0.6,
  trace = list(iter = seq(50, 5000, length.out = 50),
               running_mean = rep(1000, 50),
               running_lo   = rep(800, 50),
               running_hi   = rep(1200, 50),
               final_mean   = 1000, final_lo = 800, final_hi = 1200)
)
p <- .gg_convergence(diagnostics)
stopifnot(inherits(p, 'ggplot'))
cat('OK: .gg_convergence produces a ggplot\n')

# 5) Diagnostics table
ft <- .diagnostics_flextable(diagnostics)
stopifnot(inherits(ft, 'flextable'))
cat('OK: .diagnostics_flextable produces a flextable\n')

# 6) Density plots
set.seed(1)
samples <- data.frame(EF = rnorm(1000, 100, 10), N = rnorm(1000, 5e6, 5e5),
                      Cfi = rnorm(1000, 0.4, 0.05))
p <- .gg_input_densities(samples)
stopifnot(inherits(p, 'ggplot'))
cat('OK: .gg_input_densities produces a ggplot\n')

# 7) Aggregated results
mc_results <- list(by_system = list(
  'dairy||intensive||cows'    = list(results = data.frame(total_ch4 = rnorm(200, 80, 5), total_n2o = rnorm(200, 1, 0.1), total_co2e = rnorm(200, 2500, 200))),
  'dairy||intensive||heifers' = list(results = data.frame(total_ch4 = rnorm(200, 30, 3), total_n2o = rnorm(200, 0.5, 0.05), total_co2e = rnorm(200, 900, 80))),
  'beef||extensive||cows'     = list(results = data.frame(total_ch4 = rnorm(200, 50, 5), total_n2o = rnorm(200, 0.8, 0.1), total_co2e = rnorm(200, 1600, 200)))
))
agg <- .aggregated_results_flextable(mc_results)
stopifnot(is.list(agg))
stopifnot(inherits(agg[['cattle_type']], 'flextable'))
stopifnot(inherits(agg[['aggregation_level']], 'flextable'))
stopifnot(inherits(agg[['sub_category']], 'flextable'))
cat('OK: .aggregated_results_flextable returns all 3 levels\n')

# 8) Inputs doc flextable
param_specs <- data.frame(cattle_type='dairy', aggregation_level='intensive',
                          sub_category='cows', parameter='EF',
                          param_type='coefficient', mean=120, uncertainty_pct=15,
                          lower=100, upper=140, distribution='normal',
                          data_source='IPCC', ipcc_ref='Tab10.10')
ft <- .inputs_doc_flextable(param_specs)
stopifnot(inherits(ft, 'flextable'))
cat('OK: .inputs_doc_flextable produces a flextable\n')

# 9) YoY chart
trend_results <- data.frame(Year = 2018:2022, Mean_t_CO2eq = c(1000,1050,1100,1080,1130),
                            CI_Lower_t = c(800,840,890,860,910),
                            CI_Upper_t = c(1200,1260,1310,1300,1350),
                            CV_pct = c(10,10,10,10,10), MoE_95_pct = c(20,20,20,20,20),
                            Delta_vs_base_pct = c(0,5,10,8,13),
                            YoY_pct = c(NA, 5, 4.8, -1.8, 4.6))
p <- .gg_yoy_chart(trend_results)
stopifnot(inherits(p, 'ggplot'))
cat('OK: .gg_yoy_chart produces a ggplot\n')

# 10) Delta distribution
dt <- list(per_iter = rnorm(2000, 100, 50), mean = 100, ci = c(20, 180), pct_mean = 10, pct_ci = c(2, 18))
p <- .gg_delta_distribution(dt)
stopifnot(inherits(p, 'ggplot'))
cat('OK: .gg_delta_distribution produces a ggplot\n')

# 11) Full sensitivity table (top_n = Inf)
sens <- list(
  src  = data.frame(parameter = paste0('p', 1:25), src  = rnorm(25), abs_src  = abs(rnorm(25)), p_value = runif(25), rank = 1:25),
  prcc = data.frame(parameter = paste0('p', 1:25), prcc = rnorm(25), abs_prcc = abs(rnorm(25)), rank = 1:25)
)
ft_top <- .sensitivity_flextable(sens, top_n = 10)
ft_all <- .sensitivity_flextable(sens, top_n = Inf)
stopifnot(inherits(ft_top, 'flextable'))
stopifnot(inherits(ft_all, 'flextable'))
stopifnot(nrow(ft_all$body$dataset) == 25)
stopifnot(nrow(ft_top$body$dataset) == 10)
cat('OK: .sensitivity_flextable honours top_n (25 vs 10 rows)\n')

# 12) End-to-end: actually render a Word file with synthetic inputs
tmp <- tempfile(fileext = '.docx')

# Synthesise uncertainty frame mirroring calc_all_uncertainty() output shape
set.seed(7)
n <- 2000
co2e <- rnorm(n, 5000, 500)
inventory <- data.frame(
  enteric_ch4_total       = rnorm(n, 100, 10),
  manure_ch4_total        = rnorm(n,  30,  4),
  direct_n2o_mm_total     = rnorm(n, 0.5, 0.05),
  indirect_n2o_mm_total   = rnorm(n, 0.2, 0.02),
  direct_n2o_prp_total    = rnorm(n, 0.7, 0.08),
  indirect_n2o_prp_total  = rnorm(n, 0.3, 0.03),
  total_ch4               = rnorm(n, 130, 12),
  total_n2o               = rnorm(n, 1.7, 0.18),
  total_co2e              = co2e
)
.row <- function(v) {
  x <- inventory[[v]]
  m <- mean(x); s <- sd(x)
  lo <- quantile(x, 0.025, names = FALSE); hi <- quantile(x, 0.975, names = FALSE)
  data.frame(variable = v, mean = m, ci_lower = lo, ci_upper = hi,
             cv_pct = s / m * 100, moe_pct = ((hi - lo) / 2) / m * 100)
}
uncertainty <- do.call(rbind, lapply(names(inventory), .row))

decomp2 <- list(combined = uncertainty,
                ad_only  = uncertainty, ef_only = uncertainty)

sensitivity <- list(
  src  = data.frame(parameter = paste0('dairy | cows - p', 1:25),
                    src = rnorm(25), abs_src = abs(rnorm(25)),
                    p_value = runif(25), rank = 1:25),
  prcc = data.frame(parameter = paste0('dairy | cows - p', 1:25),
                    prcc = rnorm(25), abs_prcc = abs(rnorm(25)), rank = 1:25)
)

settings <- list(n_iter = 2000, corr_mode = 'within', ef_corr_mode = 'none',
                 run_comparison = TRUE, gwp_version = 'AR5', seed = 42,
                 analysis_mode = 'single-year',
                 emission_sources = c('enteric_ch4','manure_ch4','manure_n2o_direct'))

mc_results2 <- list(inventory = inventory,
                    by_system = list(
                      'dairy||intensive||cows' = list(samples = samples,
                                                      results = inventory)
                    ))

build_run_summary_docx(
  path                  = tmp,
  settings              = settings,
  param_specs           = param_specs,
  mc_results            = mc_results2,
  uncertainty           = uncertainty,
  sensitivity           = sensitivity,
  ipcc_table            = NULL,
  ipcc_meta             = list(ipcc_version = 'IPCC 2019 Refinement', region = 'East Africa'),
  decomposition         = decomp2,
  comparison_uncertainty = uncertainty,
  diagnostics           = diagnostics,
  samples_for_density   = samples
)
stopifnot(file.exists(tmp))
finfo <- file.info(tmp)
cat(sprintf('OK: single-year .docx built (%d bytes)\n', finfo$size))

# 13) Trend doc end-to-end
tmp2 <- tempfile(fileext = '.docx')
slope <- list(mean = 25, ci = c(5, 45))
delta_total <- list(mean = 130, ci = c(20, 240), pct_mean = 13, pct_ci = c(2, 24),
                    per_iter = rnorm(2000, 130, 50))
sens_py <- sensitivity
sens_dl <- sensitivity

build_trend_summary_docx(
  path                 = tmp2,
  trend_results        = trend_results,
  slope                = slope,
  delta_total          = delta_total,
  sensitivity_per_year = sens_py,
  sensitivity_delta    = sens_dl,
  year_corr            = 'full',
  years                = 2018:2022,
  n_iter               = 2000,
  ipcc_meta            = list(ipcc_version = 'IPCC 2019 Refinement', region = 'East Africa'),
  param_specs          = param_specs
)
stopifnot(file.exists(tmp2))
cat(sprintf('OK: trend .docx built (%d bytes)\n', file.info(tmp2)$size))

cat('\nALL TESTS PASSED.\n')
