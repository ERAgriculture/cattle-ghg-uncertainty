# =============================================================================
# Excel Input Template — openxlsx version with dropdown menus
# =============================================================================
# Sheets produced:
#   _Lists            (hidden)  — raw lists that power dropdown validation
#   README                      — colour legend + quick-start
#   Inventory_Metadata          — dropdowns for species/climate/GWP/version
#   Parameters                  — pre-populated 22-row block per sub-category,
#                                  dropdowns, auto-fill formulas for lower/upper
#   Manure_Management           — dropdown for mms_type
#   Parameter_TimeSeries        — year-by-parameter grid for correlation estimation
#   Vocab                       — parameter catalogue + all controlled terms
# =============================================================================

# Safe-default operator (used in parse_uploaded_template)
`%||%` <- function(a, b)
  if (is.null(a) || length(a) == 0 || is.na(a[1]) || !nzchar(as.character(a[1]))) b else a

# ---------------------------------------------------------------------------
# PARAMETER CATALOGUE  (central source of truth for the Vocab sheet and
#                        for pre-populating the Parameters sheet)
# ---------------------------------------------------------------------------
PARAM_CATALOGUE <- data.frame(
  parameter = c(
    "cattle_pop","live_weight","mature_weight","weight_gain",
    "milk_yield","milk_fat","pct_lactating","DE_pct",
    "Cfi","Ca","C_growth","Cp","hours","CP_pct",
    "Ym_pct","Bo","ash","UE",
    "EF3_PRP","Frac_GASM","EF4","EF5","Frac_LEACH",
    "protein_milk"),
  definition = c(
    "Number of animals in this sub-category",
    "Average live body weight of the animals",
    "Mature (adult) body weight of the animals",
    "Average daily weight gain — set 0 for non-growing (adult) animals",
    "Daily milk yield per lactating cow — set 0 for non-dairy sub-categories",
    "Milk fat content of the diet",
    "Fraction of cows currently lactating (0 to 1)",
    "Digestible energy as a percentage of gross energy — typical range 45-75%",
    "Maintenance energy coefficient — depends on sex and lactation status (IPCC Table 10.4)",
    "Activity coefficient for locomotion energy — depends on feeding situation (IPCC Table 10.5)",
    "Growth coefficient for the NEg equation — depends on sex (IPCC Eq 10.6)",
    "Pregnancy coefficient — 0.10 for pregnant animals (IPCC Table 10.7)",
    "Daily working hours for draft animals — set 0 for non-draft",
    "Crude protein content of the diet — used to estimate nitrogen excretion",
    "Methane conversion factor: % of gross energy converted to enteric CH4 (IPCC Table 10.12)",
    "Maximum CH4 producing capacity of manure (IPCC Table 10.16)",
    "Ash content of manure — IPCC default 0.08 (Eq 10.24 footnote)",
    "Urinary energy as fraction of gross energy — IPCC default 0.04 (Eq 10.24 footnote)",
    "N2O emission factor for dung/urine deposited on pasture (IPCC Table 11.1)",
    "Fraction of managed manure N volatilised as NH3/NOx (IPCC Table 10.22)",
    "N2O EF for atmospheric N deposition — global default 0.010 (IPCC Table 11.3)",
    "N2O EF for N leaching/runoff — global default 0.0075 (IPCC Table 11.3)",
    "Fraction of managed N lost through leaching — IPCC default 0.02",
    "Protein content of milk — required for IPCC 2019 nitrogen excretion (Eq 10.32A)"),
  unit = c(
    "head","kg","kg","kg/day","kg/head/day","%","fraction (0-1)","%",
    "MJ/day/kg^0.75","dimensionless","dimensionless","dimensionless",
    "hours/day","%",
    "%","m3 CH4/kg VS","fraction","fraction",
    "kg N2O-N/kg N","fraction","kg N2O-N/kg N","kg N2O-N/kg N","fraction",
    "%"),
  ipcc_default = c(
    NA, 275, 300, 0.0, 4.0, 4.0, 0.60, 55.0,
    0.386, 0.17, 0.8, 0.10, 0.0, 10.0,
    6.5, 0.10, 0.08, 0.04,
    0.02, 0.20, 0.010, 0.0075, 0.02,
    3.3),
  # Uncertainty % per Penman et al. (2000) / Monni et al. (2007).
  # NA = asymmetric: use suggested_lower_bound / suggested_upper_bound instead.
  suggested_uncertainty_pct = c(
    10, 15, 10, 30, 20, 10, 20, 15,   # cattle_pop..DE_pct
    30, 30, 30, 10, 20, 15,            # Cfi, Ca, C_growth, Cp, hours, CP_pct
    8, 20, 25, 25,                     # Ym_pct, Bo, ash, UE
    NA, 40, NA, NA, NA,               # EF3_PRP, Frac_GASM, EF4, EF5, Frac_LEACH (asymmetric — use bounds)
    10),
  suggested_distribution = c(
    "normal","normal","normal","pert","normal","normal","beta","normal",
    "pert","triangular","triangular","beta","pert","normal",
    "pert","pert","pert","pert",
    "pert","pert","lognormal","lognormal","lognormal",
    "normal"),
  # Absolute lower/upper bounds for asymmetric parameters (Monni et al. 2007 / IPCC GPG).
  # These override the symmetric ±pct formula in the Excel template.
  suggested_lower_bound = c(
    NA, NA, NA, NA, NA, NA, NA, NA,
    NA, NA, NA, NA, NA, NA,
    NA, NA, NA, NA,
    0.003, NA, 0.0043, 0.0015, 0.006,  # EF3(-85%), EF4(-57%), EF5(-80%), Frac_LEACH(-70%)
    NA),
  suggested_upper_bound = c(
    NA, NA, NA, NA, NA, NA, NA, NA,
    NA, NA, NA, NA, NA, NA,
    NA, NA, NA, NA,
    0.040, NA, 0.020, 0.0225, 0.054,   # EF3(+100%), EF4(+100%), EF5(+200%), Frac_LEACH(+170%)
    NA),
  param_type = c(
    rep("activity_data", 14), rep("emission_factor", 9), "activity_data"),
  # "core" = must be entered by user; "technical" = IPCC coefficient, pre-filled with default
  param_tier = c(
    "core","core","core","core","core","core","core","core",
    "technical","technical","technical","technical","core","core",
    "technical","technical","technical","technical",
    "technical","technical","technical","technical","technical",
    "core"),
  # TRUE = user can reduce this uncertainty by improving local data/surveys;
  # FALSE = IPCC coefficient — requires dedicated measurement research to improve
  user_reducible = c(
    TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,
    FALSE, FALSE, FALSE, FALSE, TRUE, TRUE,
    FALSE, FALSE, FALSE, FALSE,
    FALSE, FALSE, FALSE, FALSE, FALSE,
    TRUE),
  ipcc_ref = c(
    "","Table 10A.2","Table 10A.2","Table 10A.1","","","","Table 10.2",
    "Table 10.4","Table 10.5","Eq 10.6","Table 10.7","Eq 10.11","",
    "Table 10.12","Table 10.16","Eq 10.24","Eq 10.24",
    "Table 11.1","Table 10.22","Table 11.3","Table 11.3","Table 11.3",
    "Table 10A.2"),
  stringsAsFactors = FALSE
)


# ---------------------------------------------------------------------------
# MAIN ENTRY POINT
# ---------------------------------------------------------------------------
generate_template <- function(filepath, include_example = FALSE) {
  if (requireNamespace("openxlsx", quietly = TRUE)) {
    generate_template_openxlsx(filepath, include_example)
  } else {
    message("Package 'openxlsx' not found — install it for dropdown menus:\n",
            "  install.packages('openxlsx')\n",
            "Falling back to basic template (no dropdowns).")
    generate_template_basic(filepath, include_example)
  }
  invisible(filepath)
}


# ===========================================================================
# OPENXLSX VERSION — full dropdowns, formulas, colour-coding
# ===========================================================================
generate_template_openxlsx <- function(filepath, include_example) {

  wb <- openxlsx::createWorkbook()
  openxlsx::modifyBaseFont(wb, fontName = "Calibri", fontSize = 10)

  # ── colour palette ─────────────────────────────────────────────────────────
  C_HEADER     <- "#1B4332"   # dark green  — column headers
  C_SECTION    <- "#2D6A4F"   # mid green   — section labels
  C_REQUIRED   <- "#FFF9C4"   # pale yellow — cells user MUST fill (core activity data)
  C_TECHNICAL  <- "#FFF3E0"   # pale orange — IPCC coefficient pre-filled, editable
  C_DROPDOWN   <- "#E8F5E9"   # pale green  — controlled-vocab dropdowns
  C_PREFILL    <- "#E3F2FD"   # pale blue   — pre-filled info (read only)
  C_AUTO       <- "#F5F5F5"   # light grey  — auto-computed formulas
  C_OPTIONAL   <- "#FFFFFF"   # white       — optional free-text
  C_GREY_TXT   <- "#6B6B6B"
  C_RED        <- "#C62828"   # for required labels

  # ── styles ─────────────────────────────────────────────────────────────────
  mk <- openxlsx::createStyle  # shortcut

  s_hdr  <- mk(fontColour="white", fgFill=C_HEADER, fontName="Calibri",
                fontSize=10, textDecoration="bold", halign="center",
                valign="center", wrapText=TRUE,
                border="TopBottomLeftRight", borderColour="#2D6A4F")
  s_req  <- mk(fgFill=C_REQUIRED, fontName="Calibri", fontSize=10,
                border="TopBottomLeftRight", borderColour="#BBBBBB",
                halign="left", valign="top")
  s_drop <- mk(fgFill=C_DROPDOWN, fontName="Calibri", fontSize=10,
                border="TopBottomLeftRight", borderColour="#BBBBBB",
                halign="left", valign="top")
  s_pre  <- mk(fgFill=C_PREFILL, fontColour="#1565C0", fontName="Calibri",
                fontSize=9, border="TopBottomLeftRight", borderColour="#BBBBBB",
                halign="left", valign="top")
  s_auto <- mk(fgFill=C_AUTO, fontColour=C_GREY_TXT, fontName="Calibri",
                fontSize=9, border="TopBottomLeftRight", borderColour="#DDDDDD",
                halign="left", valign="top")
  s_opt  <- mk(fgFill=C_OPTIONAL, fontName="Calibri", fontSize=10,
                border="TopBottomLeftRight", borderColour="#BBBBBB",
                halign="left", valign="top")
  s_sec  <- mk(fontColour="white", fgFill=C_SECTION, fontName="Calibri",
                fontSize=10, textDecoration="bold", halign="left", valign="center")
  s_lbl  <- mk(fontName="Calibri", fontSize=9, textDecoration="bold",
                halign="right", valign="center", fontColour=C_GREY_TXT)
  s_note <- mk(fontName="Calibri", fontSize=8, fontColour=C_GREY_TXT,
                textDecoration="italic", halign="left", valign="top",
                wrapText=TRUE)
  s_bold <- mk(fontName="Calibri", fontSize=10, textDecoration="bold",
                halign="left", valign="center")
  s_num  <- mk(fgFill=C_REQUIRED, fontName="Calibri", fontSize=10,
                border="TopBottomLeftRight", borderColour="#BBBBBB",
                halign="right", valign="top", numFmt="0.0000")
  s_tech <- mk(fgFill=C_TECHNICAL, fontName="Calibri", fontSize=10,
                border="TopBottomLeftRight", borderColour="#BBBBBB",
                halign="left", valign="top")

  # helper ─────────────────────────────────────────────────────────────────
  add_validation <- function(sheet, col, rows, list_key) {
    # Use cell-range reference — produces standard <dataValidation> with visible arrows
    ref <- list_ref(list_key)
    openxlsx::dataValidation(wb, sheet, col = col, rows = rows,
                             type = "list", operator = "equal", value = ref,
                             showInputMsg = TRUE, showErrorMsg = TRUE)
  }

  apply_style <- function(sheet, style, rows, cols) {
    openxlsx::addStyle(wb, sheet, style = style, rows = rows, cols = cols,
                       gridExpand = TRUE, stack = FALSE)
  }

  # ── vocabulary lists (used by multiple sheets) ────────────────────────────
  V_SPECIES   <- c("cattle_dairy","cattle_non_dairy","buffalo")
  V_IPCCVER   <- c("2006","2019_refinement")
  V_DIST      <- c("normal","posnorm","lognormal","beta",
                   "triangular","pert","uniform","constant","tnorm_0_1")
  V_PTYPE     <- c("activity_data","emission_factor")
  V_QUALITY   <- c("measured","country_specific","regional_default",
                   "ipcc_default","expert_judgement")
  V_MMS       <- c("pasture","daily_spread","solid_storage","dry_lot",
                   "deep_bedding","liquid_slurry","composting","lagoon")

  # Kept for Vocab reference tables (informational, no longer used as dropdowns)
  V_SUBSYS    <- c("dairy_cows","other_cows","bulls","oxen",
                   "heifers","growing_males","calves_female","calves_male",
                   "feedlot_cattle")
  V_FEED      <- c("stall_fed","pasture_flat","pasture_hilly")

  N_DATA_ROWS <- 200   # rows to apply formatting/validation in Parameters

  # ── Named vocabulary lists (order defines column index in _Lists) ──────────
  # Each list becomes one column; add_validation references these ranges.
  V_LISTS <- list(
    ipccver = V_IPCCVER,  # col A
    dist    = V_DIST,     # col B
    ptype   = V_PTYPE,    # col C
    quality = V_QUALITY,  # col D
    mms     = V_MMS,      # col E
    species = V_SPECIES   # col F
  )

  # Helper: return Excel range string for a named list
  list_ref <- function(key) {
    idx <- which(names(V_LISTS) == key)
    col_letter <- LETTERS[idx]
    n <- length(V_LISTS[[key]])
    sprintf("'_Lists'!$%s$2:$%s$%d", col_letter, col_letter, n + 1)
  }

  # =========================================================================
  # SHEET: _Lists (hidden — vocabulary columns for Excel dropdown validation)
  # =========================================================================
  openxlsx::addWorksheet(wb, "_Lists", visible = FALSE)

  # Write each vocabulary list as a column (row 1 = header, rows 2+ = values)
  for (i in seq_along(V_LISTS)) {
    key <- names(V_LISTS)[i]
    vals <- V_LISTS[[i]]
    openxlsx::writeData(wb, "_Lists",
                        data.frame(x = c(key, vals), stringsAsFactors = FALSE),
                        startRow = 1, startCol = i, colNames = FALSE)
  }

  # Sub-category property lookup (used by Vocab) — placed after vocabulary cols
  lut_start_col <- length(V_LISTS) + 2   # leave a gap
  subcat_lut <- data.frame(
    subsystem  = V_SUBSYS,
    sex        = unlist(SEX_BY_SUBCAT[V_SUBSYS]),
    age_class  = unlist(AGE_BY_SUBCAT[V_SUBSYS]),
    Cfi        = unlist(CFI_BY_SUBCAT[V_SUBSYS]),
    LW_default = unlist(LW_BY_SUBCAT[V_SUBSYS]),
    MW_default = unlist(MW_BY_SUBCAT[V_SUBSYS]),
    WG_default = unlist(WG_BY_SUBCAT[V_SUBSYS]),
    C_growth   = unlist(C_GROWTH_BY_SUBCAT[V_SUBSYS]),
    stringsAsFactors = FALSE
  )
  openxlsx::writeData(wb, "_Lists", subcat_lut, startRow = 1, startCol = lut_start_col)

  # MCF lookup (used by Vocab)
  openxlsx::writeData(wb, "_Lists", MMS_DEFAULTS,
                      startRow = 1, startCol = lut_start_col + ncol(subcat_lut) + 1)

  # =========================================================================
  # SHEET: README
  # =========================================================================
  openxlsx::addWorksheet(wb, "README", tabColour = "#2D6A4F", gridLines = FALSE)
  openxlsx::setColWidths(wb, "README", cols = 1:3, widths = c(6, 28, 70))

  readme_title <- data.frame(
    x = "Cattle GHG Uncertainty Calculator — Input Template",
    stringsAsFactors = FALSE)
  openxlsx::writeData(wb, "README", readme_title, startRow = 1, startCol = 1,
                      colNames = FALSE)
  apply_style("README", mk(fontColour="white", fgFill=C_HEADER, fontSize=16,
                            textDecoration="bold", halign="left", valign="center"),
              rows=1, cols=1:3)
  openxlsx::mergeCells(wb, "README", cols=1:3, rows=1)
  openxlsx::setRowHeights(wb, "README", rows=1, heights=36)

  legend <- data.frame(
    Colour = c("Pale yellow","Pale green","Pale blue","Light grey","White"),
    Meaning = c(
      "REQUIRED — you must fill this in",
      "CONTROLLED — choose from the dropdown list",
      "PRE-FILLED — read the value, keep or override (emission factors pre-filled with IPCC defaults)",
      "AUTO-COMPUTED — calculated from your inputs, do not edit",
      "OPTIONAL — free text or leave blank (white lower_bound/upper_bound columns override the symmetric auto-computed bounds for asymmetric distributions)"),
    stringsAsFactors = FALSE)
  openxlsx::writeData(wb, "README", legend, startRow = 3, startCol = 1,
                      colNames = TRUE)
  apply_style("README", s_hdr,  rows=3, cols=1:2)
  apply_style("README", s_req,  rows=4, cols=1:2)
  apply_style("README", s_drop, rows=5, cols=1:2)
  apply_style("README", s_pre,  rows=6, cols=1:2)
  apply_style("README", s_auto, rows=7, cols=1:2)
  apply_style("README", s_opt,  rows=8, cols=1:2)

  steps <- data.frame(
    Step = paste0("Step ", 1:7),
    Action = c(
      "Fill in the Inventory_Metadata sheet (country, species, inventory year). Note: MCF values for manure must be entered manually in Manure_Management — see Vocab sheet for IPCC Table 10.17 reference values by climate zone.",
      "In the Parameters sheet, fill in cattle_type (col A: 'dairy' or 'other'), aggregation_level (col B: your region/AEZ/system name), and optionally sub_category (col C: cows/heifers/calves/etc.).",
      "Fill in the VALUE (col G) for each parameter. Emission factor parameters (Cfi, Ym, Bo, etc.) are pre-filled with IPCC defaults — update with your own values if available.",
      "Fill in UNCERTAINTY_PCT (col H) for symmetric distributions — LOWER and UPPER bounds auto-compute. For asymmetric distributions (triangular/PERT): also fill LOWER_BOUND (col I) and UPPER_BOUND (col J) with the min/max values.",
      "To add a second sub-category: copy the parameter rows, paste below, change cattle_type/aggregation_level/sub_category.",
      "Fill in the Manure_Management sheet: one row per MMS type per sub-category. Enter MCF and EF3 values (look up IPCC Table 10.17 and 10.21 in the Vocab sheet). Fractions must sum to 100% per sub-category.",
      "Optionally fill in the Parameter_TimeSeries sheet with historical annual values (one row per year, one column per parameter) to enable automatic activity data correlation analysis."),
    stringsAsFactors = FALSE)
  openxlsx::writeData(wb, "README", steps, startRow = 10, startCol = 1,
                      colNames = TRUE)
  apply_style("README", s_hdr,  rows=10, cols=1:2)
  apply_style("README", s_bold, rows=11:17, cols=1)
  apply_style("README", s_note, rows=11:17, cols=2)
  openxlsx::setColWidths(wb, "README", cols = 1:2, widths = c(10, 90))
  openxlsx::setRowHeights(wb, "README", rows=11:17, heights=30)

  sheets_desc <- data.frame(
    Sheet = c("Inventory_Metadata","Parameters","Manure_Management",
              "Parameter_TimeSeries","Vocab"),
    Description = c(
      "Country, reporting year, species, IPCC guidelines version.",
      "All parameters for each animal sub-category. 3 user-defined naming columns (cattle_type, aggregation_level, sub_category). Emission factors pre-filled with IPCC defaults. Supports symmetric (uncertainty_pct) and asymmetric (lower_bound, upper_bound) distributions.",
      "Manure management system allocation. Enter MCF and EF3 values manually (see Vocab for IPCC reference tables). Fractions must sum to 100 per sub-category. Full distribution support for MCF and EF3.",
      "CORRELATIONS — one row per year, one column per activity data parameter. Fill in historical values; the app computes a Pearson correlation matrix automatically on upload (Tab 4). You only need columns you have data for.",
      "Parameter catalogue + IPCC MCF reference table (Table 10.17) + controlled vocabulary terms and definitions."),
    stringsAsFactors = FALSE)
  openxlsx::writeData(wb, "README", sheets_desc, startRow = 20, startCol = 1,
                      colNames = TRUE)
  apply_style("README", s_hdr,  rows=20, cols=1:2)
  apply_style("README", s_note, rows=21:25, cols=1:2)

  # =========================================================================
  # SHEET: Inventory_Metadata
  # =========================================================================
  openxlsx::addWorksheet(wb, "Inventory_Metadata", tabColour = "#2D6A4F",
                         gridLines = FALSE)
  openxlsx::setColWidths(wb, "Inventory_Metadata",
                         cols = 1:4, widths = c(4, 24, 36, 60))
  openxlsx::setRowHeights(wb, "Inventory_Metadata",
                          rows = 1:8, heights = 24)

  # Write as label-value pairs (transposed layout — more readable)
  meta_fields <- list(
    list(label="Country / region",         col="country",       req=TRUE,
         hint="Free text, e.g. Uganda or Zimbabwe-Highveld",      dropdown=NULL),
    list(label="Inventory year",           col="inventory_year",req=TRUE,
         hint="Integer year, e.g. 2021",                          dropdown=NULL),
    list(label="Livestock species",        col="species",       req=TRUE,
         hint="Select from dropdown",                             dropdown="species"),
    list(label="IPCC Guidelines version", col="ipcc_version",  req=FALSE,
         hint="Select from dropdown — defaults to 2006",          dropdown="ipccver"),
    list(label="Prepared by",             col="prepared_by",   req=FALSE,
         hint="Agency / author name",                             dropdown=NULL),
    list(label="Notes",                   col="notes",         req=FALSE,
         hint="Scope, caveats, deviations from standard methodology. Note: MCF values for manure must be entered manually in Manure_Management — see Vocab sheet for IPCC Table 10.17 reference.", dropdown=NULL)
  )

  # Column headers
  openxlsx::writeData(wb, "Inventory_Metadata",
    data.frame(A="", B="Field", C="Value", D="Hint / valid options"),
    startRow=1, startCol=1, colNames=FALSE)
  apply_style("Inventory_Metadata", s_hdr, rows=1, cols=1:4)

  example_vals <- list(
    country="Uganda", inventory_year=2021, species="cattle_non_dairy",
    ipcc_version="2006",
    prepared_by="MAAIF Uganda",
    notes="Example inventory — Uganda pastoral system")

  for (i in seq_along(meta_fields)) {
    f <- meta_fields[[i]]
    row_i <- i + 1
    # Column B: label
    openxlsx::writeData(wb, "Inventory_Metadata",
                        f$label, startRow=row_i, startCol=2, colNames=FALSE)
    apply_style("Inventory_Metadata", s_lbl, rows=row_i, cols=2)

    # Column C: value (required=yellow, optional=white)
    val <- if (include_example) example_vals[[f$col]] else ""
    openxlsx::writeData(wb, "Inventory_Metadata",
                        val, startRow=row_i, startCol=3, colNames=FALSE)
    apply_style("Inventory_Metadata",
                if (f$req) s_req else s_opt, rows=row_i, cols=3)

    # Column D: hint
    openxlsx::writeData(wb, "Inventory_Metadata",
                        f$hint, startRow=row_i, startCol=4, colNames=FALSE)
    apply_style("Inventory_Metadata", s_note, rows=row_i, cols=4)

    # Dropdown validation on column C
    if (!is.null(f$dropdown))
      add_validation("Inventory_Metadata", col=3, rows=row_i, f$dropdown)
  }

  openxlsx::freezePane(wb, "Inventory_Metadata", firstRow=TRUE)


  # =========================================================================
  # SHEET: Parameters
  # =========================================================================
  openxlsx::addWorksheet(wb, "Parameters", tabColour = "#1B4332",
                         gridLines = TRUE)

  # Column layout (17 cols):
  # A  cattle_type      (required, free text: "dairy" / "other")
  # B  aggregation_level (required, free text: region/AEZ/production system)
  # C  sub_category     (optional, free text: cows/heifers/calves)
  # D  parameter        (pre-filled, info)
  # E  definition       (pre-filled, info)
  # F  unit             (pre-filled, info)
  # G  value            *** REQUIRED USER INPUT ***
  # H  uncertainty_pct  (yellow — fill for symmetric distributions)
  # I  lower_bound      (optional override — min value for asymmetric distributions)
  # J  upper_bound      (optional override — max value for asymmetric distributions)
  # K  distribution     (dropdown)
  # L  lower            (auto-formula: uses lower_bound if filled, else value*(1-pct/100))
  # M  upper            (auto-formula: uses upper_bound if filled, else value*(1+pct/100))
  # N  param_type       (pre-filled, info)
  # O  ipcc_ref         (pre-filled, info)
  # P  data_source      (optional, free text)
  # Q  data_quality     (dropdown, optional)

  P_COLS <- c("cattle_type","aggregation_level","sub_category",
              "parameter","definition","unit",
              "value","uncertainty_pct","lower_bound","upper_bound",
              "distribution","lower","upper",
              "param_type","ipcc_ref","data_source","data_quality")
  P_WIDTHS <- c(14, 20, 16, 15, 46, 16, 10, 14, 12, 12, 12, 10, 10, 14, 12, 22, 18)
  P_COL_IDX <- setNames(seq_along(P_COLS), P_COLS)

  openxlsx::setColWidths(wb, "Parameters", cols = seq_along(P_COLS), widths = P_WIDTHS)

  # Row 1: instruction banner
  openxlsx::writeData(wb, "Parameters",
    "HOW TO USE: YELLOW = core activity data — enter your own values. ORANGE = technical IPCC coefficient — pre-filled with defaults from Penman et al. (2000); uncertainty ranges from Penman (2000) / Monni et al. (2007); edit if you have country-specific values. GREEN = dropdown. BLUE = pre-filled info. GREY = auto-computed. For symmetric distributions: fill value (G) + uncertainty_pct (H). For asymmetric distributions (PERT/lognormal): fill lower_bound (I) and upper_bound (J) instead — these override the pct formula. Copy rows 4 onwards to add more sub-categories.",
    startRow=1, startCol=1, colNames=FALSE)
  openxlsx::mergeCells(wb, "Parameters", cols=1:17, rows=1)
  apply_style("Parameters",
    mk(fontColour="white", fgFill=C_SECTION, fontSize=9, textDecoration="italic",
       halign="left", valign="center", wrapText=TRUE),
    rows=1, cols=1:17)
  openxlsx::setRowHeights(wb, "Parameters", rows=1, heights=44)

  # Row 2: colour legend (mini legend)
  legend_labels <- c(
    "REQUIRED","REQUIRED","OPTIONAL","INFO","INFO","INFO",
    "REQUIRED","REQUIRED","OPT.OVERRIDE","OPT.OVERRIDE","DROPDOWN","AUTO","AUTO",
    "INFO","INFO","OPTIONAL","DROPDOWN")
  openxlsx::writeData(wb, "Parameters",
    as.data.frame(t(legend_labels)), startRow=2, startCol=1, colNames=FALSE)
  apply_style("Parameters",
    mk(fontSize=7, textDecoration="italic", halign="center",
       fontColour=C_GREY_TXT, fgFill="#FAFAFA"), rows=2, cols=1:17)
  openxlsx::setRowHeights(wb, "Parameters", rows=2, heights=14)

  # Row 3: column headers
  openxlsx::writeData(wb, "Parameters",
    as.data.frame(t(P_COLS)), startRow=3, startCol=1, colNames=FALSE)
  apply_style("Parameters", s_hdr, rows=3, cols=1:17)
  openxlsx::setRowHeights(wb, "Parameters", rows=3, heights=28)

  # Freeze rows 1-3 and column A
  openxlsx::freezePane(wb, "Parameters", firstActiveRow=4, firstActiveCol=2)

  # ── Build data rows per sub-category block ────────────────────────────────
  n_params <- nrow(PARAM_CATALOGUE)
  DATA_START <- 4   # first data row

  # Example values: activity data from Uganda survey, EFs from IPCC defaults
  # Blank template: activity data blank, EFs pre-filled with IPCC defaults
  ex_values <- c(500000, 275, 300, 0.10, 4, 4, 0.60, 55,
                 0.386, 0.17, 0.8, 0.10, 0, 10,
                 6.5, 0.10, 0.08, 0.04,
                 0.02, 0.20, 0.010, 0.0075, 0.02, 3.3)
    # Corrected example uncertainties per Penman et al. (2000) / Monni et al. (2007).
  # NA = asymmetric parameter; lower_bound/upper_bound are pre-filled from catalogue instead.
  ex_unc <- c(10,15,10,30,20,10,20,15, 30,30,30,10,20,15, 8,20,25,25, NA,40,NA,NA,NA, 10)

  for (i in seq_len(n_params)) {
    r <- DATA_START + i - 1
    is_tech <- PARAM_CATALOGUE$param_tier[i] == "technical"
    is_ef   <- PARAM_CATALOGUE$param_type[i] == "emission_factor"

    # value column: technical params get IPCC default; core activity data left blank
    val_cell <- if (include_example) {
      ex_values[i]
    } else if (is_tech) {
      PARAM_CATALOGUE$ipcc_default[i]   # pre-fill all technical params with IPCC default
    } else {
      NA   # core activity data left blank
    }
    unc_cell <- if (include_example) ex_unc[i] else PARAM_CATALOGUE$suggested_uncertainty_pct[i]

    # For asymmetric parameters (unc_cell is NA): pre-fill lower_bound / upper_bound from catalogue
    lb_cell <- if (!is.na(unc_cell)) NA else PARAM_CATALOGUE$suggested_lower_bound[i]
    ub_cell <- if (!is.na(unc_cell)) NA else PARAM_CATALOGUE$suggested_upper_bound[i]

    row_data <- list(
      cattle_type       = if (include_example) "dairy"                      else "dairy",
      aggregation_level = if (include_example) "Eastern Uganda – pastoral" else "Region_or_system_name",
      sub_category      = if (include_example) "cows"                       else "sub_category_name",
      parameter         = PARAM_CATALOGUE$parameter[i],
      definition        = PARAM_CATALOGUE$definition[i],
      unit              = PARAM_CATALOGUE$unit[i],
      value             = val_cell,
      uncertainty_pct   = unc_cell,
      lower_bound       = lb_cell,
      upper_bound       = ub_cell,
      distribution      = PARAM_CATALOGUE$suggested_distribution[i],
      lower             = NA,  # formula below
      upper             = NA,  # formula below
      param_type        = PARAM_CATALOGUE$param_type[i],
      ipcc_ref          = PARAM_CATALOGUE$ipcc_ref[i],
      data_source       = if (include_example) "IPCC default / Uganda survey" else "",
      data_quality      = if (include_example) {
                            if (is_ef) "ipcc_default" else "country_specific"
                          } else ""
    )

    # Write each column
    for (col_nm in names(row_data)) {
      ci <- P_COL_IDX[col_nm]
      val <- row_data[[col_nm]]
      if (!is.null(val) && !is.na(val))
        openxlsx::writeData(wb, "Parameters", val, startRow=r, startCol=ci,
                            colNames=FALSE)
    }

    # Excel formulas for lower (col L=12) and upper (col M=13)
    # Logic: use lower_bound/upper_bound override if filled, else ±pct formula
    g_col <- LETTERS[P_COL_IDX["value"]]           # "G"
    h_col <- LETTERS[P_COL_IDX["uncertainty_pct"]] # "H"
    i_col <- LETTERS[P_COL_IDX["lower_bound"]]     # "I"
    j_col <- LETTERS[P_COL_IDX["upper_bound"]]     # "J"
    openxlsx::writeFormula(wb, "Parameters",
      x = sprintf('=IF(%s%d<>"",%s%d,IF(AND(%s%d<>"",%s%d<>""),%s%d*(1-%s%d/100),\"\"))',
                  i_col,r, i_col,r, g_col,r, h_col,r, g_col,r, h_col,r),
      startRow=r, startCol=P_COL_IDX["lower"])
    openxlsx::writeFormula(wb, "Parameters",
      x = sprintf('=IF(%s%d<>"",%s%d,IF(AND(%s%d<>"",%s%d<>""),%s%d*(1+%s%d/100),\"\"))',
                  j_col,r, j_col,r, g_col,r, h_col,r, g_col,r, h_col,r),
      startRow=r, startCol=P_COL_IDX["upper"])
  }

  # ── Apply styles to data rows ──────────────────────────────────────────────
  data_rows  <- DATA_START:(DATA_START + n_params - 1)
  core_rows  <- DATA_START - 1 + which(PARAM_CATALOGUE$param_tier == "core")
  tech_rows  <- DATA_START - 1 + which(PARAM_CATALOGUE$param_tier == "technical")

  apply_style("Parameters", s_req,  rows=data_rows, cols=P_COL_IDX["cattle_type"])
  apply_style("Parameters", s_req,  rows=data_rows, cols=P_COL_IDX["aggregation_level"])
  apply_style("Parameters", s_opt,  rows=data_rows, cols=P_COL_IDX["sub_category"])
  apply_style("Parameters", s_pre,  rows=data_rows, cols=P_COL_IDX["parameter"])
  apply_style("Parameters", s_pre,  rows=data_rows, cols=P_COL_IDX["definition"])
  apply_style("Parameters", s_pre,  rows=data_rows, cols=P_COL_IDX["unit"])
  # value + uncertainty_pct: yellow for core (user enters), orange for technical (IPCC default pre-filled)
  apply_style("Parameters", s_req,  rows=core_rows, cols=P_COL_IDX["value"])
  apply_style("Parameters", s_req,  rows=core_rows, cols=P_COL_IDX["uncertainty_pct"])
  apply_style("Parameters", s_tech, rows=tech_rows, cols=P_COL_IDX["value"])
  apply_style("Parameters", s_tech, rows=tech_rows, cols=P_COL_IDX["uncertainty_pct"])
  apply_style("Parameters", s_opt,  rows=data_rows, cols=P_COL_IDX["lower_bound"])
  apply_style("Parameters", s_opt,  rows=data_rows, cols=P_COL_IDX["upper_bound"])
  apply_style("Parameters", s_drop, rows=data_rows, cols=P_COL_IDX["distribution"])
  apply_style("Parameters", s_auto, rows=data_rows, cols=P_COL_IDX["lower"])
  apply_style("Parameters", s_auto, rows=data_rows, cols=P_COL_IDX["upper"])
  apply_style("Parameters", s_pre,  rows=data_rows, cols=P_COL_IDX["param_type"])
  apply_style("Parameters", s_pre,  rows=data_rows, cols=P_COL_IDX["ipcc_ref"])
  apply_style("Parameters", s_opt,  rows=data_rows, cols=P_COL_IDX["data_source"])
  apply_style("Parameters", s_drop, rows=data_rows, cols=P_COL_IDX["data_quality"])
  openxlsx::setRowHeights(wb, "Parameters", rows=data_rows, heights=18)

  # ── Extend styles + dropdowns to extra blank rows (rows after the block) ──
  extra_rows <- (DATA_START + n_params):(DATA_START + N_DATA_ROWS)
  apply_style("Parameters", s_req,  rows=extra_rows, cols=P_COL_IDX["cattle_type"])
  apply_style("Parameters", s_req,  rows=extra_rows, cols=P_COL_IDX["aggregation_level"])
  apply_style("Parameters", s_opt,  rows=extra_rows, cols=P_COL_IDX["sub_category"])
  apply_style("Parameters", s_req,  rows=extra_rows, cols=P_COL_IDX["value"])
  apply_style("Parameters", s_req,  rows=extra_rows, cols=P_COL_IDX["uncertainty_pct"])
  apply_style("Parameters", s_opt,  rows=extra_rows, cols=P_COL_IDX["lower_bound"])
  apply_style("Parameters", s_opt,  rows=extra_rows, cols=P_COL_IDX["upper_bound"])
  apply_style("Parameters", s_drop, rows=extra_rows, cols=P_COL_IDX["distribution"])
  apply_style("Parameters", s_auto, rows=extra_rows, cols=P_COL_IDX["lower"])
  apply_style("Parameters", s_auto, rows=extra_rows, cols=P_COL_IDX["upper"])
  apply_style("Parameters", s_drop, rows=extra_rows, cols=P_COL_IDX["data_quality"])

  # Formulas for extra rows
  for (r in extra_rows) {
    g_col <- LETTERS[P_COL_IDX["value"]]
    h_col <- LETTERS[P_COL_IDX["uncertainty_pct"]]
    i_col <- LETTERS[P_COL_IDX["lower_bound"]]
    j_col <- LETTERS[P_COL_IDX["upper_bound"]]
    openxlsx::writeFormula(wb, "Parameters",
      x = sprintf('=IF(%s%d<>"",%s%d,IF(AND(%s%d<>"",%s%d<>""),%s%d*(1-%s%d/100),\"\"))',
                  i_col,r, i_col,r, g_col,r, h_col,r, g_col,r, h_col,r),
      startRow=r, startCol=P_COL_IDX["lower"])
    openxlsx::writeFormula(wb, "Parameters",
      x = sprintf('=IF(%s%d<>"",%s%d,IF(AND(%s%d<>"",%s%d<>""),%s%d*(1+%s%d/100),\"\"))',
                  j_col,r, j_col,r, g_col,r, h_col,r, g_col,r, h_col,r),
      startRow=r, startCol=P_COL_IDX["upper"])
  }

  # ── Dropdown validations for Parameters (rows 4 to DATA_START+N_DATA_ROWS) ─
  all_data_rows <- DATA_START:(DATA_START + N_DATA_ROWS)
  add_validation("Parameters", P_COL_IDX["distribution"], all_data_rows, "dist")
  add_validation("Parameters", P_COL_IDX["data_quality"], all_data_rows, "quality")

  # ── Separator row between the pre-populated block and empty rows ──────────
  sep_row <- DATA_START + n_params
  openxlsx::writeData(wb, "Parameters",
    "--- Add more sub-categories below: copy rows 4 onward, paste here, change cattle_type/aggregation_level/sub_category ---",
    startRow=sep_row, startCol=1, colNames=FALSE)
  openxlsx::mergeCells(wb, "Parameters", cols=1:17, rows=sep_row)
  apply_style("Parameters",
    mk(fgFill="#E8EAF6", fontColour="#3949AB", fontSize=8,
       textDecoration="italic", halign="center"),
    rows=sep_row, cols=1:17)

  # =========================================================================
  # SHEET: Manure_Management
  # =========================================================================
  openxlsx::addWorksheet(wb, "Manure_Management", tabColour = "#1B4332",
                         gridLines = TRUE)

  MM_COLS   <- c("cattle_type","aggregation_level","sub_category",
                 "mms_type","fraction_pct",
                 "MCF_pct","lower_mcf","upper_mcf","distribution_mcf",
                 "EF3","lower_ef3","upper_ef3","distribution_ef3",
                 "Bo")
  MM_WIDTHS <- c(14, 20, 16, 18, 12, 10, 10, 10, 15, 10, 10, 10, 15, 8)

  openxlsx::setColWidths(wb, "Manure_Management",
                         cols=seq_along(MM_COLS), widths=MM_WIDTHS)

  # Instruction banner
  openxlsx::writeData(wb, "Manure_Management",
    "Enter one row per manure management system (MMS) per sub-category. fraction_pct values for the same cattle_type+aggregation_level+sub_category MUST sum to 100. Enter MCF values from IPCC Table 10.17 for your climate zone (see Vocab sheet). EF3 from IPCC Table 10.21. For asymmetric distributions, fill lower_mcf/upper_mcf or lower_ef3/upper_ef3 with min/max values.",
    startRow=1, startCol=1, colNames=FALSE)
  openxlsx::mergeCells(wb, "Manure_Management", cols=1:14, rows=1)
  apply_style("Manure_Management",
    mk(fontColour="white", fgFill=C_SECTION, fontSize=9, textDecoration="italic",
       halign="left", valign="center", wrapText=TRUE),
    rows=1, cols=1:14)
  openxlsx::setRowHeights(wb, "Manure_Management", rows=1, heights=44)

  openxlsx::writeData(wb, "Manure_Management",
    as.data.frame(t(MM_COLS)), startRow=2, startCol=1, colNames=FALSE)
  apply_style("Manure_Management", s_hdr, rows=2, cols=1:14)

  hints_mm <- data.frame(
    cattle_type="dairy / other (free text)",
    aggregation_level="Region / AEZ / production system (free text)",
    sub_category="Optional: cows / heifers / calves (free text)",
    mms_type="Select from dropdown",
    fraction_pct="% of manure to this MMS (all rows per sub-cat must sum to 100)",
    MCF_pct="Methane conv. factor % — look up IPCC Table 10.17 in Vocab sheet",
    lower_mcf="Optional: min value for asymmetric MCF distribution",
    upper_mcf="Optional: max value for asymmetric MCF distribution",
    distribution_mcf="Distribution for MCF uncertainty — select from dropdown",
    EF3="Direct N2O EF — look up IPCC Table 10.21 in Vocab sheet",
    lower_ef3="Optional: min value for asymmetric EF3 distribution",
    upper_ef3="Optional: max value for asymmetric EF3 distribution",
    distribution_ef3="Distribution for EF3 uncertainty — select from dropdown",
    Bo="Max CH4 capacity (m3/kg VS) — IPCC default 0.10",
    stringsAsFactors=FALSE)
  openxlsx::writeData(wb, "Manure_Management", hints_mm, startRow=3, startCol=1,
                      colNames=FALSE)
  apply_style("Manure_Management", s_note, rows=3, cols=1:14)
  openxlsx::setRowHeights(wb, "Manure_Management", rows=3, heights=36)
  openxlsx::freezePane(wb, "Manure_Management", firstActiveRow=4)

  # Example or blank data
  if (include_example) {
    manure_data <- data.frame(
      cattle_type=c("dairy","dairy"),
      aggregation_level=c("Eastern Uganda \u2013 pastoral","Eastern Uganda \u2013 pastoral"),
      sub_category=c("cows","cows"),
      mms_type=c("pasture","solid_storage"),
      fraction_pct=c(70,30),
      MCF_pct=c(1.5,5.0),
      lower_mcf=c(NA_real_,NA_real_),
      upper_mcf=c(NA_real_,NA_real_),
      distribution_mcf=c("pert","pert"),
      EF3=c(0.02,0.005),
      lower_ef3=c(NA_real_,NA_real_),
      upper_ef3=c(NA_real_,NA_real_),
      distribution_ef3=c("pert","pert"),
      Bo=c(0.10,0.10),
      stringsAsFactors=FALSE)
    openxlsx::writeData(wb, "Manure_Management", manure_data, startRow=4,
                        startCol=1, colNames=FALSE)
    data_rng <- 4:5
  } else {
    data_rng <- 4:100
  }

  apply_style("Manure_Management", s_req,  rows=data_rng, cols=1)    # cattle_type
  apply_style("Manure_Management", s_req,  rows=data_rng, cols=2)    # aggregation_level
  apply_style("Manure_Management", s_opt,  rows=data_rng, cols=3)    # sub_category
  apply_style("Manure_Management", s_drop, rows=data_rng, cols=4)    # mms_type
  apply_style("Manure_Management", s_req,  rows=data_rng, cols=5)    # fraction_pct
  apply_style("Manure_Management", s_req,  rows=data_rng, cols=6)    # MCF_pct
  apply_style("Manure_Management", s_opt,  rows=data_rng, cols=7:8)  # lower/upper_mcf
  apply_style("Manure_Management", s_drop, rows=data_rng, cols=9)    # distribution_mcf
  apply_style("Manure_Management", s_req,  rows=data_rng, cols=10)   # EF3
  apply_style("Manure_Management", s_opt,  rows=data_rng, cols=11:12) # lower/upper_ef3
  apply_style("Manure_Management", s_drop, rows=data_rng, cols=13)   # distribution_ef3
  apply_style("Manure_Management", s_opt,  rows=data_rng, cols=14)   # Bo

  add_validation("Manure_Management", col=4,  rows=data_rng, "mms")
  add_validation("Manure_Management", col=9,  rows=data_rng, "dist")
  add_validation("Manure_Management", col=13, rows=data_rng, "dist")

  # =========================================================================
  # SHEET: Parameter_TimeSeries  (rows = years, cols = parameters)
  # Parsed by parse_uploaded_template() to auto-compute the AD correlation matrix.
  # =========================================================================
  openxlsx::addWorksheet(wb, "Parameter_TimeSeries", tabColour = "#40916C",
                         gridLines = TRUE)
  ts_params <- c("cattle_pop", "live_weight", "mature_weight", "weight_gain",
                 "milk_yield", "milk_fat", "pct_lactating", "DE_pct",
                 "CP_pct", "protein_milk")
  ts_units <- c("head", "kg", "kg", "kg/day",
                "kg/head/day", "%", "fraction (0-1)", "%", "%", "%")
  ts_desc  <- c("No. of animals", "Avg. live body weight", "Mature body weight",
                "Daily weight gain", "Daily milk yield per cow", "Milk fat content",
                "Fraction of cows lactating", "Digestible energy",
                "Crude protein in diet", "Milk protein content")
  ts_all_cols  <- c("year", ts_params)
  ts_all_units <- c("(label only)", ts_units)
  ts_all_desc  <- c("Calendar year", ts_desc)
  ts_n_cols    <- length(ts_all_cols)

  s_ts_hdr   <- mk(fontSize=10, fontName="Calibri", textDecoration="bold",
                   fontColour="#FFFFFF", fgFill="#2D6A4F",
                   border="TopBottomLeftRight", borderColour="#1B4332",
                   halign="center", valign="center", wrapText=TRUE)
  s_ts_sub   <- mk(fontSize=9, fontName="Calibri", fontColour="#555555",
                   fgFill="#D8F3DC", border="TopBottomLeftRight",
                   borderColour="#B7DFC0", halign="center", valign="top",
                   wrapText=TRUE, textDecoration="italic")
  s_ts_year  <- mk(fontSize=10, fontName="Calibri", halign="center",
                   fgFill="#F0FDF4", border="TopBottomLeftRight",
                   borderColour="#D1FAE5")
  s_ts_data  <- mk(fontSize=10, fontName="Calibri", halign="right",
                   fgFill="#F0FDF4", border="TopBottomLeftRight",
                   borderColour="#D1FAE5", numFmt="0.000")
  s_ts_int   <- mk(fontSize=10, fontName="Calibri", halign="right",
                   fgFill="#F0FDF4", border="TopBottomLeftRight",
                   borderColour="#D1FAE5", numFmt="#,##0")
  s_ts_empty <- mk(fontSize=10, fontName="Calibri", halign="right",
                   fgFill="#FFFFFF", border="TopBottomLeftRight",
                   borderColour="#E5E7EB")
  s_ts_note  <- mk(fontSize=9, fontName="Calibri", fontColour="#6B7280",
                   textDecoration="italic", wrapText=TRUE)

  ts_banner <- if (include_example) {
    paste("CORRELATIONS: Fill in one row per year for each parameter you have data for.",
          "When you upload this template in Tab 1, the app automatically computes a Pearson",
          "correlation matrix and uses it in Monte Carlo sampling (Tab 4 > Activity Data).",
          "You do NOT need every column - absent parameters are treated as uncorrelated (r=0).",
          "Delete the Uganda example rows and replace with your data.",
          "Minimum: 2 numeric columns and 5 rows.")
  } else {
    paste("CORRELATIONS: Fill in one row per year for each parameter you have historical data for.",
          "When you upload this template in Tab 1, the app automatically computes a Pearson",
          "correlation matrix and uses it in Monte Carlo sampling (Tab 4 > Activity Data).",
          "You do NOT need every column - absent parameters are treated as uncorrelated (r=0).",
          "Minimum: 2 numeric columns and 5 rows.")
  }
  openxlsx::writeData(wb, "Parameter_TimeSeries", ts_banner,
    startRow=1, startCol=1, colNames=FALSE)
  openxlsx::mergeCells(wb, "Parameter_TimeSeries", cols=1:ts_n_cols, rows=1)
  apply_style("Parameter_TimeSeries",
    mk(fontColour="white", fgFill=C_SECTION, fontSize=9, textDecoration="italic",
       halign="left", valign="center", wrapText=TRUE),
    rows=1, cols=1:ts_n_cols)
  openxlsx::setRowHeights(wb, "Parameter_TimeSeries", rows=1, heights=52)

  openxlsx::writeData(wb, "Parameter_TimeSeries",
                      as.data.frame(t(ts_all_cols)), startRow=2, startCol=1,
                      colNames=FALSE)
  apply_style("Parameter_TimeSeries", s_ts_hdr, rows=2, cols=1:ts_n_cols)
  openxlsx::setRowHeights(wb, "Parameter_TimeSeries", rows=2, heights=22)

  openxlsx::writeData(wb, "Parameter_TimeSeries",
                      as.data.frame(t(ts_all_desc)), startRow=3, startCol=1,
                      colNames=FALSE)
  apply_style("Parameter_TimeSeries", s_ts_sub, rows=3, cols=1:ts_n_cols)
  openxlsx::setRowHeights(wb, "Parameter_TimeSeries", rows=3, heights=28)

  openxlsx::writeData(wb, "Parameter_TimeSeries",
                      as.data.frame(t(ts_all_units)), startRow=4, startCol=1,
                      colNames=FALSE)
  apply_style("Parameter_TimeSeries", s_ts_sub, rows=4, cols=1:ts_n_cols)
  openxlsx::setRowHeights(wb, "Parameter_TimeSeries", rows=4, heights=18)

  TS_DATA_START <- 5

  if (include_example) {
    ts_ex <- data.frame(
      year         = 2013:2022,
      cattle_pop   = c(4320000, 4410000, 4480000, 4530000, 4490000,
                       4560000, 4620000, 4670000, 4720000, 4790000),
      live_weight  = c(278, 275, 272, 270, 274, 271, 268, 273, 276, 274),
      mature_weight= c(302, 300, 300, 299, 301, 300, 298, 301, 302, 300),
      weight_gain  = c(0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
      milk_yield   = c(3.9, 4.1, 4.0, 3.8, 4.2, 4.0, 3.9, 4.1, 4.0, 4.3),
      milk_fat     = c(3.9, 4.0, 4.1, 3.9, 4.0, 4.0, 4.1, 4.0, 3.9, 4.1),
      pct_lactating= c(0.59, 0.61, 0.60, 0.58, 0.62, 0.60, 0.59, 0.61, 0.60, 0.62),
      DE_pct       = c(54.5, 55.0, 55.5, 54.0, 55.5, 55.0, 54.5, 56.0, 55.0, 55.5),
      CP_pct       = c(9.8, 10.0, 10.2, 9.6, 10.3, 10.0, 9.9, 10.4, 10.1, 10.2),
      protein_milk = c(3.2, 3.3, 3.3, 3.2, 3.4, 3.3, 3.2, 3.4, 3.3, 3.4)
    )
    ts_n_ex <- nrow(ts_ex)
    openxlsx::writeData(wb, "Parameter_TimeSeries", ts_ex,
                        startRow=TS_DATA_START, startCol=1, colNames=FALSE)
    apply_style("Parameter_TimeSeries", s_ts_year,
                rows=TS_DATA_START:(TS_DATA_START + ts_n_ex - 1), cols=1)
    apply_style("Parameter_TimeSeries", s_ts_int,
                rows=TS_DATA_START:(TS_DATA_START + ts_n_ex - 1), cols=2)
    apply_style("Parameter_TimeSeries", s_ts_data,
                rows=TS_DATA_START:(TS_DATA_START + ts_n_ex - 1), cols=3:ts_n_cols)
    openxlsx::setRowHeights(wb, "Parameter_TimeSeries",
                            rows=TS_DATA_START:(TS_DATA_START + ts_n_ex - 1), heights=16)
    TS_BLANK_START <- TS_DATA_START + ts_n_ex
  } else {
    ts_n_ex        <- 0L
    TS_BLANK_START <- TS_DATA_START
  }

  TS_BLANK_END <- TS_BLANK_START + 19
  apply_style("Parameter_TimeSeries", s_ts_empty,
              rows=TS_BLANK_START:TS_BLANK_END, cols=1:ts_n_cols)
  openxlsx::setRowHeights(wb, "Parameter_TimeSeries",
                          rows=TS_BLANK_START:TS_BLANK_END, heights=16)

  TS_NOTE_ROW <- TS_BLANK_END + 2
  ts_note <- if (include_example) {
    "Add more rows above if needed. Delete rows 5-14 (Uganda example) and replace with your own data."
  } else {
    "Add more rows above if needed. Enter one row per year, starting from row 5."
  }
  openxlsx::writeData(wb, "Parameter_TimeSeries", ts_note,
                      startRow=TS_NOTE_ROW, startCol=1)
  apply_style("Parameter_TimeSeries", s_ts_note, rows=TS_NOTE_ROW, cols=1)
  openxlsx::mergeCells(wb, "Parameter_TimeSeries", cols=1:ts_n_cols, rows=TS_NOTE_ROW)

  openxlsx::setColWidths(wb, "Parameter_TimeSeries", cols=1, widths=7)
  openxlsx::setColWidths(wb, "Parameter_TimeSeries", cols=2:ts_n_cols, widths=14)
  openxlsx::freezePane(wb, "Parameter_TimeSeries", firstActiveRow=TS_DATA_START)

  if (FALSE) { # dead block — kept only so unicode – below doesn't break parse
    pop_example_dead <- data.frame(
      cattle_type="dairy",
      aggregation_level="Eastern Uganda \u2013 pastoral",
      sub_category="cows",
      "2018"=450000L,"2019"=460000L,"2020"=470000L,
      "2021"=480000L,"2022"=490000L,"2023"=500000L,
      check.names=FALSE, stringsAsFactors=FALSE)
    openxlsx::writeData(wb, "Population_TimeSeries", pop_example, startRow=3,
                        startCol=1, colNames=FALSE)
  }

  # =========================================================================
  # SHEET: Vocab (combined parameter catalogue + controlled vocabulary)
  # =========================================================================
  openxlsx::addWorksheet(wb, "Vocab", tabColour = "#2D6A4F", gridLines = FALSE)
  openxlsx::setColWidths(wb, "Vocab",
                         cols=1:8, widths=c(18,48,18,12,14,12,16,50))

  # ── Section A: Parameter catalogue ──────────────────────────────────────
  openxlsx::writeData(wb, "Vocab", "SECTION A — Parameter Catalogue",
                      startRow=1, startCol=1, colNames=FALSE)
  openxlsx::mergeCells(wb, "Vocab", cols=1:8, rows=1)
  apply_style("Vocab",
    mk(fontColour="white", fgFill=C_HEADER, fontSize=13, textDecoration="bold",
       halign="left", valign="center"),
    rows=1, cols=1:8)
  openxlsx::setRowHeights(wb, "Vocab", rows=1, heights=28)

  cat_hdr <- data.frame(
    parameter="parameter", definition="definition", unit="unit",
    ipcc_default="ipcc_default", suggested_uncertainty_pct="suggested_unc_%",
    suggested_distribution="suggested_distribution",
    param_type="param_type", ipcc_ref="ipcc_ref",
    stringsAsFactors=FALSE)
  openxlsx::writeData(wb, "Vocab", cat_hdr, startRow=2, startCol=1,
                      colNames=FALSE)
  apply_style("Vocab", s_hdr, rows=2, cols=1:8)

  openxlsx::writeData(wb, "Vocab", PARAM_CATALOGUE, startRow=3, startCol=1,
                      colNames=FALSE)
  cat_data_rows <- 3:(2+nrow(PARAM_CATALOGUE))

  # Alternating row shading
  for (i in seq_along(cat_data_rows)) {
    r <- cat_data_rows[i]
    bg <- if (i %% 2 == 1) "#FFFFFF" else C_PREFILL
    apply_style("Vocab",
      mk(fgFill=bg, fontName="Calibri", fontSize=9,
         border="Bottom", borderColour="#DDDDDD",
         halign="left", valign="top", wrapText=TRUE),
      rows=r, cols=1:8)
  }
  # Highlight parameter column bold
  apply_style("Vocab",
    mk(fontName="Calibri", fontSize=9, textDecoration="bold",
       fgFill="#FFFFFF", border="Bottom", borderColour="#DDDDDD"),
    rows=cat_data_rows, cols=1)
  openxlsx::setRowHeights(wb, "Vocab", rows=cat_data_rows, heights=22)

  # ── Spacer ────────────────────────────────────────────────────────────────
  spacer_row <- max(cat_data_rows) + 2

  # ── Section B: Controlled vocabulary tables ───────────────────────────────
  openxlsx::writeData(wb, "Vocab", "SECTION B — Controlled Vocabulary",
                      startRow=spacer_row, startCol=1, colNames=FALSE)
  openxlsx::mergeCells(wb, "Vocab", cols=1:8, rows=spacer_row)
  apply_style("Vocab",
    mk(fontColour="white", fgFill=C_HEADER, fontSize=13, textDecoration="bold",
       halign="left", valign="center"),
    rows=spacer_row, cols=1:8)
  openxlsx::setRowHeights(wb, "Vocab", rows=spacer_row, heights=28)

  # Each vocabulary table: term | label/description | used_in | valid_for
  vocab_tables <- list(
    list(title="species (Inventory_Metadata dropdown)",
         cols=c("term","label","used_in"),
         data=data.frame(
           term=V_SPECIES,
           label=c("Cattle — dairy breeds","Cattle — non-dairy / beef / multipurpose","Buffalo"),
           used_in=rep("Inventory_Metadata.species", 3),
           stringsAsFactors=FALSE)),

    list(title="IPCC Table 10.17 — MCF (%) by climate zone  [enter values into Manure_Management sheet]",
         cols=c("mms_type","tropical_moist_%","tropical_dry_%","temperate_%","boreal_%"),
         data=data.frame(
           mms_type=MMS_DEFAULTS$id,
           tropical_moist=MMS_DEFAULTS$mcf_tropical,
           tropical_dry=MMS_DEFAULTS$mcf_tropical_dry,
           temperate=MMS_DEFAULTS$mcf_temperate,
           boreal=MMS_DEFAULTS$mcf_boreal,
           stringsAsFactors=FALSE)),

    list(title="mms_type (manure management system)",
         cols=c("term","label","EF3 (kg N2O-N/kg N)","MCF tropical%","MCF temperate%"),
         data=data.frame(
           term=MMS_DEFAULTS$id,
           label=MMS_DEFAULTS$label,
           ef3=MMS_DEFAULTS$ef3,
           mcf_trop=MMS_DEFAULTS$mcf_tropical,
           mcf_temp=MMS_DEFAULTS$mcf_temperate,
           stringsAsFactors=FALSE)),

    list(title="distribution (Parameters and Manure_Management dropdowns)",
         cols=c("term","shape","when_to_use","bounds_input"),
         data=data.frame(
           term=V_DIST,
           shape=c("Symmetric bell","Symmetric, truncated at 0","Right-skewed, always positive",
                   "Flexible, bounded [lower,upper]","Linear triangle","Smooth peak at mode",
                   "Flat — all values equally likely","No variation","Normal clamped to [0,1]"),
           use=c("Large populations, body weights, symmetric uncertainty",
                 "Non-negative parameters with near-symmetric uncertainty",
                 "Emission factors, ratios — strictly positive, possible right tail",
                 "Fractions 0-1: pct_lactating, Cp",
                 "Expert-elicited min/mode/max: Ca, C_growth, DE_pct",
                 "IPCC coefficients: Cfi, Ym, Bo, EF3_PRP — recommended for most EFs",
                 "Only bounds known, no preferred value",
                 "Zero uncertainty, e.g. WG=0 for non-growing adults",
                 "Fractions that must stay in [0,1]"),
           bounds=c("uncertainty_pct only","uncertainty_pct only","uncertainty_pct only",
                    "uncertainty_pct only","lower_bound+upper_bound (min/max)",
                    "lower_bound+upper_bound (min/max)",
                    "lower_bound+upper_bound (min/max)","none","uncertainty_pct only"),
           stringsAsFactors=FALSE)),

    list(title="data_quality (optional metadata for each parameter)",
         cols=c("term","description"),
         data=data.frame(
           term=V_QUALITY,
           description=c(
             "Value from local measurement or controlled experiment",
             "Value from national survey, census, or country-specific study",
             "Value from continental or biome-level average",
             "Value taken directly from an IPCC default table",
             "Value estimated by domain expert without formal data"),
           stringsAsFactors=FALSE)),

    list(title="animal sub-category reference — IPCC defaults (for reference only; sub_category is free text in the template)",
         cols=c("ipcc_term","label","sex","age_class","default_Cfi",
                "default_LW_kg","default_WG_kg_day"),
         data=data.frame(
           term=V_SUBSYS,
           label=unname(ANIMAL_SUBCATEGORY_LABELS),
           sex=unlist(SEX_BY_SUBCAT[V_SUBSYS]),
           age_class=unlist(AGE_BY_SUBCAT[V_SUBSYS]),
           Cfi=unlist(CFI_BY_SUBCAT[V_SUBSYS]),
           LW=unlist(LW_BY_SUBCAT[V_SUBSYS]),
           WG=unlist(WG_BY_SUBCAT[V_SUBSYS]),
           stringsAsFactors=FALSE)),

    list(title="feeding_situation reference — Ca values (for reference only; feeding situation is captured in sub_category free text)",
         cols=c("term","description","Ca value (IPCC Table 10.5)"),
         data=data.frame(
           term=V_FEED,
           description=c("Animal is stall-fed or kept in enclosure",
                         "Animal grazes on flat terrain",
                         "Animal grazes on hilly terrain"),
           Ca=c(0.00, 0.17, 0.36),
           stringsAsFactors=FALSE))
  )

  cur_row <- spacer_row + 1
  for (vt in vocab_tables) {
    # Section title
    openxlsx::writeData(wb, "Vocab", vt$title, startRow=cur_row, startCol=1,
                        colNames=FALSE)
    openxlsx::mergeCells(wb, "Vocab", cols=1:8, rows=cur_row)
    apply_style("Vocab",
      mk(fontColour="white", fgFill=C_SECTION, fontSize=10,
         textDecoration="bold", halign="left", valign="center"),
      rows=cur_row, cols=1:8)
    openxlsx::setRowHeights(wb, "Vocab", rows=cur_row, heights=22)
    cur_row <- cur_row + 1

    # Column headers
    hdr_df <- as.data.frame(t(vt$cols), stringsAsFactors=FALSE)
    openxlsx::writeData(wb, "Vocab", hdr_df, startRow=cur_row, startCol=1,
                        colNames=FALSE)
    apply_style("Vocab", s_hdr, rows=cur_row, cols=seq_along(vt$cols))
    cur_row <- cur_row + 1

    # Data
    nc <- ncol(vt$data)
    openxlsx::writeData(wb, "Vocab", vt$data, startRow=cur_row, startCol=1,
                        colNames=FALSE)
    for (i in seq_len(nrow(vt$data))) {
      bg <- if (i%%2==1) "#FFFFFF" else C_DROPDOWN
      apply_style("Vocab",
        mk(fgFill=bg, fontName="Calibri", fontSize=9,
           border="Bottom", borderColour="#DDDDDD",
           halign="left", valign="top"),
        rows=cur_row+i-1, cols=1:nc)
      # Bold the term column
      apply_style("Vocab",
        mk(fgFill=bg, fontName="Calibri", fontSize=9, textDecoration="bold",
           border="Bottom", borderColour="#DDDDDD"),
        rows=cur_row+i-1, cols=1)
    }
    cur_row <- cur_row + nrow(vt$data) + 1  # +1 blank gap
  }

  # =========================================================================
  # Save workbook
  # =========================================================================
  openxlsx::saveWorkbook(wb, filepath, overwrite = TRUE)
  message("Template saved to: ", filepath)
}


# ===========================================================================
# FALLBACK — basic writexl version (no dropdowns)
# ===========================================================================
generate_template_basic <- function(filepath, include_example) {
  ex_values <- c(500000, 275, 300, 0.10, 4, 4, 0.60, 55,
                 0.386, 0.17, 0.8, 0.10, 0, 10,
                 6.5, 0.10, 0.08, 0.04,
                 0.02, 0.20, 0.010, 0.0075, 0.02, 3.3)
  params <- if (include_example) {
    data.frame(
      cattle_type="dairy",
      aggregation_level="Eastern Uganda \u2013 pastoral",
      sub_category="cows",
      parameter=PARAM_CATALOGUE$parameter,
      definition=PARAM_CATALOGUE$definition,
      unit=PARAM_CATALOGUE$unit,
      value=ex_values,
      uncertainty_pct=PARAM_CATALOGUE$suggested_uncertainty_pct,
      lower_bound=NA_real_,
      upper_bound=NA_real_,
      distribution=PARAM_CATALOGUE$suggested_distribution,
      lower=NA_real_, upper=NA_real_,
      param_type=PARAM_CATALOGUE$param_type,
      ipcc_ref=PARAM_CATALOGUE$ipcc_ref,
      data_source="IPCC default / Uganda survey",
      data_quality=ifelse(PARAM_CATALOGUE$param_type=="emission_factor",
                          "ipcc_default","country_specific"),
      stringsAsFactors=FALSE)
  } else {
    is_ef <- PARAM_CATALOGUE$param_type == "emission_factor"
    data.frame(
      cattle_type="dairy",
      aggregation_level="",
      sub_category="",
      parameter=PARAM_CATALOGUE$parameter,
      definition=PARAM_CATALOGUE$definition,
      unit=PARAM_CATALOGUE$unit,
      value=ifelse(is_ef, PARAM_CATALOGUE$ipcc_default, NA_real_),
      uncertainty_pct=PARAM_CATALOGUE$suggested_uncertainty_pct,
      lower_bound=NA_real_,
      upper_bound=NA_real_,
      distribution=PARAM_CATALOGUE$suggested_distribution,
      lower=NA_real_, upper=NA_real_,
      param_type=PARAM_CATALOGUE$param_type,
      ipcc_ref=PARAM_CATALOGUE$ipcc_ref,
      data_source="", data_quality="",
      stringsAsFactors=FALSE)
  }
  writexl::write_xlsx(list(Parameters=params, Vocab=PARAM_CATALOGUE),
                      path=filepath)
}


# ===========================================================================
# PARSER — read back an uploaded template (openxlsx or writexl output)
# ===========================================================================
parse_uploaded_template <- function(path) {
  warnings_list <- character()

  sheet_names <- tryCatch(readxl::excel_sheets(path),
                          error = function(e) character())

  read_sheet <- function(name) {
    if (!(name %in% sheet_names)) return(NULL)
    tryCatch(
      as.data.frame(readxl::read_excel(path, sheet = name,
                                       .name_repair = "unique")),
      error = function(e) {
        warnings_list <<- c(warnings_list,
                            paste("Could not read sheet", name, ":", e$message))
        NULL
      })
  }

  metadata   <- read_sheet("Inventory_Metadata")
  params     <- read_sheet("Parameters")
  manure     <- read_sheet("Manure_Management")

  # Parameter_TimeSeries: row 1 = param names, rows 2-3 = desc/units (skip), rows 4+ = data.
  # Also accept old "Population_TimeSeries" name for backwards compatibility.
  ts_sheet <- if ("Parameter_TimeSeries" %in% sheet_names) "Parameter_TimeSeries" else
               if ("Population_TimeSeries" %in% sheet_names) "Population_TimeSeries" else NULL
  population <- if (!is.null(ts_sheet)) {
    tryCatch(
      as.data.frame(readxl::read_excel(
        path, sheet = ts_sheet, col_names = TRUE, skip = 0,
        .name_repair = "unique")),
      error = function(e) NULL)
  } else NULL

  # Detect new-style sheet (row 1 = parameter names used as col headers by readxl)
  corr_matrix_from_ts <- NULL
  if (!is.null(population) && ncol(population) >= 2) {
    # Skip description/unit rows: if second row is non-numeric text, drop rows until numeric
    num_check <- suppressWarnings(as.numeric(population[[1]]))
    first_data <- which(!is.na(num_check))[1]
    if (!is.na(first_data) && first_data > 1)
      population <- population[first_data:nrow(population), , drop = FALSE]
    # Convert all columns to numeric
    population[] <- lapply(population, function(x) suppressWarnings(as.numeric(x)))
    numeric_cols <- sapply(population, function(x) sum(!is.na(x)) >= 5)
    pop_numeric  <- population[, numeric_cols, drop = FALSE]
    if (sum(numeric_cols) >= 2 && nrow(pop_numeric) >= 5) {
      tryCatch({
        cm <- cor(pop_numeric, use = "complete.obs")
        corr_matrix_from_ts <- as.matrix(
          Matrix::nearPD(cm, corr = TRUE)$mat)
      }, error = function(e) NULL)
    }
  }

  # For the transposed Inventory_Metadata layout (Field | Value | Hint)
  if (!is.null(metadata) && ncol(metadata) >= 2) {
    if (all(c("Field","Value") %in% names(metadata)) ||
        (ncol(metadata) >= 2 && names(metadata)[2] %in%
         c("Field","B","country","country / region",
           "Country / region"))) {
      # Try to detect transposed layout (rows = fields, col 2 = value)
      tryCatch({
        field_col <- grep("field|label", names(metadata), ignore.case=TRUE)[1]
        val_col   <- grep("value|val", names(metadata), ignore.case=TRUE)[1]
        if (!is.na(field_col) && !is.na(val_col)) {
          m2 <- setNames(as.list(metadata[[val_col]]),
                         tolower(gsub("\\s*/.*","", gsub(" ","_",
                           metadata[[field_col]]))))
          metadata <- as.data.frame(m2, stringsAsFactors=FALSE)
        }
      }, error=function(e) NULL)
    }
  }

  if (is.null(params) || nrow(params) == 0)
    stop("Parameters sheet is empty or missing.")

  # Remove instruction/separator rows (rows where parameter is not in catalogue)
  if ("parameter" %in% names(params)) {
    params <- params[
      !is.na(params$parameter) &
      nzchar(as.character(params$parameter)) &
      params$parameter %in% PARAM_CATALOGUE$parameter, ,
      drop = FALSE]
  }

  # Rename 'value' -> 'mean' for mc_sampling compatibility
  if ("value" %in% names(params) && !"mean" %in% names(params))
    names(params)[names(params) == "value"] <- "mean"

  # Ensure numeric
  for (nm in c("mean","uncertainty_pct","lower","upper","lower_bound","upper_bound")) {
    if (nm %in% names(params))
      params[[nm]] <- suppressWarnings(as.numeric(params[[nm]]))
  }

  # Fill lower/upper from lower_bound/upper_bound overrides or uncertainty_pct
  params <- fill_bounds(params)

  # Ensure Bo default in manure sheet
  if (!is.null(manure) && nrow(manure) > 0) {
    if (!"Bo" %in% names(manure)) manure$Bo <- 0.10
    manure$Bo[is.na(manure$Bo)] <- 0.10
    # Ensure numeric MCF and EF3
    for (nm in c("MCF_pct","EF3","lower_mcf","upper_mcf","lower_ef3","upper_ef3")) {
      if (nm %in% names(manure))
        manure[[nm]] <- suppressWarnings(as.numeric(manure[[nm]]))
    }
  }

  list(param_specs=params, metadata=metadata,
       manure=manure, population=population,
       corr_matrix=corr_matrix_from_ts,
       warnings=warnings_list)
}


# ===========================================================================
# IPCC REFERENCE SHEET  (kept for backwards compatibility — used by the
# old writexl path and accessible from build_ipcc_reference_sheet())
# ===========================================================================
build_ipcc_reference_sheet <- function() {
  bind_rows_safe <- function(...) {
    dfs <- list(...)
    do.call(rbind, lapply(dfs, function(d) { rownames(d) <- NULL; d }))
  }
  cfi <- data.frame(category="Cfi", subcategory=names(CFI_BY_SUBCAT),
    default_value=unlist(CFI_BY_SUBCAT), unit="MJ/day/kg^0.75",
    ipcc_ref="Table 10.4", depends_on="Sex, lactation, maturity",
    notes="Africa defaults", stringsAsFactors=FALSE)
  ca  <- data.frame(category="Ca", subcategory=names(FEEDING_SITUATION_CA),
    default_value=unlist(FEEDING_SITUATION_CA), unit="dimensionless",
    ipcc_ref="Table 10.5", depends_on="Feeding situation",
    notes="stall=0, flat=0.17, hilly=0.36", stringsAsFactors=FALSE)
  cg  <- data.frame(category="C_growth",
    subcategory=c("female","castrate","bull"), default_value=c(0.8,1.0,1.2),
    unit="dimensionless", ipcc_ref="Eq 10.6", depends_on="Sex",
    notes="NEg equation", stringsAsFactors=FALSE)
  lw  <- data.frame(category="Live weight", subcategory=names(LW_BY_SUBCAT),
    default_value=unlist(LW_BY_SUBCAT), unit="kg",
    ipcc_ref="Table 10A.1-10A.2", depends_on="Sub-category, region",
    notes="Africa defaults", stringsAsFactors=FALSE)
  ym  <- data.frame(category="Ym",
    subcategory=c("Dairy high-DE","Dairy low-DE","Feedlot","Other low-DE","Other high-DE"),
    default_value=c(6.0,6.5,3.0,6.5,6.5), unit="%",
    ipcc_ref="Table 10.12", depends_on="Feed quality, system",
    notes="GE->CH4 conversion", stringsAsFactors=FALSE)
  mcf_rows <- do.call(rbind, lapply(seq_len(nrow(MMS_DEFAULTS)), function(i) {
    m <- MMS_DEFAULTS[i,]
    data.frame(category="MCF",
      subcategory=paste0(m$label," / ",c("tropical_moist","tropical_dry","temperate","boreal")),
      default_value=c(m$mcf_tropical,m$mcf_tropical_dry,m$mcf_temperate,m$mcf_boreal),
      unit="%", ipcc_ref="Table 10.17", depends_on="MMS, climate",
      notes="", stringsAsFactors=FALSE)
  }))
  ef3 <- data.frame(category="EF3",
    subcategory=paste0(MMS_DEFAULTS$label," (N2O MMS)"),
    default_value=MMS_DEFAULTS$ef3, unit="kg N2O-N/kg N",
    ipcc_ref="Table 10.21", depends_on="MMS type", notes="",
    stringsAsFactors=FALSE)
  gwp <- data.frame(category="GWP",
    subcategory=c("CH4/AR4","N2O/AR4","CH4/AR5","N2O/AR5","CH4/AR6","N2O/AR6"),
    default_value=c(25,298,28,265,27.9,273), unit="kg CO2eq/kg gas",
    ipcc_ref="IPCC AR WG1", depends_on="Assessment report",
    notes="100-yr GWP", stringsAsFactors=FALSE)
  bind_rows_safe(cfi, ca, cg, lw, ym, mcf_rows, ef3, gwp)
}
