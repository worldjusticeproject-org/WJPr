# Chart Gallery

This gallery showcases all chart types available in the WJPr package
using the official **World Justice Project color palette**. Each example
demonstrates how to create publication-ready charts following WJP style
guidelines.

## WJP Color Palette

The WJPr package uses colors from the official WJP Brand Standards
Manual:

| Color Name       | Hex Code  | Usage                                       |
|------------------|-----------|---------------------------------------------|
| Violet (Primary) | `#482d8b` | Main brand color, headers, primary elements |
| Teal-Blue        | `#2894aa` | Secondary elements, alternative to violet   |
| Orange           | `#f26b21` | Accent color, highlights, calls to action   |
| Cool Gray        | `#555659` | Body text, subtle elements                  |

For categorical data visualizations, use these colors in sequence:

    #181878, #BF02AF, #3366FF, #FF4D6A, #9C89ED, #226640, #FFB52B, #00A8A5

``` r

library(ggplot2)
library(dplyr)
library(tidyr)
library(WJPr)

# Load fonts
wjp_fonts()

# Load sample data
gpp_data <- WJPr::gpp

# WJP Color Palettes
wjp_categorical <- c(
  "#181878", "#BF02AF", "#3366FF", "#FF4D6A",
  "#9C89ED", "#226640", "#FFB52B", "#00A8A5"
)

# Colors for contrasting two groups
wjp_contrast <- c("#181878", "#FF4D6A")

# Factor colors (Rule of Law Index)
wjp_factors <- c(
  "Constraints" = "#137b3f",
  "Corruption"  = "#869d3b",
  "Open Gov"    = "#0f9581",
  "Rights"      = "#1a74b6",
  "Security"    = "#413179",
  "Regulatory"  = "#8f2e8c",
  "Civil"       = "#89191c",
  "Criminal"    = "#f07623"
)
```

------------------------------------------------------------------------

## Bar Charts

### Vertical Bars

[`wjp_bars()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_bars.md) -
Standard vertical bar chart for comparing values across categories.

``` r

data_bars <- gpp_data %>%
  filter(year == 2022) %>%
  mutate(
    q1a  = as.double(unclass(q1a)),
    trust = case_when(q1a <= 2 ~ 1, q1a <= 4 ~ 0)
  ) %>%
  group_by(country) %>%
  summarise(trust = mean(trust, na.rm = TRUE) * 100, .groups = "drop") %>%
  mutate(label = paste0(round(trust, 0), "%"), label_pos = trust + 5)

wjp_bars(
  data_bars,
  target   = "trust",
  grouping = "country",
  colors   = "country",
  labels   = "label",
  lab_pos  = "label_pos",
  cvec     = c("Atlantis" = "#181878", "Narnia" = "#3366FF", "Neverland" = "#00A8A5")
)
```

![](gallery_files/figure-html/bars-vertical-1.png)

### Horizontal Bars

Set `direction = "horizontal"` for horizontal orientation.

``` r

wjp_bars(
  data_bars,
  target    = "trust",
  grouping  = "country",
  colors    = "country",
  labels    = "label",
  lab_pos   = "label_pos",
  cvec      = c("Atlantis" = "#181878", "Narnia" = "#3366FF", "Neverland" = "#00A8A5"),
  direction = "horizontal"
)
```

![](gallery_files/figure-html/bars-horizontal-1.png)

------------------------------------------------------------------------

## Diverging Bars

[`wjp_divbars()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_divbars.md) -
Show positive and negative values extending from a center point.

``` r

data_divbars <- gpp_data %>%
  filter(year == 2022) %>%
  mutate(
    q1a     = as.double(unclass(q1a)),
    response = case_when(q1a <= 2 ~ "Trust", q1a <= 4 ~ "No Trust")
  ) %>%
  filter(!is.na(response)) %>%
  group_by(country, response) %>%
  count() %>%
  group_by(country) %>%
  mutate(
    percent = (n / sum(n)) * 100,
    label   = paste0(round(percent, 0), "%"),
    percent = if_else(response == "No Trust", -percent, percent)
  )

wjp_divbars(
  data_divbars,
  target    = "percent",
  grouping  = "country",
  diverging = "response",
  negative  = "negative",
  labels    = "label",
  cvec      = c("Trust" = "#181878", "No Trust" = "#FF4D6A")
)
```

![](gallery_files/figure-html/divbars-1.png)

------------------------------------------------------------------------

## Dots Chart

[`wjp_dots()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_dots.md) -
Compare multiple variables across groups with dot markers.

``` r

data_dots <- gpp_data %>%
  select(country, q1a, q1b, q1c, q1d) %>%
  mutate(
    across(starts_with("q1"), \(x) as.double(unclass(x))),
    across(starts_with("q1"), ~ case_when(.x <= 2 ~ 1, .x <= 4 ~ 0))
  ) %>%
  group_by(country) %>%
  summarise(across(everything(), ~ mean(.x, na.rm = TRUE) * 100), .groups = "drop") %>%
  pivot_longer(-country, names_to = "variable", values_to = "trust") %>%
  mutate(
    institution = case_when(
      variable == "q1a" ~ "Police",
      variable == "q1b" ~ "Courts",
      variable == "q1c" ~ "Parliament",
      variable == "q1d" ~ "Government"
    )
  )

wjp_dots(
  data_dots,
  target   = "trust",
  grouping = "institution",
  colors   = "country",
  cvec     = c("Atlantis" = "#181878", "Narnia" = "#BF02AF", "Neverland" = "#226640")
)
```

![](gallery_files/figure-html/dots-1.png)

------------------------------------------------------------------------

## Line Chart

[`wjp_lines()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_lines.md) -
Display trends over time with connected points.

``` r

library(ggrepel)

data_lines <- gpp_data %>%
  filter(country == "Atlantis") %>%
  select(year, q1a, q1b, q1c) %>%
  mutate(
    across(starts_with("q1"), \(x) as.double(unclass(x))),
    across(starts_with("q1"), ~ case_when(.x <= 2 ~ 1, .x <= 4 ~ 0)),
    year = as.character(year)
  ) %>%
  group_by(year) %>%
  summarise(across(everything(), ~ mean(.x, na.rm = TRUE) * 100), .groups = "drop") %>%
  pivot_longer(-year, names_to = "variable", values_to = "trust") %>%
  mutate(
    institution = case_when(
      variable == "q1a" ~ "Police",
      variable == "q1b" ~ "Courts",
      variable == "q1c" ~ "Parliament"
    ),
    label = paste0(round(trust, 0), "%")
  )

wjp_lines(
  data_lines,
  target   = "trust",
  grouping = "year",
  ngroups  = data_lines$institution,
  colors   = "institution",
  labels   = "label",
  repel    = TRUE,
  cvec     = c("Police" = "#181878", "Courts" = "#BF02AF", "Parliament" = "#00A8A5")
)
```

![](gallery_files/figure-html/lines-1.png)

------------------------------------------------------------------------

## Slope Chart

[`wjp_slope()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_slope.md) -
Compare values between exactly two time points.

``` r

data_slope <- gpp_data %>%
  filter(year %in% c(2017, 2019)) %>%
  mutate(
    q1a   = as.double(unclass(q1a)),
    gend  = as.double(unclass(gend)),
    trust  = case_when(q1a <= 2 ~ 1, q1a <= 4 ~ 0),
    gender = case_when(gend == 1 ~ "Male", gend == 2 ~ "Female")
  ) %>%
  group_by(year, gender) %>%
  summarise(trust = mean(trust, na.rm = TRUE) * 100, .groups = "drop") %>%
  mutate(label = paste0(round(trust, 0), "%"))

wjp_slope(
  data_slope,
  target   = "trust",
  grouping = "year",
  ngroups  = data_slope$gender,
  colors   = "gender",
  labels   = "label",
  cvec     = c("Male" = "#181878", "Female" = "#FF4D6A"),
  repel    = TRUE
)
```

![](gallery_files/figure-html/slope-1.png)

------------------------------------------------------------------------

## Dumbbell Chart

[`wjp_dumbbells()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_dumbbells.md) -
Show change between two points with connected markers.

``` r

data_dumbbells <- data_lines %>%
  filter(year %in% c("2017", "2022"))

wjp_dumbbells(
  data_dumbbells,
  target   = "trust",
  grouping = "institution",
  color    = "year",
  cgroups  = c("2017", "2022"),
  cvec     = c("2017" = "#181878", "2022" = "#FF4D6A")
)
```

![](gallery_files/figure-html/dumbbells-1.png)

------------------------------------------------------------------------

## Lollipop Chart

[`wjp_lollipops()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_lollipops.md) -
Minimalist bar alternative with stems and dots.

``` r

wjp_lollipops(
  data_bars,
  target      = "trust",
  grouping    = "country",
  line_color  = "#555659",
  point_color = "#482d8b"
)
```

![](gallery_files/figure-html/lollipops-1.png)

------------------------------------------------------------------------

## Edgebars Chart

[`wjp_edgebars()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_edgebars.md) -
Horizontal bars with labels at the edge, ideal for narrow spaces.

``` r

wjp_edgebars(
  data_bars,
  target   = "trust",
  grouping = "country",
  labels   = "country",
  cvec     = "#2894aa"
)
```

![](gallery_files/figure-html/edgebars-1.png)

------------------------------------------------------------------------

## Radar Chart

[`wjp_radar()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_radar.md) -
Compare multiple dimensions on a circular grid.

``` r

data_radar <- gpp_data %>%
  select(gend, starts_with("q49")) %>%
  mutate(
    gend = as.double(unclass(gend)),
    across(starts_with("q49"), \(x) as.double(unclass(x))),
    gender = case_when(gend == 1 ~ "Male", gend == 2 ~ "Female"),
    across(starts_with("q49"), ~ case_when(.x <= 2 ~ 1, .x <= 99 ~ 0))
  ) %>%
  group_by(gender) %>%
  summarise(across(starts_with("q49"), ~ mean(.x, na.rm = TRUE) * 100), .groups = "drop") %>%
  pivot_longer(-gender, names_to = "category", values_to = "score") %>%
  mutate(
    label = case_when(
      category == "q49a"    ~ "Reliable",
      category == "q49b_G1" ~ "Accessible",
      category == "q49b_G2" ~ "Channels",
      category == "q49c_G1" ~ "Consistent",
      category == "q49c_G2" ~ "Stable",
      category == "q49d_G1" ~ "Efficient",
      category == "q49d_G2" ~ "Fast",
      category == "q49e_G1" ~ "Effective",
      category == "q49e_G2" ~ "Trustworthy"
    )
  )

wjp_radar(
  data_radar,
  axis_var = "category",
  target   = "score",
  labels   = "label",
  colors   = "gender",
  cvec     = c("Male" = "#181878", "Female" = "#FF4D6A")
)
```

![](gallery_files/figure-html/radar-1.png)

------------------------------------------------------------------------

## Rose Chart

[`wjp_rose()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_rose.md) -
Circular bar chart for single-unit multi-dimensional data.

``` r

data_rose <- data_radar %>%
  filter(gender == "Male")

wjp_rose(
  data_rose,
  target   = "score",
  grouping = "category",
  labels   = "label",
  cvec     = c("#CCCCFF", "#AEAEFF", "#8F8FFF", "#7373E5", "#5E5ECC",
               "#181878", "#3366FF", "#00A8A5", "#226640")
)
```

![](gallery_files/figure-html/rose-1.png)

------------------------------------------------------------------------

## Gauge Chart

[`wjp_gauge()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_gauge.md) -
Semicircular chart for showing composition or progress.

``` r

data_gauge <- data.frame(
  category = c("Factor 1", "Factor 2", "Factor 3", "Factor 4"),
  value    = c(25, 35, 25, 15),
  label    = c("25%", "35%", "25%", "15%")
)

wjp_gauge(
  data_gauge,
  target       = "value",
  colors       = "category",
  cvec         = c("Factor 1" = "#482d8b", "Factor 2" = "#2894aa",
                   "Factor 3" = "#f26b21", "Factor 4" = "#555659"),
  factor_order = c("Factor 1", "Factor 2", "Factor 3", "Factor 4"),
  labels       = "label"
)
```

![](gallery_files/figure-html/gauge-1.png)

------------------------------------------------------------------------

## Quick Reference

| Chart | Function | Best For |
|----|----|----|
| Vertical Bars | [`wjp_bars()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_bars.md) | Comparing values across categories |
| Horizontal Bars | `wjp_bars(direction = "horizontal")` | Long category names |
| Diverging Bars | [`wjp_divbars()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_divbars.md) | Positive/negative comparisons |
| Dots | [`wjp_dots()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_dots.md) | Multiple groups, multiple variables |
| Lines | [`wjp_lines()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_lines.md) | Trends over time |
| Slope | [`wjp_slope()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_slope.md) | Change between two time points |
| Dumbbells | [`wjp_dumbbells()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_dumbbells.md) | Before/after comparisons |
| Lollipops | [`wjp_lollipops()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_lollipops.md) | Minimalist bar alternative |
| Edgebars | [`wjp_edgebars()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_edgebars.md) | Narrow spaces, long labels |
| Radar | [`wjp_radar()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_radar.md) | Multi-dimensional group comparison |
| Rose | [`wjp_rose()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_rose.md) | Multi-dimensional single unit |
| Gauge | [`wjp_gauge()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_gauge.md) | Composition, progress |
