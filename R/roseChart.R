#' Plot a Rose Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' 
#' `wjp_rose()` takes a data frame with a specific data structure (usually long shaped) and returns a ggplot
#' object with a rose chart following WJP style guidelines.
#'
#' @param data A data frame containing the data to be plotted.
#' @param target A string specifying the variable in the data frame that contains the values to be plotted.
#' @param grouping A string specifying the variable in the data frame that contains the groups for the axis.
#' @param labels A string specifying the variable in the data frame that contains the labels to be displayed.
#' @param cvec A vector of colors to apply to lines.
#' @param order_var A string specifying the variable in the data frame that contains the display order of categories. Default is NULL.
#'
#' @return A ggplot object representing the rose chart.
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
#' data4rose <- gpp_data %>%
#' select(starts_with("q49")) %>%
#'   mutate(
#'     across(starts_with("q49"), \(x) as.double(unclass(x))),
#'     across(
#'       starts_with("q49"),
#'       \(x) case_when(
#'         x <= 2  ~ 1,
#'         x <= 99 ~ 0
#'       )
#'     )
#'   ) %>%
#'   summarise(
#'     across(
#'       starts_with("q49"),
#'       \(x) mean(x, na.rm = TRUE)*100
#'     )
#'   ) %>%
#'   pivot_longer(
#'     everything(),
#'     names_to  = "category",
#'     values_to = "percentage"
#'   ) %>%
#'   mutate(
#'     axis_label = category
#'   )
#' 
#' # Plotting chart
#' wjp_rose(
#'   data4rose,             
#'   target    = "percentage",       
#'   grouping  = "category",    
#'   labels    = "axis_label",
#'   cvec      = c("#482d8b", "#2894aa", "#f26b21",
#'                 "#137b3f", "#869d3b", "#0f9581",
#'                 "#1a74b6", "#8f2e8c", "#555659")
#' )
#' 

wjp_rose <- function(
    data,             
    target,       
    grouping,    
    labels,
    cvec      = NULL,           
    order_var = NULL
){
  
  # Renaming variables in the data frame to match the function naming
  data <- data %>%
    rename(
      target_var    = all_of(target),
      grouping_var  = all_of(grouping),
      alabels_var   = all_of(labels),
    )

  max_target <- suppressWarnings(max(abs(data$target_var), na.rm = TRUE))
  if (is.finite(max_target) && max_target > 1) {
    data <- data %>%
      mutate(target_var = target_var / 100)
  }
  
  if (is.null(order_var)){
    data <- data %>%
      arrange(target_var) %>%
      mutate(order_var = row_number())
    
    if (!is.null(cvec)) {
      names(cvec) <- data %>%
        arrange(target_var) %>%
        pull(grouping_var)
    }
  } else {
    data <- data %>%
      rename(order_var = all_of(order_var))
  }

  
  # Creating ggplot
  plt <- ggplot(data = data, 
                aes(x = alabels_var,
                    y = target_var)) +
    geom_segment(aes(x    = reorder(alabels_var, order_var),
                     y    = 0,
                     xend = reorder(alabels_var, order_var),
                     yend = 0.1),
                 linetype = "solid",
                 color    = "#d1cfd1") +
    geom_hline(yintercept = seq(0, 1, by = 0.2), 
               colour     = "#d1cfd1", 
               linetype   = "dashed",
               linewidth  = 0.45) +
    geom_col(aes(x        = reorder(alabels_var, order_var),
                 y        = target_var,
                 fill     = grouping_var),
             position     = "dodge2",
             show.legend  = FALSE)

  # Add labels - use ggtext if available for rich formatting
  if (requireNamespace("ggtext", quietly = TRUE)) {
    plt <- plt +
      ggtext::geom_richtext(aes(y       = 1.3,
                        label   = alabels_var),
                    family      = "Lato Full",
                    fontface    = "plain",
                    color       = "#000000",
                    fill        = NA,
                    label.color = NA)
  } else {
    plt <- plt +
      geom_text(aes(y     = 1.3,
                    label = alabels_var),
                family   = "Lato Full",
                fontface = "plain",
                color    = "#000000")
  }

  plt <- plt +
    coord_polar(clip = "off") +
    scale_y_continuous(
      limits = c(-0.1, 1.35),
      breaks = c(0, 0.2, 0.4, 0.6, 0.8, 1)
    )
  
  if (!is.null(cvec)) {
    plt <- plt +
      scale_fill_manual(values  = cvec)
  }
  
  plt <- plt +
    WJP_theme() +
    theme(legend.position    = "none",
          axis.line.x        = element_blank(),
          axis.line.y.left   = element_blank(),
          axis.text.y        = element_blank(),
          axis.text.x        = element_blank(),
          axis.title.x       = element_blank(),
          axis.title.y       = element_blank(), 
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_blank()) 
  
  return(plt)
  
}
