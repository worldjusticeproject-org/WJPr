# Plot a Line Chart following WJP style guidelines

**\[experimental\]**

`wjp_lines()` takes a data frame with a specific data structure (usually
long shaped) and returns a ggplot object with a line chart following WJP
style guidelines.

## Usage

``` r
wjp_lines(
  data,
  target,
  grouping,
  ngroups,
  colors,
  cvec = NULL,
  labels = NULL,
  repel = FALSE,
  transparency = FALSE,
  transparencies = NULL,
  custom.axis = FALSE,
  x.breaks = NULL,
  x.labels = NULL,
  sec.ticks = NULL,
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
  (X-Axis).

- ngroups:

  Vector containing each of the groups for the lines. If there is only a
  single group, please input c = (1).

- colors:

  String. Column name of the variable that contains the color grouping.

- cvec:

  Named vector with the colors to apply to each line.

- labels:

  String. Column name of the variable containing the value labels to
  display in plot.

- repel:

  Boolean. If TRUE, function will apply the ggrepel package to repel
  labels. Default is FALSE.

- transparency:

  Boolean. If TRUE, function will apply different opacities patterns.
  Default is FALSE.

- transparencies:

  Named vector with the different opacities to apply to each line.

- custom.axis:

  Boolean. If TRUE, x.breaks and x.labels will be passed to the ggplot
  theme. Default is FALSE.

- x.breaks:

  Numeric vector with custom breaks for the X-Axis.

- x.labels:

  Character vector with labels for the x-axis. It has to be the same
  length than x.breaks.

- sec.ticks:

  Numeric vector containing the minor breaks for the plot X-Axis.

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

# Always load the WJP fonts if not passing a custom theme to function
wjp_fonts()

# Preparing data
gpp_data <- WJPr::gpp

data4lines <- gpp_data %>%
filter(
  country == "Atlantis"
) %>%
  select(year, q1a, q1b, q1c) %>%
  mutate(
    across(
      !year,
      \(x) as.double(unclass(x))
    ),
    across(
      !year,
      ~case_when(
        .x <= 2  ~ 1,
        .x <= 4  ~ 0,
        .x == 99 ~ NA_real_
      )
    ),
    year = as.character(year)
  ) %>%
  group_by(year) %>%
  summarise(
    across(
      everything(),
      \(x) mean(x, na.rm = TRUE)
    ),
    .groups = "keep"
  ) %>%
  mutate(
    across(
      everything(),
      \(x) x*100
    )
  ) %>%
  pivot_longer(
    !year,
    names_to  = "variable",
    values_to = "percentage" 
  ) %>%
  mutate(
    institution = case_when(
      variable == "q1a" ~ "Institution A",
      variable == "q1b" ~ "Institution B",
      variable == "q1c" ~ "Institution C"
    ),
    value_label = paste0(
      format(
        round(percentage, 0),
        nsmall = 0
      ),
      "%"
    )
  )
 
 # Plotting chart
 wjp_lines(
  data4lines %>% filter(institution == "Institution A"),                    
  target         = "percentage",             
  grouping       = "year",
  ngroups        = 1,                 
  colors         = "institution",
  cvec           = c("Institution A" = "#482d8b"),
  labels         = "value_label"
 )
```
