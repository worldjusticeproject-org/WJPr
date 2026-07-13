#' Plot a Horizontal Edgebars Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `wjp_edgebars()` takes a data frame with long-format data and returns a
#' ggplot object with an edgebar chart following WJP style guidelines.
#' Edgebars are horizontal bars with the category label placed at the edge of
#' each bar, which makes them ideal for narrow spaces and long labels.
#' Values are expected on a 0-100 percentage scale.
#'
#' @param data Data frame containing the data to plot.
#' @param target String. Column name of the variable that supplies the values to plot.
#' @param grouping String. Column name of the variable that supplies the categories.
#' @param labels String. Column name of the variable containing the text labels to
#'   display above each bar. Default is `NULL` (the `grouping` values are used).
#' @param cvec String. Hex code of the color for the bars. Default is `NULL`
#'   (the WJP primary violet `#482d8b` is applied).
#' @param x_lab_pos String. Column name of the variable that contains the display
#'   order of the bars. Default is `NULL` (data order).
#' @param y_lab_pos Numeric. Y-axis position for the text labels. Default is `0`.
#' @param nudge_lab Numeric. Padding for the text labels in millimeters.
#'   Default is `2.5`.
#' @param margin_top Numeric. Top margin of the plot. Default is `20`.
#' @param bar_width Numeric. Width of the bars. The default of `0.35` is recommended
#'   for single bars; use `0.5` for plots with two bars.
#' @param ptheme ggplot theme to apply. Default is [WJP_theme()].
#'
#' @return A ggplot object representing the edgebars plot.
#' @export
#'
#' @examples
#' library(dplyr)
#'
#' # Always load the WJP fonts
#' wjp_fonts()
#'
#' # Percentage of people that trust their institutions, by country
#' data4edgebars <- WJPr::gpp %>%
#'   filter(year == 2022) %>%
#'   mutate(
#'     q1a   = as.double(unclass(q1a)),
#'     trust = case_when(q1a <= 2 ~ 1, q1a <= 4 ~ 0)
#'   ) %>%
#'   group_by(country) %>%
#'   summarise(trust = mean(trust, na.rm = TRUE) * 100, .groups = "drop")
#'
#' wjp_edgebars(
#'   data4edgebars,
#'   target   = "trust",
#'   grouping = "country",
#'   cvec     = "#2894aa"
#' )
#'
wjp_edgebars <- function(
    data,
    target,
    grouping,
    labels       = NULL,
    cvec         = NULL,
    x_lab_pos    = NULL,
    y_lab_pos    = 0,
    nudge_lab    = 2.5,
    margin_top   = 20,
    bar_width    = 0.35,
    ptheme       = WJP_theme()
  ) {

  # Single accent color for the bars
  if (is.null(cvec)) {
    cvec <- c("anchor" = "#482d8b")
  } else {
    cvec <- c("anchor" = cvec)
  }

  data <- data %>%
    mutate(
      color = "anchor"
    )

  if (is.null(x_lab_pos)) {
    x_lab_pos <- "label_position"
    data <- data %>%
      ungroup() %>%
      mutate(
        label_position = row_number()
      )
  }

  # Rename columns, handling case where grouping == labels
  data <- data %>%
    rename(
      y_value   = all_of(target),
      x_var     = all_of(grouping),
      x_lab_pos = all_of(x_lab_pos)
    )

  # Handle label_var separately: default to the category names and avoid a
  # duplicate rename when grouping == labels
  if (is.null(labels) || identical(grouping, labels)) {
    data <- data %>%
      mutate(label_var = x_var)
  } else {
    data <- data %>%
      rename(label_var = all_of(labels))
  }

  # Creating plot
  plt <- ggplot(
    data = data,
    aes(
      x    = reorder(x_var, -x_lab_pos),
      y    = y_value,
      fill = color
    )
  ) +
    geom_bar(
      position = "dodge",
      stat     = "identity",
      width    = bar_width,
      show.legend = FALSE
    )

  # Add rich text labels if ggtext is available
  if (requireNamespace("ggtext", quietly = TRUE)) {
    plt <- plt +
      ggtext::geom_richtext(
        aes(
          x        = reorder(x_var, -x_lab_pos),
          y        = y_lab_pos,
          label    = label_var,
          family   = "Lato Full",
          fontface = "plain"
        ),
        fill  = NA,
        hjust = 0,
        vjust = 0,
        size  = 3.514598,
        label.color = NA,
        label.padding = unit(c(0, 0, nudge_lab, 0), "mm")
      )
  } else {
    plt <- plt +
      geom_text(
        aes(
          x     = reorder(x_var, -x_lab_pos),
          y     = y_lab_pos,
          label = label_var
        ),
        family   = "Lato Full",
        hjust    = 0,
        vjust    = 0,
        size     = 3.514598
      )
  }

  plt <- plt +
    geom_text(
      aes(
        x = reorder(x_var, -x_lab_pos),
        y = y_value,
        label = paste0(format(round(y_value, 0),
                              nsmall = 0),
                       "%")
      ),
      color    = "#4a4a49",
      position = position_dodge(width = bar_width),
      family   = "Lato Full",
      fontface = "bold",
      size     = 3.514598,
      hjust    = -0.1
    ) +
    scale_fill_manual(
      values = cvec
    ) +
    scale_y_continuous(
      expand = expansion(mult = c(0, 0.15))
    ) +
    coord_flip(clip = "off") +
    ptheme +
    theme(
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_blank(),
      axis.text.y        = element_blank(),
      axis.title.x       = element_blank(),
      axis.title.y       = element_blank(),
      axis.text.x        = element_blank(),
      plot.margin        = margin(margin_top, 10, -15, 0),
      plot.background    = element_blank()
    )

  return(plt)
}
