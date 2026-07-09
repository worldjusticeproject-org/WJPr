#' Plot a Gauge Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `wjp_gauge()` creates a gauge (speedometer) chart using ggplot2 based on the provided data frame.
#' The chart displays segments in a semicircle, useful for showing composition or progress.
#'
#' @param data A data frame containing the data to be plotted.
#' @param target A string specifying the variable in the data frame that contains the values to be plotted.
#' @param colors A string specifying the variable in the data frame that represents the color groupings for the segments.
#' @param cvec A named vector of colors to apply to the segments. Names should match the values in the colors column.
#' @param factor_order A vector specifying the order in which the segments should be plotted. Default is NULL.
#' @param labels A string specifying the variable in the data frame that contains the labels to be displayed. Default is NULL.
#' @param crop A numeric vector specifying the amount of space to crop from the Top, Right, Bottom, and Left margins, respectively. Default is c(-10,0,0,-8).
#' @param ptheme A ggplot2 theme object to be applied to the plot. Default is WJP_theme().
#'
#' @return A ggplot object representing the gauge chart.
#' @export
#'
#' @examples
#' library(dplyr)
#' library(ggplot2)
#'
#' # Always load the WJP fonts (optional)
#' wjp_fonts()
#'
#' # Create sample data for gauge chart
#' data4gauge <- data.frame(
#'   category = c("Category A", "Category B", "Category C", "Category D"),
#'   value = c(25, 35, 20, 20),
#'   label = c("25%", "35%", "20%", "20%")
#' )
#'
#' # Define colors for each segment
#' gauge_colors <- c(
#'   "Category A" = "#482d8b",
#'   "Category B" = "#2894aa",
#'   "Category C" = "#f26b21",
#'   "Category D" = "#555659"
#' )
#'
#' # Plotting chart
#' wjp_gauge(
#'   data4gauge,
#'   target       = "value",
#'   colors       = "category",
#'   cvec         = gauge_colors,
#'   factor_order = c("Category A", "Category B", "Category C", "Category D"),
#'   labels       = "label"
#' )
#'

wjp_gauge <- function(
    data,                    
    target,             
    colors,
    cvec           = NULL,
    factor_order   = NULL,
    labels         = NULL,
    crop           = c(-10,0,0,-8),
    ptheme         = WJP_theme()
){
  
  # Renaming variables in the data frame to match the function naming
  if (is.null(labels)) {
    data <- data %>%
      mutate(labels_var    = "") %>%
      rename(
        target_var    = all_of(target),
        colors_var    = all_of(colors)
      )
  } else {
    data <- data %>%
      rename(
        target_var    = all_of(target),
        colors_var    = all_of(colors),
        labels_var    = all_of(labels)
      )
  }
  
  
  # Sorting values if necessary
  if (!is.null(factor_order)){
    data <- data %>%
      ungroup() %>%
      mutate(
        colors_var = factor(
          colors_var,
          levels  = factor_order,
          ordered = TRUE
        )
      ) %>%
      arrange(colors_var)
  }
  
  # Getting coordinates
  data <- data %>%
    ungroup() %>%
    mutate(
      ymax       = cumsum(target_var),
      ymin       = ymax-target_var,
      labpos     = ymin  + ((ymax-ymin)/2),
      labels_var = if_else(target_var >= 5, 
                           labels_var,
                           "")
    )
  
  # Calculate total for scaling

  total_value <- sum(data$target_var)
  if (!is.finite(total_value) || total_value <= 0) {
    stop("`target` values must sum to a positive finite value.", call. = FALSE)
  }

  # Scale values to span 180 degrees (half circle)
  # We'll use 0-100 for the data and add padding to make it a semicircle
  data <- data %>%
    mutate(
      # Scale to half circle (values span 0 to 50, padding spans 50 to 100)
      scaled_val = (target_var / total_value) * 50,
      ymax       = cumsum(scaled_val),
      ymin       = ymax - scaled_val,
      labpos     = ymin + ((ymax - ymin) / 2)
    )

  # Add invisible padding segment to complete the circle
  padding_data <- data.frame(
    colors_var = "___padding___",
    target_var = 0,
    labels_var = "",
    scaled_val = 50,
    ymin       = 50,
    ymax       = 100,
    labpos     = 75
  )

  data <- dplyr::bind_rows(data, padding_data)

  # Add padding color (transparent)
  if (!is.null(cvec)) {
    cvec <- c(cvec, "___padding___" = "transparent")
  } else {
    palette <- c("#482d8b", "#2894aa", "#f26b21", "#0f9581", "#555659")
    cvec <- stats::setNames(rep(palette, length.out = length(unique(data$colors_var))), unique(data$colors_var))
    cvec <- c(cvec, "___padding___" = "transparent")
  }

  # Drawing chart
  plt <- ggplot(
    data,
    aes(fill = colors_var,
        ymax = ymax,
        ymin = ymin,
        xmax = 2,
        xmin = 1)
  ) +
    geom_rect(show.legend = FALSE) +
    geom_text(
      data = data %>% dplyr::filter(colors_var != "___padding___"),
      aes(label = labels_var,
          y     = labpos,
          x     = 1.5),
      color     = "white",
      size      = 1.866058 * ggplot2::.pt,
      family    = "Lato Full",
      fontface  = "bold"
    ) +
    scale_x_continuous(limits = c(0, 2)) +
    scale_y_continuous(limits = c(0, 100)) +
    scale_fill_manual(values = cvec) +
    coord_polar(theta = "y", start = pi) +
    ptheme +
    labs(y = "", x = "") +
    theme(
      legend.position    = "none",
      plot.margin        = grid::unit(crop, "mm"),
      panel.grid.major   = element_blank(),
      panel.background   = element_blank(),
      axis.title.x       = element_blank(),
      axis.text.x        = element_blank(),
      axis.text.y        = element_blank(),
      aspect.ratio       = 0.5
    )

  return(plt)
}
