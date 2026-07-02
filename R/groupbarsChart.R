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
#' Values supplied to \code{target}, \code{national_value}, \code{ci_lower}, and
#' \code{ci_upper} can be provided as proportions (0-1) or percentages (0-100).
#' Internally they are plotted on a 0-100 percentage scale. Confidence intervals
#' can be supplied directly with \code{ci_lower} and \code{ci_upper}, or computed
#' from \code{sd} and \code{sample_size}. When \code{show_national = TRUE}, use
#' \code{national_style = "line"} to draw \code{national_value} as a vertical
#' reference line, or \code{national_style = "bar"} to add it as a full bar row
#' using the same geometry, confidence interval, and label logic as the other
#' rows.
#'
#' @param data A data frame containing the data to be plotted.
#' @param target String. Column name containing the numeric values to plot. Values
#'   can be proportions (0-1) or percentages (0-100).
#' @param grouping String. Column name for the faceting variable (e.g., "Gender", "Age Group").
#' @param levels String. Column name for the categories within each group (e.g., "Male", "Female").
#' @param colors Character vector of length 2 with hex colors for primary and secondary bars.
#'   Default is c("#575796", "#e5e8e8").
#' @param labels String. Column name containing custom labels. If NULL, percentages are auto-generated.
#'   Default is NULL.
#' @param group_order Character vector specifying the order of all facet groups.
#'   Default is NULL (uses data order).
#' @param level_order Named list where names are group values and values are character vectors
#'   specifying the order of levels within each group. Default is NULL (uses data order).
#' @param show_national Logical. If TRUE, adds a vertical national average line
#'   and a rich text annotation by default, or a national average bar when
#'   \code{national_style = "bar"}. Default is FALSE.
#' @param national_value Numeric. The national average value to display when show_national is TRUE.
#' @param national_label String. Optional single rich text label for the national
#'   average annotation. If NULL, a label is generated from \code{national_value}.
#' @param national_style String. How to display the national value when
#'   \code{show_national = TRUE}: "line", "bar", or "none". Default is "line".
#' @param national_position String. Position of the national bar when
#'   \code{national_style = "bar"}: "top" or "bottom". Default is "top".
#' @param national_ci_lower Numeric. Optional lower confidence interval bound for
#'   the national bar. Uses the same 0-1 or 0-100 scale detection as \code{target}.
#' @param national_ci_upper Numeric. Optional upper confidence interval bound for
#'   the national bar. Uses the same 0-1 or 0-100 scale detection as \code{target}.
#' @param national_group_label String. Facet label used for the national bar.
#'   Default is " " to create a blank facet strip.
#' @param draw_ci Logical. If TRUE, draws a per-category confidence interval on each
#'   primary bar. Default is FALSE.
#' @param ci_lower String. Optional column name with precomputed lower confidence
#'   interval bounds. If supplied, \code{ci_upper} must also be supplied.
#' @param ci_upper String. Optional column name with precomputed upper confidence
#'   interval bounds. If supplied, \code{ci_lower} must also be supplied.
#' @param sd String. Column name with the standard deviation used to build the
#'   confidence interval when \code{ci_lower} and \code{ci_upper} are not supplied.
#'   Default is NULL.
#' @param sample_size String. Column name with the number of observations used to
#'   build the confidence interval when \code{ci_lower} and \code{ci_upper} are not
#'   supplied. Default is NULL.
#' @param ci_level Numeric. Confidence level for the interval. Default is 0.95.
#' @param ptheme A ggplot2 theme. Default is WJP_theme().
#' @param label_position String. Position for value labels: "end", "inside", or
#'   "none". Default is "end".
#' @param label_after_ci Logical. If TRUE and confidence intervals are drawn,
#'   places labels after the upper CI bound when available. Default is TRUE.
#' @param facet_ncol Integer. Number of facet columns. Default is 1.
#' @param bar_width Numeric. Width of bars. Default is 0.7.
#' @param show_axis Logical. If TRUE, displays the X axis with percentage breaks
#'   (0%, 25%, 50%, 75%, 100%) at the bottom. Default is FALSE.
#' @param strip_position String. Position of facet strip labels: "left" places them
#'   vertically on the left side, "top" places them horizontally above each group.
#'   Default is "left".
#' @param national_var String. Value in the \code{grouping} column that identifies
#'   the national average row (e.g., "general", "Overall"). When specified, this row
#'   is displayed with a special formatted label (bold, italic, colored) using
#'   \code{geom_richtext()}. Default is NULL.
#' @param national_level String. Value in the \code{levels} column corresponding to
#'   the national average label (e.g., "National Average"). Required when
#'   \code{national_var} is specified. Default is NULL.
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
#' # With a per-category confidence interval (requires sd + sample_size columns)
#' data_ci <- data.frame(
#'   group    = c("Gender", "Gender", "Age", "Age", "Age"),
#'   category = c("Male", "Female", "18-29", "30-49", "50+"),
#'   value    = c(0.45, 0.52, 0.38, 0.48, 0.55),
#'   se       = c(0.50, 0.50, 0.49, 0.50, 0.50),
#'   n        = c(420, 460, 180, 510, 240)
#' )
#'
#' wjp_groupbars(
#'   data_ci,
#'   target      = "value",
#'   grouping    = "group",
#'   levels      = "category",
#'   draw_ci     = TRUE,
#'   sd          = "se",
#'   sample_size = "n"
#' )
#'
#' # Percentage-scale input with precomputed confidence intervals and a general line
#' data_pct <- data.frame(
#'   group    = c("Gender", "Gender", "Age", "Age"),
#'   category = c("Male", "Female", "18-29", "50+"),
#'   value    = c(74.4, 70.3, 72.1, 73.0),
#'   lower    = c(72.4, 68.4, 70.1, 70.8),
#'   upper    = c(76.4, 72.1, 74.5, 75.2)
#' )
#'
#' wjp_groupbars(
#'   data_pct,
#'   target         = "value",
#'   grouping       = "group",
#'   levels         = "category",
#'   draw_ci        = TRUE,
#'   ci_lower       = "lower",
#'   ci_upper       = "upper",
#'   show_national  = TRUE,
#'   national_value = 72.3,
#'   national_label = "General"
#' )
#'
#' # National average as its own bar with its own confidence interval
#' wjp_groupbars(
#'   data_pct,
#'   target            = "value",
#'   grouping          = "group",
#'   levels            = "category",
#'   draw_ci           = TRUE,
#'   ci_lower          = "lower",
#'   ci_upper          = "upper",
#'   show_national     = TRUE,
#'   national_value    = 72.3,
#'   national_style    = "bar",
#'   national_label    = "National Average",
#'   national_ci_lower = 70.0,
#'   national_ci_upper = 74.6
#' )
#'
#' # With visible X axis and strip labels on top (publication-style layout)
#' wjp_groupbars(
#'   data_pct,
#'   target            = "value",
#'   grouping          = "group",
#'   levels            = "category",
#'   draw_ci           = TRUE,
#'   ci_lower          = "lower",
#'   ci_upper          = "upper",
#'   show_national     = TRUE,
#'   national_value    = 72.3,
#'   national_style    = "bar",
#'   national_label    = "National Average",
#'   national_ci_lower = 70.0,
#'   national_ci_upper = 74.6,
#'   show_axis         = TRUE,
#'   strip_position    = "top"
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
    draw_ci        = FALSE,
    ci_lower       = NULL,
    ci_upper       = NULL,
    sd             = NULL,
    sample_size    = NULL,
    ci_level       = 0.95,
    ptheme         = WJP_theme(),
    national_label = NULL,
    national_style = "line",
    national_position = "top",
    national_ci_lower = NULL,
    national_ci_upper = NULL,
    national_group_label = " ",
    label_position = "end",
    label_after_ci = TRUE,
    facet_ncol     = 1,
    bar_width      = 0.7,
    show_axis      = FALSE,
    strip_position = "left",
    national_var   = NULL,
    national_level = NULL
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

  # Handle national_var: convert national grouping to empty space for facet
  use_national_richtext <- !is.null(national_var) && !is.null(national_level)
  national_group_empty <- " "

  if (use_national_richtext) {
    data <- data %>%
      dplyr::mutate(
        grouping_var = dplyr::if_else(
          grouping_var == national_var,
          national_group_empty,
          as.character(grouping_var)
        )
      )
  }

  numeric_arg <- function(x, arg) {
    raw_na <- is.na(x)
    if (is.factor(x)) {
      x <- as.character(x)
    }
    x <- suppressWarnings(as.numeric(x))
    if (any(!raw_na & is.na(x))) {
      stop(paste0(arg, " must contain numeric values."), call. = FALSE)
    }
    x
  }

  value_to_pct <- function(x, arg) {
    x <- numeric_arg(x, arg)
    observed <- x[!is.na(x)]

    if (length(observed) == 0) {
      return(x)
    }
    if (any(!is.finite(observed))) {
      stop(paste0(arg, " must contain finite numeric values."), call. = FALSE)
    }
    if (any(observed < 0 | observed > 100)) {
      stop(paste0(arg, " must contain proportions (0-1) or percentages (0-100)."), call. = FALSE)
    }
    if (max(observed) <= 1) {
      x * 100
    } else {
      x
    }
  }

  format_pct <- function(x) {
    paste0(round(x, 0), "%")
  }

  # Handle labels

  if (is.null(labels)) {
    data <- data %>%
      dplyr::mutate(labels_var = NA_character_)
  } else {
    data <- data %>%
      dplyr::rename(labels_var = dplyr::all_of(labels)) %>%
      dplyr::mutate(labels_var = as.character(labels_var))
  }

  data <- data %>%
    dplyr::mutate(target_pct = value_to_pct(target_var, "`target`"))

  if (length(colors) != 2) {
    stop("`colors` must be a character vector of length 2.", call. = FALSE)
  }
  if (!label_position %in% c("end", "inside", "none")) {
    stop('`label_position` must be one of "end", "inside", or "none".', call. = FALSE)
  }
  if (length(facet_ncol) != 1 || !is.finite(facet_ncol) || facet_ncol < 1) {
    stop("`facet_ncol` must be a positive integer.", call. = FALSE)
  }
  facet_ncol <- as.integer(facet_ncol)
  if (length(bar_width) != 1 || !is.finite(bar_width) || bar_width <= 0 || bar_width > 1) {
    stop("`bar_width` must be a single number greater than 0 and no greater than 1.", call. = FALSE)
  }
  if (length(ci_level) != 1 || !is.finite(ci_level) || ci_level <= 0 || ci_level >= 1) {
    stop("`ci_level` must be a single number between 0 and 1.", call. = FALSE)
  }
  if (!national_style %in% c("line", "bar", "none")) {
    stop('`national_style` must be one of "line", "bar", or "none".', call. = FALSE)
  }
  if (!national_position %in% c("top", "bottom")) {
    stop('`national_position` must be one of "top" or "bottom".', call. = FALSE)
  }
  if (length(label_after_ci) != 1 || !is.logical(label_after_ci)) {
    stop("`label_after_ci` must be TRUE or FALSE.", call. = FALSE)
  }
  if (length(national_group_label) != 1) {
    stop("`national_group_label` must be a single string.", call. = FALSE)
  }
  if (length(show_axis) != 1 || !is.logical(show_axis)) {
    stop("`show_axis` must be TRUE or FALSE.", call. = FALSE)
  }
  if (!strip_position %in% c("left", "top")) {
    stop('`strip_position` must be one of "left" or "top".', call. = FALSE)
  }
  if (!is.null(national_var) && is.null(national_level)) {
    stop("`national_level` must be provided when `national_var` is specified.", call. = FALSE)
  }
  if (is.null(national_var) && !is.null(national_level)) {
    stop("`national_var` must be provided when `national_level` is specified.", call. = FALSE)
  }

  # ===========================================================================
  # HELPER FUNCTION: Calculate position for national average label

  # ===========================================================================

  calculate_national_label_position <- function(data2plot,
                                                 national_group,
                                                 national_level_val,
                                                 group_levels,
                                                 level_order,
                                                 colors_primary,
                                                 label_text) {
    # Build the y_id for national average
    national_y_id <- paste(national_group, national_level_val, sep = " | ")

    # Check if it exists in the data
    if (!national_y_id %in% level_order) {
      warning("National average level not found in data")
      return(NULL)
    }

    # Create data.frame for geom_richtext
    # x = 0 (start of bar)
    # y = the corresponding factor level
    # hjust = 1.02 so text ends just before the bar
    label_df <- data.frame(
      grouping_var = factor(national_group, levels = group_levels),
      x = 0,
      y_id = factor(national_y_id, levels = level_order),
      label = paste0(
        "<b><i><span style='color:", colors_primary, "'>", label_text, "</span></i></b>"
      ),
      stringsAsFactors = FALSE
    )

    return(label_df)
  }

  national_value_pct <- NULL
  national_ci_lower_pct <- NULL
  national_ci_upper_pct <- NULL
  if (isTRUE(show_national) && national_style != "none") {
    if (is.null(national_value)) {
      stop("`national_value` must be provided when show_national = TRUE.", call. = FALSE)
    }
    if (length(national_value) != 1 || !is.finite(national_value) ||
        national_value < 0 || national_value > 100) {
      stop("`national_value` must be a single proportion (0-1) or percentage (0-100).", call. = FALSE)
    }
    national_value_pct <- if (national_value <= 1) national_value * 100 else national_value
    if (!is.null(national_label) && length(national_label) != 1) {
      stop("`national_label` must be a single string.", call. = FALSE)
    }
    if (!is.null(national_ci_lower) || !is.null(national_ci_upper)) {
      if (is.null(national_ci_lower) || is.null(national_ci_upper)) {
        stop("`national_ci_lower` and `national_ci_upper` must both be provided.", call. = FALSE)
      }
      if (length(national_ci_lower) != 1 || length(national_ci_upper) != 1) {
        stop("`national_ci_lower` and `national_ci_upper` must be single numeric values.", call. = FALSE)
      }
      national_ci_lower_pct <- value_to_pct(national_ci_lower, "`national_ci_lower`")
      national_ci_upper_pct <- value_to_pct(national_ci_upper, "`national_ci_upper`")
      if (national_ci_lower_pct > national_ci_upper_pct) {
        stop("`national_ci_lower` must be less than or equal to `national_ci_upper`.", call. = FALSE)
      }
    }
  }

  # ===========================================================================
  # 2. PREPARE DATA FOR STACKED BARS
  # ===========================================================================

  # Build per-category confidence interval (normal approximation)
  if (draw_ci) {
    if (!is.null(ci_lower) || !is.null(ci_upper)) {
      if (is.null(ci_lower) || is.null(ci_upper)) {
        stop("`ci_lower` and `ci_upper` must both be provided when using precomputed intervals.", call. = FALSE)
      }
      data <- data %>%
        dplyr::rename(
          ci_lower_var = dplyr::all_of(ci_lower),
          ci_upper_var = dplyr::all_of(ci_upper)
        ) %>%
        dplyr::mutate(
          lower = pmax(0, value_to_pct(ci_lower_var, "`ci_lower`")),
          upper = pmin(100, value_to_pct(ci_upper_var, "`ci_upper`"))
        )
    } else {
      if (is.null(sd) || is.null(sample_size)) {
        stop(
          "`ci_lower` and `ci_upper`, or `sd` and `sample_size`, must be provided when draw_ci = TRUE.",
          call. = FALSE
        )
      }
      z <- stats::qnorm(1 - (1 - ci_level) / 2)
      data <- data %>%
        dplyr::rename(
          sd_var          = dplyr::all_of(sd),
          sample_size_var = dplyr::all_of(sample_size)
        ) %>%
        dplyr::mutate(
          sd_pct          = value_to_pct(sd_var, "`sd`"),
          sample_size_var = numeric_arg(sample_size_var, "`sample_size`")
        )

      if (any(!is.na(data$sample_size_var) & (!is.finite(data$sample_size_var) | data$sample_size_var <= 0))) {
        stop("`sample_size` must contain positive finite values.", call. = FALSE)
      }

      data <- data %>%
        dplyr::mutate(
          se    = sd_pct / sqrt(sample_size_var),
          lower = pmax(0, target_pct - z * se),
          upper = pmin(100, target_pct + z * se)
        )
    }

    if (any(!is.na(data$lower) & !is.na(data$upper) & data$lower > data$upper)) {
      stop("Confidence interval lower bounds must be less than or equal to upper bounds.", call. = FALSE)
    }
  }

  national_is_bar <- isTRUE(show_national) && national_style == "bar"
  national_is_line <- isTRUE(show_national) && national_style == "line"

  # Store national bar label for later use in axis styling
  national_bar_label <- NULL

  if (national_is_bar) {
    national_bar_label <- if (is.null(national_label)) {
      "National Average"
    } else {
      as.character(national_label)
    }

    national_row <- data.frame(
      target_var   = national_value,
      grouping_var = national_group_label,
      levels_var   = national_bar_label,
      labels_var   = NA_character_,
      target_pct   = national_value_pct,
      lower        = if (!is.null(national_ci_lower_pct)) national_ci_lower_pct else NA_real_,
      upper        = if (!is.null(national_ci_upper_pct)) national_ci_upper_pct else NA_real_,
      stringsAsFactors = FALSE
    )

    data <- if (national_position == "top") {
      dplyr::bind_rows(national_row, data)
    } else {
      dplyr::bind_rows(data, national_row)
    }
  }

  # Create stacked data (primary + secondary = 100%)
  data2plot <- data %>%
    dplyr::mutate(
      primary   = target_pct,
      secondary = 100 - target_pct
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
          format_pct(value)
        ),
        NA_character_
      ),
      # Use custom labels if provided
      label_value = dplyr::if_else(
        !is.na(labels_var) & color_type == "primary",
        labels_var,
        label_value
      ),
      label_x = dplyr::case_when(
        color_type != "primary" ~ NA_real_,
        label_position == "inside" ~ pmax(0, value - 2),
        TRUE ~ pmin(113, value + 1)
      )
    )

  if (draw_ci && label_position == "end" && isTRUE(label_after_ci)) {
    data2plot <- data2plot %>%
      dplyr::mutate(
        label_x = dplyr::if_else(
          color_type == "primary",
          pmin(113, dplyr::coalesce(upper, value) + 1),
          NA_real_
        )
      )
  }

  # ===========================================================================
  # 3. APPLY ORDERING
  # ===========================================================================

  # Order groups (facets)
  if (!is.null(group_order)) {
    if (national_is_bar) {
      group_order <- if (national_position == "top") {
        unique(c(national_group_label, group_order))
      } else {
        unique(c(group_order, national_group_label))
      }
    }
    missing_groups <- setdiff(unique(as.character(data2plot$grouping_var)), group_order)
    if (length(missing_groups) > 0) {
      stop("`group_order` must include all values from `grouping`.", call. = FALSE)
    }
    data2plot <- data2plot %>%
      dplyr::mutate(
        grouping_var = factor(grouping_var, levels = group_order)
      )
  }

  # Create y-axis identifier combining group and level
  data2plot <- data2plot %>%
    dplyr::mutate(
      y_id = paste(grouping_var, levels_var, sep = " | ")
    )

  # Order levels within groups
  if (!is.null(level_order)) {
    # Build ordered levels vector
    all_levels <- character(0)

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

  national_label_data <- NULL
  if (national_is_line) {
    national_group <- if (!is.null(group_order)) {
      available_groups <- group_order[group_order %in% as.character(data2plot$grouping_var)]
      if (length(available_groups) > 0) {
        available_groups[1]
      } else {
        as.character(unique(data2plot$grouping_var))[1]
      }
    } else {
      as.character(unique(data2plot$grouping_var))[1]
    }

    national_y_levels <- data2plot$y_id[as.character(data2plot$grouping_var) == national_group]
    national_top_y <- tail(levels(droplevels(national_y_levels)), 1)
    national_y <- paste(national_group, ".national_average", sep = " | ")
    y_levels <- levels(data2plot$y_id)
    y_levels <- append(y_levels, national_y, after = match(national_top_y, y_levels))
    data2plot <- data2plot %>%
      dplyr::mutate(y_id = factor(as.character(y_id), levels = y_levels))

    if (is.null(national_label)) {
      national_label <- paste0(
        "<b>National Average</b><br>",
        round(national_value_pct, 0),
        "%"
      )
    } else if (!grepl("<|%|\\n|<br", national_label)) {
      national_label <- paste0("<b>", national_label, "</b><br>", round(national_value_pct, 0), "%")
    }

    national_label_data <- data.frame(
      grouping_var = national_group,
      y_id         = national_y,
      x            = national_value_pct,
      label        = national_label,
      hjust        = dplyr::case_when(
        national_value_pct <= 15 ~ 0,
        national_value_pct >= 85 ~ 1,
        TRUE                  ~ 0.5
      )
    )

    if (is.factor(data2plot$grouping_var)) {
      national_label_data$grouping_var <- factor(
        national_label_data$grouping_var,
        levels = levels(data2plot$grouping_var)
      )
    }
    national_label_data$y_id <- factor(national_label_data$y_id, levels = levels(data2plot$y_id))
  }

  # ===========================================================================
  # 5. CREATE PLOT
  # ===========================================================================

  plt <- ggplot2::ggplot(
    data2plot,
    ggplot2::aes(x = value, y = y_id, fill = color_type)
  ) +
    ggplot2::geom_col(
      position = ggplot2::position_stack(reverse = TRUE),
      width    = bar_width,
      na.rm    = TRUE
    ) +
    ggplot2::scale_fill_manual(values = cvec) +
    ggplot2::scale_x_continuous(
      expand   = c(0, 0),
      limits   = c(0, if (show_axis) 100 else 115),
      breaks   = if (show_axis) c(0, 25, 50, 75, 100) else ggplot2::waiver(),
      labels   = if (show_axis) function(x) paste0(x, "%") else ggplot2::waiver(),
      position = if (show_axis) "bottom" else "top",
      oob      = scales::oob_keep
    ) +
    ggplot2::scale_y_discrete(
      labels = function(x) {
        label <- sub("^.* \\| ", "", x)
        label <- ifelse(label == ".national_average", "", label)
        # Hide national_level when using national_var (will be shown via geom_richtext)
        if (use_national_richtext) {
          label <- ifelse(label == national_level, "", label)
        }
        # Color national bar label with primary color if ggtext is available
        if (!is.null(national_bar_label) && requireNamespace("ggtext", quietly = TRUE)) {
          label <- ifelse(
            label == national_bar_label,
            paste0("<span style='color:", colors[1], "'>", label, "</span>"),
            label
          )
        }
        label
      }
    ) +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::labs(x = "", y = "")

  if (facet_ncol == 1) {
    if (strip_position == "top") {
      plt <- plt +
        ggplot2::facet_grid(
          rows   = ggplot2::vars(grouping_var),
          scales = "free",
          space  = "free_y"
        )
    } else {
      plt <- plt +
        ggplot2::facet_grid(
          rows   = ggplot2::vars(grouping_var),
          scales = "free",
          space  = "free_y",
          switch = "y"
        )
    }
  } else {
    plt <- plt +
      ggplot2::facet_wrap(
        ggplot2::vars(grouping_var),
        scales = "free_y",
        ncol   = facet_ncol,
        strip.position = if (strip_position == "top") "top" else "left"
      )
  }

  if (label_position != "none") {
    plt <- plt +
      ggplot2::geom_text(
        ggplot2::aes(x = label_x, label = label_value),
        family   = "Lato Full",
        fontface = "bold",
        color    = if (label_position == "inside") "#ffffff" else colors[1],
        hjust    = if (label_position == "inside") 1 else 0,
        size     = 3.5,
        na.rm    = TRUE
      )
  }

  if (national_is_line) {
    plt <- plt +
      ggplot2::geom_vline(
        xintercept = national_value_pct,
        linetype   = "dashed",
        color      = colors[1],
        linewidth  = 0.7,
        inherit.aes = FALSE
      )

    if (requireNamespace("ggtext", quietly = TRUE)) {
      plt <- plt +
        ggtext::geom_richtext(
          data = national_label_data,
          ggplot2::aes(x = x, y = y_id, label = label, hjust = hjust),
          inherit.aes   = FALSE,
          family        = "Lato Full",
          fontface      = "plain",
          color         = colors[1],
          fill          = NA,
          label.color   = NA,
          label.padding = grid::unit(c(1.5, 1.5, 1.5, 1.5), "mm"),
          size          = 3.2,
          vjust         = 0.5
        )
    } else {
      plt <- plt +
        ggplot2::geom_text(
          data = national_label_data,
          ggplot2::aes(
            x     = x,
            y     = y_id,
            label = gsub("<[^>]+>", "", gsub("<br\\s*/?>", "\n", label)),
            hjust = hjust
          ),
          inherit.aes = FALSE,
          family      = "Lato Full",
          fontface    = "plain",
          color       = colors[1],
          size        = 3.2,
          vjust       = 0.5
        )
    }
  }

  # Overlay the confidence interval on each primary bar
  if (draw_ci) {
    plt <- plt +
      ggplot2::geom_errorbar(
        data = dplyr::filter(data2plot, color_type == "primary"),
        ggplot2::aes(y = y_id, xmin = lower, xmax = upper),
        orientation = "y",
        inherit.aes = FALSE,
        width       = 0.25,
        linewidth   = 0.6,
        color       = "#4a4a4a",
        na.rm       = TRUE
      )
  }

  # Add richtext label for national average when national_var is specified
  if (use_national_richtext && requireNamespace("ggtext", quietly = TRUE)) {
    # Get group levels and level order from the plot data
    group_levels_vec <- levels(data2plot$grouping_var)
    if (is.null(group_levels_vec)) {
      group_levels_vec <- unique(as.character(data2plot$grouping_var))
    }
    level_order_vec <- levels(data2plot$y_id)
    if (is.null(level_order_vec)) {
      level_order_vec <- unique(as.character(data2plot$y_id))
    }

    # Calculate position for national label
    national_richtext_df <- calculate_national_label_position(
      data2plot         = data2plot,
      national_group    = national_group_empty,
      national_level_val = national_level,
      group_levels      = group_levels_vec,
      level_order       = level_order_vec,
      colors_primary    = colors[1],
      label_text        = national_level
    )

    if (!is.null(national_richtext_df)) {
      plt <- plt +
        ggtext::geom_richtext(
          data        = national_richtext_df,
          ggplot2::aes(x = x, y = y_id, label = label),
          inherit.aes = FALSE,
          hjust       = 1.02,
          vjust       = 0.5,
          fill        = NA,
          label.color = NA,
          size        = 3.5,
          family      = "Lato Full"
        )
    }
  }

  # ===========================================================================
  # 6. APPLY THEME
  # ===========================================================================

  # Base theme adjustments

  theme_base <- ggplot2::theme(
    strip.placement      = "outside",
    strip.background     = ggplot2::element_blank(),
    axis.title.x         = ggplot2::element_blank(),
    axis.title.y         = ggplot2::element_blank(),
    panel.grid.major.y   = ggplot2::element_blank(),
    panel.grid.major.x   = ggplot2::element_blank(),
    panel.grid.minor.x   = ggplot2::element_blank(),
    panel.spacing        = grid::unit(8, "mm"),
    strip.clip           = "off",
    legend.position      = "none"
  )

  # Axis X styling based on show_axis
  if (show_axis) {
    theme_axis <- ggplot2::theme(
      axis.text.x = ggplot2::element_text(
        size   = 9,
        family = "Lato Full",
        face   = "plain",
        color  = "#4a4a4a"
      ),
      axis.ticks.x = ggplot2::element_line(color = "#d0d0d0", linewidth = 0.3),
      axis.ticks.length.x = grid::unit(2, "mm")
    )
  } else {
    theme_axis <- ggplot2::theme(
      axis.text.x = ggplot2::element_blank()
    )
  }

  # Axis Y styling - use element_markdown if ggtext available and national bar exists
  if (!is.null(national_bar_label) && requireNamespace("ggtext", quietly = TRUE)) {
    theme_axis_y <- ggplot2::theme(
      axis.text.y = ggtext::element_markdown(
        size   = 10,
        hjust  = 1,
        family = "Lato Full"
      )
    )
  } else {
    theme_axis_y <- ggplot2::theme(
      axis.text.y = ggplot2::element_text(
        size   = 10,
        hjust  = 1,
        family = "Lato Full",
        face   = "plain"
      )
    )
  }

  # Strip styling based on strip_position
  if (strip_position == "top") {
    theme_strip <- ggplot2::theme(
      strip.text.y = ggplot2::element_text(
        size   = 11,
        color  = colors[1],
        hjust  = 0,
        family = "Lato Full",
        face   = "plain"
      ),
      plot.margin = ggplot2::margin(10, 30, 10, 10)
    )
  } else {
    theme_strip <- ggplot2::theme(
      strip.text.y.left = ggplot2::element_text(
        angle  = 0,
        size   = 11,
        color  = colors[1],
        hjust  = 1,
        vjust  = 0.5,
        family = "Lato Full",
        face   = "bold",
        margin = ggplot2::margin(0, 0, 0, 0)
      ),
      strip.switch.pad.grid = grid::unit(0, "mm"),
      plot.margin = ggplot2::margin(10, 30, 10, 40)
    )
  }

  plt <- plt +
    ptheme +
    theme_base +
    theme_axis +
    theme_axis_y +
    theme_strip

  return(plt)
}
