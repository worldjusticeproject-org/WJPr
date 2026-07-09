# Plot a Lollipop Chart following WJP style guidelines

**\[experimental\]**

`wjp_lollipops()` takes a data frame with a specific data structure
(usually long shaped) and returns a ggplot object with a lollipop chart
following WJP style guidelines.

## Usage

``` r
wjp_lollipops(
  data,
  target,
  grouping,
  order = NULL,
  line_size = 3,
  point_size = 4,
  line_color = "#d9dde3",
  point_color = "#482d8b"
)
```

## Arguments

- data:

  A data frame containing the data to be plotted.

- target:

  A string specifying the column name of the variable that contains the
  numeric values to be plotted.

- grouping:

  A string specifying the column name of the variable that contains the
  categories for the Y-axis labels.

- order:

  A string specifying the column name of the variable that contains the
  custom order for displaying categories. Default is NULL (uses row
  order).

- line_size:

  A numeric value specifying the thickness of the lines. Default is 3.

- point_size:

  A numeric value specifying the size of the points. Default is 4.

- line_color:

  A string specifying the hex color code for the lines. Default is
  "#d9dde3".

- point_color:

  A string specifying the hex color code for the points. Default is
  "#482d8b".

## Value

A ggplot object representing the lollipop chart.

## Examples

``` r
library(dplyr)
library(ggplot2)

# Always load the WJP fonts (optional)
wjp_fonts()

# Preparing data
gpp_data <- WJPr::gpp

data4lollipops <- gpp_data %>%
  filter(year == 2022, country == "Atlantis") %>%
  select(q1a, q1b, q1c, q1d) %>%
  mutate(
    across(everything(), \(x) as.double(unclass(x))),
    across(
      everything(),
      \(x) case_when(
        x <= 2 ~ 1,
        x <= 4 ~ 0
      )
    )
  ) %>%
  summarise(
    across(
      everything(),
      \(x) mean(x, na.rm = TRUE) * 100
    )
  ) %>%
  tidyr::pivot_longer(
    everything(),
    names_to  = "variable",
    values_to = "percentage"
  ) %>%
  mutate(
    institution = case_when(
      variable == "q1a" ~ "Institution A",
      variable == "q1b" ~ "Institution B",
      variable == "q1c" ~ "Institution C",
      variable == "q1d" ~ "Institution D"
    )
  )

# Plotting chart
wjp_lollipops(
  data4lollipops,
  target      = "percentage",
  grouping    = "institution",
  line_color  = "#d9dde3",
  point_color = "#482d8b"
)

```
