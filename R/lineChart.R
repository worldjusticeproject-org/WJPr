#' Plot a Line Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `wjp_lines()` takes a data frame with long-format data and returns a ggplot
#' object with a line chart following WJP style guidelines. Each line is defined
#' by the `colors` variable, so the function works out of the box for both single
#' and multiple series. Values are expected on a 0-100 percentage scale.
#'
#' @details
#' The function expects long-format data with one row per time point and
#' series: the X-axis values in `grouping` (usually years), the values in
#' `target`, and the series identifier in `colors`. To highlight one line
#' among several, set `transparency = TRUE` and pass per-series opacities
#' through `transparencies`. When labels overlap, set `repel = TRUE`
#' (requires the ggrepel package).
#'
#' @param data Data frame containing the data to plot.
#' @param target String. Column name of the variable that supplies the values to plot.
#' @param grouping String. Column name of the variable that supplies the X-axis values
#'   (usually years).
#' @param colors String. Column name of the variable that defines the lines and their
#'   color grouping. Default is `NULL` (a single line is drawn).
#' @param cvec Named vector of colors, one per line. Names should match the values of
#'   the `colors` variable. Default is `NULL` (the WJP palette, see [wjp_palette()],
#'   is applied).
#' @param labels String. Column name of the variable containing the value labels to
#'   display. Default is `NULL` (no labels).
#' @param repel Logical. If `TRUE`, the ggrepel package is used to avoid overlapping
#'   labels. Default is `FALSE`.
#' @param transparency Logical. If `TRUE`, per-line opacities given in `transparencies`
#'   are applied. Default is `FALSE`.
#' @param transparencies Named vector of opacities, one per line. Required when
#'   `transparency = TRUE`.
#' @param custom.axis Logical. If `TRUE`, `x.breaks` and `x.labels` are applied to a
#'   continuous X-axis (requires the ggh4x package). Default is `FALSE`.
#' @param x.breaks Numeric vector with custom breaks for the X-axis.
#' @param x.labels Character vector with labels for the X-axis. Must have the same
#'   length as `x.breaks`.
#' @param sec.ticks Numeric vector with minor breaks for the X-axis.
#' @param ngroups `r lifecycle::badge("deprecated")` Grouping vector for the lines.
#'   Retained for backwards compatibility; lines are now grouped by `colors`
#'   automatically.
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
#' # Percentage of people that trust their institutions, over time
#' data4lines <- WJPr::gpp %>%
#'   filter(country == "Atlantis") %>%
#'   select(year, q1a, q1b, q1c) %>%
#'   mutate(
#'     across(!year, \(x) as.double(unclass(x))),
#'     across(!year, ~ case_when(.x <= 2 ~ 1, .x <= 4 ~ 0)),
#'     year = as.character(year)
#'   ) %>%
#'   group_by(year) %>%
#'   summarise(across(everything(), \(x) mean(x, na.rm = TRUE) * 100)) %>%
#'   pivot_longer(!year, names_to = "variable", values_to = "percentage") %>%
#'   mutate(
#'     institution = case_when(
#'       variable == "q1a" ~ "Institution A",
#'       variable == "q1b" ~ "Institution B",
#'       variable == "q1c" ~ "Institution C"
#'     ),
#'     value_label = paste0(round(percentage, 0), "%")
#'   )
#'
#' # Multiple lines, one per institution
#' wjp_lines(
#'   data4lines,
#'   target   = "percentage",
#'   grouping = "year",
#'   colors   = "institution",
#'   labels   = "value_label",
#'   repel    = TRUE,
#'   cvec     = c("Institution A" = "#482d8b",
#'                "Institution B" = "#2894aa",
#'                "Institution C" = "#f26b21")
#' )
#'
#' # Single line
#' wjp_lines(
#'   data4lines %>% filter(institution == "Institution A"),
#'   target   = "percentage",
#'   grouping = "year",
#'   colors   = "institution",
#'   labels   = "value_label"
#' )
#'
#' # Highlighting one line with per-series opacities
#' wjp_lines(
#'   data4lines,
#'   target         = "percentage",
#'   grouping       = "year",
#'   colors         = "institution",
#'   labels         = "value_label",
#'   repel          = TRUE,
#'   cvec           = c("Institution A" = "#482d8b",
#'                      "Institution B" = "#555659",
#'                      "Institution C" = "#555659"),
#'   transparency   = TRUE,
#'   transparencies = c("Institution A" = 1.00,
#'                      "Institution B" = 0.30,
#'                      "Institution C" = 0.30)
#' )
#'
wjp_lines <- function(
    data,
    target,
    grouping,
    colors         = NULL,
    cvec           = NULL,
    labels         = NULL,
    repel          = FALSE,
    transparency   = FALSE,
    transparencies = NULL,
    custom.axis    = FALSE,
    x.breaks       = NULL,
    x.labels       = NULL,
    sec.ticks      = NULL,
    ngroups        = NULL,
    ptheme         = WJP_theme()
){

  # Renaming variables in the data frame to match the function naming
  data <- data %>%
    rename(target_var   = all_of(target),
           grouping_var = all_of(grouping))

  if (is.null(colors)) {
    data <- data %>%
      dplyr::mutate(colors_var = "line")
  } else {
    data <- data %>%
      rename(colors_var = all_of(colors))
  }

  if (is.null(labels)) {
    data <- data %>%
      dplyr::mutate(labels_var = "")
  } else {
    data <- data %>%
      rename(labels_var = all_of(labels))
  }

  # Default to the WJP palette when no color vector is supplied
  if (is.null(cvec)) {
    cvec <- wjp_default_cvec(data$colors_var)
  }

  # Lines are grouped by the colors variable; `ngroups` is kept for
  # backwards compatibility with previous versions of the function.
  if (is.null(ngroups)) {
    data <- data %>%
      dplyr::mutate(group_var = colors_var)
  } else if (length(ngroups) == nrow(data)) {
    data$group_var <- ngroups
  } else {
    data <- data %>%
      dplyr::mutate(group_var = colors_var)
  }

  # Keep value labels inside the panel: flip the offset below the point
  # when the value is close to the top of the scale.
  data <- data %>%
    dplyr::mutate(
      labpos_var = dplyr::if_else(target_var > 95,
                                  target_var - 7.5,
                                  target_var + 7.5)
    )

  # Creating ggplot
  plt <- ggplot(data,
                aes(x     = grouping_var,
                    y     = target_var,
                    color = colors_var,
                    label = labels_var,
                    group = group_var))

  if (isTRUE(transparency)) {
    plt <- plt +
      geom_point(size = 2,
                 aes(alpha   = colors_var),
                 show.legend = FALSE) +
      geom_line(linewidth    = 1,
                aes(alpha    = colors_var),
                show.legend  = FALSE) +
      scale_alpha_manual(values = transparencies)
  } else {
    plt <- plt +
      geom_point(size = 2,
                 show.legend = FALSE) +
      geom_line(linewidth    = 1,
                show.legend  = FALSE)
  }

  if (isFALSE(repel)) {

    # Applying regular geom_text
    plt <- plt +
      geom_text(aes(y       = labpos_var,
                    x       = grouping_var,
                    label   = labels_var),
                family      = "Lato Full",
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
                                             x     = grouping_var,
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
    scale_y_continuous(limits = c(0, 105),
                       expand = c(0, 0),
                       breaks = seq(0, 100, 20),
                       labels = paste0(seq(0, 100, 20), "%")) +
    scale_color_manual(values = cvec)

  if (isTRUE(custom.axis)) {
    if (!requireNamespace("ggh4x", quietly = TRUE)) {
      stop("Package 'ggh4x' is required for custom.axis=TRUE. Install with: install.packages('ggh4x')",
           call. = FALSE)
    }
    if (is.null(x.breaks) || is.null(x.labels)) {
      stop("`x.breaks` and `x.labels` must be provided when custom.axis = TRUE.", call. = FALSE)
    }
    if (length(x.breaks) != length(x.labels)) {
      stop("`x.breaks` and `x.labels` must have the same length.", call. = FALSE)
    }
    plt <- plt +
      scale_x_continuous(limits = c(head(x.breaks, 1), tail(x.breaks, 1)),
                         breaks = x.breaks,
                         expand = expansion(mult = c(0.075, 0.125)),
                         labels = x.labels,
                         guide  = ggh4x::guide_axis_minor(),
                         minor_breaks = sec.ticks)
  }

  plt <- plt +
    ptheme +
    theme(panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(colour = "#d1cfd1"),
          axis.title.x       = element_blank(),
          axis.title.y       = element_blank(),
          axis.line.x        = element_line(color    = "#d1cfd1"),
          axis.ticks.x       = element_line(color    = "#d1cfd1",
                                            linetype = "solid"))

  if (isTRUE(custom.axis)) {
    plt <- plt +
      theme(
        ggh4x.axis.ticks.length.minor = rel(1)
      )
  }

  return(plt)
}
