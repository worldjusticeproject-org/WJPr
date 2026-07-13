# Plot a Horizontal Edgebars Chart following WJP style guidelines

**\[experimental\]**

`wjp_edgebars()` takes a data frame with long-format data and returns a
ggplot object with an edgebar chart following WJP style guidelines.
Edgebars are horizontal bars with the category label placed at the edge
of each bar, which makes them ideal for narrow spaces and long labels.
Values are expected on a 0-100 percentage scale.

## Usage

``` r
wjp_edgebars(
  data,
  target,
  grouping,
  labels = NULL,
  cvec = NULL,
  x_lab_pos = NULL,
  y_lab_pos = 0,
  nudge_lab = 2.5,
  margin_top = 20,
  bar_width = 0.35,
  ptheme = WJP_theme()
)
```

## Arguments

- data:

  Data frame containing the data to plot.

- target:

  String. Column name of the variable that supplies the values to plot.

- grouping:

  String. Column name of the variable that supplies the categories.

- labels:

  String. Column name of the variable containing the text labels to
  display above each bar. Default is `NULL` (the `grouping` values are
  used).

- cvec:

  String. Hex code of the color for the bars. Default is `NULL` (the WJP
  primary violet `#482d8b` is applied).

- x_lab_pos:

  String. Column name of the variable that contains the display order of
  the bars. Default is `NULL` (data order).

- y_lab_pos:

  Numeric. Y-axis position for the text labels. Default is `0`.

- nudge_lab:

  Numeric. Padding for the text labels in millimeters. Default is `2.5`.

- margin_top:

  Numeric. Top margin of the plot. Default is `20`.

- bar_width:

  Numeric. Width of the bars. The default of `0.35` is recommended for
  single bars; use `0.5` for plots with two bars.

- ptheme:

  ggplot theme to apply. Default is
  [`WJP_theme()`](https://worldjusticeproject-org.github.io/WJPr/reference/WJP_theme.md).

## Value

A ggplot object representing the edgebars plot.

## Details

The function expects one row per bar: the category in `grouping` and its
value in `target`. The text above each bar defaults to the `grouping`
values; pass a `labels` column to customize it (HTML/markdown is
supported when the ggtext package is installed). Percentage value labels
are added automatically at the end of each bar.

## Examples

``` r
library(dplyr)

# Always load the WJP fonts
wjp_fonts()

# Percentage of people that trust their institutions, by country
data4edgebars <- WJPr::gpp %>%
  filter(year == 2022) %>%
  mutate(
    q1a   = as.double(unclass(q1a)),
    trust = case_when(q1a <= 2 ~ 1, q1a <= 4 ~ 0)
  ) %>%
  group_by(country) %>%
  summarise(trust = mean(trust, na.rm = TRUE) * 100, .groups = "drop")

wjp_edgebars(
  data4edgebars,
  target   = "trust",
  grouping = "country",
  cvec     = "#2894aa"
)


# Custom rich-text labels above each bar (requires ggtext)
data4edgebars_lab <- data4edgebars %>%
  mutate(
    bar_label = paste0(
      "<b>", country, "</b> — % that trust their institutions"
    )
  )

wjp_edgebars(
  data4edgebars_lab,
  target   = "trust",
  grouping = "country",
  labels   = "bar_label"
)

```
