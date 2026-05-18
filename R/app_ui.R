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
    header = tagList(
      tags$head(tags$link(rel = "stylesheet", href = "custom.css")),
      tags$head(tags$script(HTML(
        "Shiny.addCustomMessageHandler('scrollTo', function(id) {
           var el = document.getElementById(id);
           if (el) el.scrollIntoView({behavior: 'smooth', block: 'center'});
         });"
      )))
    ),
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
            style = "font-size: 0.9rem; opacity: 0.7;")
        ),

        # What this tool does
        bslib::card(
          bslib::card_header(h4("What does this tool do?", style = "margin: 0;")),
          bslib::card_body(
            p("When a country reports cattle greenhouse gas emissions under the Paris Agreement, every input parameter
              (animal populations, body weights, feed quality, emission factors) has some uncertainty. This tool:"),
            tags$ol(
              tags$li("Takes your country-specific input data aligned with the IPCC Tier 2 equations, with uncertainty ranges"),
              tags$li("Runs thousands of Monte Carlo simulations, varying all parameters according to their probability distributions"),
              tags$li("Produces the uncertainty range for your total emission estimate (95% confidence interval)"),
              tags$li("Identifies which parameters contribute most to the uncertainty (sensitivity analysis)"),
              tags$li("Formats results for IPCC inventory reporting (IPCC 2006 Vol. 1 Ch. 3, Table 3.3)")
            ),
            p(tags$strong("Emission sources covered:"),
              " Enteric fermentation CH₄, Manure management CH₄, Manure management N₂O (direct and indirect),
              and N₂O (direct and indirect) from dung and urine deposited on pasture.")
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
              tags$li("It does not produce Tier 1 estimates and is not designed for uncertainty analysis of country-specific Tier 2 methods — the IPCC Tier 2 equation chain is required."),
              tags$li("It does not validate your country's IPCC categorisation choices — sub-category structure is the user's responsibility."),
              tags$li("Cross-block correlations between activity data and emission factors are not yet supported (planned for v3.0).")
            )
          )
        ),
        # Andreas 2026-05 #3: analysis-mode toggle moved to top of Data Input
        # tab (see below). Card removed from Home page so the workflow start
        # is more visible.
      )
    ),

    # ==================== DEFINITIONS TAB (T1.4 + R1.7 + R1.8) ====================
    bslib::nav_panel(
      title = "Definitions",
      icon = icon("book"),
      div(class = "info-panel", style = "margin: 16px;",
          tags$strong("Parameter glossary. "),
          "All parameters used in the IPCC Tier 2 calculations, with their plain-language ",
          "definition, unit, IPCC default value, suggested distribution, level (core / advanced), ",
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
          bslib::card_header(h4("Tool-specific resources", style = "margin: 0;")),
          bslib::card_body(
            p(tags$em("Drafts in progress for beta-testing. Sections below will be expanded with detailed content before partner rollout.")),
            tags$h5("How this tool works"),
            tags$ul(
              tags$li("Equation chain: IPCC 2006 Vol 4 Ch 10 (Eq 10.1–10.34) and Ch 11 for the per-head emission factor; population × EF for the per-sub-category total."),
              tags$li("Monte Carlo: Approach 2 from IPCC 2006 Vol 1 Ch 3, with optional Gaussian copula correlations across activity data and coefficients."),
              tags$li("Sensitivity: Standardised regression coefficients (SRC) and partial rank correlation (PRCC) on the sampled inputs vs each output.")
            ),
            tags$h5("How to use the tool"),
            tags$ul(
              tags$li("If you are not accounting for uncertainty on a parameter, enter the parameter value and set uncertainty_pct = 0 (or distribution = constant)."),
              tags$li("Set Milk = 0 for sub-categories that do not lactate; set WG = 0 for adult animals not gaining weight."),
              tags$li("For asymmetric IPCC parameters (EF3_PRP, EF4, EF5, Frac_LEACH_H), supply explicit lower / upper bounds — the catalogue pre-fills Monni-2007 / Penman-2000 ranges if you leave them blank."),
              tags$li("Two ways to fix QA/QC failures: (a) edit values directly in the in-app Parameters table on Tab 1 — quick for one or two cells; or (b) edit the original Excel template and re-upload — easier when you have 100+ parameters and want a saved record of your final values. Both produce the same simulation inputs.")
            ),
            tags$h5("Preparing uncertainty inputs"),
            tags$ul(
              tags$li("Use the IPCC Approach 1 spreadsheet to combine survey CVs into a 95 % CI half-width, then enter as `uncertainty_pct` in the Parameters sheet."),
              tags$li("For parameters with skewed empirical distributions (e.g. milk yield across smallholders), choose `lognormal` or `pert` instead of `normal`."),
              tags$li("For correlations, upload a multi-year activity-data time-series in the Parameter_TimeSeries sheet and let the Correlations tab auto-compute Pearson coefficients.")
            )
          )
        ),

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
                             "IPCC 2006 Guidelines — Volume 1, Chapter 3 (Uncertainties)")),
              tags$li(tags$a(href = "https://www.ipcc-nggip.iges.or.jp/public/2019rf/vol1.html",
                             target = "_blank",
                             "2019 Refinement to the 2006 IPCC Guidelines — Volume 1, Chapter 3 (Uncertainties)"))
            ),
            tags$h5("Activity data guidance"),
            tags$ul(
              tags$li(tags$a(href = "https://www.fao.org/livestock-systems/global-distributions/en/",
                             target = "_blank",
                             "FAO Livestock Activity Data Guidance (L-ADG)")),
              tags$li("Penman et al. (2000) — Good Practice Guidance and Uncertainty Management in National Greenhouse Gas Inventories")
            ),
            tags$h5("Distributions and Monte Carlo references"),
            tags$ul(
              tags$li("Frey & Rhodes (1998) — Characterizing, simulating, and analyzing variability and uncertainty"),
              tags$li("IPCC GPG 2000 §6 — Quantifying uncertainties in practice (Approach 1 vs Approach 2)")
            ),
            tags$h5("Learning resources"),
            tags$ul(
              tags$li(tags$a(href = "https://elearning.fao.org/course/view.php?id=625",
                             target = "_blank",
                             "FAO e-learning — Assessing uncertainty in the land sector")),
              tags$li(tags$a(href = "https://elearning.fao.org/course/view.php?id=531",
                             target = "_blank",
                             "FAO e-learning — Tier 2 inventory for livestock")),
              tags$li(tags$a(href = "https://unfccc.int/topics/science/workstreams/methodological-issues-under-the-convention",
                             target = "_blank",
                             "UNFCCC webinar notes — Uncertainty analysis for GHG inventories"))
            ),
            tags$h5("Case studies"),
            tags$ul(
              tags$li("Monni et al. (2007) — Uncertainty in agricultural CH₄ and N₂O emissions from Finland"),
              tags$li("Karimi-Zindashty et al. (2012) — Sources of uncertainty in livestock emission inventories: Canadian case study"),
              tags$li("Milne et al. (2014) — Estimating uncertainty in pasture-based dairy CH₄ emissions"),
              tags$li(tags$em("Additional national-inventory examples to be added."))
            )
          )
        )
      )
    ),

    # ==================== TAB 1: DATA INPUT ====================
    bslib::nav_panel(
      title = "1. Data Input",
      icon = icon("upload"),
      # Andreas 2026-05 #3: analysis-mode toggle moved here from Home page.
      bslib::card(
        style = "margin: 16px;",
        bslib::card_header(h5("Choose your analysis mode", style = "margin: 0;")),
        bslib::card_body(
          radioButtons("analysis_mode",
            label = NULL,
            choiceNames = list(
              tagList(
                "Single year — quantify uncertainty in one inventory year ",
                bslib::tooltip(
                  span(icon("circle-question"),
                       style = "color:#2D6A4F; cursor:help; vertical-align:middle;"),
                  "Use this mode to estimate the uncertainty for one specific inventory year. All parameters are sampled independently for each iteration. This is the most common mode and is sufficient for IPCC Table 3.3 reporting. Choose Trend if you also want to assess whether emission changes over time are statistically significant.",
                  placement = "right"
                )
              ),
              tagList(
                "Trend — compare uncertainty across multiple years ",
                bslib::tooltip(
                  span(icon("circle-question"),
                       style = "color:#2D6A4F; cursor:help; vertical-align:middle;"),
                  "Use this mode when you have activity data for several inventory years and want to assess whether the trend (change over time) is statistically distinguishable from zero. IPCC Vol 1 Ch 3 §3.7 recommends reporting trend uncertainty for inventory series. Requires a Parameter_TimeSeries sheet in your upload template, or use one of the built-in example datasets.",
                  placement = "right"
                )
              )
            ),
            choiceValues = c("single", "trend"),
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
      ),
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
                " Custom mode selected. Pick an IPCC version, download the matching template, fill it in, then upload below.")
          ),
          # Andreas 2026-05 follow-up: the IPCC version picker, template
          # downloads and upload section only apply to the Custom Upload
          # path — hide them entirely for the built-in example datasets so
          # the sidebar isn't cluttered.
          conditionalPanel(
            condition = "input.country == 'custom'",
            hr(),
            # Round 7.1: IPCC version picker drives the downloaded template's
            # MMS dropdown (filtered to systems valid for that version) and
            # the Inventory_Metadata `ipcc_version` cell.
            h5("1. Pick an IPCC Guidelines version"),
            radioButtons("template_version", label = NULL,
                          choices = c("IPCC 2006" = "2006",
                                      "IPCC 2019 Refinement" = "2019_refinement"),
                          selected = character(0), inline = TRUE),
            div(style = "font-size:0.78rem; color:#666; margin-top:-6px; margin-bottom:8px;",
                tags$em("The MMS dropdown in the downloaded template will be filtered to manure systems valid for the version you pick here.")),
            h5("2. Download a template"),
            downloadButton("download_template", "Download Blank Template",
                           class = "btn-outline-success btn-sm"),
            downloadButton("download_template_example", "Download Template with Example",
                           class = "btn-outline-primary btn-sm mt-2"),
            div(style = "font-size:0.78rem; color:#666; margin-top:6px;",
                tags$em("If no IPCC version is picked, the download is blocked and the app will prompt you to select one.")),
            hr(),
            h5("3. Upload your filled template"),
            fileInput("data_upload", "Upload Excel Template (.xlsx)",
                      accept = ".xlsx")
          ),
          hr(),
          h5("Validation"),
          uiOutput("validation_status")
        ),
        conditionalPanel(
          condition = "output.has_imputed_params == true",
          uiOutput("imputed_params_notice_tab1")
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
          tags$strong("Info"), " (blue) = informational only — typically for emission factor parameters (EF3, EF4, EF5, Frac_*) where country-specific overrides are expected and the IPCC benchmark is a Monni-2007 / Penman-2000 mid-point, not a fixed table value. No action required unless the deviation is very large. ",
          tags$strong("Pass"), " (green) = check satisfied. ",
          "Fix any fails before running the simulation. Warnings are advisory -- document your justification for large deviations from IPCC defaults. ",
          tags$br(), tags$br(),
          tags$strong("Auto-filled parameters: "),
          "If any parameters were absent from your upload, an ",
          tags$strong("Auto-filled parameters"),
          " panel appears above the results table showing which values were substituted from IPCC defaults. ",
          "Review these and replace with country-specific data in your template where possible."),
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
          tags$strong("Activity data correlation modes (four options): "),
          tags$ul(
            tags$li(tags$strong("No correlations (default):"),
                    " parameters are sampled independently. Conservative and appropriate when you have no information about co-movement."),
            tags$li(tags$strong("From template (auto, time-series):"),
                    " upload multi-year national livestock data in the Parameter_TimeSeries sheet. ",
                    "Year-to-year co-movement is computed automatically (Pearson correlation, then nearest positive-definite). ",
                    "This is the recommended option whenever you have ≥5 years of data."),
            tags$li(tags$strong("IPCC-guidance preset:"),
                    " applies a sparse correlation matrix containing only well-documented structural pairs ",
                    "(e.g. W ↔ MW, Milk ↔ Fat). ",
                    "All other pairs are zero. A good middle ground when you have no time series but want some realism beyond full independence."),
            tags$li(tags$strong("Advanced — manual entry:"),
                    " upload a CSV with expert estimates of pairwise correlations. ",
                    "Most users should leave this alone.")
          ),
          tags$strong("Emission factor correlations: "),
          "A single uniform rho (ρ ∈ [0, 0.9]) representing systematic bias shared across ",
          "all IPCC equation coefficients. Use ρ = 0.3 as a moderate sensitivity test; values above 0.5 require justification."),
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
          tags$strong("'Run Monte Carlo Simulation'"),
          " at the bottom of the left-hand panel. ",
          "The tool will sample all parameters from their distributions and run the IPCC equation chain ",
          "thousands of times. 10,000+ iterations recommended; check convergence by re-running with a different seed (1,000 is fine for quick testing). ",
          tags$br(), tags$br(),
          tags$strong("Once the simulation completes, this tab switches to the results view automatically."),
          " Use the ", tags$em("Back to settings"), " button at the top of the results to change inputs and re-run — the next run will switch back to results when it finishes. ",
          "Tab 7 (Sensitivity) and Tab 8 (IPCC Report) provide deeper drill-downs.",
          tags$br(), tags$br(),
          tags$strong("How many iterations to use: "),
          "Use ", tags$strong("1,000 only for a quick test run"),
          " to check that the model runs. Use a ", tags$strong("minimum of 10,000 iterations"),
          " for any result you intend to use — convergence is not guaranteed below 10,000. ",
          "Higher is always better: 25,000–30,000 is recommended for final reporting, especially when correlations are enabled or you have many sub-categories. ",
          "To verify convergence, re-run with a different random seed: if the CV% changes by more than 1–2 percentage points, increase the number of iterations."),
      # R1.5: view toggle — output.sim_view is "settings" or "results"
      conditionalPanel(
        condition = "output.sim_view != 'results'",
        bslib::layout_columns(
        col_widths = c(4, 8),
        bslib::card(
          bslib::card_header("Simulation Settings"),
          bslib::card_body(
            sliderInput("n_iter", "Number of Iterations",
              min = 1000, max = 50000, step = 1000,
              value = 10000, sep = ","),
            numericInput("seed",
              label = tagList(
                "Random Seed (for reproducibility) ",
                bslib::tooltip(
                  span(icon("circle-question"),
                       style = "color:#2D6A4F; cursor:help; vertical-align:middle;"),
                  "Fixing the seed makes results exactly reproducible — anyone using the same data, settings, and seed will get the same numbers. To check convergence, re-run with a different seed (e.g. 123 or 456): if the CV% changes by more than ~1 percentage point, increase the number of iterations.",
                  placement = "right"
                )
              ),
              value = 42),
            # Andreas 2026-05 follow-up: Dirichlet MMS-allocation control removed
            # (no IPCC citation). MMS% is now treated deterministically across
            # iterations, matching the IPCC Inventory Software's behaviour.
            selectInput("gwp_version",
              label = tagList(
                "GWP Assessment Report ",
                bslib::tooltip(
                  span(icon("circle-question"),
                       style = "color:#2D6A4F; cursor:help; vertical-align:middle;"),
                  "GWP (Global Warming Potential) converts CH₄ and N₂O emissions to CO₂ equivalent for reporting. AR5 (CH₄=28, N₂O=265) is the most commonly required for current IPCC submissions. AR6 (CH₄=27, N₂O=273) is the latest IPCC assessment. Use whichever version your national reporting guidelines specify.",
                  placement = "right"
                )
              ),
              choices = c("AR4 (CH₄=25)" = "AR4",
                          "AR5 (CH₄=28, N₂O=265)" = "AR5",
                          "AR6 (CH₄=27, N₂O=273)" = "AR6"),
              selected = "AR5"),
            # T1.12 / R1.4: emission source selector — none ticked by default,
            # forcing the user to make an explicit choice before running.
            checkboxGroupInput("emission_sources", "Emission sources to include",
                               choices = c(
                                 "Enteric fermentation CH₄"            = "enteric_ch4",
                                 "Manure management CH₄"               = "manure_ch4",
                                 "Manure management N₂O direct"        = "manure_n2o_direct",
                                 "Manure management N₂O indirect"      = "manure_n2o_indirect",
                                 "Pasture deposition N₂O direct"       = "pasture_n2o_direct",
                                 "Pasture deposition N₂O indirect"     = "pasture_n2o_indirect"
                               ),
                               selected = character(0)),
            uiOutput("select_all_btn"),
            div(style = "font-size:0.78rem; color:#92400E; background:#FEF3C7; padding:8px 10px; border-radius:6px; margin-bottom:8px; margin-top:4px;",
                icon("exclamation-triangle"),
                tags$strong(" Tick at least one source above"),
                " — the simulation cannot run without an explicit selection. ",
                tags$em("(Most users tick all 6 for a full inventory.)")),
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
        # Andreas 2026-05 C1: headline value-boxes by IPCC source category
        # instead of total CH₄ / N₂O. CV and Margin of Error moved into the
        # inline footnote alongside Total CO₂eq.
        conditionalPanel(
          condition = "input.analysis_mode != 'trend'",
          bslib::layout_columns(
            col_widths = NULL,
            bslib::value_box(title = "Enteric CH₄ (t)",
                              value = textOutput("vb_enteric_ch4"),
                              showcase = icon("fire"), theme = "success"),
            bslib::value_box(title = "Manure CH₄ (t)",
                              value = textOutput("vb_manure_ch4"),
                              showcase = icon("recycle"), theme = "success"),
            bslib::value_box(title = "Manure N₂O (t)",
                              value = textOutput("vb_manure_n2o"),
                              p("Direct + indirect"),
                              showcase = icon("cloud"), theme = "primary"),
            bslib::value_box(title = "Pasture N₂O (t)",
                              value = textOutput("vb_pasture_n2o"),
                              p("Direct + indirect"),
                              showcase = icon("seedling"), theme = "primary"),
            bslib::value_box(title = "Total CV (%)",
                              value = textOutput("vb_cv"),
                              p("Coefficient of variation"),
                              showcase = icon("percent"), theme = "warning")
          ),
          div(style = "padding: 0 12px 8px; color: #555; font-size: 0.85rem;",
              tags$em("Total CO₂eq: "), textOutput("vb_co2e_inline", inline = TRUE),
              tags$em(" · 95% MoE: "), textOutput("vb_moe", inline = TRUE),
              tags$em(" · Total CH₄: "), textOutput("vb_ch4", inline = TRUE),
              tags$em(" · Total N₂O: "), textOutput("vb_n2o", inline = TRUE)),
          bslib::layout_columns(
            col_widths = c(6, 6),
            bslib::card(
              bslib::card_header("Emission Distribution (Total CO₂eq)"),
              bslib::card_body(plotly::plotlyOutput("results_histogram"))
            ),
            bslib::card(
              bslib::card_header("Uncertainty Decomposition"),
              bslib::card_body(
                plotly::plotlyOutput("decomposition_plot")
              )
            )
          ),
          # Andreas 2026-05 #32, C2: aggregation level selector — default to
          # cattle_type (IPCC reporting convention: dairy / other cattle), with
          # optional drill-down to aggregation_level (production system) or
          # sub_category for advanced users.
          div(style = "padding: 0 16px 8px; display: flex; align-items: center; gap: 12px;",
              tags$strong("Aggregation level:"),
              selectInput("results_aggregation_level", label = NULL,
                          choices = c(
                            "Cattle type (dairy / other)"  = "cattle_type",
                            "Production system"            = "aggregation_level",
                            "Sub-category"                 = "sub_category"),
                          selected = "cattle_type",
                          width = "260px"),
              tags$em(style = "color:#666; font-size:0.85rem;",
                      "Tables below aggregate per-iteration results at this level.")),
          bslib::card(
            bslib::card_header("By-System Breakdown"),
            bslib::card_body(DT::DTOutput("results_by_system"))
          ),
          bslib::card(
            bslib::card_header("By Reporting Category (IPCC Table 3.3 layout)"),
            bslib::card_body(
              p("Each row is one IPCC inventory reporting line (group × source). ",
                "Rows match the granularity used in IPCC Volume 1 Chapter 3 uncertainty reporting."),
              DT::DTOutput("results_by_category")
            )
          ),
          uiOutput("comparison_card")
        ),

        # Round 9 follow-up: trend results layout — mirrors single-year's
        # value-boxes-then-charts pattern but with trend-specific metrics.
        conditionalPanel(
          condition = "input.analysis_mode == 'trend'",
          bslib::layout_columns(
            col_widths = c(3, 3, 3, 3),
            bslib::value_box(title = "Δ vs base year",
                              value = textOutput("vb_trend_delta"),
                              p(textOutput("vb_trend_delta_sub", inline = TRUE)),
                              showcase = icon("arrow-trend-up"), theme = "primary"),
            bslib::value_box(title = "Trend slope",
                              value = textOutput("vb_trend_slope"),
                              p(textOutput("vb_trend_slope_sub", inline = TRUE)),
                              showcase = icon("chart-line"), theme = "success"),
            bslib::value_box(title = "Latest year",
                              value = textOutput("vb_trend_latest"),
                              p(textOutput("vb_trend_latest_sub", inline = TRUE)),
                              showcase = icon("calendar-days"), theme = "info"),
            bslib::value_box(title = "Largest YoY change",
                              value = textOutput("vb_trend_yoy"),
                              p(textOutput("vb_trend_yoy_sub", inline = TRUE)),
                              showcase = icon("bolt"), theme = "warning")
          ),
          div(style = "padding: 0 12px 8px; color: #555; font-size: 0.85rem;",
              tags$em(textOutput("vb_trend_inline", inline = TRUE))),
          bslib::layout_columns(
            col_widths = c(7, 5),
            bslib::card(
              bslib::card_header("Trend chart — Total CO₂eq with 95% CI band"),
              bslib::card_body(plotly::plotlyOutput("trend_plot", height = "360px"))
            ),
            bslib::card(
              bslib::card_header("Year-over-year % change"),
              bslib::card_body(plotly::plotlyOutput("trend_yoy_chart", height = "360px"))
            )
          ),
          bslib::card(
            bslib::card_header("Distribution of Δ Y_N − Y_1 — uncertainty on the trend itself"),
            bslib::card_body(
              p(tags$em("This histogram shows the Monte Carlo distribution of the absolute change in CO₂eq between the first and last year. The dashed red lines mark the 95% CI; the dotted line marks zero. If zero falls inside the CI, the trend is not statistically distinguishable from no change at this confidence level.")),
              plotly::plotlyOutput("trend_delta_histogram", height = "300px")
            )
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
            "to get the biggest reduction in overall inventory uncertainty.",
            tags$br(), tags$br(),
            tags$strong("Sensitivity methods explained: "),
            tags$strong("SRC (Standardized Regression Coefficients)"),
            " — fits a linear model between each input parameter and the output; fast and easy to interpret. ",
            "A positive SRC means higher values of that input produce higher emissions. ",
            tags$strong("PRCC (Partial Rank Correlation Coefficients)"),
            " — rank-based method, more robust when the input-output relationship is non-linear or when the output distribution is skewed. ",
            "For most livestock inventories both methods give similar rankings. ",
            "Use PRCC as a cross-check when SRC rankings seem counterintuitive or when distributions are highly asymmetric."),
        uiOutput("sens_view_toggle"),
        div(style = "margin: 0 16px 12px 16px;",
            selectInput("sens_source", "Output variable",
                        choices = c(
                          "Total CO₂eq (all sources)"             = "total_co2e",
                          "Enteric fermentation CH₄"              = "enteric_ch4_total",
                          "Manure management CH₄"                 = "manure_ch4_total",
                          "Manure management N₂O direct"          = "direct_n2o_mm_total",
                          "Manure management N₂O indirect"        = "indirect_n2o_mm_total",
                          "Pasture deposition N₂O direct"         = "direct_n2o_prp_total",
                          "Pasture deposition N₂O indirect"       = "indirect_n2o_prp_total"
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
            tags$em("Combined Y_1 + Y_N inputs are sensitivity-tested against the per-iteration ΔCO₂eq. Suffixes _y1 / _yN distinguish the same parameter at different years.")),
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
            "inventory submission. ",
            "The table has three uncertainty columns — ",
            tags$strong("AD uncertainty (%)"), ", ",
            tags$strong("EF uncertainty (%)"), ", and ",
            tags$strong("Combined uncertainty (%)"),
            " — all expressed as CV (coefficient of variation = SD ÷ mean × 100). ",
            "AD = population/activity-data uncertainty only; EF = per-head emission factor uncertainty driven by the 23 IPCC coefficients; Combined = both sources together. ",
            "Click ", tags$strong("'Download Excel Report'"), " to get a complete workbook with all results, ",
            "sensitivity rankings, run settings, and metadata. Click ", tags$strong("'Download CSV'"), " for a simpler file ",
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
            uiOutput("ipcc_table_notice"),
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
              "Useful for third-party QA review of which sources contribute the most variance. ",
              "When you hover over a bar, the tooltip shows two numbers: ",
              "the ", tags$strong("x-range"), " (e.g. '37k–38k') is the emission value interval for that bin in tonnes — ",
              "the width of this interval reflects the spread of the distribution for that source; ",
              "the ", tags$strong("count"), " (e.g. '530') is the number of Monte Carlo iterations that fell in that bin. ",
              "A narrow x-range with a tall peak indicates low uncertainty; a wide x-range with a flat histogram indicates high uncertainty."),
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
          bslib::card_header("Trend chart — Total CO₂eq with 95% CI band"),
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
