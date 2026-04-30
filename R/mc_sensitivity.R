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

sensitivity_analysis <- function(inputs, output, method = c("src", "prcc", "both")) {
  method <- match.arg(method)
  var_cols <- sapply(inputs, function(x) sd(x) > 0)
  inputs_var <- inputs[, var_cols, drop = FALSE]
  if (ncol(inputs_var) == 0) return(list())

  result <- list()
  if (method %in% c("src", "both")) result$src <- calc_src(inputs_var, output)
  if (method %in% c("prcc", "both")) result$prcc <- calc_prcc(inputs_var, output)
  result
}
