#' Plot a Radar Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' 
#' `wjp_radar()` takes a data frame with a specific data structure (usually long shaped) and returns a ggplot
#' object with a radar chart following WJP style guidelines.
#'
#' @details
#' The function expects long-format data with one row per `axis_var`
#' (dimension) and `colors` (group) combination; one polygon is drawn per
#' group. With `source = "GPP"` (default) values are read as percentages
#' (0-100) and the rings are labeled 0%-100%; with `source = "QRQ"` values
#' are read as scores (0-1). Axis labels are taken from the `labels` column
#' of the group given by `maincat` (or the first group when `maincat` is
#' `NULL`) and support HTML/markdown formatting when the ggtext package is
#' installed.
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
#' @param show_legend Logical. If `TRUE`, displays a horizontal legend above the
#'   chart using the color groups. Default is `FALSE`.
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
#'   show_legend = TRUE,
#'   cvec     = c("Male" = "#482d8b", "Female" = "#f26b21")
#' )
#'
#' # Rule of Law Index factor scores (0-1 scale) with source = "QRQ"
#' data4radar_roli <- WJPr::roli %>%
#'   filter(country == "Austria", year == 2024) %>%
#'   select(country, f1, f2, f3, f4, f5, f6, f7, f8) %>%
#'   pivot_longer(!country, names_to = "factor", values_to = "score") %>%
#'   mutate(factor_label = paste("Factor", substr(factor, 2, 2)))
#'
#' wjp_radar(
#'   data4radar_roli,
#'   axis_var = "factor",
#'   target   = "score",
#'   labels   = "factor_label",
#'   colors   = "country",
#'   cvec     = c("Austria" = "#482d8b"),
#'   source   = "QRQ"
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
    order_var = NULL,
    show_legend = FALSE
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

  legend_breaks <- wjp_legend_breaks(data$color_var)
    
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
          label = r),
      family     = wjp_font_family(),
      fontface   = "plain",
      color      = "#524F4C",
      show.legend = FALSE
    ) +
    
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
          family      = wjp_font_family(),
          fontface    = "plain",
          fill        = NA,
          label.color = NA,
          show.legend = FALSE
        )
      } else {
        geom_text(
          data  = label_data,
          aes(x = x, y = y),
          label = axis_labels,
          family   = wjp_font_family(),
          fontface = "plain",
          show.legend = FALSE
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
      size        = 3,
      show.legend = show_legend
    ) +
    geom_path(
      data = rescaled_data, 
      aes(x     = x, 
          y     = y, 
          group = color_var, 
          color = as.factor(color_var)), 
      linewidth   = 1,
      show.legend = show_legend
    ) +
    
    # Remaining aesthetics
    coord_cartesian(clip = "off") + 
    scale_x_continuous(expand = expansion(mult = 0.125)) + 
    scale_y_continuous(expand = expansion(mult = 0.10)) + 
    scale_color_manual(values = cvec, breaks = legend_breaks, name = NULL) +
    theme_void() +
    theme(
      panel.background   = element_blank(),
      plot.background    = element_blank()
    ) +
    wjp_legend_theme(show_legend)
  
  return(radar)
  
}
