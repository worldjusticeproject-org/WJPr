# Plot a Line Chart following WJP style guidelines

**\[experimental\]**

`wjp_lines()` takes a data frame with long-format data and returns a
ggplot object with a line chart following WJP style guidelines. Each
line is defined by the `colors` variable, so the function works out of
the box for both single and multiple series. Values are expected on a
0-100 percentage scale.

## Usage

``` r
wjp_lines(
  data,
  target,
  grouping,
  colors = NULL,
  cvec = NULL,
  labels = NULL,
  repel = FALSE,
  transparency = FALSE,
  transparencies = NULL,
  custom.axis = FALSE,
  x.breaks = NULL,
  x.labels = NULL,
  sec.ticks = NULL,
  ngroups = NULL,
  ptheme = WJP_theme()
)
```

## Arguments

- data:

  Data frame containing the data to plot.

- target:

  String. Column name of the variable that supplies the values to plot.

- grouping:

  String. Column name of the variable that supplies the X-axis values
  (usually years).

- colors:

  String. Column name of the variable that defines the lines and their
  color grouping. Default is `NULL` (a single line is drawn).

- cvec:

  Named vector of colors, one per line. Names should match the values of
  the `colors` variable. Default is `NULL` (the WJP palette, see
  [`wjp_palette()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_palette.md),
  is applied).

- labels:

  String. Column name of the variable containing the value labels to
  display. Default is `NULL` (no labels).

- repel:

  Logical. If `TRUE`, the ggrepel package is used to avoid overlapping
  labels. Default is `FALSE`.

- transparency:

  Logical. If `TRUE`, per-line opacities given in `transparencies` are
  applied. Default is `FALSE`.

- transparencies:

  Named vector of opacities, one per line. Required when
  `transparency = TRUE`.

- custom.axis:

  Logical. If `TRUE`, `x.breaks` and `x.labels` are applied to a
  continuous X-axis (requires the ggh4x package). Default is `FALSE`.

- x.breaks:

  Numeric vector with custom breaks for the X-axis.

- x.labels:

  Character vector with labels for the X-axis. Must have the same length
  as `x.breaks`.

- sec.ticks:

  Numeric vector with minor breaks for the X-axis.

- ngroups:

  **\[deprecated\]** Grouping vector for the lines. Retained for
  backwards compatibility; lines are now grouped by `colors`
  automatically.

- ptheme:

  ggplot theme to apply. Default is
  [`WJP_theme()`](https://worldjusticeproject-org.github.io/WJPr/reference/WJP_theme.md).

## Value

A ggplot object.

## Examples

``` r
library(dplyr)
library(tidyr)

# Always load the WJP fonts
wjp_fonts()

# Percentage of people that trust their institutions, over time
data4lines <- WJPr::gpp %>%
  filter(country == "Atlantis") %>%
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

# Multiple lines, one per institution
wjp_lines(
  data4lines,
  target   = "percentage",
  grouping = "year",
  colors   = "institution",
  labels   = "value_label",
  repel    = TRUE,
  cvec     = c("Institution A" = "#482d8b",
               "Institution B" = "#2894aa",
               "Institution C" = "#f26b21")
)


# Single line
wjp_lines(
  data4lines %>% filter(institution == "Institution A"),
  target   = "percentage",
  grouping = "year",
  colors   = "institution",
  labels   = "value_label"
)

```
