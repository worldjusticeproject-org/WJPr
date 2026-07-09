#' Plot a Line Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' 
#' `wjp_lines()` takes a data frame with a specific data structure (usually long shaped) and returns a ggplot
#' object with a line chart following WJP style guidelines.
#'
#' @param data Data frame containing the data to plot
#' @param target String. Column name of the variable that will supply the values to plot.
#' @param grouping String. Column name of the variable that supplies the grouping values (X-Axis).
#' @param ngroups Vector containing each of the groups for the lines. If there is only a single group, please input c = (1).
#' @param labels String. Column name of the variable containing the value labels to display in plot.
#' @param colors String. Column name of the variable that contains the color grouping.
#' @param cvec Named vector with the colors to apply to each line.
#' @param repel Boolean. If TRUE, function will apply the ggrepel package to repel labels. Default is FALSE.
#' @param transparency Boolean. If TRUE, function will apply different opacities patterns. Default is FALSE.
#' @param transparencies Named vector with the different opacities to apply to each line.
#' @param custom.axis Boolean. If TRUE, x.breaks and x.labels will be passed to the ggplot theme. Default is FALSE.
#' @param x.breaks Numeric vector with custom breaks for the X-Axis.
#' @param x.labels Character vector with labels for the x-axis. It has to be the same length than x.breaks.
#' @param sec.ticks Numeric vector containing the minor breaks for the plot X-Axis.
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
#' # Always load the WJP fonts if not passing a custom theme to function
#' wjp_fonts()
#' 
#' # Preparing data
#' gpp_data <- WJPr::gpp
#' 
#' data4lines <- gpp_data %>%
#' filter(
#'   country == "Atlantis"
#' ) %>%
#'   select(year, q1a, q1b, q1c) %>%
#'   mutate(
#'     across(
#'       !year,
#'       \(x) as.double(unclass(x))
#'     ),
#'     across(
#'       !year,
#'       ~case_when(
#'         .x <= 2  ~ 1,
#'         .x <= 4  ~ 0,
#'         .x == 99 ~ NA_real_
#'       )
#'     ),
#'     year = as.character(year)
#'   ) %>%
#'   group_by(year) %>%
#'   summarise(
#'     across(
#'       everything(),
#'       \(x) mean(x, na.rm = TRUE)
#'     ),
#'     .groups = "keep"
#'   ) %>%
#'   mutate(
#'     across(
#'       everything(),
#'       \(x) x*100
#'     )
#'   ) %>%
#'   pivot_longer(
#'     !year,
#'     names_to  = "variable",
#'     values_to = "percentage" 
#'   ) %>%
#'   mutate(
#'     institution = case_when(
#'       variable == "q1a" ~ "Institution A",
#'       variable == "q1b" ~ "Institution B",
#'       variable == "q1c" ~ "Institution C"
#'     ),
#'     value_label = paste0(
#'       format(
#'         round(percentage, 0),
#'         nsmall = 0
#'       ),
#'       "%"
#'     )
#'   )
#'  
#'  # Plotting chart
#'  wjp_lines(
#'   data4lines %>% filter(institution == "Institution A"),                    
#'   target         = "percentage",             
#'   grouping       = "year",
#'   ngroups        = 1,                 
#'   colors         = "institution",
#'   cvec           = c("Institution A" = "#482d8b"),
#'   labels         = "value_label"
#'  )


wjp_lines <- function(
    data,                    
    target,             
    grouping,
    ngroups,                 
    colors,
    cvec           = NULL,
    labels         = NULL,
    repel          = FALSE,
    transparency   = FALSE,
    transparencies = NULL,   
    custom.axis    = FALSE,
    x.breaks       = NULL,    
    x.labels       = NULL,    
    sec.ticks      = NULL,       
    ptheme         = WJP_theme()
){
  
  # Renaming variables in the data frame to match the function naming
  if (is.null(labels)) {
    data <- data %>%
      dplyr::mutate(labels_var    = "") %>%
      rename(target_var    = all_of(target),
             grouping_var  = all_of(grouping),
             colors_var     = all_of(colors))
  } else {
    data <- data %>%
      rename(target_var    = all_of(target),
             grouping_var  = all_of(grouping),
             labels_var    = all_of(labels),
             colors_var    = all_of(colors))
  }
  
  # Creating ggplot
  plt <- ggplot(data, 
                aes(x     = grouping_var,
                    y     = target_var,
                    color = colors_var,
                    label = labels_var,
                    group = ngroups))
    
  if (transparency == FALSE) {
    plt <- plt +
      geom_point(size = 2,
                 show.legend = FALSE) +
      geom_line(linewidth    = 1,
                show.legend  = FALSE)
      
  } else {
    plt <- plt +
      geom_point(size = 2,
                 aes(alpha   = colors_var),
                 show.legend = FALSE) +
      geom_line(linewidth    = 1,
                aes(alpha    = colors_var),
                show.legend  = FALSE)
  }
  
  if (repel == FALSE) {
    
    # Applying regular geom_text
    
    if (transparency == FALSE) {
      plt <- plt +
        geom_text(aes(y       = target_var + 7.5,
                      x       = grouping_var,
                      label   = labels_var),
                  family      = "Lato Full",
                  fontface    = "bold",
                  size        = 3.514598,
                  show.legend = FALSE)
    } else {
      plt <- plt +
        geom_text(aes(y       = target_var + 7.5,
                      x       = grouping_var,
                      label   = labels_var,
                      alpha   = colors_var),
                  family      = "Lato Full",
                  fontface    = "bold",
                  size        = 3.514598,
                  show.legend = FALSE)
    }
    
    
  } else {
    
    # Applying ggrepel for a better visualization of plots
    # Check if ggrepel is available
    if (!requireNamespace("ggrepel", quietly = TRUE)) {
      stop("Package 'ggrepel' is required for repel=TRUE. Install with: install.packages('ggrepel')")
    }

    if (transparency == FALSE) {
      plt <- plt +
        ggrepel::geom_text_repel(mapping = aes(y     = target_var,
                                      x     = grouping_var,
                                      label = labels_var),
                        family      = "Lato Full",
                        fontface    = "bold",
                        size        = 3.514598,
                        show.legend = FALSE,

                        # Additional options from ggrepel package:
                        min.segment.length = 1000,
                        seed               = 42,
                        box.padding        = 0.5,
                        direction          = "y",
                        force              = 5,
                        force_pull         = 1)
    } else {
      plt <- plt +
        ggrepel::geom_text_repel(mapping = aes(y     = target_var,
                                      x     = grouping_var,
                                      label = labels_var,
                                      alpha = colors_var),
                        family      = "Lato Full",
                        fontface    = "bold",
                        size        = 3.514598,
                        show.legend = FALSE,

                        # Additional options from ggrepel package:
                        min.segment.length = 1000,
                        seed               = 42,
                        box.padding        = 0.5,
                        direction          = "y",
                        force              = 5,
                        force_pull         = 1)
    }
      
  }
  
  if (transparency == TRUE) {
    plt <- plt +
      scale_alpha_manual(values = transparencies)
  }
  
  if (custom.axis == FALSE) {
    plt <- plt +
      scale_y_continuous(limits = c(0, 105),
                         expand = c(0,0),
                         breaks = seq(0,100,20),
                         labels = paste0(seq(0,100,20), "%"))
    
    if (!is.null(cvec)) {
      plt <- plt +
        scale_color_manual(values = cvec)
    }
    
  } else {
    if (!requireNamespace("ggh4x", quietly = TRUE)) {
      stop("Package 'ggh4x' is required for custom.axis=TRUE. Install with: install.packages('ggh4x')", call. = FALSE)
    }
    if (is.null(x.breaks) || is.null(x.labels)) {
      stop("`x.breaks` and `x.labels` must be provided when custom.axis = TRUE.", call. = FALSE)
    }
    if (length(x.breaks) != length(x.labels)) {
      stop("`x.breaks` and `x.labels` must have the same length.", call. = FALSE)
    }
    plt <- plt +
      scale_y_continuous(limits = c(0, 105),
                         expand = c(0,0),
                         breaks = seq(0,100,20),
                         labels = paste0(seq(0,100,20), "%")) +
      scale_x_continuous(limits = c(head(x.breaks, 1), tail(x.breaks, 1)),
                         breaks = x.breaks,
                         expand = expansion(mult = c(0.075, 0.125)),
                         labels = x.labels,
                         guide  = ggh4x::guide_axis_minor(),
                         minor_breaks = sec.ticks)
    
    if (!is.null(cvec)) {
      plt <- plt +
        scale_color_manual(values = cvec)
    }
  }
  
  plt <- plt +
    ptheme +
    theme(panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(colour = "#d1cfd1"),
          axis.title.x       = element_blank(),
          axis.title.y       = element_blank(),
          axis.line.x        = element_line(color    = "#d1cfd1"),
          axis.ticks.x       = element_line(color    = "#d1cfd1",
                                            linetype = "solid"))
  
  if (custom.axis == TRUE) {
    plt <- plt +
      theme(
        ggh4x.axis.ticks.length.minor = rel(1)
      )
    
  }
  
  return(plt)
}
