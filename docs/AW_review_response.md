# Response to Andreas Wilkes review — Cattle GHG Uncertainty Calculator

**App version reviewed:** v2.1
**Review date:** 1 May 2026
**Reviewer:** Andreas Wilkes (domain expert, IPCC inventories)
**Source materials:** `AW comments on UNC tool 1_5_26.pdf` + meeting transcript with Peter Steward and Lolita Muller

---

## 1. Executive summary

Andreas reviewed v2.1 of the Cattle GHG Uncertainty Calculator and produced ~30 comments organised by tab, plus three additional design points raised in a follow-up meeting. This document walks through every one with a recommended action and a phase assignment.

**Headline numbers**

| Category | Count |
|---|---|
| Confirmed bugs | 11 |
| Feature gaps | 14 |
| Strategic divergences (need decision) | 4 — **all 4 adopted with recommended option** |
| UX / cosmetic items | 6 |
| Already works as expected | 3 |
| Cross-references only | 2 |
| **Total items** | **40** |

**Phase 1 status (v2.2 implementation, May 2026)**

| | Count | Status |
|---|---|---|
| Phase 1 items shipped in this update | 19 | ✅ Done |
| Phase 1 items deferred (TT.8 Excel-level QC) | 1 | ⏳ Phase 2 |
| Phase 2 items | 12 | ⏳ Pending divergence-driven work |
| Phase 3 items | 8 | ⏳ Future |

**Headline message**

The single most important issue is **T1.1 — custom upload not working**. Andreas reports that uploading a custom Excel template does nothing — the on-screen table keeps showing the Uganda example. This blocks all real-world testing of the app and must be the first thing fixed. A diagnostic walkthrough is included in section 3 of this document.

The second most important issue is **terminological**. The app currently calls 15 parameters "Activity Data" and 9 "Emission Factor", whereas the IPCC convention is AD = population only, EF = emissions per head per year. Adopting the IPCC convention is recommended (see Divergence #2) but it is XL-effort because the decomposition logic, the chart labels, and the Excel template all need to change.

**Recommended phasing**

- **Phase 1 (v2.2 — "Andreas-response MVP", ~2-3 weeks):** every confirmed bug + low-risk UX additions. Land first.
- **Phase 2 (v2.3 — "IPCC alignment", ~4-6 weeks):** terminology realignment, per-source breakdowns, MMS expansion, correlation-tab restructure.
- **Phase 3 (v3.0 — "Depth", scoped after Phase 2):** cross-block correlations, MMS sum-to-100% constraint, trend-year correlations.

---

## 2. Cross-cutting divergences — strategic decisions

> **Decision:** All four recommendations below have been **adopted** (May 2026). Implementation status noted per item.

These four items were decided before Phase 1 implementation. Each one ramifies into multiple code changes.

### Divergence 1 — Correlation UI granularity

| | Position |
|---|---|
| **Lolita** (transcript) | Simplify Tab 4 to two modes: none / from time series. Remove manual matrix entry — too technical for the target audience. |
| **Andreas** (transcript) | Keep flexibility. Some users may want correlations only among population data, not among activity data inputs. Suggested adding intermediate options based on IPCC guidance, but cautioned "not too many options because then you're already an advanced user and don't need this tool". |
| **Recommendation** | **Hybrid.** Keep the simple default UI (three radio choices: none / from time series / IPCC-guidance preset). The "IPCC-guidance preset" fills a sensible default matrix — zero correlations except for known structural pairs (e.g. live\_weight ↔ mature\_weight). Hide the manual matrix entry behind an "Advanced" collapsible. This satisfies Andreas's "based on IPCC guidance" ask without exposing matrix algebra to new users, and keeps Lolita's simplification spirit. |

### Divergence 2 — Activity Data vs Emission Factor terminology

| | Position |
|---|---|
| **Current code** | AD = 15 production-side parameters (cattle\_pop, LW, milk\_yield, Ym\_pct, intake parameters, IPCC coefficients Cfi/Ca/Cp/C\_growth). EF = 9 IPCC equation parameters (Bo, EF3\_PRP, EF4, EF5, Frac\_GASM, Frac\_LEACH, ash, UE, MCF). |
| **Andreas / IPCC convention** | AD = population only. EF = emissions per head per year (a derived quantity computed from intake + feed-quality + coefficients). Several parameters we currently call "AD" actually feed into the EF in IPCC framing. |
| **Impact** | The Tab 6 decomposition chart and Tab 8 IPCC Report decomposition do not match what an IPCC inventory reviewer expects. Reviewers will read "Activity Data uncertainty: 12%" and assume that refers to population uncertainty, not the production-side block. |
| **Recommendation** | **Adopt the IPCC mapping.** Rename `param_type = "emission_factor"` to `"coefficient"` in `PARAM_CATALOGUE` (Andreas comment T1.5). Restructure the decomposition runs so AD-only varies cattle\_pop and fixes everything else; EF-only varies everything except cattle\_pop. Re-label all UI text accordingly. This is XL-effort but unavoidable for IPCC credibility. |

### Divergence 3 — Manual correlation entry

| | Position |
|---|---|
| **Lolita** | Delete the manual matrix entry option entirely. |
| **Andreas** | Some users may want population-only correlations or other targeted scenarios that the time-series mode doesn't capture. |
| **Recommendation** | **Keep manual entry but hide it.** Move it under an "Advanced" expander on Tab 4. Add a parameter-group selector ("correlate within: all AD / population only / intake only") inside the time-series mode itself — this gives Andreas's specific scenarios without forcing users to type a matrix. |

### Divergence 4 — Cross-block AD ↔ EF correlation

| | Position |
|---|---|
| **Current code** | Activity-data and emission-factor blocks are sampled with independent copulas. No correlation across blocks. |
| **Andreas** | Some "EF" coefficients are calculated using AD-related data (e.g. Cfi may be derived from herd-structure data on calving rates), so they should be correlated with the AD block. |
| **Recommendation** | **Document as a known limitation in v2.x; defer to v3.0.** Implementing cross-block correlation requires a unified copula across all 24 parameters and surfacing a 24×24 correlation matrix. The effect is real but second-order. A single line in the IPCC Report stating "cross-block correlations assumed zero" is honest and sufficient for now. |

---

## 3. Custom upload diagnostic (T1.1) — priority-one fix

Andreas's first comment was: *"Possible bug? Custom upload seems not to be working. It kept showing the Uganda default values."*

This blocks all real-world testing of the app and is the single most important thing to fix.

**Two prime suspects identified in code:**

1. **Country-dropdown observer race.** [`app_server.R:27-35`](../R/app_server.R#L27-L35) — fires at startup with `input$country == "uganda"` (the default), and re-fires whenever the user re-touches the dropdown. It writes `rv$param_specs` directly. The upload observer at [`app_server.R:37-60`](../R/app_server.R#L37-L60) also writes `rv$param_specs`. If the user uploads, then for any reason re-touches the country dropdown (or a reactivity loop re-evaluates `input$country`), Uganda overwrites their upload silently.

2. **Silent parser failure.** [`parse_uploaded_template()`](../R/utils_template.R) may return empty/partial data when uploaded column names don't match the strict schema, leaving `rv$param_specs` unchanged. The user sees no error and the table still shows Uganda.

**Fix sequence**

1. **Reproduce.** Load Uganda → upload a known-valid custom template → confirm bug.
2. **Add server-side logging** in `observeEvent(input$data_upload, ...)`: write to `rv$sim_log` (a) parser warnings, (b) `nrow(parsed$param_specs)`, (c) the first three parameter names parsed. Surfacing this in the validation panel makes silent failures visible.
3. **Test the parser in isolation.** Run `parse_uploaded_template()` on the test file in an R console — confirm it returns valid data without going through Shiny.
4. **Trace the country observer.** Add `cat()` or `message()` calls to confirm whether anything is re-firing the country observer post-upload.
5. **Fix path A (race condition):** change the country observer to load defaults only when `is.null(rv$param_specs)`, and add an explicit "Reload example" button rather than triggering on dropdown change.
6. **Fix path B (silent parse):** make `parse_uploaded_template()` raise a visible error (in the validation panel) when column-name matches fail, instead of returning empty/partial data.
7. **Verify.** Upload-then-reload-dropdown flow works, log shows correct parameter count, validation panel reports a clear error if upload fails.

This must land first. Everything else in Phase 1 can be done in any order.

---

## 4. Comment-by-comment reflection table

Comments are in Andreas's original tab order (matching the PDF) so cross-referencing is easy.

### Tab 0 — Opening page

| ID | Comment | Status | Verification | Action | Effort | Phase |
|---|---|---|---|---|---|---|
| T0.1 | Minor edits to phrasing — cosmetic | Cosmetic | n/a | Defer to documentation polish pass at end of Phase 1 | S | Defer |
| T0.2 | Add a 'Useful resources' tab linking to IPCC Vol.4 Ch.10–11, FAO L-ADG, uncertainty case studies | UX ✅ Done | `app_ui.R` — new "Resources" nav_panel | Added Resources tab with curated links to IPCC 2006/2019, FAO L-ADG, Penman/Monni, Frey & Rhodes, case studies | S | 1 |
| T0.3 | Anonymise the Uganda example for beta-testing — change to a hypothetical country | UX ✅ Done | `app_ui.R`, `app_server.R:.load_example` | Dropdown labels now read "Country X (hypothetical dairy)" / "Country Y (hypothetical pastoral)"; quick-start text updated | S | 1 |
| T0.4 | Add a statement of prerequisites (what the user needs before using the tool) and limitations (e.g. tool does not estimate input uncertainties) | UX ✅ Done | `app_ui.R` — Home tab | "Before you start" card lists prerequisites and "What this tool does NOT do" | S | 1 |

### Tab 1 — Data Input

| ID | Comment | Status | Verification | Action | Effort | Phase |
|---|---|---|---|---|---|---|
| **T1.1** | **Custom upload not working — Uganda values persist** | **Bug confirmed ✅ Done** | `app_server.R:27-60` (race) and `utils_template.R:parse_uploaded_template` (silent fail) | **Fixed:** upload errors now surface via `showNotification()` and the validation panel; success message displays "X parameters loaded from <filename>"; country dropdown asks for confirmation before overwriting a custom upload; parser raises a clear error listing the unrecognised parameter names | M | 1 |
| T1.2 | Completeness check — for each defined sub-category, are all required parameters present? | Feature gap ✅ Done | `utils_validation.R:validate_completeness`; gate in `app_server.R` run_sim observer | New `validate_completeness()` checks every (cattle_type × aggregation_level × sub_category) group has all `core` parameters from PARAM_CATALOGUE; Run button blocks with a notification listing missing items | M | 1 |
| T1.3 | Align parameter names/abbreviations with IPCC software | Terminology | Need IPCC software screenshots from Andreas | Build a name-mapping table after receiving the screenshots; rename in `PARAM_CATALOGUE` and template | M | 2 |
| T1.4 | Parameter abbreviations need a definitions list (definitions tab) | UX | n/a | Add a "Definitions" tab with the 24 parameter names + plain-language description + IPCC reference (already exists in `PARAM_CATALOGUE`, just needs a viewer) | S | 2 |
| T1.5 | Rename "emission factor" → "coefficient" because both AD and these are used together to compute the actual EF | Terminology | See **Divergence #2** | Rename `param_type = "emission_factor"` to `"coefficient"` throughout codebase, template, and UI text | L | 2 |
| T1.6 | Need guidance: lower/upper are 95% CI bounds; uncertainty\_pct definition unclear | UX ✅ Done | `app_ui.R` — Tab 1 info-panel | Added explicit explainer paragraph on Tab 1: defines mean / uncertainty_pct / lower / upper and notes that edits cascade to keep them consistent | S | 1 |
| T1.7 | Triangular distribution — guidance for converting min/max to 95% CI | UX | n/a | Add note in the distribution dropdown and a separate guidance doc | S | 3 |
| T1.8 | Bug — editing `uncertainty_pct` updates bounds, but editing bounds does not update `uncertainty_pct` | Bug confirmed ✅ Done | `app_server.R:param_table_cell_edit` rewritten | Bidirectional cascade: editing `mean` or `uncertainty_pct` recomputes bounds; editing `lower`/`upper` recomputes `uncertainty_pct` from symmetric half-width | M | 1 |
| T1.11a | Bug — changing distribution to "constant" doesn't auto-zero the bounds | Bug confirmed ✅ Done | Same observer | When `distribution = "constant"`, observer auto-sets `uncertainty_pct = 0` and `lower = upper = mean` | S | 1 |
| T1.12 | Selectable emission sources — some users only want enteric, or only manure | Feature gap | `mc_simulation.R:72-78` always sums all 5 sources | Add checkboxes to the Inventory\_Metadata sheet (Enteric CH4 / Manure CH4 / Manure N2O direct / Manure N2O indirect / Pasture deposit N2O) and read them into the simulation pipeline | M | 2 |

### Blank Template

| ID | Comment | Status | Verification | Action | Effort | Phase |
|---|---|---|---|---|---|---|
| TT.1 | Clarify how to enter percentages (`45` or `45%`) | UX ✅ Done | `utils_template.R` — Parameters sheet instruction banner | Banner now explicitly states: "PERCENTAGE FIELDS: enter the bare number, e.g. '45' for 45% — do NOT include the '%' symbol" | S | 1 |
| TT.2 | Delete `data_quality` column if it has no function | Bug confirmed ⚠️ Partial | grep confirms zero use in calculations or QA/QC | Marked deprecated in template instruction banner ("data_quality (col Q) is documentation-only and will be removed in v2.3"); structural removal deferred to Phase 2 alongside template refactor | S | 1 → 2 |
| TT.3 | MMS dropdown does not change between IPCC 2006 and 2019; doesn't include all dairy/beef-specific options | Feature gap | `utils_ipcc_defaults.R:20` defines a single MMS list with 8 entries | Restructure MMS list as two named vectors (`MMS_2006`, `MMS_2019`); make the dropdown conditional on `ipcc_version`; expand to full IPCC tables (10.17, 10.21) | M | 2 |
| TT.4 | Missing columns: EF4, EF5, Frac\_LEACH, Frac\_GASM\_S, Frac\_LEACH\_H, Frac\_GASM | Feature gap | EF4, EF5, Frac\_LEACH, Frac\_GASM exist as **global** parameters in `PARAM_CATALOGUE`; the per-MMS variants (Frac\_GASM\_S, Frac\_LEACH\_H) are not modelled | Add per-MMS columns to the Manure\_Management sheet; update `calc_manure_n2o.R` to apply them per-MMS rather than globally | L | 2 |
| TT.5 | Same MMS values across sub-categories — guidance unclear | UX ✅ Done | `utils_template.R` — Manure_Management instruction banner | Banner now states: "if all sub-categories use the same MMS allocation, leave sub_category blank — values apply to every sub-category in that group; otherwise provide separate rows per sub-category" | S | 1 |
| TT.6 | Single-year vs trend analysis option | Feature gap | App always runs single-year; Trend tab is placeholder | Folds into the Trend tab work (currently in Tab 9 placeholder); add radio for "single year / trend" on the opening page | M | 3 |
| TT.7 | Parameter time series — see correlations tab below | Reference | n/a | Cross-ref to T4.x rows | — | — |
| TT.8 | QC in input template — completeness + documentation that the user has checked their inputs | UX ⏳ Deferred | Currently no Excel-level validation beyond dropdowns | Excel-level conditional formatting deferred to Phase 2 (requires significant template builder refactor); in-app completeness check covers the runtime case (T1.2) | M | 2 |
| TT.9 | Param\_type set by default, not user-defined; relates to correlations | Reference | `utils_template.R:97-98` assigns from catalogue | Folds into **Divergence #2** (rename emission\_factor → coefficient) | — | — |

### Tab 2 — QA/QC

| ID | Comment | Status | Verification | Action | Effort | Phase |
|---|---|---|---|---|---|---|
| T2.1 | Benchmark deviation methodology — what does it benchmark against? Considers IPCC region or version? | Feature gap | `utils_qaqc.R:136-150` — single ±50%/±200% tolerance against `IPCC_DEFAULTS`, no region/version awareness | Expand `IPCC_DEFAULTS` into a region × version table; refactor benchmark check to look up the right cell | L | 3 |
| T2.2 | Completeness check (per sub-category, minimum set of variables) | Feature gap ✅ Done | Same as T1.2 | Single implementation covers both T1.2 and T2.2 | M | 1 |
| T2.3 | Continuous distributions (e.g. normal) on fractional parameters can produce out-of-range samples | Bug confirmed ✅ Done | `utils_qaqc.R` — new check 5b "fraction_distribution" | Added a QA/QC check: when a fractional parameter (`pct_lactating`, `ash`, `UE`, `Frac_GASM`, `Frac_LEACH`) uses an unbounded distribution (`normal`, `lognormal`, `posnorm`), the row warns and recommends `tnorm_0_1` or `beta` | M | 1 |

### Tab 3 — Uncertainty

| ID | Comment | Status | Verification | Action | Effort | Phase |
|---|---|---|---|---|---|---|
| T3.1 | If a user edits Tab 3, are the QA/QC checks re-applied? | Already works | `app_server.R:91-94` — `qaqc_result` reactive depends on `rv$param_specs`; edits trigger recompute | No action needed; document this in the response to Andreas | — | — |
| T3.2 | "Quick-set buttons at the bottom" — cannot find these | Bug confirmed ✅ Done | `app_server.R` — new `observeEvent(input$set_all_normal)` and `set_all_pert` handlers | Both buttons now functional; "Set All AD to Normal +/-15%" sets distribution + uncertainty_pct + recomputes bounds; "Set All EF to PERT" sets distribution; success notifications shown | S | 1 |
| T3.3 | EF correlations — see correlations tab below | Reference | n/a | Cross-ref to **Divergence #1** | — | — |

### Tab 4 — Correlations

| ID | Comment | Status | Verification | Action | Effort | Phase |
|---|---|---|---|---|---|---|
| T4.1 | AD correlations from time series only — what about other correlations (e.g. milk\_yield ↔ calf\_weight\_gain via shared assumption)? Would these match the time-series correlation? | Divergence #1 | `app_ui.R:269-272` shows 3 modes: none / time series / manual | See **Divergence #1**: keep simple radios + IPCC-guidance preset + Advanced expander with manual entry and group selector | L | 2 |
| T4.2 | Guidance on correlations needed | UX ✅ Done | `app_ui.R` — Tab 4 info-panel | Expanded the Tab 4 panel with a "When to use correlations" section and bullets covering AD-from-time-series, AD-manual (advanced), and EF-uniform-rho with concrete recommendations | S | 1 |
| T4.3 | EF correlations — Cfi may be calculated using cow-birth proportion data, so AD↔EF correlation exists | Divergence #4 | Independent blocks in `mc_sampling.R` | See **Divergence #4**: defer to v3.0; document as known limitation | XL | 3 |
| T4.4 | "Default is no EF correlation, which is the standard IPCC Approach 2 assumption" — is this correct? | Bug confirmed ✅ Done | `app_ui.R` — Tab 4 EF correlation card | Tooltip rephrased: "Default is no EF correlation — a simplifying assumption used when no information on correlations is available. IPCC Approach 2 recommends incorporating known correlations where they exist." | S | 1 |
| T4.21 | MMS correlations — IPCC 2019 Box 3.1A says fractions sum to 100% so they are mutually dependent | Feature gap | MMS fractions currently treated as fixed inputs, not random variables | Implement Dirichlet sampling for MMS fractions when uncertainty is specified; constrain sum-to-100% | L | 3 |
| T4.22 | Trend correlations — IPCC 2019 §3.2 covers correlation between years | Feature gap | Folds into Trend tab | Implement once the Trend tab is built; reference IPCC 2006 §3.2.1.2 and 2019 §3.22ff | L | 3 |

### Tab 5 — Simulate

| ID | Comment | Status | Verification | Action | Effort | Phase |
|---|---|---|---|---|---|---|
| T5.1 | Tool should auto-proceed to Tab 6 when simulation completes | Bug confirmed ✅ Done | `app_ui.R:page_navbar id="nav"`; `app_server.R` after success | `bslib::nav_select(id = "nav", selected = "6. Results")` called after simulation completes; "Simulation complete. Showing Results." notification fires | S | 1 |

### Tab 6 — Results

| ID | Comment | Status | Verification | Action | Effort | Phase |
|---|---|---|---|---|---|---|
| T6.1 | Summary cards show CV — IPCC requires 95% margin of error | Feature gap ✅ Done | `mc_uncertainty.R:calc_uncertainty_metrics`; `app_ui.R` value boxes; `app_server.R` `vb_moe`; by-system table | Added quantile-based 95% MoE (asymmetry-aware: `((q975 - q025)/2)/mean*100`). **Bonus bug fix:** previous `moe_pct` formula was `1.96*sd/sqrt(n)/mean` — that is the standard error of the *estimator*, ~1/100 of the true MoE for n=10,000. New value-box "95% Margin of Error" is the IPCC headline metric; CV% retained as secondary | M | 1 |
| T6.2 | Report per inventory reporting category (dairy enteric, dairy manure CH4, etc.), not per gas | Feature gap | `app_server.R:479-496` — by-system table is gas-only | Add a cross-tab: rows = (sub-category × source), columns = mean / 95% CI / MoE; place above the per-gas table | L | 2 |
| T6.3 | CO₂eq not needed in summary, but keep in calculations for sensitivity | UX ✅ Done | `app_ui.R` value-box row + inline secondary line | CO₂eq removed from primary card row (replaced by 95% MoE card); CO₂eq value + 95% CI now shown as a smaller inline line below the cards. Underlying `mc_results$inventory$total_co2e` unchanged so sensitivity / decomposition still work | S | 1 |
| T6.4 | Decomposition — the AD/EF definitions used here likely differ from IPCC | Divergence #2 | Confirmed: 15-param AD vs 9-param EF, not IPCC's population-vs-EF | See **Divergence #2**: re-classify so AD-only run varies cattle\_pop and EF-only varies everything else | XL | 2 |

### Tab 7 — Sensitivity

| ID | Comment | Status | Verification | Action | Effort | Phase |
|---|---|---|---|---|---|---|
| T7.1 | Clarify whether rankings reflect parameter influence on uncertainty or on the level of emissions | UX ✅ Done | `app_ui.R` — Tab 7 info-panel | Added explicit "Note: these rankings show which parameters drive the **uncertainty** of total emissions, not the absolute emission level" | S | 1 |
| T7.2 | One chart + table per emission source, plus a combined option | Feature gap | Currently a single combined chart only | Add a dropdown above the chart: "Source: All / Enteric CH4 / Manure CH4 / N2O direct / N2O indirect / Pasture N2O"; recompute SRC/PRCC per source | M | 2 |

### Tab 8 — IPCC Report

| ID | Comment | Status | Verification | Action | Effort | Phase |
|---|---|---|---|---|---|---|
| T8.1 | CV → 95% margin of error (also requested for IPCC Report) | Feature gap ✅ Done | Same as T6.1 | Single implementation covers both — by-system table now includes `MoE_95_pct` column | M | 1 |
| T8.2 | AD/EF redefinition (also requested for IPCC Report) | Divergence #2 ⏳ Phase 2 | Same as T6.4 | Strategic decision adopted — implementation in Phase 2 | XL | 2 |
| T8.3 | Add a tab/section summarising all inputs used in the run (full documentation) | Feature gap ✅ Done | `app_ui.R` — new "Input parameters used in this run" card; `app_server.R:inputs_doc_table` | New DT table in IPCC Report tab lists every parameter row used: cattle_type / aggregation_level / sub_category / parameter / param_type / mean / uncertainty_pct / lower / upper / distribution / data_source / ipcc_ref | M | 1 |
| T8.4 | Auto-generate uncertainty distribution charts and tornado charts inside the report | Feature gap | Charts live in Tab 6 / Tab 7 | Embed the per-source distribution histograms and tornado charts in the IPCC Report tab and the XLSX export | M | 2 |

### Meeting transcript

| ID | Topic | Status | Action | Effort | Phase |
|---|---|---|---|---|---|
| Tx.1 | Andreas — show the fitted distribution in a final report output, useful for third-party QA | Feature gap | Add a "Distributions used" section in the IPCC Report tab with mini-density plots for each parameter | M | 3 |
| Tx.2 | Lolita wants to delete manual correlation entry; Andreas wants to keep some flexibility | Divergence #1/#3 | See **Divergence #1** and **Divergence #3** — keep manual entry hidden under Advanced; add group selector | L | 2 |

---

## 5. Implementation roadmap

### Phase 1 — v2.2 "Andreas-response MVP" (~2-3 weeks)

Bug fixes only + low-risk UX. Land first; this is what we report back to Andreas as "addressed".

**Critical (must land before any other Phase 1 work):**

- T1.1 — Custom upload bug (see section 3)

**Bug fixes:**

- T1.2 / T2.2 — Completeness check on the Run button
- T1.6 — Tooltips and guidance on bounds and uncertainty\_pct
- T1.8 + T1.11a — Bidirectional cell-edit cascade with distribution-aware behaviour
- TT.1 — Percentage entry guidance in template
- TT.2 — Remove `data_quality` column
- TT.5 — Document MMS-per-sub-category behaviour
- TT.8 — Excel-level QC in template
- T2.3 — Fractional-parameter distribution check
- T3.2 — Wire up quick-set buttons
- T4.4 — Rephrase EF-correlation tooltip
- T5.1 — Auto-navigate Simulate → Results
- T6.1 / T8.1 — 95% margin of error metric
- T6.3 — Hide CO₂eq from primary summary
- T8.3 — Input documentation table in IPCC Report
- T7.1 — Sensitivity tab clarifying sentence

**UX additions:**

- T0.2 — Useful resources tab
- T0.3 — Anonymise Uganda example
- T0.4 — Prerequisites & limitations card
- T4.2 — Correlation guidance text

### Phase 2 — v2.3 "IPCC alignment" (~4-6 weeks)

Requires divergence decisions #1, #2, #3.

- T1.5 + T6.4 + T8.2 + TT.9 — AD/EF/coefficient rename and decomposition restructure
- T1.3 + T1.4 — Parameter-name alignment + Definitions tab
- T1.12 — Emission-source selector
- TT.3 + TT.4 — MMS dropdown expansion + per-MMS Frac columns
- T4.1 + Tx.2 — Correlation tab restructure (radios + preset + Advanced)
- T6.2 — Per-reporting-category breakdown
- T7.2 + T8.4 — Per-source sensitivity charts and IPCC Report chart embedding

### Phase 3 — v3.0 "Depth"

Scoped after Phase 2 lands.

- T4.3 — Cross-block AD↔EF correlation (Divergence #4)
- T4.21 — MMS sum-to-100% Dirichlet
- T4.22 + TT.6 — Trend / two-year correlation
- T2.1 — Region-aware benchmarks
- Tx.1 — Distribution visualisation in IPCC Report
- T1.7 — Triangular distribution conversion guidance

### Out of scope / cosmetic

- T0.1 — Phrasing edits (address with documentation polish at end of each phase)

---

## 6. Open questions for Lolita

These don't block implementation but inform the response to Andreas.

1. **Tone of the response to Andreas.** Do we send him this document directly, or summarise it in plainer language for someone without programming background?
2. **IPCC software screenshots** referenced in T1.3 — does Lolita have these? They are needed before the parameter-name alignment exercise can be made specific.
3. **L-ADG citation** — confirm "Livestock Activity Data Guidelines" (FAO) is the document Andreas means in T0.2 before we hard-code the link.
4. **Phase-1 deadline** — does the v2.2 release have a target date driven by an external event (workshop, beta testing window)?

---

## Appendix A — IPCC terminology mapping (Divergence #2)

If we adopt the IPCC convention, parameters in `PARAM_CATALOGUE` would be re-classified as follows.

| Parameter | Current `param_type` | IPCC framing | Phase 2 `param_type` |
|---|---|---|---|
| `cattle_pop` | activity_data | Activity data (population) | `activity_data` (unchanged) |
| `live_weight` | activity_data | Feeds into EF (animal energy demand) | `coefficient` |
| `mature_weight` | activity_data | Feeds into EF | `coefficient` |
| `weight_gain` | activity_data | Feeds into EF (NEg) | `coefficient` |
| `milk_yield` | activity_data | Feeds into EF (NEl) | `coefficient` |
| `milk_fat` | activity_data | Feeds into EF (NEl) | `coefficient` |
| `pct_lactating` | activity_data | Feeds into EF (NEl scaling) | `coefficient` |
| `DE_pct` | activity_data | Feeds into EF (REM, REG, GE) | `coefficient` |
| `Cfi` | activity_data | IPCC coefficient | `coefficient` |
| `Ca` | activity_data | IPCC coefficient | `coefficient` |
| `C_growth` | activity_data | IPCC coefficient | `coefficient` |
| `Cp` | activity_data | IPCC coefficient | `coefficient` |
| `hours` | activity_data | Feeds into EF (NEw) | `coefficient` |
| `CP_pct` | activity_data | Feeds into N excretion EF | `coefficient` |
| `protein_milk` | activity_data | Feeds into N excretion EF | `coefficient` |
| `Ym_pct` | emission_factor | IPCC coefficient | `coefficient` |
| `Bo` | emission_factor | IPCC coefficient | `coefficient` |
| `ash` | emission_factor | IPCC coefficient | `coefficient` |
| `UE` | emission_factor | IPCC coefficient | `coefficient` |
| `EF3_PRP` | emission_factor | IPCC EF | `coefficient` |
| `Frac_GASM` | emission_factor | IPCC EF | `coefficient` |
| `EF4` | emission_factor | IPCC EF | `coefficient` |
| `EF5` | emission_factor | IPCC EF | `coefficient` |
| `Frac_LEACH` | emission_factor | IPCC EF | `coefficient` |

Under the IPCC framing, **only `cattle_pop` is true Activity Data**. All other 23 parameters are coefficients that combine to produce the emission factor (emissions per head per year). The decomposition in Tab 6 / Tab 8 should therefore report:

- **AD-only run:** `cattle_pop` varies, all 23 coefficients fixed at mean
- **EF-only run:** all 23 coefficients vary, `cattle_pop` fixed at mean
- **Combined run:** everything varies

---

## Appendix B — Code locations verified during this review

For spot-checking the technical claims in the table.

| Claim | File:line |
|---|---|
| Quick-set buttons declared without handler | `R/app_ui.R:237-239` |
| Cell-edit observer (no cascade) | `R/app_server.R:70-74` |
| Country dropdown observer | `R/app_server.R:27-35` |
| Upload observer | `R/app_server.R:37-60` |
| Run button gating only on req() | `R/app_server.R:222` |
| QA/QC checks list (6 checks) | `R/utils_qaqc.R:23-173` |
| Benchmark deviation (no region/version) | `R/utils_qaqc.R:136-150` |
| Fractional parameter list | `R/utils_qaqc.R:5` |
| QA/QC reactive chain | `R/app_server.R:91-94` |
| CV% metric | `R/mc_uncertainty.R:3-12` |
| IPCC table columns (CV-only) | `R/utils_export.R:14-39` |
| `data_quality` column generation | `R/utils_template.R:535-537` |
| MMS list (single, fixed) | `R/utils_ipcc_defaults.R:20` |
| EF4/EF5/Frac_LEACH applied globally | `R/calc_manure_n2o.R:35-45` |
| All 5 emission sources hardcoded | `R/mc_simulation.R:72-78` |
| Manure_Management defaults when missing | `R/app_server.R:273-290` |
| `param_type` not user-editable | `R/utils_template.R:97-98`, `R/app_ui.R:228-229` |
| Correlation modes radio | `R/app_ui.R:269-272` |
| EF correlation slider | `R/app_ui.R:290-299` |
