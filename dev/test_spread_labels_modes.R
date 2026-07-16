# Visual test: spread_labels_x() sizing modes.
#
# Contrasts the two ways of sizing the required separation:
#   * min_gap  -> a fixed, uniform centre-to-centre distance (no text measured).
#   * labels   -> the rendered width of each string, so wide labels get more room.
#
# The second row uses labels of very different widths ("Low" vs "Very high") to
# show that the measured-width mode keeps them apart while the uniform mode can
# still let a wide label collide with its neighbour.
#
# Usage: Rscript dev/test_spread_labels_modes.R

suppressPackageStartupMessages({
  library(WJPr)
  library(ggplot2)
  library(dplyr)
  library(tibble)
})

source("R/spread_labels.R")
try(wjp_fonts(), silent = TRUE)

rows <- tribble(
  ~outcome,               ~category, ~value, ~label,
  "Percent labels",       "G1",      0.47,   "47%",
  "Percent labels",       "G2",      0.49,   "49%",
  "Percent labels",       "G3",      0.51,   "51%",
  "Mixed-width labels",   "G1",      0.47,   "Low",
  "Mixed-width labels",   "G2",      0.49,   "Medium",
  "Mixed-width labels",   "G3",      0.51,   "Very high"
) %>%
  mutate(
    outcome = factor(outcome, levels = c("Mixed-width labels", "Percent labels"))
  )

by_gap <- rows %>%
  group_by(outcome) %>%
  mutate(
    panel   = "min_gap = 0.08 (uniform)",
    label_x = spread_labels_x(value, min_gap = 0.08, limits = c(0, 1))
  ) %>%
  ungroup()

by_width <- rows %>%
  group_by(outcome) %>%
  mutate(
    panel   = "labels (measured width)",
    label_x = spread_labels_x(value, labels = label, limits = c(0, 1))
  ) %>%
  ungroup()

plot_data <- bind_rows(by_gap, by_width) %>%
  mutate(
    panel = factor(
      panel,
      levels = c("min_gap = 0.08 (uniform)", "labels (measured width)")
    )
  )

cvec <- setNames(wjp_palette(3), c("G1", "G2", "G3"))

plt <- ggplot(plot_data, aes(x = value, y = outcome, color = category)) +
  geom_point(size = 4) +
  geom_text(
    aes(x = label_x, label = label),
    vjust       = -0.9,
    size        = 3.514598,
    fontface    = "bold",
    show.legend = FALSE
  ) +
  facet_wrap(~panel, ncol = 1) +
  scale_x_continuous(limits = c(0, 1), labels = scales::percent) +
  scale_color_manual(values = cvec) +
  WJP_theme() +
  theme(
    legend.position = "top",
    strip.text      = element_text(face = "bold", size = 12, hjust = 0),
    panel.spacing   = unit(1.2, "lines")
  )

ggsave(
  "dev/test_spread_labels_modes.png",
  plt,
  width  = 11,
  height = 5,
  dpi    = 150,
  bg     = "white"
)

message("Saved: dev/test_spread_labels_modes.png")

bind_rows(by_gap, by_width) %>%
  arrange(panel, outcome, category) %>%
  transmute(panel, outcome, category, label, value, label_x = round(label_x, 3)) %>%
  print(n = Inf)
