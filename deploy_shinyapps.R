# Deploy to shinyapps.io
#
# One-time setup (run once per machine):
#   install.packages("rsconnect")
#   rsconnect::setAccountInfo(
#     name   = "YOUR-SHINYAPPS-USERNAME",
#     token  = "YOUR-TOKEN",       # from shinyapps.io > Account > Tokens
#     secret = "YOUR-SECRET"
#   )
#
# Deploy (run from the repo root):
rsconnect::deployApp(
  appDir  = ".",
  appName = "cattle-ghg-uncertainty",
  account = "YOUR-SHINYAPPS-USERNAME"
)
