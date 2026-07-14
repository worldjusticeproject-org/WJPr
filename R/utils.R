#' Load WJP Fonts
#'
#' @description
#' `wjp_fonts()` loads the standard fonts used in WJP visualizations from Google Fonts.
#' This function should be called once at the beginning of your R session before creating
#' any WJP charts.
#'
#' @details
#' The function loads the following font families:
#' \itemize{
#'   \item \strong{Lato Full}: Regular weight (400) and bold (700)
#'   \item \strong{Lato Light}: Light weight (300) and bold (700)
#'   \item \strong{Lato Black}: Black weight (900)
#'   \item \strong{Inter Tight}: Regular weight (400) and bold (700)
#' }
#'
#' WJPr charts use \strong{Lato Full} by default. To switch every chart and
#' theme to another loaded family (e.g., Inter Tight), set the `wjpr.family`
#' option once per session: `options(wjpr.family = "Inter Tight")`. See
#' [wjp_font_family()].
#'
#' @return No return value, called for side effects. Fonts are registered and
#'   \code{showtext::showtext_auto()} is enabled.
#'
#' @export
#'
#' @examples
#' # Load fonts before creating charts
#' wjp_fonts()
#'
#' # Now you can use the fonts in ggplot2
#' library(ggplot2)
#' ggplot(mtcars, aes(x = mpg, y = wt)) +
#'   geom_point() +
#'   theme(text = element_text(family = "Lato Full"))
#'
wjp_fonts <- function(){

  # Use curl handle if available for better connection handling
  handle <- if (requireNamespace("curl", quietly = TRUE)) {
    curl::new_handle()
  } else {
    NULL
  }

  sysfonts::font_add_google(
    "Lato",
    family     = "Lato Full",
    regular.wt = 400,
    bold.wt    = 700,
    repo       = "https://fonts.gstatic.com/",
    db_cache   = TRUE,
    handle     = handle
  )
  sysfonts::font_add_google(
    "Lato",
    family     = "Lato Light",
    regular.wt = 300,
    bold.wt    = 700,
    repo       = "https://fonts.gstatic.com/",
    db_cache   = TRUE,
    handle     = handle
  )
  sysfonts::font_add_google(
    "Lato",
    family     = "Lato Black",
    regular.wt = 900,
    bold.wt    = 900,
    repo       = "https://fonts.gstatic.com/",
    db_cache   = TRUE,
    handle     = handle
  )
  sysfonts::font_add_google(
    "Inter Tight",
    family     = "Inter Tight",
    regular.wt = 400,
    bold.wt    = 700,
    repo       = "https://fonts.gstatic.com/",
    db_cache   = TRUE,
    handle     = handle
  )
  showtext::showtext_auto()
}


#' WJP Color Palette
#'
#' @description
#' `wjp_palette()` returns the categorical color palette used across World
#' Justice Project visualizations. All WJPr chart functions fall back to this
#' palette when no color vector (`cvec`) is supplied, so charts stay on-brand
#' by default.
#'
#' @details
#' The palette contains nine colors, ordered so that the first three
#' (violet, teal-blue, orange) provide maximum contrast for small categorical
#' sets, followed by the Rule of Law Index factor colors:
#'
#' | Order | Hex code | Usage |
#' |-------|-----------|-------|
#' | 1 | `#482d8b` | Violet (primary) |
#' | 2 | `#2894aa` | Teal-blue (secondary) |
#' | 3 | `#f26b21` | Orange (contrast) |
#' | 4 | `#137b3f` | Green |
#' | 5 | `#869d3b` | Olive |
#' | 6 | `#0f9581` | Teal-green |
#' | 7 | `#1a74b6` | Blue |
#' | 8 | `#8f2e8c` | Magenta |
#' | 9 | `#555659` | Cool gray (neutral) |
#'
#' When more than nine colors are requested, the palette is interpolated with
#' [grDevices::colorRampPalette()].
#'
#' @param n Integer. Number of colors to return. If `NULL` (default), the full
#'   nine-color palette is returned.
#'
#' @return A character vector of hex color codes.
#'
#' @export
#'
#' @examples
#' # Full palette
#' wjp_palette()
#'
#' # First three colors for a small categorical set
#' wjp_palette(3)
#'
wjp_palette <- function(n = NULL) {
  pal <- c("#482d8b", "#2894aa", "#f26b21", "#137b3f", "#869d3b",
           "#0f9581", "#1a74b6", "#8f2e8c", "#555659")
  if (is.null(n)) {
    return(pal)
  }
  if (length(n) != 1 || !is.finite(n) || n < 1) {
    stop("`n` must be a single positive integer.", call. = FALSE)
  }
  n <- as.integer(n)
  if (n <= length(pal)) {
    pal[seq_len(n)]
  } else {
    grDevices::colorRampPalette(pal)(n)
  }
}


#' Build a default named color vector for a grouping variable
#'
#' Maps the WJP palette onto the unique values (or factor levels) of `x`,
#' so charts remain on-brand when the user does not supply `cvec`.
#'
#' @noRd
wjp_default_cvec <- function(x) {
  vals <- if (is.factor(x)) levels(droplevels(x)) else unique(as.character(x))
  vals <- vals[!is.na(vals)]
  stats::setNames(wjp_palette(length(vals)), vals)
}


#' Determine the display order for a categorical legend
#'
#' Factor levels take precedence; otherwise categories retain their first
#' appearance in the data.
#'
#' @param x A categorical vector.
#'
#' @return A character vector of visible legend breaks.
#' @noRd
wjp_legend_breaks <- function(x) {
  vals <- if (is.factor(x)) levels(droplevels(x)) else unique(as.character(x))
  vals[!is.na(vals)]
}


#' Get the Active WJP Font Family
#'
#' @description
#' `wjp_font_family()` returns the font family used by all WJPr chart
#' functions and themes. It defaults to `"Lato Full"` and can be changed
#' globally for the session through the `wjpr.family` option, so a single
#' line switches every chart to another family loaded by [wjp_fonts()]
#' (e.g., Inter Tight).
#'
#' @details
#' Families registered by [wjp_fonts()]: `"Lato Full"` (default),
#' `"Lato Light"`, `"Lato Black"`, and `"Inter Tight"`. Any other family
#' already registered in your session (via [sysfonts::font_add_google()] or
#' similar) can also be used.
#'
#' @return A single string with the active font family.
#'
#' @export
#'
#' @examples
#' # Default family
#' wjp_font_family()
#'
#' # Switch every WJPr chart to Inter Tight for this session
#' options(wjpr.family = "Inter Tight")
#' wjp_font_family()
#'
#' # Back to the default
#' options(wjpr.family = NULL)
#'
wjp_font_family <- function() {
  family <- getOption("wjpr.family", default = "Lato Full")
  if (length(family) != 1 || !is.character(family) || is.na(family)) {
    stop("`options(wjpr.family = )` must be a single string.", call. = FALSE)
  }
  family
}


#' WJP ggplot2 Theme
#'
#' @description
#' `WJP_theme()` returns a ggplot2 theme object that applies the World Justice Project
#' visual style guidelines to charts.
#'
#' @details
#' The theme includes the following style specifications:
#' \itemize{
#'   \item Transparent panel and plot backgrounds
#'   \item Dashed grey grid lines (\code{#5e5c5a})
#'   \item WJP font family for all text elements (Lato Full by default; see
#'     [wjp_font_family()])
#'   \item Text color \code{#524F4C}
#'   \item No axis ticks
#'   \item Zero plot margins
#' }
#'
#' @param family String. Font family for all text elements. Default is the
#'   active WJP font family (see [wjp_font_family()]), which is `"Lato Full"`
#'   unless changed via `options(wjpr.family = )`.
#'
#' @return A ggplot2 theme object that can be added to any ggplot.
#'
#' @export
#'
#' @examples
#' library(ggplot2)
#'
#' # Load fonts first
#' wjp_fonts()
#'
#' # Apply WJP theme to a plot
#' ggplot(mtcars, aes(x = mpg, y = wt)) +
#'   geom_point() +
#'   WJP_theme()
#'
#' # Same plot with Inter Tight
#' ggplot(mtcars, aes(x = mpg, y = wt)) +
#'   geom_point() +
#'   WJP_theme(family = "Inter Tight")
#'
WJP_theme <- function(family = wjp_font_family()) {
  theme(panel.background   = element_blank(),
        plot.background    = element_blank(),
        panel.grid.major   = element_line(linewidth = 0.25,
                                          colour   = "#5e5c5a",
                                          linetype = "dashed"),
        panel.grid.minor   = element_blank(),
        axis.title.y       = element_text(family   = family,
                                          face     = "plain",
                                          size     = 3.514598 * ggplot2::.pt,
                                          color    = "#524F4C",
                                          margin   = margin(0, 10, 0, 0)),
        axis.title.x       = element_text(family   = family,
                                          face     = "plain",
                                          size     = 3.514598 * ggplot2::.pt,
                                          color    = "#524F4C",
                                          margin   = margin(10, 0, 0, 0)),
        axis.text.y        = element_text(family   = family,
                                          face     = "plain",
                                          size     = 3.514598 * ggplot2::.pt,
                                          color    = "#524F4C"),
        axis.text.x = element_text(family = family,
                                   face   = "plain",
                                   size   = 3.514598 * ggplot2::.pt,
                                   color  = "#524F4C"),
        axis.ticks  = element_blank(),
        plot.margin  = unit(c(0, 0, 0, 0), "points")
  )
}


#' Build the shared WJP legend theme
#'
#' Keeps categorical chart legends visually consistent across plot families.
#'
#' @param show_legend Logical. Whether the legend should be displayed.
#'
#' @return A ggplot2 theme object.
#' @noRd
wjp_legend_theme <- function(show_legend = TRUE) {
  if (length(show_legend) != 1 || !is.logical(show_legend) || is.na(show_legend)) {
    stop("`show_legend` must be TRUE or FALSE.", call. = FALSE)
  }

  ggplot2::theme(
    legend.position      = if (show_legend) "top" else "none",
    legend.direction     = "horizontal",
    legend.justification = "left",
    legend.title         = ggplot2::element_blank(),
    legend.key           = ggplot2::element_blank(),
    legend.text          = ggplot2::element_text(
      family = wjp_font_family(),
      face   = "bold",
      size   = 11,
      color  = "#524F4C"
    ),
    legend.key.width     = grid::unit(1.4, "cm"),
    legend.spacing.x     = grid::unit(18, "pt"),
    legend.box.margin    = ggplot2::margin(t = 4, r = 0, b = 20, l = 0)
  )
}
