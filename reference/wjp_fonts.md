# Load WJP Fonts

`wjp_fonts()` loads the standard fonts used in WJP visualizations from
Google Fonts. This function should be called once at the beginning of
your R session before creating any WJP charts.

## Usage

``` r
wjp_fonts()
```

## Value

No return value, called for side effects. Fonts are registered and
[`showtext::showtext_auto()`](https://rdrr.io/pkg/showtext/man/showtext_auto.html)
is enabled.

## Details

The function loads the following font families:

- **Lato Full**: Regular weight (400) and bold (700)

- **Lato Light**: Light weight (300) and bold (700)

- **Lato Black**: Black weight (900)

- **Inter Tight**: Regular weight (400) and bold (700)

WJPr charts use **Lato Full** by default. To switch every chart and
theme to another loaded family (e.g., Inter Tight), set the
`wjpr.family` option once per session:
`options(wjpr.family = "Inter Tight")`. See
[`wjp_font_family()`](https://worldjusticeproject-org.github.io/WJPr/reference/wjp_font_family.md).

## Examples

``` r
# Load fonts before creating charts
wjp_fonts()

# Now you can use the fonts in ggplot2
library(ggplot2)
ggplot(mtcars, aes(x = mpg, y = wt)) +
  geom_point() +
  theme(text = element_text(family = "Lato Full"))

```
