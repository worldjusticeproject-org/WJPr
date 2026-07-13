# WJP Color Palette

`wjp_palette()` returns the categorical color palette used across World
Justice Project visualizations. All WJPr chart functions fall back to
this palette when no color vector (`cvec`) is supplied, so charts stay
on-brand by default.

## Usage

``` r
wjp_palette(n = NULL)
```

## Arguments

- n:

  Integer. Number of colors to return. If `NULL` (default), the full
  nine-color palette is returned.

## Value

A character vector of hex color codes.

## Details

The palette contains nine colors, ordered so that the first three
(violet, teal-blue, orange) provide maximum contrast for small
categorical sets, followed by the Rule of Law Index factor colors:

|       |           |                       |
|-------|-----------|-----------------------|
| Order | Hex code  | Usage                 |
| 1     | `#482d8b` | Violet (primary)      |
| 2     | `#2894aa` | Teal-blue (secondary) |
| 3     | `#f26b21` | Orange (contrast)     |
| 4     | `#137b3f` | Green                 |
| 5     | `#869d3b` | Olive                 |
| 6     | `#0f9581` | Teal-green            |
| 7     | `#1a74b6` | Blue                  |
| 8     | `#8f2e8c` | Magenta               |
| 9     | `#555659` | Cool gray (neutral)   |

When more than nine colors are requested, the palette is interpolated
with
[`grDevices::colorRampPalette()`](https://rdrr.io/r/grDevices/colorRamp.html).

## Examples

``` r
# Full palette
wjp_palette()
#> [1] "#482d8b" "#2894aa" "#f26b21" "#137b3f" "#869d3b" "#0f9581" "#1a74b6"
#> [8] "#8f2e8c" "#555659"

# First three colors for a small categorical set
wjp_palette(3)
#> [1] "#482d8b" "#2894aa" "#f26b21"
```
