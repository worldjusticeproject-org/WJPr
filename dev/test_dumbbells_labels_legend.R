# Visual test: colored endpoint labels and a legend in wjp_dumbbells().
#
# Uses generic comparison names to verify that legend labels and colors are
# derived from `cgroups` and `cvec`, rather than from hard-coded values.
#
# Usage: Rscript dev/test_dumbbells_labels_legend.R

suppressPackageStartupMessages({
  library(WJPr)
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(magrittr)
})

# Source the local implementation directly so this visual test remains fast
# and always exercises the working-tree version.
source("R/dumbbellsChart.R")

data_test <- data.frame(
  outcome = rep(
    c(
      "Problem Solved",
      "Fair Process",
      "Trust in Effectiveness",
      "Trust in Competence"
    ),
    each = 2
  ),
  comparison = rep(c("Category 1", "Category 2"), 4),
  value = c(68, 79, 47, 64, 38, 37, 48, 51)
) %>%
  mutate(value_label = paste0(round(value, 0), "%"))

plt <- wjp_dumbbells(
  data         = data_test,
  target       = "value",
  grouping     = "outcome",
  colors       = "comparison",
  cgroups      = c("Category 1", "Category 2"),
  labels       = "value_label",
  cvec         = c(
    "Category 1" = "#2894aa",
    "Category 2" = "#482d8b"
  ),
  show_legend  = TRUE,
  label_offset = 4
)

ggsave(
  "dev/test_dumbbells_labels_legend.png",
  plt,
  width = 12,
  height = 7,
  dpi = 150,
  bg = "white"
)

message("Saved: dev/test_dumbbells_labels_legend.png")
