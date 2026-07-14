# Plot a Slope Chart following WJP style guidelines

**\[experimental\]**

`wjp_slope()` takes a data frame with long-format data and returns a
ggplot object with a slope chart following WJP style guidelines. Slope
charts compare values between exactly two points in time. Each line is
defined by the `colors` variable. Values are expected on a 0-100
percentage scale.

## Usage

``` r
wjp_slope(
  data,
  target,
  grouping,
  colors = NULL,
  cvec = NULL,
  labels = NULL,
  repel = FALSE,
  ngroups = NULL,
  ptheme = WJP_theme(),
  show_legend = FALSE
)
```

## Arguments

- data:

  Data frame containing the data to plot.

- target:

  String. Column name of the variable that supplies the values to plot.

- grouping:

  String. Column name of the numeric variable that supplies the two
  X-axis values (usually years).

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

- ngroups:

  **\[deprecated\]** Grouping vector for the lines. Retained for
  backwards compatibility; lines are now grouped by `colors`
  automatically.

- ptheme:

  ggplot theme to apply. Default is
  [`WJP_theme()`](https://worldjusticeproject-org.github.io/WJPr/reference/WJP_theme.md).

- show_legend:

  Logical. If `TRUE`, displays a horizontal series legend above the
  chart when `colors` is supplied. Default is `FALSE`.

## Value

A ggplot object.

## Details

The function expects long-format data with exactly two `grouping` values
(the two time points) per series. `grouping` must be numeric (e.g.,
years) so the value labels can be placed just outside each endpoint.
When labels overlap, set `repel = TRUE` (requires the ggrepel package).

## Examples

``` r
library(dplyr)

# Always load the WJP fonts
wjp_fonts()

# Percentage of people that trust their institutions, by gender
data4slopes <- WJPr::gpp %>%
  filter(year %in% c(2017, 2019)) %>%
  mutate(
    q1a    = as.double(unclass(q1a)),
    gend   = as.double(unclass(gend)),
    trust  = case_when(q1a <= 2 ~ 1, q1a <= 4 ~ 0),
    gender = case_when(gend == 1 ~ "Male", gend == 2 ~ "Female")
  ) %>%
  group_by(year, gender) %>%
  summarise(trust = mean(trust, na.rm = TRUE) * 100, .groups = "drop") %>%
  mutate(value_label = paste0(round(trust, 0), "%"))

wjp_slope(
  data4slopes,
  target   = "trust",
  grouping = "year",
  colors   = "gender",
  labels   = "value_label",
  cvec     = c("Male" = "#482d8b", "Female" = "#f26b21"),
  repel    = TRUE,
  show_legend = TRUE
)


# Minimal call: colors default to the WJP palette
wjp_slope(
  data4slopes,
  target   = "trust",
  grouping = "year",
  colors   = "gender",
  labels   = "value_label"
)

```
