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

  groupbars <- data.frame(group = "G", level = "L", value = 45)
  expect_error(
    wjp_groupbars(groupbars, "value", "group", "level"),
    "between 0 and 1"
  )
})
