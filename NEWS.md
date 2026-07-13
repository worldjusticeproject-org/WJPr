# WJPr 1.1.0

## New features

- New `wjp_palette()` function exposing the official WJP categorical color
  palette. All chart functions now fall back to this palette when no `cvec`
  is supplied, so charts stay on-brand by default (previously they fell back
  to the default ggplot2 hues).
- `wjp_lines()` and `wjp_slope()` no longer require the `ngroups` parameter:
  lines are grouped by the `colors` variable automatically. Both functions
  also work without `colors` (a single series is drawn). `ngroups` is retained
  for backwards compatibility.
- `wjp_dumbbells()` gains an alternating strip background (visual consistency
  with `wjp_dots()`), automatic label positions when `labpos` is not supplied,
  and support for named `cvec` vectors matched against `cgroups`.
- `wjp_lollipops()` gains `labels`, `order`, and `ptheme` parameters. Value
  labels are generated automatically when `labels` is not supplied.
- `wjp_edgebars()` `labels` parameter is now optional and defaults to the
  `grouping` values.
- `wjp_dots()` automatically enables per-group opacities and shapes when
  `opacities` or `shapes` are supplied.
- `wjp_divbars()` enables custom ordering automatically when `order` is
  supplied (the `custom_order` flag is retained for backwards compatibility).

## Parameter harmonization

- `wjp_dumbbells()`: `color` was renamed to `colors` (old name still works).
- `wjp_radar()` and `wjp_rose()`: `order_var` was renamed to `order`
  (old name still works).

## Bug fixes

- Fixed a bug in `wjp_gauge()` where the invisible padding segment received a
  visible palette color when no `cvec` was supplied, drawing a full circle
  instead of a semicircle.
- Fixed a bug in `wjp_dumbbells()` where the `order` parameter was ignored.
- `diffmeans()` now returns its results explicitly (previously the value was
  returned invisibly).
- `wjp_lines()` value labels no longer get clipped when values are close to
  100%: the label flips below the point instead.

## Visual consistency

- Value labels now share the same typography across all charts
  (Lato bold, 10 pt, ink `#4a4a49`).
- Grid lines harmonized to a single gray (`#d1cfd1`) across charts.
- Category axis text harmonized (`#524F4C`, left-aligned) across horizontal
  charts.
- Horizontal charts (`wjp_dots()`, `wjp_dumbbells()`, `wjp_lollipops()`,
  `wjp_edgebars()`) now consistently display the first row of the data at the
  top of the chart.
- `wjp_check_data()` gains support for `type = "groupbars"`.
- `wjp_groupbars()`: when confidence intervals are drawn, value labels are now
  placed at the end of the full bar (after the gray complement), aligned in a
  single column, instead of next to the upper interval whisker.

# WJPr 1.0.1

- Updated `wjp_groupbars()` documentation and gallery images to show the corrected grouped-bar layout with neutral complement bars, confidence intervals, a national bar, and an optional percentage axis.

# WJPr 1.0.0

- Fixed bugs preventing `wjp_radar()` to plot specific data structures.
- Fixed bugs preventing `wjp_dots()` to plot specific data structures.
- Change the way that `wjp_dots()` calculated and added Confidence Intervals to charts.
- `wjp_slope()` added.
- `diff_means()` added.

# WJPr 0.0.0

- Initial base release 
