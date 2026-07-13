# Plot a Rose Chart following WJP style guidelines

**\[experimental\]**

`wjp_rose()` takes a data frame with long-format data and returns a
ggplot object with a rose (polar bar) chart following WJP style
guidelines. Rose charts display the values of a single unit across
multiple dimensions. Values can be supplied as proportions (0-1) or
percentages (0-100).

## Usage

``` r
wjp_rose(
  data,
  target,
  grouping,
  labels,
  cvec = NULL,
  order = NULL,
  order_var = NULL,
  ptheme = WJP_theme()
)
```

## Arguments

- data:

  Data frame containing the data to plot.

- target:

  String. Column name of the variable that supplies the values to plot.

- grouping:

  String. Column name of the variable that supplies the dimensions (one
  petal per dimension).

- labels:

  String. Column name of the variable containing the labels to display
  around the chart.

- cvec:

  Vector of colors, one per dimension. Default is `NULL` (the WJP
  palette, see
  [`wjp_palette()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_palette.md),
  is applied).

- order:

  String. Column name of the variable that contains the display order of
  the dimensions. Default is `NULL` (dimensions are ordered by value).

- order_var:

  **\[deprecated\]** Use `order` instead.

- ptheme:

  ggplot theme to apply. Default is
  [`WJP_theme()`](https://worldjusticeproject-org.github.io/WJPr/reference/WJP_theme.md).

## Value

A ggplot object representing the rose chart.

## Details

The function expects one row per dimension (petal): the dimension name
in `grouping`, its value in `target`, and the text to display around the
chart in `labels`. By default petals are ordered by value; pass an
`order` column for a custom arrangement. Labels support HTML/markdown
formatting when the ggtext package is installed.

## Examples

``` r
library(dplyr)
library(tidyr)

# Always load the WJP fonts
wjp_fonts()

# Opinions about authorities as a single-unit profile
data4rose <- WJPr::gpp %>%
  select(starts_with("q49")) %>%
  mutate(
    across(starts_with("q49"), \(x) as.double(unclass(x))),
    across(starts_with("q49"), \(x) case_when(x <= 2 ~ 1, x <= 99 ~ 0))
  ) %>%
  summarise(across(starts_with("q49"), \(x) mean(x, na.rm = TRUE) * 100)) %>%
  pivot_longer(everything(), names_to = "category", values_to = "percentage") %>%
  mutate(axis_label = category)

wjp_rose(
  data4rose,
  target   = "percentage",
  grouping = "category",
  labels   = "axis_label"
)

```
