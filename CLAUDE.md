# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Project Overview

WJPr is an R package developed by the Data Analytics Unit at The World
Justice Project (WJP). It provides visualization functions for creating
publication-ready charts following WJP style guidelines, plus Rule of
Law Index data and analysis tools.

## Development Commands

### Package Installation

``` r

devtools::install_github("worldjusticeproject-org/WJPr")
```

### Environment Setup (renv)

``` r

renv::restore()         # Install exact package versions from renv.lock
renv::status()          # Check if environment matches lockfile
renv::snapshot()        # Update lockfile after installing packages
```

### Building and Checking

``` r

devtools::document()    # Generate documentation from Roxygen2 comments
devtools::build()       # Build the package
devtools::check()       # Run R CMD check
devtools::load_all()    # Load package for testing during development
```

### Running Tests

``` r

devtools::test()                    # Run all tests
testthat::test_file("tests/testthat/test-example.R")  # Run single test file
```

### Documentation

``` r

pkgdown::build_site()   # Build the documentation website locally
```

## Architecture

### Function Pattern

All visualization functions follow a consistent pattern: - Named
`wjp_*()` (e.g.,
[`wjp_bars()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_bars.md),
[`wjp_lines()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_lines.md),
[`wjp_radar()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_radar.md)) -
Accept a data frame with tidy/long-format data - Return a ggplot2 object
for further customization - Use common parameters: `target`, `grouping`,
`colors`, `cvec` (named color vector), `labels`, `ptheme`

### Key Files

- `R/utils.R` -
  [`wjp_fonts()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_fonts.md)
  loads Lato and Inter Tight fonts;
  [`WJP_theme()`](https://worldjusticeproject-org.github.io/WJPr/reference/WJP_theme.md)
  provides base ggplot2 theme;
  [`wjp_palette()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_palette.md)
  exposes the WJP categorical palette (used as the default `cvec`
  fallback by all chart functions)
- `R/*Chart.R` - Each chart type has its own file (barsChart.R,
  lineChart.R, radarChart.R, etc.)
- `R/check_data.R` -
  [`wjp_check_data()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_check_data.md)
  validates data structure before plotting
- `R/diffmeans.R` - Statistical analysis function for hypothesis testing
- `data/gpp.rda` and `data/roli.rda` - Built-in datasets
- `vignettes/articles/data-preparation.Rmd` - Guide for preparing data
  for WJPr functions

### Chart Functions (13 total)

| Function | File | Description |
|----|----|----|
| [`wjp_bars()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_bars.md) | barsChart.R | Vertical/horizontal bar charts |
| [`wjp_divbars()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_divbars.md) | divbarsChart.R | Diverging bar charts |
| [`wjp_dots()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_dots.md) | dotsChart.R | Dot plots |
| [`wjp_lines()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_lines.md) | lineChart.R | Line charts with points |
| [`wjp_slope()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_slope.md) | slopeChart.R | Slope charts for comparisons |
| [`wjp_dumbbells()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_dumbbells.md) | dumbellsChart.R | Dumbbell plots |
| [`wjp_radar()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_radar.md) | radarChart.R | Radar/spider charts |
| [`wjp_rose()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_rose.md) | roseChart.R | Rose/polar bar charts |
| [`wjp_gauge()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_gauge.md) | gaugeChart.R | Gauge/speedometer charts |
| [`wjp_lollipops()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_lollipops.md) | lollipopChart.R | Lollipop charts |
| [`wjp_edgebars()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_edgebars.md) | edgebarsChart.R | Edge-aligned horizontal bars |
| [`wjp_groupbars()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_groupbars.md) | groupbarsChart.R | Faceted stacked bars by demographic groups, with optional CI and national line/bar |
| [`diffmeans()`](https://worldjusticeproject-org.github.io/WJPr/reference/diffmeans.md) | diffmeans.R | Difference in means analysis |

### Styling Conventions

- Font: Lato (loaded via Google Fonts using sysfonts/showtext)
- WJP color palette uses hex codes such as `#482d8b`, `#2894aa`,
  `#f26b21`, and `#555659` (full ordered palette available via
  [`wjp_palette()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_palette.md))
- Colors are passed via named vectors (`cvec`) where names match
  grouping variable values; when `cvec` is NULL, functions fall back to
  [`wjp_palette()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_palette.md)
- Always call
  [`wjp_fonts()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_fonts.md)
  before plotting to ensure fonts are available
- Value labels: Lato Full bold, `size = 3.514598` (10 pt), ink color
  `#4a4a49`
- Grid lines: `#d1cfd1`; category axis text: `#524F4C`, `hjust = 0`
- Horizontal charts display the first data row at the top

### Documentation

- Uses Roxygen2 for inline documentation (RoxygenNote: 7.3.2)
- All exported functions need `@export` tag
- Functions are marked with `lifecycle::badge("experimental")` where
  applicable
- Examples should use the built-in
  [`WJPr::gpp`](https://worldjusticeproject-org.github.io/WJPr/reference/gpp.md)
  or
  [`WJPr::roli`](https://worldjusticeproject-org.github.io/WJPr/reference/roli.md)
  datasets

## CI/CD

GitHub Actions workflow (`.github/workflows/pkgdown.yaml`) automatically
builds and deploys documentation to GitHub Pages on push to main/master.

## Contributing Guidelines

### Adding New Functions

1.  **File naming**: `R/{tipo}Chart.R` (e.g., `R/waterfallChart.R`)
2.  **Function naming**: `wjp_{tipo}()` (e.g., `wjp_waterfall()`)
3.  **Required parameters**: `data`, `target`, `grouping`
4.  **Optional parameters**: `colors`, `cvec`, `labels`,
    `ptheme = WJP_theme()`

### Function Structure Pattern

``` r
wjp_newchart <- function(data, target, grouping, colors = NULL, cvec = NULL, ptheme = WJP_theme()) {
  # 1. Rename columns with all_of()
  data <- data %>% rename(target_var = all_of(target), grouping_var = all_of(grouping))

  # 2. Handle NULL/duplicate parameters
  if (is.null(colors)) {
    data <- data %>% mutate(colors_var = grouping_var)
  } else if (colors == grouping) {
    data <- data %>% mutate(colors_var = grouping_var)
  } else {
    data <- data %>% rename(colors_var = all_of(colors))
  }

  # 3. Create ggplot
  plt <- ggplot(data, aes(...)) + geom_*()

  # 4. Apply colors only if cvec not NULL
  if (!is.null(cvec)) plt <- plt + scale_fill_manual(values = cvec)

  # 5. Apply theme
  plt <- plt + ptheme

  return(plt)
}
```

### Checklist Before PR

Roxygen2 docs with `@export`, `@param`, `@return`, `@examples`

Include `lifecycle::badge("experimental")`

Add to `data-raw/generate-examples.R`

Update this CLAUDE.md file

Run `devtools::document()` and `devtools::check()`

### Documentation Files

- `CONTRIBUTING.md` - Complete contribution guidelines
- `vignettes/articles/development-guide.Rmd` - Step-by-step tutorial
- `.github/ISSUE_TEMPLATE/` - Issue templates
- `.github/pull_request_template.md` - PR template
