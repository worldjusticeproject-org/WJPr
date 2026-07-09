# Plot a Slope Chart following WJP style guidelines

**\[experimental\]**

`wjp_slope()` takes a data frame with a specific data structure (usually
long shaped) and returns a ggplot object with a slope chart following
WJP style guidelines.

## Usage

``` r
wjp_slope(
  data,
  target,
  grouping,
  ngroups,
  colors,
  cvec = NULL,
  labels = NULL,
  repel = FALSE,
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
  display in plot. Default is NULL.

- repel:

  Boolean. If TRUE, function will apply the ggrepel package to repel
  labels. Default is FALSE.

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
library(ggrepel)

# Always load the WJP fonts if not passing a custom theme to function
wjp_fonts()

# Preparing data
gpp_data <- WJPr::gpp

data4slopes <- gpp_data %>%
select(year, gend, q1a) %>%
  filter(
    year %in% c(2017, 2019)
  ) %>%
  mutate(
    gend = as.double(unclass(gend)),
    q1a = as.double(unclass(q1a)),
    trust = case_when(
      q1a <= 2  ~ 1,
      q1a <= 4  ~ 0
    ),
    gender = case_when(
      gend == 1 ~ "Male",
      gend == 2 ~ "Female"
    )
  ) %>%
  group_by(year, gender) %>%
  summarise(
    trust = mean(trust, na.rm = TRUE)*100,
    .groups = "keep"
  ) %>%
  mutate(
    value_label = paste0(
      format(
        round(trust, 0),
        nsmall = 0
      ),
      "%"
    )
  )

# Plotting chart
wjp_slope(
  data4slopes,                    
  target    = "trust",             
  grouping  = "year",
  ngroups   = data4slopes$gender,                 
  labels    = "value_label",
  colors    = "gender",
  cvec      = c("Male"   = "#482d8b",
                "Female" = "#f26b21"),
  repel     = TRUE
)
```
