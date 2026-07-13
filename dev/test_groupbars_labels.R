# Prueba: posición de labels en wjp_groupbars() con intervalos de confianza.
# Replica la estructura del chart de country reports (Overall / Age / Benefits /
# Capabilities score threshold) para verificar que los labels quedan al final
# de la barra completa, después del complemento gris.
#
# Uso: Rscript dev/test_groupbars_labels.R

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(ggtext)
  library(showtext)
  library(sysfonts)
})
devtools::load_all(quiet = TRUE)

wjp_fonts()

data_test <- data.frame(
  group = c(
    "Age", "Age", "Age",
    "Benefits", "Benefits",
    "Capabilities score threshold", "Capabilities score threshold"
  ),
  category = c(
    "55+", "25 to 54", "18 to 24",
    "No benefits", "Benefits",
    "Lower", "Higher"
  ),
  value = c(65, 62, 53, 61, 64, 54, 68),
  lower = c(63, 60, 49, 59, 62, 51, 66),
  upper = c(67, 64, 57, 63, 66, 57, 70)
)

plt <- wjp_groupbars(
  data_test,
  target            = "value",
  grouping          = "group",
  levels            = "category",
  colors            = c("#482d8b", "#e5e8e8"),
  group_order       = c("Age", "Benefits", "Capabilities score threshold"),
  level_order       = list(
    Age = c("18 to 24", "25 to 54", "55+"),
    Benefits = c("Benefits", "No benefits"),
    `Capabilities score threshold` = c("Higher", "Lower")
  ),
  draw_ci           = TRUE,
  ci_lower          = "lower",
  ci_upper          = "upper",
  show_national     = TRUE,
  national_value    = 62,
  national_style    = "bar",
  national_label    = "Overall",
  national_ci_lower = 60.5,
  national_ci_upper = 63.5,
  strip_position    = "top"
)

ggsave("dev/test_groupbars_labels.png", plt,
       width = 9, height = 6, dpi = 150, bg = "white")
message("Saved: dev/test_groupbars_labels.png")
