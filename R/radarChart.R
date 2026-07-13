#' Plot a Radar Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' 
#' `wjp_radar()` takes a data frame with a specific data structure (usually long shaped) and returns a ggplot
#' object with a radar chart following WJP style guidelines.
#'
#' @param data Data frame containing the data to plot.
#' @param axis_var String. Column name of the variable that supplies the axes
#'   (dimensions) of the radar.
#' @param target String. Column name of the variable that supplies the values to plot.
#' @param labels String. Column name of the variable containing the axis labels to
#'   display around the radar.
#' @param colors String. Column name of the variable that supplies the color grouping.
#'   The plot shows one polygon per group.
#' @param cvec Named vector of colors, one per group. Default is `NULL`
#'   (the WJP contrast pair `#482d8b` / `#f26b21` is applied).
#' @param order String. Column name of the variable that contains the display order of
#'   the axes. Default is `NULL` (data order).
#' @param maincat String. Column used to choose the axis labels. If `NULL`, labels are
#'   taken from the first color group.
#' @param source String. Either `"GPP"` (values on a 0-100 percentage scale) or
#'   `"QRQ"` (values on a 0-1 score scale). Default is `"GPP"`.
#' @param order_var `r lifecycle::badge("deprecated")` Use `order` instead.
#'
#' @return A ggplot object representing the radar plot.
#' @export
#'
#' @examples
#' library(dplyr)
#' library(tidyr)
#'
#' # Always load the WJP fonts
#' wjp_fonts()
#'
#' # Opinions about authorities, by gender
#' data4radar <- WJPr::gpp %>%
#'   select(gend, starts_with("q49")) %>%
#'   mutate(
#'     gend   = as.double(unclass(gend)),
#'     across(starts_with("q49"), \(x) as.double(unclass(x))),
#'     gender = case_when(gend == 1 ~ "Male", gend == 2 ~ "Female"),
#'     across(starts_with("q49"), \(x) case_when(x <= 2 ~ 1, x <= 99 ~ 0))
#'   ) %>%
#'   group_by(gender) %>%
#'   summarise(across(starts_with("q49"), \(x) mean(x, na.rm = TRUE) * 100)) %>%
#'   pivot_longer(!gender, names_to = "category", values_to = "percentage") %>%
#'   mutate(axis_label = category)
#'
#' wjp_radar(
#'   data4radar,
#'   axis_var = "category",
#'   target   = "percentage",
#'   labels   = "axis_label",
#'   colors   = "gender",
#'   cvec     = c("Male" = "#482d8b", "Female" = "#f26b21")
#' )
#'


wjp_radar <- function(
    data,
    axis_var,
    target,
    labels,
    colors,
    maincat   = NULL,
    cvec      = NULL,
    order     = NULL,
    source    = "GPP",
    order_var = NULL
){

  # Backwards compatibility: `order_var` was renamed to `order`
  if (is.null(order) && !is.null(order_var)) {
    order <- order_var
  }

  # Renaming variables in the data frame to match the function naming
  data <- data %>%
    rename(axis_var    = all_of(axis_var),
           target_var  = all_of(target),
           label_var   = all_of(labels),
           color_var   = all_of(colors))

  if (!is.null(maincat)) {
    data <- data %>%
      rename(maincat_var = all_of(maincat))
  } else {
    data <- data %>%
      mutate(maincat_var = color_var)
  }
  
  if (is.null(order)) {
    data <- data %>%
      group_by(color_var) %>%
      mutate(order_var = row_number())
  } else {
    data <- data %>%
      rename(order_var = all_of(order))
  }
  
  if (source == "GPP") {
    data <- data %>%
      mutate(
        target_var = target_var/100
      )
  }
  
  # Default colors: WJP contrast pair plus a neutral gray fallback
  if (is.null(cvec)) {
    cvec   <- c("#482d8b", "#f26b21")
  }
  cvec <- c(cvec, "#555659")
    
  # Counting number of axis for the radar
  nvertix <- length(unique(data$axis_var))
  
  # Distance to the center of the web 
  central_distance <- 0.2
  
  # Function to generate radar coordinates
  circle_coords <- function(r, n_axis = nvertix){
    fi <- seq(0, 2*pi, (1/n_axis)*2*pi) + pi/2
    x <- r*cos(fi)
    y <- r*sin(fi)
    
    tibble(x, y, r)
  }
  
  # Function to generate axis lines
  axis_coords <- function(n_axis = nvertix){
    fi <- seq(0, (1 - 1/n_axis)*2*pi, (1/n_axis)*2*pi) + pi/2
    x1 <- central_distance*cos(fi)
    y1 <- central_distance*sin(fi)
    x2 <- (1 + central_distance)*cos(fi)
    y2 <- (1 + central_distance)*sin(fi)
    
    tibble(x = c(x1, x2), y = c(y1, y2), id = rep(1:n_axis, 2))
  }
  
  # Function to generate axis coordinates
  text_coords <- function(r      = 1.5, 
                          n_axis = nvertix){
    fi <- seq(0, (1 - 1/n_axis)*2*pi, (1/n_axis)*2*pi) + pi/2 + 0.01*2*pi/r
    x <- r*cos(fi)
    y <- r*sin(fi)
    
    tibble(x, y, r = r - central_distance)
  }
  
  # Y-Axis labels
  axis_measure <- tibble(
    r         = seq(0, 1, 0.2),
    parameter = rep(
      data %>% 
        filter(order_var == 1) %>% 
        ungroup() %>%
        distinct(axis_var) %>% 
        pull(axis_var),
      6
    )
  ) %>%
    bind_cols(
      purrr::map_df(
        seq(0, 1, 0.2) + central_distance, 
        text_coords
      ) %>% 
        distinct(r, .keep_all = TRUE) %>%
        select(-r)
    )
  
  if (source == "GPP"){
    axis_measure <- axis_measure %>%
      mutate(
        r = paste0(r*100, "%")
      )
  }
  
  # Generating data points
  rescaled_coords <- function(r, n_axis = nvertix){
    fi <- seq(0, 2*pi, (1/n_axis)*2*pi) + pi/2
    tibble(r, fi) %>% 
      mutate(x = r*cos(fi), y = r*sin(fi)) %>% 
      select(-fi)
  }
  
  rescaled_data <- data %>% 
    bind_rows(
      data %>% 
        filter(
          axis_var %in% 
            (data %>% 
               filter(order_var == 1) %>% 
               distinct(axis_var) %>% 
               pull(axis_var))
        ) %>%
        mutate(axis_var  = "copy",
               order_var = nvertix)
    ) %>%
    group_by(color_var) %>%
    arrange(order_var) %>%
    mutate(
      coords = rescaled_coords(target_var + central_distance)
    ) %>%
    unnest(cols = c(coords)) 
  
  # Generating ggplot
  radar <-
    
    # We set up the ggplot
    ggplot(
      data = purrr::map_df(seq(0, 1, 0.20) + central_distance, circle_coords),
      aes(x = x, 
          y = y)
    ) +
    
    # We draw the outter ring
    geom_polygon(
      data     = circle_coords(1 + central_distance),
      linetype = "dotted",
      color    = "#d1cfd1",
      fill     = NA
    ) +
    
    # We draw the inner rings
    geom_path(
      aes(group = r), 
      lty       = 2, 
      color     = "#d1cfd1"
    ) +
    
    # We draw the ZERO ring
    geom_polygon(
      data = purrr::map_df(seq(0, 1, 0.20) + central_distance, circle_coords) %>%
        filter(r == 0.2),
      fill      = NA,
      linetype  = "solid",
      color     = "#d1cfd1"
    ) +
    
    # Then, we draw the Y-axis lines
    geom_line(
      data = axis_coords(), 
      aes(x     = x, 
          y     = y, 
          group = id),
      color = "#d1cfd1"
    ) +
    
    # Along with its labels
    geom_text(
      data = axis_measure,
      aes(x     = x,
          y     = y,
          label = r,
          family   = "Lato Full",
          fontface = "plain",
          color    = "#524F4C"
      )) +
    
    # Then, we add the axis labels
    {
      label_data <- text_coords() %>%
        mutate(n = row_number())

      label_group <- data %>%
        ungroup() %>%
        distinct(maincat_var) %>%
        slice_head(n = 1) %>%
        pull(maincat_var)

      axis_labels <- data %>%
        arrange(order_var) %>%
        filter(maincat_var == label_group) %>%
        distinct(axis_var, .keep_all = TRUE) %>%
        pull(label_var)

      if (requireNamespace("ggtext", quietly = TRUE)) {
        ggtext::geom_richtext(
          data  = label_data,
          aes(x = x, y = y),
          label = axis_labels,
          family      = "Lato Full",
          fontface    = "plain",
          fill        = NA,
          label.color = NA
        )
      } else {
        geom_text(
          data  = label_data,
          aes(x = x, y = y),
          label = axis_labels,
          family   = "Lato Full",
          fontface = "plain"
        )
      }
    } +
    
    # We add the data points along with its lines
    geom_point(
      data = rescaled_data, 
      aes(x     = x, 
          y     = y, 
          group = color_var, 
          color = as.factor(color_var)), 
      size      = 3
    ) +
    geom_path(
      data = rescaled_data, 
      aes(x     = x, 
          y     = y, 
          group = color_var, 
          color = as.factor(color_var)), 
      linewidth = 1
    ) +
    
    # Remaining aesthetics
    coord_cartesian(clip = "off") + 
    scale_x_continuous(expand = expansion(mult = 0.125)) + 
    scale_y_continuous(expand = expansion(mult = 0.10)) + 
    scale_color_manual(values = cvec) +
    theme_void() +
    theme(
      panel.background   = element_blank(),
      plot.background    = element_blank(),
      legend.position    = "none"
    )
  
  return(radar)
  
}
