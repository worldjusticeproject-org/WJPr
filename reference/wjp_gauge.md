# Plot a Gauge Chart following WJP style guidelines

**\[experimental\]**

`wjp_gauge()` creates a gauge (speedometer) chart using ggplot2 based on
the provided data frame. The chart displays segments in a semicircle,
useful for showing composition or progress.

## Usage

``` r
wjp_gauge(
  data,
  target,
  colors,
  cvec = NULL,
  factor_order = NULL,
  labels = NULL,
  crop = c(-10, 0, 0, -8),
  ptheme = WJP_theme()
)
```

## Arguments

- data:

  Data frame containing the data to plot.

- target:

  String. Column name of the variable that supplies the values to plot.

- colors:

  String. Column name of the variable that supplies the color grouping
  for the segments.

- cvec:

  Named vector of colors, one per segment. Names should match the values
  of the `colors` variable. Default is `NULL` (the WJP palette, see
  [`wjp_palette()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_palette.md),
  is applied).

- factor_order:

  Vector with the order in which the segments should be plotted. Default
  is `NULL` (data order).

- labels:

  String. Column name of the variable containing the labels to display
  inside the segments. Default is `NULL` (no labels).

- crop:

  Numeric vector with the space to crop from the Top, Right, Bottom, and
  Left margins, respectively. Default is `c(-10, 0, 0, -8)`.

- ptheme:

  ggplot theme to apply. Default is
  [`WJP_theme()`](https://worldjusticeproject-org.github.io/WJPr/reference/WJP_theme.md).

## Value

A ggplot object representing the gauge chart.

## Examples

``` r
library(dplyr)
library(ggplot2)

# Always load the WJP fonts (optional)
wjp_fonts()

# Create sample data for gauge chart
data4gauge <- data.frame(
  category = c("Category A", "Category B", "Category C", "Category D"),
  value = c(25, 35, 20, 20),
  label = c("25%", "35%", "20%", "20%")
)

# Define colors for each segment
gauge_colors <- c(
  "Category A" = "#482d8b",
  "Category B" = "#2894aa",
  "Category C" = "#f26b21",
  "Category D" = "#555659"
)

# Plotting chart
wjp_gauge(
  data4gauge,
  target       = "value",
  colors       = "category",
  cvec         = gauge_colors,
  factor_order = c("Category A", "Category B", "Category C", "Category D"),
  labels       = "label"
)

```
