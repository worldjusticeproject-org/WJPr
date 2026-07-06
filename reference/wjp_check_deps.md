# Check WJPr Dependencies

`wjp_check_deps()` verifies that all required and optional dependencies
for WJPr are installed and reports their status.

## Usage

``` r
wjp_check_deps(install = FALSE, quiet = FALSE, ask = interactive())
```

## Arguments

- install:

  Logical. If TRUE, attempts to install missing packages. Default is
  FALSE.

- quiet:

  Logical. If TRUE, suppresses output messages. Default is FALSE.

- ask:

  Logical. If TRUE in an interactive session, asks before installing
  missing packages. Default is
  [`interactive()`](https://rdrr.io/r/base/interactive.html).

## Value

Invisibly returns a list with two elements:

- `core`: Named logical vector of core dependency status

- `optional`: Named logical vector of optional dependency status

## Examples

``` r
# Check all dependencies
wjp_check_deps()
#> 
#> WJPr Dependency Check
#> ============================================================ 
#> 
#> CORE DEPENDENCIES (Required)
#> ---------------------------------------- 
#>   ggplot2      [OK] v4.0.3
#>   dplyr        [OK] v1.2.1
#>   tidyr        [OK] v1.3.2
#>   magrittr     [OK] v2.0.5
#>   rlang        [OK] v1.3.0
#>   tibble       [OK] v3.3.1
#>   sysfonts     [OK] v0.8.9
#>   showtext     [OK] v0.9.8
#> 
#> OPTIONAL DEPENDENCIES
#> ---------------------------------------- 
#>   ggtext       [OK] v0.1.2                Rich text labels (wjp_radar, wjp_edgebars)
#>   ggrepel      [OK] v0.9.8                Non-overlapping labels (wjp_lines, wjp_slope)
#>   ggh4x        [OK] v0.3.1                Extended faceting
#>   haven        [OK] v2.5.5                Reading Stata/SPSS files
#>   purrr        [OK] v1.2.2                Functional programming (wjp_radar)
#> 
#> All dependencies are installed!
#> 

# Check and install missing packages
# wjp_check_deps(install = TRUE)
```
