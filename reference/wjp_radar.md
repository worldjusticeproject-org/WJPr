# Plot a Radar Chart following WJP style guidelines

**\[experimental\]**

`wjp_radar()` takes a data frame with a specific data structure (usually
long shaped) and returns a ggplot object with a radar chart following
WJP style guidelines.

## Usage

``` r
wjp_radar(
  data,
  axis_var,
  target,
  labels,
  colors,
  maincat = NULL,
  cvec = NULL,
  order = NULL,
  source = "GPP",
  order_var = NULL
)
```

## Arguments

- data:

  Data frame containing the data to plot.

- axis_var:

  String. Column name of the variable that supplies the axes
  (dimensions) of the radar.

- target:

  String. Column name of the variable that supplies the values to plot.

- labels:

  String. Column name of the variable containing the axis labels to
  display around the radar.

- colors:

  String. Column name of the variable that supplies the color grouping.
  The plot shows one polygon per group.

- maincat:

  String. Column used to choose the axis labels. If `NULL`, labels are
  taken from the first color group.

- cvec:

  Named vector of colors, one per group. Default is `NULL` (the WJP
  contrast pair `#482d8b` / `#f26b21` is applied).

- order:

  String. Column name of the variable that contains the display order of
  the axes. Default is `NULL` (data order).

- source:

  String. Either `"GPP"` (values on a 0-100 percentage scale) or `"QRQ"`
  (values on a 0-1 score scale). Default is `"GPP"`.

- order_var:

  **\[deprecated\]** Use `order` instead.

## Value

A ggplot object representing the radar plot.

## Examples

``` r
library(dplyr)
library(tidyr)

# Always load the WJP fonts
wjp_fonts()

# Opinions about authorities, by gender
data4radar <- WJPr::gpp %>%
  select(gend, starts_with("q49")) %>%
  mutate(
    gend   = as.double(unclass(gend)),
    across(starts_with("q49"), \(x) as.double(unclass(x))),
    gender = case_when(gend == 1 ~ "Male", gend == 2 ~ "Female"),
    across(starts_with("q49"), \(x) case_when(x <= 2 ~ 1, x <= 99 ~ 0))
  ) %>%
  group_by(gender) %>%
  summarise(across(starts_with("q49"), \(x) mean(x, na.rm = TRUE) * 100)) %>%
  pivot_longer(!gender, names_to = "category", values_to = "percentage") %>%
  mutate(axis_label = category)

wjp_radar(
  data4radar,
  axis_var = "category",
  target   = "percentage",
  labels   = "axis_label",
  colors   = "gender",
  cvec     = c("Male" = "#482d8b", "Female" = "#f26b21")
)

```
