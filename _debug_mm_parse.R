library(readxl)
path <- "uncertainty_template_ipcc2019_ZIM_v2.xlsx"
for (sk in 0:3) {
  cat("\n--- skip=", sk, "---\n", sep="")
  df <- tryCatch(suppressMessages(as.data.frame(
    read_excel(path, sheet = "Manure_Management", skip = sk,
               .name_repair = "unique"))),
    error = function(e) { cat("ERR:", e$message, "\n"); NULL })
  if (is.null(df)) next
  cat("dim:", dim(df), "\n")
  cat("names:", paste(head(names(df), 8), collapse = " | "), "\n")
  if (nrow(df) > 0)
    cat("first row vals:", paste(as.character(df[1, 1:6]), collapse = " | "), "\n")
}
