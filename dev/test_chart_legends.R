# Visual regression fixture for optional legends across WJPr chart families.
devtools::load_all(".", quiet = TRUE)

library(ggplot2)

wjp_fonts()

categories <- c("Category 1", "Category 2")
category_colors <- c("Category 1" = "#2894aa", "Category 2" = "#482d8b")

bars_data <- data.frame(
  item = rep(c("Item A", "Item B", "Item C"), each = 2),
  category = rep(categories, 3),
  value = c(42, 58, 55, 45, 63, 37),
  label = paste0(c(42, 58, 55, 45, 63, 37), "%")
)

dots_data <- data.frame(
  item = rep(c("Measure A", "Measure B", "Measure C", "Measure D"), each = 2),
  category = rep(categories, 4),
  value = c(38, 52, 47, 61, 69, 75, 56, 49),
  order = rep(1:4, each = 2)
)

lines_data <- data.frame(
  year = rep(2021:2024, 2),
  category = rep(categories, each = 4),
  value = c(43, 49, 54, 62, 67, 64, 60, 58),
  label = paste0(c(43, 49, 54, 62, 67, 64, 60, 58), "%")
)

radar_data <- data.frame(
  axis = rep(LETTERS[1:5], 2),
  category = rep(categories, each = 5),
  value = c(45, 62, 54, 71, 58, 66, 52, 73, 57, 68),
  label = rep(paste("Measure", 1:5), 2),
  order = rep(1:5, 2)
)

gauge_data <- data.frame(
  category = categories,
  value = c(42, 58),
  label = c("42%", "58%")
)

plots <- list(
  wjp_bars(
    bars_data, "value", "item", colors = "category", stacked = TRUE,
    cvec = category_colors, show_legend = TRUE
  ) + labs(title = "Stacked bars"),
  wjp_divbars(
    bars_data, "value", "item", "category", negative = "Category 2",
    labels = "label", cvec = category_colors, show_legend = TRUE
  ) + labs(title = "Diverging bars"),
  wjp_dots(
    dots_data, "value", "item", "category", order = "order",
    cvec = category_colors, show_legend = TRUE
  ) + labs(title = "Dots"),
  wjp_lines(
    lines_data, "value", "year", colors = "category",
    cvec = category_colors, show_legend = TRUE
  ) + labs(title = "Lines"),
  wjp_slope(
    lines_data[lines_data$year %in% c(2021, 2024), ],
    "value", "year", colors = "category",
    cvec = category_colors, show_legend = TRUE
  ) + labs(title = "Slope"),
  wjp_radar(
    radar_data, "axis", "value", "label", "category", order = "order",
    cvec = category_colors, show_legend = TRUE
  ) + labs(title = "Radar"),
  wjp_gauge(
    gauge_data, "value", "category", labels = "label",
    cvec = category_colors, show_legend = TRUE
  ) + labs(title = "Gauge")
)

plots <- lapply(
  plots,
  function(plot) plot + theme(plot.margin = margin(20, 20, 35, 20))
)

grDevices::png(
  filename = "dev/test_chart_legends.png",
  width = 3200,
  height = 3600,
  res = 200,
  bg = "white"
)
grid::grid.newpage()
layout <- grid::grid.layout(nrow = 4, ncol = 2)
grid::pushViewport(grid::viewport(layout = layout))

for (index in seq_along(plots)) {
  row <- ((index - 1) %/% 2) + 1
  column <- ((index - 1) %% 2) + 1
  print(
    plots[[index]],
    vp = grid::viewport(layout.pos.row = row, layout.pos.col = column),
    newpage = FALSE
  )
}

grid::popViewport()
grDevices::dev.off()
