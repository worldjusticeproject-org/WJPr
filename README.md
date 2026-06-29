# WJPr

WJPr is an R package developed to streamline data analysis and visualization for the Data Analytics Unit at The World Justice Project (WJP). This package includes essential data and tools for replicating visualizations from WJP Country Reports and analyzing Rule of Law Index scores.

## Features

**Version 1.0.0** of WJPr offers:

- A wide range of visualization functions to recreate WJP Country Report charts, such as bar plots, line graphs, and radar charts.
- Access to Rule of Law Index scores data, including detailed information for all factors and subfactors.
- Streamlined tools for generating publication-ready graphics.

## Installation

WJPr is hosted on GitHub. To install the package, ensure you have the `devtools` package installed and use the following commands:

```R
# Install WJPr from GitHub
devtools::install_github("worldjusticeproject-org/WJPr")
```

## Usage

Load the package into your R session:

```R
library(WJPr)
```

### Example: Accessing Rule of Law Index Data

The package provides built-in datasets for analysis:

```R
# View the first few rows of the dataset
head(WJPr::roli)
```

### Example: Creating a Visualization

Here is an example of how to use WJPr to create a bar chart:

```R
# Always load the WJP fonts if not passing a custom theme to function
wjp_fonts()

# Loading data
gpp_data <- WJPr::gpp

# Prepare the data
data4bars <- gpp_data %>%
  select(country, year, q1a) %>%
  group_by(country, year) %>%
  mutate(
    q1a = as.double(q1a),
    trust = case_when(
      q1a <= 2  ~ 1,
      q1a <= 4  ~ 0,
      q1a == 99 ~ NA_real_
    ),
    year = as.character(year)
  ) %>%
  summarise(
    trust   = mean(trust, na.rm = TRUE),
    .groups = "keep"
  ) %>%
  mutate(
    trust = trust*100
  ) %>%
  filter(year == "2022")

# Draw the chart
wjp_bars(
    data4bars,              
    target    = "trust",        
    grouping  = "country",
    colors    = "year",
    cvec      = c("2022" = "#8789C0")
)
```

## Chart Gallery

WJPr provides 12 chart types for creating publication-ready visualizations:

| | | |
|:---:|:---:|:---:|
| **Bar Chart** | **Dots Chart** | **Line Chart** |
| <img src="man/figures/example-bars.png" width="200" alt="Example vertical bar chart"/> | <img src="man/figures/example-dots.png" width="200" alt="Example dot chart"/> | <img src="man/figures/example-lines.png" width="200" alt="Example line chart"/> |
| `wjp_bars()` | `wjp_dots()` | `wjp_lines()` |
| **Diverging Bars** | **Dumbbells** | **Slope Chart** |
| <img src="man/figures/example-divbars.png" width="200" alt="Example diverging bar chart"/> | <img src="man/figures/example-dumbbells.png" width="200" alt="Example dumbbell chart"/> | <img src="man/figures/example-slope.png" width="200" alt="Example slope chart"/> |
| `wjp_divbars()` | `wjp_dumbbells()` | `wjp_slope()` |
| **Radar Chart** | **Rose Chart** | **Gauge Chart** |
| <img src="man/figures/example-radar.png" width="200" alt="Example radar chart"/> | <img src="man/figures/example-rose.png" width="200" alt="Example rose chart"/> | <img src="man/figures/example-gauge.png" width="200" alt="Example gauge chart"/> |
| `wjp_radar()` | `wjp_rose()` | `wjp_gauge()` |
| **Lollipop Chart** | **Edgebars** | **Grouped Bars** |
| <img src="man/figures/example-lollipops.png" width="200" alt="Example lollipop chart"/> | <img src="man/figures/example-edgebars.png" width="200" alt="Example edge bar chart"/> | <img src="man/figures/example-groupbars.png" width="200" alt="Example grouped bar chart"/> |
| `wjp_lollipops()` | `wjp_edgebars()` | `wjp_groupbars()` |

For a complete interactive gallery with code examples, see the [Chart Gallery vignette](https://worldjusticeproject-org.github.io/WJPr/articles/gallery.html).

## Data Structure

All WJPr visualization functions expect data in **long (tidy) format**:

```
| grouping     | target | colors   | labels (optional) |
|--------------|--------|----------|-------------------|
| Category A   | 45.2   | Group 1  | "45%"             |
| Category B   | 32.1   | Group 1  | "32%"             |
| Category A   | 51.0   | Group 2  | "51%"             |
| Category B   | 38.5   | Group 2  | "39%"             |
```

**Key parameters used across all functions:**

| Parameter  | Description                          | Type            |
|------------|--------------------------------------|-----------------|
| `target`   | Values to plot (Y-axis)              | Numeric column  |
| `grouping` | Categories (X-axis or rows)          | Character/Factor|
| `colors`   | Variable for color grouping          | Character/Factor|
| `cvec`     | Named vector mapping values to colors| `c("A" = "#HEX")`|
| `labels`   | Text labels to display               | Character column|

### Validate Your Data

Use `wjp_check_data()` to verify your data structure before plotting:

```R
wjp_check_data(
  data     = my_data,
  type     = "bars",
  target   = "value",
  grouping = "category",
  colors   = "group",
  cvec     = c("Group 1" = "#2E4057", "Group 2" = "#F4D35E")
)
```

For detailed guidance, see the [Data Preparation vignette](https://worldjusticeproject-org.github.io/WJPr/articles/data-preparation.html).

## Documentation

Comprehensive documentation is available for all functions and datasets. Use the R help system to access it:

```R
?WJPr::wjp_lines
```

## Contributing

Contributions are welcome! Before contributing, please read our guidelines:

### Quick Start

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-chart`
3. Follow the coding conventions in [CONTRIBUTING.md](CONTRIBUTING.md)
4. Submit a pull request

### Adding New Functions

All visualization functions must follow the WJPr patterns:

```r
wjp_newchart <- function(
    data,
    target,
    grouping,
    colors    = NULL,
    cvec      = NULL,
    labels    = NULL,
    ptheme    = WJP_theme()
) {
  # 1. Rename columns using all_of()
  # 2. Handle NULL parameters
  # 3. Create ggplot
  # 4. Apply colors if cvec provided
  # 5. Apply theme
  return(plt)
}
```

### Documentation Requirements

- Roxygen2 with `@export`, `@param`, `@return`, `@examples`
- Include `lifecycle::badge("experimental")` in description
- Add example to `data-raw/generate-examples.R`
- Update `CLAUDE.md`

### Resources

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Complete contribution guidelines
- **[Development Guide](https://worldjusticeproject-org.github.io/WJPr/articles/development-guide.html)** - Step-by-step tutorial
- **[Issues](https://github.com/worldjusticeproject-org/WJPr/issues)** - Report bugs or request features

## License

This project is licensed under the MIT License. See the `LICENSE.md` file for details.

## Acknowledgments

WJPr was developed by the Data Analytics Unit at The World Justice Project. Special thanks to the whole team for their invaluable input in creating this package.
