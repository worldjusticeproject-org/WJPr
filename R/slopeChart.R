#' Plot a Slope Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' 
#' `wjp_slope()` takes a data frame with a specific data structure (usually long shaped) and returns a ggplot
#' object with a slope chart following WJP style guidelines.
#'
#' @param data Data frame containing the data to plot
#' @param target String. Column name of the variable that will supply the values to plot.
#' @param grouping String. Column name of the variable that supplies the grouping values (X-Axis).
#' @param ngroups Vector containing each of the groups for the lines. If there is only a single group, please input c = (1).
#' @param colors String. Column name of the variable that contains the color grouping.
#' @param cvec Named vector with the colors to apply to each line.
#' @param labels String. Column name of the variable containing the value labels to display in plot. Default is NULL.
#' @param repel Boolean. If TRUE, function will apply the ggrepel package to repel labels. Default is FALSE.
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
#' library(ggrepel)
#' 
#' # Always load the WJP fonts if not passing a custom theme to function
#' wjp_fonts()
#' 
#' # Preparing data
#' gpp_data <- WJPr::gpp
#' 
#' data4slopes <- gpp_data %>%
#' select(year, gend, q1a) %>%
#'   filter(
#'     year %in% c(2017, 2019)
#'   ) %>%
#'   mutate(
#'     gend = as.double(unclass(gend)),
#'     q1a = as.double(unclass(q1a)),
#'     trust = case_when(
#'       q1a <= 2  ~ 1,
#'       q1a <= 4  ~ 0
#'     ),
#'     gender = case_when(
#'       gend == 1 ~ "Male",
#'       gend == 2 ~ "Female"
#'     )
#'   ) %>%
#'   group_by(year, gender) %>%
#'   summarise(
#'     trust = mean(trust, na.rm = TRUE)*100,
#'     .groups = "keep"
#'   ) %>%
#'   mutate(
#'     value_label = paste0(
#'       format(
#'         round(trust, 0),
#'         nsmall = 0
#'       ),
#'       "%"
#'     )
#'   )
#' 
#' # Plotting chart
#' wjp_slope(
#'   data4slopes,                    
#'   target    = "trust",             
#'   grouping  = "year",
#'   ngroups   = data4slopes$gender,                 
#'   labels    = "value_label",
#'   colors    = "gender",
#'   cvec      = c("Male"   = "#482d8b",
#'                 "Female" = "#f26b21"),
#'   repel     = TRUE
#' )

wjp_slope <- function(
    data,                    
    target,             
    grouping,
    ngroups,  
    colors,
    cvec      = NULL,
    labels    = NULL,
    repel     = FALSE,
    ptheme    = WJP_theme()
){
  
  # Renaming variables in the data frame to match the function naming
  if (is.null(labels)) {
    data <- data %>%
      dplyr::mutate(labels_var = "")
  } else {
    data <- data %>%
      rename(labels_var = all_of(labels))
  }
  
  data <- data %>%
    rename(
      target_var    = all_of(target),
      grouping_var  = all_of(grouping),
      colors_var    = all_of(colors)
    )
  
  data <- data %>%
    mutate(
      labpos = case_when(
        grouping_var == min(data$grouping_var) ~ grouping_var-0.5,
        grouping_var == max(data$grouping_var) ~ grouping_var+0.5,
      )
    )
  
  if (is.null(cvec)){
    default_colors <- c("#482d8b", "#2894aa", "#f26b21", "#0f9581", "#555659")
    nitems <- length(unique(ngroups))
    cvec   <- default_colors[1:nitems]
  }
  
  # Creating ggplot
  plt <- ggplot(data, 
                aes(x     = grouping_var,
                    y     = target_var,
                    color = colors_var,
                    label = labels_var,
                    group = ngroups)) +
    geom_point(size = 2,
               show.legend = FALSE) +
    geom_line(linewidth    = 1,
              show.legend  = FALSE)
  
  if (repel == FALSE) {
    
    # Applying regular geom_text
    plt <- plt +
      geom_text(aes(y       = target_var,
                    x       = labpos,
                    label   = labels_var),
                family      = "Lato Full",
                fontface    = "bold",
                size        = 3.514598,
                show.legend = FALSE)
    
  } else {

    # Applying ggrepel for a better visualization of plots
    # Check if ggrepel is available
    if (!requireNamespace("ggrepel", quietly = TRUE)) {
      stop("Package 'ggrepel' is required for repel=TRUE. Install with: install.packages('ggrepel')")
    }

    plt <- plt +
      ggrepel::geom_text_repel(mapping = aes(y     = target_var,
                                    x     = labpos,
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

  }
  
  plt <- plt +
    scale_x_continuous(
      n.breaks = 2,
      breaks   = data %>% ungroup() %>% distinct(grouping_var) %>% pull(grouping_var)
    ) +
    scale_y_continuous(limits = c(0, 105),
                       expand = c(0,0),
                       breaks = seq(0,100,20),
                       labels = paste0(seq(0,100,20), "%")) +
    scale_color_manual(values = cvec) +
    ptheme +
    theme(
      panel.grid.major.x = element_line(color    = "#ACA8AC",
                                        linetype = "solid",
                                        linewidth = 0.75),
      panel.grid.major.y = element_blank(),
      axis.line.y        = element_blank(),
      axis.title.x       = element_blank(),
      axis.title.y       = element_blank(),
      axis.line.x        = element_blank(),
      axis.ticks.x       = element_blank(),
      axis.text.y        = element_blank() 
    )

  return(plt)
}
