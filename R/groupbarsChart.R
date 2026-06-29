#' Plot a Grouped Stacked Bar Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `wjp_groupbars()` creates a faceted horizontal stacked bar chart where bars are
#' grouped by categories and show a primary value (e.g., percentage) stacked with
#' its complement. Useful for displaying survey results broken down by demographic
#' groups like gender, age, income, etc.
#'
#' @param data A data frame containing the data to be plotted.
#' @param target String. Column name containing the numeric values to plot (typically proportions 0-1).
#' @param grouping String. Column name for the faceting variable (e.g., "Gender", "Age Group").
#' @param levels String. Column name for the categories within each group (e.g., "Male", "Female").
#' @param colors Character vector of length 2 with hex colors for primary and secondary bars.
#'   Default is c("#575796", "#e5e8e8").
#' @param labels String. Column name containing custom labels. If NULL, percentages are auto-generated.
#'   Default is NULL.
#' @param group_order Character vector specifying the order of facet groups. Default is NULL (uses data order).
#' @param level_order Named list where names are group values and values are character vectors
#'   specifying the order of levels within each group. Default is NULL (uses data order).
#' @param show_national Logical. If TRUE, adds a "National Average" row at the top. Default is FALSE.
#' @param national_value Numeric. The national average value to display when show_national is TRUE.
#' @param ptheme A ggplot2 theme. Default is WJP_theme().
#'
#' @return A ggplot object representing the grouped stacked bar chart.
#' @export
#'
#' @examples
#' library(dplyr)
#' library(ggplot2)
#'
#' # Load WJP fonts (optional)
#' wjp_fonts()
#'
#' # Create sample data
#' data_groups <- data.frame(
#'   group = c("Gender", "Gender", "Age", "Age", "Age"),
#'   category = c("Male", "Female", "18-29", "30-49", "50+"),
#'   value = c(0.45, 0.52, 0.38, 0.48, 0.55)
#' )
#'
#' # Basic grouped bars
#' wjp_groupbars(
#'   data_groups,
#'   target   = "value",
#'   grouping = "group",
#'   levels   = "category"
#' )
#'
#' # With custom colors and group order
#' wjp_groupbars(
#'   data_groups,
#'   target      = "value",
#'   grouping    = "group",
#'   levels      = "category",
#'   colors      = c("#2a2a94", "#d0d1d3"),
#'   group_order = c("Gender", "Age")
#' )
#'

wjp_groupbars <- function(
    data,
    target,
    grouping,
    levels,
    colors         = c("#575796", "#e5e8e8"),
    labels         = NULL,
    group_order    = NULL,
    level_order    = NULL,
    show_national  = FALSE,
    national_value = NULL,
    ptheme         = WJP_theme()
) {

  # ===========================================================================
  # 1. RENAME VARIABLES
  # ===========================================================================

  data <- data %>%
    dplyr::rename(
      target_var   = dplyr::all_of(target),
      grouping_var = dplyr::all_of(grouping),
      levels_var   = dplyr::all_of(levels)
    )

  # Handle labels

if (is.null(labels)) {
    data <- data %>%
      dplyr::mutate(labels_var = NA_character_)
  } else {
    data <- data %>%
      dplyr::rename(labels_var = dplyr::all_of(labels))
  }

  if (any(!is.na(data$target_var) & (data$target_var < 0 | data$target_var > 1))) {
    stop("`target` must contain proportions between 0 and 1 for wjp_groupbars().", call. = FALSE)
  }

  # ===========================================================================
  # 2. PREPARE DATA FOR STACKED BARS
  # ===========================================================================

  # Add national average row if requested
  if (show_national && !is.null(national_value)) {
    national_row <- data.frame(
      target_var   = national_value,
      grouping_var = " ",
      levels_var   = "National Average",
      labels_var   = NA_character_
    )
    data <- dplyr::bind_rows(national_row, data)
  }

  # Create stacked data (primary + secondary = 100%)
  data2plot <- data %>%
    dplyr::mutate(
      primary   = target_var,
      secondary = 1 - target_var
    ) %>%
    tidyr::pivot_longer(
      cols      = c(primary, secondary),
      names_to  = "color_type",
      values_to = "value"
    ) %>%
    dplyr::mutate(
      # Generate percentage labels for primary bars only
      label_value = dplyr::if_else(
        color_type == "primary",
        dplyr::if_else(
          is.na(value),
          "NA",
          paste0(round(value * 100, 0), "%")
        ),
        NA_character_
      ),
      # Use custom labels if provided
      label_value = dplyr::if_else(
        !is.na(labels_var) & color_type == "primary",
        labels_var,
        label_value
      )
    )

  # ===========================================================================
  # 3. APPLY ORDERING
  # ===========================================================================

  # Order groups (facets)
  if (!is.null(group_order)) {
    if (show_national) {
      group_order <- c(" ", group_order)
    }
    data2plot <- data2plot %>%
      dplyr::mutate(
        grouping_var = factor(grouping_var, levels = group_order)
      )
  } else {
    if (show_national) {
      existing_groups <- unique(data2plot$grouping_var[data2plot$grouping_var != " "])
      group_order <- c(" ", existing_groups)
      data2plot <- data2plot %>%
        dplyr::mutate(
          grouping_var = factor(grouping_var, levels = group_order)
        )
    }
  }

  # Create y-axis identifier combining group and level
  data2plot <- data2plot %>%
    dplyr::mutate(
      y_id = dplyr::if_else(
        grouping_var == " ",
        " ",
        paste(grouping_var, levels_var, sep = " | ")
      )
    )

  # Order levels within groups
  if (!is.null(level_order)) {
    # Build ordered levels vector
    all_levels <- character(0)
    if (show_national) {
      all_levels <- " "
    }

    for (grp in names(level_order)) {
      lvls <- level_order[[grp]]
      all_levels <- c(all_levels, paste(grp, lvls, sep = " | "))
    }

    # Add any remaining levels not specified
    existing_ids <- unique(data2plot$y_id)
    remaining <- setdiff(existing_ids, all_levels)
    all_levels <- c(all_levels, remaining)

    data2plot <- data2plot %>%
      dplyr::mutate(y_id = factor(y_id, levels = all_levels))
  } else {
    # Use data order
    level_vec <- unique(data2plot$y_id)
    data2plot <- data2plot %>%
      dplyr::mutate(y_id = factor(y_id, levels = level_vec))
  }

  # ===========================================================================
  # 4. CREATE COLOR VECTOR
  # ===========================================================================

  cvec <- c("primary" = colors[1], "secondary" = colors[2])

  # ===========================================================================
  # 5. CREATE PLOT
  # ===========================================================================

  plt <- ggplot2::ggplot(
    data2plot,
    ggplot2::aes(x = value * 100, y = y_id, fill = color_type)
  ) +
    ggplot2::geom_col(
      position = ggplot2::position_stack(reverse = TRUE),
      width    = 0.9,
      na.rm    = TRUE
    ) +
    ggplot2::geom_text(
      ggplot2::aes(x = 101, label = label_value),
      family   = "Lato Full",
      fontface = "bold",
      color    = colors[1],
      hjust    = 0,
      size     = 3.5,
      na.rm    = TRUE
    ) +
    ggplot2::facet_grid(
      rows   = ggplot2::vars(grouping_var),
      scales = "free",
      space  = "free_y",
      switch = "y"
    ) +
    ggplot2::scale_fill_manual(values = cvec) +
    ggplot2::scale_x_continuous(
      expand   = c(0, 0),
      limits   = c(0, 115),
      position = "top"
    ) +
    ggplot2::scale_y_discrete(
      labels = function(x) sub("^.* \\| ", "", x)
    ) +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::labs(x = "", y = "")

  # ===========================================================================
  # 6. APPLY THEME
  # ===========================================================================

  plt <- plt +
    ptheme +
    ggplot2::theme(
      strip.placement      = "outside",
      strip.background     = ggplot2::element_blank(),
      axis.title.x         = ggplot2::element_blank(),
      axis.title.y         = ggplot2::element_blank(),
      axis.text.x          = ggplot2::element_blank(),
      axis.text.y          = ggplot2::element_text(
        size   = 10,
        hjust  = 1,
        family = "Lato Full",
        face   = "plain"
      ),
      panel.grid.major.y   = ggplot2::element_blank(),
      panel.grid.major.x   = ggplot2::element_blank(),
      panel.grid.minor.x   = ggplot2::element_blank(),
      panel.spacing        = grid::unit(8, "mm"),
      strip.text.y.left    = ggplot2::element_text(
        angle  = 0,
        size   = 11,
        color  = colors[1],
        hjust  = 1,
        vjust  = 1,
        family = "Lato Full",
        face   = "bold",
        margin = ggplot2::margin(-15, -25, 0, 40)
      ),
      strip.switch.pad.grid = grid::unit(-25, "mm"),
      strip.clip            = "off",
      legend.position       = "none",
      plot.margin           = ggplot2::margin(10, 30, 10, 10)
    )

  return(plt)
}
