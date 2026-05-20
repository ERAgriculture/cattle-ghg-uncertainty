options(warn = 1)
src_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
ok <- TRUE
for (f in src_files) {
  res <- tryCatch({ source(f); "ok" },
                  error = function(e) conditionMessage(e))
  if (res != "ok") {
    cat("ERROR in", f, ":", res, "\n")
    ok <- FALSE
  }
}
if (ok) cat("ALL SOURCED OK\n")
cat("PARAM_CATALOGUE rows:", nrow(PARAM_CATALOGUE), "\n")
