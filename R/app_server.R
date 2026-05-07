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
    has_custom_upload = FALSE,
    sim_view = "settings"   # R1.5: "settings" or "results" — drives Tab 5 panel toggle
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
    # T0.3 + B1: distinct example datasets per country selection
    if (name == "uganda") {
      rv$param_specs <- fill_bounds(generate_uganda_example())
      # R2.2: built-in example now ships with synthetic 5-year time-series so
      # that Tab 4's "From template (auto)" correlation mode works without
      # requiring a separate Excel upload.
      rv$population  <- generate_uganda_timeseries()
      rv$corr_matrix <- compute_corr_from_population(rv$population)
      rv$sim_log <- "Country X (hypothetical dairy smallholder) example data loaded — 12 parameters, dairy / cows; 5-year synthetic time-series populated for correlation auto-mode.\n"
    } else if (name == "zimbabwe") {
      rv$param_specs <- fill_bounds(generate_country_y_example())
      rv$population  <- generate_country_y_timeseries()
      rv$corr_matrix <- compute_corr_from_population(rv$population)
      rv$sim_log <- "Country Y (hypothetical pastoral non-dairy) example data loaded — 11 parameters, non_dairy / breeding_cows; 5-year synthetic time-series populated for correlation auto-mode.\n"
    }
    rv$has_custom_upload <- FALSE
    rv$upload_status     <- list(type = "success",
                                 message = sprintf("%s example loaded — %d parameters (with example time-series)",
                                   if (name == "uganda") "Country X" else "Country Y",
                                   nrow(rv$param_specs)))
  }

  observeEvent(input$confirm_load_example, {
    removeModal()
    .load_example(input$country)
  })

  # T1.1 fix: surface upload errors and successes visibly on Tab 1.
  # Previously errors only landed in rv$sim_log (Tab 5) — invisible to a user on Tab 1,
  # who would see the Country X example data still there and assume the upload silently failed.
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

  # Parameter data table — R1.3: imputed rows rendered in red bold
  # Round 6b #4: add hover tooltip on imputed rows showing default + IPCC ref
  output$param_table <- DT::renderDT({
    req(rv$param_specs)
    ps <- rv$param_specs
    has_imputed <- "imputed" %in% names(ps) && any(isTRUE(ps$imputed) | ps$imputed == TRUE, na.rm = TRUE)

    options_list <- list(
      pageLength = 20,
      scrollX = TRUE,
      columnDefs = list(list(
        targets = which(names(ps) == "imputed") - 1,
        visible = FALSE))
    )

    if (has_imputed) {
      imputed_col <- which(names(ps) == "imputed") - 1L  # 0-based for JS
      options_list$rowCallback <- DT::JS(sprintf(
        "function(row, data) {
           if (data[%d] === true || data[%d] === 'TRUE' || data[%d] === 'true') {
             $(row).attr('title',
               'Auto-filled from IPCC default. Override in template if local data is available.');
           }
         }",
        imputed_col, imputed_col, imputed_col))
    }

    dt <- DT::datatable(ps,
                        options = options_list,
                        editable = TRUE, rownames = FALSE)
    if (has_imputed) {
      # Highlight imputed rows in red bold
      dt <- DT::formatStyle(dt, "imputed",
                            target = "row",
                            backgroundColor = DT::styleEqual(c(TRUE), c("#FECACA")),
                            color = DT::styleEqual(c(TRUE), c("#7F1D1D")),
                            fontWeight = DT::styleEqual(c(TRUE), c("bold")))
    }
    dt
  })

  # T3.2 / Round 6a #2: quick-set buttons toggle on / undo on second click.
  # On first click, snapshot current rows then apply the preset.
  # On second click, restore the snapshot and clear it. The button label flips
  # between the apply/undo wording in `quickset_normal_label` /
  # `quickset_pert_label` so the user can see which state it is in.
  observeEvent(input$set_all_normal, {
    req(rv$param_specs)
    if (!is.null(rv$quickset_normal_snapshot)) {
      rv$param_specs <- rv$quickset_normal_snapshot
      rv$quickset_normal_snapshot <- NULL
      showNotification("Reverted activity-data preset (restored previous values).",
                       type = "message", duration = 4)
    } else {
      rv$quickset_normal_snapshot <- rv$param_specs
      ad <- rv$param_specs$param_type == "activity_data"
      rv$param_specs$distribution[ad]    <- "normal"
      rv$param_specs$uncertainty_pct[ad] <- 15
      rv$param_specs <- fill_bounds(.recompute_bounds(rv$param_specs, which(ad)))
      showNotification("Set all activity-data parameters to Normal ±15% (click again to undo).",
                       type = "message", duration = 4)
    }
  })
  observeEvent(input$set_all_pert, {
    req(rv$param_specs)
    if (!is.null(rv$quickset_pert_snapshot)) {
      rv$param_specs <- rv$quickset_pert_snapshot
      rv$quickset_pert_snapshot <- NULL
      showNotification("Reverted coefficient PERT preset (restored previous values).",
                       type = "message", duration = 4)
    } else {
      rv$quickset_pert_snapshot <- rv$param_specs
      ef <- rv$param_specs$param_type == "coefficient"
      rv$param_specs$distribution[ef] <- "pert"
      showNotification("Set all coefficients to PERT (click again to undo).",
                       type = "message", duration = 4)
    }
  })

  # If the user edits the parameter table directly after applying a preset,
  # clear the snapshot so the next click is a fresh apply rather than an
  # accidental revert that would discard their edits.
  observeEvent(input$param_table_cell_edit, {
    rv$quickset_normal_snapshot <- NULL
    rv$quickset_pert_snapshot   <- NULL
  })
  observeEvent(input$uncertainty_table_cell_edit, {
    rv$quickset_normal_snapshot <- NULL
    rv$quickset_pert_snapshot   <- NULL
  })

  # Dynamic button labels (apply / undo) for the quick-set actions.
  output$quickset_normal_label <- renderText({
    if (!is.null(rv$quickset_normal_snapshot))
      "Undo: restore previous activity-data settings"
    else
      "Set all activity-data params to Normal ±15%"
  })
  outputOptions(output, "quickset_normal_label", suspendWhenHidden = FALSE)
  output$quickset_pert_label <- renderText({
    if (!is.null(rv$quickset_pert_snapshot))
      "Undo: restore previous coefficient settings"
    else
      "Set all coefficients to PERT"
  })
  outputOptions(output, "quickset_pert_label", suspendWhenHidden = FALSE)
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
    # G2: pass region from metadata for region-aware benchmark check
    region <- if (!is.null(rv$inv_metadata) && "region" %in% names(rv$inv_metadata) &&
                  nzchar(rv$inv_metadata$region %||% "")) {
      rv$inv_metadata$region
    } else "global"
    run_qaqc(rv$param_specs, region = region)
  })

  # --- Auto-filled parameters card (Round 6b #4) ---
  imputed_rows <- reactive({
    ps <- rv$param_specs
    if (is.null(ps) || !"imputed" %in% names(ps)) return(NULL)
    flag <- ps$imputed
    flag[is.na(flag)] <- FALSE
    out <- ps[as.logical(flag), , drop = FALSE]
    if (nrow(out) == 0) return(NULL)
    out
  })

  output$has_imputed_params <- reactive({
    !is.null(imputed_rows())
  })
  outputOptions(output, "has_imputed_params", suspendWhenHidden = FALSE)

  output$imputed_params_card <- renderUI({
    rows <- imputed_rows()
    if (is.null(rows)) return(NULL)
    tagList(
      tags$p(
        sprintf("%d parameter%s not supplied in your upload — auto-filled from IPCC defaults so the simulation could run. Override these values in the template if you have country-specific data.",
                nrow(rows), if (nrow(rows) == 1) "" else "s"),
        style = "margin-bottom:8px; color:#92400E;"
      ),
      DT::DTOutput("imputed_params_dt")
    )
  })

  output$imputed_params_dt <- DT::renderDT({
    rows <- imputed_rows()
    req(rows)

    cat_lookup <- PARAM_CATALOGUE[, c("parameter", "unit", "ipcc_ref")]
    names(cat_lookup)[2:3] <- c("unit_cat", "ipcc_ref_cat")
    rows <- merge(rows, cat_lookup, by = "parameter", all.x = TRUE, sort = FALSE)

    pick <- function(primary, fallback) {
      out <- primary
      missing <- is.na(out) | !nzchar(as.character(out))
      out[missing] <- fallback[missing]
      as.character(out)
    }
    unit_user <- if ("unit" %in% names(rows)) rows$unit else rep(NA_character_, nrow(rows))
    ref_user  <- if ("ipcc_ref" %in% names(rows)) rows$ipcc_ref else rep(NA_character_, nrow(rows))
    unit_disp <- pick(unit_user, rows$unit_cat)
    ref_disp  <- pick(ref_user,  rows$ipcc_ref_cat)
    src_disp  <- if ("data_source" %in% names(rows)) rows$data_source else rep("AUTO-FILLED (IPCC default)", nrow(rows))

    display <- data.frame(
      Parameter = rows$parameter,
      `Default value used` = formatC(rows$mean, digits = 4, format = "g"),
      Unit = unit_disp,
      `IPCC reference` = ref_disp,
      Source = src_disp,
      check.names = FALSE,
      stringsAsFactors = FALSE
    )

    DT::datatable(
      display,
      rownames = FALSE,
      options  = list(dom = "t", paging = FALSE, ordering = FALSE),
      class    = "compact stripe"
    )
  })

  output$qaqc_summary_ui <- renderUI({
    df <- qaqc_result()
    s  <- qaqc_summary(df)
    if (nrow(df) == 0)
      return(tags$p("Load data first.", style = "color:#888;"))
    tags$div(
      style = "display:flex; gap:8px; flex-wrap:wrap;",
      if ((s$n_missing %||% 0) > 0)
        tags$span(
          style = "font-size:1rem; padding:6px 14px; background-color:#FEF3C7; color:#92400E; border-radius:4px; font-weight:600;",
          paste(s$n_missing, "auto-filled")),
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

  # Round 7 R1.16: persist Tab 3 cell edits (including param_type override)
  # back into rv$param_specs and cascade bounds the same way the Tab 1 DT does.
  # Validates that param_type is one of activity_data/coefficient.
  observeEvent(input$uncertainty_table_cell_edit, {
    info <- input$uncertainty_table_cell_edit
    visible_cols <- c("parameter", "mean", "uncertainty_pct", "distribution",
                      "lower", "upper", "param_type")
    edit_col <- visible_cols[info$col + 1]
    row      <- info$row
    if (is.na(edit_col)) return()

    new_value <- info$value
    if (edit_col == "param_type") {
      vt <- tolower(trimws(as.character(new_value)))
      if (vt == "emission_factor") vt <- "coefficient"  # legacy alias
      if (!vt %in% c("activity_data", "coefficient")) {
        showNotification(
          sprintf("param_type must be 'activity_data' or 'coefficient' — got '%s'. Edit ignored.",
                  new_value),
          type = "error", duration = 6)
        return()
      }
      new_value <- vt
    }

    rv$param_specs[row, edit_col] <- DT::coerceValue(
      new_value, rv$param_specs[row, edit_col])

    ps   <- rv$param_specs
    mean <- suppressWarnings(as.numeric(ps$mean[row]))
    cols <- names(ps)

    # Same cascade rules as the Tab 1 DT (param_table)
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
        half <- ((up - lo) / 2) / mean * 100
        ps$uncertainty_pct[row] <- round(half, 2)
      }
    }

    rv$param_specs <- ps
  })

  # Template downloads. Round 7.1: filename and MMS dropdown reflect the
  # IPCC version picked via input$template_version (default = "2006").
  .selected_ipcc_version <- function() {
    v <- input$template_version
    if (is.null(v) || !nzchar(v)) "2006" else v
  }
  .version_suffix <- function(v) {
    if (identical(v, "2019_refinement")) "ipcc2019" else "ipcc2006"
  }
  output$download_template <- downloadHandler(
    filename = function() {
      v <- .selected_ipcc_version()
      paste0("uncertainty_template_", .version_suffix(v), ".xlsx")
    },
    content = function(file) {
      generate_template(file, include_example = FALSE,
                         ipcc_version = .selected_ipcc_version())
    }
  )
  output$download_template_example <- downloadHandler(
    filename = function() {
      v <- .selected_ipcc_version()
      paste0("uncertainty_template_example_", .version_suffix(v), ".xlsx")
    },
    content = function(file) {
      generate_template(file, include_example = TRUE,
                         ipcc_version = .selected_ipcc_version())
    }
  )

  # --- CORRELATIONS ---

  # T4.1 / Round 7 R1.15: IPCC-guidance preset — sparse matrix with documented
  # structural pairs only. After Round 7 the preset operates on the **unified**
  # set of all parameter names (AD + coefficients) so cross-block pairs
  # like N <-> W (T4.3) flow correctly. Bug fixed in Round 7: prior code
  # filtered to activity_data names, which after R1.6 left only `N` and made
  # the preset matrix 1x1 (effectively a no-op for documented pairs like
  # W <-> MW that are coefficients post-rename).
  observeEvent(input$corr_mode, {
    if (input$corr_mode == "preset") {
      all_names <- if (!is.null(rv$param_specs))
        rv$param_specs$parameter
      else
        PARAM_CATALOGUE$parameter
      preset <- build_ipcc_preset_corr(all_names)
      if (is.null(preset)) {
        showNotification(
          "Preset has no applicable pairs for the current parameter set.",
          type = "warning", duration = 5)
        return()
      }
      rv$corr_matrix <- preset
      showNotification(
        sprintf("Loaded IPCC-guidance preset correlation matrix (%d-parameter scope).",
                nrow(preset)),
        type = "message", duration = 4)
    } else if (input$corr_mode == "none") {
      # Don't wipe an uploaded matrix — just don't apply it (sim observer reads input$corr_mode)
    }
  }, ignoreInit = TRUE)

  # T4.1: manual matrix upload (CSV)
  observeEvent(input$corr_matrix_upload, {
    req(input$corr_matrix_upload)
    tryCatch({
      df <- read.csv(input$corr_matrix_upload$datapath, row.names = 1,
                     check.names = FALSE)
      m  <- as.matrix(df)
      if (nrow(m) != ncol(m) || any(is.na(m)))
        stop("Matrix must be square with no missing values.")
      if (any(diag(m) != 1))
        stop("Diagonal entries must be 1.")
      m <- as.matrix(Matrix::nearPD(m, corr = TRUE)$mat)
      rv$corr_matrix <- m
      showNotification(sprintf("Loaded manual correlation matrix (%d parameters).",
                               nrow(m)), type = "message", duration = 5)
    }, error = function(e) {
      showNotification(paste("Matrix upload failed:", e$message),
                       type = "error", duration = 8)
    })
  })

  # Round 6a #5: render the "Compare with/without correlations" checkbox
  # disabled when no correlations are selected on Tab 4 — the comparison
  # run would otherwise be identical to the main run and waste compute time.
  output$run_comparison_ui <- renderUI({
    no_ad_corr <- is.null(input$corr_mode) || input$corr_mode == "none"
    no_ef_corr <- is.null(input$ef_corr_mode) || input$ef_corr_mode == "none"
    if (no_ad_corr && no_ef_corr) {
      tagList(
        tags$div(
          style = "opacity:0.55; pointer-events:none;",
          checkboxInput("run_comparison",
                        "Compare with/without correlations",
                        value = FALSE)
        ),
        tags$div(
          style = "font-size:0.78rem; color:#92400E; background:#FEF3C7; padding:6px 10px; border-radius:4px; margin-top:-6px; margin-bottom:8px;",
          icon("info-circle"),
          tags$em(" No correlations selected on Tab 4 — comparison would be identical to the main run, so this option is disabled. Enable a correlation mode to activate it.")
        )
      )
    } else {
      checkboxInput("run_comparison",
                    "Compare with/without correlations",
                    value = FALSE)
    }
  })

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
      # R2.2: message disambiguates "no template loaded yet" from "template
      # has no time-series sheet". The built-in examples now include
      # time-series, so the most likely cause of seeing this card is a real
      # upload that didn't include the Parameter_TimeSeries sheet.
      div(style = "font-size:0.85rem; color:#92400E; background:#FEF3C7; padding:8px 10px; border-radius:6px;",
          icon("exclamation-triangle"),
          " No time-series data in the loaded inventory. To enable auto-correlation, ",
          "upload a template with a populated ",
          tags$strong("Parameter_TimeSeries"),
          " sheet, or load Country X / Country Y from the dropdown ",
          "(both ship with example time-series).")
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
    ef_params <- rv$param_specs[rv$param_specs$param_type == "coefficient", ]
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

    # Round 6a #1: block run if no analysis mode selected on the Home tab.
    if (is.null(input$analysis_mode) || !nzchar(input$analysis_mode)) {
      showNotification(
        "Please choose an analysis mode (Single year or Trend) on the Home tab before running.",
        type = "error", duration = 10)
      rv$sim_log <- paste0(rv$sim_log,
        "Run blocked: no analysis mode selected on Home tab.\n")
      bslib::nav_select(id = "nav", selected = "Home", session = session)
      return()
    }

    # Round 9: defensive no-op. Trend mode shows a different Run button
    # ('run_trend') via conditionalPanel, so clicking the single-year button
    # in trend mode shouldn't be possible — but if it is, we bail with a
    # message rather than running a single-year sim against trend settings.
    if (input$analysis_mode == "trend") {
      showNotification(
        "Trend mode is selected on the Home page. Click 'Run Trend Analysis' on this tab instead — the single-year Run is only used for analysis_mode = 'single'.",
        type = "warning", duration = 8)
      return()
    }

    # R1.4: block run if no emission sources selected
    if (is.null(input$emission_sources) || length(input$emission_sources) == 0) {
      showNotification(
        "Please tick at least one emission source on the left before running the simulation.",
        type = "error", duration = 8)
      rv$sim_log <- paste0(rv$sim_log,
        "Run blocked: no emission sources selected.\n")
      return()
    }

    # T1.2 / T2.2 / A1: auto-fill missing core params from IPCC defaults
    # rather than blocking the simulation.
    # Round 7 T2.1: pass region so regional IPCC defaults are preferred over
    # the global table for the 5 parameters covered by IPCC_DEFAULTS_BY_REGION.
    region_for_completeness <- if (!is.null(rv$inv_metadata) &&
                                    "region" %in% names(rv$inv_metadata) &&
                                    nzchar(rv$inv_metadata$region %||% "")) {
      rv$inv_metadata$region
    } else NULL
    comp <- ensure_completeness(rv$param_specs, region = region_for_completeness)
    if (!isTRUE(comp$valid)) {
      showNotification(paste0("Cannot run simulation. ", comp$message),
                       type = "error", duration = 12)
      rv$sim_log <- paste0(rv$sim_log,
                           "Completeness check failed: ", comp$message, "\n")
      return()
    }
    if (length(comp$auto_filled) > 0) {
      rv$param_specs <- comp$param_specs
      showNotification(comp$message, type = "warning", duration = 6)
      rv$sim_log <- paste0(rv$sim_log,
                           "Auto-fill: ", comp$message, "\n")
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

            # Round 7 R1.13: also extract per-MMS Frac_GasMS / Frac_LeachMS
            # from the manure sheet if the columns are present. NA -> fall back
            # to mms_frac_defaults_2019() inside calc_indirect_n2o_mm().
            frac_gas_vals   <- NULL
            frac_leach_vals <- NULL

            if (!is.null(manure) && nrow(manure) > 0 &&
                all(c("mms_type", "fraction_pct", "MCF_pct", "EF3") %in% names(manure))) {
              manure_key <- make_group_key(manure)
              mms_rows   <- manure[manure_key == sg, ]
              if (nrow(mms_rows) > 0) {
                # Defensive coercion in case Excel stored these as text
                fp_num   <- suppressWarnings(as.numeric(mms_rows$fraction_pct))
                mcf_num  <- suppressWarnings(as.numeric(mms_rows$MCF_pct))
                ef3_num  <- suppressWarnings(as.numeric(mms_rows$EF3))
                mms_fracs <- setNames(fp_num / 100,  mms_rows$mms_type)
                mcf_vals  <- setNames(mcf_num / 100, mms_rows$mms_type)
                ef3_vals  <- setNames(ef3_num,       mms_rows$mms_type)
                # Drop any rows that didn't coerce (NA fraction → useless)
                mms_fracs <- mms_fracs[!is.na(mms_fracs)]
                mcf_vals  <- mcf_vals[names(mms_fracs)]
                ef3_vals  <- ef3_vals[names(mms_fracs)]
                # Replace any leftover NAs in MCF/EF3 with defaults rather than
                # crashing the simulation
                mcf_vals[is.na(mcf_vals)] <- 0.015
                ef3_vals[is.na(ef3_vals)] <- 0.005

                # Round 7 R1.13: per-MMS Frac_GasMS / Frac_LeachMS columns.
                if ("Frac_GasMS_pct" %in% names(mms_rows)) {
                  fg_num <- suppressWarnings(as.numeric(mms_rows$Frac_GasMS_pct)) / 100
                  frac_gas_vals <- setNames(fg_num, mms_rows$mms_type)
                  frac_gas_vals <- frac_gas_vals[names(mms_fracs)]
                }
                if ("Frac_LeachMS_pct" %in% names(mms_rows)) {
                  fl_num <- suppressWarnings(as.numeric(mms_rows$Frac_LeachMS_pct)) / 100
                  frac_leach_vals <- setNames(fl_num, mms_rows$mms_type)
                  frac_leach_vals <- frac_leach_vals[names(mms_fracs)]
                }
                # Final guard: if all MMS rows were unparsable, use defaults
                if (length(mms_fracs) == 0) {
                  mms_fracs <- default_mms_fracs
                  mcf_vals  <- default_mcf_vals
                  ef3_vals  <- default_ef3_vals
                }
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

            # R1.1 / Round 7 T4.3: build a UNIFIED correlation matrix over both
            # AD and coefficient parameters. The preset matrix and the time-series
            # matrix can both span both blocks (post-Round-7), so we expand the
            # user's matrix to the full (AD + coefficient) parameter list. This
            # supersedes the prior two-pass `corr_matrix` / `ef_corr_matrix` split,
            # though both inputs are still passed downstream for back-compat.
            ad_names   <- sys_specs$parameter[sys_specs$param_type == "activity_data"]
            coef_names <- sys_specs$parameter[sys_specs$param_type == "coefficient"]
            all_names  <- c(ad_names, coef_names)

            unified_corr <- if (input$corr_mode != "none" && !is.null(rv$corr_matrix)) {
              expand_corr_matrix(rv$corr_matrix, all_names)
            } else NULL

            ts_coef_corr <- if (input$corr_mode != "none" && !is.null(rv$corr_matrix)) {
              expand_corr_matrix(rv$corr_matrix, coef_names)
            } else NULL

            # AD block has only cattle_pop — within-block correlation is meaningless.
            corr <- NULL

            # If time-series matrix is available, prefer it over uniform-rho.
            ef_corr <- if (!is.null(ts_coef_corr)) {
              ts_coef_corr
            } else if (!is.null(rv$ef_corr_matrix)) {
              ef_n <- sum(sys_specs$param_type == "coefficient")
              if (nrow(rv$ef_corr_matrix) == ef_n) rv$ef_corr_matrix else NULL
            } else NULL

            # Round 7 T4.21: build per-iteration MMS allocation matrix from a
            # Dirichlet on the simplex with concentration controlled by the
            # mms_concentration input. concentration <= 0 disables sampling
            # and falls back to deterministic shares.
            mms_matrix <- NULL
            mc_n_iter <- if (!is.null(input$n_iter)) input$n_iter else 10000
            conc <- if (!is.null(input$mms_concentration)) input$mms_concentration else 0
            if (length(mms_fracs) >= 2 && !is.na(conc) && conc > 0) {
              mms_matrix <- sample_dirichlet_simplex(
                p = as.numeric(mms_fracs),
                n_iter = mc_n_iter,
                names_vec = names(mms_fracs),
                concentration = conc
              )
            }

            systems_data[[sg]] <- list(
              param_specs = sys_specs, corr_matrix = corr, ef_corr_matrix = ef_corr,
              unified_corr_matrix = unified_corr,
              mms_fractions = mms_fracs, mcf_values = mcf_vals, ef3_values = ef3_vals,
              frac_gas_values = frac_gas_vals, frac_leach_values = frac_leach_vals,
              mms_fractions_matrix = mms_matrix
            )
          }

          # ---- Stage 2: Monte Carlo sampling ----
          n_sys <- length(sys_groups)
          setProgress(0.08,
            detail = sprintf("Sampling %s iterations across %d system(s)...",
                             n_iter_fmt, n_sys))

          sim_result <- run_inventory_simulation(
            systems_data, n_iter = input$n_iter,
            gwp = input$gwp_version, seed = input$seed,
            # E1, E3: read from UI inputs (default 20°C Tw, 1.0 = no Cp pro-rate)
            Tw = if (!is.null(input$tw)) input$tw else 20,
            pct_calving = if (!is.null(input$pct_calving)) input$pct_calving else 1
          )

          # T1.12: zero out per-source contributions the user has unchecked.
          # The per-source columns are kept (for sensitivity / per-system tables);
          # only the headline totals (total_ch4, total_n2o, total_co2e) are
          # recomputed to reflect the selection.
          srcs <- input$emission_sources %||% character()
          gwp_vals <- GWP_VALUES[[input$gwp_version]]
          .apply_source_selection <- function(df) {
            ch4 <- (if ("enteric_ch4" %in% srcs) df$enteric_ch4_total else 0) +
                   (if ("manure_ch4"  %in% srcs) df$manure_ch4_total  else 0)
            n2o <- (if ("manure_n2o_direct"   %in% srcs) df$direct_n2o_mm_total   else 0) +
                   (if ("manure_n2o_indirect" %in% srcs) df$indirect_n2o_mm_total else 0) +
                   (if ("pasture_n2o" %in% srcs) df$direct_n2o_prp_total   + df$indirect_n2o_prp_total else 0)
            df$total_ch4  <- ch4
            df$total_n2o  <- n2o
            df$co2e_ch4   <- ch4 * gwp_vals$CH4
            df$co2e_n2o   <- n2o * gwp_vals$N2O
            df$total_co2e <- df$co2e_ch4 + df$co2e_n2o
            df
          }
          if (length(srcs) > 0 && length(srcs) < 5) {
            sim_result$inventory <- .apply_source_selection(sim_result$inventory)
            for (sn in names(sim_result$by_system)) {
              sim_result$by_system[[sn]]$results <- .apply_source_selection(
                sim_result$by_system[[sn]]$results)
            }
            rv$sim_log <- paste0(rv$sim_log, "Source selection: ",
                                 paste(srcs, collapse = ", "), "\n")
          }
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

          # Round 6a #6: flip directly to the results panel on every successful
          # run (not just the first one) and surface a short toast that doesn't
          # mention scrolling — the page already swaps to the results view.
          rv$sim_view <- "results"
          showNotification("Simulation complete — results displayed.",
                           type = "message", duration = 4)

        }, error = function(e) {
          rv$sim_log   <- paste0(rv$sim_log, "ERROR: ", e$message, "\n")
          rv$sim_error <- e$message
          rv$sim_running <- FALSE
        })
      }
    )
  })

  output$sim_log <- renderText(rv$sim_log)

  # B2: drives the inline results section visibility on the merged Tab 5
  output$sim_complete <- reactive({
    !is.null(rv$mc_results) && !is.null(rv$uncertainty)
  })
  outputOptions(output, "sim_complete", suspendWhenHidden = FALSE)

  # R1.5 / Round 6a #6: switch to results view when the simulation completes.
  # The flip is forced directly in the run handler, so this observer is now
  # only a fallback for the first-run case.
  observe({
    if (!is.null(rv$mc_results) && !is.null(rv$uncertainty)) {
      isolate({
        rv$sim_view <- "results"
      })
    }
  })

  # Back button: return to settings
  observeEvent(input$show_settings_btn, {
    rv$sim_view <- "settings"
  })

  output$sim_view <- reactive(rv$sim_view)
  outputOptions(output, "sim_view", suspendWhenHidden = FALSE)

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

  # T6.2: per-reporting-category breakdown (system x source) using GWP-aligned t CO2eq
  output$results_by_category <- DT::renderDT({
    req(rv$mc_results)
    gwp_vals <- GWP_VALUES[[input$gwp_version]]
    g_ch4 <- gwp_vals$CH4
    g_n2o <- gwp_vals$N2O

    # source_label, ch4 column, n2o column (column-name lookup so we get t CO2eq)
    sources <- list(
      list(label = "Enteric fermentation CH4",       ch4 = "enteric_ch4_total",   n2o = NULL),
      list(label = "Manure management CH4",          ch4 = "manure_ch4_total",    n2o = NULL),
      list(label = "Manure management N2O direct",   ch4 = NULL,                  n2o = "direct_n2o_mm_total"),
      list(label = "Manure management N2O indirect", ch4 = NULL,                  n2o = "indirect_n2o_mm_total"),
      list(label = "Pasture deposition N2O direct",  ch4 = NULL,                  n2o = "direct_n2o_prp_total"),
      list(label = "Pasture deposition N2O indirect",ch4 = NULL,                  n2o = "indirect_n2o_prp_total")
    )

    rows <- list()
    for (sn in names(rv$mc_results$by_system)) {
      res <- rv$mc_results$by_system[[sn]]$results
      for (s in sources) {
        co2e <- if (!is.null(s$ch4)) res[[s$ch4]] * g_ch4 else res[[s$n2o]] * g_n2o
        if (is.null(co2e) || all(co2e == 0)) next
        m  <- mean(co2e)
        lo <- quantile(co2e, 0.025, names = FALSE)
        hi <- quantile(co2e, 0.975, names = FALSE)
        rows[[length(rows) + 1]] <- data.frame(
          System = sn,
          Source = s$label,
          Mean_t_CO2eq = round(m, 2),
          MoE_95_pct   = if (m > 0) round(((hi - lo) / 2) / m * 100, 1) else NA_real_,
          CV_pct       = if (m > 0) round(sd(co2e) / m * 100, 1) else NA_real_,
          CI_Lower_t   = round(lo, 2),
          CI_Upper_t   = round(hi, 2)
        )
      }
    }
    if (length(rows) == 0) return(DT::datatable(data.frame()))
    DT::datatable(do.call(rbind, rows), rownames = FALSE,
                  options = list(pageLength = 30, scrollX = TRUE))
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

  # Helper: pick the right sensitivity dataset.
  # T7.2: now also recomputes per-source sensitivity on demand (against the
  # selected output column) using the cached samples.
  active_sensitivity <- reactive({
    view <- if (!is.null(input$sens_view)) input$sens_view else "with"
    src  <- if (!is.null(input$sens_source)) input$sens_source else "total_co2e"

    base <- if (view == "without" && !is.null(rv$comparison_result)) {
      rv$comparison_result
    } else {
      rv$mc_results
    }
    if (is.null(base) || length(base$by_system) == 0) return(NULL)
    first_sys <- base$by_system[[1]]

    if (src == "total_co2e") {
      if (view == "without" && !is.null(rv$comparison_sensitivity))
        return(rv$comparison_sensitivity)
      return(rv$sensitivity)
    }
    if (!src %in% names(first_sys$results)) return(rv$sensitivity)
    sensitivity_analysis(first_sys$samples,
                         first_sys$results[[src]],
                         method = "both")
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

  # T1.4 + R1.7: parameter glossary — variable names are now IPCC-aligned, so the
  # separate ipcc_software_name column is dropped (redundant). "Our column"
  # renamed to "Variable name".
  output$definitions_table <- DT::renderDT({
    cat <- PARAM_CATALOGUE
    cat$ipcc_framing <- ifelse(cat$parameter %in% c("cattle_pop", "N"),
                               "Activity data (population)",
                               "Coefficient (combines into EF)")
    DT::datatable(
      cat[, c("parameter", "definition", "unit",
              "ipcc_default", "suggested_distribution",
              "param_tier", "ipcc_framing", "ipcc_ref")],
      rownames = FALSE,
      colnames = c("Variable name" = "parameter",
                   "Definition" = "definition",
                   "Unit" = "unit",
                   "IPCC default" = "ipcc_default",
                   "Suggested distribution" = "suggested_distribution",
                   "Tier" = "param_tier",
                   "IPCC framing" = "ipcc_framing",
                   "IPCC reference" = "ipcc_ref"),
      options = list(pageLength = 25, scrollX = TRUE),
      class = "compact stripe"
    )
  })

  # T8.4 / Round 6a #8: per-source histograms embedded in IPCC Report.
  # Bug fix: previous version referenced `inv$enteric_ch4_total` etc., but the
  # top-level inventory data.frame only carries cross-system aggregates
  # (`total_enteric_ch4`, `total_manure_ch4`, `total_direct_n2o`,
  # `total_indirect_n2o`). Indirect N2O is the sum of MM-indirect and PRP-
  # indirect across systems, so we now rebuild per-source vectors by summing
  # the per-system samples directly. Sources with zero variance (because the
  # source was not ticked, or because all systems sum to zero for that source)
  # are skipped with a placeholder annotation rather than rendered as a flat
  # bar at zero.
  output$report_source_histograms <- plotly::renderPlotly({
    req(rv$mc_results)
    by_sys <- rv$mc_results$by_system
    if (length(by_sys) == 0)
      return(plotly::plot_ly() |>
               plotly::layout(title = "No simulation data available."))

    .sum_across <- function(field) {
      vals <- lapply(by_sys, function(s) s$results[[field]])
      vals <- Filter(function(v) !is.null(v) && length(v) > 0, vals)
      if (length(vals) == 0) return(NULL)
      Reduce(`+`, vals)
    }
    enteric_ch4 <- .sum_across("enteric_ch4_total")
    manure_ch4  <- .sum_across("manure_ch4_total")
    mm_n2o_dir  <- .sum_across("direct_n2o_mm_total")
    mm_n2o_ind  <- .sum_across("indirect_n2o_mm_total")
    prp_dir     <- .sum_across("direct_n2o_prp_total")
    prp_ind     <- .sum_across("indirect_n2o_prp_total")
    pasture_n2o <- if (!is.null(prp_dir) && !is.null(prp_ind)) prp_dir + prp_ind
                   else if (!is.null(prp_dir)) prp_dir
                   else prp_ind

    sources <- list(
      "Enteric CH4 (t)"         = enteric_ch4,
      "Manure CH4 (t)"          = manure_ch4,
      "Manure N2O direct (t)"   = mm_n2o_dir,
      "Manure N2O indirect (t)" = mm_n2o_ind,
      "Pasture N2O (t)"         = pasture_n2o
    )

    has_variance <- function(v) !is.null(v) && length(v) > 1 &&
      sd(v, na.rm = TRUE) > .Machine$double.eps
    keep <- vapply(sources, has_variance, logical(1))
    if (!any(keep)) {
      return(plotly::plot_ly() |>
               plotly::layout(
                 title = "No source has variance to display.",
                 annotations = list(list(
                   text = paste("None of the ticked emission sources produced",
                                "variable output. Ensure at least one source",
                                "is selected on Tab 5 and that the relevant",
                                "parameters have non-zero uncertainty."),
                   showarrow = FALSE, x = 0.5, y = 0.5,
                   xref = "paper", yref = "paper"))))
    }
    sources <- sources[keep]

    plots <- lapply(seq_along(sources), function(i) {
      plotly::plot_ly(x = sources[[i]], type = "histogram", nbinsx = 40,
                      marker = list(color = "#2D6A4F"),
                      name = names(sources)[i], showlegend = FALSE) |>
        plotly::layout(xaxis = list(title = names(sources)[i]),
                       yaxis = list(title = ""))
    })
    plotly::subplot(plots,
                    nrows  = max(1, ceiling(length(plots) / 3)),
                    margin = 0.06,
                    titleX = TRUE, titleY = FALSE)
  })

  # T8.4 / Round 6a #8: tornado chart embedded in IPCC Report (vs total_co2e).
  # Bug fix: when sensitivity_analysis() returns an empty list (no input
  # parameters had variance), or when SRC's lm() coefficients column is named
  # `Estimate` rather than `src`, the previous code crashed on
  # `top10[[val_col]]`. We now defend against an empty sensitivity object,
  # missing column, or zero rows with friendly placeholder annotations.
  output$report_tornado <- plotly::renderPlotly({
    placeholder <- function(msg) {
      plotly::plot_ly() |>
        plotly::layout(
          xaxis = list(visible = FALSE),
          yaxis = list(visible = FALSE),
          annotations = list(list(
            text = msg, showarrow = FALSE,
            x = 0.5, y = 0.5, xref = "paper", yref = "paper",
            font = list(size = 14, color = "#555"))))
    }
    if (is.null(rv$sensitivity) || length(rv$sensitivity) == 0)
      return(placeholder("Sensitivity analysis not yet run. Run a simulation on Tab 5 first."))

    # Hotfix: custom %||% is unsafe on data.frames (it does is.na(a[1])
    # which on a frame returns a vector, breaking the `||` chain). Use
    # explicit checks instead so the tornado renderer doesn't throw.
    sens <- if (!is.null(rv$sensitivity$src) &&
                is.data.frame(rv$sensitivity$src) && nrow(rv$sensitivity$src) > 0) {
      rv$sensitivity$src
    } else if (!is.null(rv$sensitivity$prcc) &&
               is.data.frame(rv$sensitivity$prcc) && nrow(rv$sensitivity$prcc) > 0) {
      rv$sensitivity$prcc
    } else NULL
    if (is.null(sens) || nrow(sens) == 0)
      return(placeholder("No input parameters had variance — tornado chart cannot be built."))

    val_col <- if ("src" %in% names(sens)) "src"
               else if ("prcc" %in% names(sens)) "prcc"
               else NULL
    if (is.null(val_col) || !"parameter" %in% names(sens))
      return(placeholder("Sensitivity result is missing the expected columns."))

    top10 <- utils::head(sens, 10)
    top10 <- top10[order(top10[[val_col]]), , drop = FALSE]
    plotly::plot_ly(y = factor(top10$parameter, levels = top10$parameter),
                    x = top10[[val_col]], type = "bar", orientation = "h",
                    marker = list(color = ifelse(top10[[val_col]] > 0,
                                                 "#2D6A4F", "#C1121F"))) |>
      plotly::layout(title = paste0("Top 10 — ", toupper(val_col)),
                     xaxis = list(title = val_col),
                     yaxis = list(title = ""))
  })

  # Tx.1: input distribution density plots for QA review
  output$report_input_densities <- plotly::renderPlotly({
    req(rv$mc_results)
    if (length(rv$mc_results$by_system) == 0) return(plotly::plot_ly())
    samples <- rv$mc_results$by_system[[1]]$samples
    if (is.null(samples) || ncol(samples) == 0) return(plotly::plot_ly())

    # Take up to 12 parameters to keep the panel readable
    keep <- head(colnames(samples), 12)
    plots <- lapply(keep, function(p) {
      x <- samples[[p]]
      plotly::plot_ly(x = x, type = "histogram", histnorm = "probability density",
                      nbinsx = 30, marker = list(color = "#40916C"),
                      name = p, showlegend = FALSE) |>
        plotly::layout(xaxis = list(title = p), yaxis = list(title = ""))
    })
    plotly::subplot(plots, nrows = 4, margin = 0.04,
                    titleX = TRUE, titleY = FALSE)
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

  # Round 6b #9: Word run-summary download
  output$download_docx <- downloadHandler(
    filename = function() paste0("uncertainty_summary_", Sys.Date(), ".docx"),
    content = function(file) {
      validate(
        need(!is.null(rv$mc_results),  "Run a Monte Carlo simulation on Tab 5 before downloading the Word summary."),
        need(!is.null(rv$uncertainty), "Uncertainty metrics not yet computed.")
      )
      settings <- list(
        n_iter            = input$n_iter,
        corr_mode         = input$corr_mode,
        ef_corr_mode      = input$ef_corr_mode,
        run_comparison    = isTRUE(input$run_comparison),
        gwp_version       = input$gwp_version,
        seed              = input$seed,
        analysis_mode     = input$analysis_mode,
        emission_sources  = input$emission_sources
      )
      build_run_summary_docx(
        path        = file,
        settings    = settings,
        param_specs = rv$param_specs,
        mc_results  = rv$mc_results,
        uncertainty = rv$uncertainty,
        sensitivity = rv$sensitivity,
        ipcc_table  = rv$ipcc_table,
        ipcc_meta   = rv$inv_metadata
      )
    }
  )

  # ====================================================================
  # F / T4.22 / TT.6: Trend tab — multi-year inventory uncertainty
  # ====================================================================
  # Round 8: rv_trend now caches per-year MC samples + delta + slope so the
  # trend tab can compute sensitivity and produce Excel/CSV/Word reports.
  rv_trend <- reactiveValues(results = NULL, samples_by_year = NULL,
                              co2e_by_year = NULL, slope = NULL,
                              delta_total = NULL, year_corr = NULL,
                              years = NULL, message = NULL)

  observeEvent(input$run_trend, {
    req(rv$param_specs)
    n_iter <- if (!is.null(input$n_iter)) input$n_iter else 10000
    n_iter_fmt <- format(n_iter, big.mark = ",")
    # Round 9 follow-up: withProgress bar mirrors the single-year handler so
    # the user gets feedback during the per-year MC loop (which can take ~1
    # minute at 10k iter × 5 years on shinyapps.io).
    withProgress(
      message = sprintf("Trend Monte Carlo (%s iter / year)", n_iter_fmt),
      value = 0,
      {
        tryCatch({
          setProgress(0.03, detail = "Preparing trend data...")
          # R2.3: prefer the Parameter_TimeSeries already parsed from the main
          # template (rv$population) so the user does not have to upload a
          # separate CSV. The CSV input remains as an explicit override for
          # users who want to bring different trend data.
          df <- if (!is.null(input$trend_upload) &&
                    !is.null(input$trend_upload$datapath) &&
                    nzchar(input$trend_upload$datapath)) {
            read.csv(input$trend_upload$datapath, stringsAsFactors = FALSE)
          } else if (!is.null(rv$population) && ncol(rv$population) >= 2) {
            trend_df_from_population(rv$population, rv$param_specs)
          } else {
            stop("No time-series data available. Either load a template that ",
                 "includes a Parameter_TimeSeries sheet (or one of the built-in ",
                 "examples), or upload a long-format CSV here.")
          }
          # Round 9: trend uses the same n_iter slider as single-year. Source
          # selection from Tab 5 also applies — trend now honours
          # input$emission_sources just like the single-year flow.
          yc <- if (!is.null(input$year_corr) && nzchar(input$year_corr)) input$year_corr else "full"
          gv <- if (!is.null(input$gwp_version) && nzchar(input$gwp_version)) input$gwp_version else "AR5"
          sd_ <- if (!is.null(input$seed)) input$seed else 42

          # Per-year progress callback: fan out the [0.05, 0.95] band across
          # the years so the bar advances as each per-year sim completes.
          prog_fn <- function(yi, n_years, year_label) {
            frac <- 0.05 + 0.90 * (yi / max(n_years, 1L))
            setProgress(frac, detail = sprintf("Year %s (%d / %d)",
                                                year_label, yi, n_years))
          }
          setProgress(0.05, detail = "Starting per-year simulations...")

          res <- run_trend_analysis(df, base_specs = rv$param_specs, n_iter = n_iter,
                                     gwp = gv, seed = sd_, year_corr = yc,
                                     emission_sources = input$emission_sources,
                                     progress_fn = prog_fn)

          setProgress(0.97, detail = "Computing slope and Δ...")
          # Round 8: res is now a list, not a data frame
          rv_trend$results         <- res$table
          rv_trend$samples_by_year <- res$samples_by_year
          rv_trend$co2e_by_year    <- res$co2e_by_year
          rv_trend$slope           <- res$slope
          rv_trend$delta_total     <- res$delta_total
          rv_trend$year_corr       <- res$year_corr
          rv_trend$years           <- res$years
          rv_trend$message <- list(type = "success",
            text = sprintf("Trend computed for %d years (%d–%d). Δ vs base: %.1f%% [95%% CI %.1f%%, %.1f%%]; slope: %.0f t CO₂eq/yr.",
                           nrow(res$table), min(res$table$Year), max(res$table$Year),
                           res$delta_total$pct_mean,
                           res$delta_total$pct_ci[1], res$delta_total$pct_ci[2],
                           res$slope$mean))
          # Round 9: flip Tab 5 to results-view so trend chart/table/sensitivity
          # show in place (mirrors the single-year Run handler's sim_view flip).
          rv$sim_view <- "results"
          setProgress(1.00, detail = "Done.")
          showNotification(rv_trend$message$text, type = "message", duration = 7)
        }, error = function(e) {
          rv_trend$message <- list(type = "error",
            text = paste("Trend run failed:", e$message))
          showNotification(rv_trend$message$text, type = "error", duration = 10)
        })
      }
    )
  })

  output$trend_status <- renderUI({
    if (is.null(rv_trend$message)) {
      # R2.3: report whether the trend run will use template TS or a CSV override
      if (!is.null(rv$population) && ncol(rv$population) >= 2) {
        n_yrs <- length(unique(rv$population$year))
        n_par <- ncol(rv$population) - 1
        div(style = "font-size:0.85rem; color:#1B4332; background:#D8F3DC; padding:8px 10px; border-radius:6px;",
            icon("check-circle"),
            sprintf(" Using time-series from loaded template — %d years × %d parameters. ",
                    n_yrs, n_par),
            "Click Run to compute the trend, or upload a CSV above to override.")
      } else {
        div(style = "font-size:0.85rem; color:#555;",
            icon("info-circle"),
            " No time-series in the loaded template. Upload a long-format CSV and click Run, ",
            "or load Country X / Country Y from Tab 1 to use the example time-series.")
      }
    } else {
      bg <- if (rv_trend$message$type == "success") "#D8F3DC" else "#FECACA"
      fg <- if (rv_trend$message$type == "success") "#1B4332" else "#7F1D1D"
      div(style = sprintf("font-size:0.85rem; background:%s; color:%s; padding:8px 10px; border-radius:6px;",
                          bg, fg),
          rv_trend$message$text)
    }
  })

  output$trend_table <- DT::renderDT({
    req(rv_trend$results)
    DT::datatable(rv_trend$results, rownames = FALSE,
                  options = list(pageLength = 25, dom = "t"))
  })

  output$trend_plot <- plotly::renderPlotly({
    req(rv_trend$results)
    df <- rv_trend$results
    sub <- if (!is.null(rv_trend$slope) && !is.null(rv_trend$delta_total)) {
      sprintf("Δ vs base: %.1f%% (95%% CI %.1f%%, %.1f%%)  •  Slope: %.0f t CO₂eq/yr (95%% CI %.0f, %.0f)",
              rv_trend$delta_total$pct_mean,
              rv_trend$delta_total$pct_ci[1], rv_trend$delta_total$pct_ci[2],
              rv_trend$slope$mean,
              rv_trend$slope$ci[1], rv_trend$slope$ci[2])
    } else NULL
    plotly::plot_ly() |>
      plotly::add_ribbons(x = df$Year, ymin = df$CI_Lower_t, ymax = df$CI_Upper_t,
                          name = "95% CI", line = list(color = "transparent"),
                          fillcolor = "rgba(45,106,79,0.25)") |>
      plotly::add_trace(x = df$Year, y = df$Mean_t_CO2eq,
                        type = "scatter", mode = "lines+markers",
                        name = "Mean", line = list(color = "#1B4332", width = 3),
                        marker = list(size = 8, color = "#1B4332")) |>
      plotly::layout(
        title = list(text = paste0("Trend in total CO₂eq emissions (95% CI)",
                                    if (!is.null(sub)) paste0("<br><sub>", sub, "</sub>") else "")),
        xaxis = list(title = "Inventory year"),
        yaxis = list(title = "Total CO₂eq (tonnes)"),
        hovermode = "x unified"
      )
  })

  # Round 8 — Trend sensitivity (per-year + delta)

  trend_sens_per_year <- reactive({
    req(rv_trend$samples_by_year, rv_trend$co2e_by_year)
    yrs <- names(rv_trend$samples_by_year)
    last <- yrs[length(yrs)]
    sensitivity_analysis(
      rv_trend$samples_by_year[[last]],
      rv_trend$co2e_by_year[[last]],
      method = "both"
    )
  })

  trend_sens_delta <- reactive({
    req(rv_trend$samples_by_year, rv_trend$delta_total)
    yrs <- names(rv_trend$samples_by_year)
    if (length(yrs) < 2) return(NULL)
    s_y1 <- as.data.frame(rv_trend$samples_by_year[[1]])
    s_yN <- as.data.frame(rv_trend$samples_by_year[[length(yrs)]])
    names(s_y1) <- paste0(names(s_y1), "_y1")
    names(s_yN) <- paste0(names(s_yN), "_yN")
    combined <- cbind(s_y1, s_yN)
    sensitivity_analysis(
      combined, rv_trend$delta_total$per_iter, method = "both"
    )
  })

  # Round 9 follow-up: trend tornado now matches the single-year tornado
  # (output$tornado_chart) — coloured by user_reducible × sign, with a hover
  # text and a bottom-right legend annotation explaining the colour scheme.
  # The bare-parameter strip in the trend-driver case (e.g. "W_y1" / "W_yN")
  # is split on the suffix so reducibility lookup hits PARAM_CATALOGUE.
  .trend_tornado_plot <- function(sens, title_text) {
    placeholder <- function(msg) {
      plotly::plot_ly() |>
        plotly::layout(
          xaxis = list(visible = FALSE),
          yaxis = list(visible = FALSE),
          annotations = list(list(
            text = msg, showarrow = FALSE, x = 0.5, y = 0.5,
            xref = "paper", yref = "paper",
            font = list(size = 13, color = "#555"))))
    }
    if (is.null(sens) || length(sens) == 0)
      return(placeholder("Run a trend simulation first."))
    base <- if (!is.null(sens$src) && is.data.frame(sens$src) && nrow(sens$src) > 0) {
      sens$src
    } else if (!is.null(sens$prcc) && is.data.frame(sens$prcc) && nrow(sens$prcc) > 0) {
      sens$prcc
    } else NULL
    if (is.null(base) || nrow(base) == 0)
      return(placeholder("No input parameters had variance."))
    val_col <- if ("src" %in% names(base)) "src"
               else if ("prcc" %in% names(base)) "prcc"
               else NULL
    if (is.null(val_col) || !"parameter" %in% names(base))
      return(placeholder("Sensitivity result missing expected columns."))
    top10 <- utils::head(base[order(-abs(base[[val_col]])), , drop = FALSE], 10)
    top10 <- top10[order(top10[[val_col]]), , drop = FALSE]

    # Map parameter -> user_reducible. For trend-driver names like "W_y1" or
    # "Cfi_yN" strip the year suffix before the catalogue lookup.
    bare_name <- gsub("_(y1|yN)$", "", top10$parameter)
    reducible_lut <- setNames(PARAM_CATALOGUE$user_reducible,
                                PARAM_CATALOGUE$parameter)
    top10$reducible <- reducible_lut[bare_name]
    top10$reducible[is.na(top10$reducible)] <- TRUE

    bar_colours <- ifelse(top10[[val_col]] > 0,
      ifelse(top10$reducible, "#2D6A4F", "#78909C"),
      ifelse(top10$reducible, "#C1121F", "#90A4AE")
    )
    hover_txt <- ifelse(top10$reducible, "User-reducible", "IPCC coefficient")

    plotly::plot_ly(y = factor(top10$parameter, levels = top10$parameter),
                    x = top10[[val_col]], type = "bar", orientation = "h",
                    marker = list(color = bar_colours),
                    text = hover_txt, hoverinfo = "x+y+text") |>
      plotly::layout(
        title = list(text = title_text, font = list(size = 12)),
        xaxis = list(title = toupper(val_col)),
        yaxis = list(title = ""),
        margin = list(l = 130, b = 40),
        annotations = list(list(
          x = 0.99, y = -0.18, xref = "paper", yref = "paper",
          showarrow = FALSE, align = "right",
          text = "<span style='color:#2D6A4F'>■</span> User-reducible &nbsp; <span style='color:#78909C'>■</span> IPCC coefficient",
          font = list(size = 10)
        ))
      )
  }

  # Round 9 follow-up: trend rankings table (per-year + Δ). Mirrors the
  # single-year output$sensitivity_table but shows both SRC and PRCC columns
  # (and the user_reducible flag as a coloured Class column) so the user
  # doesn't have to flip a method toggle. Used by Tab 6 (Sensitivity) under
  # the trend mode conditional.
  .trend_sens_table <- function(sens) {
    if (is.null(sens) || length(sens) == 0) {
      return(DT::datatable(data.frame(Note = "Run a trend simulation first."),
                            rownames = FALSE, options = list(dom = "t")))
    }
    src  <- sens$src
    prcc <- sens$prcc
    base <- if (!is.null(src) && nrow(src) > 0) src
            else if (!is.null(prcc) && nrow(prcc) > 0) prcc
            else NULL
    if (is.null(base) || nrow(base) == 0) {
      return(DT::datatable(
        data.frame(Note = "No input parameters had variance."),
        rownames = FALSE, options = list(dom = "t")))
    }
    val_col <- if ("src" %in% names(base)) "src"
               else if ("prcc" %in% names(base)) "prcc"
               else names(base)[2]
    base <- base[order(-abs(base[[val_col]])), , drop = FALSE]
    base <- utils::head(base, 15)

    bare_name <- gsub("_(y1|yN)$", "", base$parameter)
    reducible_lut <- setNames(PARAM_CATALOGUE$user_reducible,
                                PARAM_CATALOGUE$parameter)
    reducible <- reducible_lut[bare_name]
    reducible[is.na(reducible)] <- TRUE

    src_disp  <- if ("src" %in% names(base))
                   formatC(base$src,  digits = 3, format = "f") else NA_character_
    prcc_disp <- if (!is.null(prcc) && "prcc" %in% names(prcc))
                   formatC(prcc$prcc[match(base$parameter, prcc$parameter)],
                           digits = 3, format = "f") else NA_character_

    df <- data.frame(
      Parameter = base$parameter,
      Class     = ifelse(reducible, "User-reducible", "IPCC coefficient"),
      SRC       = src_disp,
      PRCC      = prcc_disp,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    if (all(is.na(df$PRCC))) df$PRCC <- NULL
    if (all(is.na(df$SRC)))  df$SRC  <- NULL

    dt <- DT::datatable(df, rownames = FALSE,
                         options = list(pageLength = 15, dom = "t"))
    DT::formatStyle(dt, "Class",
      backgroundColor = DT::styleEqual(
        c("User-reducible", "IPCC coefficient"),
        c("#D8F3DC", "#ECEFF1")),
      color = DT::styleEqual(
        c("User-reducible", "IPCC coefficient"),
        c("#1B4332", "#37474F")),
      fontWeight = "600")
  }

  output$trend_tornado_per_year <- plotly::renderPlotly({
    .trend_tornado_plot(trend_sens_per_year(),
                         "Top 10 drivers — latest year")
  })

  output$trend_tornado_delta <- plotly::renderPlotly({
    .trend_tornado_plot(trend_sens_delta(),
                         "Top 10 drivers — Δ Y_N − Y_1")
  })

  # Round 9: mirror outputs for the IPCC Report tab. Shiny requires unique
  # output IDs per UI element, so the same chart shown in two places needs two
  # render calls. Both delegate to the same reactive sources.
  output$trend_table_report <- DT::renderDT({
    req(rv_trend$results)
    DT::datatable(rv_trend$results, rownames = FALSE,
                  options = list(pageLength = 25, dom = "t"))
  })
  output$trend_plot_report <- plotly::renderPlotly({
    req(rv_trend$results)
    df <- rv_trend$results
    sub <- if (!is.null(rv_trend$slope) && !is.null(rv_trend$delta_total)) {
      sprintf("Δ vs base: %.1f%% (95%% CI %.1f%%, %.1f%%)  •  Slope: %.0f t CO₂eq/yr (95%% CI %.0f, %.0f)",
              rv_trend$delta_total$pct_mean,
              rv_trend$delta_total$pct_ci[1], rv_trend$delta_total$pct_ci[2],
              rv_trend$slope$mean,
              rv_trend$slope$ci[1], rv_trend$slope$ci[2])
    } else NULL
    plotly::plot_ly() |>
      plotly::add_ribbons(x = df$Year, ymin = df$CI_Lower_t, ymax = df$CI_Upper_t,
                          name = "95% CI", line = list(color = "transparent"),
                          fillcolor = "rgba(45,106,79,0.25)") |>
      plotly::add_trace(x = df$Year, y = df$Mean_t_CO2eq,
                        type = "scatter", mode = "lines+markers",
                        name = "Mean", line = list(color = "#1B4332", width = 3),
                        marker = list(size = 8, color = "#1B4332")) |>
      plotly::layout(
        title = list(text = paste0("Trend in total CO₂eq emissions (95% CI)",
                                    if (!is.null(sub)) paste0("<br><sub>", sub, "</sub>") else "")),
        xaxis = list(title = "Inventory year"),
        yaxis = list(title = "Total CO₂eq (tonnes)"),
        hovermode = "x unified"
      )
  })
  output$trend_tornado_per_year_report <- plotly::renderPlotly({
    .trend_tornado_plot(trend_sens_per_year(),
                         "Top 10 drivers — latest year")
  })
  output$trend_tornado_delta_report <- plotly::renderPlotly({
    .trend_tornado_plot(trend_sens_delta(),
                         "Top 10 drivers — Δ Y_N − Y_1")
  })
  # Round 9 follow-up: third copy of the trend tornadoes for Tab 6 (Sensitivity)
  # since each Shiny output ID can render in only one UI element. All three
  # copies (Tab 5 results, Tab 6, Tab 7 report) read from the same reactives.
  output$trend_tornado_per_year_sens <- plotly::renderPlotly({
    .trend_tornado_plot(trend_sens_per_year(),
                         "Top 10 drivers — latest year")
  })
  output$trend_tornado_delta_sens <- plotly::renderPlotly({
    .trend_tornado_plot(trend_sens_delta(),
                         "Top 10 drivers — Δ Y_N − Y_1")
  })
  # Round 9 follow-up: rankings tables (Top 15) for trend mode, mirroring
  # the single-year output$sensitivity_table. Both SRC and PRCC columns
  # surfaced together; Class column is colour-coded (green = user-reducible,
  # grey = IPCC coefficient) to match the tornado bar palette.
  output$trend_sens_per_year_table <- DT::renderDT({
    .trend_sens_table(trend_sens_per_year())
  })
  output$trend_sens_delta_table <- DT::renderDT({
    .trend_sens_table(trend_sens_delta())
  })

  # Round 8 — Trend downloads (Excel / CSV / Word)

  .trend_filename <- function(ext) {
    yc <- if (!is.null(rv_trend$year_corr)) rv_trend$year_corr else "trend"
    paste0("trend_", yc, "_", Sys.Date(), ".", ext)
  }

  output$download_trend_xlsx <- downloadHandler(
    filename = function() .trend_filename("xlsx"),
    content = function(file) {
      validate(need(!is.null(rv_trend$results),
                    "Run a trend simulation on Tab 7 before downloading."))
      n_iter_val <- if (!is.null(input$n_iter)) input$n_iter else 10000
      export_trend_xlsx(
        results_table        = rv_trend$results,
        slope                = rv_trend$slope,
        delta_total          = rv_trend$delta_total,
        sensitivity_per_year = trend_sens_per_year(),
        sensitivity_delta    = trend_sens_delta(),
        year_corr            = rv_trend$year_corr,
        n_iter               = n_iter_val,
        filepath             = file
      )
    }
  )

  output$download_trend_csv <- downloadHandler(
    filename = function() .trend_filename("csv"),
    content = function(file) {
      validate(need(!is.null(rv_trend$results),
                    "Run a trend simulation on Tab 7 before downloading."))
      write.csv(rv_trend$results, file, row.names = FALSE)
    }
  )

  output$download_trend_docx <- downloadHandler(
    filename = function() .trend_filename("docx"),
    content = function(file) {
      validate(need(!is.null(rv_trend$results),
                    "Run a trend simulation on Tab 7 before downloading."))
      n_iter_val <- if (!is.null(input$n_iter)) input$n_iter else 10000
      build_trend_summary_docx(
        path                 = file,
        trend_results        = rv_trend$results,
        slope                = rv_trend$slope,
        delta_total          = rv_trend$delta_total,
        sensitivity_per_year = trend_sens_per_year(),
        sensitivity_delta    = trend_sens_delta(),
        year_corr            = rv_trend$year_corr,
        years                = rv_trend$years,
        n_iter               = n_iter_val,
        ipcc_meta            = rv$inv_metadata,
        param_specs          = rv$param_specs
      )
    }
  )

  # Round 8 — Contact / Feedback. The form is rendered as raw HTML+JS in
  # R/utils_contact.R via contact_form_html(); submission happens browser-side
  # (Web3Forms free tier blocks server-side POSTs). No Shiny observer needed.
}
