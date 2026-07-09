# Plot a Dumbbell Chart following WJP style guidelines

**\[experimental\]**

`wjp_dumbbells()` takes a data frame with a specific data structure
(usually long shaped) and returns a ggplot object with a dumbbell chart
following WJP style guidelines.

## Usage

``` r
wjp_dumbbells(
  data,
  target,
  grouping,
  cgroups,
  color,
  labels = NULL,
  labpos = NULL,
  cvec = NULL,
  order = NULL,
  ptheme = WJP_theme()
)
```

## Arguments

- data:

  A data frame containing the data to be plotted.

- target:

  A string specifying the variable in the data frame that contains the
  numeric values to be plotted.

- grouping:

  A string specifying the variable in the data frame that contains the
  categories for the rows.

- cgroups:

  A vector of two strings specifying the groups to be compared in the
  dumbbell plot.

- color:

  A string specifying the variable in the data frame that indicates the
  groups for start and end points.

- labels:

  A string specifying the variable in the data frame that contains the
  text labels to display. Default is NULL.

- labpos:

  A string specifying the variable in the data frame that contains the
  label positions.

- cvec:

  A vector of colors to apply to the points and lines. Default is NULL.

- order:

  A named vector specifying the order of the categories. Default is
  NULL.

- ptheme:

  A ggplot2 theme object to be applied to the plot. Default is
  WJP_theme().

## Value

A ggplot object representing the dumbbell plot.

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

data4dumbbells <- gpp_data %>%
filter(
  country == "Atlantis" & year %in% c(2017, 2022)
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
  wjp_dumbbells(
    data4dumbbells,
    target    = "percentage",
    grouping  = "institution",
    color     = "year",
    cvec      = c("2017" = "#2894aa",
                  "2022" = "#482d8b"),
    cgroups   = c("2017", "2022")
 )

 
```
