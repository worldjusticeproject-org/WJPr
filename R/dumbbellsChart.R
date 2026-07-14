#' Plot a Dumbbell Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `wjp_dumbbells()` takes a data frame with long-format data and returns a
#' ggplot object with a dumbbell chart following WJP style guidelines.
#' Dumbbell charts show the change between two points (e.g., two years) for
#' each category, connected by a line. Values are expected on a 0-100
#' percentage scale.
#'
#' @details
#' The function expects long-format data with one row per `grouping` (category)
#' and `colors` (endpoint) combination; `cgroups` names the two endpoint values
#' in order (start, end). When `labels` is supplied without `labpos`, labels
#' are placed automatically just outside each endpoint and use the endpoint
#' color. By default, a horizontal legend is built from the two `cgroups`
#' values and displayed above the chart. Use `order` (a named vector such as
#' `c("A" = 1, "B" = 2)`) to control the top-to-bottom order of the rows.
#'
#' @param data Data frame containing the data to plot.
#' @param target String. Column name of the variable that supplies the values to plot.
#' @param grouping String. Column name of the variable that supplies the categories
#'   (Y-axis labels).
#' @param cgroups Character vector of length 2 with the two groups to compare (the
#'   start and end points of each dumbbell).
#' @param colors String. Column name of the variable that indicates the start and end
#'   groups (the one containing the `cgroups` values).
#' @param labels String. Column name of the variable containing the value labels to
#'   display. Default is `NULL` (no labels).
#' @param labpos String. Column name of the variable that contains the positions for
#'   the value labels. Default is `NULL` (positions are computed automatically just
#'   outside each endpoint).
#' @param label_offset Numeric. Distance in percentage points between an endpoint
#'   and its automatically positioned label. Ignored when `labpos` is supplied.
#'   Default is `4`.
#' @param cvec Vector of two colors for the start and end points. If named, names
#'   should match the `cgroups` values. Default is `NULL`
#'   (`c("#2894aa", "#482d8b")` is applied).
#' @param order Named vector mapping category values to their display order (top to
#'   bottom). Default is `NULL` (data order).
#' @param bgcolor String. Hex code of the background color for the alternating row
#'   strips. Default is `"#ffffff"`.
#' @param show_legend Logical. If `TRUE`, displays a horizontal point legend above
#'   the chart using the `cgroups` values as labels. Default is `TRUE`.
#' @param color `r lifecycle::badge("deprecated")` Use `colors` instead.
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
#' # Percentage of people that trust their institutions, 2017 vs 2022
#' data4dumbbells <- WJPr::gpp %>%
#'   filter(country == "Atlantis", year %in% c(2017, 2022)) %>%
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
#' wjp_dumbbells(
#'   data4dumbbells,
#'   target   = "percentage",
#'   grouping = "institution",
#'   colors   = "year",
#'   cgroups  = c("2017", "2022"),
#'   labels   = "value_label",
#'   cvec     = c("2017" = "#2894aa", "2022" = "#482d8b"),
#'   show_legend = TRUE,
#'   label_offset = 4
#' )
#'
wjp_dumbbells <- function(
    data,
    target,
    grouping,
    cgroups,
    colors    = NULL,
    labels    = NULL,
    labpos    = NULL,
    cvec      = NULL,
    order     = NULL,
    bgcolor   = "#ffffff",
    color     = NULL,
    ptheme    = WJP_theme(),
    label_offset = 4,
    show_legend = TRUE
){

  # Backwards compatibility: `color` was renamed to `colors`
  if (is.null(colors) && !is.null(color)) {
    colors <- color
  }
  if (is.null(colors)) {
    stop("`colors` must be provided.", call. = FALSE)
  }
  if (length(cgroups) != 2) {
    stop("`cgroups` must be a vector of exactly two values.", call. = FALSE)
  }
  cgroups <- as.character(cgroups)
  if (length(unique(cgroups)) != 2) {
    stop("`cgroups` must contain two different values.", call. = FALSE)
  }
  if (length(label_offset) != 1 || !is.numeric(label_offset) ||
      !is.finite(label_offset) || label_offset < 0) {
    stop("`label_offset` must be a single non-negative number.", call. = FALSE)
  }
  legend_theme <- wjp_legend_theme(show_legend)

  # Default colors: map named vectors onto cgroups, otherwise use positions
  if (is.null(cvec)) {
    cvec <- c("#2894aa", "#482d8b")
  } else if (!is.null(names(cvec)) && all(cgroups %in% names(cvec))) {
    cvec <- unname(cvec[cgroups])
  } else {
    cvec <- unname(cvec)
  }
  if (length(cvec) != 2) {
    stop("`cvec` must contain exactly two colors.", call. = FALSE)
  }
  endpoint_palette <- stats::setNames(cvec, cgroups)

  # Reshaping data into a wide format with start/end columns
  data_wider <- data %>%
    pivot_wider(
      id_cols     = all_of(grouping),
      names_from  = all_of(colors),
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
            names_from  = all_of(colors),
            values_from = all_of(labels)
          ) %>%
          rename(
            group = all_of(grouping),
            lab0  = all_of(cgroups[1]),
            lab1  = all_of(cgroups[2])
          ),
        by = "group"
      )

    if (!is.null(labpos)) {
      data_wider <- data_wider %>%
        left_join(
          data %>%
            pivot_wider(
              id_cols     = all_of(grouping),
              names_from  = all_of(colors),
              values_from = all_of(labpos)
            ) %>%
            rename(
              group = all_of(grouping),
              labp0 = all_of(cgroups[1]),
              labp1 = all_of(cgroups[2])
            ),
          by = "group"
        )
    } else {
      # Place labels just outside each endpoint, kept inside the 0-100 panel
      data_wider <- data_wider %>%
        mutate(
          labp0 = pmax(
            label_offset,
            pmin(100 - label_offset,
                 if_else(start <= end, start - label_offset, start + label_offset))
          ),
          labp1 = pmax(
            label_offset,
            pmin(100 - label_offset,
                 if_else(start <= end, end + label_offset, end - label_offset))
          )
        )
    }
  }

  data_wider <- data_wider %>%
    mutate(
      start_group = cgroups[1],
      end_group   = cgroups[2]
    )

  # Ordering rows: first item of the order appears at the top
  if (is.null(order)) {
    data_wider <- data_wider %>%
      ungroup() %>%
      mutate(
        order_var = row_number()
      )
  } else {
    data_wider <- data_wider %>%
      mutate(
        order_var = recode(group, !!!order)
      )
  }

  data_wider <- data_wider %>%
    mutate(group = reorder(group, -order_var))

  # Creating an alternating strip pattern (visual consistency with wjp_dots)
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
    geom_blank(
      data = data_wider,
      aes(x = group,
          y = start)
    ) +
    geom_ribbon(
      data = strips,
      aes(x     = x,
          ymin  = ymin,
          ymax  = ymax,
          group = xposition,
          fill  = fill),
      show.legend = FALSE
    ) +
    scale_fill_manual(values   = c("grey"  = "#EBEBEB",
                                   "white" = bgcolor),
                      na.value = NA,
                      guide    = "none") +
    geom_segment(
      data = data_wider,
      aes(
        x    = group,
        xend = group,
        y    = start,
        yend = end
      ),
      color     = "#BFBFBF",
      linewidth = 2.5
    ) +
    geom_point(
      data = data_wider,
      aes(
        x = group,
        y = start,
        color = start_group
      ),
      size        = 4.5,
      show.legend = show_legend
    ) +
    geom_point(
      data = data_wider,
      aes(
        x = group,
        y = end,
        color = end_group
      ),
      size        = 4.5,
      show.legend = show_legend
    ) +
    scale_color_manual(
      values = endpoint_palette,
      breaks = cgroups,
      name   = NULL,
      guide  = ggplot2::guide_legend(
        direction = "horizontal",
        nrow = 1,
        byrow = TRUE,
        override.aes = list(size = 4.5)
      )
    )

  if (!is.null(labels)) {
    plt <- plt +
      geom_text(
        data = data_wider,
        aes(
          x     = group,
          y     = labp0,
          label = lab0,
          color = start_group
        ),
        family   = "Lato Full",
        fontface = "bold",
        size     = 3.514598,
        show.legend = FALSE
      ) +
      geom_text(
        data = data_wider,
        aes(
          x     = group,
          y     = labp1,
          label = lab1,
          color = end_group
        ),
        family   = "Lato Full",
        fontface = "bold",
        size     = 3.514598,
        show.legend = FALSE
      )
  }

  plt <- plt +
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
                                            hjust = 0)) +
    legend_theme

  return(plt)
}
