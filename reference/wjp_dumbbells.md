# Plot a Dumbbell Chart following WJP style guidelines

**\[experimental\]**

`wjp_dumbbells()` takes a data frame with long-format data and returns a
ggplot object with a dumbbell chart following WJP style guidelines.
Dumbbell charts show the change between two points (e.g., two years) for
each category, connected by a line. Values are expected on a 0-100
percentage scale.

## Usage

``` r
wjp_dumbbells(
  data,
  target,
  grouping,
  cgroups,
  colors = NULL,
  labels = NULL,
  labpos = NULL,
  cvec = NULL,
  order = NULL,
  bgcolor = "#ffffff",
  color = NULL,
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

- cgroups:

  Character vector of length 2 with the two groups to compare (the start
  and end points of each dumbbell).

- colors:

  String. Column name of the variable that indicates the start and end
  groups (the one containing the `cgroups` values).

- labels:

  String. Column name of the variable containing the value labels to
  display. Default is `NULL` (no labels).

- labpos:

  String. Column name of the variable that contains the positions for
  the value labels. Default is `NULL` (positions are computed
  automatically just outside each endpoint).

- cvec:

  Vector of two colors for the start and end points. If named, names
  should match the `cgroups` values. Default is `NULL`
  (`c("#2894aa", "#482d8b")` is applied).

- order:

  Named vector mapping category values to their display order (top to
  bottom). Default is `NULL` (data order).

- bgcolor:

  String. Hex code of the background color for the alternating row
  strips. Default is `"#ffffff"`.

- color:

  **\[deprecated\]** Use `colors` instead.

- ptheme:

  ggplot theme to apply. Default is
  [`WJP_theme()`](https://worldjusticeproject-org.github.io/WJPr/reference/WJP_theme.md).

## Value

A ggplot object.

## Details

The function expects long-format data with one row per `grouping`
(category) and `colors` (endpoint) combination; `cgroups` names the two
endpoint values in order (start, end). When `labels` is supplied without
`labpos`, labels are placed automatically just outside each endpoint.
Use `order` (a named vector such as `c("A" = 1, "B" = 2)`) to control
the top-to-bottom order of the rows.

## Examples

``` r
library(dplyr)
library(tidyr)

# Always load the WJP fonts
wjp_fonts()

# Percentage of people that trust their institutions, 2017 vs 2022
data4dumbbells <- WJPr::gpp %>%
  filter(country == "Atlantis", year %in% c(2017, 2022)) %>%
  select(year, q1a, q1b, q1c) %>%
  mutate(
    across(!year, \(x) as.double(unclass(x))),
    across(!year, ~ case_when(.x <= 2 ~ 1, .x <= 4 ~ 0)),
    year = as.character(year)
  ) %>%
  group_by(year) %>%
  summarise(across(everything(), \(x) mean(x, na.rm = TRUE) * 100)) %>%
  pivot_longer(!year, names_to = "variable", values_to = "percentage") %>%
  mutate(
    institution = case_when(
      variable == "q1a" ~ "Institution A",
      variable == "q1b" ~ "Institution B",
      variable == "q1c" ~ "Institution C"
    ),
    value_label = paste0(round(percentage, 0), "%")
  )

wjp_dumbbells(
  data4dumbbells,
  target   = "percentage",
  grouping = "institution",
  colors   = "year",
  cgroups  = c("2017", "2022"),
  labels   = "value_label",
  cvec     = c("2017" = "#2894aa", "2022" = "#482d8b")
)

```
