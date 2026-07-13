# Plot a Diverging Horizontal Bar Chart following WJP style guidelines

**\[experimental\]**

`wjp_divbars()` takes a data frame with long-format data and returns a
ggplot object with a diverging horizontal bar chart following WJP style
guidelines. Bars extend left (negative) and right (positive) from a
common zero line, which makes the chart suitable for contrasting two
opposing responses (e.g., "Trust" vs "No Trust"). Values are expected on
a percentage scale.

## Usage

``` r
wjp_divbars(
  data,
  target,
  grouping,
  diverging,
  negative = NULL,
  cvec = NULL,
  labels = NULL,
  label_color = "#ffffff",
  order = NULL,
  custom_order = FALSE,
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

- diverging:

  String. Column name of the variable that supplies the diverging groups
  (e.g., the answer categories).

- negative:

  String. Value of the `diverging` variable whose bars should extend
  into the negative quadrant. Default is `NULL` (values are used as
  supplied, so negative values must already carry a negative sign).

- cvec:

  Named vector of colors, one per diverging group. Default is `NULL`
  (the WJP contrast pair is applied, with orange for the negative
  group).

- labels:

  String. Column name of the variable containing the value labels to
  display inside the bars. Default is `NULL` (no labels).

- label_color:

  String. Hex code for the value labels. Default is `"#ffffff"`.

- order:

  String. Column name of the variable that contains the display order of
  categories. Default is `NULL` (data order).

- custom_order:

  **\[deprecated\]** Logical. Ordering is now enabled automatically when
  `order` is supplied.

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

# Trust vs no trust, by country
data4divbars <- WJPr::gpp %>%
  filter(year == 2022) %>%
  mutate(
    q1a      = as.double(unclass(q1a)),
    response = case_when(q1a <= 2 ~ "Trust", q1a <= 4 ~ "No Trust")
  ) %>%
  filter(!is.na(response)) %>%
  group_by(country, response) %>%
  count() %>%
  group_by(country) %>%
  mutate(
    percentage  = (n / sum(n)) * 100,
    value_label = paste0(round(percentage, 0), "%")
  )

wjp_divbars(
  data4divbars,
  target    = "percentage",
  grouping  = "country",
  diverging = "response",
  negative  = "No Trust",
  labels    = "value_label",
  cvec      = c("Trust" = "#482d8b", "No Trust" = "#f26b21")
)

```
