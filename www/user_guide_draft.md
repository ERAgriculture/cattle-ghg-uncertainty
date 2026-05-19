# IPCC Tier 2 Livestock GHG Uncertainty Calculator — User Guide

_Draft v0.1 — 2026-05-19 — for review by A. Wilkes_

---

## 1. Overview

### 1.1 What this tool does

National GHG inventories based on IPCC Tier 2 methods require not only a central estimate of emissions but also a quantification of their uncertainty. This tool automates that process for livestock (cattle) using Monte Carlo simulation:

1. You supply your country-specific Tier 2 activity data and emission-factor inputs, each with an uncertainty range.
2. The tool randomly samples from the uncertainty distributions you have defined (thousands of times) and propagates those samples through the full IPCC Tier 2 equation chain (Eq. 10.1–10.34).
3. It reports the resulting 95% confidence interval around your emission estimate, identifies which parameters drive the most uncertainty (sensitivity analysis), and formats the results for submission in the format of IPCC 2006 Vol. 1 Ch. 3 Table 3.3.

The approach follows IPCC Approach 2 (Monte Carlo) as described in IPCC 2006 Vol. 1 Ch. 3.

### 1.2 Who this tool is for

This tool is designed for national inventory practitioners who:

- Are already conducting or have recently completed a Tier 2 cattle GHG inventory (enteric fermentation, manure management, direct and indirect N₂O from pasture deposition)
- Have at least rough estimates of the uncertainty in their key activity data and emission factors
- Need to report the uncertainty range for inclusion in national inventory reports

The tool assumes basic familiarity with IPCC Tier 2 methodology. Users do not need prior experience with Monte Carlo methods, but a conceptual understanding of probability distributions is helpful.

### 1.3 Emission sources covered

The tool covers:

| IPCC Category | Source |
|---|---|
| 3.A.1 | Enteric fermentation — cattle (CH₄) |
| 3.A.2 | Manure management — cattle (CH₄) |
| 3.A.2 | Manure management — cattle (N₂O direct) |
| 3.A.2 | Manure management — cattle (N₂O indirect) |
| 3.C.4 | Direct N₂O from pasture/range/paddock deposition |
| 3.C.5 | Indirect N₂O from pasture/range/paddock deposition |

---

## 2. Preparing your data

### 2.1 What you need before you start

Before opening the tool, assemble the following:

1. **Activity data**: For each animal sub-category, the population (N), body weight (BW), weight gain (WG), milk yield (for dairy), milk fat %, digestible energy (DE%), manure management system (MMS) fractions, and other Tier 2 inputs.

2. **Uncertainty ranges**: For each parameter, an estimate of its uncertainty — typically either:
   - A percentage uncertainty (e.g. ±20% representing the half-width of a 95% confidence interval), or
   - Explicit lower and upper bounds

3. **Manure management fractions** (if running manure N₂O): The percentage of manure allocated to each management system (pasture, solid storage, liquid, etc.).

If you do not yet have uncertainty estimates, see Section 2.4 for guidance on obtaining them.

### 2.2 Understanding the input structure

The tool uses an Excel template with a specific structure. Download the template from the **Data Input** tab (Tab 1) by clicking "Download Excel template".

The template has the following key columns in the **Parameters** sheet:

| Column | Description | Example |
|---|---|---|
| `cattle_type` | Broad cattle category | `dairy`, `non_dairy` |
| `aggregation_level` | Production system or region name | `Highland smallholder dairy` |
| `sub_category` | Animal sub-group | `cows`, `heifers`, `calves_female` |
| `parameter` | Parameter code (see Definitions tab) | `N`, `BW`, `Ym`, `DE`, `Bo` |
| `mean` | Central estimate (point value from your inventory) | `450` (for BW in kg) |
| `distribution` | Uncertainty distribution shape | `normal`, `triangular`, `pert`, `uniform`, `lognormal` |
| `uncertainty_pct` | Symmetric ±% half-width of 95% CI | `20` |
| `lower` | Lower bound (alternative to uncertainty_pct) | `360` |
| `upper` | Upper bound | `540` |
| `param_type` | IPCC framing | `activity_data` or `coefficient` |
| `unit` | Unit of measurement | `kg`, `%`, `t CH4/t VS` |

**Important:** Each row is one parameter for one sub-category. A country with two production systems (e.g. highland dairy and lowland pastoral) and five sub-categories each would have approximately 12–15 parameters × 10 sub-categories = 100–150 rows.

### 2.3 Defining sub-categories

Sub-categories should match your national inventory. Typical sub-categories include:

- Dairy: `cows` (lactating), `dry_cows`, `heifers`, `calves`, `bulls`
- Non-dairy beef: `breeding_cows`, `growing_males`, `heifers`, `calves`, `oxen`

Each sub-category needs its own rows for all relevant parameters. The values of `cattle_type`, `aggregation_level`, and `sub_category` together identify each group uniquely — they must be spelled consistently across all rows for the same group.

### 2.4 Obtaining uncertainty estimates

Uncertainty estimates can be derived from several sources:

**For activity data (N, BW, milk yields):**
- **Survey-based estimates**: If populations are estimated from livestock surveys, the survey sampling error provides a direct estimate of uncertainty. The 95% confidence interval from a survey translates directly to the `lower` and `upper` bounds (or to `uncertainty_pct` if symmetric).
- **Expert elicitation**: Ask the data provider to give a range within which they are 95% confident the true value falls.
- **IPCC defaults**: IPCC 2019 Refinement Chapter 11 provides uncertainty ranges for key emission factors (EF3, EF4, EF5, and Frac parameters). Use these as the starting point if no country-specific data is available.

**For emission factors and coefficients (Ym, Bo, DE, MCF, etc.):**
- **Literature review**: If you used a country-specific value from a published study, the study's reported confidence interval or standard deviation can be used.
- **IPCC default uncertainty ranges**: IPCC 2019 Refinement provides ±% ranges for key EFs. These are reflected in the pre-filled columns in the template.
- **Expert elicitation**: Ask the expert who provided the value to estimate the plausible range.

If you genuinely have no information about a parameter's uncertainty, a reasonable default for emission factors is ±20–40% (representing expert uncertainty about a value that has not been directly measured in-country). For population data with census-based estimates, ±5–15% is typical.

### 2.5 Choosing a distribution

The tool offers five distribution shapes:

| Distribution | Shape | Best for |
|---|---|---|
| **Normal** | Symmetric bell curve | Activity data (N, BW) where the mean is well-known and errors are random |
| **PERT** | Smooth bounded curve | Emission factors where you have a min, mode, and max (preferred for skewed EFs) |
| **Triangular** | Peaked triangle | Situations with a clear most-likely value and known hard limits |
| **Uniform** | Flat (equal probability) | When all values in a range are equally likely; very conservative |
| **Lognormal** | Right-skewed | Strictly positive values where uncertainty is proportionally larger at lower values (e.g. Bo, CH₄ yields) |

**Recommended defaults:**
- Use **Normal** for population (N) and body weight (BW) — these are typically measured with roughly symmetric errors
- Use **PERT or Lognormal** for emission factors (Ym, Bo, MCF, EF3–EF5, Frac parameters) — these are bounded below at zero and often have right-skewed uncertainty
- Use **Uniform** as a conservative fallback when you only know the plausible range

---

## 3. Loading your data (Tab 1 — Data Input)

### 3.1 Using the example datasets

Two built-in example datasets are included to let you explore the tool without uploading your own data:

- **Country X (hypothetical dairy)**: A fictional East African highland dairy system — 12 parameters, dairy/cows, including a synthetic 5-year time series.
- **Country Y (hypothetical pastoral)**: A fictional semi-arid pastoral beef system — 11 parameters, non-dairy/breeding cows, including a synthetic 5-year time series.

Select either from the "Country / Example Data" dropdown. The tool loads the data immediately and you can proceed directly to Tab 2.

### 3.2 Uploading your own data

1. Click "Download Excel template" to get the template
2. Fill in the Parameters sheet following the structure in Section 2.2
3. Fill in the Manure_Management sheet if you are running manure N₂O sources
4. (Optional) Fill in the Parameter_TimeSeries sheet if you want correlations computed automatically from historical data
5. Save the file and upload it using the file picker

After a successful upload, a green notification confirms how many parameters were loaded. Any upload warnings (missing columns, unrecognised values) appear as amber notifications.

**Common upload issues:**
- `cattle_type` must be `dairy` or `non_dairy` (lowercase, no spaces)
- Distribution names must match exactly: `normal`, `pert`, `triangular`, `uniform`, `lognormal`
- If `uncertainty_pct` is left blank, both `lower` and `upper` must be filled
- `param_type` must be `activity_data` or `coefficient`

---

## 4. Reviewing data quality (Tab 2 — QA/QC)

### 4.1 What the QA/QC checks do

The QA/QC tab runs automated checks on your parameter values and flags any that are potentially problematic. Four statuses are possible:

| Status | Colour | Meaning |
|---|---|---|
| **Pass** | Green | Value is within the expected range for this parameter |
| **Warn** | Amber | Value deviates noticeably from the typical range — check and document |
| **Fail** | Red | Value is outside the plausible range — likely a data entry error |
| **Info** | Blue | Value differs from an older benchmark source; check against IPCC 2019 where available |
| **Missing** | Purple/grey | A required parameter was not found in your upload |

### 4.2 What to do for each status

**Pass**: No action needed. The value is consistent with IPCC default ranges.

**Warn**: Review the flagged parameter. A Warn means your value is unusual but not impossible. Possible actions:
- Confirm the value is correct for your country context
- If it is country-specific and well-justified, document it in your inventory report
- If it is an error, correct it in your Excel file and re-upload

**Fail**: These represent likely data entry errors (e.g. a live weight of 50,000 kg, a DE% of 150%). Correct the value before proceeding.

**Info**: These flags cite older benchmark sources (Penman 2000, Monni 2007) that may be less relevant than IPCC 2019 Refinement values. For parameters like EF3, EF4, EF5, and Frac values, check the IPCC 2019 Refinement Chapter 11 Table 11.1 for the current recommended range. If your value falls within the 2019 range, the Info flag can be disregarded for reporting purposes.

**Missing**: If a parameter is flagged as missing, the tool has filled it in with an IPCC default value (shown in the notification). You should review whether the default is appropriate for your country context and, if possible, supply a country-specific value.

### 4.3 Documenting deviations

For any Warn or Info flags where you are deliberately using a country-specific value that deviates from the default, document the justification in your national inventory report. IPCC expert reviewers will look for this documentation.

---

## 5. Reviewing uncertainty distributions (Tab 3 — Uncertainty)

### 5.1 The parameter table

Tab 3 shows all parameters loaded from your data as an editable table. Each row shows:
- The parameter name, unit, and current mean value
- The distribution type currently assigned
- The uncertainty_pct or lower/upper bounds
- A visual preview of the distribution shape

You can edit values directly in the table. Clicking a cell opens an edit field.

### 5.2 Quick-set buttons

Two quick-set buttons are available for rapid exploration:
- **Set all activity data to Normal ±15%**: Sets N, BW, and other activity data parameters to a Normal distribution with ±15% uncertainty. Click again to undo.
- **Set all coefficients to PERT**: Sets emission factors and other coefficients to PERT distribution. Click again to undo.

These are useful for a first exploratory run. Refine individual parameters before your final analysis.

---

## 6. Correlations (Tab 4 — Correlations)

### 6.1 Why correlations matter

If multiple parameters tend to move together (e.g. larger animals also tend to produce more milk), ignoring this relationship underestimates the uncertainty in the total emission estimate. The Correlations tab allows you to specify these relationships.

For most Tier 2 analyses, ignoring correlations (the default "No correlations" setting) is a reasonable simplifying assumption that errs on the side of caution (slightly underestimates total uncertainty). IPCC Approach 2 guidance recommends including known correlations where they exist.

### 6.2 Automatic correlations from time-series data

If you included a Parameter_TimeSeries sheet in your upload (or used one of the built-in example datasets), the tool can compute historical correlations automatically:

1. On Tab 4, select "From template (auto)" under Activity Data Correlations
2. The tool fits a Gaussian copula to the historical parameter data and uses the resulting correlation matrix for sampling
3. The matrix is displayed for your review — inspect it to confirm correlations are plausible

### 6.3 Manual correlation matrix

If you prefer to specify correlations manually:
1. Select "Manual (upload CSV)" under Activity Data Correlations
2. Upload a square, symmetric CSV matrix of correlation coefficients (−1 to +1, diagonal = 1)
3. The tool verifies positive-definiteness and adjusts the matrix if needed

### 6.4 IPCC-guidance preset

A built-in preset based on IPCC guidance on correlated emission factors is available under the Emission Factor Correlations section. This assumes a moderate positive correlation between emission factors of the same type (e.g. Ym and DE% tend to co-vary). It is applied as a uniform correlation (single ρ value).

---

## 7. Running the simulation (Tab 5 — Simulate)

### 7.1 Settings

Before clicking Run, configure:

**Number of iterations**: The number of Monte Carlo samples. Recommendations:
- **1,000**: Quick test run to check the model runs correctly. Do not use for reporting.
- **10,000**: Minimum for final reporting purposes. Tail percentiles (2.5th/97.5th) are reliable.
- **25,000–30,000**: Recommended for final reporting, especially when correlations are enabled or you have many sub-categories.

**GWP version**: Choose between AR5 (CH₄ GWP = 28, N₂O = 265) and AR6 (CH₄ GWP = 27.9, N₂O = 273). Select the version required by your national inventory reporting guidelines.

**Random seed**: Fixing the seed ensures results are exactly reproducible — anyone using the same data, settings, and seed will get the same numbers. Change the seed to verify convergence: if the 95% CI changes substantially between runs, increase the number of iterations.

**Analysis mode**: Single-year (most common) or Trend (multi-year time series).

**Emission sources**: Tick all sources applicable to your inventory. Unticked sources contribute zero emissions to the total.

### 7.2 Running the simulation

Click "Run Monte Carlo Simulation". A progress bar shows the simulation steps. For 10,000 iterations and a single production system, typical run time is 15–60 seconds depending on server load.

When complete, results appear in the lower section of the same tab.

### 7.3 Convergence diagnostics

Click "Run Diagnostic" (magnifying glass button) after a simulation to assess whether enough iterations were run for stable results. The diagnostics include:

- **Iterations used**: The number confirmed for this run (shown in amber if below 10,000)
- **MCSE%** (Monte Carlo Standard Error %): Measures whether more iterations would change the mean. Pass = <0.5%, Warn = 0.5–1%, Fail ≥1%
- **Mean drift %**: How much the mean from the first half of iterations differs from the second half. Pass = <2%
- **CI drift %**: How much the 95% CI bounds shift between the two halves. Pass = <5%
- **Skewness**: Indicates whether the output distribution is strongly non-symmetric (expected for livestock emissions)
- **Convergence trace**: Running mean and 95% CI plotted against iteration count — should stabilise before the end of the run

Note: this tool uses **independent Monte Carlo**, not MCMC. Each iteration is drawn independently, so there are no chains, no warmup, and no burn-in. The diagnostics above assess stability of the independent sample, not chain convergence.

---

## 8. Understanding results (Tab 5 — Results)

### 8.1 Headline metrics

After a successful run, five value boxes show:

- **Total CO₂eq (t)**: The mean of the simulated total emission estimate, in tonnes CO₂-equivalent
- **Enteric CH₄ (t)**: Mean enteric fermentation contribution
- **Manure CH₄ (t)**: Mean manure management CH₄ contribution
- **Pasture N₂O (t)**: Mean combined direct and indirect N₂O from pasture deposition
- **Total CV (%)**: Coefficient of variation = SD / mean × 100. This is a descriptive statistic; the IPCC reporting metric is the % uncertainty (MoE%) in the IPCC Report tab

Below the value boxes, a footnote shows the 95% CI (2.5th–97.5th percentile range) and the margin of error (MoE%) for the total emission estimate.

### 8.2 Uncertainty decomposition (AD vs EF)

If "Run uncertainty decomposition (AD/EF/Combined)" was checked before running, the results include a breakdown of uncertainty by source:

- **AD uncertainty**: Uncertainty driven by activity data only (population N, with all emission factors fixed at their means)
- **EF uncertainty**: Uncertainty driven by emission factors and coefficients only (with activity data fixed at means)
- **Combined uncertainty**: Both sources varying together

This decomposition is useful for prioritising which type of data collection would most reduce overall uncertainty. If AD uncertainty dominates, improving livestock population surveys would be most effective. If EF uncertainty dominates, investing in country-specific EF measurement studies would help more.

### 8.3 By-system and by-category breakdown

The results tables show:
- **By-system breakdown**: The mean, 95% CI, MoE%, and CV% for each production system and emission source
- **By reporting category (IPCC Table 3.3 layout)**: Same information grouped by IPCC source category (3.A.1, 3.A.2, 3.C.4, 3.C.5)

---

## 9. Sensitivity analysis (Tab 6)

### 9.1 Reading the tornado chart

The tornado chart ranks parameters by their contribution to total uncertainty. The longest bars indicate the parameters that, if better constrained, would most reduce the 95% CI on total emissions.

Each bar is labelled with:
- **Cattle type and sub-category**: e.g. `dairy | cows`
- **Parameter name**: e.g. `Ym` (methane conversion factor), `N` (population), `BW` (body weight)

This labelling allows you to identify not just _which parameter_ is most sensitive, but _for which animal group_ — critical information for directing future data collection efforts.

Bars are coloured by reducibility:
- **Green**: The uncertainty on this parameter can be reduced with better local data (e.g. country-specific surveys or measurement studies)
- **Grey**: The parameter's uncertainty is largely irreducible with national-level data (e.g. fundamental biochemical constants)

### 9.2 SRC vs PRCC

Two sensitivity methods are computed:
- **SRC (Standardised Regression Coefficient)**: Linear sensitivity. Reliable when relationships between parameters and outputs are approximately linear.
- **PRCC (Partial Rank Correlation Coefficient)**: Rank-based, captures non-linear relationships. More robust but less interpretable.

Both are shown; they typically agree on the top-ranked parameters. If they disagree significantly, the emission pathway may be strongly non-linear.

---

## 10. Generating the IPCC report (Tab 7 — IPCC Report)

### 10.1 IPCC Table 3.3

The IPCC Report tab shows your results formatted as IPCC 2006 Vol. 1 Ch. 3 Table 3.3. Each row is one IPCC inventory reporting line. The three uncertainty columns show:

- **AD uncertainty (%)**: % uncertainty (MoE%) from activity data alone
- **EF uncertainty (%)**: % uncertainty (MoE%) from emission factors alone
- **Combined uncertainty (%)**: Overall % uncertainty (MoE%)

**Definition of % uncertainty**: Following IPCC Table 3.3 conventions, all values are expressed as the half-width of the 95% confidence interval divided by the mean, multiplied by 100. This is the standard IPCC "percentage uncertainty" metric.

_Example: a Combined uncertainty of 35% means the 95% CI is approximately ±35% of the mean emission estimate._

### 10.2 Downloads

Three download formats are available:
- **Excel report (.xlsx)**: Full workbook with run settings, IPCC summary table, uncertainty metrics, and sensitivity results (SRC and PRCC)
- **CSV report**: The IPCC Table 3.3 formatted table only, for easy import into inventory reporting software
- **Word report**: Narrative summary suitable for inclusion in the uncertainty section of your national inventory report

---

## 11. IPCC reporting conventions

### 11.1 Where uncertainty results go in the national inventory report

IPCC 2006 Vol. 1 Ch. 3 §3.3 describes the standard approach to presenting uncertainty in national inventory reports. For Approach 2 (Monte Carlo):

1. Report the 95% confidence interval for each major source category and for the national total
2. Present the results in Table 3.3 format (included in the IPCC Report tab downloads)
3. Describe the Monte Carlo approach used (number of iterations, distributions chosen, correlation assumptions)
4. Document any parameters where country-specific values were used instead of IPCC defaults, including the justification

The methodology PDF (available on the Resources tab) provides a complete technical description of the equations, sampling approach, and convergence assessment that can be referenced in your national inventory report.

### 11.2 What IPCC expert reviewers will check

Based on experience with IPCC expert reviews, reviewers typically focus on:
- Whether the uncertainty metric reported is the correct one (% uncertainty = MoE%, not CV%)
- Whether the IPCC Table 3.3 format and column conventions are followed
- Whether Approach 2 (Monte Carlo) is described sufficiently to be reproducible
- Whether the number of iterations is sufficient for stable results
- Whether the CV% IPCC annex table reference (if cited) is correct
- The basis for any country-specific emission factor values that deviate substantially from IPCC defaults

---

## Appendix A: Parameter reference

Key parameter codes used in the tool:

| Code | Full name | Unit | IPCC equation |
|---|---|---|---|
| N | Animal population | head | Eq. 10.1 |
| BW | Body weight | kg | Eq. 10.3 |
| WG | Daily weight gain | kg/day | Eq. 10.3 |
| Milk | Milk production per lactating animal | kg/day | Eq. 10.4 |
| Fat | Milk fat content | % | Eq. 10.4 |
| DE | Digestible energy | % GE | Eq. 10.2 |
| Ym | Methane conversion factor | % GE | Eq. 10.21 |
| Cfi | Net energy for body maintenance coefficient | — | Eq. 10.3 |
| Ca | Net energy for activity coefficient | — | Eq. 10.3 |
| Cp | Net energy for pregnancy coefficient | — | Eq. 10.3 |
| Bo | Maximum CH₄ producing capacity | m³ CH₄/kg VS | Eq. 10.23 |
| MCF | Methane conversion factor (manure system) | % | Eq. 10.23 |
| Frac_GASF | Fraction of nitrogen volatilised as NH₃ / NOₓ (manure storage) | fraction | Eq. 10.28 |
| Frac_LEACH | Fraction of nitrogen lost to leaching/runoff (manure storage) | fraction | Eq. 10.28 |
| EF3 | N₂O emission factor (manure management) | kg N₂O-N/kg N | Eq. 10.26 |
| EF3_S | N₂O emission factor (solid storage) | kg N₂O-N/kg N | Eq. 10.26 |
| EF4 | N₂O indirect emission factor (atmospheric deposition) | kg N₂O-N/kg N | Eq. 10.30 |
| EF5 | N₂O indirect emission factor (leaching/runoff) | kg N₂O-N/kg N | Eq. 10.31 |
| Frac_GASM | Fraction of TAN volatilised (manure storage) | fraction | Eq. 10.28 |
| Frac_LEACH_H | Fraction of TAN leached (manure storage) | fraction | Eq. 10.29 |
| Tw | Watering point visit frequency (for indirect N₂O, Africa) | visits/day | IPCC regional |

For a complete parameter list with IPCC references, see the **Definitions** tab in the tool.

---

## Appendix B: Worked example — Country X (hypothetical dairy)

To illustrate the workflow, the following example uses the Country X built-in dataset.

**Step 1 — Load data**: Select "Country X (hypothetical dairy)" from the dropdown on Tab 1. The data loads automatically (12 parameters, dairy smallholder system).

**Step 2 — QA/QC**: Go to Tab 2. All parameters should pass or show only Info flags. The Info flags for EF3/EF4/EF5 cite older benchmark sources; for this hypothetical example, the values match IPCC 2019 defaults.

**Step 3 — Uncertainty**: Go to Tab 3. Note that activity data (N, BW, Milk, WG, Fat) use Normal distributions and coefficients (Ym, DE, Bo, etc.) use PERT or lognormal distributions.

**Step 4 — Correlations**: Go to Tab 4. Select "From template (auto)" — the example dataset includes a 5-year time series from which a correlation matrix is computed automatically.

**Step 5 — Simulate**: Go to Tab 5. Set iterations to 10,000, GWP to AR6, seed to 42. Click "Run Monte Carlo Simulation".

**Step 6 — Results**: After ~30 seconds, the results appear. Note the 95% CI and MoE%. Click "Run Diagnostic" to confirm convergence.

**Step 7 — Sensitivity**: Go to Tab 6. The tornado chart shows which parameters drive most uncertainty. In this example, Ym and BW for cows are typically the dominant contributors.

**Step 8 — Report**: Go to Tab 7. Download the Excel report to see the full IPCC Table 3.3 output.

---

_For questions, contact Lolita Muller (Alliance Bioversity-CIAT) or Andreas Wilkes._
_This document is a draft for internal review. Do not distribute externally._
