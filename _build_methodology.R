setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

if (!requireNamespace("rmarkdown", quietly = TRUE)) install.packages("rmarkdown")
if (!requireNamespace("tinytex",   quietly = TRUE)) install.packages("tinytex")
if (!tinytex::is_tinytex()) tinytex::install_tinytex()

rmarkdown::render(
  "methodology.Rmd",
  output_format = "pdf_document",
  output_file   = "www/methodology.pdf"
)
cat("Done — www/methodology.pdf created.\n")
