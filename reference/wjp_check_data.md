# Validate Data Structure for WJPr Charts

`wjp_check_data()` validates that a data frame has the correct structure
for use with WJPr visualization functions. It checks for required
columns, correct data types, and common issues.

## Usage

``` r
wjp_check_data(
  data,
  type,
  target,
  grouping = NULL,
  colors = NULL,
  cvec = NULL,
  labels = NULL,
  verbose = TRUE
)
```

## Arguments

- data:

  A data frame to validate.

- type:

  A string specifying the chart type. Options are: "bars", "dots",
  "lines", "slope", "dumbbells", "divbars", "radar", "rose", "gauge",
  "lollipops", "edgebars", "groupbars".

- target:

  A string specifying the column name for values to plot.

- grouping:

  A string specifying the column name for categories. Default is NULL.

- colors:

  A string specifying the column name for color grouping. Default is
  NULL.

- cvec:

  A named vector of colors. Default is NULL.

- labels:

  A string specifying the column name for labels. Default is NULL.

- verbose:

  A logical value. If TRUE (default), prints detailed messages. If
  FALSE, returns a list with validation results silently.

## Value

If verbose = TRUE, prints validation messages and returns TRUE/FALSE
invisibly. If verbose = FALSE, returns a list with elements: valid
(logical), errors (character vector), warnings (character vector), info
(character vector).

## Examples

``` r
library(dplyr)

# Prepare sample data
sample_data <- data.frame(
  country = c("Atlantis", "Narnia", "Neverland"),
  trust = c(45.2, 38.1, 52.3),
  year = c("2022", "2022", "2022")
)

# Check if data is valid for bar chart
wjp_check_data(
  data     = sample_data,
  type     = "bars",
  target   = "trust",
  grouping = "country",
  colors   = "year"
)
#> 
#> ✔ Data structure is valid for WJPr!
#> 
#> Info:
#>   ℹ Data has 3 rows and 3 columns.
#>   ℹ Column 'trust' (target): numeric, range [38.1, 52.3]
#>   ℹ Column 'country' (grouping): 3 unique values.
#>   ℹ Column 'year' (colors): 1 unique values: 2022
#>   ℹ No cvec provided. Default colors will be used.
#> 

# Check with color vector
wjp_check_data(
  data     = sample_data,
  type     = "bars",
  target   = "trust",
  grouping = "country",
  colors   = "country",
  cvec     = c("Atlantis" = "#482d8b", "Narnia" = "#2894aa")
)
#> 
#> ✔ Data structure is valid for WJPr!
#> 
#> Warnings:
#>   ⚠ Values in 'country' without color mapping in cvec: Neverland. These will use default colors.
#> 
#> Info:
#>   ℹ Data has 3 rows and 3 columns.
#>   ℹ Column 'trust' (target): numeric, range [38.1, 52.3]
#>   ℹ Column 'country' (grouping): 3 unique values.
#>   ℹ Column 'country' (colors): 3 unique values: Atlantis, Narnia, Neverland
#> 
```
