# Plot a Diverging Horizontal Bar Chart following WJP style guidelines

**\[experimental\]**

`wjp_divbars()` takes a data frame with a specific data structure
(usually long shaped) and returns a ggplot object with a diverging
horizontal bar chart following WJP style guidelines.

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
  custom_order = FALSE,
  order = NULL,
  ptheme = WJP_theme()
)
```

## Arguments

- data:

  Data frame containing the data to plot

- target:

  String. Column name of the variable that will supply the values to
  plot.

- grouping:

  String. Column name of the variable that supplies the grouping values
  (Y-Axis Labels).

- diverging:

  String. Column name of the variable that supplies the diverging
  values.

- negative:

  String. Value that indicates that the bar should be in the negative
  quadrant.

- cvec:

  Named vector with the colors to apply to each bar segment. Default is
  NULL.

- labels:

  String. Column name of the variable that supplies the labels to show
  in the plot. Default is NULL.

- label_color:

  String. Hex code to be use for the labels.

- custom_order:

  Boolean. If TRUE, the plot will expect a custom order of the graph
  labels. Default is FALSE.

- order:

  String. Vector that contains the custom order for the y-axis labels.
  Default is NULL.

- ptheme:

  ggplot theme function to apply to the plot. By default, function
  applies WJP_theme()

## Value

A ggplot object

## Examples

``` r
library(dplyr)
library(tidyr)
library(haven)
library(ggplot2)

# Always load the WJP fonts (optional)
wjp_fonts()

# Preparing data
data4divbars <- WJPr::gpp %>%
filter(
  year == 2022
) %>%
  select(country, q1a) %>%
  mutate(
    q1a = as.double(unclass(q1a)),
    q1a  = case_when(
      q1a <= 2  ~ "Trust",
      q1a <= 4  ~ "No Trust"
    )
  ) %>%
  group_by(country, q1a) %>%
  count() %>%
  filter(
    !is.na(q1a)
  ) %>%
  group_by(country) %>%
  mutate(
    total       = sum(n),
    percentage  = (n/total)*100,
    value_label = paste0(
      format(
        round(percentage, 1),
        nsmall = 1
      ),
      "%"
    ),
    value_label    = if_else(percentage >= 5, 
                             value_label, 
                             NA_character_),
    direction      = if_else(q1a == "Trust", 
                             "positive", 
                             "negative"),
    percentage     = if_else(direction == "negative", 
                             percentage*-1, 
                             percentage),
    label_position = (percentage/2)
  ) %>%
  select(
    country, q1a, percentage, value_label, label_position, direction
  )

# Plotting chart
wjp_divbars(
  data4divbars,             
  target      = "percentage",       
  grouping    = "country",         
  diverging   = "q1a",     
  negative    = "negative",   
  cvec        = c("Trust"     = "#482d8b",
                  "No Trust"  = "#f26b21"),
  labels      = "value_label"
)
```
