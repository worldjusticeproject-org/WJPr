# Get the Active WJP Font Family

`wjp_font_family()` returns the font family used by all WJPr chart
functions and themes. It defaults to `"Lato Full"` and can be changed
globally for the session through the `wjpr.family` option, so a single
line switches every chart to another family loaded by
[`wjp_fonts()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_fonts.md)
(e.g., Inter Tight).

## Usage

``` r
wjp_font_family()
```

## Value

A single string with the active font family.

## Details

Families registered by
[`wjp_fonts()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_fonts.md):
`"Lato Full"` (default), `"Lato Light"`, `"Lato Black"`, and
`"Inter Tight"`. Any other family already registered in your session
(via
[`sysfonts::font_add_google()`](https://rdrr.io/pkg/sysfonts/man/font_add_google.html)
or similar) can also be used.

There are three ways to control the font of a WJPr chart:

1.  **Whole session**: `options(wjpr.family = "Inter Tight")`. Every
    chart created afterwards (axis text, value labels, and legends) uses
    the new family. Reset with `options(wjpr.family = NULL)`.

2.  **A single chart**: wrap the call with
    `withr::with_options(list(wjpr.family = "Inter Tight"), ...)` so the
    rest of the session keeps the default.

3.  **Theme elements only**: pass
    `ptheme = WJP_theme(family = "Inter Tight")` to a chart function.
    Note this changes axis text and titles only; value labels drawn
    inside the chart read the session option at call time, so use
    approaches 1 or 2 to switch the complete chart.

## Examples

``` r
# Default family
wjp_font_family()
#> [1] "Lato Full"

# Switch every WJPr chart to Inter Tight for this session
options(wjpr.family = "Inter Tight")
wjp_font_family()
#> [1] "Inter Tight"

# Back to the default
options(wjpr.family = NULL)
```
