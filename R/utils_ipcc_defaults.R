# IPCC Default Values for Africa/Developing Countries
# Sources: IPCC 2006 Guidelines Vol 4 Ch 10, 2019 Refinement

IPCC_DEFAULTS <- list(
  Cfi = list(cows_lactating = 0.386, cows_dry = 0.322, heifers = 0.322,
             bulls = 0.370, oxen = 0.322, growing_males = 0.370,
             calves_male = 0.370, calves_female = 0.322),
  Ca = list(stall = 0.00, pasture = 0.17, hilly = 0.36),
  LW = list(cows = 275, heifers = 200, adult_males = 300, growing_males = 200, calves = 60),
  WG = list(cows = 0.0, heifers = 0.25, adult_males = 0.0, growing_males = 0.20, calves = 0.30),
  MW = list(cows = 300, heifers = 300, adult_males = 350, growing_males = 350, calves = 300),
  C_growth = list(female = 0.8, castrate = 1.0, bull = 1.2),
  pct_lactating = 0.60, pct_pregnant_cows = 0.60, pct_pregnant_heifers = 0.20,
  milk_yield = 4.0, milk_fat = 4.0, Ym = 6.5, DE_pct = 55.0,
  Bo = 0.10, ash = 0.08, UE = 0.04, CP_pct = 10.0,
  EF3_PRP = 0.02, Frac_GASM = 0.20, EF4 = 0.010, EF5 = 0.0075, Frac_LEACH = 0.02
)

MMS_DEFAULTS <- data.frame(
  id = c("pasture", "daily_spread", "solid_storage", "dry_lot", "deep_bedding", "liquid_slurry", "composting", "lagoon"),
  label = c("Pasture/Paddock/Range", "Daily Spread", "Solid Storage", "Dry Lot",
            "Deep Bedding (>1 month)", "Liquid/Slurry", "Composting", "Anaerobic Lagoon"),
  mcf_tropical = c(1.5, 1.0, 5.0, 5.0, 30.0, 80.0, 1.5, 80.0),
  mcf_tropical_dry = c(1.5, 1.0, 5.0, 5.0, 30.0, 80.0, 1.5, 80.0),
  mcf_temperate = c(1.0, 0.5, 4.0, 1.5, 17.0, 35.0, 1.0, 66.0),
  mcf_boreal = c(1.0, 0.1, 3.0, 1.0, 3.0, 10.0, 0.5, 66.0),
  ef3 = c(0.02, 0.0, 0.005, 0.02, 0.01, 0.005, 0.006, 0.0),
  stringsAsFactors = FALSE
)

GWP_VALUES <- list(
  AR4 = list(CH4 = 25, N2O = 298),
  AR5 = list(CH4 = 28, N2O = 265),
  AR6 = list(CH4 = 27.9, N2O = 273)
)

SUBCATS <- c("cows", "heifers", "adult_males", "growing_males", "calves")
SUBCAT_LABELS <- c(cows = "Dairy Cows", heifers = "Heifers (>1yr)",
                   adult_males = "Adult Males (bulls/oxen)",
                   growing_males = "Growing Males (1-3yr)", calves = "Calves (<1yr)")

# ==========================================================================
# CONTROLLED VOCABULARIES FOR INPUT TEMPLATE
# These are used for dropdowns, validation, and auto-fill of defaults
# ==========================================================================

# Livestock species (IPCC Ch 10 scope). Cattle is the primary focus.
SPECIES_OPTIONS <- c("cattle_dairy", "cattle_non_dairy", "buffalo")
SPECIES_LABELS <- c(
  cattle_dairy = "Cattle - Dairy",
  cattle_non_dairy = "Cattle - Non-Dairy (Beef/Other)",
  buffalo = "Buffalo"
)

# Production systems (informed by Uganda/Zimbabwe inventories + IPCC Table 10A.1/10A.2)
PRODUCTION_SYSTEMS <- c(
  "pastoral", "agro_pastoral", "semi_intensive_dairy", "intensive_dairy",
  "extensive_ranching", "semi_intensive_beef", "intensive_beef",
  "feedlot", "mixed_crop_livestock", "smallholder_dairy"
)
PRODUCTION_SYSTEM_LABELS <- c(
  pastoral = "Pastoral",
  agro_pastoral = "Agro-Pastoral",
  semi_intensive_dairy = "Semi-Intensive Dairy",
  intensive_dairy = "Intensive Dairy",
  extensive_ranching = "Extensive Ranching / Beef",
  semi_intensive_beef = "Semi-Intensive Beef",
  intensive_beef = "Intensive Beef",
  feedlot = "Feedlot",
  mixed_crop_livestock = "Mixed Crop-Livestock",
  smallholder_dairy = "Smallholder Dairy"
)

# System type classification (for reporting and defaults)
SYSTEM_TYPES <- c("dairy", "beef", "mixed", "draft")

# Animal sub-categories (IPCC-aligned, expanded to match real inventories)
ANIMAL_SUBCATEGORIES <- c(
  "dairy_cows", "other_cows", "bulls", "oxen",
  "heifers", "growing_males", "calves_female", "calves_male",
  "feedlot_cattle"
)
ANIMAL_SUBCATEGORY_LABELS <- c(
  dairy_cows = "Dairy Cows (mature lactating females)",
  other_cows = "Other Cows (mature non-dairy females, inc. dry)",
  bulls = "Bulls (mature intact males, breeding)",
  oxen = "Oxen (mature castrated males, draft)",
  heifers = "Heifers (young females 1-3yr, not yet calved)",
  growing_males = "Growing Males (young males 1-3yr, steers/bulls)",
  calves_female = "Calves - Female (<1yr)",
  calves_male = "Calves - Male (<1yr)",
  feedlot_cattle = "Feedlot Cattle (concentrated feeding)"
)

# Sex categories
SEX_OPTIONS <- c("female", "male", "mixed")

# Age class categories (harmonised with Uganda/Zimbabwe templates)
AGE_CLASSES <- c("adult_>3yr", "young_1-3yr", "calf_<1yr", "mixed")
AGE_CLASS_LABELS <- c(
  "adult_>3yr" = "Adult (>3 years)",
  "young_1-3yr" = "Young (1-3 years)",
  "calf_<1yr" = "Calf (<1 year)",
  "mixed" = "Mixed ages"
)

# Feeding situation (IPCC Table 10.5 -> determines Ca coefficient)
FEEDING_SITUATIONS <- c("stall_fed", "pasture_flat", "pasture_hilly")
FEEDING_SITUATION_LABELS <- c(
  stall_fed = "Stall-fed / confined (Ca = 0.00)",
  pasture_flat = "Pasture - flat terrain (Ca = 0.17)",
  pasture_hilly = "Pasture - hilly terrain (Ca = 0.36)"
)
FEEDING_SITUATION_CA <- list(stall_fed = 0.00, pasture_flat = 0.17, pasture_hilly = 0.36)

# Climate zones (IPCC Table 10.17 -> determines MCF)
CLIMATE_ZONES <- c("tropical_moist", "tropical_dry", "temperate", "boreal")
CLIMATE_ZONE_LABELS <- c(
  tropical_moist = "Tropical - warm, moist / wet",
  tropical_dry = "Tropical - warm, dry",
  temperate = "Temperate",
  boreal = "Boreal / Cold"
)

# Data quality indicators (for documentation)
DATA_QUALITY <- c("measured", "country_specific", "regional_default", "ipcc_default", "expert_judgement")
DATA_QUALITY_LABELS <- c(
  measured = "Measured (local study/survey)",
  country_specific = "Country-specific estimate",
  regional_default = "Regional default (continent/biome)",
  ipcc_default = "IPCC default (Tier 1/2 table)",
  expert_judgement = "Expert judgement"
)

# IPCC Guidelines version
IPCC_VERSIONS <- c("2006", "2019_refinement")

# Distribution types supported (mirrors utils_distributions.R)
DISTRIBUTION_TYPES <- c("normal", "posnorm", "lognormal", "beta", "triangular",
                        "pert", "uniform", "constant", "tnorm_0_1")
DISTRIBUTION_LABELS <- c(
  normal = "Normal (symmetric bell curve)",
  posnorm = "Positive Normal (normal, truncated at 0)",
  lognormal = "Log-normal (strictly positive, right-skewed)",
  beta = "Beta (bounded, flexible shape)",
  triangular = "Triangular (min / mode / max, linear)",
  pert = "PERT (modified Beta, peak at mode)",
  uniform = "Uniform (all values in range equally likely)",
  constant = "Constant (no variation)",
  tnorm_0_1 = "Truncated Normal to [0,1]"
)

PARAM_TYPES <- c("activity_data", "emission_factor")

# ==========================================================================
# EXPANDED DEFAULT LOOKUPS BY NEW SUB-CATEGORY
# ==========================================================================

# Cfi by new subcategory (IPCC Table 10.4, Africa/developing defaults)
CFI_BY_SUBCAT <- list(
  dairy_cows = 0.386,     # lactating dairy cows
  other_cows = 0.322,     # dry/non-dairy cows
  bulls = 0.370,          # intact mature males
  oxen = 0.322,           # castrated draft males
  heifers = 0.322,        # young females
  growing_males = 0.370,  # young intact males
  calves_female = 0.322,
  calves_male = 0.370,
  feedlot_cattle = 0.370
)

# Live weight defaults by subcategory (kg, IPCC Africa defaults)
LW_BY_SUBCAT <- list(
  dairy_cows = 275, other_cows = 275, bulls = 350, oxen = 300,
  heifers = 200, growing_males = 200, calves_female = 60, calves_male = 60,
  feedlot_cattle = 250
)

# Mature weight defaults by subcategory (kg)
MW_BY_SUBCAT <- list(
  dairy_cows = 300, other_cows = 300, bulls = 400, oxen = 350,
  heifers = 300, growing_males = 350, calves_female = 300, calves_male = 350,
  feedlot_cattle = 400
)

# Weight gain defaults (kg/day)
WG_BY_SUBCAT <- list(
  dairy_cows = 0.0, other_cows = 0.0, bulls = 0.0, oxen = 0.0,
  heifers = 0.25, growing_males = 0.20, calves_female = 0.30, calves_male = 0.30,
  feedlot_cattle = 1.00
)

# C_growth by subcategory (IPCC Eq 10.6)
C_GROWTH_BY_SUBCAT <- list(
  dairy_cows = 0.8, other_cows = 0.8, bulls = 1.2, oxen = 1.0,
  heifers = 0.8, growing_males = 1.0, calves_female = 0.8, calves_male = 1.0,
  feedlot_cattle = 1.0
)

# Sex inferred from subcategory
SEX_BY_SUBCAT <- list(
  dairy_cows = "female", other_cows = "female", bulls = "male", oxen = "male",
  heifers = "female", growing_males = "male", calves_female = "female",
  calves_male = "male", feedlot_cattle = "mixed"
)

# Age class inferred from subcategory
AGE_BY_SUBCAT <- list(
  dairy_cows = "adult_>3yr", other_cows = "adult_>3yr",
  bulls = "adult_>3yr", oxen = "adult_>3yr",
  heifers = "young_1-3yr", growing_males = "young_1-3yr",
  calves_female = "calf_<1yr", calves_male = "calf_<1yr",
  feedlot_cattle = "young_1-3yr"
)

# Generate example Uganda parameter specs
generate_uganda_example <- function() {
  data.frame(
    cattle_type       = rep("dairy", 12),
    aggregation_level = rep("Eastern Uganda \u2013 pastoral", 12),
    sub_category      = rep("cows", 12),
    parameter = c("cattle_pop", "live_weight", "mature_weight", "weight_gain",
                   "milk_yield", "milk_fat", "DE_pct", "Cfi", "Ca", "Cp",
                   "Ym_pct", "Bo"),
    mean = c(500000, 275, 300, 0, 4, 4, 55, 0.386, 0.17, 0.10, 6.5, 0.10),
    uncertainty_pct = c(10, 15, 10, 0, 20, 10, 10, 5, 20, 15, 15, 20),
    distribution = c("normal", "normal", "normal", "constant", "normal", "normal",
                      "normal", "pert", "triangular", "beta", "pert", "pert"),
    lower = NA_real_, upper = NA_real_,
    param_type = c(rep("activity_data", 10), rep("emission_factor", 2)),
    stringsAsFactors = FALSE
  )
}

# Fill in lower/upper bounds from explicit overrides or uncertainty_pct
# Priority: lower_bound/upper_bound columns (if present and non-NA) > ±pct formula
fill_bounds <- function(param_specs) {
  has_lb <- "lower_bound" %in% names(param_specs)
  has_ub <- "upper_bound" %in% names(param_specs)
  for (i in seq_len(nrow(param_specs))) {
    # Determine lower
    if (is.na(param_specs$lower[i])) {
      if (has_lb && !is.na(param_specs$lower_bound[i])) {
        param_specs$lower[i] <- param_specs$lower_bound[i]
      } else {
        bounds <- calc_bounds(param_specs$mean[i], param_specs$uncertainty_pct[i])
        param_specs$lower[i] <- bounds$lower
      }
    }
    # Determine upper
    if (is.na(param_specs$upper[i])) {
      if (has_ub && !is.na(param_specs$upper_bound[i])) {
        param_specs$upper[i] <- param_specs$upper_bound[i]
      } else {
        bounds <- calc_bounds(param_specs$mean[i], param_specs$uncertainty_pct[i])
        param_specs$upper[i] <- bounds$upper
      }
    }
  }
  param_specs
}
