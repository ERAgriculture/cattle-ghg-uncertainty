# Sensitivity Analysis
# Standardized Regression Coefficients (SRC) and Partial Rank Correlation (PRCC)

calc_src <- function(inputs, output) {
  inputs_std <- as.data.frame(scale(inputs))
  output_std <- scale(output)
  df <- cbind(inputs_std, y = output_std)
  fit <- lm(y ~ ., data = df)
  coefs <- summary(fit)$coefficients
  coefs <- coefs[rownames(coefs) != "(Intercept)", , drop = FALSE]

  result <- data.frame(
    parameter = rownames(coefs),
    src = coefs[, "Estimate"],
    abs_src = abs(coefs[, "Estimate"]),
    p_value = coefs[, "Pr(>|t|)"],
    stringsAsFactors = FALSE
  )
  result <- result[order(-result$abs_src), ]
  result$rank <- seq_len(nrow(result))
  rownames(result) <- NULL
  result
}

calc_prcc <- function(inputs, output) {
  inputs_ranked <- as.data.frame(lapply(inputs, rank))
  output_ranked <- rank(output)
  n_params <- ncol(inputs_ranked)
  prcc_values <- numeric(n_params)

  for (j in seq_len(n_params)) {
    other_cols <- setdiff(seq_len(n_params), j)
    resid_j <- residuals(lm(inputs_ranked[[j]] ~ as.matrix(inputs_ranked[, other_cols])))
    resid_y <- residuals(lm(output_ranked ~ as.matrix(inputs_ranked[, other_cols])))
    prcc_values[j] <- cor(resid_j, resid_y)
  }

  result <- data.frame(
    parameter = names(inputs_ranked),
    prcc = prcc_values,
    abs_prcc = abs(prcc_values),
    stringsAsFactors = FALSE
  )
  result <- result[order(-result$abs_prcc), ]
  result$rank <- seq_len(nrow(result))
  rownames(result) <- NULL
  result
}

sensitivity_analysis <- function(inputs, output, method = c("src", "prcc", "both"),
                                  max_prcc_cols = 40L) {
  method <- match.arg(method)

  # Output-variance guard: SRC/PRCC on a constant (or near-constant) output
  # returns spurious ranks. This happens when the selected output column is
  # structurally zero — e.g. PRP direct N2O for an intensive-dairy run where
  # pct_pasture = 0 across all iterations. Return an empty list with a
  # `message` attribute so renderers can surface why the chart is empty.
  if (length(output) == 0 || !is.finite(sd(output)) || sd(output) < 1e-9) {
    out <- list()
    attr(out, "message") <- paste0(
      "This output is constant across all Monte Carlo iterations, so ",
      "sensitivity is not defined. Common cause: the selected emission ",
      "pathway is zero for this dataset (e.g. pasture-deposition emissions ",
      "when no animals are on pasture)."
    )
    return(out)
  }

  var_cols <- sapply(inputs, function(x) sd(x) > 0)
  inputs_var <- inputs[, var_cols, drop = FALSE]
  if (ncol(inputs_var) == 0) return(list())

  # PRCC is O(p) in lm() fits (one per parameter). For multi-group inventories
  # the combined parameter matrix can have 80-150 columns, making PRCC take
  # several minutes. Cap it: if p > max_prcc_cols, compute SRC only and attach
  # a note so the UI can explain the fallback.
  prcc_note <- NULL
  if (method %in% c("prcc", "both") && ncol(inputs_var) > max_prcc_cols) {
    method <- "src"
    prcc_note <- paste0(
      "PRCC was skipped: the combined parameter matrix has ",
      ncol(inputs_var), " columns (limit: ", max_prcc_cols, "). ",
      "SRC is shown instead — it requires only one regression fit regardless ",
      "of the number of parameters. To see PRCC, select a single emission ",
      "source from the 'Output' dropdown above."
    )
  }

  result <- list()
  if (method %in% c("src", "both")) result$src <- calc_src(inputs_var, output)
  if (method %in% c("prcc", "both")) result$prcc <- calc_prcc(inputs_var, output)
  if (!is.null(prcc_note)) attr(result, "prcc_note") <- prcc_note
  result
}
