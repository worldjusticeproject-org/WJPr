# =============================================================================
# Desarrollo iterativo de wjp_groupbars()
# =============================================================================

library(dplyr)
library(ggplot2)
library(tidyr)
library(ggtext)

# Cargar el paquete en desarrollo
devtools::load_all()

# =============================================================================
# PASO 1: Datos de prueba
# =============================================================================

data_test <- tibble::tribble(
  ~disaggregation,     ~demographics,        ~pct_weighted,
  # National Average (general)
  "general",           "National Average",   0.75,


  # Age Group
  "Age Group",         "65+",                0.80,
  "Age Group",         "55-64",              0.75,
  "Age Group",         "45-54",              0.73,
  "Age Group",         "35-44",              0.71,
  "Age Group",         "25-34",              0.74,
  "Age Group",         "18-24",              0.79,

  # Disability
  "Disability",        "Without disability", 0.76,
  "Disability",        "With disability",    0.73,

  # Education Level
  "Education Level",   "Higher Education",   0.74,
  "Education Level",   "Lower Education",    0.76,

  # Ethnicity
  "Ethnicity",         "Other Ethnicity",    0.70,
  "Ethnicity",         "White Irish",        0.76,

  # Gender
  "Gender",            "Male",               0.77,
  "Gender",            "Female",             0.73,

  # Income
  "Income",            "> 120k a year",

      0.80,
  "Income",            "70k - 120k a year",  0.75,
  "Income",            "30k - 70k a year",   0.78,
  "Income",            "< 30k a year",       0.68,


  # Region
  "Region",            "Ulster/Connacht",    0.72,
  "Region",            "Munster",            0.76,
  "Region",            "Leinster",           0.73,
  "Region",            "Dublin",             0.77
)

# Verificar estructura
print(data_test)

# =============================================================================
# PASO 2: Probar la función actual
# =============================================================================

# Cargar fuentes
wjp_fonts()

# Probar con la función actual - veamos qué produce
p1 <- wjp_groupbars(

  data          = data_test,
  target        = "pct_weighted",
  grouping      = "disaggregation",
  levels        = "demographics",
  show_national = FALSE
)

print(p1)

# Guardar para comparar
ggsave("dev/test_current.png", p1, width = 10, height = 14)
