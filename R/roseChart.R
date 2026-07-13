#' Plot a Rose Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `wjp_rose()` takes a data frame with long-format data and returns a ggplot
#' object with a rose (polar bar) chart following WJP style guidelines. Rose
#' charts display the values of a single unit across multiple dimensions.
#' Values can be supplied as proportions (0-1) or percentages (0-100).
#'
#' @details
#' The function expects one row per dimension (petal): the dimension name in
#' `grouping`, its value in `target`, and the text to display around the
#' chart in `labels`. By default petals are ordered by value; pass an
#' `order` column for a custom arrangement. Labels support HTML/markdown
#' formatting when the ggtext package is installed.
#'
#' @param data Data frame containing the data to plot.
#' @param target String. Column name of the variable that supplies the values to plot.
#' @param grouping String. Column name of the variable that supplies the dimensions
#'   (one petal per dimension).
#' @param labels String. Column name of the variable containing the labels to display
#'   around the chart.
#' @param cvec Vector of colors, one per dimension. Default is `NULL`
#'   (the WJP palette, see [wjp_palette()], is applied).
#' @param order String. Column name of the variable that contains the display order of
#'   the dimensions. Default is `NULL` (dimensions are ordered by value).
#' @param order_var `r lifecycle::badge("deprecated")` Use `order` instead.
#' @param ptheme ggplot theme to apply. Default is [WJP_theme()].
#'
#' @return A ggplot object representing the rose chart.
#' @export
#'
#' @examples
#' library(dplyr)
#' library(tidyr)
#'
#' # Always load the WJP fonts
#' wjp_fonts()
#'
#' # Opinions about authorities as a single-unit profile
#' data4rose <- WJPr::gpp %>%
#'   select(starts_with("q49")) %>%
#'   mutate(
#'     across(starts_with("q49"), \(x) as.double(unclass(x))),
#'     across(starts_with("q49"), \(x) case_when(x <= 2 ~ 1, x <= 99 ~ 0))
#'   ) %>%
#'   summarise(across(starts_with("q49"), \(x) mean(x, na.rm = TRUE) * 100)) %>%
#'   pivot_longer(everything(), names_to = "category", values_to = "percentage") %>%
#'   mutate(axis_label = category)
#'
#' wjp_rose(
#'   data4rose,
#'   target   = "percentage",
#'   grouping = "category",
#'   labels   = "axis_label"
#' )
#'
wjp_rose <- function(
    data,
    target,
    grouping,
    labels,
    cvec      = NULL,
    order     = NULL,
    order_var = NULL,
    ptheme    = WJP_theme()
){

  # Backwards compatibility: `order_var` was renamed to `order`
  if (is.null(order) && !is.null(order_var)) {
    order <- order_var
  }

  # Renaming variables in the data frame to match the function naming
  data <- data %>%
    rename(
      target_var   = all_of(target),
      grouping_var = all_of(grouping),
      alabels_var  = all_of(labels),
    )

  # Accept percentages (0-100) as well as proportions (0-1)
  max_target <- suppressWarnings(max(abs(data$target_var), na.rm = TRUE))
  if (is.finite(max_target) && max_target > 1) {
    data <- data %>%
      mutate(target_var = target_var / 100)
  }

  if (is.null(order)) {
    data <- data %>%
      arrange(target_var) %>%
      mutate(order_var = row_number())

    if (!is.null(cvec) && is.null(names(cvec))) {
      names(cvec) <- data %>%
        arrange(target_var) %>%
        pull(grouping_var)
    }
  } else {
    data <- data %>%
      rename(order_var = all_of(order))
  }

  # Default to the WJP palette when no color vector is supplied
  if (is.null(cvec)) {
    cvec <- wjp_default_cvec(data$grouping_var)
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
      ggtext::geom_richtext(aes(y     = 1.3,
                                label = alabels_var),
                            family      = "Lato Full",
                            fontface    = "plain",
                            color       = "#524F4C",
                            fill        = NA,
                            label.color = NA)
  } else {
    plt <- plt +
      geom_text(aes(y     = 1.3,
                    label = alabels_var),
                family   = "Lato Full",
                fontface = "plain",
                color    = "#524F4C")
  }

  plt <- plt +
    coord_polar(clip = "off") +
    scale_y_continuous(
      limits = c(-0.1, 1.35),
      breaks = c(0, 0.2, 0.4, 0.6, 0.8, 1)
    ) +
    scale_fill_manual(values = cvec) +
    ptheme +
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
