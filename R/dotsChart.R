#' Plot a Dots Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `wjp_dots()` takes a data frame with long-format data and returns a ggplot
#' object with a dots chart following WJP style guidelines. Dots charts compare
#' multiple variables (rows) across groups (colors) on a horizontal 0-100
#' percentage scale, with an alternating strip background.
#'
#' @details
#' The function expects long-format data with one row per `grouping`
#' (variable/row) and `colors` (group) combination. To draw a 95%
#' normal-approximation confidence interval around each dot, set
#' `draw_ci = TRUE` and supply per-row standard deviations (`sd`) and sample
#' sizes (`sample_size`). Per-group opacities (`opacities`) and point shapes
#' (`shapes`) can be supplied to distinguish groups beyond color.
#'
#' @param data Data frame containing the data to plot.
#' @param target String. Column name of the variable that supplies the values to plot.
#' @param grouping String. Column name of the variable that supplies the categories
#'   (Y-axis labels).
#' @param colors String. Column name of the variable that supplies the color grouping.
#'   The plot shows a different color per group.
#' @param cvec Named vector of colors. Names should match the values of the `colors`
#'   variable. Default is `NULL` (the WJP palette, see [wjp_palette()], is applied).
#' @param order String. Column name of the variable that contains the display order of
#'   categories. Default is `NULL` (data order).
#' @param diffOpac Logical. If `TRUE`, different opacity levels are applied per group.
#'   Automatically enabled when `opacities` is supplied. Default is `FALSE`.
#' @param opacities Named vector of opacity levels, one per group. Default is `NULL`.
#' @param diffShp Logical. If `TRUE`, different point shapes are applied per group.
#'   Automatically enabled when `shapes` is supplied. Default is `FALSE`.
#' @param shapes Named vector of point shapes, one per group. Default is `NA`.
#' @param draw_ci Logical. If `TRUE`, draws a normal-approximation confidence interval
#'   using `sd` and `sample_size`. Default is `FALSE`.
#' @param sd String. Column name of the variable that supplies the standard deviation
#'   for the confidence intervals.
#' @param sample_size String. Column name of the variable that supplies the number of
#'   observations for the confidence intervals.
#' @param bgcolor String. Hex code of the background color for the alternating row
#'   strips. Default is `"#ffffff"`.
#' @param ptheme ggplot theme to apply. Default is [WJP_theme()].
#'
#' @return A ggplot object.
#' @export
#'
#' @examples
#' library(dplyr)
#' library(tidyr)
#'
#' # Always load the WJP fonts
#' wjp_fonts()
#'
#' # Percentage of people that trust their institutions, by country
#' data4dots <- WJPr::gpp %>%
#'   select(country, q1a, q1b, q1c, q1d) %>%
#'   mutate(
#'     across(!country, \(x) as.double(unclass(x))),
#'     across(!country, \(x) case_when(x <= 2 ~ 1, x <= 4 ~ 0))
#'   ) %>%
#'   group_by(country) %>%
#'   summarise(across(everything(), \(x) mean(x, na.rm = TRUE) * 100)) %>%
#'   pivot_longer(!country, names_to = "variable", values_to = "percentage") %>%
#'   mutate(
#'     institution = case_when(
#'       variable == "q1a" ~ "Institution A",
#'       variable == "q1b" ~ "Institution B",
#'       variable == "q1c" ~ "Institution C",
#'       variable == "q1d" ~ "Institution D"
#'     )
#'   )
#'
#' wjp_dots(
#'   data4dots,
#'   target   = "percentage",
#'   grouping = "institution",
#'   colors   = "country",
#'   cvec     = c("Atlantis"  = "#482d8b",
#'                "Narnia"    = "#2894aa",
#'                "Neverland" = "#f26b21")
#' )
#'
#' # With 95% confidence intervals from sd and sample size
#' data4dots_ci <- WJPr::gpp %>%
#'   filter(year == 2022) %>%
#'   mutate(
#'     q1a    = as.double(unclass(q1a)),
#'     gend   = as.double(unclass(gend)),
#'     trust  = case_when(q1a <= 2 ~ 100, q1a <= 4 ~ 0),
#'     gender = case_when(gend == 1 ~ "Male", gend == 2 ~ "Female")
#'   ) %>%
#'   group_by(country, gender) %>%
#'   summarise(
#'     mean = mean(trust, na.rm = TRUE),
#'     sd   = sd(trust, na.rm = TRUE),
#'     n    = sum(!is.na(trust)),
#'     .groups = "drop"
#'   )
#'
#' wjp_dots(
#'   data4dots_ci,
#'   target      = "mean",
#'   grouping    = "country",
#'   colors      = "gender",
#'   cvec        = c("Male" = "#482d8b", "Female" = "#f26b21"),
#'   draw_ci     = TRUE,
#'   sd          = "sd",
#'   sample_size = "n"
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
      target_var   = all_of(target),
      colors_var   = all_of(colors),
      grouping_var = all_of(grouping)
    ) %>%
    mutate(target_var = as.numeric(target_var)) # Ensure target_var is numeric

  if (is.null(order)) {
    data <- data %>%
      group_by(colors_var) %>%
      mutate(
        order_var = row_number()
      )
  } else {
    data <- data %>%
      rename(order_var = all_of(order))
  }

  # Supplying opacity/shape vectors enables the respective aesthetics
  if (!is.null(opacities)) diffOpac <- TRUE
  if (length(shapes) > 1 || !all(is.na(shapes))) diffShp <- TRUE

  # Default to the WJP palette when no color vector is supplied
  if (is.null(cvec)) {
    cvec <- wjp_default_cvec(data$colors_var)
  }

  # Compute confidence intervals if requested
  if (draw_ci) {
    if (is.null(sd) || is.null(sample_size)) {
      stop("`sd` and `sample_size` must be provided when draw_ci = TRUE.", call. = FALSE)
    }
    z <- stats::qnorm(1 - 0.05 / 2)
    data  <- data %>%
      rename(sd_var          = all_of(sd),
             sample_size_var = all_of(sample_size)) %>%
      mutate(
        se    = sd_var / sqrt(sample_size_var),
        lower = target_var - z * se,
        upper = target_var + z * se
      )
  }

  # Creating an alternating strip pattern
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
                show.legend = FALSE) +
    scale_fill_manual(values = c("grey"  = "#EBEBEB",
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

  # Point layer: opacity and shape aesthetics are added only when requested
  point_aes <- aes(x     = reorder(grouping_var, -order_var),
                   y     = target_var,
                   color = colors_var)
  if (diffShp) {
    point_aes <- utils::modifyList(point_aes, aes(shape = colors_var))
  }
  if (diffOpac) {
    point_aes <- utils::modifyList(point_aes, aes(alpha = colors_var))
  }

  plt <- plt +
    geom_point(data        = data,
               mapping     = point_aes,
               fill        = NA,
               size        = 4,
               stroke      = if (diffShp) 2 else 0.5,
               show.legend = FALSE)

  if (diffShp) {
    plt <- plt +
      scale_shape_manual(values = shapes)
  }
  if (diffOpac) {
    plt <- plt +
      scale_alpha_manual(values = opacities)
  }

  plt <- plt +
    scale_color_manual(values = cvec) +
    scale_y_continuous(limits = c(0, 100),
                       breaks = seq(0, 100, 20),
                       labels = paste0(seq(0, 100, 20),
                                       "%"),
                       position = "right") +
    coord_flip() +
    ptheme +
    theme(axis.title.x       = element_blank(),
          axis.title.y       = element_blank(),
          panel.grid.major.y = element_blank(),
          panel.background   = element_blank(),
          panel.ontop        = TRUE,
          axis.text.y        = element_text(color = "#524F4C",
                                            hjust = 0))

  return(plt)

}
