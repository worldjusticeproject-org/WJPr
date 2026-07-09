#' Plot a Dumbbell Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' 
#' `wjp_dumbbells()` takes a data frame with a specific data structure (usually long shaped) and returns a ggplot
#' object with a dumbbell chart following WJP style guidelines.
#'
#' @param data A data frame containing the data to be plotted.
#' @param target A string specifying the variable in the data frame that contains the numeric values to be plotted.
#' @param grouping A string specifying the variable in the data frame that contains the categories for the rows.
#' @param color A string specifying the variable in the data frame that indicates the groups for start and end points.
#' @param cgroups A vector of two strings specifying the groups to be compared in the dumbbell plot.
#' @param labels A string specifying the variable in the data frame that contains the text labels to display. Default is NULL. 
#' @param labpos A string specifying the variable in the data frame that contains the label positions.
#' @param cvec A vector of colors to apply to the points and lines. Default is NULL.
#' @param order A named vector specifying the order of the categories. Default is NULL.
#' @param ptheme A ggplot2 theme object to be applied to the plot. Default is WJP_theme().
#'
#' @return A ggplot object representing the dumbbell plot.
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
#' data4dumbbells <- gpp_data %>%
#' filter(
#'   country == "Atlantis" & year %in% c(2017, 2022)
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
#'   # Plotting chart
#'   wjp_dumbbells(
#'     data4dumbbells,
#'     target    = "percentage",
#'     grouping  = "institution",
#'     color     = "year",
#'     cvec      = c("2017" = "#2894aa",
#'                   "2022" = "#482d8b"),
#'     cgroups   = c("2017", "2022")
#'  )
#'  

wjp_dumbbells <- function(
    data,             
    target, 
    grouping,
    cgroups,  
    color,
    labels    = NULL,
    labpos    = NULL,
    cvec      = NULL, 
    order     = NULL,
    ptheme    = WJP_theme()
){
  
  # Default colors
  if (is.null(cvec)){
    cvec   <- c("#2894aa", "#482d8b")
  }
  
  # Renaming variables in the data frame to match the function naming
  data_wider <- data %>%
    pivot_wider(
      id_cols     = all_of(grouping),
      names_from  = all_of(color),
      values_from = all_of(target)
    ) %>%
    rename(
      group = all_of(grouping),
      start = all_of(cgroups[1]),
      end   = all_of(cgroups[2])
    )
  
  if (!is.null(labels)) {
    data_wider <- data_wider %>%
      left_join(
        data %>%
          pivot_wider(
            id_cols     = all_of(grouping),
            names_from  = all_of(color),
            values_from = all_of(labels)
          ) %>%
          rename(
            group = all_of(grouping),
            lab0  = all_of(cgroups[1]),
            lab1  = all_of(cgroups[2])
          ),
        by = "group"
      )
    
    data_wider <- data_wider %>%
      left_join(
        data %>%
          pivot_wider(
            id_cols     = all_of(grouping),
            names_from  = all_of(color),
            values_from = all_of(labpos)
          ) %>%
          rename(
            group = all_of(grouping),
            labp0 = all_of(cgroups[1]),
            labp1 = all_of(cgroups[2])
          ),
        by = "group"
      )
  }
  
  if (is.null(order)){
    data_wider <- data_wider %>%
      ungroup() %>%
      mutate(
        order = row_number()
      )
    
  } else {
    data_wider <- data_wider %>% 
     mutate(
       order = recode(group, !!!order)
     )
  }
  
  # Creating a strip pattern
  strips <- data_wider %>%
    group_by(group) %>%
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
  
  # Drawing plot
  plt <- ggplot() +
    geom_segment(
      data = data_wider,
      aes(
        x    = group,
        xend = group,
        y    = start,
        yend = end
      ),
      color  = "#BFBFBF",
      linewidth = 2.5
    ) +
    geom_point(
      data = data_wider,
      aes(
        x     = group,
        y     = start
      ),
      color = cvec[1],
      size  = 4.5
    ) +
    geom_point(
      data = data_wider,
      aes(
        x     = group,
        y     = end
      ),
      color = cvec[2],
      size  = 4.5
    ) 
  
  if (!is.null(labels)) {
    plt <- plt +
      geom_text(
        data = data_wider,
        aes(
          x     = group,
          y     = labp0,
          label = lab0
        ),
        family   = "Lato Full",
        fontface = "bold",
        color    = cvec[1] 
      ) +
      geom_text(
        data = data_wider,
        aes(
          x     = group,
          y     = labp1,
          label = lab1
        ),
        family   = "Lato Full",
        fontface = "bold",
        color    = cvec[2]
      )
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
          panel.ontop = TRUE,
          axis.text.y = element_text(color = "#222221",
                                     hjust = 0))
  
  return(plt)
}
