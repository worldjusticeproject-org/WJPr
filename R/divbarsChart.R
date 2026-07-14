#' Plot a Diverging Horizontal Bar Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `wjp_divbars()` takes a data frame with long-format data and returns a ggplot
#' object with a diverging horizontal bar chart following WJP style guidelines.
#' Bars extend left (negative) and right (positive) from a common zero line,
#' which makes the chart suitable for contrasting two opposing responses
#' (e.g., "Trust" vs "No Trust"). Values are expected on a percentage scale.
#'
#' @details
#' The function expects one row per `grouping` (row) and `diverging` (answer
#' group) combination. All values can be supplied as positive percentages:
#' name the group that should extend left through `negative` and the function
#' flips it automatically. Alternatively, leave `negative = NULL` and supply
#' pre-signed values. Value labels are drawn centered inside each segment.
#'
#' @param data Data frame containing the data to plot.
#' @param target String. Column name of the variable that supplies the values to plot.
#' @param grouping String. Column name of the variable that supplies the categories
#'   (Y-axis labels).
#' @param diverging String. Column name of the variable that supplies the diverging
#'   groups (e.g., the answer categories).
#' @param negative String. Value of the `diverging` variable whose bars should extend
#'   into the negative quadrant. Default is `NULL` (values are used as supplied, so
#'   negative values must already carry a negative sign).
#' @param cvec Named vector of colors, one per diverging group. Default is `NULL`
#'   (the WJP contrast pair is applied, with orange for the negative group).
#' @param labels String. Column name of the variable containing the value labels to
#'   display inside the bars. Default is `NULL` (no labels).
#' @param label_color String. Hex code for the value labels. Default is `"#ffffff"`.
#' @param order String. Column name of the variable that contains the display order of
#'   categories. Default is `NULL` (data order).
#' @param custom_order `r lifecycle::badge("deprecated")` Logical. Ordering is now
#'   enabled automatically when `order` is supplied.
#' @param ptheme ggplot theme to apply. Default is [WJP_theme()].
#' @param show_legend Logical. If `TRUE`, displays a horizontal legend above the
#'   chart using the `diverging` values. Default is `FALSE`.
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
#' # Trust vs no trust, by country
#' data4divbars <- WJPr::gpp %>%
#'   filter(year == 2022) %>%
#'   mutate(
#'     q1a      = as.double(unclass(q1a)),
#'     response = case_when(q1a <= 2 ~ "Trust", q1a <= 4 ~ "No Trust")
#'   ) %>%
#'   filter(!is.na(response)) %>%
#'   group_by(country, response) %>%
#'   count() %>%
#'   group_by(country) %>%
#'   mutate(
#'     percentage  = (n / sum(n)) * 100,
#'     value_label = paste0(round(percentage, 0), "%")
#'   )
#'
#' wjp_divbars(
#'   data4divbars,
#'   target    = "percentage",
#'   grouping  = "country",
#'   diverging = "response",
#'   negative  = "No Trust",
#'   labels    = "value_label",
#'   show_legend = TRUE,
#'   cvec      = c("Trust" = "#482d8b", "No Trust" = "#f26b21")
#' )
#'
#' # Custom row order via an order column
#' data4divbars_ordered <- data4divbars %>%
#'   mutate(
#'     row_order = case_when(
#'       country == "Neverland" ~ 1,
#'       country == "Atlantis"  ~ 2,
#'       country == "Narnia"    ~ 3
#'     )
#'   )
#'
#' wjp_divbars(
#'   data4divbars_ordered,
#'   target    = "percentage",
#'   grouping  = "country",
#'   diverging = "response",
#'   negative  = "No Trust",
#'   labels    = "value_label",
#'   order     = "row_order"
#' )
#'
wjp_divbars <- function(
    data,
    target,
    grouping,
    diverging,
    negative     = NULL,
    cvec         = NULL,
    labels       = NULL,
    label_color  = "#ffffff",
    order        = NULL,
    custom_order = FALSE,
    ptheme       = WJP_theme(),
    show_legend  = FALSE
){

  # Renaming variables in the data frame to match the function naming
  data <- data %>%
    rename(target_var   = all_of(target),
           rows_var     = all_of(grouping),
           grouping_var = all_of(diverging),
           order_var    = any_of(order))

  if (!is.null(labels)) {
    data <- data %>%
      rename(labels_var = all_of(labels))
  } else {
    data$labels_var <- rep("", nrow(data))
  }

  # Flip the negative group into the negative quadrant
  if (!is.null(negative)) {
    data <- data %>%
      mutate(
        target_var = if_else(
          grouping_var == negative,
          -abs(target_var),
          target_var
        )
      )
  }

  # Default colors: WJP contrast pair, orange for the negative group
  if (is.null(cvec)) {
    vals <- unique(as.character(data$grouping_var))
    if (!is.null(negative) && negative %in% vals) {
      others <- setdiff(vals, negative)
      cvec <- stats::setNames(wjp_palette(length(others)), others)
      cvec[negative] <- "#f26b21"
    } else {
      cvec <- wjp_default_cvec(data$grouping_var)
    }
  }
  legend_breaks <- wjp_legend_breaks(data$grouping_var)

  # Supplying an order column enables custom ordering
  use_order <- isTRUE(custom_order) || !is.null(order)

  # Creating ggplot
  if (use_order && "order_var" %in% names(data)) {
    chart <- ggplot(data, aes(x     = reorder(rows_var, order_var),
                              y     = target_var,
                              fill  = grouping_var,
                              label = labels_var))
  } else {
    chart <- ggplot(data, aes(x     = rows_var,
                              y     = target_var,
                              fill  = grouping_var,
                              label = labels_var))
  }

  # Axis breaks
  brs <-  c(-100, -75, -50, -25, 0, 25, 50, 75, 100)

  # Adding geoms
  chart <- chart +
    geom_col(position     = "stack",
             show.legend  = show_legend,
             width        = 0.85) +
    geom_hline(yintercept = 0,
               linetype   = "solid",
               linewidth  = 0.5,
               color      = "#262424") +
    scale_fill_manual(values = cvec,
                      breaks = legend_breaks,
                      name = NULL) +
    scale_y_continuous(limits   = c(-105, 105),
                       breaks   = brs,
                       labels   = paste0(abs(brs), "%"),
                       position = "right") +
    scale_x_discrete(limits = rev) +
    coord_flip() +
    ptheme +
    geom_text(aes(label = labels_var),
              family   = "Lato Full",
              fontface = "bold",
              size     = 3.514598,
              color    = label_color,
              show.legend = FALSE,
              position = position_stack(vjust = 0.5)) +
    theme(panel.grid.major = element_blank(),
          axis.text.x      = element_text(family = "Lato Full",
                                          face   = "bold",
                                          size   = 3.514598 * ggplot2::.pt,
                                          color  = "#262424",
                                          hjust  = 0),
          axis.text.y      = element_text(family = "Lato Full",
                                          face   = "bold",
                                          size   = 3.514598 * ggplot2::.pt,
                                          color  = "#262424",
                                          hjust  = 0),
          axis.title.x     = element_blank(),
          axis.title.y     = element_blank(),
          axis.line.x      = element_line(linetype  = "solid",
                                          linewidth = 0.5,
                                          color     = "#262424"))

  chart <- chart + wjp_legend_theme(show_legend)

  return(chart)

}
