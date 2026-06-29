#' Plot a Diverging Horizontal Bar Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' 
#' `wjp_divbars()` takes a data frame with a specific data structure (usually long shaped) and returns a ggplot
#' object with a diverging horizontal bar chart following WJP style guidelines.
#' 
#' @param data Data frame containing the data to plot
#' @param target String. Column name of the variable that will supply the values to plot.
#' @param grouping String. Column name of the variable that supplies the grouping values (Y-Axis Labels).
#' @param diverging String. Column name of the variable that supplies the diverging values.
#' @param negative String. Value that indicates that the bar should be in the negative quadrant.
#' @param cvec Named vector with the colors to apply to each bar segment. Default is NULL.
#' @param labels String. Column name of the variable that supplies the labels to show in the plot. Default is NULL.
#' @param label_color String. Hex code to be use for the labels.
#' @param custom_order Boolean. If TRUE, the plot will expect a custom order of the graph labels. Default is FALSE.
#' @param order String. Vector that contains the custom order for the y-axis labels. Default is NULL.
#' @param ptheme ggplot theme function to apply to the plot. By default, function applies WJP_theme()
#'
#' @return A ggplot object
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
#' data4divbars <- WJPr::gpp %>%
#' filter(
#'   year == 2022
#' ) %>%
#'   select(country, q1a) %>%
#'   mutate(
#'     q1a  = case_when(
#'       q1a <= 2  ~ "Trust",
#'       q1a <= 4  ~ "No Trust"
#'     )
#'   ) %>%
#'   group_by(country, q1a) %>%
#'   count() %>%
#'   filter(
#'     !is.na(q1a)
#'   ) %>%
#'   group_by(country) %>%
#'   mutate(
#'     total       = sum(n),
#'     percentage  = (n/total)*100,
#'     value_label = paste0(
#'       format(
#'         round(percentage, 1),
#'         nsmall = 1
#'       ),
#'       "%"
#'     ),
#'     value_label    = if_else(percentage >= 5, 
#'                              value_label, 
#'                              NA_character_),
#'     direction      = if_else(q1a == "Trust", 
#'                              "positive", 
#'                              "negative"),
#'     percentage     = if_else(direction == "negative", 
#'                              percentage*-1, 
#'                              percentage),
#'     label_position = (percentage/2)
#'   ) %>%
#'   select(
#'     country, q1a, percentage, value_label, label_position, direction
#'   )
#' 
#' # Plotting chart
#' wjp_divbars(
#'   data4divbars,             
#'   target      = "percentage",       
#'   grouping    = "country",         
#'   diverging   = "q1a",     
#'   negative    = "negative",   
#'   cvec        = c("Trust"     = "#4F518C",
#'                   "No Trust"  = "#2C2A4A"),
#'   labels      = "value_label"
#' )


wjp_divbars <- function(
    data,             
    target,       
    grouping,         
    diverging,     
    negative = NULL,
    cvec = NULL,
    labels = NULL,  
    label_color = "#ffffff",
    custom_order = F, 
    order = NULL,  
    ptheme = WJP_theme()
){
  
  # Renaming variables in the data frame to match the function naming
  if (!is.null(labels)) {
    data <- data %>%
      rename(target_var    = all_of(target),
             rows_var      = all_of(grouping),
             grouping_var  = all_of(diverging),
             labels_var    = all_of(labels),
             order_var     = any_of(order))
  } else{
  data <- data %>%
    rename(target_var    = all_of(target),
           rows_var      = all_of(grouping),
           grouping_var  = all_of(diverging),
           order_var     = any_of(order))
  data$labels_var <- rep("", nrow(data))
  }

  if (!is.null(negative)) {
    data <- data %>%
      mutate(
        target_var = if_else(
          grouping_var == negative,
          -abs(target_var),
          target_var
        )
      )
  }
  
  # Creating ggplot
  if (custom_order == F) {
    chart <- ggplot(data, aes(x     = rows_var,
                              y     = target_var,
                              fill  = grouping_var,
                              label = labels_var))
  } else {
    chart <- ggplot(data, aes(x     = reorder(rows_var, order_var),
                              y     = target_var,
                              fill  = grouping_var,
                              label = labels_var))
  }
  
  # Axis breaks
  brs <-  c(-100, -75, -50, -25, 0, 25, 50, 75, 100)
  
  # Adding geoms
  chart <- chart +
    geom_bar(stat         = "identity",
             position     = "stack",
             show.legend  = F,
             width        = 0.85) +
    geom_hline(yintercept = 0,
               linetype   = "solid",
               linewidth  = 0.5,
               color      = "#262424")
  
  if (!is.null(cvec)) {
    chart <- chart +
      scale_fill_manual(values = cvec)
  }
  
    chart <- chart +
    scale_y_continuous(limits   = c(-105,105),
                       breaks   = brs,
                       labels   = paste0(abs(brs), "%"),
                       position = "right") +
    scale_x_discrete(limits   = rev) +
    coord_flip() +
    ptheme +
    geom_text(aes(label = labels_var), 
              family   = "Lato Full", 
              fontface = "bold",
              color    = label_color, 
              position = position_stack(vjust=0.5)) +
    theme(panel.grid.major = element_blank(),
          axis.text.x      = element_text(family = "Lato Full",
                                          face   = "bold",
                                          size   = 3.514598 * ggplot2::.pt,
                                          color  = "#262424",
                                          hjust  = 0),
          axis.text.y      = element_text(family = "Lato Full",
                                          face   = "bold",
                                          size   = 3.514598 * ggplot2::.pt,
                                          color  = "#262424",
                                          hjust  = 0),
          axis.title.x      = element_blank(),
          axis.title.y      = element_blank(),
          axis.line.x       = element_line(linetype   = "solid",
                                           linewidth  = 0.5,
                                           color      = "#262424"))
  
  return(chart)
  
}
