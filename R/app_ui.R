# Master UI Function
app_ui <- function() {
  bslib::page_navbar(
    id = "nav",
    # Round 9 follow-up: stacked header — big centered title row above the
    # tabs row. Title + subtitle live inside a flex column; CSS in
    # www/custom.css turns the navbar into vertical layout (title above
    # tabs) and centers both rows. The bg=transparent on .app-title keeps
    # the navbar's existing background.
    title = tags$div(
      class = "app-title-block",
      tags$div(class = "app-title",
                "IPCC Tier 2 Livestock GHG Uncertainty Calculator"),
      tags$div(class = "app-subtitle",
                "Approach 2 Monte Carlo · CGIAR Alliance / Bioversity-CIAT · funded by the Global Methane Hub")
    ),
    theme = bslib::bs_theme(
      version = 5,
      primary = "#2D6A4F",
      secondary = "#40916C",
      success = "#2D6A4F",
      bg = "#F7F5F0",
      fg = "#1A1A1A",
      base_font = bslib::font_google("DM Sans"),
      code_font = bslib::font_google("JetBrains Mono")
    ),
    header = tags$head(tags$link(rel = "stylesheet", href = "custom.css")),
    fillable = FALSE,

    # ==================== HOME TAB ====================
    bslib::nav_panel(
      title = "Home",
      icon = icon("home"),
      div(
        style = "max-width: 960px; margin: 0 auto; padding: 24px;",

        # Hero section
        div(
          style = "background: linear-gradient(135deg, #1B4332 0%, #2D6A4F 50%, #40916C 100%);
                   color: white; border-radius: 16px; padding: 48px 40px; margin-bottom: 32px;
                   position: relative; overflow: hidden;",
          h1("IPCC Tier 2 Livestock GHG Uncertainty Calculator",
             style = "font-size: 2rem; font-weight: 700; margin-bottom: 12px;"),
          p("Monte Carlo uncertainty analysis for national cattle methane and nitrous oxide inventories.",
            style = "font-size: 1.1rem; opacity: 0.9; margin-bottom: 8px;"),
          p("Developed by CIAT/CGIAR Alliance | Funded by Global Methane Hub",
            style = "font-size: 0.9rem; opacity: 0.7;"),
          div(
            style = "display: flex; gap: 10px; margin-top: 20px; flex-wrap: wrap;",
            tags$span(style = "background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.25);
                               padding: 4px 14px; border-radius: 20px; font-size: 0.8rem;",
                      "IPCC Tier 2 · Approach 2"),
            tags$span(style = "background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.25);
                               padding: 4px 14px; border-radius: 20px; font-size: 0.8rem;",
                      "Monte Carlo — 10,000+ runs"),
            tags$span(style = "background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.25);
                               padding: 4px 14px; border-radius: 20px; font-size: 0.8rem;",
                      "Activity data + coefficient uncertainty"),
            tags$span(style = "background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.25);
                               padding: 4px 14px; border-radius: 20px; font-size: 0.8rem;",
                      "CH₄ + N₂O · 5 emission sources"),
            tags$span(style = "background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.25);
                               padding: 4px 14px; border-radius: 20px; font-size: 0.8rem;",
                      "IPCC Table 3.3 export-ready"),
            tags$span(style = "background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.25);
                               padding: 4px 14px; border-radius: 20px; font-size: 0.8rem;",
                      "Sensitivity tornado + decomposition")
          )
        ),

        # What this tool does
        bslib::card(
          bslib::card_header(h4("What does this tool do?", style = "margin: 0;")),
          bslib::card_body(
            p("When a country reports cattle greenhouse gas emissions under the Paris Agreement, every input parameter
              (animal populations, body weights, feed quality, emission factors) has some uncertainty. This tool:"),
            tags$ol(
              tags$li("Takes your country-specific Tier 2 input data with uncertainty ranges"),
              tags$li("Runs thousands of Monte Carlo simulations, varying all parameters according to their probability distributions"),
              tags$li("Produces the uncertainty range for your total emission estimate (95% confidence interval)"),
              tags$li("Identifies which parameters contribute most to the uncertainty (sensitivity analysis)"),
              tags$li("Formats results for IPCC inventory reporting (Table 3.3)")
            ),
            p(tags$strong("Emission sources covered:"),
              " Enteric fermentation CH4, Manure management CH4, Manure management N2O (direct and indirect),
              and N2O from dung/urine deposited on pasture.")
          )
        ),

        # Workflow overview
        bslib::card(
          bslib::card_header(h4("How to use this tool -- Step by step", style = "margin: 0;")),
          bslib::card_body(
            p("Work through the tabs from left to right. Each tab has instructions at the top explaining what to do."),
            tags$table(
              style = "width: 100%; border-collapse: collapse; margin-top: 8px;",
              tags$thead(
                tags$tr(style = "background: #D8F3DC; text-align: left;",
                  tags$th(style = "padding: 10px; border: 1px solid #E0DDD5;", "Step"),
                  tags$th(style = "padding: 10px; border: 1px solid #E0DDD5;", "Tab"),
                  tags$th(style = "padding: 10px; border: 1px solid #E0DDD5;", "What you do"),
                  tags$th(style = "padding: 10px; border: 1px solid #E0DDD5;", "Time")
                )
              ),
              tags$tbody(
                tags$tr(
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "1"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5; font-weight: 600; color: #2D6A4F;", "Data Input"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "Load example data or upload your country data from the Excel template"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "5 min")
                ),
                tags$tr(style = "background: #FAFAF7;",
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "2"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5; font-weight: 600; color: #2D6A4F;", "QA/QC"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "Review automated quality checks -- fix any fails and document large deviations from IPCC defaults"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "5 min")
                ),
                tags$tr(
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "3"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5; font-weight: 600; color: #2D6A4F;", "Uncertainty"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "Review and adjust probability distributions and uncertainty ranges for each parameter"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "10 min")
                ),
                tags$tr(style = "background: #FAFAF7;",
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "4"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5; font-weight: 600; color: #2D6A4F;", "Correlations"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "(Optional) Upload population time series or manually define correlations between activity data"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "5 min")
                ),
                tags$tr(
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "5"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5; font-weight: 600; color: #2D6A4F;", "Simulate"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "Choose number of iterations, GWP version, and click Run"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "1-2 min")
                ),
                tags$tr(style = "background: #FAFAF7;",
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "6"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5; font-weight: 600; color: #2D6A4F;", "Results"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "View emission distributions, uncertainty ranges (95% CI), and decomposition"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "5 min")
                ),
                tags$tr(
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "7"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5; font-weight: 600; color: #2D6A4F;", "Sensitivity"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "Identify which parameters contribute most to uncertainty (tornado chart)"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "5 min")
                ),
                tags$tr(style = "background: #FAFAF7;",
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "8"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5; font-weight: 600; color: #2D6A4F;", "IPCC Report"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "Download results formatted as IPCC Table 3.3 for your inventory submission"),
                  tags$td(style = "padding: 8px; border: 1px solid #E0DDD5;", "2 min")
                )
              )
            ),
            br(),
            div(class = "info-panel",
                tags$strong("Quick start: "),
                "To try the tool immediately, go to ",
                tags$strong("1. Data Input"), ", select 'Country X (hypothetical dairy)', then go to ",
                tags$strong("5. Simulate"), " and click 'Run Monte Carlo Simulation'.")
          )
        ),

        # T0.4: prerequisites & limitations
        bslib::card(
          bslib::card_header(h4("Before you start", style = "margin: 0;")),
          bslib::card_body(
            tags$p(tags$strong("You will need:")),
            tags$ul(
              tags$li("A Tier 2 input dataset for the inventory year(s) you wish to assess: ",
                      "animal sub-categories with population, body weights, feed quality, and manure-management shares."),
              tags$li("A defensible estimate of the uncertainty in each input (typically ±% half-width of the 95 % CI, or ",
                      "lower / upper bounds for asymmetric parameters). The tool ", tags$strong("does not"),
                      " estimate input uncertainties for you."),
              tags$li("Optional but recommended: multi-year time series of activity data, used to compute correlations automatically.")
            ),
            tags$p(tags$strong("What this tool does NOT do:")),
            tags$ul(
              tags$li("It does not collect data or estimate input uncertainties — those must be supplied by the user."),
              tags$li("It does not produce Tier 1 estimates — the IPCC Tier 2 equation chain is required."),
              tags$li("It does not validate your country's IPCC categorisation choices — sub-category structure is the user's responsibility."),
              tags$li("Cross-block correlations between activity data and emission factors are not yet supported (planned for v3.0).")
            )
          )
        ),
        # R1.11: single-year vs trend choice on the Home page
        bslib::card(
          bslib::card_header(h4("Choose your analysis mode", style = "margin: 0;")),
          bslib::card_body(
            radioButtons("analysis_mode",
              label = NULL,
              choices = c(
                "Single year — quantify uncertainty in one inventory year" = "single",
                "Trend — compare uncertainty across multiple years (uses Tab 9)"   = "trend"
              ),
              selected = character(0)),
            div(id = "analysis_mode_warning",
                style = "background:#FEF3C7; border-left:3px solid #F59E0B; padding:8px 10px; margin-top:8px; font-size:0.85rem; color:#92400E; border-radius:4px;",
                icon("exclamation-triangle"),
                tags$strong(" Selection required: "),
                "pick Single year or Trend before moving on. The Run button on Tab 5 will block until a mode is chosen."),
            tags$p(tags$em("IPCC Volume 1 Chapter 3 recommends running uncertainty analysis ",
                           "for both the first and last year of an inventory and quantifying the ",
                           "trend uncertainty. Use 'Trend' if you have multi-year data; use ",
                           "'Single year' for a one-off uncertainty estimate."),
                   style = "color:#555; font-size:0.85rem; margin-top:8px;")
          )
        )
      )
    ),

    # ==================== DEFINITIONS TAB (T1.4 + R1.7 + R1.8) ====================
    bslib::nav_panel(
      title = "Definitions",
      icon = icon("book"),
      div(class = "info-panel", style = "margin: 16px;",
          tags$strong("Parameter glossary. "),
          "All parameters used in the IPCC Tier 2 calculations, with their plain-language ",
          "definition, unit, IPCC default value, suggested distribution, tier (core / technical), ",
          "IPCC framing (activity data vs coefficient), and IPCC reference table or equation. ",
          "Variable names match the ", tags$strong("IPCC Inventory Software"),
          " v2.95 nomenclature directly.")
      ,
      bslib::card(
        bslib::card_header("Parameter definitions"),
        bslib::card_body(DT::DTOutput("definitions_table"))
      )
    ),

    # ==================== USEFUL RESOURCES TAB (T0.2) ====================
    bslib::nav_panel(
      title = "Resources",
      icon = icon("book-open"),
      div(style = "max-width: 960px; margin: 0 auto; padding: 24px;",
        bslib::card(
          bslib::card_header(h4("Useful resources", style = "margin: 0;")),
          bslib::card_body(
            tags$h5("Methodological foundations"),
            tags$ul(
              tags$li(tags$a(href = "https://www.ipcc-nggip.iges.or.jp/public/2006gl/vol4.html",
                             target = "_blank",
                             "IPCC 2006 Guidelines — Volume 4 (AFOLU), Chapters 10 & 11")),
              tags$li(tags$a(href = "https://www.ipcc-nggip.iges.or.jp/public/2019rf/vol4.html",
                             target = "_blank",
                             "2019 Refinement to the 2006 IPCC Guidelines — Volume 4")),
              tags$li(tags$a(href = "https://www.ipcc-nggip.iges.or.jp/public/2006gl/vol1.html",
                             target = "_blank",
                             "IPCC 2006 Guidelines — Volume 1, Chapter 3 (Uncertainties)"))
            ),
            tags$h5("Activity data guidance"),
            tags$ul(
              tags$li(tags$a(href = "https://www.fao.org/livestock-systems/global-distributions/en/",
                             target = "_blank",
                             "FAO Livestock Activity Data Guidelines (L-ADG)")),
              tags$li("Penman et al. (2000) — Good Practice Guidance and Uncertainty Management in National Greenhouse Gas Inventories"),
              tags$li("Monni et al. (2007) — Uncertainty in agricultural CH4 and N2O emissions from Finland")
            ),
            tags$h5("Distributions and Monte Carlo references"),
            tags$ul(
              tags$li("Frey & Rhodes (1998) — Characterizing, simulating, and analyzing variability and uncertainty"),
              tags$li("IPCC GPG 2000 §6 — Quantifying uncertainties in practice (Approach 1 vs Approach 2)")
            ),
            tags$h5("Case studies"),
            tags$ul(
              tags$li("Karimi-Zindashty et al. (2012) — Sources of uncertainty in livestock emission inventories: Canadian case study"),
              tags$li("Milne et al. (2014) — Estimating uncertainty in pasture-based dairy CH4 emissions")
            )
          )
        )
      )
    ),

    # ==================== TAB 1: DATA INPUT ====================
    bslib::nav_panel(
      title = "1. Data Input",
      icon = icon("upload"),
      div(class = "info-panel", style = "margin: 16px;",
          tags$strong("What to do: "),
          "Select an example country dataset from the dropdown, or upload your own data using the Excel template. ",
          "The parameter table on the right shows the loaded data -- ",
          "you can click on any cell to edit values directly. Check the validation panel at the bottom left to ",
          "ensure your data is complete and valid before proceeding to the next tab."),
      bslib::layout_sidebar(
        sidebar = bslib::sidebar(
          width = 320,
          h5("Data Source"),
          selectInput("country", "Country / Example Data",
                      choices = c("Country X (hypothetical dairy)" = "uganda",
                                  "Country Y (hypothetical pastoral)" = "zimbabwe",
                                  "Custom Upload" = "custom")),
          # B1: explicit hint when "Custom Upload" selected so the user knows the
          # dropdown registered (the example tables don't auto-load for "custom")
          conditionalPanel(
            condition = "input.country == 'custom'",
            div(style = "background:#FEF3C7; border-left:3px solid #F59E0B; padding:8px 10px; margin-top:8px; font-size:0.85rem; color:#92400E; border-radius:4px;",
                icon("info-circle"),
                " Custom mode selected. Use the file uploader below to load your own template. ",
                "The data preview will appear once your file uploads successfully.")
          ),
          hr(),
          h5("Custom Data Upload"),
          fileInput("data_upload", "Upload Excel Template (.xlsx)",
                    accept = ".xlsx"),
          # Round 7.1 (Andreas Template #3 follow-up): IPCC version picker so
          # the downloaded template's MMS dropdown filters to the systems
          # valid for that version (and the Inventory_Metadata `ipcc_version`
          # cell is pre-set to match). Previously a single template shipped
          # with all 12 MMS entries regardless of version, deferring the
          # mismatch to upload-time validation only.
          radioButtons("template_version", "IPCC Guidelines version for template",
                        choices = c("IPCC 2006" = "2006",
                                    "IPCC 2019 Refinement" = "2019_refinement"),
                        selected = "2006", inline = TRUE),
          div(style = "font-size:0.78rem; color:#666; margin-top:-6px; margin-bottom:8px;",
              tags$em("The MMS dropdown in the downloaded template will be filtered to manure systems valid for the version you pick here.")),
          downloadButton("download_template", "Download Blank Template",
                         class = "btn-outline-success btn-sm"),
          downloadButton("download_template_example", "Download Template with Example",
                         class = "btn-outline-primary btn-sm mt-2"),
          hr(),
          h5("Validation"),
          uiOutput("validation_status")
        ),
        bslib::card(
          bslib::card_header("Parameter Data"),
          bslib::card_body(DT::DTOutput("param_table"))
        )
      )
    ),

    # ==================== TAB 2: QA/QC ====================
    bslib::nav_panel(
      title = "2. QA/QC",
      icon = icon("check-square"),
      div(class = "info-panel", style = "margin: 16px;",
          tags$strong("What to do: "),
          "After loading data, review these automated quality checks. Each row flags a specific check for one parameter. ",
          tags$strong("Missing"), " (amber) = the parameter was not in your upload and was auto-filled from the IPCC default — verify or replace with country data. ",
          tags$strong("Fail"), " (red) = the value or bounds will likely cause an error in the simulation. ",
          tags$strong("Warn"), " (amber) = the value is unusual compared with IPCC defaults or Penman/Monni uncertainty references -- investigate and document. ",
          tags$strong("Pass"), " (green) = check satisfied. ",
          "Fix any fails before running the simulation. Warnings are advisory -- document your justification for large deviations from IPCC defaults."),
      conditionalPanel(
        condition = "output.has_imputed_params == true",
        div(style = "margin: 0 16px 16px 16px;",
            bslib::card(
              style = "border-left: 4px solid #F59E0B;",
              bslib::card_header(
                style = "background-color:#FEF3C7; color:#92400E; font-weight:600;",
                icon("triangle-exclamation"), " Auto-filled parameters"
              ),
              bslib::card_body(uiOutput("imputed_params_card"))
            ))
      ),
      bslib::layout_columns(
        col_widths = c(3, 9),
        bslib::card(
          bslib::card_header("Summary"),
          bslib::card_body(
            uiOutput("qaqc_summary_ui"),
            hr(),
            p(style = "font-size:0.83rem; color:#555;",
              "Checks run: bounds order, non-negative bounds, ",
              "valid ranges (DE_pct, Ym_pct, fractions), ",
              "distribution suitability (beta/lognormal/tnorm_0_1), ",
              "benchmark deviation vs. IPCC defaults (>50% = warn, >200% = fail), ",
              "and asymmetric-distribution warning for EF3/EF4/EF5/Frac_LEACH.")
          )
        ),
        bslib::card(
          bslib::card_header("QA/QC Results"),
          bslib::card_body(DT::DTOutput("qaqc_table"))
        )
      )
    ),

    # ==================== TAB 3: UNCERTAINTY ====================
    bslib::nav_panel(
      title = "3. Uncertainty",
      icon = icon("sliders-h"),
      div(class = "info-panel", style = "margin: 16px;",
          # A2: paragraphs cleanly separated to avoid mid-sentence break
          tags$p(
            tags$strong("What to do: "),
            "Review and adjust each parameter's probability distribution and uncertainty range. ",
            "Click any cell in the table below to edit the distribution type ",
            "(normal, lognormal, beta, triangular, pert, uniform, constant), ",
            "the uncertainty percentage, or the lower/upper bounds."
          ),
          tags$p(
            tags$strong("Note on triangular distributions: "),
            tags$em(
              "triangular is most often used when only the minimum, most-likely (mode), and maximum are known. ",
              "The tool treats lower/upper as ", tags$strong("absolute min/max"),
              ", not 95% CI bounds — for triangular, those are usually the same. ",
              "If you have a 95% CI but want a triangular shape, use PERT instead ",
              "(PERT uses the 95% bounds and a most-likely value)."
            )
          ),
          tags$p(
            tags$strong("Quick-set buttons"),
            " at the bottom of the table apply common settings to all parameters of one type ",
            "(e.g. 'Set all activity data to Normal ±15%')."
          )),
      bslib::card(
        bslib::card_header("Distribution & Uncertainty Specification"),
        bslib::card_body(DT::DTOutput("uncertainty_table")),
        # R2.1: quick-set buttons moved into card_footer so they remain visible
        # regardless of how tall the DT grows (pageLength = 20 was pushing them
        # below the fold). Labels rewritten in IPCC-aligned wording.
        bslib::card_footer(
          fluidRow(
            column(5, actionButton(
              "set_all_normal",
              label = textOutput("quickset_normal_label", inline = TRUE),
              class = "btn-outline-success btn-sm w-100")),
            column(5, actionButton(
              "set_all_pert",
              label = textOutput("quickset_pert_label", inline = TRUE),
              class = "btn-outline-primary btn-sm w-100"))
          ),
          tags$p(style = "font-size:0.78rem; color:#666; margin-top:6px;",
                 tags$em("Click a preset to apply; click the same button again to undo and restore your previous values."))
        )
      )
    ),

    # ==================== TAB 4: CORRELATIONS ====================
    bslib::nav_panel(
      title = "4. Correlations",
      icon = icon("th"),
      div(class = "info-panel", style = "margin: 16px;",
          tags$strong("What to do (optional): "),
          "Define correlations for activity data and/or emission factors. ",
          "Correlations produce more realistic uncertainty estimates when parameters tend to move together. ",
          "If you have no information, leave both sections at 'No correlations' (the default).",
          tags$br(), tags$br(),
          # T4.2: extended guidance
          tags$strong("When to use correlations: "),
          tags$ul(
            tags$li(tags$strong("Activity data — from time series:"),
                    " upload multi-year national livestock data in the Parameter_TimeSeries sheet. ",
                    "Year-to-year co-movement is computed automatically (Pearson correlation, then nearest positive-definite). ",
                    "This is the recommended option whenever you have ≥5 years of data."),
            tags$li(tags$strong("Activity data — manual entry (advanced):"),
                    " hide-and-seek option for users who have expert estimates of pairwise correlations. ",
                    "Most users should leave this alone."),
            tags$li(tags$strong("Emission factors — uniform rho:"),
                    " a single number (rho ∈ [0, 0.9]) representing systematic methodological bias shared across ",
                    "all IPCC equation parameters. Use ρ = 0.3 as a moderate sensitivity test if you suspect bias; ",
                    "values above 0.5 require explicit justification.")
          )),
      bslib::layout_columns(
        col_widths = c(6, 6),

        # --- Activity data correlations ---
        bslib::card(
          bslib::card_header("Activity Data Correlations"),
          bslib::card_body(
            div(class = "info-panel",
                "Activity data correlations are specified via the ",
                tags$strong("Parameter_TimeSeries"), " sheet in your main input template. ",
                "Fill in one row per year for the parameters you have historical data for, then ",
                "upload the template in ", tags$strong("Tab 1. Data Input"), ". ",
                "The correlation matrix is computed automatically on upload. ",
                "You only need columns for parameters you have data for — absent parameters are treated as uncorrelated."),
            # T4.1 / Tx.2: simplified default UI; manual entry hidden under Advanced
            radioButtons("corr_mode", "Mode",
                         choices = c("No correlations"        = "none",
                                     "From template (auto, time-series)" = "timeseries",
                                     "IPCC-guidance preset"   = "preset",
                                     "Advanced — manual entry"= "manual"),
                         selected = "none"),
            # Group selector for time-series mode (Andreas: "correlate within all AD / population only / intake only")
            conditionalPanel(
              condition = "input.corr_mode == 'timeseries'",
              radioButtons("corr_group_scope", "Apply correlations within:",
                           choices = c(
                             "All AD parameters"                     = "all",
                             "Population-related only (N, W, MW, WG)" = "population",
                             "Intake / feed-quality only (DE_pct, CP_pct, Cfi, Ca, etc.)"      = "intake"
                           ),
                           selected = "all"),
              uiOutput("corr_ts_status")
            ),
            conditionalPanel(
              condition = "input.corr_mode == 'preset'",
              div(class = "info-panel",
                  tags$strong("IPCC-guidance preset: "),
                  "applies a sparse correlation matrix with only well-documented structural pairs ",
                  "(e.g. W ↔ MW, Milk ↔ Fat). ",
                  "All other pairs are zero. Use this when you have no time series but want some realism beyond independence.")
            ),
            conditionalPanel(
              condition = "input.corr_mode == 'manual'",
              div(class = "info-panel",
                  tags$strong("Advanced — manual matrix entry. "),
                  "Upload a CSV with parameter names as both column headers and the first column. ",
                  "Values must be in [-1, 1] with the diagonal = 1. ",
                  "Recommended only for experienced users — most cases are covered by the time-series or preset options."),
              fileInput("corr_matrix_upload", "Upload correlation matrix (.csv)",
                        accept = ".csv")
            ),
            plotly::plotlyOutput("corr_heatmap", height = "350px")
          )
        ),

        # --- Emission factor correlations ---
        bslib::card(
          bslib::card_header("Coefficient Correlations (per-head EF inputs)"),
          bslib::card_body(
            div(class = "info-panel",
                "Systematic biases in IPCC methodology (e.g., the Ym% equation) can cause all emission factors ",
                "to be over- or under-estimated together. A ", tags$strong("uniform correlation"),
                " (single rho) captures this assumption. ",
                tags$em("Default is no EF correlation — a simplifying assumption used when no information on correlations is available. IPCC Approach 2 recommends incorporating known correlations where they exist.")),
            radioButtons("ef_corr_mode", "Mode",
                         choices = c("No EF correlations (default)" = "none",
                                     "Uniform EF correlation"       = "uniform")),
            conditionalPanel(
              condition = "input.ef_corr_mode == 'uniform'",
              sliderInput("ef_corr_rho", "Uniform correlation coefficient (rho)",
                          min = 0.0, max = 0.9, value = 0.3, step = 0.05),
              div(style = "font-size:0.82rem; color:#555; margin-top:4px;",
                  "rho = 0 = independent (same as 'No EF correlations'). ",
                  "rho = 0.3 is a moderate assumption; values above 0.5 are strong and should be justified.")
            ),
            plotly::plotlyOutput("ef_corr_heatmap", height = "350px")
          )
        )
      )
    ),

    # ==================== TAB 5: SIMULATE & RESULTS (merged, B2) ====================
    bslib::nav_panel(
      title = "5. Simulate & Results",
      icon = icon("play"),
      value = "5. Simulate & Results",
      div(class = "info-panel", style = "margin: 16px;",
          tags$strong("What to do: "),
          "Configure simulation settings on the left, then click ",
          tags$strong("'Run Monte Carlo Simulation'"), ". ",
          "The tool will sample all parameters from their distributions and run the IPCC equation chain ",
          "thousands of times. Use 10,000 iterations for reliable results (1,000 for quick testing). ",
          tags$br(), tags$br(),
          tags$strong("Once the simulation completes, this tab switches to the results view automatically."),
          " Use the ", tags$em("Back to settings"), " button at the top of the results to change inputs and re-run — the next run will switch back to results when it finishes. ",
          "Tab 7 (Sensitivity) and Tab 8 (IPCC Report) provide deeper drill-downs."),
      # R1.5: view toggle — output.sim_view is "settings" or "results"
      conditionalPanel(
        condition = "output.sim_view != 'results'",
        bslib::layout_columns(
        col_widths = c(4, 8),
        bslib::card(
          bslib::card_header("Simulation Settings"),
          bslib::card_body(
            sliderInput("n_iter", "Number of Iterations",
                        min = 1000, max = 50000, value = 10000, step = 1000),
            numericInput("seed", "Random Seed (for reproducibility)", value = 42),
            # Round 7 T4.21: Dirichlet MMS allocation precision per IPCC 2019
            # Box 3.1A. Higher concentration = tighter sampling around the user's
            # stated MMS percentages. 50 ≈ ±5pp jitter on a 50/50 split.
            # Set to 0 to disable Dirichlet sampling and use deterministic
            # MMS shares (pre-Round-7 behaviour).
            numericInput("mms_concentration",
                          "MMS allocation precision (Dirichlet concentration)",
                          value = 50, min = 0, max = 10000, step = 10),
            div(style = "font-size:0.78rem; color:#666; margin-top:-6px; margin-bottom:8px;",
                tags$em("0 = deterministic (no MMS uncertainty). 50 ≈ ±5pp on a 50/50 split. Higher = tighter around your stated percentages.")),
            selectInput("gwp_version", "GWP Assessment Report",
                        choices = c("AR4 (CH4=25)" = "AR4",
                                    "AR5 (CH4=28, N2O=265)" = "AR5",
                                    "AR6 (CH4=27.9, N2O=273)" = "AR6"),
                        selected = "AR5"),
            # T1.12 / R1.4: emission source selector — none ticked by default,
            # forcing the user to make an explicit choice before running.
            checkboxGroupInput("emission_sources", "Emission sources to include",
                               choices = c(
                                 "Enteric fermentation CH4"      = "enteric_ch4",
                                 "Manure management CH4"         = "manure_ch4",
                                 "Manure management N2O direct"  = "manure_n2o_direct",
                                 "Manure management N2O indirect"= "manure_n2o_indirect",
                                 "Pasture deposition N2O"        = "pasture_n2o"
                               ),
                               selected = character(0)),
            div(style = "font-size:0.78rem; color:#92400E; background:#FEF3C7; padding:8px 10px; border-radius:6px; margin-bottom:8px;",
                icon("exclamation-triangle"),
                tags$strong(" Tick at least one source above"),
                " — the simulation cannot run without an explicit selection. ",
                tags$em("(Most users tick all 5 for a full inventory.)")),
            hr(),
            # E1, E3: IPCC software-aligned optional inputs (collapsible)
            tags$details(
              tags$summary(tags$strong("IPCC software-aligned options (advanced)")),
              div(style = "padding: 8px 4px;",
                  numericInput("tw",
                               "Mean daily temperature in winter, Tw (°C)",
                               value = 20, min = -40, max = 40, step = 1),
                  div(style = "font-size:0.75rem; color:#666; margin-top:-8px; margin-bottom:8px;",
                      tags$em("Triggers IPCC cold-climate Cfi adjustment when Tw < 20°C: Cfi(in_cold) = Cfi + 0.0048 × (20 − Tw). Leave at 20 for tropical / temperate regions.")),
                  sliderInput("pct_calving",
                              "Fraction of females that calve in a year (Cp pro-rate)",
                              min = 0, max = 1, value = 1, step = 0.05),
                  div(style = "font-size:0.75rem; color:#666; margin-top:-8px; margin-bottom:8px;",
                      tags$em("Pro-rates Cp for the share of cows actually pregnant in the year (IPCC software 'Pregnancy fraction')."))
              )
            ),
            hr(),
            # Round 9: single-year-only options (decomposition + comparison).
            # Trend mode doesn't use these — the trend's IPCC-§3.7 framework
            # already separates AD vs coefficient via the year_corr radio.
            conditionalPanel(
              condition = "input.analysis_mode != 'trend'",
              checkboxInput("run_decomposition", "Run uncertainty decomposition (AD/EF/Combined)",
                            value = TRUE),
              # Round 6a #5: rendered server-side so we can grey it out when no
              # correlations are selected on Tab 4 (the comparison would be
              # identical, so the toggle is meaningless).
              uiOutput("run_comparison_ui")
            ),
            # Round 9: trend-only settings (year-correlation mode + optional
            # CSV override). Visible only when 'trend' is picked on Home.
            conditionalPanel(
              condition = "input.analysis_mode == 'trend'",
              hr(),
              radioButtons("year_corr", "Year-to-year correlation",
                            choices = c(
                              "Fully correlated coefficients (IPCC 2019 default)" = "full",
                              "Partial (AR(1), ρ=0.7)"                       = "partial",
                              "Independent (no year-to-year correlation)"         = "none"),
                            selected = "full"),
              div(style = "font-size:0.78rem; color:#666; margin-top:-6px; margin-bottom:8px;",
                  tags$em("IPCC 2019 §3.2.2.4: emission factor uncertainties tend to be fully correlated across years, while activity data are usually re-estimated annually. The default reuses the same coefficient draws every year so the trend reflects AD changes only.")),
              div(style = "font-size:0.78rem; color:#92400E; background:#FEF3C7; padding:6px 10px; border-radius:4px; margin-bottom:8px;",
                  icon("info-circle"),
                  tags$em(" Trend mode runs n_iter simulations ", tags$strong("per year"),
                          " — total compute = n_iter × number of years.")),
              tags$details(
                tags$summary(tags$strong("Optional: override with separate CSV")),
                div(style = "padding: 6px 0;",
                    fileInput("trend_upload",
                      "Upload multi-year CSV (year, parameter, mean, uncertainty_pct)",
                      accept = c(".csv")),
                    div(style = "font-size:0.78rem; color:#666;",
                        tags$em("If a CSV is uploaded here, it takes precedence over the template's Parameter_TimeSeries sheet for this run.")))
              )
            ),
            hr(),
            # Round 9: route the Run button by mode. Single-year shows the
            # MC button (existing handler), trend shows Run Trend (existing
            # observeEvent(input$run_trend) handler).
            conditionalPanel(
              condition = "input.analysis_mode != 'trend'",
              actionButton("run_sim", "Run Monte Carlo Simulation",
                           class = "run-btn w-100", icon = icon("play"))
            ),
            conditionalPanel(
              condition = "input.analysis_mode == 'trend'",
              actionButton("run_trend", "Run Trend Analysis",
                           class = "run-btn w-100", icon = icon("play")),
              hr(),
              uiOutput("trend_status")
            ),
            hr(),
            uiOutput("sim_status")
          )
        ),
        bslib::card(
          bslib::card_header("Simulation Log"),
          bslib::card_body(
            verbatimTextOutput("sim_log")
          )
        )
      )
      ),  # close R1.5 conditionalPanel for settings

      # ==== Results section (merged into Tab 5 per B2 / R1.5) ====
      conditionalPanel(
        condition = "output.sim_view == 'results'",
        div(style = "margin: 12px 16px;",
            actionButton("show_settings_btn", HTML("&#8592; Back to settings"),
                         class = "btn-outline-secondary",
                         icon = icon("arrow-left"))),
        h3("Simulation results", style = "margin: 8px 16px;"),

        # Round 9: single-year results layout (visible when mode != trend)
        conditionalPanel(
          condition = "input.analysis_mode != 'trend'",
          bslib::layout_columns(
            col_widths = c(3, 3, 3, 3),
            bslib::value_box(title = "Total CH4", value = textOutput("vb_ch4"),
                              showcase = icon("fire"), theme = "success"),
            bslib::value_box(title = "Total N2O", value = textOutput("vb_n2o"),
                              showcase = icon("cloud"), theme = "primary"),
            bslib::value_box(title = "95% Margin of Error",
                              value = textOutput("vb_moe"),
                              p("IPCC-aligned uncertainty metric"),
                              showcase = icon("ruler-horizontal"), theme = "warning"),
            bslib::value_box(title = "CV (%)", value = textOutput("vb_cv"),
                              p("Coefficient of variation"),
                              showcase = icon("percent"), theme = "info")
          ),
          div(style = "padding: 0 12px 8px; color: #555; font-size: 0.85rem;",
              tags$em("Total CO₂eq: "), textOutput("vb_co2e_inline", inline = TRUE),
              tags$em(" · retained for sensitivity analysis across sources.")),
          bslib::layout_columns(
            col_widths = c(6, 6),
            bslib::card(
              bslib::card_header("Emission Distribution (Total CO2eq)"),
              bslib::card_body(plotly::plotlyOutput("results_histogram"))
            ),
            bslib::card(
              bslib::card_header("Uncertainty Decomposition"),
              bslib::card_body(
                plotly::plotlyOutput("decomposition_plot")
              )
            )
          ),
          bslib::card(
            bslib::card_header("By-System Breakdown"),
            bslib::card_body(DT::DTOutput("results_by_system"))
          ),
          bslib::card(
            bslib::card_header("By Reporting Category (IPCC Table 3.3 layout)"),
            bslib::card_body(
              p("Each row is one IPCC inventory reporting line (system × source). ",
                "Rows match the granularity used in IPCC Volume 1 Chapter 3 uncertainty reporting."),
              DT::DTOutput("results_by_category")
            )
          ),
          uiOutput("comparison_card")
        ),

        # Round 9: trend results layout (visible when mode == trend)
        conditionalPanel(
          condition = "input.analysis_mode == 'trend'",
          bslib::card(
            bslib::card_header("Trend chart — Total CO2eq with 95% CI band"),
            bslib::card_body(plotly::plotlyOutput("trend_plot", height = "400px"))
          ),
          bslib::card(
            bslib::card_header("Trend table"),
            bslib::card_body(
              p(tags$em("Year-by-year mean, 95% CI bounds, CV%, MoE%, Δ vs. base year, and year-over-year change.")),
              DT::DTOutput("trend_table")
            )
          ),
          div(style = "margin: 8px 16px; font-size:0.85rem; color:#555;",
              tags$em("Sensitivity drivers (per-year + Δ Y_N − Y_1) are on Tab 6 (Sensitivity). Word / Excel / CSV trend reports are on Tab 7 (IPCC Report)."))
        )
      ),
      # R1.5: placeholder removed — settings panel itself shows when sim_view is settings
    ),

    # ==================== TAB 6: SENSITIVITY ====================
    # Round 9 follow-up: branches by analysis_mode like Tab 5 / Tab 7.
    # Single mode shows the existing single-year sensitivity (tornado +
    # rankings table); trend mode shows the per-year + Δ tornadoes
    # previously displayed inside Tab 5's results panel.
    bslib::nav_panel(
      title = "6. Sensitivity",
      icon = icon("bullseye"),

      # ---------- Single-year sensitivity ----------
      conditionalPanel(
        condition = "input.analysis_mode != 'trend'",
        div(class = "info-panel", style = "margin: 16px;",
            tags$strong("What to do: "),
            "This page shows which input parameters contribute most to the overall emission uncertainty. ",
            "The ", tags$strong("tornado chart"), " on the left ranks parameters by their influence -- ",
            "longer bars mean more influential parameters. Green bars indicate a positive relationship ",
            "(higher value = higher emissions) and red bars indicate a negative relationship. ",
            "Use the dropdown on the right to switch between SRC (linear influence) and PRCC (rank-based, more robust). ",
            tags$br(), tags$br(),
            tags$strong("Note: "),
            tags$em("These rankings show which parameters drive the "),
            tags$em(tags$strong("uncertainty")),
            tags$em(" of total emissions, not the absolute emission level."),
            tags$br(),
            tags$strong("Action item: "), "Focus your data improvement efforts on the top 3-5 parameters ",
            "to get the biggest reduction in overall inventory uncertainty."),
        uiOutput("sens_view_toggle"),
        div(style = "margin: 0 16px 12px 16px;",
            selectInput("sens_source", "Output variable",
                        choices = c(
                          "Total CO2eq (all sources)"             = "total_co2e",
                          "Enteric fermentation CH4"              = "enteric_ch4_total",
                          "Manure management CH4"                 = "manure_ch4_total",
                          "Manure management N2O direct"          = "direct_n2o_mm_total",
                          "Manure management N2O indirect"        = "indirect_n2o_mm_total",
                          "Pasture deposition N2O direct"         = "direct_n2o_prp_total",
                          "Pasture deposition N2O indirect"       = "indirect_n2o_prp_total"
                        ),
                        selected = "total_co2e", width = "360px")),
        bslib::layout_columns(
          col_widths = c(6, 6),
          bslib::card(
            bslib::card_header("Tornado Chart - Top Parameters"),
            bslib::card_body(plotly::plotlyOutput("tornado_chart"))
          ),
          bslib::card(
            bslib::card_header("Sensitivity Rankings"),
            bslib::card_body(
              selectInput("sens_method", "Method",
                          choices = c("Standardized Regression (SRC)" = "src",
                                      "Partial Rank Correlation (PRCC)" = "prcc")),
              DT::DTOutput("sensitivity_table")
            )
          )
        )
      ),

      # ---------- Trend sensitivity ----------
      conditionalPanel(
        condition = "input.analysis_mode == 'trend'",
        div(class = "info-panel", style = "margin: 16px;",
            tags$strong("What to do: "),
            "Trend sensitivity has two complementary views. ",
            tags$strong("Per-year (latest)"),
            " — which parameters dominate the uncertainty in the most recent year. ",
            tags$strong("Trend driver (Δ Y_N − Y_1)"),
            " — which parameters drive the change between the first and last year (per IPCC Vol 1 Ch 3 §3.7). ",
            "Bars are coloured by ", tags$strong("user-reducibility"),
            " (same scheme as the single-year tornado): ",
            tags$span(style = "color:#2D6A4F;font-weight:bold;", "■ green"),
            " = the user can improve uncertainty on this parameter with better local data; ",
            tags$span(style = "color:#78909C;font-weight:bold;", "■ grey"),
            " = IPCC coefficient (requires dedicated measurement research to improve). ",
            tags$br(), tags$br(),
            tags$strong("Action item: "),
            "Focus your data improvement efforts on green-coloured parameters in the top 5 — those give you the biggest uncertainty reduction with locally-collectible data."),
        h4("Per-year drivers (latest year)",
            style = "color:#1B4332; margin: 8px 16px 4px;"),
        bslib::layout_columns(
          col_widths = c(7, 5),
          bslib::card(
            bslib::card_header("Tornado — top 10"),
            bslib::card_body(plotly::plotlyOutput("trend_tornado_per_year_sens",
                                                   height = "420px"))
          ),
          bslib::card(
            bslib::card_header("Rankings — top 15 (SRC + PRCC)"),
            bslib::card_body(DT::DTOutput("trend_sens_per_year_table"))
          )
        ),
        h4("Trend driver (Δ Y_N − Y_1)",
            style = "color:#1B4332; margin: 16px 16px 4px;"),
        div(style = "margin: 0 16px 8px; font-size:0.82rem; color:#666;",
            tags$em("Combined Y_1 + Y_N inputs are sensitivity-tested against the per-iteration ΔCO2eq. Suffixes _y1 / _yN distinguish the same parameter at different years.")),
        bslib::layout_columns(
          col_widths = c(7, 5),
          bslib::card(
            bslib::card_header("Tornado — top 10"),
            bslib::card_body(plotly::plotlyOutput("trend_tornado_delta_sens",
                                                   height = "420px"))
          ),
          bslib::card(
            bslib::card_header("Rankings — top 15 (SRC + PRCC)"),
            bslib::card_body(DT::DTOutput("trend_sens_delta_table"))
          )
        )
      )
    ),

    # ==================== TAB 7: IPCC REPORT (last app tab) ====================
    # Round 8 moved this to last position. Round 9 collapses the standalone
    # Trend tab into here: content swaps based on input$analysis_mode, so the
    # report a user sees matches the route they picked on Home (single year vs
    # trend). The downloads on each side are mode-specific too.
    bslib::nav_panel(
      title = "7. IPCC Report",
      icon = icon("file-alt"),

      # ---------- Single-year report layout ----------
      conditionalPanel(
        condition = "input.analysis_mode != 'trend'",
        div(class = "info-panel", style = "margin: 16px;",
            tags$strong("What to do: "),
            "This page shows your uncertainty results formatted as IPCC Table 3.3, ready for your national ",
            "inventory submission. The table shows uncertainty (CV%) decomposed by activity data, emission factors, ",
            "and combined, for each emission source category. ",
            "Click ", tags$strong("'Download Excel Report'"), " to get a complete workbook with all results, ",
            "sensitivity rankings, and metadata. Click ", tags$strong("'Download CSV'"), " for a simpler file ",
            "with uncertainty metrics only."),
        div(style = "margin: 0 16px 12px; font-size:0.82rem; color:#1B4332; background:#D8F3DC; border-left:3px solid #2D6A4F; padding:10px 12px; border-radius:4px;",
            tags$strong("AD vs EF column convention: "),
            "in this version, ", tags$em("AD"),
            " = population uncertainty only (N), and ", tags$em("EF"),
            " = the per-head emission factor uncertainty driven by the 23 coefficients (live weight, feed quality, ",
            "Ym, Bo, Frac_GASMS, etc.). This matches IPCC Volume 1 Chapter 3 reporting conventions."),
        bslib::card(
          bslib::card_header("IPCC Table 3.3 - Uncertainty Report"),
          bslib::card_body(
            DT::DTOutput("ipcc_table"),
            hr(),
            fluidRow(
              column(3, downloadButton("download_xlsx", "Download Excel Report",
                                        class = "btn-success")),
              column(3, downloadButton("download_csv", "Download CSV",
                                        class = "btn-outline-success")),
              column(3, downloadButton("download_docx", "Download Word summary",
                                        class = "btn-primary"))
            )
          )
        ),
        bslib::card(
          bslib::card_header("Uncertainty distributions per emission source"),
          bslib::card_body(
            p("Histograms of the Monte Carlo output for each emission source. ",
              "Useful for third-party QA review of which sources contribute the most variance."),
            plotly::plotlyOutput("report_source_histograms", height = "420px")
          )
        ),
        bslib::card(
          bslib::card_header("Top sensitivity drivers (Total CO₂eq)"),
          bslib::card_body(
            p("Standardised regression coefficients for the top 10 input parameters driving total uncertainty."),
            plotly::plotlyOutput("report_tornado", height = "380px")
          )
        ),
        bslib::card(
          bslib::card_header("Input distributions used"),
          bslib::card_body(
            p("Density plots of each input parameter's fitted distribution — confirms each ",
              "parameter was sampled with the marginal distribution specified in the input table."),
            plotly::plotlyOutput("report_input_densities", height = "520px")
          )
        ),
        bslib::card(
          bslib::card_header("Input parameters used in this run"),
          bslib::card_body(
            p("Full record of every parameter value, distribution, and bounds ",
              "used in the simulation — included for inventory documentation and ",
              "third-party QA review."),
            DT::DTOutput("inputs_doc_table")
          )
        )
      ),

      # ---------- Trend report layout ----------
      conditionalPanel(
        condition = "input.analysis_mode == 'trend'",
        div(class = "info-panel", style = "margin: 16px;",
            tags$strong("What to do: "),
            "This page presents the trend results — year-by-year totals, the trend slope and Δ across years with their own 95% CIs, and the sensitivity drivers per IPCC Vol 1 Ch 3 §3.7. ",
            "Use the downloads below to export the trend report as Excel (multi-sheet workbook), CSV (table only), or Word (full IPCC-style narrative report including the executive summary and methodological notes on the year-correlation mode you chose)."),
        bslib::card(
          bslib::card_header("Trend report — downloads"),
          bslib::card_body(
            p(tags$em("Available after a successful trend run on the Simulate tab. Filename includes the year-correlation mode you picked.")),
            fluidRow(
              column(3, downloadButton("download_trend_xlsx", "Download Excel Report",
                                        class = "btn-success")),
              column(3, downloadButton("download_trend_csv", "Download CSV",
                                        class = "btn-outline-success")),
              column(3, downloadButton("download_trend_docx", "Download Word summary",
                                        class = "btn-primary"))
            )
          )
        ),
        bslib::card(
          bslib::card_header("Trend chart — Total CO2eq with 95% CI band"),
          bslib::card_body(plotly::plotlyOutput("trend_plot_report", height = "400px"))
        ),
        bslib::card(
          bslib::card_header("Trend table"),
          bslib::card_body(
            p(tags$em("Year-by-year mean, 95% CI bounds, CV%, MoE%, Δ vs. base year, and year-over-year change.")),
            DT::DTOutput("trend_table_report")
          )
        ),
        bslib::card(
          bslib::card_header("Sensitivity drivers (per-year + trend)"),
          bslib::card_body(
            p(tags$em("Per-year tornado shows drivers of the latest year; Δ Y_N − Y_1 tornado shows what drives the change between the first and last year (per IPCC Vol 1 Ch 3 §3.7).")),
            bslib::layout_columns(
              col_widths = c(6, 6),
              div(
                h6("Per-year (latest)", style = "color:#1B4332;"),
                plotly::plotlyOutput("trend_tornado_per_year_report", height = "320px")
              ),
              div(
                h6("Trend driver (Δ Y_N − Y_1)", style = "color:#1B4332;"),
                plotly::plotlyOutput("trend_tornado_delta_report", height = "320px")
              )
            )
          )
        )
      )
    ),

    # ==================== TAB 9: CONTACT / FEEDBACK ====================
    # Round 8: client-side Web3Forms submission. The form HTML below posts
    # directly from the visitor's browser to https://api.web3forms.com/submit
    # — Web3Forms restrict server-side POST on the free tier, so we use their
    # recommended client-side fetch() pattern. The Shiny server is bypassed
    # for the actual relay; the access key (which is public-facing by design,
    # see R/utils_contact.R) is embedded in the form.
    bslib::nav_panel(
      title = "Contact / Feedback",
      icon = icon("envelope"),
      div(class = "info-panel", style = "margin: 16px;",
          tags$strong("We welcome feedback, bug reports, feature suggestions, and methodology questions."),
          tags$br(), tags$br(),
          "Submissions are sent to the development team. We aim to reply within a few working days."),
      bslib::layout_columns(
        col_widths = c(6, 6),
        bslib::card(
          bslib::card_header("Send us a message"),
          # Round 9 follow-up: contact_form_html() returns a tagList (form HTML
          # + <style> + <script>). Pass it directly — wrapping in HTML() would
          # re-stringify the script and break the submit handler again.
          bslib::card_body(contact_form_html())
        ),
        bslib::card(
          bslib::card_header("What kind of feedback helps most"),
          bslib::card_body(
            tags$ul(
              tags$li(tags$strong("Bug reports"),
                      " — with steps to reproduce, the example dataset or your upload, and the error message."),
              tags$li(tags$strong("Methodology questions"),
                      " — e.g. how a particular IPCC equation is implemented, or whether your country's data fits the assumptions."),
              tags$li(tags$strong("Feature requests"),
                      " — missing parameters, additional emission sources, integration with national inventory tools."),
              tags$li(tags$strong("Documentation gaps"),
                      " — if a tab or label was confusing, tell us where you got stuck.")
            ),
            hr(),
            div(style = "font-size:0.8rem; color:#666;",
                tags$em("Privacy note: messages are relayed via Web3Forms, an HTTPS form-relay service. We don't store your message; we don't share your email."))
          )
        )
      )
    ),

    # Footer
    bslib::nav_spacer(),
    bslib::nav_item(
      tags$span(style = "color: #6B6B6B; font-size: 0.85rem;",
                "Developed by CIAT/CGIAR Alliance | Funded by Global Methane Hub")
    )
  )
}
