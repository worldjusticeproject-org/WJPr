# Script to generate example chart images for documentation
# Run this script to regenerate all example images in man/figures/
#
# Usage:
#   source("data-raw/generate-examples.R")
#
# Or run from terminal:
#   Rscript data-raw/generate-examples.R

library(ggplot2)
library(dplyr)
library(tidyr)
library(haven)
library(showtext)
library(sysfonts)
library(ggtext)
library(ggrepel)
library(ggh4x)
library(grid)

# Load WJPr - try multiple methods
wjpr_loaded <- FALSE

# Method 1: Try devtools::load_all() so examples use the local source tree
tryCatch({
  devtools::load_all()
  wjpr_loaded <- TRUE
  message("Loaded WJPr with devtools::load_all()")
}, error = function(e) {
  message("devtools::load_all() not available")
})

# Method 2: Try loading installed package
if (!wjpr_loaded) {
  tryCatch({
    library(WJPr)
    wjpr_loaded <- TRUE
    message("Loaded WJPr from installed package")
  }, error = function(e) {
    message("WJPr not installed as package")
  })
}

# Method 3: Source files directly
if (!wjpr_loaded) {
  message("Loading WJPr by sourcing R files directly...")
  r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
  for (f in r_files) {
    tryCatch(source(f), error = function(e) NULL)
  }
  # Load data
  load("data/gpp.rda")
  load("data/roli.rda")
  message("Loaded WJPr from source files")
}

# Load fonts
wjp_fonts()

# Create output directory if it doesn't exist
output_dir <- "man/figures"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Helper function to save plots consistently
save_example <- function(plot, name, width = 6, height = 4) {
  filepath <- file.path(output_dir, paste0("example-", name, ".png"))
  ggsave(
    filepath,
    plot,
    width  = width,
    height = height,
    dpi    = 150,
    bg     = "white"
  )
  message("Saved: ", filepath)
}

# Load sample data
# Use gpp directly (loaded from data/ or from WJPr package)
# Convert haven_labelled columns to regular types
gpp_data <- gpp %>%
  mutate(across(where(haven::is.labelled), ~ as.numeric(.x)))

# =============================================================================
# 1. BAR CHART
# =============================================================================
message("\n1. Generating bar chart example...")

data_bars <- gpp_data %>%
  filter(year == 2022) %>%
  select(country, q1a) %>%
  mutate(
    trust = case_when(
      q1a <= 2  ~ 1,
      q1a <= 4  ~ 0,
      q1a == 99 ~ NA_real_
    )
  ) %>%
  group_by(country) %>%
  summarise(
    trust = mean(trust, na.rm = TRUE) * 100,
    .groups = "drop"
  ) %>%
  mutate(
    label = paste0(round(trust, 0), "%"),
    label_pos = trust + 5
  )

plot_bars <- wjp_bars(
  data_bars,
  target   = "trust",
  grouping = "country",
  colors   = "country",
  labels   = "label",
  lab_pos  = "label_pos",
  cvec     = c("Atlantis"  = "#482d8b",
               "Narnia"    = "#2894aa",
               "Neverland" = "#f26b21")
)

save_example(plot_bars, "bars")

# =============================================================================
# 2. HORIZONTAL BAR CHART
# =============================================================================
message("2. Generating horizontal bar chart example...")

plot_bars_h <- wjp_bars(
  data_bars,
  target    = "trust",
  grouping  = "country",
  colors    = "country",
  labels    = "label",
  lab_pos   = "label_pos",
  cvec      = c("Atlantis"  = "#482d8b",
                "Narnia"    = "#2894aa",
                "Neverland" = "#f26b21"),
  direction = "horizontal"
)

save_example(plot_bars_h, "bars-horizontal")

# =============================================================================
# 3. DIVERGING BARS
# =============================================================================
message("3. Generating diverging bars example...")

data_divbars <- gpp_data %>%
  filter(year == 2022) %>%
  select(country, q1a) %>%
  mutate(
    response = case_when(
      q1a <= 2 ~ "Trust",
      q1a <= 4 ~ "No Trust"
    )
  ) %>%
  filter(!is.na(response)) %>%
  group_by(country, response) %>%
  count() %>%
  group_by(country) %>%
  mutate(
    total   = sum(n),
    percent = (n / total) * 100,
    label   = paste0(round(percent, 0), "%"),
    percent = if_else(response == "No Trust", -percent, percent)
  )

plot_divbars <- wjp_divbars(
  data_divbars,
  target    = "percent",
  grouping  = "country",
  diverging = "response",
  negative  = "negative",
  labels    = "label",
  cvec      = c("Trust" = "#482d8b", "No Trust" = "#f26b21")
)

save_example(plot_divbars, "divbars")

# =============================================================================
# 4. DOTS CHART
# =============================================================================
message("4. Generating dots chart example...")

data_dots <- gpp_data %>%
  select(country, q1a, q1b, q1c, q1d) %>%
  mutate(
    across(
      starts_with("q1"),
      ~ case_when(.x <= 2 ~ 1, .x <= 4 ~ 0)
    )
  ) %>%
  group_by(country) %>%
  summarise(
    across(everything(), ~ mean(.x, na.rm = TRUE) * 100),
    .groups = "drop"
  ) %>%
  pivot_longer(
    -country,
    names_to  = "variable",
    values_to = "trust"
  ) %>%
  mutate(
    institution = case_when(
      variable == "q1a" ~ "Police",
      variable == "q1b" ~ "Courts",
      variable == "q1c" ~ "Parliament",
      variable == "q1d" ~ "Government"
    )
  )

plot_dots <- wjp_dots(
  data_dots,
  target   = "trust",
  grouping = "institution",
  colors   = "country",
  cvec     = c("Atlantis"  = "#482d8b",
               "Narnia"    = "#2894aa",
               "Neverland" = "#f26b21")
)

save_example(plot_dots, "dots")

# =============================================================================
# 5. LINE CHART
# =============================================================================
message("5. Generating line chart example...")

data_lines <- gpp_data %>%
  filter(country == "Atlantis") %>%
  select(year, q1a, q1b, q1c) %>%
  mutate(
    across(
      starts_with("q1"),
      ~ case_when(.x <= 2 ~ 1, .x <= 4 ~ 0)
    ),
    year = as.character(year)
  ) %>%
  group_by(year) %>%
  summarise(
    across(everything(), ~ mean(.x, na.rm = TRUE) * 100),
    .groups = "drop"
  ) %>%
  pivot_longer(
    -year,
    names_to  = "variable",
    values_to = "trust"
  ) %>%
  mutate(
    institution = case_when(
      variable == "q1a" ~ "Police",
      variable == "q1b" ~ "Courts",
      variable == "q1c" ~ "Parliament"
    ),
    label = paste0(round(trust, 0), "%")
  )

plot_lines <- wjp_lines(
  data_lines,
  target   = "trust",
  grouping = "year",
  colors   = "institution",
  labels   = "label",
  repel    = TRUE,
  cvec     = c("Police"     = "#482d8b",
               "Courts"     = "#2894aa",
               "Parliament" = "#f26b21")
)

save_example(plot_lines, "lines")

# =============================================================================
# 6. SLOPE CHART
# =============================================================================
message("6. Generating slope chart example...")

data_slope <- gpp_data %>%
  filter(year %in% c(2017, 2019)) %>%
  select(year, gend, q1a) %>%
  mutate(
    trust = case_when(q1a <= 2 ~ 1, q1a <= 4 ~ 0),
    gender = case_when(gend == 1 ~ "Male", gend == 2 ~ "Female")
  ) %>%
  group_by(year, gender) %>%
  summarise(
    trust = mean(trust, na.rm = TRUE) * 100,
    .groups = "drop"
  ) %>%
  mutate(label = paste0(round(trust, 0), "%"))

plot_slope <- wjp_slope(
  data_slope,
  target   = "trust",
  grouping = "year",
  colors   = "gender",
  labels   = "label",
  cvec     = c("Male" = "#482d8b", "Female" = "#f26b21"),
  repel    = TRUE
)

save_example(plot_slope, "slope")

# =============================================================================
# 7. DUMBBELLS CHART
# =============================================================================
message("7. Generating dumbbells chart example...")

data_dumbbells <- data_lines %>%
  filter(year %in% c("2017", "2022"))

plot_dumbbells <- wjp_dumbbells(
  data_dumbbells,
  target   = "trust",
  grouping = "institution",
  colors   = "year",
  cgroups  = c("2017", "2022"),
  labels   = "label",
  cvec     = c("2017" = "#2894aa", "2022" = "#482d8b")
)

save_example(plot_dumbbells, "dumbbells")

# =============================================================================
# 8. RADAR CHART
# =============================================================================
message("8. Generating radar chart example...")

data_radar <- gpp_data %>%
  select(gend, starts_with("q49")) %>%
  mutate(
    gender = case_when(gend == 1 ~ "Male", gend == 2 ~ "Female"),
    across(
      starts_with("q49"),
      ~ case_when(.x <= 2 ~ 1, .x <= 99 ~ 0)
    )
  ) %>%
  group_by(gender) %>%
  summarise(
    across(starts_with("q49"), ~ mean(.x, na.rm = TRUE) * 100),
    .groups = "drop"
  ) %>%
  pivot_longer(
    -gender,
    names_to  = "category",
    values_to = "score"
  ) %>%
  mutate(
    label = case_when(
      category == "q49a"    ~ "Reliable",
      category == "q49b_G1" ~ "Accessible",
      category == "q49b_G2" ~ "Channels",
      category == "q49c_G1" ~ "Consistent",
      category == "q49c_G2" ~ "Stable",
      category == "q49d_G1" ~ "Efficient",
      category == "q49d_G2" ~ "Fast",
      category == "q49e_G1" ~ "Effective",
      category == "q49e_G2" ~ "Trustworthy"
    )
  )

plot_radar <- wjp_radar(
  data_radar,
  axis_var = "category",
  target   = "score",
  labels   = "label",
  colors   = "gender",
  cvec     = c("Male" = "#482d8b", "Female" = "#f26b21")
)

save_example(plot_radar, "radar", width = 6, height = 5)

# =============================================================================
# 9. ROSE CHART
# =============================================================================
message("9. Generating rose chart example...")

data_rose <- data_radar %>%
  filter(gender == "Male")

plot_rose <- wjp_rose(
  data_rose,
  target   = "score",
  grouping = "category",
  labels   = "label",
  cvec     = c("#482d8b", "#2894aa", "#f26b21", "#137b3f", "#869d3b",
               "#0f9581", "#1a74b6", "#8f2e8c", "#555659")
)

save_example(plot_rose, "rose", width = 6, height = 5)

# =============================================================================
# 10. LOLLIPOP CHART
# =============================================================================
message("10. Generating lollipop chart example...")

data_lollipop <- data_bars

plot_lollipop <- wjp_lollipops(
  data_lollipop,
  target      = "trust",
  grouping    = "country",
  line_color  = "#d9dde3",
  point_color = "#482d8b"
)

save_example(plot_lollipop, "lollipops")

# =============================================================================
# 11. EDGEBARS CHART
# =============================================================================
message("11. Generating edgebars chart example...")

plot_edgebars <- wjp_edgebars(
  data_bars,
  target   = "trust",
  grouping = "country",
  cvec     = "#f26b21"
)

save_example(plot_edgebars, "edgebars")

# =============================================================================
# 12. GAUGE CHART
# =============================================================================
message("12. Generating gauge chart example...")

tryCatch({
  data_gauge <- data.frame(
    category = c("Factor 1", "Factor 2", "Factor 3", "Factor 4"),
    value    = c(25, 35, 25, 15),
    label    = c("25%", "35%", "25%", "15%")
  )

  gauge_colors <- c(
    "Factor 1" = "#482d8b",
    "Factor 2" = "#2894aa",
    "Factor 3" = "#f26b21",
    "Factor 4" = "#555659"
  )

  plot_gauge <- wjp_gauge(
    data_gauge,
    target       = "value",
    colors       = "category",
    cvec         = gauge_colors,
    factor_order = c("Factor 1", "Factor 2", "Factor 3", "Factor 4"),
    labels       = "label"
  )

  save_example(plot_gauge, "gauge", width = 5, height = 4)
}, error = function(e) {
  message("  SKIPPED: Gauge chart requires ggh4x with with_ggtrace function")
  message("  Error: ", e$message)
})

# =============================================================================
# 13. GROUPED BARS CHART
# =============================================================================
message("13. Generating grouped bars chart example...")

# Use percentage-scale input with precomputed confidence intervals so the
# thumbnail shows the grouped-bar geometry without relying on vignette data.
data_groupbars <- data.frame(
  group    = c("Gender", "Gender", "Age", "Age", "Age"),
  category = c("Men", "Women", "18-24", "25-54", "55+"),
  value    = c(74.4, 70.3, 72.1, 73.1, 73.0),
  lower    = c(72.4, 68.4, 70.1, 71.0, 70.8),
  upper    = c(76.4, 72.1, 74.5, 75.2, 75.2),
  stringsAsFactors = FALSE
)

plot_groupbars <- wjp_groupbars(
  data_groupbars,
  target            = "value",
  grouping          = "group",
  levels            = "category",
  colors            = c("#482d8b", "#e5e8e8"),
  group_order       = c("Gender", "Age"),
  level_order       = list(
    Gender = c("Women", "Men"),
    Age    = c("55+", "25-54", "18-24")
  ),
  draw_ci           = TRUE,
  ci_lower          = "lower",
  ci_upper          = "upper",
  show_national     = TRUE,
  national_value    = 72.3,
  national_style    = "bar",
  national_label    = "National Average",
  national_ci_lower = 70.0,
  national_ci_upper = 74.6,
  show_axis         = TRUE
)

save_example(plot_groupbars, "groupbars", width = 6, height = 5)

# =============================================================================
# SUMMARY
# =============================================================================
message("\n", strrep("=", 50))
message("All example images generated successfully!")
message("Output directory: ", normalizePath(output_dir))
message(strrep("=", 50), "\n")

# List generated files
files <- list.files(output_dir, pattern = "^example-.*\\.png$", full.names = TRUE)
message("Generated files:")
for (f in files) {
  message("  - ", basename(f))
}
