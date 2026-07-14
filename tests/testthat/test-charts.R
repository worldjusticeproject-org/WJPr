test_that("chart functions return buildable ggplot objects", {
  bars <- data.frame(
    cat = c("A", "B", "C"),
    val = c(20, 50, 80),
    lab = c("20%", "50%", "80%"),
    pos = c(25, 55, 85),
    col = c("A", "B", "C"),
    ord = c(1, 2, 3)
  )

  stack <- data.frame(
    cat = c("A", "A", "B", "B"),
    val = c(40, 60, 30, 70),
    diverge = c("Trust", "No Trust", "Trust", "No Trust"),
    lab = c("40%", "60%", "30%", "70%"),
    ord = c(1, 1, 2, 2)
  )

  dots <- data.frame(
    cat = rep(c("A", "B", "C"), 2),
    group = rep(c("G1", "G2"), each = 3),
    val = c(20, 40, 60, 30, 50, 70),
    ord = rep(1:3, 2),
    sd = rep(5, 6),
    n = rep(100, 6)
  )

  dumb <- data.frame(
    cat = rep(c("A", "B", "C"), each = 2),
    yr = rep(c("2019", "2024"), 3),
    val = c(20, 30, 40, 45, 60, 70),
    lab = paste0(c(20, 30, 40, 45, 60, 70), "%"),
    labpos = c(15, 35, 35, 50, 55, 75)
  )

  line <- data.frame(
    year = rep(2019:2021, 2),
    group = rep(c("A", "B"), each = 3),
    val = c(20, 25, 35, 50, 55, 60),
    lab = paste0(c(20, 25, 35, 50, 55, 60), "%")
  )

  gauge <- data.frame(
    cat = c("A", "B", "C"),
    val = c(25, 35, 40),
    lab = c("25%", "35%", "40%")
  )

  radar <- data.frame(
    axis = rep(LETTERS[1:5], 2),
    val = c(20, 40, 60, 80, 50, 30, 50, 70, 65, 45),
    lab = rep(LETTERS[1:5], 2),
    group = rep(c("G1", "G2"), each = 5),
    main = rep(c("Labels", "Comparison"), each = 5)
  )

  groupbars <- data.frame(
    group = c("Gender", "Gender", "Age", "Age"),
    level = c("Male", "Female", "Young", "Old"),
    value = c(0.45, 0.55, 0.35, 0.62)
  )

  plots <- list(
    wjp_bars(bars, "val", "cat", labels = "lab", lab_pos = "pos", colors = "col", order = "ord", expand = TRUE),
    wjp_divbars(stack, "val", "cat", "diverge", negative = "No Trust", labels = "lab"),
    wjp_dots(dots, "val", "cat", "group", draw_ci = TRUE, sd = "sd", sample_size = "n"),
    wjp_dumbbells(dumb, "val", "cat", cgroups = c("2019", "2024"), color = "yr", labels = "lab", labpos = "labpos"),
    wjp_edgebars(bars, "val", "cat", "lab"),
    wjp_gauge(gauge, "val", "cat", labels = "lab"),
    wjp_groupbars(groupbars, "value", "group", "level"),
    wjp_lines(line, "val", "year", ngroups = line$group, colors = "group", labels = "lab"),
    wjp_lollipops(bars, "val", "cat", point_size = 8, line_size = 1),
    wjp_radar(radar, "axis", "val", "lab", "group", maincat = "main"),
    wjp_rose(radar[radar$group == "G1", ], "val", "axis", "lab"),
    wjp_slope(line[line$year %in% c(2019, 2021), ], "val", "year",
              ngroups = line$group[line$year %in% c(2019, 2021)],
              colors = "group", labels = "lab")
  )

  for (plot in plots) {
    expect_s3_class(plot, "ggplot")
    expect_no_error(ggplot2::ggplot_build(plot))
  }
})

test_that("optional arguments validate invalid inputs clearly", {
  dots <- data.frame(cat = "A", group = "G", val = 10)
  expect_error(
    wjp_dots(dots, "val", "cat", "group", draw_ci = TRUE),
    "`sd` and `sample_size`"
  )

  gauge <- data.frame(cat = c("A", "B"), val = c(0, 0))
  expect_error(
    wjp_gauge(gauge, "val", "cat"),
    "positive finite"
  )

  groupbars <- data.frame(group = "G", level = "L", value = 145)
  expect_error(
    wjp_groupbars(groupbars, "value", "group", "level"),
    "0-100"
  )

  groupbars <- data.frame(group = "G", level = "L", value = 0.45)
  expect_error(
    wjp_groupbars(groupbars, "value", "group", "level", show_national = TRUE),
    "`national_value`"
  )

  expect_error(
    wjp_groupbars(groupbars, "value", "group", "level", group_order = "Missing"),
    "`group_order`"
  )

  groupbars <- data.frame(
    group = c("Gender", "Age"),
    level = c("Male", "Young"),
    value = c(0.45, 0.35)
  )
  expect_error(
    wjp_groupbars(groupbars, "value", "group", "level", group_order = "Gender"),
    "`group_order`"
  )

  expect_error(
    wjp_groupbars(
      groupbars,
      "value",
      "group",
      "level",
      show_national  = TRUE,
      national_value = 0.5,
      national_label = c("A", "B")
    ),
    "`national_label`"
  )

  expect_error(
    wjp_groupbars(
      groupbars,
      "value",
      "group",
      "level",
      show_national  = TRUE,
      national_value = 0.5,
      national_style = "point"
    ),
    "`national_style`"
  )
})

test_that("wjp_groupbars draws national average as annotation, not as a data row", {
  groupbars <- data.frame(
    group = c("Gender", "Gender", "Age", "Age"),
    level = c("Male", "Female", "Young", "Old"),
    value = c(0.45, 0.55, 0.35, 0.62)
  )

  plot <- wjp_groupbars(
    groupbars,
    "value",
    "group",
    "level",
    show_national  = TRUE,
    national_value = 0.5
  )

  expect_s3_class(plot, "ggplot")
  expect_no_error(built <- ggplot2::ggplot_build(plot))
  expect_equal(nrow(built$data[[1]]), nrow(groupbars) * 2)
  expect_true(any(vapply(built$data, function(layer) {
    "xintercept" %in% names(layer) && any(layer$xintercept == 50)
  }, logical(1))))
  expect_true(any(vapply(built$data, function(layer) {
    "label" %in% names(layer) && any(grepl("National Average", layer$label, fixed = TRUE))
  }, logical(1))))
})

test_that("wjp_groupbars supports percentage inputs and precomputed confidence intervals", {
  groupbars <- data.frame(
    group = c("Gender", "Gender", "Age", "Age"),
    level = c("Male", "Female", "Young", "Old"),
    value = c(45, 55, 35, 62),
    lower = c(40, 50, 30, 57),
    upper = c(50, 60, 40, 67)
  )

  plot <- wjp_groupbars(
    groupbars,
    "value",
    "group",
    "level",
    draw_ci  = TRUE,
    ci_lower = "lower",
    ci_upper = "upper",
    show_national  = TRUE,
    national_value = 50,
    national_label = "General"
  )

  expect_no_error(built <- ggplot2::ggplot_build(plot))
  expect_equal(nrow(built$data[[1]]), nrow(groupbars) * 2)
  expect_true(any(vapply(built$data, function(layer) {
    all(c("xmin", "xmax") %in% names(layer)) && any(layer$xmin == 40) && any(layer$xmax == 67)
  }, logical(1))))
  expect_true(any(vapply(built$data, function(layer) {
    "label" %in% names(layer) && any(grepl("General", layer$label, fixed = TRUE))
  }, logical(1))))
})

test_that("wjp_groupbars can draw national average as a bar", {
  groupbars <- data.frame(
    group = c("Gender", "Gender", "Age", "Age"),
    level = c("Male", "Female", "Young", "Old"),
    value = c(45, 55, 35, 62),
    lower = c(40, 50, 30, 57),
    upper = c(50, 60, 40, 67)
  )

  plot <- wjp_groupbars(
    groupbars,
    "value",
    "group",
    "level",
    group_order       = c("Gender", "Age"),
    draw_ci           = TRUE,
    ci_lower          = "lower",
    ci_upper          = "upper",
    show_national     = TRUE,
    national_value    = 50,
    national_style    = "bar",
    national_label    = "National Average",
    national_ci_lower = 48,
    national_ci_upper = 52
  )

  expect_no_error(built <- ggplot2::ggplot_build(plot))
  expect_equal(nrow(built$data[[1]]), (nrow(groupbars) + 1) * 2)
  expect_false(any(vapply(built$data, function(layer) {
    "xintercept" %in% names(layer)
  }, logical(1))))
  expect_true(any(vapply(built$data, function(layer) {
    all(c("xmin", "xmax") %in% names(layer)) && any(layer$xmin == 48) && any(layer$xmax == 52)
  }, logical(1))))
  expect_true(any(vapply(built$data, function(layer) {
    "label" %in% names(layer) && any(layer$label == "50%")
  }, logical(1))))
})

test_that("wjp_palette returns the WJP brand colors", {
  pal <- wjp_palette()
  expect_length(pal, 9)
  expect_equal(pal[1], "#482d8b")
  expect_equal(wjp_palette(3), c("#482d8b", "#2894aa", "#f26b21"))
  expect_length(wjp_palette(12), 12)
  expect_error(wjp_palette(0), "positive")
})

test_that("chart functions fall back to the WJP palette when cvec is NULL", {
  bars <- data.frame(cat = c("A", "B", "C"), val = c(20, 50, 80))

  plot <- wjp_bars(bars, "val", "cat")
  built <- ggplot2::ggplot_build(plot)
  expect_setequal(unique(built$data[[1]]$fill), wjp_palette(3))

  lines <- data.frame(
    year = rep(2019:2021, 2),
    group = rep(c("A", "B"), each = 3),
    val = c(20, 25, 35, 50, 55, 60)
  )
  plot <- wjp_lines(lines, "val", "year", colors = "group")
  built <- ggplot2::ggplot_build(plot)
  expect_setequal(unique(built$data[[1]]$colour), wjp_palette(2))
})

test_that("wjp_lines and wjp_slope work without ngroups and without colors", {
  line <- data.frame(
    year = rep(2019:2021, 2),
    group = rep(c("A", "B"), each = 3),
    val = c(20, 25, 35, 50, 55, 60),
    lab = paste0(c(20, 25, 35, 50, 55, 60), "%")
  )

  expect_no_error(ggplot2::ggplot_build(
    wjp_lines(line, "val", "year", colors = "group", labels = "lab")
  ))
  expect_no_error(ggplot2::ggplot_build(
    wjp_lines(line[line$group == "A", ], "val", "year")
  ))
  expect_no_error(ggplot2::ggplot_build(
    wjp_slope(line[line$year %in% c(2019, 2021), ], "val", "year", colors = "group")
  ))
})

test_that("wjp_gauge padding segment stays invisible with default colors", {
  gauge <- data.frame(cat = c("A", "B"), val = c(30, 70))
  built <- ggplot2::ggplot_build(wjp_gauge(gauge, "val", "cat"))
  rects <- built$data[[1]]
  # The padding rectangle (upper half of the y scale) must be transparent
  padding_fill <- rects$fill[rects$ymin >= 50]
  expect_true(all(padding_fill == "transparent"))
  visible_fill <- rects$fill[rects$ymin < 50]
  expect_setequal(visible_fill, wjp_palette(2))
})

test_that("wjp_dumbbells honors order, colors alias, and named cvec", {
  dumb <- data.frame(
    cat = rep(c("A", "B", "C"), each = 2),
    yr = rep(c("2019", "2024"), 3),
    val = c(20, 30, 40, 45, 60, 70)
  )

  # `colors` is the new name of `color`
  plot <- wjp_dumbbells(
    dumb, "val", "cat",
    cgroups = c("2019", "2024"),
    colors  = "yr",
    cvec    = c("2024" = "#482d8b", "2019" = "#2894aa"),
    order   = c("C" = 1, "B" = 2, "A" = 3)
  )
  built <- ggplot2::ggplot_build(plot)
  expect_s3_class(plot, "ggplot")

  # Named cvec is matched by cgroups order: start = 2019 -> #2894aa
  start_layer <- built$data[[4]]
  expect_true(all(start_layer$colour == "#2894aa"))

  # Missing `colors` raises a clear error
  expect_error(
    wjp_dumbbells(dumb, "val", "cat", cgroups = c("2019", "2024")),
    "`colors`"
  )
})

test_that("wjp_dumbbells supports colored outside labels and an endpoint legend", {
  dumb <- data.frame(
    category = rep(c("Problem Solved", "Trust in Effectiveness"), each = 2),
    comparison = rep(c("Category 1", "Category 2"), 2),
    value = c(68, 79, 38, 37),
    label = c("68%", "79%", "38%", "37%")
  )

  plot <- wjp_dumbbells(
    dumb,
    target       = "value",
    grouping     = "category",
    colors       = "comparison",
    cgroups      = c("Category 1", "Category 2"),
    labels       = "label",
    cvec         = c("Category 1" = "#2894aa", "Category 2" = "#482d8b"),
    show_legend  = TRUE,
    label_offset = 4
  )

  color_scale <- plot$scales$get_scales("colour")
  fill_scale <- plot$scales$get_scales("fill")
  expect_equal(color_scale$breaks, c("Category 1", "Category 2"))
  expect_equal(
    unname(color_scale$palette(2)),
    c("#2894aa", "#482d8b")
  )
  expect_equal(plot$theme$legend.position, "top")
  expect_equal(plot$theme$legend.justification, "left")
  expect_equal(fill_scale$guide, "none")
  expect_true(plot$layers[[4]]$show.legend)
  expect_true(plot$layers[[5]]$show.legend)
  expect_equal(plot$layers[[6]]$data$labp0, c(64, 42))
  expect_equal(plot$layers[[7]]$data$labp1, c(83, 33))
  expect_equal(rlang::as_label(plot$layers[[6]]$mapping$colour), "start_group")
  expect_equal(rlang::as_label(plot$layers[[7]]$mapping$colour), "end_group")

  plot_without_legend <- wjp_dumbbells(
    dumb,
    target      = "value",
    grouping    = "category",
    colors      = "comparison",
    cgroups     = c("Category 1", "Category 2"),
    show_legend = FALSE
  )
  expect_equal(plot_without_legend$theme$legend.position, "none")

  expect_error(
    wjp_dumbbells(
      dumb, "value", "category",
      cgroups = c("Category 1", "Category 2"),
      colors = "comparison",
      label_offset = -1
    ),
    "`label_offset`"
  )
})

test_that("categorical charts expose consistent optional legends", {
  categories <- c("Category 1", "Category 2")
  category_colors <- c("Category 1" = "#2894aa", "Category 2" = "#482d8b")

  bars <- data.frame(
    item = rep(c("Item A", "Item B"), each = 2),
    category = rep(categories, 2),
    value = c(45, 55, 60, 40)
  )
  dots <- data.frame(
    item = rep(c("Item A", "Item B", "Item C"), each = 2),
    category = rep(categories, 3),
    value = c(45, 55, 60, 40, 35, 65),
    order = rep(1:3, each = 2)
  )
  lines <- data.frame(
    year = rep(2022:2024, 2),
    category = rep(categories, each = 3),
    value = c(45, 50, 55, 65, 60, 58)
  )
  slopes <- lines[lines$year %in% c(2022, 2024), ]
  radar <- data.frame(
    axis = rep(LETTERS[1:5], 2),
    category = rep(categories, each = 5),
    value = c(45, 50, 55, 60, 65, 65, 60, 58, 55, 50),
    label = rep(paste("Measure", 1:5), 2),
    order = rep(1:5, 2)
  )
  gauge <- data.frame(
    category = categories,
    value = c(45, 55)
  )

  make_plots <- function(show_legend) {
    list(
      bars = wjp_bars(
        bars, "value", "item", colors = "category", stacked = TRUE,
        cvec = category_colors, show_legend = show_legend
      ),
      divbars = wjp_divbars(
        bars, "value", "item", "category", negative = "Category 2",
        cvec = category_colors, show_legend = show_legend
      ),
      dots = wjp_dots(
        dots, "value", "item", "category", order = "order",
        cvec = category_colors,
        shapes = c("Category 1" = 16, "Category 2" = 17),
        opacities = c("Category 1" = 1, "Category 2" = 0.65),
        show_legend = show_legend
      ),
      lines = wjp_lines(
        lines, "value", "year", colors = "category",
        cvec = category_colors, show_legend = show_legend
      ),
      slope = wjp_slope(
        slopes, "value", "year", colors = "category",
        cvec = category_colors, show_legend = show_legend
      ),
      radar = wjp_radar(
        radar, "axis", "value", "label", "category", order = "order",
        cvec = category_colors, show_legend = show_legend
      ),
      gauge = wjp_gauge(
        gauge, "value", "category", cvec = category_colors,
        show_legend = show_legend
      )
    )
  }

  visible <- make_plots(TRUE)
  hidden <- make_plots(FALSE)

  for (plot in visible) {
    expect_s3_class(plot, "ggplot")
    expect_equal(plot$theme$legend.position, "top")
    expect_equal(plot$theme$legend.justification, "left")
    expect_no_error(ggplot2::ggplot_build(plot))
  }
  for (plot in hidden) {
    expect_equal(plot$theme$legend.position, "none")
  }

  expect_equal(visible$bars$scales$get_scales("fill")$breaks, categories)
  expect_equal(visible$divbars$scales$get_scales("fill")$breaks, categories)
  expect_equal(visible$dots$scales$get_scales("colour")$breaks, categories)
  expect_equal(visible$lines$scales$get_scales("colour")$breaks, categories)
  expect_equal(visible$slope$scales$get_scales("colour")$breaks, categories)
  expect_equal(visible$radar$scales$get_scales("colour")$breaks, categories)
  expect_equal(visible$gauge$scales$get_scales("fill")$breaks, categories)

  expect_equal(visible$dots$scales$get_scales("fill")$guide, "none")
  expect_equal(visible$dots$scales$get_scales("shape")$guide, "none")
  expect_equal(visible$dots$scales$get_scales("alpha")$guide, "none")
  expect_false("___padding___" %in% visible$gauge$scales$get_scales("fill")$breaks)
  expect_false("#524F4C" %in% visible$radar$scales$get_scales("colour")$breaks)

  single_line <- lines[lines$category == "Category 1", ]
  single_slope <- slopes[slopes$category == "Category 1", ]
  expect_equal(
    wjp_lines(single_line, "value", "year", show_legend = TRUE)$theme$legend.position,
    "none"
  )
  expect_equal(
    wjp_slope(single_slope, "value", "year", show_legend = TRUE)$theme$legend.position,
    "none"
  )

  expect_error(
    wjp_bars(bars, "value", "item", show_legend = "yes"),
    "`show_legend`"
  )
})

test_that("wjp_rose and wjp_radar accept the harmonized order parameter", {
  radar <- data.frame(
    axis = rep(LETTERS[1:5], 2),
    val = c(20, 40, 60, 80, 50, 30, 50, 70, 65, 45),
    lab = rep(LETTERS[1:5], 2),
    group = rep(c("G1", "G2"), each = 5),
    ord = rep(1:5, 2)
  )

  expect_no_error(ggplot2::ggplot_build(
    wjp_radar(radar, "axis", "val", "lab", "group", order = "ord")
  ))
  expect_no_error(ggplot2::ggplot_build(
    wjp_rose(radar[radar$group == "G1", ], "val", "axis", "lab", order = "ord")
  ))
  # Deprecated alias still works
  expect_no_error(ggplot2::ggplot_build(
    wjp_rose(radar[radar$group == "G1", ], "val", "axis", "lab", order_var = "ord")
  ))
})

test_that("wjp_lollipops supports labels, order, and ptheme", {
  bars <- data.frame(
    cat = c("A", "B", "C"),
    val = c(20, 50, 80),
    lab = c("20%", "50%", "80%"),
    ord = c(3, 2, 1)
  )
  expect_no_error(ggplot2::ggplot_build(
    wjp_lollipops(bars, "val", "cat", labels = "lab", order = "ord")
  ))
})

test_that("wjp_groupbars places CI labels after the full bar", {
  groupbars <- data.frame(
    group = c("Gender", "Gender"),
    level = c("Male", "Female"),
    value = c(45, 55),
    lower = c(40, 50),
    upper = c(50, 60)
  )

  plot <- wjp_groupbars(
    groupbars, "value", "group", "level",
    draw_ci  = TRUE,
    ci_lower = "lower",
    ci_upper = "upper"
  )
  built <- ggplot2::ggplot_build(plot)
  text_layer <- Filter(function(l) "label" %in% names(l) && any(grepl("%", l$label)), built$data)[[1]]
  label_x <- text_layer$x[!is.na(text_layer$label)]
  expect_true(all(label_x == 101))
})

test_that("wjp_groupbars orders default levels naturally from top to bottom", {
  groupbars <- data.frame(
    group = c(rep("Letters", 3), rep("Age", 4)),
    level = c("Zulu", "Alpha", "Beta", "51+", "21-50", "1-20", "9-10"),
    value = rep(0.5, 7)
  )

  plot <- wjp_groupbars(groupbars, "value", "group", "level")
  y_levels <- levels(plot$data$y_id)

  letters_bottom_to_top <- y_levels[startsWith(y_levels, "Letters | ")]
  age_bottom_to_top <- y_levels[startsWith(y_levels, "Age | ")]

  expect_equal(
    rev(sub("^Letters \\| ", "", letters_bottom_to_top)),
    c("Alpha", "Beta", "Zulu")
  )
  expect_equal(
    rev(sub("^Age \\| ", "", age_bottom_to_top)),
    c("1-20", "9-10", "21-50", "51+")
  )

  custom_plot <- wjp_groupbars(
    groupbars[1:3, ],
    "value",
    "group",
    "level",
    level_order = list(Letters = c("Zulu", "Beta", "Alpha"))
  )
  custom_levels <- levels(custom_plot$data$y_id)
  expect_equal(
    rev(sub("^Letters \\| ", "", custom_levels)),
    c("Zulu", "Beta", "Alpha")
  )
})

test_that("wjp_font_family switches chart fonts via the wjpr.family option", {
  expect_equal(wjp_font_family(), "Lato Full")

  withr::with_options(list(wjpr.family = "Inter Tight"), {
    expect_equal(wjp_font_family(), "Inter Tight")

    # Theme text elements pick up the active family
    thm <- WJP_theme()
    expect_equal(thm$axis.title.y$family, "Inter Tight")

    # Chart text layers pick up the active family
    bars <- data.frame(cat = c("A", "B"), val = c(30, 70), lab = c("30%", "70%"))
    plot <- wjp_bars(bars, "val", "cat", labels = "lab")
    text_families <- vapply(
      Filter(function(l) "family" %in% names(l$aes_params), plot$layers),
      function(l) l$aes_params$family,
      character(1)
    )
    expect_true(all(text_families == "Inter Tight"))
  })

  # Explicit family argument overrides the option
  thm <- WJP_theme(family = "Inter Tight")
  expect_equal(thm$axis.text.x$family, "Inter Tight")

  withr::with_options(list(wjpr.family = c("a", "b")), {
    expect_error(wjp_font_family(), "single string")
  })
})
