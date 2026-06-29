# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WJPr is an R package developed by the Data Analytics Unit at The World Justice Project (WJP). It provides visualization functions for creating publication-ready charts following WJP style guidelines, plus Rule of Law Index data and analysis tools.

## Development Commands

### Package Installation
```r
devtools::install_github("worldjusticeproject-org/WJPr")
```

### Environment Setup (renv)
```r
renv::restore()         # Install exact package versions from renv.lock
renv::status()          # Check if environment matches lockfile
renv::snapshot()        # Update lockfile after installing packages
```

### Building and Checking
```r
devtools::document()    # Generate documentation from Roxygen2 comments
devtools::build()       # Build the package
devtools::check()       # Run R CMD check
devtools::load_all()    # Load package for testing during development
```

### Running Tests
```r
devtools::test()                    # Run all tests
testthat::test_file("tests/testthat/test-example.R")  # Run single test file
```

### Documentation
```r
pkgdown::build_site()   # Build the documentation website locally
```

## Architecture

### Function Pattern
All visualization functions follow a consistent pattern:
- Named `wjp_*()` (e.g., `wjp_bars()`, `wjp_lines()`, `wjp_radar()`)
- Accept a data frame with tidy/long-format data
- Return a ggplot2 object for further customization
- Use common parameters: `target`, `grouping`, `colors`, `cvec` (named color vector), `labels`, `ptheme`

### Key Files
- `R/utils.R` - `wjp_fonts()` loads Lato and Inter Tight fonts; `WJP_theme()` provides base ggplot2 theme
- `R/*Chart.R` - Each chart type has its own file (barsChart.R, lineChart.R, radarChart.R, etc.)
- `R/check_data.R` - `wjp_check_data()` validates data structure before plotting
- `R/diffmeans.R` - Statistical analysis function for hypothesis testing
- `data/gpp.rda` and `data/roli.rda` - Built-in datasets
- `vignettes/articles/data-preparation.Rmd` - Guide for preparing data for WJPr functions

### Chart Functions (13 total)
| Function | File | Description |
|----------|------|-------------|
| `wjp_bars()` | barsChart.R | Vertical/horizontal bar charts |
| `wjp_divbars()` | divbarsChart.R | Diverging bar charts |
| `wjp_dots()` | dotsChart.R | Dot plots |
| `wjp_lines()` | lineChart.R | Line charts with points |
| `wjp_slope()` | slopeChart.R | Slope charts for comparisons |
| `wjp_dumbbells()` | dumbellsChart.R | Dumbbell plots |
| `wjp_radar()` | radarChart.R | Radar/spider charts |
| `wjp_rose()` | roseChart.R | Rose/polar bar charts |
| `wjp_gauge()` | gaugeChart.R | Gauge/speedometer charts |
| `wjp_lollipops()` | lollipopChart.R | Lollipop charts |
| `wjp_edgebars()` | edgebarsChart.R | Edge-aligned horizontal bars |
| `wjp_groupbars()` | groupbarsChart.R | Faceted stacked bars by demographic groups |
| `wjp_diffmeans()` | diffmeans.R | Difference in means analysis |

### Styling Conventions
- Font: Lato (loaded via Google Fonts using sysfonts/showtext)
- WJP color palette uses hex codes (e.g., `#2E4057`, `#083D77`, `#F4D35E`)
- Colors are passed via named vectors (`cvec`) where names match grouping variable values
- Always call `wjp_fonts()` before plotting to ensure fonts are available

### Documentation
- Uses Roxygen2 for inline documentation (RoxygenNote: 7.3.2)
- All exported functions need `@export` tag
- Functions are marked with `lifecycle::badge("experimental")` where applicable
- Examples should use the built-in `WJPr::gpp` or `WJPr::roli` datasets

## CI/CD

GitHub Actions workflow (`.github/workflows/pkgdown.yaml`) automatically builds and deploys documentation to GitHub Pages on push to main/master.

## Contributing Guidelines

### Adding New Functions

1. **File naming**: `R/{tipo}Chart.R` (e.g., `R/waterfallChart.R`)
2. **Function naming**: `wjp_{tipo}()` (e.g., `wjp_waterfall()`)
3. **Required parameters**: `data`, `target`, `grouping`
4. **Optional parameters**: `colors`, `cvec`, `labels`, `ptheme = WJP_theme()`

### Function Structure Pattern

```r
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

- [ ] Roxygen2 docs with `@export`, `@param`, `@return`, `@examples`
- [ ] Include `lifecycle::badge("experimental")`
- [ ] Add to `data-raw/generate-examples.R`
- [ ] Update this CLAUDE.md file
- [ ] Run `devtools::document()` and `devtools::check()`

### Documentation Files

- `CONTRIBUTING.md` - Complete contribution guidelines
- `vignettes/articles/development-guide.Rmd` - Step-by-step tutorial
- `.github/ISSUE_TEMPLATE/` - Issue templates
- `.github/pull_request_template.md` - PR template
