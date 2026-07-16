# Visual test: spread_labels_x() horizontal collision handling.
#
# Compares two ways of placing the value labels of a row-based point chart:
#
#   * "Without helper"  -> the naive approach: every label sits on its point
#                          value, so near-equal values collide and duplicate
#                          labels stack on top of each other.
#   * "With helper"      -> the recommended approach: labels are spread with
#                          spread_labels_x() AND identical labels within a row
#                          are collapsed to a single mark. Deduplication is a
#                          content decision that belongs in the drawing layer,
#                          not in the positioning primitive.
#
# Points always stay at their true value; only the labels move. Label colour
# matches the series colour so the association survives the horizontal shift.
#
# Usage: Rscript dev/test_spread_labels.R

suppressPackageStartupMessages({
  library(WJPr)
  library(ggplot2)
  library(dplyr)
  library(tibble)
  library(scales)
})

# Source the local implementation directly so this visual test always exercises
# the working-tree version.
source("R/spread_labels.R")

# Fonts are best-effort: fall back to the default family when offline.
try(wjp_fonts(), silent = TRUE)

# Four rows, each a scenario the helper must handle -------------------------
rows <- tribble(
  ~outcome,               ~category, ~value,
  "Three identical",      "G1",      0.50,
  "Three identical",      "G2",      0.50,
  "Three identical",      "G3",      0.50,
  "Four near-identical",  "G1",      0.36,
  "Four near-identical",  "G2",      0.37,
  "Four near-identical",  "G3",      0.38,
  "Four near-identical",  "G4",      0.38,
  "Near upper edge",      "G1",      0.94,
  "Near upper edge",      "G2",      0.96,
  "Near upper edge",      "G3",      0.98,
  "Already separated",    "G1",      0.15,
  "Already separated",    "G2",      0.50,
  "Already separated",    "G3",      0.85
) %>%
  mutate(
    outcome = factor(
      outcome,
      levels = rev(c("Three identical", "Four near-identical",
                     "Near upper edge", "Already separated"))
    ),
    label = percent(value, accuracy = 1)
  )

panel_levels <- c("Without helper (labels at value)",
                  "With helper (spread + dedup)")

# Points are drawn for every observation in both panels -----------------------
points_data <- bind_rows(
  rows %>% mutate(panel = panel_levels[1]),
  rows %>% mutate(panel = panel_levels[2])
) %>%
  mutate(panel = factor(panel, levels = panel_levels))

# Panel 1 (naive): every label on its point value.
naive_labels <- rows %>%
  mutate(panel = panel_levels[1], label_x = value)

# Panel 2 (recommended): collapse identical labels within a row, then spread.
fixed_labels <- rows %>%
  distinct(outcome, label, .keep_all = TRUE) %>%
  group_by(outcome) %>%
  mutate(
    panel   = panel_levels[2],
    label_x = spread_labels_x(value, labels = label, limits = c(0, 1))
  ) %>%
  ungroup()

labels_data <- bind_rows(naive_labels, fixed_labels) %>%
  mutate(panel = factor(panel, levels = panel_levels))

cvec <- setNames(wjp_palette(4), c("G1", "G2", "G3", "G4"))

plt <- ggplot() +
  geom_point(
    data = points_data,
    aes(x = value, y = outcome, color = category),
    size = 4
  ) +
  geom_text(
    data = labels_data,
    aes(x = label_x, y = outcome, label = label, color = category),
    vjust       = -0.9,
    size        = 3.514598,
    fontface    = "bold",
    show.legend = FALSE
  ) +
  facet_wrap(~panel, ncol = 1) +
  scale_x_continuous(limits = c(0, 1), labels = percent) +
  scale_color_manual(values = cvec) +
  labs(y = "outcome") +
  WJP_theme() +
  theme(
    legend.position = "top",
    strip.text      = element_text(face = "bold", size = 12, hjust = 0),
    panel.spacing   = unit(1.2, "lines")
  )

ggsave(
  "dev/test_spread_labels.png",
  plt,
  width  = 11,
  height = 7,
  dpi    = 150,
  bg     = "white"
)

message("Saved: dev/test_spread_labels.png")

# Print the numeric before/after for a quick sanity check in the console -----
fixed_labels %>%
  arrange(outcome, category) %>%
  transmute(outcome, category, value, label, label_x = round(label_x, 3)) %>%
  print(n = Inf)
