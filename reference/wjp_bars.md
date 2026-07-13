# Plot a Bar Chart following WJP style guidelines

**\[experimental\]**

`wjp_bars()` takes a data frame with long-format data and returns a
ggplot object with a vertical or horizontal bar chart following WJP
style guidelines. Values are expected on a 0-100 percentage scale.

## Usage

``` r
wjp_bars(
  data,
  target,
  grouping,
  labels = NULL,
  colors = NULL,
  cvec = NULL,
  direction = "vertical",
  stacked = FALSE,
  lab_pos = NULL,
  expand = FALSE,
  order = NULL,
  width = 0.9,
  ptheme = WJP_theme()
)
```

## Arguments

- data:

  Data frame containing the data to plot.

- target:

  String. Column name of the variable that supplies the values to plot.

- grouping:

  String. Column name of the variable that supplies the categories
  (X-axis for vertical bars, Y-axis for horizontal bars).

- labels:

  String. Column name of the variable containing the value labels to
  display. Default is `NULL` (no labels).

- colors:

  String. Column name of the variable that contains the color grouping.
  Default is `NULL` (colors follow `grouping`).

- cvec:

  Named vector of colors. Names should match the values of the `colors`
  variable. Default is `NULL` (the WJP palette, see
  [`wjp_palette()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_palette.md),
  is applied).

- direction:

  String. Either `"vertical"` (default) or `"horizontal"`.

- stacked:

  Logical. If `TRUE`, bars are stacked on top of each other per group.
  Default is `FALSE`.

- lab_pos:

  String. Column name of the variable that contains the Y coordinates
  for the value labels. Default is `NULL` (labels are placed at the bar
  value).

- expand:

  Logical. If `TRUE`, the axis is expanded to give extra space for value
  labels above 100%. Default is `FALSE`.

- order:

  String. Column name of the variable that contains the display order of
  categories. Default is `NULL` (data order).

- width:

  Numeric value between 0 and 1. Width of bars as a fraction of the
  space available for each bar. Default is `0.9`.

- ptheme:

  ggplot theme to apply. Default is
  [`WJP_theme()`](https://worldjusticeproject-org.github.io/WJPr/reference/WJP_theme.md).

## Value

A ggplot object.

## Examples

``` r
library(dplyr)

# Always load the WJP fonts
wjp_fonts()

# Percentage of people that trust their institutions, by country
data4bars <- WJPr::gpp %>%
  filter(year == 2022) %>%
  mutate(
    q1a   = as.double(unclass(q1a)),
    trust = case_when(q1a <= 2 ~ 1, q1a <= 4 ~ 0)
  ) %>%
  group_by(country) %>%
  summarise(trust = mean(trust, na.rm = TRUE) * 100, .groups = "drop") %>%
  mutate(
    value_label    = paste0(round(trust, 0), "%"),
    label_position = trust + 6
  )

# Vertical bars (default)
wjp_bars(
  data4bars,
  target   = "trust",
  grouping = "country",
  labels   = "value_label",
  lab_pos  = "label_position",
  cvec     = c("Atlantis"  = "#482d8b",
               "Narnia"    = "#2894aa",
               "Neverland" = "#f26b21")
)


# Horizontal bars
wjp_bars(
  data4bars,
  target    = "trust",
  grouping  = "country",
  labels    = "value_label",
  lab_pos   = "label_position",
  direction = "horizontal"
)

```
