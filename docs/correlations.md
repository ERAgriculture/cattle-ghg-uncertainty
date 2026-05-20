# Correlation Handling in the IPCC Tier 2 Uncertainty Calculator

> **Changelog (May 2026 audit re-review):** Structural-defaults preset values revisited as an IPCC reviewer. **DE ↔ Ym strengthened from −0.40 to −0.50** (matches IPCC 2019 Refinement Eq 10.21 and Niu et al. 2018 / Hristov et al. 2013 meta-analyses). **Cfi ↔ Ca lowered from 0.60 to 0.30** (the original 0.60 estimation-covariance argument does not apply — Cfi and Ca are independent inputs in IPCC Eq 10.3 / 10.4, not jointly estimated). The earlier **N ↔ BW = 0.30** pair was removed (no defensible cross-country source). The resulting preset matrix is positive-definite without nearest-PD repair (smallest eigenvalue 0.06).

## 1. Why correlations matter

When two input parameters tend to move in the same direction — for instance, when cattle populations are high, body weights tend to be lower due to grazing pressure — sampling them independently produces Monte Carlo draws that do not reflect reality. Independent sampling assigns equal probability to a draw where both are at their upper extremes as to a draw where one is high and the other low. If the true relationship is negative, the independent assumption inflates uncertainty. If the relationship is positive, it deflates it.

The tool handles this through a **Gaussian copula**: a method that preserves each parameter's user-specified marginal distribution (normal, PERT, lognormal, etc.) while inducing the desired pairwise rank correlations between parameters.

---

## 2. Parameter classification

All parameters in `param_specs` carry a `param_type` label that determines which correlation block they belong to:

| `param_type` | Parameters | Default correlation treatment |
|---|---|---|
| `activity_data` | N, BW, MW, WG, Milk, Fat, pct_calving, DE, hours, CP, MilkPR | User-specified matrix (upload or manual) or independent |
| `emission_factor` (coefficient) | Cfi, Ca, C, Cp, Ym, Bo, ASH, UE, EF3_PRP, EF3_S, Frac_GASMS, EF4, EF5, Frac_LEACH_H, etc. | Independent (default) or block-structured |

The two blocks can be correlated **within** themselves (the default scope) and **across** each other (via the unified-matrix path used by the structural-defaults preset and any time-series matrix that covers parameters from both blocks). The sampler draws from a single multivariate distribution covering the union of all parameter names whenever cross-block pairs are specified; otherwise the two blocks are sampled in two independent passes for backward compatibility.

---

## 3. The Gaussian copula algorithm

The same algorithm is applied to both blocks. For a block of *n* parameters with correlation matrix **R** and *N* Monte Carlo iterations:

**Step 1 — Multivariate normal draw**

Draw *N* rows from a multivariate standard normal with covariance **R**:

```
Z ~ MVN(0, R),   Z is N × n
```

This is implemented with `MASS::mvrnorm`. Before use, **R** is passed through `Matrix::nearPD(..., corr = TRUE)` to guarantee it is positive definite, correcting for any numerical issues in user-supplied matrices or in the uniform EF matrix construction.

**Step 2 — Probability integral transform**

Convert each column of Z to uniform [0, 1] using the standard normal CDF Φ:

```
U_ij = Φ(Z_ij),   U is N × n,   U_ij ∈ (0, 1)
```

The columns of U are now *uniformly* distributed but retain the rank dependence structure induced by **R**. This is the copula.

**Step 3 — Marginal quantile transform**

For each parameter *j*, transform column *j* of U through the quantile function (inverse CDF) of its specified distribution:

```
X_ij = F_j⁻¹(U_ij)
```

where F_j is the marginal CDF defined by the parameter's `distribution`, `mean`, `lower`, and `upper` values. The result X has exactly the right marginal shape for each parameter and approximately the right Spearman rank correlations between columns.

**Implementation in `mc_sampling.R`:**

```r
.copula_sample <- function(n_iter, params, corr_mat) {
  corr_mat <- as.matrix(Matrix::nearPD(corr_mat, corr = TRUE)$mat)
  z <- MASS::mvrnorm(n_iter, mu = rep(0, nrow(corr_mat)), Sigma = corr_mat)
  u <- pnorm(z)
  for (j in seq_len(nrow(params)))
    samp[, j] <- transform_marginal(u[, j], params$distribution[j],
                                    params$mean[j], params$lower[j], params$upper[j])
}
```

---

## 4. Activity data correlations

### 4.1 What the correlation matrix represents

The activity data correlation matrix **R_AD** is an *n_AD × n_AD* matrix where entry (i, j) is the Spearman rank correlation between parameter *i* and parameter *j*. It must be symmetric and positive definite with diagonal entries = 1.

For the Uganda example (12 rows, all `cattle_type = "dairy"`, one production system), the activity data block has parameters:

```
cattle_pop, live_weight, mature_weight, weight_gain, milk_yield, milk_fat,
pct_lactating, DE_pct, hours, CP_pct, protein_milk
```

so **R_AD** is 11 × 11.

### 4.2 How to specify the matrix

**Option A — Upload time series (recommended)**

Upload a spreadsheet where columns are activity data parameters and rows are years. The tool computes **R_AD** as the **Spearman rank correlation** matrix of the time series, after **detrending** (first differences by default), then applies `nearPD` to guarantee positive-definiteness:

```r
compute_corr_from_population <- function(population, detrend = "first_diff") {
  series  <- switch(detrend, none = numeric_cols,
                            first_diff = diff(numeric_cols),
                            linear     = residuals(lm(y ~ year)))
  cor_mat <- cor(series, use = "complete.obs", method = "spearman")
  as.matrix(Matrix::nearPD(cor_mat, corr = TRUE)$mat)
}
```

Sampling along this path uses **Iman–Conover restricted pairing** (`mc2d::cornode`) — the method explicitly cited by IPCC V1 Ch3 §3.2.3.2. Iman–Conover is distribution-free and reproduces the target Spearman rank correlation exactly, regardless of the marginal shapes (lognormal, PERT, beta).

Detrending matters: most national livestock series share a long-run growth trend, and raw Pearson correlation between two upward-trending series is mechanically high. That trend co-movement is not the year-to-year parameter uncertainty Approach 2 is meant to propagate. First differences (the default) isolate the year-to-year shocks; "linear detrend" removes a fitted linear trend; "raw series" reproduces the legacy behaviour.

Example: if you have national livestock census data for 2005–2022 with columns for cattle headcount, average liveweight, and milk yield, the tool will compute the year-to-year co-movement between these variables directly from the data — after stripping shared growth.

**Option B — Manual entry**

Specify **R_AD** directly. This is intended for advanced users who have estimates of pairwise correlations from expert elicitation or from published studies.

**Option C — No correlations (default)**

**R_AD** = **I** (identity). Each activity data parameter is sampled independently. This is the IPCC Approach 2 default assumption when no time series is available.

### 4.3 Effect on uncertainty

Positive correlations among activity data parameters *increase* total uncertainty. To see why, consider cattle_pop and live_weight with correlation r = +0.6. In any iteration where cattle_pop is sampled high, live_weight is also likely to be sampled high, producing a compounded upward push on enteric CH4 (which scales as cattle_pop × GE, and GE depends on live_weight). Independent sampling misses this co-movement and underestimates the tail of the distribution.

Conversely, negative correlations *reduce* total uncertainty: parameters partially offset each other.

---

## 5. Emission factor correlations

### 5.1 Motivation

By default, emission factors (EFs) are sampled independently. This is the standard IPCC Approach 2 assumption and is appropriate when the uncertainty in each EF arises from different, unrelated measurement studies.

However, if EF uncertainty is driven partly by **systematic bias** in the IPCC equation structure — for example, if the Ym_pct equation (IPCC Table 10.12) systematically overestimates for all sub-categories, or if measurement conditions in developing-country studies consistently differ from the IPCC default assumptions — then multiple EFs will tend to be simultaneously over- or under-estimated. Ignoring this correlation underestimates the EF component of total uncertainty.

### 5.2 The uniform correlation assumption

Because there are 13 emission factors, the full **R_EF** matrix has 78 free off-diagonal entries. Eliciting all 78 pairwise correlations from expert knowledge is impractical. The tool therefore offers a single scalar **ρ** that populates a uniform (equicorrelation) matrix:

```
R_EF(i, j) = ρ    for i ≠ j
R_EF(i, i) = 1
```

This can be written as:

```
R_EF = (1 − ρ) I + ρ 1 1ᵀ
```

where **1** is a column vector of ones. This matrix is positive definite for all ρ in (−1/(n−1), 1), which for n = 13 means ρ > −0.083. For the slider range of ρ ∈ [0, 0.9] this is always satisfied, but `nearPD` is applied regardless as a safety check.

**Implementation in `mc_sampling.R`:**

```r
make_uniform_corr <- function(n, rho) {
  m <- matrix(rho, n, n)
  diag(m) <- 1.0
  as.matrix(Matrix::nearPD(m, corr = TRUE)$mat)
}
```

The matrix is constructed in the server and passed per-system, labelled with the EF parameter names:

```r
mat <- make_uniform_corr(n_ef, rho)
rownames(mat) <- colnames(mat) <- ef_params$parameter
```

### 5.3 Interpreting ρ

| ρ | Interpretation |
|---|---|
| 0.00 | Fully independent EFs — standard IPCC Approach 2 assumption |
| 0.20 | Weak systematic bias — most variation is parameter-specific |
| 0.30 | Moderate systematic bias — recommended starting point if you suspect IPCC equation bias |
| 0.50 | Strong systematic bias — requires documented justification |
| 0.70–0.90 | Very strong — most of the EF variation is a shared signal; implies near-perfect co-movement across all 13 factors |

### 5.4 Numerical example

Suppose Ym_pct is sampled at iteration *k* at its 85th percentile (high end). With ρ = 0.3, each other EF has an expected percentile shift upward:

```
E[rank(EF_j) | rank(Ym_pct) = 0.85] ≈ Φ(ρ · Φ⁻¹(0.85)) = Φ(0.3 × 1.036) ≈ Φ(0.311) ≈ 0.622
```

So the other EFs are nudged to approximately their 62nd percentile, not their 50th. With ρ = 0 they would stay at their 50th percentile on average. With ρ = 0.9 they would be at their 83rd percentile — nearly as extreme as Ym_pct itself.

---

## 6. How correlations interact with uncertainty decomposition

The tool decomposes total uncertainty into three components: **AD-only**, **EF-only**, and **Combined**. This is done by running three separate simulations:

| Run | Activity data | Emission factors | Correlations used |
|---|---|---|---|
| Combined | Vary (full distributions) | Vary (full distributions) | **R_AD** + **R_EF** |
| AD-only | Vary (full distributions) | Fixed at mean (constant) | **R_AD** only; **R_EF** irrelevant (NULL) |
| EF-only | Fixed at mean (constant) | Vary (full distributions) | **R_EF** only; **R_AD** irrelevant (NULL) |

From `mc_uncertainty.R`:

```r
# Combined — both correlation matrices applied
combined <- run_mc_simulation(param_specs, corr_matrix, ..., ef_corr_matrix = ef_corr_matrix)

# AD only — EFs are constant, so ef_corr_matrix has no effect (passed as NULL)
ad_only  <- run_mc_simulation(ad_specs,   corr_matrix, ..., ef_corr_matrix = NULL)

# EF only — AD is constant, so corr_matrix has no effect (passed as NULL for clarity)
ef_only  <- run_mc_simulation(ef_specs,   NULL,        ..., ef_corr_matrix = ef_corr_matrix)
```

The Combined CV will generally be less than the sum of AD-only and EF-only CVs because the two blocks are sampled independently of each other (there is no cross-block correlation). However, within each block, positive correlations increase the variance of that block's contribution.

---

## 7. Practical guidance

**When to use activity data correlations:**

Use them whenever you have multi-year national livestock census data. Upload the time series and let the tool compute the matrix. If you do not have time series data, leave this at "No correlations" — the resulting uncertainty estimate will be conservative (possibly underestimated) but defensible.

**When to use EF correlations:**

EF correlations are **optional and off by default**. Most users should leave the setting at "No EF correlations", which is the standard IPCC Approach 2 assumption. No ρ value is required.

Activate the uniform EF correlation option only if you want to run a sensitivity test or if you have a specific reason to believe that systematic bias is present (e.g., the IPCC equation structure consistently over- or under-estimates for your production system type). The recommended workflow is:

1. Run the simulation with "No EF correlations" → record the EF-only CV.
2. Switch to "Uniform EF correlation" with ρ = 0.3 → re-run → record the new EF-only CV.
3. The difference between the two EF-only CVs is the sensitivity of your result to the EF correlation assumption. If the difference is small, the assumption is immaterial and you can report results without it. If it is large, document the ρ value used and justify the choice.

Always report the ρ value used.

**What not to do:**

Do not set ρ close to 1 without a specific justification. A value of ρ = 0.9 implies that knowing Ym_pct is high tells you almost nothing new about EF4 or Frac_LEACH — they are all essentially the same signal. This is rarely defensible for parameters that are measured independently.

---

## 8. Summary of the call chain

```
app_server.R
  │
  ├── rv$corr_matrix       ← computed from time series or set manually
  ├── rv$ef_corr_matrix    ← make_uniform_corr(n_ef, rho) or NULL
  │
  └── run_inventory_simulation(systems_data)
        │
        └── run_mc_simulation(param_specs, corr_matrix, ..., ef_corr_matrix)
              │
              └── generate_mc_samples(param_specs, corr_matrix, n_iter, seed, ef_corr_matrix)
                    │
                    ├── .copula_sample(n_iter, ad_params, corr_matrix)     [if R_AD provided]
                    │     └── MASS::mvrnorm → pnorm → transform_marginal
                    │
                    └── .copula_sample(n_iter, ef_params, ef_corr_matrix)  [if R_EF provided]
                          └── MASS::mvrnorm → pnorm → transform_marginal
```
