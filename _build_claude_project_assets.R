# =============================================================================
# Build the knowledge files for the "GMH Uncertainty Translator" Claude Project
# =============================================================================
# Reads PARAM_CATALOGUE, PARAM_ALIASES, MMS_DEFAULTS and controlled vocabularies
# from the live R source and emits Markdown knowledge files into
# claude_project_assets/. Re-run whenever the catalogue or vocabularies change,
# then re-upload the .md files to the public Claude Project on claude.ai.
#
# Usage (from project root):
#   source("_build_claude_project_assets.R")
# =============================================================================

suppressMessages({
  source("R/utils_template.R", local = FALSE)
  source("R/utils_validation.R", local = FALSE)
  source("R/utils_ipcc_defaults.R", local = FALSE)
})

out_dir <- "claude_project_assets"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

stamp <- format(Sys.Date(), "%Y-%m-%d")

# ---------------------------------------------------------------------------
# 1. param_catalogue.md  -- the 27 IPCC-aligned parameters with everything
# Claude needs to map a raw column to a template field.
# ---------------------------------------------------------------------------
fmt_num <- function(x) {
  if (is.na(x)) "" else if (x == 0) "0" else format(x, scientific = FALSE,
                                                      drop0trailing = TRUE)
}

# Build alias index: parameter -> aliases pointing to it
alias_to <- function(canonical) {
  hits <- names(PARAM_ALIASES)[PARAM_ALIASES == canonical]
  if (length(hits) == 0) "(none)" else paste(hits, collapse = ", ")
}

pc <- PARAM_CATALOGUE

lines <- c(
  sprintf("# Parameter catalogue — auto-generated %s", stamp),
  "",
  "Single source of truth for the 27 IPCC-aligned parameters the cattle uncertainty app expects.",
  "When you (Claude) translate a user's raw column to a template field, use this table.",
  "All parameter codes are case-sensitive.",
  "",
  "| code | tier | type | unit | IPCC default | suggested ±% | distribution | IPCC ref | aliases accepted | definition |",
  "|------|------|------|------|--------------|--------------|--------------|----------|------------------|------------|"
)
for (i in seq_len(nrow(pc))) {
  lines <- c(lines, sprintf(
    "| `%s` | %s | %s | %s | %s | %s | %s | %s | %s | %s |",
    pc$parameter[i],
    pc$param_tier[i],
    pc$param_type[i],
    pc$unit[i],
    fmt_num(pc$ipcc_default[i]),
    if (is.na(pc$suggested_uncertainty_pct[i])) "(asymmetric — use bounds)"
      else paste0(pc$suggested_uncertainty_pct[i], "%"),
    pc$suggested_distribution[i],
    if (nzchar(pc$ipcc_ref[i])) pc$ipcc_ref[i] else "—",
    alias_to(pc$parameter[i]),
    gsub("\\|", "\\\\|", pc$definition[i])
  ))
}

# Asymmetric bounds detail
asym <- pc[!is.na(pc$suggested_lower_bound) | !is.na(pc$suggested_upper_bound), ]
if (nrow(asym) > 0) {
  lines <- c(lines, "",
    "## Asymmetric (non-symmetric) bounds",
    "",
    "These parameters use absolute IPCC-derived lower/upper bounds rather than a symmetric ±% around the central value.",
    "",
    "| code | lower | central | upper |",
    "|------|-------|---------|-------|"
  )
  for (i in seq_len(nrow(asym))) {
    lines <- c(lines, sprintf("| `%s` | %s | %s | %s |",
      asym$parameter[i],
      fmt_num(asym$suggested_lower_bound[i]),
      fmt_num(asym$ipcc_default[i]),
      fmt_num(asym$suggested_upper_bound[i])
    ))
  }
}

# Tier explanation
lines <- c(lines, "",
  "## Tier meaning",
  "",
  "- **core** = user must provide a value (or accept the IPCC default). These are the activity-data parameters and a handful of high-impact coefficients (DE, CP, MilkPR).",
  "- **advanced** = IPCC equation coefficient. Pre-filled with the IPCC default from the column above; only override if the user has a country-specific measurement.",
  "",
  "## param_type",
  "",
  "- **activity_data** = `N` only (animal population). This is the one true activity-data variable.",
  "- **coefficient** = everything else (production parameters, energy/methane/N₂O coefficients).",
  "",
  "## Distribution codes accepted",
  "",
  paste("`", paste(DISTRIBUTION_TYPES, collapse = "`, `"), "`", sep = ""),
  "",
  "Use `pert` or `triangular` when only a mode + bounds are known; `normal` for symmetric ±% around a measured mean; `beta` or `tnorm_0_1` for fractions that must stay in [0, 1]; `lognormal` for strictly-positive values with right skew (typical for emission factors)."
)

writeLines(lines, file.path(out_dir, "param_catalogue.md"), useBytes = TRUE)
message("✓ wrote param_catalogue.md (", nrow(pc), " parameters)")

# ---------------------------------------------------------------------------
# 2. template_schema.md -- exact sheet/column layout + validation rules
# ---------------------------------------------------------------------------
lines <- c(
  sprintf("# Template schema — auto-generated %s", stamp),
  "",
  "The app expects an `.xlsx` workbook with the sheets and columns below.",
  "Sheet names and column headers are **case-sensitive and must match exactly**.",
  "",
  "## Workbook overview",
  "",
  "| sheet | required? | purpose |",
  "|-------|-----------|---------|",
  "| `_Lists` | optional (hidden) | dropdown vocabularies — created automatically when the user downloads the blank template; safe to omit when you (Claude) build a workbook from scratch |",
  "| `README` | optional | human-readable quick-start — safe to omit |",
  "| `Inventory_Metadata` | **required** | country, year, IPCC version, species |",
  "| `Parameters` | **required** | the 27 parameters per cattle sub-category |",
  "| `Manure_Management` | **required** | per-MMS allocation; per-group fractions must sum to 100% |",
  "| `Parameter_TimeSeries` | optional | 5+ years of annual values for auto-correlation |",
  "| `Vocab` | optional | reference catalogue — safe to omit |",
  "",
  "## Sheet: `Inventory_Metadata`",
  "",
  "Transposed (label/value) layout. Column A is the label, column B is the value.",
  "",
  "| label | value | notes |",
  "|-------|-------|-------|",
  "| country | (free text) | e.g. `Zimbabwe` |",
  "| inventory_year | (integer) | e.g. `2022` |",
  paste0("| species | one of: ", paste(SPECIES_OPTIONS, collapse = " / "), " | controlled vocabulary |"),
  paste0("| ipcc_version | one of: ", paste(IPCC_VERSIONS, collapse = " / "), " | drives MMS list filtering |"),
  "| prepared_by | (free text) | name / institution |",
  "| notes | (free text) | optional |",
  "",
  "## Sheet: `Parameters`",
  "",
  "Header row in row 3. Data starts at row 4. One row per (cattle_type × aggregation_level × sub_category × parameter).",
  "",
  "| col | header | required? | notes |",
  "|-----|--------|-----------|-------|",
  "| A | cattle_type | yes | e.g. `dairy`, `non_dairy` |",
  "| B | aggregation_level | yes | free text label for the inventory grouping |",
  "| C | sub_category | yes | one of the ANIMAL_SUBCATEGORIES below (or free-text if the inventory uses custom groups) |",
  "| D | parameter | yes | the parameter code from param_catalogue.md |",
  "| E | definition | no | optional human label (mirrors param_catalogue) |",
  "| F | unit | no | optional unit (mirrors param_catalogue) |",
  "| G | value | yes | the central value — **the number the user is providing** |",
  "| H | uncertainty_pct | one of (H) or (I/J) | symmetric ±% half-width of 95% CI |",
  "| I | lower_bound | one of (H) or (I/J) | explicit lower bound (use for asymmetric params) |",
  "| J | upper_bound | one of (H) or (I/J) | explicit upper bound |",
  "| K | distribution | yes | one of the codes above |",
  "| L | lower | no | auto-computed from H or I; safe to leave blank |",
  "| M | upper | no | auto-computed from H or J; safe to leave blank |",
  "| N | param_type | yes | `activity_data` (only for `N`) or `coefficient` |",
  "| O | ipcc_ref | no | citation, e.g. `Table 10.4` |",
  "| P | data_source | no | free text: where the value came from |",
  "",
  "### Sub-category codes (ANIMAL_SUBCATEGORIES)",
  ""
)
for (k in seq_along(ANIMAL_SUBCATEGORIES)) {
  lines <- c(lines, sprintf("- `%s` — %s",
    ANIMAL_SUBCATEGORIES[k], ANIMAL_SUBCATEGORY_LABELS[ANIMAL_SUBCATEGORIES[k]]))
}

lines <- c(lines, "",
  "## Sheet: `Manure_Management`",
  "",
  "One row per (cattle_type × aggregation_level × sub_category × mms_type). Per-group rows must sum to fraction_pct = 100.",
  "",
  "| col | header | required? | notes |",
  "|-----|--------|-----------|-------|",
  "| A | cattle_type | yes | matches Parameters sheet |",
  "| B | aggregation_level | yes | matches Parameters sheet |",
  "| C | sub_category | yes | matches Parameters sheet |",
  "| D | mms_type | yes | controlled vocabulary (below) |",
  "| E | fraction_pct | yes | % of manure to this MMS; rows per group must sum to 100 |",
  "| F | MCF_pct | yes | methane conversion factor (%) — see climate-zone lookup |",
  "| G | lower_mcf | no | for asymmetric ranges |",
  "| H | upper_mcf | no | for asymmetric ranges |",
  "| I | distribution_mcf | no | distribution code for MCF |",
  "| J | EF3 | yes | direct N₂O EF (kg N₂O-N/kg N) for this MMS |",
  "| K | lower_ef3 | no | |",
  "| L | upper_ef3 | no | |",
  "| M | distribution_ef3 | no | |",
  "| N | Frac_GasMS_pct | no | per-MMS volatilisation fraction (%) — defaults from IPCC 2019 Table 10.22 |",
  "| O | lower | no | |",
  "| P | upper | no | |",
  "| Q | distribution | no | |",
  "| R | Frac_LeachMS_pct | no | per-MMS leaching fraction (%) — defaults from IPCC 2019 Table 10.23 |",
  "| S | lower | no | |",
  "| T | upper | no | |",
  "| U | distribution | no | |",
  "",
  "### MMS types — by IPCC version",
  ""
)
mms <- MMS_DEFAULTS
lines <- c(lines, "| id | label | 2006? | 2019R? | MCF tropical | MCF temperate | EF3 |",
  "|----|-------|-------|--------|--------------|----------------|-----|")
for (i in seq_len(nrow(mms))) {
  vs <- strsplit(mms$versions[i], ",")[[1]]
  lines <- c(lines, sprintf("| `%s` | %s | %s | %s | %s | %s | %s |",
    mms$id[i], mms$label[i],
    if ("2006" %in% vs) "✓" else "",
    if ("2019" %in% vs) "✓" else "",
    fmt_num(mms$mcf_tropical[i]),
    fmt_num(mms$mcf_temperate[i]),
    fmt_num(mms$ef3[i])
  ))
}

# Per-MMS Frac_Gas / Frac_Leach defaults (2019R)
mfd <- MMS_FRAC_DEFAULTS_2019
lines <- c(lines, "",
  "### Per-MMS volatilisation & leaching defaults (IPCC 2019 Refinement)",
  "",
  "Use these when filling Frac_GasMS_pct and Frac_LeachMS_pct.",
  "",
  "| mms_type | Frac_Gas (mean / low / high) | Frac_Leach (mean / low / high) |",
  "|----------|------------------------------|--------------------------------|"
)
for (i in seq_len(nrow(mfd))) {
  lines <- c(lines, sprintf("| `%s` | %s / %s / %s | %s / %s / %s |",
    mfd$mms_type[i],
    fmt_num(mfd$frac_gas[i]),  fmt_num(mfd$frac_gas_low[i]),  fmt_num(mfd$frac_gas_high[i]),
    fmt_num(mfd$frac_leach[i]),fmt_num(mfd$frac_leach_low[i]),fmt_num(mfd$frac_leach_high[i])
  ))
}

lines <- c(lines, "",
  "## Sheet: `Parameter_TimeSeries` (optional)",
  "",
  "Annual values, used to compute Spearman-rank correlations between activity-data parameters. Minimum 5 years (or 4 if first-difference detrending is used).",
  "",
  "| col | header | notes |",
  "|-----|--------|-------|",
  "| A | cattle_type | optional — blank = applies to all groups |",
  "| B | aggregation_level | optional |",
  "| C | sub_category | optional |",
  "| D | year | required (integer) |",
  "| E–N | N, BW, MW, WG, Milk, Fat, pct_calving, DE, CP, MilkPR | the 10 parameters the app correlates; leave columns blank for parameters not measured |",
  "",
  "## Validation rules the app applies",
  "",
  "These are the checks Claude should run before declaring the workbook ready:",
  "",
  "- **bounds**: `lower ≤ value ≤ upper` for every Parameters row (exception: when `distribution = constant` and all three = 0, e.g. WG for adults, hours for non-working cattle)",
  "- **N ≥ 0** (cattle population can't be negative)",
  "- **DE ∈ [0, 100]**, **Ym > 0**, fractions (`Frac_*`, `pct_calving`, `ASH`, `UE`) ∈ [0, 1]",
  "- **distribution** ∈ DISTRIBUTION_TYPES",
  "- **param_type** ∈ {`activity_data`, `coefficient`}",
  "- **Manure_Management**: per (cattle_type, aggregation_level, sub_category), fraction_pct sums to 100 ± 1",
  "- **Manure_Management**: mms_type must be a valid id for the selected IPCC version",
  "- **Inventory_Metadata.species** ∈ SPECIES_OPTIONS; **ipcc_version** ∈ IPCC_VERSIONS",
  "",
  "## Distribution choice guide",
  "",
  "When the user gives you a value but no distribution, pick from this priority list:",
  "",
  "1. If the parameter has an asymmetric IPCC range (EF3_PRP, EF3_S, EF4, EF5, Frac_GASMS, Frac_LEACH_*) → use **`lognormal`** or **`pert`** with the absolute bounds from the asymmetric table in param_catalogue.md.",
  "2. If the parameter is a fraction bounded in [0, 1] (pct_calving, ASH, UE, manure fractions) → **`beta`** or **`tnorm_0_1`**.",
  "3. If the central value comes from a measured mean ± SD or ±CV → **`normal`**.",
  "4. If only min / mode / max are known (expert judgement) → **`pert`** (preferred) or **`triangular`**.",
  "5. If the parameter is structurally constant (WG = 0 for adults, hours = 0 for non-working cattle) → **`constant`**, lower = value = upper.",
  ""
)

writeLines(lines, file.path(out_dir, "template_schema.md"), useBytes = TRUE)
message("✓ wrote template_schema.md")

# ---------------------------------------------------------------------------
# 3. Stage user-facing assets into www/ so the Shiny app can serve them.
# Only the files end-users need to download go to www/ — system_instructions.md
# and the README stay in claude_project_assets/ for the maintainer.
# ---------------------------------------------------------------------------
www_dir <- "www"
if (!dir.exists(www_dir)) dir.create(www_dir, recursive = TRUE)
user_facing <- c("questionnaire.md", "getting_started.md",
                 "param_catalogue.md", "template_schema.md")
for (f in user_facing) {
  src <- file.path(out_dir, f)
  dst <- file.path(www_dir, f)
  if (file.exists(src)) file.copy(src, dst, overwrite = TRUE)
}
message("✓ staged ", length(user_facing), " files into ", www_dir, "/")

# ---------------------------------------------------------------------------
# 3b. Convert getting_started.md and questionnaire.md to PDF + DOCX if pandoc
# is available. PDF prefers xelatex (good Unicode coverage); falls back to the
# pandoc default engine if xelatex is missing. Both PDF and DOCX are staged in
# claude_project_assets/ (canonical) and copied to www/ (served by Shiny).
# ---------------------------------------------------------------------------
# Locate xelatex. R's child-process PATH doesn't always include MiKTeX/TinyTeX
# even when the shell does, so we also check the usual Windows install dirs.
find_xelatex <- function() {
  hit <- Sys.which("xelatex")
  if (nzchar(hit) && file.exists(hit)) return(unname(hit))
  candidates <- c(
    file.path(Sys.getenv("LOCALAPPDATA"),
              "Programs/MiKTeX/miktex/bin/x64/xelatex.exe"),
    file.path(Sys.getenv("APPDATA"),
              "TinyTeX/bin/windows/xelatex.exe"),
    "C:/Program Files/MiKTeX/miktex/bin/x64/xelatex.exe",
    "C:/texlive/2024/bin/windows/xelatex.exe",
    "/usr/bin/xelatex", "/usr/local/bin/xelatex"
  )
  for (p in candidates) if (file.exists(p)) return(p)
  ""
}

pandoc_bin <- Sys.which("pandoc")
if (nzchar(pandoc_bin)) {
  xelatex_bin <- find_xelatex()
  has_xelatex <- nzchar(xelatex_bin)
  if (has_xelatex) {
    # Pandoc finds xelatex by name only if its dir is on PATH — prepend it.
    Sys.setenv(PATH = paste(dirname(xelatex_bin), Sys.getenv("PATH"),
                             sep = .Platform$path.sep))
    message("  (using xelatex at ", xelatex_bin, ")")
  }
  to_convert <- c("getting_started.md", "questionnaire.md")
  for (md in to_convert) {
    src <- file.path(out_dir, md)
    if (!file.exists(src)) next
    base <- tools::file_path_sans_ext(md)
    pdf_out  <- file.path(out_dir, paste0(base, ".pdf"))
    docx_out <- file.path(out_dir, paste0(base, ".docx"))

    pdf_args <- c(src, "-o", pdf_out, "--standalone",
                  if (has_xelatex) c("--pdf-engine=xelatex",
                                     "-V", "geometry:margin=2cm",
                                     "-V", "mainfont=Calibri",
                                     "-V", "monofont=Consolas"))
    pdf_status <- tryCatch(
      system2(pandoc_bin, pdf_args, stdout = TRUE, stderr = TRUE),
      error = function(e) NULL)
    if (file.exists(pdf_out)) {
      file.copy(pdf_out, file.path(www_dir, basename(pdf_out)), overwrite = TRUE)
      message("✓ ", basename(pdf_out), "  (", file.info(pdf_out)$size, " bytes)")
    } else {
      message("✗ PDF conversion failed for ", md,
              " — install xelatex/MiKTeX or check the pandoc log")
    }

    docx_status <- tryCatch(
      system2(pandoc_bin, c(src, "-o", docx_out, "--standalone"),
              stdout = TRUE, stderr = TRUE),
      error = function(e) NULL)
    if (file.exists(docx_out)) {
      file.copy(docx_out, file.path(www_dir, basename(docx_out)), overwrite = TRUE)
      message("✓ ", basename(docx_out), "  (", file.info(docx_out)$size, " bytes)")
    } else {
      message("✗ DOCX conversion failed for ", md)
    }
  }
} else {
  message("(pandoc not found on PATH — skipping PDF/DOCX conversion. Install pandoc to enable.)")
}

# ---------------------------------------------------------------------------
# 4. Quick smoke-check
# ---------------------------------------------------------------------------
message("\nFiles in ", out_dir, "/:")
for (f in list.files(out_dir, full.names = TRUE))
  message("  ", basename(f), "  (", file.info(f)$size, " bytes)")

invisible(NULL)
