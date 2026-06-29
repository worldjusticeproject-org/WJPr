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
#'   \item Lato Full font family for all text elements
#'   \item Text color \code{#524F4C}
#'   \item No axis ticks
#'   \item Zero plot margins
#' }
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
WJP_theme <- function() {
  theme(panel.background   = element_blank(),
        plot.background    = element_blank(),
        panel.grid.major   = element_line(linewidth = 0.25,
                                          colour   = "#5e5c5a",
                                          linetype = "dashed"),
        panel.grid.minor   = element_blank(),
        axis.title.y       = element_text(family   = "Lato Full",
                                          face     = "plain",
                                          size     = 3.514598 * ggplot2::.pt,
                                          color    = "#524F4C",
                                          margin   = margin(0, 10, 0, 0)),
        axis.title.x       = element_text(family   = "Lato Full",
                                          face     = "plain",
                                          size     = 3.514598 * ggplot2::.pt,
                                          color    = "#524F4C",
                                          margin   = margin(10, 0, 0, 0)),
        axis.text.y        = element_text(family   = "Lato Full",
                                          face     = "plain",
                                          size     = 3.514598 * ggplot2::.pt,
                                          color    = "#524F4C"),
        axis.text.x = element_text(family = "Lato Full",
                                   face   = "plain",
                                   size   = 3.514598 * ggplot2::.pt,
                                   color  = "#524F4C"),
        axis.ticks  = element_blank(),
        plot.margin  = unit(c(0, 0, 0, 0), "points")
  ) 
}
