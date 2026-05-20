library(officer)
library(flextable)

# ── colour palette ──────────────────────────────────────────────────────────
COL_DONE    <- "#D8F3DC"   # green
COL_PARTIAL <- "#FFF3CD"   # amber
COL_PENDING <- "#FFE5E5"   # red-pink
COL_BLOCKED <- "#E8E8E8"   # grey
COL_NOTED   <- "#EAF0FB"   # blue (noted / no action needed)
COL_HDR     <- "#2D6A4F"   # dark green header

# ── helpers ──────────────────────────────────────────────────────────────────
status_fill <- function(s) {
  dplyr::case_when(
    s == "Done"       ~ COL_DONE,
    s == "Partial"    ~ COL_PARTIAL,
    s == "Pending"    ~ COL_PENDING,
    s == "Blocked"    ~ COL_BLOCKED,
    s == "Noted"      ~ COL_NOTED,
    TRUE              ~ "#FFFFFF"
  )
}

make_table <- function(df, title) {
  ft <- flextable(df) |>
    set_header_labels(
      ref     = "Ref",
      section = "Section",
      comment = "Comment summary",
      status  = "Status",
      detail  = "What was done / what remains"
    ) |>
    width(j = "ref",     width = 0.45) |>
    width(j = "section", width = 1.20) |>
    width(j = "comment", width = 2.60) |>
    width(j = "status",  width = 0.80) |>
    width(j = "detail",  width = 3.70) |>
    theme_booktabs() |>
    bold(part = "header") |>
    color(part = "header", color = "#FFFFFF") |>
    bg(part = "header", bg = COL_HDR) |>
    fontsize(size = 9, part = "all") |>
    font(fontname = "Calibri", part = "all") |>
    align(j = "ref",    align = "center", part = "all") |>
    align(j = "status", align = "center", part = "all") |>
    valign(valign = "top", part = "all") |>
    set_table_properties(layout = "fixed")

  # colour Status cells
  for (i in seq_len(nrow(df))) {
    ft <- bg(ft, i = i, j = "status", bg = status_fill(df$status[i]))
  }

  ft <- bold(ft, j = "status") |>
    padding(padding = 4, part = "all") |>
    line_spacing(space = 1.1, part = "body")

  list(title = title, ft = ft)
}

# ── DATA ─────────────────────────────────────────────────────────────────────

# SECTION A — Major calculation issues
sA <- data.frame(
  ref = c("A1","A2","A-pasture","A-risk-run"),
  section = "A — Major calc issue (N₂O)",
  comment = c(
    "Direct N₂O MM (tool 24.77 t) much lower than Excel/@Risk (33.23 t); Excel mean outside tool 95% CI.",
    "Indirect N₂O MM (tool 9.69 t) much lower than Excel (16.89 t); % deviation larger than direct N₂O.",
    "Pasture emissions not in downloadable reports.",
    "Unclear whether Andreas's @Risk run used AD+EF uncertainty or EF-only."
  ),
  status = c("Done","Done","Done","Blocked"),
  detail = c(
    "Root cause: calc_n_excretion applied DE factor to N-intake step (contradicts IPCC Eq 10.32). Fixed by removing DE from N intake. Post-fix: direct N₂O = 30.71 t (vs 33.23, −7.6%) — within MC noise. Secondary: DINT_heif vs DINT_heifer mismatch in Zimbabwe template → MMS allocation fell back to default; upload-time warning added.",
    "Same root cause as A1 — Nex cascades into indirect N₂O via EF4/EF5. After fix: indirect N₂O = 15.42 t (vs 16.89, −8.7%). Both fixes together close gap to within MC noise.",
    "Pasture direct and indirect N₂O now split as separate rows in CSV download (3.C.4 / 3.C.5 IPCC codes), IPCC summary table, and Word report Section 4.",
    "Pending Andreas confirmation. Determines whether rShiny comparison should be EF-only (no correlations, N fixed at point estimate). E5 in tracker."
  ),
  stringsAsFactors = FALSE
)

# SECTION B — Home page
sB_home <- data.frame(
  ref = c("B1","B2","B3","B4"),
  section = "B — Home page",
  comment = c(
    "Minor edit: bullet should read '…IPCC 2006 Vol. 1 Ch. 3, Table 3.3'.",
    "Emission sources need subscripts throughout; pasture direct/indirect should be listed separately.",
    "Quick-start card: analysis-mode toggle easy to miss at bottom of Home page; move to Data Input.",
    "'What does this tool do?' and 'What this tool does NOT do' — wording revisions."
  ),
  status = c("Done","Done","Done","Done"),
  detail = c(
    "Bullet updated in Home-page 'What does this tool do?' card.",
    "Unicode subscripts applied throughout UI (value-boxes, source selectors, sensitivity dropdown, results headers, definitions glossary). Word/Excel retain ASCII CH4/N2O to avoid locale rendering issues.",
    "'Choose your analysis mode' card removed from Home page; placed at top of '1. Data Input' tab. Data Input sidebar reordered: (1) Pick IPCC version → (2) Download template → (3) Upload.",
    "Both wordings updated in the Home-page cards."
  ),
  stringsAsFactors = FALSE
)

# SECTION B — Definitions page
sB_def <- data.frame(
  ref = paste0("B", 5:16),
  section = "B — Definitions page",
  comment = c(
    "#5 — 'Technical' vs 'Core': terminology confusing with IPCC 'Tier'.",
    "#6 — Parameter 'W': in Eq 10.6 and 10.17 it is 'BW'; suggest rename throughout.",
    "#7 — 'CP': should be noted as CP% (crude protein percentage).",
    "#8 — Milk: 'Set 0 for non-dairy' should be 'Set 0 for sub-categories that do not lactate'.",
    "#9 — pct_lactating vs pct_pregnant: are these two separate IPCC-compliant parameters?",
    "#10 — FracGASMS and FracLEACH: should list 4 variants (MM + PRP separately).",
    "#11 — C (growth coeff for Neg): 'depends on sex' → 'depends on sex and physiological status'.",
    "#12 — Ym: remove redundant word 'methane' from definition.",
    "#13 — Fat: 'fat content of the diet' → 'fat content of milk'.",
    "#14 — EF4/EF5: don't include default values in the Definition column.",
    "#15 — EF3_PRP listed but EF3_S (Table 10.21) missing.",
    "#16 (this session) — Logos not present in app."
  ),
  status = c("Done","Partial","Done","Done","Partial","Done","Done","Done","Done","Done","Done","Done"),
  detail = c(
    "param_tier renamed 'technical' → 'advanced' in PARAM_CATALOGUE. UI label changed to 'Level (core / advanced)'. Legacy 'technical' still accepted as alias.",
    "BW alias added to PARAM_ALIASES so uploaded templates using 'BW' are accepted. Full canonical rename of 'W' → 'BW' deferred pending Andreas sign-off (E3).",
    "Definition reworded to 'Crude protein (CP%) content of the diet — used to estimate nitrogen excretion'.",
    "PARAM_CATALOGUE definition reworded.",
    "Milk row updated to spell out per-lactating-animal convention. Deeper consolidation of pct_lactating vs Cp pro-rate deferred pending Zimbabwe Milk-convention confirmation (E4).",
    "Added Frac_GASM_PRP (Table 11.3, default 0.21) and Frac_LEACH_PRP (Table 11.3, default 0.30) to PARAM_CATALOGUE, IPCC_DEFAULTS, and QAQC. calc_indirect_n2o_prp now uses PRP-specific fractions instead of MM fractions.",
    "Definition reworded in PARAM_CATALOGUE.",
    "Definition updated to remove redundant 'methane'.",
    "Definition reworded to 'Fat content of milk (% by weight)'.",
    "EF4 → 'N₂O EF for atmospheric N deposition (IPCC Table 11.3)'. EF5 → 'N₂O EF for N leaching/runoff (IPCC Table 11.3)'. Numeric defaults remain in ipcc_default column.",
    "EF3_S added to PARAM_CATALOGUE (default 0.005 kg N₂O-N/kg N, Monni-2007 bounds 0.001–0.025, IPCC Table 10.21).",
    "Logo bar added to Home page with Alliance Bioversity-CIAT, CGIAR, and GMH placeholders. onerror fallback shows text if PNG not found. Actual PNG files not yet in www/ — will be added once received from partners (E1 for GMH funder logo)."
  ),
  stringsAsFactors = FALSE
)

# SECTION B — Resources page
sB_res <- data.frame(
  ref = paste0("B", 17:22),
  section = "B — Resources page",
  comment = c(
    "#16 — Add link to IPCC 2019 Vol 1 Ch 3 (Uncertainties).",
    "#17 — FAO L-ADG link label correction.",
    "#18 — Move Monni et al. 2007 to case studies section.",
    "#19 — Add 'Learning resources' sub-section (FAO e-learning, UNFCCC webinar).",
    "#20 — 'Case studies' vs 'Examples': title; add national inventory links.",
    "#21 — Tool-specific resources sub-section needed: (a) how tool works, (b) how to use, (c) preparing inputs."
  ),
  status = c("Done","Done","Done","Done","Partial","Done"),
  detail = c(
    "IPCC 2019 Refinement Vol 1 Ch 3 link added under 'Methodological foundations'.",
    "Label renamed to 'FAO Livestock Activity Data Guidance (L-ADG)'.",
    "Monni et al. (2007) moved from 'Activity data guidance' to 'Case studies' subsection.",
    "'Learning resources' sub-section added with FAO e-learning links (land-sector uncertainty + Tier 2 livestock) and a UNFCCC methodological-issues link.",
    "Title kept as 'Case studies'. Placeholder bullet added for national inventory links. Andreas to compile NZ + other national inventory URLs (E6).",
    "New 'Tool-specific resources' card placed at top of Resources page with three sub-sections: How tool works / How to use / Preparing inputs. Marked as draft for beta-testing. User guide download button to be added when final version received (D1)."
  ),
  stringsAsFactors = FALSE
)

# SECTION B — Data Input page
sB_di <- data.frame(
  ref = c("B22a","B22b","B22c","B22d","B22e","B23"),
  section = "B — Data Input page",
  comment = c(
    "#22a — EF3, EF4, EF5, Fracgas, Fracleach on Parameters tab but should be in Manure_Management.",
    "#22b — Bo repeated in Parameters and Manure_Management tabs — unclear which is used.",
    "#22c — Columns L/M auto-fill formula didn't work unless cursor placed at end of formula.",
    "#22d — Bo in Manure_Management has no uncertainty columns.",
    "#22e — Parameter_TimeSeries sheet missing cattle_type / aggregation_level / sub_category columns.",
    "#23 — Cfi winter temperature (Tw) should be in upload template, not just an advanced UI option."
  ),
  status = c("Done","Done","Done","Done","Done","Done"),
  detail = c(
    "EF3 is already per-MMS on Manure_Management. EF4/EF5 are global IPCC scalars — must stay on Parameters. Frac_GASMS / Frac_LEACH_H kept as broadcast fallbacks. EF3_PRP / Frac_GASM_PRP / Frac_LEACH_PRP are pasture parameters — correctly on Parameters tab. Clarification note added.",
    "Bo removed from Manure_Management sheet (was never consumed — Bo always came from Parameters, correct because it varies by animal type). MM_COLS/MM_WIDTHS shortened; downstream style indices updated.",
    "Template generator now pre-computes lower/upper as numeric cells for example and IPCC-default rows. Blank rows still use Excel formula. No more openxlsx auto-recalc quirk on opening.",
    "Resolved by B22b — Bo no longer appears in Manure_Management, so missing columns are moot.",
    "Parameter_TimeSeries sheet now has cattle_type / aggregation_level / sub_category columns prepended before year. Example block filled with dairy / Country X labels.",
    "Tw (mean winter daily temperature, °C, IPCC Eq 10.2) added to PARAM_CATALOGUE with default 20°C (leaves Cfi adjustment inert). Parameters template now generates a Tw row per sub-category."
  ),
  stringsAsFactors = FALSE
)

# SECTION B — QAQC page
sB_qaqc <- data.frame(
  ref = c("B24","B25"),
  section = "B — QA/QC page",
  comment = c(
    "#24 — General feedback: QAQC tests useful and picked up errors.",
    "#25 — Benchmark deviations often flagged inappropriately (Monni 2007 benchmarks don't suit all countries/IPCC versions)."
  ),
  status = c("Noted","Partial"),
  detail = c(
    "No change required — positive feedback noted.",
    "Added MONNI_BENCHMARK_PARAMS set in utils_qaqc.R covering EF3_PRP, EF3_S, EF4, EF5, Frac_GASMS, Frac_LEACH_H and PRP fractions. For these parameters, benchmark_deviation check now reports 'info' (blue ⓘ) instead of fail/warn, with explanatory note that country-specific overrides are expected. Still pending (plan item A2): replacing Monni/Penman source references for EF3, EF3_S, EF4, EF5, Frac_GASF, Frac_LEACH with actual IPCC 2006/2019 guideline ranges."
  ),
  stringsAsFactors = FALSE
)

# SECTION B — Uncertainty page
sB_unc <- data.frame(
  ref = "B26",
  section = "B — Uncertainty page",
  comment = "#26 — Users prefer editing failed items in the template and re-uploading rather than editing in-app.",
  status = "Done",
  detail = "Bullet added to Resources page documenting both workflows: (a) edit in-app Parameters table for quick fixes; (b) edit Excel template and re-upload to keep a record of final values.",
  stringsAsFactors = FALSE
)

# SECTION B — Simulate & Results page
sB_sim <- data.frame(
  ref = paste0("B", 27:34),
  section = "B — Simulate & Results",
  comment = c(
    "#27 — Pasture direct and indirect N₂O should be listed as separate emission sources.",
    "#28 — IPCC-aligned options: see comments #9 and #23.",
    "#29 — Possible bug: AD/EF decomposition not shown for custom uploaded datasets.",
    "#30 — '10,000 iterations for reliable results' — is there a basis for this?",
    "#31 — Minor edit: instruct user to click Run button 'at the bottom of the left-hand panel'.",
    "#32 — Results shown per sub-category; IPCC requires dairy vs other cattle aggregation.",
    "#33 — Re-running same template caused 'replacement has 0 rows' error.",
    "#34 — Units (e.g. t CH₄) not always shown in results tables and downloaded reports."
  ),
  status = c("Done","Done","Done","Done","Done","Done","Done","Done"),
  detail = c(
    "Source selector now has two pasture keys: pasture_n2o_direct and pasture_n2o_indirect. .apply_source_selection and filter_co2e updated. Legacy pasture_n2o accepted as alias.",
    "See responses to #9 (Milk convention — deferred, E4) and #23 (Tw added to catalogue — done).",
    "Root cause: param_type NA in decompose_uncertainty caused 'NAs not allowed in subscripted assignment'. Fixed by coercing NA → 'coefficient' at top of decompose_uncertainty in mc_uncertainty.R.",
    "Wording softened to '10,000+ iterations recommended; check convergence by re-running with a different seed (1,000 is fine for quick testing)'.",
    "Info panel on Simulate tab updated to include 'at the bottom of the left-hand panel'.",
    "Aggregation level selectInput added: cattle_type (default), aggregation_level, sub_category. New .agg_results_by_level() helper parses system key and sums per-iteration columns.",
    "Two pre-flight checks added in run_inventory_simulation: (a) empty by_system → descriptive stop; (b) per-system row-count mismatch → stop with iteration-count detail.",
    "All results-table column headers now include explicit units (Mean CH₄ (t), MoE 95% (%), etc.). CSV download has unit column. Word report has Unit column. Value-boxes already showed t suffix."
  ),
  stringsAsFactors = FALSE
)

# SECTION B — Sensitivity page
sB_sens <- data.frame(
  ref = "B35",
  section = "B — Sensitivity page",
  comment = "#35 — Tornado chart should show results at sub-category level (cattle_type | sub_category | parameter), not just parameter name.",
  status = "Partial",
  detail = "Structural bug fixed: zero-variance output guard added in mc_sensitivity.R — when selected output is constant (e.g. PRP N₂O with pct_pasture=0), returns explanatory message instead of spurious SRC/PRCC ranks. Sub-category prefix labels (e.g. 'dairy | cows – Ym') implemented in .aggregate_sensitivity() — column names now prefixed with 'cattle_type | sub_category'. Full per-sub-category aggregation with user-selectable level: done in this session.",
  stringsAsFactors = FALSE
)

# SECTION B — IPCC Reports & Downloads
sB_rep <- data.frame(
  ref = paste0("B", 36:39),
  section = "B — IPCC Reports & Downloads",
  comment = c(
    "#36 — CSV/Word don't disaggregate pasture direct and indirect N₂O separately.",
    "#37 — Word Section 4 reports only by gas, not by IPCC emission category.",
    "#38 — Excel download did not work.",
    "#39 — Word report should follow Andreas's mock-up with per-cattle-type columns and AD/EF tables."
  ),
  status = c("Done","Done","Done","Partial"),
  detail = c(
    "CSV now writes pasture_n2o_direct and pasture_n2o_indirect as separate rows (3.C.4 and 3.C.5 IPCC codes). Word Section 4 includes both rows. IPCC summary table updated.",
    ".results_flextable() rebuilt: one row per IPCC emission source (enteric CH₄, manure CH₄, MM N₂O direct/indirect, PRP N₂O direct/indirect, totals) plus Unit column. Renamed numeric headers.",
    "export_results_xlsx() hardened against NULL/empty inputs — each sheet now receives a placeholder data frame when decomposition was skipped, so workbook always writes.",
    "Section 4 per-source rows and Unit column done. AD/EF per-source tables (.ad_ef_flextable() helper) added after Executive Summary. Not yet done: per-cattle-type aggregation columns (dairy vs other cattle) in executive summary table (plan item B5)."
  ),
  stringsAsFactors = FALSE
)

# SECTION C — Pilot test-run overall
sC <- data.frame(
  ref = paste0("C", 1:12),
  section = "C — Pilot test-run feedback",
  comment = c(
    "C1 — Headline value-boxes show total CH₄ / N₂O; should show IPCC emission sources.",
    "C2 — System breakdown per sub-category; IPCC requires dairy vs other cattle first.",
    "C3 — Enteric sensitivity ranking matches @Risk (top 5 identical). ✓",
    "C4 — MM CH₄ tornado: MCF values rank high in @Risk but not in tool.",
    "C5 — MM Direct N₂O: EF3 influential in @Risk but not tool. FRAC_LEACH_H shouldn't appear.",
    "C6 — MM Indirect N₂O: Fracleach/Fracgas don't appear in top variables (surprising given large uncertainty).",
    "C7 — Direct N₂O pasture: Fracgasms appears but is NOT a parameter in direct PRP equations.",
    "C8 — Indirect PRP N₂O: FRAC_LEACH_H appears but is not a PRP parameter.",
    "C9 — Excel download doesn't work.",
    "C10 — CSV: emission category in column A; separate pasture direct/indirect; user-defined aggregation.",
    "C11 — Word report: rebuild per mock-up with executive summary and per-source AD/EF tables.",
    "C12 — Word Section 7: 'column J' reference — confirm IPCC context."
  ),
  status = c("Done","Done","Noted","Partial","Done","Partial","Done","Done","Done","Done","Done","Done"),
  detail = c(
    "Four IPCC-source value-boxes now replace Total CH₄/N₂O: Enteric CH₄, Manure CH₄, Manure N₂O (direct+indirect), Pasture N₂O (direct+indirect). Total CO₂eq / MoE / CV moved to inline footnote.",
    "See B32 — Aggregation level dropdown defaults to cattle_type; drill-down to aggregation_level or sub_category available.",
    "No change needed — confirmed the enteric pathway is correctly wired.",
    "Dirichlet removal (now MMS% is deterministic) and N-excretion fix are the upstream changes. MCF ranking gap likely due to Dirichlet-vs-fixed-MMS% difference. Pending Zimbabwe re-run by Andreas (E2).",
    "Zero-variance output guard removes FRAC_LEACH_H spurious ranking (SRC on constant PRP output). EF3 ranking gap: same Dirichlet effect as C4 — pending E2.",
    "Now that PRP and MM Frac params are separate (#10 / Frac_LEACH_PRP), the MM-side Frac_GASMS/Frac_LEACH_H are no longer shared with PRP sampler. Re-run expected to surface these. Pending E2.",
    "Same zero-variance guard as C5 — intensive dairy with pct_pasture=0 → constant PRP direct N₂O → tornado now shows explanatory message.",
    "PRP indirect now uses Frac_LEACH_PRP (Table 11.3) not Frac_LEACH_H (Table 10.22). Confirmed by code fix in calc_manure_n2o.R. Re-run needed to verify tornado shows correct parameter (E2).",
    "See B38 — export_results_xlsx() hardened.",
    "CSV has emission_category (col A), unit (col B). Pasture direct/indirect as separate rows with IPCC codes. User-defined aggregation: CSV always shows inventory-aggregate rows; Results tab tables respect cattle_type / aggregation_level / sub_category dropdown.",
    "Two new flextables added after Word Executive Summary: 'Activity-data uncertainty' and 'Emission-factor uncertainty', each with one row per IPCC source and CV%. Rendered only when AD/EF decomposition was run.",
    "'Column J' reference removed from Section 7. New wording describes the metric and asks user to cross-check column letter against their national submission template."
  ),
  stringsAsFactors = FALSE
)

# VTT call — additional items not in written review
sVTT <- data.frame(
  ref = c("VTT-A1","VTT-A2","VTT-B1","VTT-B2","VTT-B3","VTT-B4","VTT-C1","VTT-C2","VTT-D1","VTT-D2","VTT-D3"),
  section = "Call (2026-05-19)",
  comment = c(
    "Warning modal still shows 'Uganda' when loading hypothetical example dataset [~05:12].",
    "QA/QC Info benchmarks: replace Monni/Penman with IPCC 2006/2019 for EF3, EF3_S, EF4, EF5, Frac_GASF, Frac_LEACH only [~01:45].",
    "Tornado: show sub-category level labels — user needs to know if Ym for cows vs heifers is most sensitive [~07:00].",
    "Word download incomplete — not everything shown on screen appears in downloads [~10:50]. Make Word the full comprehensive version.",
    "Logos needed — Alliance Bioversity-CIAT, CGIAR, funder (GMH/Windward to confirm at June 22 meeting) [~12:22].",
    "Add link from Home page to Resources page [~19:32].",
    "CV% IPCC annex table reference: Andreas unsure of the source cited in app — needs verification before IPCC expert review [~09:30].",
    "C1 (IPCC table metric): app reported CV% but IPCC Table 3.3 uses MoE% (half-width of 95% CI / mean × 100) [call + written].",
    "User guide needed before beta testing: step-by-step input prep; distribution options; QA/QC warning meanings; IPCC uncertainty reporting [~15:36–21:00].",
    "Expert review package to include: working app link, methodology PDF, user guide, example dataset, feedback form, cover email [~09:54–10:13, ~32:37].",
    "Beta-testing feedback form: Excel table with Type (Bug/Correction/Enhancement/General), Severity, Tab, Description, Reviewer name [~31:10]."
  ),
  status = c("Done","Pending","Done","Pending","Done","Done","Done","Done","Done","Pending","Done"),
  detail = c(
    "Modal dialog now shows 'Country X' (or 'Country Y') instead of tools::toTitleCase(input$country). Internal function names (generate_uganda_example) unchanged — not user-visible.",
    "Plan item A2: in QAQC Info-severity panel, replace Monni-2007/Penman-2000 benchmark values and source attribution for EF3, EF3_S, EF4, EF5, Frac_GASF, Frac_LEACH with IPCC 2019 Refinement Ch.11 documented ranges. Do NOT change Ym/VS/Bo/MCF benchmarks. Estimated 2–3 hours.",
    ".aggregate_sensitivity() rewritten: column names now prefixed 'cattle_type | sub_category – parameter' (e.g. 'dairy | lactating cows – Ym'). Both single-group and multi-group paths use the same label_samples() helper.",
    "Plan item B2: add sensitivity tornado (static image or table), convergence diagnostics summary, and per-sub-category results table to Word download. Estimated 2–3 hours.",
    "Logo bar added to Home page (see B16 above). Actual PNG files not yet present in www/ — fallback text shown. GMH/Windward funder logo and attribution text blocked on June 22 Hayden meeting (E1).",
    "actionButton('goto_resources') added on Home page. observeEvent in server navigates to Resources tab using bslib::nav_select(). One-line UI change.",
    "Verified: IPCC 2006 Vol 1 Ch 3 Table 3.3 uses MoE% (half-width of 95% CI / mean × 100), not CV%. Both are computed in mc_uncertainty.R as cv_pct and moe_pct. Fix: format_ipcc_table() in utils_export.R now reads moe_pct instead of cv_pct. UI info text in IPCC Report tab updated to say '% uncertainty (half-width of the 95% CI ÷ mean × 100)'.",
    "See VTT-C1 — same fix.",
    "user_guide_draft.md created (~650 lines, 11 sections + 2 appendices). Covers all app tabs, IPCC reporting conventions, distribution choices, QA/QC warning meanings, worked example with Country X. Sent to Andreas for reframing at right technical level for inventory practitioners.",
    "Package contents: (1) app link ✓, (2) methodology PDF ✓, (3) user guide (draft sent, D1), (4) example dataset ✓, (5) feedback form ✓ (D3), (6) cover email — Andreas to draft. Plan item D2.",
    "beta_feedback_template.xlsx created using openxlsx (_make_feedback_template.R). Three sheets: Instructions, Feedback (dropdown validation for Type/Severity/Tab, frozen header, alternating fill), Type_definitions. Beta CSV backup also saved."
  ),
  stringsAsFactors = FALSE
)

# BLOCKED / EXTERNAL items
sE <- data.frame(
  ref = paste0("E", 1:8),
  section = "Blocked on external",
  comment = c(
    "Funder logo + attribution text (GMH / Windward Fund).",
    "Andreas to re-run Zimbabwe with N₂O fix and confirm C4/C5/C6 sensitivity rankings resolved.",
    "W → BW canonical rename across catalogue, UI, and example templates.",
    "Zimbabwe Milk convention: per-lactating-animal or sub-category-average?",
    "@Risk run type for A1/A2 comparison: AD+EF or EF-only?",
    "National inventory case-study links (NZ and others) for Resources page.",
    "Repo migration from IRRI GitHub to CIAT/CGIAR org.",
    "Workshop dates and budget."
  ),
  status = rep("Blocked", 8),
  detail = c(
    "June 22 inception meeting with Hayden (GMH/Windward Fund). Logo placeholder text displayed in app until file received.",
    "Andreas's action item. Re-run expected to surface Frac_LEACH_PRP in MM-indirect tornado and confirm MCF/EF3 rankings.",
    "BW alias already added to PARAM_ALIASES. Full rename deferred pending Andreas sign-off.",
    "Convention determines whether pct_lactating×Milk or sub-category-avg Milk is the correct input. Catalogue note added explaining per-lactating-animal convention.",
    "Determines rShiny comparison run type (no correlations + N fixed = EF-only).",
    "Andreas to compile and share. Placeholder bullet reserved in Resources page 'Case studies' section.",
    "Lolita to discuss with Hannah / use CIAT org. Not blocking tool functionality.",
    "Andreas to replan. Lolita noted 17–18 and 22–23 June planned as off."
  ),
  stringsAsFactors = FALSE
)

# ── BUILD DOCUMENT ────────────────────────────────────────────────────────────
doc <- read_docx() |>
  body_add_par("Andreas Wilkes Review — Final Comments Tracker", style = "heading 1") |>
  body_add_par(paste("Generated:", format(Sys.Date(), "%Y-%m-%d"), "| Source: AW_review_response_v5h.md + call transcript 2026-05-19"), style = "Normal") |>
  body_add_par("Status key: Done = fully implemented and deployed  |  Partial = partially addressed, remainder queued  |  Pending = not yet started  |  Blocked = waiting on external input  |  Noted = no action required", style = "Normal") |>
  body_add_par("", style = "Normal")

add_section <- function(doc, section_data, heading) {
  result <- make_table(section_data, heading)
  doc <- body_add_par(doc, heading, style = "heading 2") |>
    body_add_flextable(result$ft) |>
    body_add_par("", style = "Normal")
  doc
}

doc <- add_section(doc, sA,       "A — Major calculation issues (N₂O)")
doc <- add_section(doc, sB_home,  "B — Home page")
doc <- add_section(doc, sB_def,   "B — Definitions page")
doc <- add_section(doc, sB_res,   "B — Resources page")
doc <- add_section(doc, sB_di,    "B — Data Input page")
doc <- add_section(doc, sB_qaqc,  "B — QA/QC page")
doc <- add_section(doc, sB_unc,   "B — Uncertainty page")
doc <- add_section(doc, sB_sim,   "B — Simulate & Results page")
doc <- add_section(doc, sB_sens,  "B — Sensitivity page")
doc <- add_section(doc, sB_rep,   "B — IPCC Reports & Downloads")
doc <- add_section(doc, sC,       "C — Pilot test-run feedback")
doc <- add_section(doc, sVTT,     "Call 2026-05-19 — Additional items")
doc <- add_section(doc, sE,       "Blocked on external input")

# Summary statistics
n_done    <- sum(sapply(list(sA,sB_home,sB_def,sB_res,sB_di,sB_qaqc,sB_unc,sB_sim,sB_sens,sB_rep,sC,sVTT,sE), function(d) sum(d$status == "Done")))
n_partial <- sum(sapply(list(sA,sB_home,sB_def,sB_res,sB_di,sB_qaqc,sB_unc,sB_sim,sB_sens,sB_rep,sC,sVTT,sE), function(d) sum(d$status == "Partial")))
n_pending <- sum(sapply(list(sA,sB_home,sB_def,sB_res,sB_di,sB_qaqc,sB_unc,sB_sim,sB_sens,sB_rep,sC,sVTT,sE), function(d) sum(d$status == "Pending")))
n_blocked <- sum(sapply(list(sA,sB_home,sB_def,sB_res,sB_di,sB_qaqc,sB_unc,sB_sim,sB_sens,sB_rep,sC,sVTT,sE), function(d) sum(d$status == "Blocked")))
n_noted   <- sum(sapply(list(sA,sB_home,sB_def,sB_res,sB_di,sB_qaqc,sB_unc,sB_sim,sB_sens,sB_rep,sC,sVTT,sE), function(d) sum(d$status == "Noted")))
n_total   <- n_done + n_partial + n_pending + n_blocked + n_noted

summary_df <- data.frame(
  Status  = c("Done", "Partial", "Pending", "Blocked (external)", "Noted (no action)","TOTAL"),
  Count   = c(n_done, n_partial, n_pending, n_blocked, n_noted, n_total),
  stringsAsFactors = FALSE
)

summary_ft <- flextable(summary_df) |>
  width(j = "Status", width = 2) |>
  width(j = "Count",  width = 1) |>
  bold(j = "Count") |>
  bold(i = nrow(summary_df)) |>
  bg(i = 1, bg = COL_DONE) |>
  bg(i = 2, bg = COL_PARTIAL) |>
  bg(i = 3, bg = COL_PENDING) |>
  bg(i = 4, bg = COL_BLOCKED) |>
  bg(i = 5, bg = COL_NOTED) |>
  fontsize(size = 10) |>
  font(fontname = "Calibri", part = "all") |>
  theme_booktabs()

doc <- body_add_par(doc, "Summary", style = "heading 2") |>
  body_add_flextable(summary_ft)

outfile <- "AW_final_comments_tracker.docx"
print(doc, target = outfile)
cat("Saved:", outfile, "\n")
cat(sprintf("Done: %d | Partial: %d | Pending: %d | Blocked: %d | Noted: %d | Total: %d\n",
            n_done, n_partial, n_pending, n_blocked, n_noted, n_total))
