#' Plot a Bar Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `wjp_bars()` takes a data frame with long-format data and returns a ggplot
#' object with a vertical or horizontal bar chart following WJP style guidelines.
#' Values are expected on a 0-100 percentage scale.
#'
#' @param data Data frame containing the data to plot.
#' @param target String. Column name of the variable that supplies the values to plot.
#' @param grouping String. Column name of the variable that supplies the categories
#'   (X-axis for vertical bars, Y-axis for horizontal bars).
#' @param labels String. Column name of the variable containing the value labels to
#'   display. Default is `NULL` (no labels).
#' @param colors String. Column name of the variable that contains the color grouping.
#'   Default is `NULL` (colors follow `grouping`).
#' @param cvec Named vector of colors. Names should match the values of the `colors`
#'   variable. Default is `NULL` (the WJP palette, see [wjp_palette()], is applied).
#' @param direction String. Either `"vertical"` (default) or `"horizontal"`.
#' @param stacked Logical. If `TRUE`, bars are stacked on top of each other per group.
#'   Default is `FALSE`.
#' @param lab_pos String. Column name of the variable that contains the Y coordinates
#'   for the value labels. Default is `NULL` (labels are placed at the bar value).
#' @param expand Logical. If `TRUE`, the axis is expanded to give extra space for value
#'   labels above 100%. Default is `FALSE`.
#' @param order String. Column name of the variable that contains the display order of
#'   categories. Default is `NULL` (data order).
#' @param width Numeric value between 0 and 1. Width of bars as a fraction of the space
#'   available for each bar. Default is `0.9`.
#' @param ptheme ggplot theme to apply. Default is [WJP_theme()].
#'
#' @return A ggplot object.
#' @export
#'
#' @examples
#' library(dplyr)
#'
#' # Always load the WJP fonts
#' wjp_fonts()
#'
#' # Percentage of people that trust their institutions, by country
#' data4bars <- WJPr::gpp %>%
#'   filter(year == 2022) %>%
#'   mutate(
#'     q1a   = as.double(unclass(q1a)),
#'     trust = case_when(q1a <= 2 ~ 1, q1a <= 4 ~ 0)
#'   ) %>%
#'   group_by(country) %>%
#'   summarise(trust = mean(trust, na.rm = TRUE) * 100, .groups = "drop") %>%
#'   mutate(
#'     value_label    = paste0(round(trust, 0), "%"),
#'     label_position = trust + 6
#'   )
#'
#' # Vertical bars (default)
#' wjp_bars(
#'   data4bars,
#'   target   = "trust",
#'   grouping = "country",
#'   labels   = "value_label",
#'   lab_pos  = "label_position",
#'   cvec     = c("Atlantis"  = "#482d8b",
#'                "Narnia"    = "#2894aa",
#'                "Neverland" = "#f26b21")
#' )
#'
#' # Horizontal bars
#' wjp_bars(
#'   data4bars,
#'   target    = "trust",
#'   grouping  = "country",
#'   labels    = "value_label",
#'   lab_pos   = "label_position",
#'   direction = "horizontal"
#' )
#'
wjp_bars <- function(
    data,
    target,
    grouping,
    labels     = NULL,
    colors     = NULL,
    cvec       = NULL,
    direction  = "vertical",
    stacked    = FALSE,
    lab_pos    = NULL,
    expand     = FALSE,
    order      = NULL,
    width      = 0.9,
    ptheme     = WJP_theme()
){

  if (!direction %in% c("vertical", "horizontal")) {
    stop('`direction` must be one of "vertical" or "horizontal".', call. = FALSE)
  }

  # Renaming variables in the data frame to match the function naming
  data <- data %>%
    dplyr::rename(target_var   = all_of(target),
                  grouping_var = all_of(grouping))

  # Handle labels
  if (is.null(labels)) {
    data <- data %>%
      dplyr::mutate(labels_var = "")
  } else {
    data <- data %>%
      dplyr::rename(labels_var = all_of(labels))
  }

  # Handle lab_pos
  if (is.null(lab_pos)) {
    data <- data %>%
      dplyr::mutate(lab_pos = target_var)
  } else {
    data <- data %>%
      dplyr::rename(lab_pos = all_of(lab_pos))
  }

  # Handle colors
  if (is.null(colors) || identical(grouping, colors)) {
    data <- data %>%
      dplyr::mutate(colors_var = grouping_var)
  } else {
    data <- data %>%
      dplyr::rename(colors_var = all_of(colors))
  }

  # Handle order: reorder categories upfront so a single ggplot block suffices
  if (!is.null(order)) {
    data <- data %>%
      dplyr::rename(order_var = all_of(order)) %>%
      dplyr::mutate(grouping_var = reorder(grouping_var, order_var))
  }

  # Default to the WJP palette when no color vector is supplied
  if (is.null(cvec)) {
    cvec <- wjp_default_cvec(data$colors_var)
  }

  # Extra headroom for value labels
  y_upper <- 110
  if (isTRUE(expand)) {
    max_value <- suppressWarnings(max(c(data$target_var, data$lab_pos), na.rm = TRUE))
    if (is.finite(max_value)) {
      y_upper <- max(110, max_value * 1.05)
    }
  }

  # Creating plot
  plt <- ggplot2::ggplot(data,
                         aes(x     = grouping_var,
                             y     = target_var,
                             label = labels_var,
                             fill  = colors_var)) +
    ggplot2::geom_col(position    = "stack",
                      width       = width,
                      show.legend = FALSE) +
    ggplot2::geom_text(aes(y = lab_pos),
                       color    = if (isTRUE(stacked)) "#ffffff" else "#4a4a49",
                       family   = "Lato Full",
                       fontface = "bold",
                       size     = 3.514598) +
    ggplot2::scale_fill_manual(values = cvec) +
    labs(y = "% of respondents")

  if (direction == "vertical") {
    plt  <- plt +
      ggplot2::scale_y_continuous(limits = c(0, y_upper),
                                  breaks = seq(0, 100, 20),
                                  labels = paste0(seq(0, 100, 20), "%")) +
      ptheme +
      ggplot2::theme(panel.grid.major.x = element_blank(),
                     panel.grid.major.y = element_line(color = "#d1cfd1"),
                     axis.title.x       = element_blank())
  } else {
    plt  <- plt +
      ggplot2::scale_y_continuous(limits   = c(0, y_upper),
                                  breaks   = seq(0, 100, 20),
                                  labels   = paste0(seq(0, 100, 20), "%"),
                                  position = "right") +
      ggplot2::scale_x_discrete(limits = rev) +
      ggplot2::coord_flip() +
      ptheme +
      ggplot2::theme(panel.grid.major.y = element_blank(),
                     panel.grid.major.x = element_line(color = "#d1cfd1"),
                     axis.title.y       = element_blank(),
                     axis.title.x       = element_blank(),
                     axis.text.y        = element_text(hjust = 0))
  }

  return(plt)

}
