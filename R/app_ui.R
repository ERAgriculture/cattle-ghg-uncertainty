# Master UI Function
app_ui <- function() {
  bslib::page_navbar(
    id = "nav",
    title = "IPCC Tier 2 Livestock GHG Uncertainty Calculator",
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
                               padding: 4px 14px; border-radius: 20px; font-size: 0.8rem;", "IPCC 2006/2019"),
            tags$span(style = "background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.25);
                               padding: 4px 14px; border-radius: 20px; font-size: 0.8rem;", "Monte Carlo Approach 2"),
            tags$span(style = "background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.25);
                               padding: 4px 14px; border-radius: 20px; font-size: 0.8rem;", "Open Source"),
            tags$span(style = "background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.25);
                               padding: 4px 14px; border-radius: 20px; font-size: 0.8rem;", "Enteric + Manure CH4 + N2O")
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
        )
      )
    ),

    # ==================== DEFINITIONS TAB (T1.4) ====================
    bslib::nav_panel(
      title = "Definitions",
      icon = icon("book"),
      div(class = "info-panel", style = "margin: 16px;",
          tags$strong("Parameter glossary. "),
          "All 23 parameters used in the IPCC Tier 2 calculations, with their plain-language definition, ",
          "unit, IPCC default, IPCC reference table/equation, and which IPCC framing they belong to ",
          "(activity data = population; coefficient = everything else that combines into the emission factor)."),
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
          "Choose your IPCC guidelines version. The parameter table on the right shows the loaded data -- ",
          "you can click on any cell to edit values directly. Check the validation panel at the bottom left to ",
          "ensure your data is complete and valid before proceeding to the next tab.",
          tags$br(), tags$br(),
          # T1.6: clarify the data model
          tags$strong("How values, uncertainty and bounds relate: "),
          tags$code("mean"), " is the central estimate. ",
          tags$code("uncertainty_pct"), " is the symmetric ±% half-width of the 95% confidence interval. ",
          tags$code("lower"), " and ", tags$code("upper"),
          " are the absolute 95% CI bounds in the same units as the parameter. ",
          "Editing any of these auto-updates the others to keep them consistent (asymmetric distributions can override the bounds directly)."),
      bslib::layout_sidebar(
        sidebar = bslib::sidebar(
          width = 320,
          h5("Data Source"),
          selectInput("country", "Country / Example Data",
                      choices = c("Country X (hypothetical dairy)" = "uganda",
                                  "Country Y (hypothetical pastoral)" = "zimbabwe",
                                  "Custom Upload" = "custom")),
          hr(),
          div(class = "info-panel",
              style = "font-size: 0.82rem; padding: 8px 10px; margin-top: 4px;",
              icon("info-circle"), " MCF values are entered in the Manure_Management sheet of the Excel template — see the Vocab sheet for IPCC Table 10.17 reference values by climate zone."),
          hr(),
          h5("Custom Data Upload"),
          fileInput("data_upload", "Upload Excel Template (.xlsx)",
                    accept = ".xlsx"),
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
          tags$strong("Fail"), " (red) = the value or bounds will likely cause an error in the simulation. ",
          tags$strong("Warn"), " (amber) = the value is unusual compared with IPCC defaults or Penman/Monni uncertainty references -- investigate and document. ",
          tags$strong("Pass"), " (green) = check satisfied. ",
          "Fix any fails before running the simulation. Warnings are advisory -- document your justification for large deviations from IPCC defaults."),
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
          tags$strong("What to do: "),
          "Review and adjust the probability distribution and uncertainty range for each parameter. ",
          "Click on any cell to change the distribution type (normal, lognormal, beta, triangular, pert, uniform, constant). ",
          tags$br(), tags$br(),
          # T1.7: triangular distribution conversion guidance
          tags$strong("Note on triangular distributions: "),
          tags$em("triangular is most often used when only the minimum, most-likely (mode), and maximum are known. ",
                  "The tool treats lower/upper as ", tags$strong("absolute min/max"),
                  ", not 95% CI bounds — for triangular, those are usually the same. ",
                  "If you have a 95% CI but want a triangular shape, use PERT instead (PERT uses the 95% bounds and a most-likely value)."),
          tags$br(), tags$br(),
          "or to modify the uncertainty percentage and bounds. ",
          tags$strong("Activity data"), " parameters (param_type = 'activity_data') support correlated sampling in Tab 4. ",
          tags$strong("Emission factors"), " (param_type = 'emission_factor') are always sampled independently. ",
          "Use the quick-set buttons at the bottom to apply common settings to all parameters of one type."),
      bslib::card(
        bslib::card_header("Distribution & Uncertainty Specification"),
        bslib::card_body(
          DT::DTOutput("uncertainty_table"),
          hr(),
          fluidRow(
            column(4, actionButton("set_all_normal", "Set All AD to Normal +/-15%",
                                   class = "btn-outline-success btn-sm")),
            column(4, actionButton("set_all_pert", "Set All EF to PERT",
                                   class = "btn-outline-primary btn-sm"))
          )
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
                                     "From template (auto)"   = "timeseries",
                                     "IPCC-guidance preset"   = "preset",
                                     "Advanced — manual entry"= "manual"),
                         selected = "none"),
            # Group selector for time-series mode (Andreas: "correlate within all AD / population only / intake only")
            conditionalPanel(
              condition = "input.corr_mode == 'timeseries'",
              radioButtons("corr_group_scope", "Apply correlations within:",
                           choices = c(
                             "All AD parameters"                     = "all",
                             "Population-related only (cattle_pop, live_weight, mature_weight, weight_gain)" = "population",
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
                  "(e.g. live_weight ↔ mature_weight, milk_yield ↔ milk_fat). ",
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
          bslib::card_header("Emission Factor Correlations"),
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

    # ==================== TAB 5: SIMULATION ====================
    bslib::nav_panel(
      title = "5. Simulate",
      icon = icon("play"),
      div(class = "info-panel", style = "margin: 16px;",
          tags$strong("What to do: "),
          "Configure the simulation settings on the left, then click ",
          tags$strong("'Run Monte Carlo Simulation'"), ". ",
          "The tool will sample all parameters from their distributions and run the full IPCC equation chain ",
          "thousands of times. Use 10,000 iterations for reliable results (1,000 for quick testing). ",
          "A random seed ensures reproducibility -- the same seed always produces the same results. ",
          "Check 'Run uncertainty decomposition' to separate activity data from emission factor uncertainty. ",
          "When the simulation is complete, proceed to the Results and Sensitivity tabs."),
      bslib::layout_columns(
        col_widths = c(4, 8),
        bslib::card(
          bslib::card_header("Simulation Settings"),
          bslib::card_body(
            sliderInput("n_iter", "Number of Iterations",
                        min = 1000, max = 50000, value = 10000, step = 1000),
            numericInput("seed", "Random Seed (for reproducibility)", value = 42),
            selectInput("gwp_version", "GWP Assessment Report",
                        choices = c("AR4 (CH4=25)" = "AR4",
                                    "AR5 (CH4=28, N2O=265)" = "AR5",
                                    "AR6 (CH4=27.9, N2O=273)" = "AR6"),
                        selected = "AR5"),
            # T1.12: emission source selector
            checkboxGroupInput("emission_sources", "Emission sources to include",
                               choices = c(
                                 "Enteric fermentation CH4"      = "enteric_ch4",
                                 "Manure management CH4"         = "manure_ch4",
                                 "Manure management N2O direct"  = "manure_n2o_direct",
                                 "Manure management N2O indirect"= "manure_n2o_indirect",
                                 "Pasture deposition N2O"        = "pasture_n2o"
                               ),
                               selected = c("enteric_ch4", "manure_ch4",
                                            "manure_n2o_direct", "manure_n2o_indirect",
                                            "pasture_n2o")),
            div(style = "font-size:0.78rem; color:#666; margin-top:-8px; margin-bottom:8px;",
                tags$em("All sources are included by default. Uncheck a source to exclude it from the totals (the calculation still runs but its contribution is zeroed in CH4 / N2O / CO2eq sums).")),
            hr(),
            checkboxInput("run_decomposition", "Run uncertainty decomposition (AD/EF/Combined)",
                          value = TRUE),
            checkboxInput("run_comparison", "Compare with/without correlations", value = FALSE),
            hr(),
            actionButton("run_sim", "Run Monte Carlo Simulation",
                         class = "run-btn w-100", icon = icon("play")),
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
    ),

    # ==================== TAB 6: RESULTS ====================
    bslib::nav_panel(
      title = "6. Results",
      icon = icon("chart-bar"),
      div(class = "info-panel", style = "margin: 16px;",
          tags$strong("What to do: "),
          "Review the simulation results below. The ", tags$strong("summary cards"),
          " at the top show total emissions and overall uncertainty (CV%). The ",
          tags$strong("histogram"), " shows the full distribution of simulated CO2eq values with ",
          "95% confidence interval lines (red dashes). The ",
          tags$strong("decomposition chart"), " shows how much uncertainty comes from activity data vs. emission factors. ",
          "The ", tags$strong("by-system table"), " breaks down results per production system. ",
          "A CV below 25% indicates reasonably good data quality; above 50% suggests priority areas for data improvement."),
      bslib::layout_columns(
        col_widths = c(3, 3, 3, 3),
        # T6.3: CH4 + N2O headline; CO2eq moved to a smaller secondary card.
        # T6.1: 95% Margin of Error replaces CV as the IPCC-aligned headline metric.
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
            # T6.4 / T1.5 / T8.2 (partial): IPCC framing callout
            div(style = "font-size:0.82rem; color:#444; background:#FFF8E1; border-left:3px solid #F59E0B; padding:8px 10px; margin-bottom:10px; border-radius:4px;",
                tags$strong("Note on AD vs EF terminology: "),
                "this chart currently uses the tool's internal classification — ",
                tags$em("Activity Data"), " = the 14 production parameters (cattle_pop, weights, milk yield, intake), ",
                tags$em("Emission Factor"), " = the 9 IPCC equation parameters. ",
                "In the IPCC convention, only ", tags$strong("cattle_pop"),
                " is true Activity Data, and the rest combine to form a per-head ",
                tags$em("emission factor"),
                ". A full re-classification is planned for v2.3 (Phase 2)."),
            plotly::plotlyOutput("decomposition_plot")
          )
        )
      ),
      bslib::card(
        bslib::card_header("By-System Breakdown"),
        bslib::card_body(DT::DTOutput("results_by_system"))
      ),
      # T6.2: per-IPCC-reporting-category breakdown
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

    # ==================== TAB 7: SENSITIVITY ====================
    bslib::nav_panel(
      title = "7. Sensitivity",
      icon = icon("bullseye"),
      div(class = "info-panel", style = "margin: 16px;",
          tags$strong("What to do: "),
          "This page shows which input parameters contribute most to the overall emission uncertainty. ",
          "The ", tags$strong("tornado chart"), " on the left ranks parameters by their influence -- ",
          "longer bars mean more influential parameters. Green bars indicate a positive relationship ",
          "(higher value = higher emissions) and red bars indicate a negative relationship. ",
          "Use the dropdown on the right to switch between SRC (linear influence) and PRCC (rank-based, more robust). ",
          # T7.1: clarify what the rankings mean
          tags$br(), tags$br(),
          tags$strong("Note: "),
          tags$em("These rankings show which parameters drive the "),
          tags$em(tags$strong("uncertainty")),
          tags$em(" of total emissions, not the absolute emission level."),
          tags$br(),
          tags$strong("Action item: "), "Focus your data improvement efforts on the top 3-5 parameters ",
          "to get the biggest reduction in overall inventory uncertainty."),
      uiOutput("sens_view_toggle"),
      # T7.2: per-emission-source sensitivity selector
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

    # ==================== TAB 8: IPCC REPORT ====================
    bslib::nav_panel(
      title = "8. IPCC Report",
      icon = icon("file-alt"),
      div(class = "info-panel", style = "margin: 16px;",
          tags$strong("What to do: "),
          "This page shows your uncertainty results formatted as IPCC Table 3.3, ready for your national ",
          "inventory submission. The table shows uncertainty (CV%) decomposed by activity data, emission factors, ",
          "and combined, for each emission source category. ",
          "Click ", tags$strong("'Download Excel Report'"), " to get a complete workbook with all results, ",
          "sensitivity rankings, and metadata. Click ", tags$strong("'Download CSV'"), " for a simpler file ",
          "with uncertainty metrics only."),
      # T8.2 partial: IPCC AD/EF framing callout
      div(style = "margin: 0 16px 12px; font-size:0.82rem; color:#444; background:#FFF8E1; border-left:3px solid #F59E0B; padding:10px 12px; border-radius:4px;",
          tags$strong("Note on Activity Data vs Emission Factor columns: "),
          "the AD_Uncertainty_pct and EF_Uncertainty_pct columns below currently use the tool's internal classification ",
          "(AD = 14 production parameters; EF = 9 IPCC equation parameters). The IPCC convention is AD = population only, ",
          "EF = emissions per head per year. A full re-classification of the decomposition is planned for v2.3 — until then, ",
          "interpret these labels with the caveat above when comparing to other IPCC inventory submissions."),
      bslib::card(
        bslib::card_header("IPCC Table 3.3 - Uncertainty Report"),
        bslib::card_body(
          DT::DTOutput("ipcc_table"),
          hr(),
          fluidRow(
            column(3, downloadButton("download_xlsx", "Download Excel Report",
                                      class = "btn-success")),
            column(3, downloadButton("download_csv", "Download CSV",
                                      class = "btn-outline-success"))
          )
        )
      ),
      # T8.4: per-source uncertainty distribution histograms
      bslib::card(
        bslib::card_header("Uncertainty distributions per emission source"),
        bslib::card_body(
          p("Histograms of the Monte Carlo output for each emission source. ",
            "Useful for third-party QA review of which sources contribute the most variance."),
          plotly::plotlyOutput("report_source_histograms", height = "420px")
        )
      ),
      # T8.4: per-source tornado embedded
      bslib::card(
        bslib::card_header("Top sensitivity drivers (Total CO₂eq)"),
        bslib::card_body(
          p("Standardised regression coefficients for the top 10 input parameters driving total uncertainty."),
          plotly::plotlyOutput("report_tornado", height = "380px")
        )
      ),
      # Tx.1: distribution-shape viz for QA verification
      bslib::card(
        bslib::card_header("Input distributions used"),
        bslib::card_body(
          p("Density plots of each input parameter's fitted distribution — confirms each ",
            "parameter was sampled with the marginal distribution specified in the input table."),
          plotly::plotlyOutput("report_input_densities", height = "520px")
        )
      ),
      # T8.3: full input documentation for the run
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

    # ==================== TAB 9: TREND ====================
    bslib::nav_panel(
      title = "9. Trend",
      icon = icon("chart-line"),
      div(class = "info-panel", style = "margin: 16px;",
          tags$strong("What to do: "),
          "This feature will analyze how emission uncertainty changes over time. It will allow you to upload ",
          "multi-year emission estimates, visualize uncertainty bands across inventory years, and quantify ",
          "uncertainty in the emission trend itself. This is particularly important for countries tracking ",
          "progress toward emission reduction targets under the Paris Agreement."),
      bslib::card(
        bslib::card_header("Trend Uncertainty Analysis (Optional)"),
        bslib::card_body(
          p("This feature is under development and will be available in a future release."),
          p("Requirements: Multi-year population data uploaded in the Correlations tab (Sheet: Population_TimeSeries).")
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
