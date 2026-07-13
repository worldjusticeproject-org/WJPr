#' Plot a Lollipop Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `wjp_lollipops()` takes a data frame with long-format data and returns a
#' ggplot object with a lollipop chart following WJP style guidelines.
#' Lollipop charts are a minimalist alternative to horizontal bar charts.
#' Values are expected on a 0-100 percentage scale.
#'
#' @param data Data frame containing the data to plot.
#' @param target String. Column name of the variable that supplies the values to plot.
#' @param grouping String. Column name of the variable that supplies the categories
#'   (Y-axis labels).
#' @param labels String. Column name of the variable containing the value labels to
#'   display. Default is `NULL` (labels are generated automatically as rounded
#'   percentages).
#' @param order String. Column name of the variable that contains the display order of
#'   categories. Default is `NULL` (data order).
#' @param line_size Numeric. Thickness of the lines. Default is `3`.
#' @param point_size Numeric. Size of the points. Default is `4`.
#' @param line_color String. Hex code for the lines. Default is `"#d9dde3"`.
#' @param point_color String. Hex code for the points. Default is `"#482d8b"`.
#' @param ptheme ggplot theme to apply. Default is [WJP_theme()].
#'
#' @return A ggplot object representing the lollipop chart.
#' @export
#'
#' @examples
#' library(dplyr)
#' library(tidyr)
#'
#' # Always load the WJP fonts
#' wjp_fonts()
#'
#' # Percentage of people that trust their institutions in Atlantis
#' data4lollipops <- WJPr::gpp %>%
#'   filter(year == 2022, country == "Atlantis") %>%
#'   select(q1a, q1b, q1c, q1d) %>%
#'   mutate(
#'     across(everything(), \(x) as.double(unclass(x))),
#'     across(everything(), \(x) case_when(x <= 2 ~ 1, x <= 4 ~ 0))
#'   ) %>%
#'   summarise(across(everything(), \(x) mean(x, na.rm = TRUE) * 100)) %>%
#'   pivot_longer(everything(), names_to = "variable", values_to = "percentage") %>%
#'   mutate(
#'     institution = case_when(
#'       variable == "q1a" ~ "Institution A",
#'       variable == "q1b" ~ "Institution B",
#'       variable == "q1c" ~ "Institution C",
#'       variable == "q1d" ~ "Institution D"
#'     )
#'   )
#'
#' wjp_lollipops(
#'   data4lollipops,
#'   target   = "percentage",
#'   grouping = "institution"
#' )
#'
wjp_lollipops <- function(
    data,
    target,
    grouping,
    labels        = NULL,
    order         = NULL,
    line_size     = 3,
    point_size    = 4,
    line_color    = "#d9dde3",
    point_color   = "#482d8b",
    ptheme        = WJP_theme()
) {

  # Renaming variables in the data frame to match the function naming
  data <- data %>%
    dplyr::rename(target_var   = all_of(target),
                  grouping_var = all_of(grouping))

  if (is.null(order)) {
    data <- data %>%
      dplyr::mutate(order_var = row_number())
  } else {
    data <- data %>%
      dplyr::rename(order_var = all_of(order))
  }

  # Value labels: use the supplied column or fall back to rounded percentages
  if (is.null(labels)) {
    data <- data %>%
      dplyr::mutate(labels_var = paste0(round(target_var, 0), "%"))
  } else {
    data <- data %>%
      dplyr::rename(labels_var = all_of(labels))
  }

  # Creating plot
  plt <- ggplot(data) +
    geom_linerange(
      aes(x    = reorder(grouping_var, -order_var),
          ymin = 0,
          ymax = target_var),
      linewidth = line_size,
      color     = line_color
    ) +
    geom_point(
      aes(y = target_var,
          x = reorder(grouping_var, -order_var)),
      size  = point_size,
      shape = 16,
      color = point_color
    ) +
    geom_text(
      aes(y     = target_var + 7,
          x     = reorder(grouping_var, -order_var),
          label = labels_var),
      size     = 3.514598,
      color    = "#4a4a49",
      family   = "Lato Full",
      fontface = "bold"
    ) +
    scale_y_continuous(breaks   = seq(0, 100, by = 20),
                       limits   = c(0, 105),
                       labels   = paste0(seq(0, 100, by = 20), "%"),
                       position = "right") +
    coord_flip() +
    ptheme +
    theme(
      axis.title.x       = element_blank(),
      axis.title.y       = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_line(color = "#d1cfd1"),
      axis.text.y        = element_text(color = "#524F4C",
                                        hjust = 0)
    )

  return(plt)
}
