# IPCC Tier 2 Livestock GHG Uncertainty Calculator
# Developed by CIAT/CGIAR Alliance | Funded by Global Methane Hub
install.packages('rsconnect')
library(rsconnect)
rsconnect::setAccountInfo(name='mlolita26', token='BBC50C4B07A986B0BFC2A8FDE98F1257', secret='F9EjzRoRWRHedz2Ah/+0bqQwbcTGZ55Ux684i+iP')
library(rsconnect)
rsconnect::deployApp('app.R')
# Source all R files
r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
for (f in sort(r_files)) source(f, local = TRUE)

# Required packages
library(shiny)
library(bslib)
library(shinyWidgets)
library(DT)
library(readxl)
library(writexl)
library(plotly)
library(ggplot2)
library(MASS)
library(mc2d)
library(Matrix)
library(future)
library(promises)

# Launch app
shinyApp(ui = app_ui(), server = app_server)
