#' Plot a Lollipop Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `wjp_lollipops()` takes a data frame with a specific data structure (usually long shaped) and returns a ggplot
#' object with a lollipop chart following WJP style guidelines.
#'
#' @param data A data frame containing the data to be plotted.
#' @param target A string specifying the column name of the variable that contains the numeric values to be plotted.
#' @param grouping A string specifying the column name of the variable that contains the categories for the Y-axis labels.
#' @param order A string specifying the column name of the variable that contains the custom order for displaying categories. Default is NULL (uses row order).
#' @param line_size A numeric value specifying the thickness of the lines. Default is 3.
#' @param point_size A numeric value specifying the size of the points. Default is 4.
#' @param line_color A string specifying the hex color code for the lines. Default is "#c4c4c4".
#' @param point_color A string specifying the hex color code for the points. Default is "#2a2a94".
#'
#' @return A ggplot object representing the lollipop chart.
#' @export
#'
#' @examples
#' library(dplyr)
#' library(ggplot2)
#'
#' # Always load the WJP fonts (optional)
#' wjp_fonts()
#'
#' # Preparing data
#' gpp_data <- WJPr::gpp
#'
#' data4lollipops <- gpp_data %>%
#'   filter(year == 2022, country == "Atlantis") %>%
#'   select(q1a, q1b, q1c, q1d) %>%
#'   mutate(
#'     across(
#'       everything(),
#'       \(x) case_when(
#'         x <= 2 ~ 1,
#'         x <= 4 ~ 0
#'       )
#'     )
#'   ) %>%
#'   summarise(
#'     across(
#'       everything(),
#'       \(x) mean(x, na.rm = TRUE) * 100
#'     )
#'   ) %>%
#'   tidyr::pivot_longer(
#'     everything(),
#'     names_to  = "variable",
#'     values_to = "percentage"
#'   ) %>%
#'   mutate(
#'     institution = case_when(
#'       variable == "q1a" ~ "Institution A",
#'       variable == "q1b" ~ "Institution B",
#'       variable == "q1c" ~ "Institution C",
#'       variable == "q1d" ~ "Institution D"
#'     )
#'   )
#'
#' # Plotting chart
#' wjp_lollipops(
#'   data4lollipops,
#'   target      = "percentage",
#'   grouping    = "institution",
#'   line_color  = "#c4c4c4",
#'   point_color = "#2a2a94"
#' )
#'
wjp_lollipops <- function(
    data,
    target,
    grouping,
    order         = NULL,
    line_size     = 3,
    point_size    = 4,
    line_color    = "#c4c4c4",
    point_color   = "#2a2a94"
) {
  
  # Renaming variables in the data frame to match the function naming
  if (is.null(order)) {
    data <- data %>%
      dplyr::mutate(order_var     = row_number()) %>%
      dplyr::rename(target_var    = all_of(target),
                    grouping_var  = all_of(grouping))
  } else {
    data <- data %>%
      dplyr::rename(target_var    = all_of(target),
                    grouping_var  = all_of(grouping),
                    order_var     = all_of(order))
  }
  
  # Creating plot
  ggplot(data) +
    geom_linerange(
      aes(x    = reorder(grouping_var, order_var),  
          ymin = 0, 
          ymax = target_var), 
      linewidth = line_size,
      color = line_color
    ) +
    geom_point(
      aes(y = target_var, 
          x = reorder(grouping_var, order_var)),
      size  = point_size,
      shape = 16, 
      color = point_color
    ) +
    geom_text(
      aes(y = target_var + 7, 
          x = grouping_var, 
          label = paste0(round(target_var, 0),"%")),
      size     = 3.514598, 
      color    = "black",
      family   = "Lato Full", 
      fontface = "bold"
    ) +
    scale_y_continuous(breaks   = seq(0, 100, by = 10),
                       limits   = c(0,105),
                       labels   = paste0(seq(0, 100, by = 10),"%"), 
                       position = "right") +
    coord_flip() +
    theme_minimal() +
    WJP_theme() +
    theme(
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      panel.grid.major.y = element_blank()
    )
}
