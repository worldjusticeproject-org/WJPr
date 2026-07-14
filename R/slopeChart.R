#' Plot a Slope Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `wjp_slope()` takes a data frame with long-format data and returns a ggplot
#' object with a slope chart following WJP style guidelines. Slope charts
#' compare values between exactly two points in time. Each line is defined by
#' the `colors` variable. Values are expected on a 0-100 percentage scale.
#'
#' @details
#' The function expects long-format data with exactly two `grouping` values
#' (the two time points) per series. `grouping` must be numeric (e.g., years)
#' so the value labels can be placed just outside each endpoint. When labels
#' overlap, set `repel = TRUE` (requires the ggrepel package).
#'
#' @param data Data frame containing the data to plot.
#' @param target String. Column name of the variable that supplies the values to plot.
#' @param grouping String. Column name of the numeric variable that supplies the two
#'   X-axis values (usually years).
#' @param colors String. Column name of the variable that defines the lines and their
#'   color grouping. Default is `NULL` (a single line is drawn).
#' @param cvec Named vector of colors, one per line. Names should match the values of
#'   the `colors` variable. Default is `NULL` (the WJP palette, see [wjp_palette()],
#'   is applied).
#' @param labels String. Column name of the variable containing the value labels to
#'   display. Default is `NULL` (no labels).
#' @param repel Logical. If `TRUE`, the ggrepel package is used to avoid overlapping
#'   labels. Default is `FALSE`.
#' @param ngroups `r lifecycle::badge("deprecated")` Grouping vector for the lines.
#'   Retained for backwards compatibility; lines are now grouped by `colors`
#'   automatically.
#' @param ptheme ggplot theme to apply. Default is [WJP_theme()].
#' @param show_legend Logical. If `TRUE`, displays a horizontal series legend above
#'   the chart when `colors` is supplied. Default is `FALSE`.
#'
#' @return A ggplot object.
#' @export
#'
#' @examples
#' library(dplyr)
#'
#' # Always load the WJP fonts
#' wjp_fonts()
#'
#' # Percentage of people that trust their institutions, by gender
#' data4slopes <- WJPr::gpp %>%
#'   filter(year %in% c(2017, 2019)) %>%
#'   mutate(
#'     q1a    = as.double(unclass(q1a)),
#'     gend   = as.double(unclass(gend)),
#'     trust  = case_when(q1a <= 2 ~ 1, q1a <= 4 ~ 0),
#'     gender = case_when(gend == 1 ~ "Male", gend == 2 ~ "Female")
#'   ) %>%
#'   group_by(year, gender) %>%
#'   summarise(trust = mean(trust, na.rm = TRUE) * 100, .groups = "drop") %>%
#'   mutate(value_label = paste0(round(trust, 0), "%"))
#'
#' wjp_slope(
#'   data4slopes,
#'   target   = "trust",
#'   grouping = "year",
#'   colors   = "gender",
#'   labels   = "value_label",
#'   cvec     = c("Male" = "#482d8b", "Female" = "#f26b21"),
#'   repel    = TRUE,
#'   show_legend = TRUE
#' )
#'
#' # Minimal call: colors default to the WJP palette
#' wjp_slope(
#'   data4slopes,
#'   target   = "trust",
#'   grouping = "year",
#'   colors   = "gender",
#'   labels   = "value_label"
#' )
#'
wjp_slope <- function(
    data,
    target,
    grouping,
    colors    = NULL,
    cvec      = NULL,
    labels    = NULL,
    repel     = FALSE,
    ngroups   = NULL,
    ptheme    = WJP_theme(),
    show_legend = FALSE
){

  legend_theme <- wjp_legend_theme(show_legend)
  show_color_legend <- isTRUE(show_legend) && !is.null(colors)
  if (!show_color_legend) {
    legend_theme <- wjp_legend_theme(FALSE)
  }

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
      target_var   = all_of(target),
      grouping_var = all_of(grouping)
    )

  if (is.null(colors)) {
    data <- data %>%
      dplyr::mutate(colors_var = "line")
  } else {
    data <- data %>%
      rename(colors_var = all_of(colors))
  }

  # Lines are grouped by the colors variable; `ngroups` is kept for
  # backwards compatibility with previous versions of the function.
  if (!is.null(ngroups) && length(ngroups) == nrow(data)) {
    data$group_var <- ngroups
  } else {
    data <- data %>%
      dplyr::mutate(group_var = colors_var)
  }

  # Value labels are placed just outside each endpoint
  data <- data %>%
    mutate(
      labpos = case_when(
        grouping_var == min(data$grouping_var) ~ grouping_var - 0.5,
        grouping_var == max(data$grouping_var) ~ grouping_var + 0.5
      )
    )

  # Default to the WJP palette when no color vector is supplied
  if (is.null(cvec)) {
    cvec <- wjp_default_cvec(data$colors_var)
  }
  legend_breaks <- wjp_legend_breaks(data$colors_var)

  # Creating ggplot
  plt <- ggplot(data,
                aes(x     = grouping_var,
                    y     = target_var,
                    color = colors_var,
                    label = labels_var,
                    group = group_var)) +
    geom_point(size = 2,
               show.legend = show_color_legend) +
    geom_line(linewidth    = 1,
              show.legend  = show_color_legend)

  if (isFALSE(repel)) {

    # Applying regular geom_text
    plt <- plt +
      geom_text(aes(y       = target_var,
                    x       = labpos,
                    label   = labels_var),
                family      = wjp_font_family(),
                fontface    = "bold",
                size        = 3.514598,
                show.legend = FALSE)

  } else {

    # Applying ggrepel for a better visualization of labels
    if (!requireNamespace("ggrepel", quietly = TRUE)) {
      stop("Package 'ggrepel' is required for repel=TRUE. Install with: install.packages('ggrepel')",
           call. = FALSE)
    }

    plt <- plt +
      ggrepel::geom_text_repel(mapping = aes(y     = target_var,
                                             x     = labpos,
                                             label = labels_var),
                               family      = wjp_font_family(),
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
                       expand = c(0, 0),
                       breaks = seq(0, 100, 20),
                       labels = paste0(seq(0, 100, 20), "%")) +
    scale_color_manual(
      values = cvec,
      breaks = legend_breaks,
      name   = NULL,
      guide  = ggplot2::guide_legend(
        direction = "horizontal",
        nrow = 1,
        byrow = TRUE
      )
    ) +
    ptheme +
    theme(
      panel.grid.major.x = element_line(color     = "#ACA8AC",
                                        linetype  = "solid",
                                        linewidth = 0.75),
      panel.grid.major.y = element_blank(),
      axis.line.y        = element_blank(),
      axis.title.x       = element_blank(),
      axis.title.y       = element_blank(),
      axis.line.x        = element_blank(),
      axis.ticks.x       = element_blank(),
      axis.text.y        = element_blank()
    ) +
    legend_theme

  return(plt)
}
