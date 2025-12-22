#' Plot a Dots Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' 
#' `wjp_dots()` takes a data frame with a specific data structure (usually long shaped) and returns a ggplot
#' object with a dots chart following WJP style guidelines.
#' 
#' @param data Data frame containing the data to plot
#' @param target String. Column name of the variable that will supply the values to plot.
#' @param colors String. Column name of the variable that supplies the grouping values. The plot will show a different color per group.
#' @param grouping String. Column name of the variable that supplies the Y-Axis labels to show in the plot.
#' @param cvec Named vector with the colors to apply to the dots. Default is NULL.
#' @param order String. Column name of the variable that contains the desired order for the labels.
#' @param diffOpac Boolean. If TRUE, the plot will expect different levels of opacities for the dots. Default is FALSE.
#' @param opacities Named vector with the opacity levels to apply to the dots. Default is NULL.
#' @param diffShp Boolean. If TRUE, the plot will expect different shapes for the dots. Default is FALSE.
#' @param shapes Named vector with shapes to be displayed. Default is NULL.
#' @param draw_ci Boolean. If TRUE, will draw a binomial confidence interval with target value as parameter of interest.
#' @param sd  String. Column name of the variable that supplies the standard error for drawing confidence intervals.
#' @param sample_size  String. Column name of the variable that supplies the number of observations for drawing confidence intervals.
#' @param bgcolor String. Hex code for the "white" background in the strips.
#' @param ptheme ggplot theme function to apply to the plot. By default, function applies WJP_theme().
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
#' # Always load the WJP fonts if not passing a custom theme to function
#' wjp_fonts()
#' 
#' # Preparing data
#' gpp_data <- WJPr::gpp
#' 
#' # Preparing data
#' data4dots <- gpp_data %>%
#'   select(country, q1a, q1b, q1c, q1d) %>%
#'   mutate(
#'     across(
#'       !country,
#'       \(x) case_when(
#'         x <= 2 ~ 1,
#'         x <= 4 ~ 0
#'       )
#'     )
#'   ) %>%
#'   group_by(country) %>%
#'   summarise(
#'     across(
#'       everything(),
#'       \(x) mean(x, na.rm = T)*100
#'     ),
#'     .groups = "keep"
#'   ) %>%
#'   pivot_longer(
#'     !country,
#'     names_to  = "variable",
#'     values_to = "percentage" 
#'   ) %>%
#'   mutate(
#'     institution = case_when(
#'       variable == "q1a" ~ "Institution A",
#'       variable == "q1b" ~ "Institution B",
#'       variable == "q1c" ~ "Institution C",
#'       variable == "q1d" ~ "Institution D",
#'     )
#'   )
#' 
#' # Plotting chart
#' wjp_dots(
#'   data4dots,             
#'   target      = "percentage",
#'   grouping    = "institution",  
#'   colors      = "country",  
#'   cvec        = c("Atlantis"  = "#08605F",
#'                   "Narnia"    = "#9E6240",
#'                   "Neverland" = "#2E0E02")
#' )
#' 

wjp_dots <- function(
    data,             
    target,
    grouping,
    colors,  
    cvec        = NULL, 
    order       = NULL,
    diffOpac    = FALSE,  
    opacities   = NULL,      
    diffShp     = FALSE,     
    shapes      = NA,
    draw_ci     = FALSE,
    sd          = NULL,
    sample_size = NULL,
    bgcolor     = "#ffffff",
    ptheme      = WJP_theme()
){
  
  # Renaming variables in the data frame to match the function naming
  data <- data %>%
    rename(
      target_var    = all_of(target),
      colors_var    = all_of(colors),
      grouping_var  = all_of(grouping)
    ) %>%
    mutate(target_var = as.numeric(target_var)) # Ensure target_var is numeric
  
  if (is.null(order)){
    data <- data %>%
      group_by(colors_var) %>%
      mutate(
        order_var = row_number()
      )
    
  } else {
    data <- data %>%
      rename(order_var = all_of(order))
  }
  
  # Add sample_size_var if drawing CI
  if (draw_ci){
    z <- qnorm(1 - 0.05 / 2)
    data  <- data %>%
      rename(sd_var = all_of(sd),
             sample_size_var = all_of(sample_size)) %>%
      mutate(
        se = sd_var / sqrt(sample_size_var),
        lower = target_var - z * se,
        upper = target_var + z * se
      )
  }
  
  # Creating a strip pattern
  strips <- data %>%
    group_by(grouping_var) %>%
    summarise() %>%
    mutate(ymin = 0,
           ymax = 100,
           xposition = rev(1:nrow(.)),
           xmin = xposition - 0.5,
           xmax = xposition + 0.5,
           fill = rep(c("grey", "white"), 
                      length.out = nrow(.))) %>%
    pivot_longer(c(xmin, xmax),
                 names_to  = "cat",
                 values_to = "x") %>%
    select(-cat)
    
  # Creating ggplot
  plt <- ggplot() +
    geom_blank(data      = data,
               aes(x     = reorder(grouping_var, -order_var),
                   y     = target_var,
                   label = grouping_var,
                   color = colors_var)) +
    geom_ribbon(data      = strips,
                aes(x     = x,
                    ymin  = ymin,
                    ymax  = ymax,
                    group = xposition,
                    fill  = fill),
                show.legend = F) +
    scale_fill_manual(values = c("grey"  = "#D6D6D6",
                                 "white" = bgcolor),
                      na.value = NA)
  
  if (draw_ci) {
    plt <- plt +
      geom_errorbar(
        data = data,
        aes(
          x     = reorder(grouping_var, -order_var),
          ymin  = lower,
          ymax  = upper,
          color = colors_var
        ),
        width = 0.2,
        show.legend = FALSE
      )
  }
  
  if (diffShp == F) {
    
    if (diffOpac == F) {
      plt <- plt +
        geom_point(data      = data,
                   aes(x     = reorder(grouping_var, -order_var),
                       y     = target_var,
                       color = colors_var),
                   size = 4,
                   show.legend = F)
    } else {
      plt <- plt +
        geom_point(data = data,
                   aes(x     = reorder(grouping_var, -order_var),
                       y     = target_var,
                       color = colors_var,
                       alpha = colors_var),
                   size      = 4,
                   show.legend   = F) +
        scale_alpha_manual(values = opacities)
    }
    
  } else {
    
    if (diffOpac == F) {
      plt <- plt +
        geom_point(data      = data,
                   aes(x     = reorder(grouping_var, -order_var),
                       y     = target_var,
                       color = colors_var,
                       shape = colors_var),
                   fill   = NA,
                   size   = 4,
                   stroke = 2,
                   show.legend = F) +
        scale_shape_manual(values = shapes)
      
    } else {
      plt <- plt +
        geom_point(data = data,
                   aes(x     = reorder(grouping_var, -order_var),
                       y     = target_var,
                       color = colors_var,
                       shape = colors_var,
                       alpha = colors_var),
                   fill   = NA,
                   size   = 4,
                   stroke = 2,
                   show.legend    = F) +
        scale_shape_manual(values = shapes) +
        scale_alpha_manual(values = opacities)
    }
    
  }
  
  if (!is.null(cvec)){
    plt <- plt +
      scale_color_manual(values = cvec)
  }
  
  plt <- plt +
    scale_y_continuous(limits = c(0,100),
                       breaks = seq(0,100,20),
                       labels = paste0(seq(0,100,20),
                                       "%"),
                       position = "right") +
    coord_flip() +
    ptheme +
    theme(axis.title.x       = element_blank(),
          axis.title.y       = element_blank(),
          panel.grid.major.y = element_blank(),
          panel.background   = element_blank(), 
          panel.ontop = T,
          axis.text.y = element_text(color = "#222221",
                                     hjust = 0))
    
  return(plt)
  
}
