#' Plot a Bar Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' 
#' `wjp_bars()` takes a data frame with a specific data structure (usually long shaped) and returns a ggplot
#' object with a bar chart following WJP style guidelines.
#'
#' @param data Data frame containing the data to plot
#' @param target String. Column name of the variable that will supply the values to plot.
#' @param grouping String. Column name of the variable that supplies the grouping values. Values can be grouped either in the X- or Y- Axis.
#' @param labels String. Column name of the variable containing the value labels to display in plot. Default is NULL.
#' @param colors String. Column name of the variable that contains the color grouping. Default is NULL.
#' @param cvec Named vector with the colors to apply to bars. Vector names should have the values specified by the "colors" variables, while vector values should have 
#' @param direction String. Should the bars be plotted in a "horizontal" or "vertical" way? Default is "vertical".
#' @param stacked Boolean. If TRUE, bars will be stacked on top of each other per group. Default is FALSE.
#' @param lab_pos String. Column name of the variable that contains the coordinates for the value labels. Default is NULL.
#' @param expand Boolean. If TRUE, the plot will give extra space for value labels. Default is FALSE.
#' @param order String. Column name of the variable that contains the custom order for labels.
#' @param width Numeric value between 0 and 1. Width of bars as a percentage of the space for each bar. Default is 0.9.
#' @param ptheme ggplot theme function to apply to the plot. By default, function applies WJP_theme()
#'
#' @returns A ggplot object
#' @export
#'
#' @examples
#' library(dplyr)
#' library(tidyr)
#' library(haven)
#' library(ggplot2)
#' 
#' # Always load the WJP fonts (optional)
#' wjp_fonts()
#' 
#' # Preparing data
#' gpp_data <- WJPr::gpp
#' 
#' data4bars <- gpp_data %>%
#'   select(country, year, q1a) %>%
#'   group_by(country, year) %>%
#'   mutate(
#'     q1a = as.double(unclass(q1a)),
#'     trust = case_when(
#'       q1a <= 2  ~ 1,
#'       q1a <= 4  ~ 0,
#'       q1a == 99 ~ NA_real_
#'     ),
#'     year = as.character(year)
#'   ) %>%
#'   summarise(
#'     trust   = mean(trust, na.rm = TRUE),
#'     .groups = "keep"
#'   ) %>%
#'   mutate(
#'     trust = trust*100
#'   ) %>%
#'   filter(year == "2022") %>%
#'   mutate(
#'     color_variable = country,
#'     value_label = paste0(
#'       format(
#'         round(trust, 0),
#'         nsmall = 0
#'       ),
#'       "%"
#'     ),
#'     label_position = trust + 5
#'   )
#' 
#' # Plotting chart
#' wjp_bars(
#'   data4bars,              
#'   target    = "trust",        
#'   grouping  = "country",
#'   labels    = "value_label",
#'   lab_pos   = "label_position",
#'   colors    = "color_variable",
#'   cvec      = c("Atlantis"  = "#482d8b",
#'                 "Narnia"    = "#2894aa",
#'                 "Neverland" = "#f26b21")
#'   )
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
  
  # Renaming variables in the data frame to match the function naming
  # Always rename target and grouping
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
  if (is.null(colors)) {
    data <- data %>%
      dplyr::mutate(colors_var = grouping_var)
  } else if (grouping == colors) {
    data <- data %>%
      dplyr::mutate(colors_var = grouping_var)
  } else {
    data <- data %>%
      dplyr::rename(colors_var = all_of(colors))
  }

  # Handle order
  if (!is.null(order)) {
    data <- data %>%
      dplyr::rename(order_var = all_of(order))
  }

  y_upper <- 110
  if (isTRUE(expand)) {
    max_value <- suppressWarnings(max(c(data$target_var, data$lab_pos), na.rm = TRUE))
    if (is.finite(max_value)) {
      y_upper <- max(110, max_value * 1.05)
    }
  }
  
  # Creating plot
  if(is.null(order)) {
    
    if (stacked == FALSE) {
      plt <- ggplot2::ggplot(data, 
                             aes(x     = grouping_var,
                                 y     = target_var,
                                 label = labels_var,
                                 fill  = colors_var)) +
        ggplot2::geom_bar(stat  = "identity",
                          width = width,
                          show.legend = FALSE) +
        ggplot2::geom_text(aes(y    = lab_pos),
                           color    = "#4a4a49",
                           family   = "Lato Full",
                           fontface = "bold")
    } else {
      plt <- ggplot2::ggplot(data, 
                    aes(x     = grouping_var,
                        y     = target_var,
                        label = labels_var,
                        fill  = colors_var)) +
        ggplot2::geom_bar(stat         = "identity",
                          position     = "stack", 
                          show.legend  = FALSE,
                          width        = width) +
        ggplot2::geom_text(aes(y       = lab_pos),
                           color       = "#ffffff",
                           family      = "Lato Full",
                           fontface    = "bold")
    }
    
  } else {
    
    if (stacked == FALSE) {
      plt <- ggplot2::ggplot(data, 
                             aes(x     = reorder(grouping_var, order_var),
                                 y     = target_var,
                                 label = labels_var,
                                 fill  = colors_var)) +
        ggplot2::geom_bar(stat = "identity",
                          show.legend = FALSE,  width = width) +
        ggplot2::geom_text(aes(y    = lab_pos),
                           color    = "#4a4a49",
                           family   = "Lato Full",
                           fontface = "bold")
    } else {
      plt <- ggplot2::ggplot(data, 
                             aes(x     = reorder(grouping_var, order_var),
                                 y     = target_var,
                                 label = labels_var,
                                 fill  = colors_var)) +
        ggplot2::geom_bar(stat         = "identity",
                          position     = "stack", 
                          show.legend  = FALSE,  width = width) +
        ggplot2::geom_text(aes(y    = lab_pos),
                           color    = "#ffffff",
                           family   = "Lato Full",
                           fontface = "bold")
    }
  }
  
  plt <- plt +
    labs(y = "% of respondents")
  
  if (!is.null(cvec)) {
    plt <- plt +
      ggplot2::scale_fill_manual(values = cvec)
  }
  
  if (direction == "vertical") {
    plt  <- plt +
      ggplot2::scale_y_continuous(limits = c(0, y_upper),
                                  breaks = seq(0,100,20),
                                  labels = paste0(seq(0,100,20), "%")) +
      ptheme +
      ggplot2::theme(panel.grid.major.x = element_blank(),
                     panel.grid.major.y = element_line(color = "#D0D1D3"),
                     axis.title.x       = element_blank())
  }
  
  if (direction == "horizontal") {
    plt  <- plt +
      ggplot2::scale_y_continuous(limits = c(0, y_upper),
                                  breaks = seq(0,100,20),
                                  labels = paste0(seq(0,100,20), "%"),
                                  position = "right") +
      ggplot2::scale_x_discrete(limits = rev) +
      ggplot2::coord_flip() +
      ptheme +
      ggplot2::theme(panel.grid.major.y = element_blank(),
                     panel.grid.major.x = element_line(color = "#D0D1D3"),
                     axis.title.y       = element_blank(),
                     axis.title.x       = element_blank(),
                     axis.text.y        = element_text(hjust = 0))
  }
  
  return(plt)
  
}
