# Master Server Function
app_server <- function(input, output, session) {

  # Reactive values
  rv <- reactiveValues(
    param_specs = NULL,
    inv_metadata = NULL,
    manure_data = NULL,
    population = NULL,
    corr_matrix = NULL,
    ef_corr_matrix = NULL,
    mc_results = NULL,
    uncertainty = NULL,
    decomposition = NULL,
    sensitivity = NULL,
    ipcc_table = NULL,
    sim_log = "",
    sim_running = FALSE,
    sim_error = NULL,
    comparison_result = NULL,
    comparison_sensitivity = NULL,
    upload_status = NULL,   # NULL | list(type = "success"|"error", message = "...")
    has_custom_upload = FALSE
  )

  # --- DATA INPUT ---

  # T1.1 fix: when the user has a custom upload loaded and re-touches the country
  # dropdown, ask before overwriting. Otherwise load the example silently.
  observeEvent(input$country, {
    if (!input$country %in% c("uganda", "zimbabwe")) return()  # "custom" is a no-op
    if (isTRUE(rv$has_custom_upload)) {
      showModal(modalDialog(
        title = "Discard custom upload?",
        paste0("Loading the ", tools::toTitleCase(input$country),
               " example will overwrite your uploaded data. Proceed?"),
        footer = tagList(
          modalButton("Keep my upload"),
          actionButton("confirm_load_example", "Load example",
                       class = "btn-warning")
        ),
        easyClose = TRUE
      ))
      return()
    }
    .load_example(input$country)
  })

  # Helper: load an example dataset
  .load_example <- function(name) {
    # T0.3: anonymised example labels — underlying data unchanged
    if (name == "uganda") {
      rv$param_specs <- fill_bounds(generate_uganda_example())
      rv$sim_log <- "Country X (hypothetical dairy) example data loaded.\n"
    } else if (name == "zimbabwe") {
      rv$param_specs <- fill_bounds(generate_uganda_example())  # placeholder
      rv$sim_log <- "Country Y (hypothetical pastoral) example loaded (using Country X defaults as placeholder).\n"
    }
    rv$has_custom_upload <- FALSE
    rv$upload_status     <- NULL
  }

  observeEvent(input$confirm_load_example, {
    removeModal()
    .load_example(input$country)
  })

  # T1.1 fix: surface upload errors and successes visibly on Tab 1.
  # Previously errors only landed in rv$sim_log (Tab 5) — invisible to a user on Tab 1,
  # who would see the Uganda data still there and assume the upload silently failed.
  observeEvent(input$data_upload, {
    req(input$data_upload)
    fname <- input$data_upload$name
    tryCatch({
      parsed <- parse_uploaded_template(input$data_upload$datapath)

      if (is.null(parsed$param_specs) || nrow(parsed$param_specs) == 0)
        stop("No recognised parameters found in the Parameters sheet. ",
             "Check that parameter names match the expected list ",
             "(see the Vocab sheet of the template).")

      rv$param_specs    <- parsed$param_specs
      rv$inv_metadata   <- parsed$metadata
      rv$manure_data    <- parsed$manure
      rv$population     <- parsed$population
      if (!is.null(parsed$corr_matrix)) rv$corr_matrix <- parsed$corr_matrix
      rv$has_custom_upload <- TRUE

      msg <- sprintf("%d parameters loaded from %s", nrow(parsed$param_specs), fname)
      if (!is.null(parsed$metadata) && nzchar(parsed$metadata$country %||% ""))
        msg <- paste0(msg, " (country: ", parsed$metadata$country, ")")
      if (!is.null(parsed$corr_matrix))
        msg <- paste0(msg, " — correlation matrix loaded from Parameter_TimeSeries (",
                      nrow(parsed$corr_matrix), " parameters)")

      rv$upload_status <- list(type = "success", message = msg)
      rv$sim_log <- paste0(rv$sim_log, "Custom data uploaded: ", msg, "\n")

      showNotification(msg, type = "message", duration = 6)

      if (length(parsed$warnings) > 0) {
        showNotification(paste("Upload warnings:",
                               paste(parsed$warnings, collapse = "; ")),
                         type = "warning", duration = 8)
      }
    }, error = function(e) {
      rv$upload_status <- list(type = "error",
                               message = paste0("Upload failed (", fname, "): ",
                                                e$message))
      rv$sim_log <- paste0(rv$sim_log, "Upload error: ", e$message, "\n")
      showNotification(paste0("Upload failed: ", e$message),
                       type = "error", duration = 10)
    })
  })

  # Parameter data table
  output$param_table <- DT::renderDT({
    req(rv$param_specs)
    DT::datatable(rv$param_specs, options = list(pageLength = 20, scrollX = TRUE),
                  editable = TRUE, rownames = FALSE)
  })

  # T3.2: quick-set buttons to apply common distribution settings
  observeEvent(input$set_all_normal, {
    req(rv$param_specs)
    ad <- rv$param_specs$param_type == "activity_data"
    rv$param_specs$distribution[ad]    <- "normal"
    rv$param_specs$uncertainty_pct[ad] <- 15
    rv$param_specs <- fill_bounds(.recompute_bounds(rv$param_specs, which(ad)))
    showNotification("Set all activity-data parameters to Normal ±15%",
                     type = "message", duration = 4)
  })
  observeEvent(input$set_all_pert, {
    req(rv$param_specs)
    ef <- rv$param_specs$param_type == "emission_factor"
    rv$param_specs$distribution[ef] <- "pert"
    showNotification("Set all emission-factor parameters to PERT",
                     type = "message", duration = 4)
  })
  # Helper: recompute lower/upper from mean and uncertainty_pct for given rows
  .recompute_bounds <- function(ps, rows) {
    for (i in rows) {
      m   <- suppressWarnings(as.numeric(ps$mean[i]))
      pct <- suppressWarnings(as.numeric(ps$uncertainty_pct[i]))
      if (!is.na(m) && !is.na(pct)) {
        ps$lower[i] <- m * (1 - pct / 100)
        ps$upper[i] <- m * (1 + pct / 100)
      }
    }
    ps
  }

  # Edit parameter table in place — with bidirectional cascade (T1.8, T1.11a)
  # Edits to uncertainty_pct  -> recompute lower/upper from mean
  # Edits to lower or upper   -> recompute uncertainty_pct from the symmetric half-width
  # Edits to mean             -> recompute lower/upper from existing uncertainty_pct
  # Edits to distribution=constant -> zero uncertainty_pct, set lower=upper=mean
  observeEvent(input$param_table_cell_edit, {
    info     <- input$param_table_cell_edit
    cols     <- names(rv$param_specs)
    edit_col <- cols[info$col + 1]
    row      <- info$row

    # Apply the edit
    rv$param_specs[row, edit_col] <- DT::coerceValue(
      info$value, rv$param_specs[row, edit_col])

    ps   <- rv$param_specs
    mean <- suppressWarnings(as.numeric(ps$mean[row]))

    # Cascade rules
    if (edit_col == "distribution" && identical(ps$distribution[row], "constant")) {
      if ("uncertainty_pct" %in% cols) ps$uncertainty_pct[row] <- 0
      if ("lower" %in% cols)            ps$lower[row]            <- mean
      if ("upper" %in% cols)            ps$upper[row]            <- mean
    } else if (edit_col %in% c("uncertainty_pct", "mean") &&
               "uncertainty_pct" %in% cols && !is.na(mean)) {
      pct <- suppressWarnings(as.numeric(ps$uncertainty_pct[row]))
      if (!is.na(pct)) {
        if ("lower" %in% cols) ps$lower[row] <- mean * (1 - pct / 100)
        if ("upper" %in% cols) ps$upper[row] <- mean * (1 + pct / 100)
      }
    } else if (edit_col %in% c("lower", "upper") && !is.na(mean) && mean != 0 &&
               "uncertainty_pct" %in% cols) {
      lo <- suppressWarnings(as.numeric(ps$lower[row]))
      up <- suppressWarnings(as.numeric(ps$upper[row]))
      if (!is.na(lo) && !is.na(up)) {
        # Use symmetric half-width as the implied uncertainty_pct
        half <- ((up - lo) / 2) / mean * 100
        ps$uncertainty_pct[row] <- round(half, 2)
      }
    }

    rv$param_specs <- ps
  })

  # Validation — surfaces upload status (success/failure) AND data validation errors
  output$validation_status <- renderUI({
    blocks <- list()
    # Show upload status banner if present (T1.1: makes upload errors visible)
    if (!is.null(rv$upload_status)) {
      cls <- if (rv$upload_status$type == "success") "validation-ok" else "validation-error"
      ic  <- if (rv$upload_status$type == "success") "check-circle" else "exclamation-triangle"
      blocks <- c(blocks, list(
        tags$div(class = cls, icon(ic), rv$upload_status$message)
      ))
    }
    if (is.null(rv$param_specs)) {
      blocks <- c(blocks, list(
        tags$div(class = "validation-error", icon("info-circle"),
                 "No data loaded. Select an example or upload a template.")
      ))
    } else {
      v <- validate_param_specs(rv$param_specs)
      if (v$valid) {
        blocks <- c(blocks, list(
          tags$div(class = "validation-ok", icon("check-circle"),
                   paste("Valid:", nrow(rv$param_specs), "parameters loaded"))
        ))
      } else {
        blocks <- c(blocks, list(
          tags$div(class = "validation-error", icon("exclamation-triangle"),
                   paste("Errors:", paste(v$errors, collapse = "; ")))
        ))
      }
    }
    do.call(tagList, blocks)
  })

  # --- QA/QC ---

  qaqc_result <- reactive({
    req(rv$param_specs)
    run_qaqc(rv$param_specs)
  })

  output$qaqc_summary_ui <- renderUI({
    df <- qaqc_result()
    s  <- qaqc_summary(df)
    if (nrow(df) == 0)
      return(tags$p("Load data first.", style = "color:#888;"))
    tags$div(
      style = "display:flex; gap:8px; flex-wrap:wrap;",
      tags$span(class = "badge bg-success",
                style = "font-size:1rem; padding:6px 14px;",
                paste(s$n_pass, "pass")),
      tags$span(class = "badge bg-warning text-dark",
                style = "font-size:1rem; padding:6px 14px;",
                paste(s$n_warn, "warn")),
      tags$span(class = "badge bg-danger",
                style = "font-size:1rem; padding:6px 14px;",
                paste(s$n_fail, "fail"))
    )
  })

  output$qaqc_table <- DT::renderDT({
    df <- qaqc_result()
    if (nrow(df) == 0)
      return(DT::datatable(data.frame(message = "No data loaded."),
                           rownames = FALSE, options = list(dom = "t")))
    df$status_icon <- sapply(df$status, qaqc_icon)
    display <- df[, c("group", "parameter", "check", "status_icon", "message")]
    DT::datatable(
      display,
      escape    = FALSE,
      rownames  = FALSE,
      colnames  = c("Group", "Parameter", "Check", "Status", "Message"),
      options   = list(
        pageLength = 50,
        dom        = "ftp",
        columnDefs = list(
          list(targets = 3, orderData = 0),  # sort by status_icon uses its text
          list(width = "90px", targets = 2),
          list(width = "80px", targets = 3)
        )
      )
    )
  })

  # Uncertainty table
  output$uncertainty_table <- DT::renderDT({
    req(rv$param_specs)
    DT::datatable(
      rv$param_specs[, c("parameter", "mean", "uncertainty_pct", "distribution",
                          "lower", "upper", "param_type")],
      options = list(pageLength = 20), editable = TRUE, rownames = FALSE
    )
  })

  # Template downloads
  output$download_template <- downloadHandler(
    filename = "uncertainty_template.xlsx",
    content = function(file) generate_template(file, include_example = FALSE)
  )
  output$download_template_example <- downloadHandler(
    filename = "uncertainty_template_example.xlsx",
    content = function(file) generate_template(file, include_example = TRUE)
  )

  # --- CORRELATIONS ---

  output$corr_heatmap <- plotly::renderPlotly({
    if (is.null(rv$corr_matrix)) {
      plotly::plot_ly() %>%
        plotly::layout(title = "No correlation matrix loaded",
                       xaxis = list(visible = FALSE), yaxis = list(visible = FALSE))
    } else {
      plotly::plot_ly(z = rv$corr_matrix, type = "heatmap",
                      x = colnames(rv$corr_matrix), y = rownames(rv$corr_matrix),
                      colorscale = list(c(0, "#C1121F"), c(0.5, "#FFFFFF"), c(1, "#2D6A4F")),
                      zmin = -1, zmax = 1) %>%
        plotly::layout(title = "Activity Data Correlation Matrix")
    }
  })

  output$corr_ts_status <- renderUI({
    if (is.null(rv$corr_matrix)) {
      div(style = "font-size:0.85rem; color:#92400E; background:#FEF3C7; padding:8px 10px; border-radius:6px;",
          icon("exclamation-triangle"), " No time series data found. Fill in the ",
          tags$strong("Parameter_TimeSeries"), " sheet in your input template and re-upload.")
    } else {
      n <- nrow(rv$corr_matrix)
      nms <- paste(rownames(rv$corr_matrix), collapse = ", ")
      div(style = "font-size:0.85rem; color:#1B4332; background:#D8F3DC; padding:8px 10px; border-radius:6px;",
          icon("check-circle"), sprintf(" Correlation matrix loaded: %d parameters (%s).", n, nms))
    }
  })

  # EF correlation matrix — built from UI inputs whenever they change
  ef_corr_reactive <- reactive({
    req(rv$param_specs)
    if (is.null(input$ef_corr_mode) || input$ef_corr_mode == "none") return(NULL)
    ef_params <- rv$param_specs[rv$param_specs$param_type == "emission_factor", ]
    n_ef <- nrow(ef_params)
    if (n_ef < 2) return(NULL)
    rho <- if (!is.null(input$ef_corr_rho)) input$ef_corr_rho else 0.3
    mat <- make_uniform_corr(n_ef, rho)
    rownames(mat) <- colnames(mat) <- ef_params$parameter
    mat
  })

  observe({
    rv$ef_corr_matrix <- ef_corr_reactive()
  })

  output$ef_corr_heatmap <- plotly::renderPlotly({
    mat <- ef_corr_reactive()
    if (is.null(mat)) {
      plotly::plot_ly() %>%
        plotly::layout(title = "No EF correlation (independent sampling)",
                       xaxis = list(visible = FALSE), yaxis = list(visible = FALSE))
    } else {
      plotly::plot_ly(z = mat, type = "heatmap",
                      x = colnames(mat), y = rownames(mat),
                      colorscale = list(c(0, "#FFFFFF"), c(1, "#2D6A4F")),
                      zmin = 0, zmax = 1) %>%
        plotly::layout(title = sprintf("EF Correlation Matrix (rho = %.2f)", input$ef_corr_rho))
    }
  })

  # --- SIMULATION ---

  observeEvent(input$run_sim, {
    req(rv$param_specs)

    # T1.2 / T2.2: completeness check before running the simulation
    comp <- validate_completeness(rv$param_specs)
    if (!isTRUE(comp$valid)) {
      showNotification(paste0("Cannot run simulation. ", comp$message),
                       type = "error", duration = 12)
      rv$sim_log <- paste0(rv$sim_log,
                           "Completeness check failed: ", comp$message, "\n")
      return()
    }

    rv$sim_running <- TRUE
    rv$sim_error   <- NULL
    n_iter_fmt <- format(input$n_iter, big.mark = ",")

    rv$sim_log <- paste0(rv$sim_log, "\n--- Starting simulation ---\n")
    rv$sim_log <- paste0(rv$sim_log, "Iterations: ", input$n_iter, "\n")
    rv$sim_log <- paste0(rv$sim_log, "GWP: ", input$gwp_version, "\n")
    if (!is.null(rv$ef_corr_matrix)) {
      rho_val <- if (!is.null(input$ef_corr_rho)) input$ef_corr_rho else "?"
      rv$sim_log <- paste0(rv$sim_log, "EF correlation: uniform rho = ", rho_val, "\n")
    } else {
      rv$sim_log <- paste0(rv$sim_log, "EF correlation: none (independent)\n")
    }

    withProgress(
      message = sprintf("Monte Carlo simulation (%s iterations)", n_iter_fmt),
      value   = 0,
      {
        tryCatch({

          # ---- Stage 1: build system data ----
          setProgress(0.03, detail = "Preparing system data...")

          specs  <- rv$param_specs
          manure <- rv$manure_data

          make_group_key <- function(df) {
            if (all(c("cattle_type", "aggregation_level") %in% names(df))) {
              sub <- if ("sub_category" %in% names(df)) df$sub_category else rep("", nrow(df))
              paste(df$cattle_type, df$aggregation_level, sub, sep = "||")
            } else if (all(c("system", "subsystem") %in% names(df))) {
              paste(df$system, df$subsystem, sep = "||")
            } else {
              rep("group1", nrow(df))
            }
          }

          group_key  <- make_group_key(specs)
          sys_groups <- unique(group_key)
          systems_data <- list()

          default_mms_fracs <- c(pasture = 0.70, solid_storage = 0.30)
          default_mcf_vals  <- c(pasture = 0.015, solid_storage = 0.050)
          default_ef3_vals  <- c(pasture = 0.020, solid_storage = 0.005)

          for (sg in sys_groups) {
            sys_specs <- specs[group_key == sg, ]

            if (!is.null(manure) && nrow(manure) > 0 &&
                all(c("mms_type", "fraction_pct", "MCF_pct", "EF3") %in% names(manure))) {
              manure_key <- make_group_key(manure)
              mms_rows   <- manure[manure_key == sg, ]
              if (nrow(mms_rows) > 0) {
                mms_fracs <- setNames(mms_rows$fraction_pct / 100, mms_rows$mms_type)
                mcf_vals  <- setNames(mms_rows$MCF_pct / 100,      mms_rows$mms_type)
                ef3_vals  <- setNames(mms_rows$EF3,                mms_rows$mms_type)
              } else {
                mms_fracs <- default_mms_fracs
                mcf_vals  <- default_mcf_vals
                ef3_vals  <- default_ef3_vals
              }
            } else {
              mms_fracs <- default_mms_fracs
              mcf_vals  <- default_mcf_vals
              ef3_vals  <- default_ef3_vals
            }

            corr <- if (input$corr_mode != "none" && !is.null(rv$corr_matrix)) {
              ad_names <- sys_specs$parameter[sys_specs$param_type == "activity_data"]
              expand_corr_matrix(rv$corr_matrix, ad_names)
            } else NULL

            ef_corr <- if (!is.null(rv$ef_corr_matrix)) {
              ef_n <- sum(sys_specs$param_type == "emission_factor")
              if (nrow(rv$ef_corr_matrix) == ef_n) rv$ef_corr_matrix else NULL
            } else NULL

            systems_data[[sg]] <- list(
              param_specs = sys_specs, corr_matrix = corr, ef_corr_matrix = ef_corr,
              mms_fractions = mms_fracs, mcf_values = mcf_vals, ef3_values = ef3_vals
            )
          }

          # ---- Stage 2: Monte Carlo sampling ----
          n_sys <- length(sys_groups)
          setProgress(0.08,
            detail = sprintf("Sampling %s iterations across %d system(s)...",
                             n_iter_fmt, n_sys))

          sim_result <- run_inventory_simulation(
            systems_data, n_iter = input$n_iter,
            gwp = input$gwp_version, seed = input$seed
          )
          rv$mc_results <- sim_result

          # ---- Stage 3: uncertainty metrics ----
          setProgress(0.40, detail = "Computing uncertainty metrics...")
          rv$uncertainty <- calc_all_uncertainty(sim_result$inventory)
          rv$sim_log <- paste0(rv$sim_log, "Simulation complete.\n")

          # ---- Stage 4: decomposition (3 additional MC runs) ----
          if (input$run_decomposition && length(systems_data) == 1) {
            sg <- names(systems_data)[1]
            setProgress(0.48, detail = "Running AD-only simulation...")
            # decompose_uncertainty runs combined + AD-only + EF-only internally
            # progress jumps to ~90% when it returns
            rv$decomposition <- decompose_uncertainty(
              systems_data[[sg]]$param_specs,
              systems_data[[sg]]$corr_matrix,
              n_iter         = input$n_iter,
              mms_fractions  = mms_fracs, mcf_values = mcf_vals, ef3_values = ef3_vals,
              gwp            = input$gwp_version, seed = input$seed,
              ef_corr_matrix = systems_data[[sg]]$ef_corr_matrix
            )
            rv$ipcc_table <- format_ipcc_table(rv$decomposition)
            rv$sim_log <- paste0(rv$sim_log, "Uncertainty decomposition complete.\n")
            setProgress(0.90, detail = "Decomposition complete.")
          } else {
            setProgress(0.90, detail = "Decomposition skipped.")
          }

          # ---- Stage 5: sensitivity analysis ----
          setProgress(0.92, detail = "Running sensitivity analysis...")
          if (length(sim_result$by_system) > 0) {
            first_sys <- sim_result$by_system[[1]]
            rv$sensitivity <- sensitivity_analysis(
              first_sys$samples, first_sys$results$total_co2e, method = "both"
            )
            rv$sim_log <- paste0(rv$sim_log, "Sensitivity analysis complete.\n")
          }

          # ---- Stage 6: comparison run (no correlations) ----
          rv$comparison_result      <- NULL
          rv$comparison_sensitivity <- NULL
          if (isTRUE(input$run_comparison)) {
            setProgress(0.94, detail = "Running comparison (no correlations)...")
            systems_nocorr <- lapply(systems_data, function(s) {
              s$corr_matrix    <- NULL
              s$ef_corr_matrix <- NULL
              s
            })
            nocorr_result <- run_inventory_simulation(
              systems_nocorr, n_iter = input$n_iter,
              gwp = input$gwp_version, seed = input$seed
            )
            rv$comparison_result <- nocorr_result
            if (length(nocorr_result$by_system) > 0) {
              first_nocorr <- nocorr_result$by_system[[1]]
              rv$comparison_sensitivity <- sensitivity_analysis(
                first_nocorr$samples, first_nocorr$results$total_co2e, method = "both"
              )
            }
            rv$sim_log <- paste0(rv$sim_log, "Comparison (no correlations) complete.\n")
            setProgress(0.99, detail = "Comparison complete.")
          }

          setProgress(1.00, detail = "Done.")
          rv$sim_running <- FALSE

          # T5.1: auto-navigate to Results tab on success
          bslib::nav_select(id = "nav", selected = "6. Results", session = session)
          showNotification("Simulation complete. Showing Results.",
                           type = "message", duration = 5)

        }, error = function(e) {
          rv$sim_log   <- paste0(rv$sim_log, "ERROR: ", e$message, "\n")
          rv$sim_error <- e$message
          rv$sim_running <- FALSE
        })
      }
    )
  })

  output$sim_log <- renderText(rv$sim_log)

  output$sim_status <- renderUI({
    if (!is.null(rv$sim_error)) {
      tags$div(
        style = "color:#C1121F; font-weight:600; margin-top:8px;",
        icon("exclamation-triangle"), " Error: ", rv$sim_error
      )
    } else if (!is.null(rv$mc_results)) {
      n_sys <- if (!is.null(rv$mc_results$by_system)) length(rv$mc_results$by_system) else 1
      tags$div(
        style = "color:#2D6A4F; font-weight:600; margin-top:8px;",
        icon("check-circle"),
        sprintf(" Complete — %d system(s) simulated.", n_sys)
      )
    } else {
      tags$div(style = "color:#6B6B6B; margin-top:8px;", "Ready to run.")
    }
  })

  # --- RESULTS ---

  output$vb_ch4 <- renderText({
    req(rv$uncertainty)
    row <- rv$uncertainty[rv$uncertainty$variable == "total_ch4", ]
    if (nrow(row) > 0) paste0(round(row$mean, 1), " t") else "---"
  })

  output$vb_n2o <- renderText({
    req(rv$uncertainty)
    row <- rv$uncertainty[rv$uncertainty$variable == "total_n2o", ]
    if (nrow(row) > 0) paste0(round(row$mean, 3), " t") else "---"
  })

  output$vb_co2e <- renderText({
    req(rv$uncertainty)
    row <- rv$uncertainty[rv$uncertainty$variable == "total_co2e", ]
    if (nrow(row) > 0) paste0(round(row$mean, 1), " t CO2eq") else "---"
  })

  # T6.3: secondary inline display of CO2eq (kept for sensitivity)
  output$vb_co2e_inline <- renderText({
    req(rv$uncertainty)
    row <- rv$uncertainty[rv$uncertainty$variable == "total_co2e", ]
    if (nrow(row) > 0) paste0(round(row$mean, 1), " t (95% CI ",
                              round(row$ci_lower, 1), "–",
                              round(row$ci_upper, 1), ")") else "---"
  })

  output$vb_cv <- renderText({
    req(rv$uncertainty)
    row <- rv$uncertainty[rv$uncertainty$variable == "total_co2e", ]
    if (nrow(row) > 0) paste0(round(row$cv_pct, 1), "%") else "---"
  })

  # T6.1 / T8.1: IPCC 95% margin of error
  output$vb_moe <- renderText({
    req(rv$uncertainty)
    row <- rv$uncertainty[rv$uncertainty$variable == "total_co2e", ]
    if (nrow(row) > 0) paste0("±", round(row$moe_pct, 1), "%") else "---"
  })

  output$results_histogram <- plotly::renderPlotly({
    req(rv$mc_results)
    co2e <- rv$mc_results$inventory$total_co2e
    ci <- quantile(co2e, c(0.025, 0.975))

    plotly::plot_ly(x = co2e, type = "histogram", nbinsx = 50,
                    marker = list(color = "#2D6A4F", line = list(color = "#1B4332", width = 1))) %>%
      plotly::layout(
        title = "Distribution of Total CO2eq Emissions",
        xaxis = list(title = "Total CO2eq (tonnes)"),
        yaxis = list(title = "Frequency"),
        shapes = list(
          list(type = "line", x0 = ci[1], x1 = ci[1], y0 = 0, y1 = 1,
               yref = "paper", line = list(color = "#C1121F", dash = "dash")),
          list(type = "line", x0 = ci[2], x1 = ci[2], y0 = 0, y1 = 1,
               yref = "paper", line = list(color = "#C1121F", dash = "dash"))
        )
      )
  })

  output$decomposition_plot <- plotly::renderPlotly({
    req(rv$decomposition)
    vars <- c("total_co2e")
    categories <- c("AD Only", "EF Only", "Combined")
    cv_vals <- sapply(categories, function(cat) {
      df <- switch(cat,
        "AD Only" = rv$decomposition$ad_only,
        "EF Only" = rv$decomposition$ef_only,
        "Combined" = rv$decomposition$combined
      )
      row <- df[df$variable == "total_co2e", ]
      if (nrow(row) > 0) row$cv_pct else NA
    })

    plotly::plot_ly(x = categories, y = cv_vals, type = "bar",
                    marker = list(color = c("#40916C", "#4361EE", "#2D6A4F"))) %>%
      plotly::layout(title = "Uncertainty Decomposition (CV %)",
                     yaxis = list(title = "CV (%)"))
  })

  output$results_by_system <- DT::renderDT({
    req(rv$mc_results)
    sys_names <- names(rv$mc_results$by_system)
    summary_rows <- lapply(sys_names, function(sn) {
      res <- rv$mc_results$by_system[[sn]]$results
      m   <- mean(res$total_co2e)
      lo  <- quantile(res$total_co2e, 0.025, names = FALSE)
      hi  <- quantile(res$total_co2e, 0.975, names = FALSE)
      data.frame(
        System = sn,
        Mean_CH4_t = round(mean(res$total_ch4), 2),
        Mean_N2O_t = round(mean(res$total_n2o), 4),
        Mean_CO2eq_t = round(m, 2),
        # T6.1: IPCC 95% margin of error (primary), CV% (secondary)
        MoE_95_pct = round(((hi - lo) / 2) / m * 100, 1),
        CV_pct = round(sd(res$total_co2e) / m * 100, 1),
        CI_Lower = round(lo, 2),
        CI_Upper = round(hi, 2)
      )
    })
    DT::datatable(do.call(rbind, summary_rows), rownames = FALSE,
                  options = list(pageLength = 20))
  })

  # Comparison card in Results tab — only rendered when comparison data exists
  output$comparison_card <- renderUI({
    if (is.null(rv$comparison_result)) return(NULL)
    bslib::card(
      bslib::card_header("Effect of Correlations on Uncertainty"),
      bslib::card_body(plotly::plotlyOutput("comparison_plot", height = "320px"))
    )
  })

  output$comparison_plot <- plotly::renderPlotly({
    req(rv$mc_results, rv$comparison_result)

    vars   <- c("total_co2e", "total_ch4", "total_n2o")
    labels <- c("Total CO2eq", "Total CH4", "Total N2O")

    unc_with    <- calc_all_uncertainty(rv$mc_results$inventory)
    unc_without <- calc_all_uncertainty(rv$comparison_result$inventory)

    get_cv <- function(unc, v) {
      row <- unc[unc$variable == v, ]
      if (nrow(row) > 0) round(row$cv_pct, 1) else NA_real_
    }

    cv_with    <- sapply(vars, get_cv, unc = unc_with)
    cv_without <- sapply(vars, get_cv, unc = unc_without)

    plotly::plot_ly() %>%
      plotly::add_bars(x = labels, y = cv_with,    name = "With correlations",
                       marker = list(color = "#2D6A4F")) %>%
      plotly::add_bars(x = labels, y = cv_without, name = "Without correlations",
                       marker = list(color = "#90A4AE")) %>%
      plotly::layout(
        barmode = "group",
        title   = "CV% comparison: with vs. without correlations",
        yaxis   = list(title = "Coefficient of Variation (%)"),
        xaxis   = list(title = ""),
        legend  = list(orientation = "h", y = -0.25)
      )
  })

  # --- SENSITIVITY ---

  # Toggle appears only when comparison data exists
  output$sens_view_toggle <- renderUI({
    if (is.null(rv$comparison_result)) return(NULL)
    div(
      style = "margin: 0 16px 12px 16px;",
      radioButtons("sens_view", "View:",
                   choices = c("With correlations"    = "with",
                               "Without correlations" = "without"),
                   selected = "with", inline = TRUE)
    )
  })

  # Helper: pick the right sensitivity dataset
  active_sensitivity <- reactive({
    view <- if (!is.null(input$sens_view)) input$sens_view else "with"
    if (view == "without" && !is.null(rv$comparison_sensitivity)) {
      rv$comparison_sensitivity
    } else {
      rv$sensitivity
    }
  })

  output$tornado_chart <- plotly::renderPlotly({
    sens_data <- active_sensitivity()
    req(sens_data)
    sens <- if (input$sens_method == "src" && !is.null(sens_data$src)) {
      sens_data$src
    } else if (!is.null(sens_data$prcc)) {
      sens_data$prcc
    } else return(plotly::plot_ly())

    top10 <- head(sens, 10)
    val_col <- if ("src" %in% names(top10)) "src" else "prcc"
    top10 <- top10[order(top10[[val_col]]), ]

    # Colour by user_reducible: green = user can improve with better data; grey = IPCC coefficient
    reducible_lut <- setNames(PARAM_CATALOGUE$user_reducible, PARAM_CATALOGUE$parameter)
    top10$reducible <- reducible_lut[top10$parameter]
    top10$reducible[is.na(top10$reducible)] <- TRUE
    bar_colours <- ifelse(top10[[val_col]] > 0,
      ifelse(top10$reducible, "#2D6A4F", "#78909C"),
      ifelse(top10$reducible, "#C1121F", "#90A4AE")
    )

    view_label <- if (!is.null(input$sens_view) && input$sens_view == "without")
      " (without correlations)" else ""

    plotly::plot_ly(y = factor(top10$parameter, levels = top10$parameter),
                    x = top10[[val_col]], type = "bar", orientation = "h",
                    marker = list(color = bar_colours),
                    text = ifelse(top10$reducible, "User-reducible", "IPCC coefficient"),
                    hoverinfo = "x+y+text") %>%
      plotly::layout(
        title = paste0("Top Parameters — ", toupper(val_col), view_label),
        xaxis = list(title = val_col), yaxis = list(title = ""),
        annotations = list(list(
          x = 0.99, y = 0.01, xref = "paper", yref = "paper", showarrow = FALSE, align = "right",
          text = "<span style='color:#2D6A4F'>■</span> User-reducible &nbsp; <span style='color:#78909C'>■</span> IPCC coefficient",
          font = list(size = 10)
        ))
      )
  })

  output$sensitivity_table <- DT::renderDT({
    sens_data <- active_sensitivity()
    req(sens_data)
    sens <- if (input$sens_method == "src") sens_data$src else sens_data$prcc
    req(sens)
    DT::datatable(sens, rownames = FALSE, options = list(pageLength = 20))
  })

  # --- IPCC REPORT ---

  output$ipcc_table <- DT::renderDT({
    req(rv$ipcc_table)
    DT::datatable(rv$ipcc_table, rownames = FALSE,
                  options = list(pageLength = 10, dom = 't'))
  })

  # T8.3: input documentation table for IPCC inventory submission / QA
  output$inputs_doc_table <- DT::renderDT({
    req(rv$param_specs)
    ps <- rv$param_specs
    keep <- intersect(c("cattle_type", "aggregation_level", "sub_category",
                        "parameter", "param_type", "mean", "uncertainty_pct",
                        "lower", "upper", "distribution", "data_source",
                        "ipcc_ref"),
                      names(ps))
    DT::datatable(ps[, keep, drop = FALSE], rownames = FALSE,
                  options = list(pageLength = 25, scrollX = TRUE),
                  class = "compact stripe")
  })

  output$download_xlsx <- downloadHandler(
    filename = function() paste0("uncertainty_report_", Sys.Date(), ".xlsx"),
    content = function(file) {
      req(rv$mc_results, rv$uncertainty)
      export_results_xlsx(
        rv$mc_results$inventory, rv$uncertainty,
        rv$sensitivity, rv$ipcc_table, file
      )
    }
  )

  output$download_csv <- downloadHandler(
    filename = function() paste0("uncertainty_results_", Sys.Date(), ".csv"),
    content = function(file) {
      req(rv$uncertainty)
      write.csv(rv$uncertainty, file, row.names = FALSE)
    }
  )
}
