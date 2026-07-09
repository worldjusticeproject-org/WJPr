# Plot a Rose Chart following WJP style guidelines

**\[experimental\]**

`wjp_rose()` takes a data frame with a specific data structure (usually
long shaped) and returns a ggplot object with a rose chart following WJP
style guidelines.

## Usage

``` r
wjp_rose(data, target, grouping, labels, cvec = NULL, order_var = NULL)
```

## Arguments

- data:

  A data frame containing the data to be plotted.

- target:

  A string specifying the variable in the data frame that contains the
  values to be plotted.

- grouping:

  A string specifying the variable in the data frame that contains the
  groups for the axis.

- labels:

  A string specifying the variable in the data frame that contains the
  labels to be displayed.

- cvec:

  A vector of colors to apply to lines.

- order_var:

  A string specifying the variable in the data frame that contains the
  display order of categories. Default is NULL.

## Value

A ggplot object representing the rose chart.

## Examples

``` r
library(dplyr)
library(tidyr)
library(haven)
library(ggplot2)

# Always load the WJP fonts (optional)
wjp_fonts()

# Preparing data
gpp_data <- WJPr::gpp

data4rose <- gpp_data %>%
select(starts_with("q49")) %>%
  mutate(
    across(starts_with("q49"), \(x) as.double(unclass(x))),
    across(
      starts_with("q49"),
      \(x) case_when(
        x <= 2  ~ 1,
        x <= 99 ~ 0
      )
    )
  ) %>%
  summarise(
    across(
      starts_with("q49"),
      \(x) mean(x, na.rm = TRUE)*100
    )
  ) %>%
  pivot_longer(
    everything(),
    names_to  = "category",
    values_to = "percentage"
  ) %>%
  mutate(
    axis_label = category
  )

# Plotting chart
wjp_rose(
  data4rose,             
  target    = "percentage",       
  grouping  = "category",    
  labels    = "axis_label",
  cvec      = c("#482d8b", "#2894aa", "#f26b21",
                "#137b3f", "#869d3b", "#0f9581",
                "#1a74b6", "#8f2e8c", "#555659")
)

```
