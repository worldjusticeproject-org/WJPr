# Plot a Lollipop Chart following WJP style guidelines

**\[experimental\]**

`wjp_lollipops()` takes a data frame with long-format data and returns a
ggplot object with a lollipop chart following WJP style guidelines.
Lollipop charts are a minimalist alternative to horizontal bar charts.
Values are expected on a 0-100 percentage scale.

## Usage

``` r
wjp_lollipops(
  data,
  target,
  grouping,
  labels = NULL,
  order = NULL,
  line_size = 3,
  point_size = 4,
  line_color = "#d9dde3",
  point_color = "#482d8b",
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
  (Y-axis labels).

- labels:

  String. Column name of the variable containing the value labels to
  display. Default is `NULL` (labels are generated automatically as
  rounded percentages).

- order:

  String. Column name of the variable that contains the display order of
  categories. Default is `NULL` (data order).

- line_size:

  Numeric. Thickness of the lines. Default is `3`.

- point_size:

  Numeric. Size of the points. Default is `4`.

- line_color:

  String. Hex code for the lines. Default is `"#d9dde3"`.

- point_color:

  String. Hex code for the points. Default is `"#482d8b"`.

- ptheme:

  ggplot theme to apply. Default is
  [`WJP_theme()`](https://worldjusticeproject-org.github.io/WJPr/reference/WJP_theme.md).

## Value

A ggplot object representing the lollipop chart.

## Details

The function expects one row per category: the category name in
`grouping` and its value in `target`. Value labels are generated
automatically as rounded percentages unless a `labels` column is
supplied. Use `order` to control the top-to-bottom order of the rows,
and `line_color`/`point_color` to adjust the accent colors.

## Examples

``` r
library(dplyr)
library(tidyr)

# Always load the WJP fonts
wjp_fonts()

# Percentage of people that trust their institutions in Atlantis
data4lollipops <- WJPr::gpp %>%
  filter(year == 2022, country == "Atlantis") %>%
  select(q1a, q1b, q1c, q1d) %>%
  mutate(
    across(everything(), \(x) as.double(unclass(x))),
    across(everything(), \(x) case_when(x <= 2 ~ 1, x <= 4 ~ 0))
  ) %>%
  summarise(across(everything(), \(x) mean(x, na.rm = TRUE) * 100)) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "percentage") %>%
  mutate(
    institution = case_when(
      variable == "q1a" ~ "Institution A",
      variable == "q1b" ~ "Institution B",
      variable == "q1c" ~ "Institution C",
      variable == "q1d" ~ "Institution D"
    )
  )

wjp_lollipops(
  data4lollipops,
  target   = "percentage",
  grouping = "institution"
)


# Custom order (highest first) and accent color
data4lollipops_ordered <- data4lollipops %>%
  arrange(desc(percentage)) %>%
  mutate(rank = row_number())

wjp_lollipops(
  data4lollipops_ordered,
  target      = "percentage",
  grouping    = "institution",
  order       = "rank",
  point_color = "#2894aa"
)

```
