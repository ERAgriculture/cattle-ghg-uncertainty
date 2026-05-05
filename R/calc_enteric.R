# IPCC Tier 2 Enteric Fermentation CH4 Emissions
# Source: IPCC 2006 Guidelines, Volume 4, Chapter 10

# Enteric CH4 emission factor (Eq 10.21) - kg CH4/head/year
calc_enteric_ch4 <- function(ge, Ym) {
  (ge * (Ym / 100) * 365) / 55.65
}
