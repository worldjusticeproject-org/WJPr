# Visual test: wjp_dots(show_labels = TRUE) integration.
#
# Exercises the value-label placement built into wjp_dots(): labels are spread
# horizontally with spread_labels_x() so near-equal series do not collide, and
# identical labels within a row are collapsed. Points never move.
#
# Usage: Rscript dev/test_dots_labels.R

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
})

# Load the whole working tree so internal helpers (wjp_legend_theme, etc.) and
# spread_labels_x() all resolve against the local source.
devtools::load_all(quiet = TRUE)

try(wjp_fonts(), silent = TRUE)

# Institutions (rows) x countries (series). The "Courts" row clusters three
# near-equal values, and "Parliament" has two identical values.
data_dots <- tibble::tibble(
  institution = rep(c("Police", "Courts", "Parliament", "Government"), each = 3),
  country     = rep(c("Atlantis", "Narnia", "Neverland"), times = 4),
  percentage  = c(41, 63, 88,      # Police: well separated
                  37, 38, 38,      # Courts: near-identical -> spread + dedup
                  55, 55, 55,      # Parliament: all identical -> single label
                  20, 47, 91)      # Government: separated
)

plt <- wjp_dots(
  data_dots,
  target      = "percentage",
  grouping    = "institution",
  colors      = "country",
  cvec        = c("Atlantis"  = "#482d8b",
                  "Narnia"    = "#2894aa",
                  "Neverland" = "#f26b21"),
  show_labels = TRUE,
  show_legend = TRUE
)

ggsave(
  "dev/test_dots_labels.png",
  plt,
  width  = 10,
  height = 6,
  dpi    = 150,
  bg     = "white"
)

message("Saved: dev/test_dots_labels.png")
