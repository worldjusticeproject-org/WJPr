# Helper: the minimum centre-to-centre distance found among sorted positions.
min_sorted_gap <- function(x) {
  x <- sort(x[!is.na(x)])
  if (length(x) < 2) return(Inf)
  min(diff(x))
}

test_that("three identical values in the middle are separated symmetrically", {
  res <- spread_labels_x(c(0.5, 0.5, 0.5), min_gap = 0.04)

  expect_length(res, 3)
  expect_gte(min_sorted_gap(res), 0.04 - 1e-8)
  # Centroid is preserved by the default (L2) solver
  expect_equal(mean(res), 0.5)
})

test_that("four nearly identical percentage values no longer overlap", {
  vals <- c(0.37, 0.38, 0.38, 0.38)
  res  <- spread_labels_x(vals, min_gap = 0.03)

  expect_gte(min_sorted_gap(res), 0.03 - 1e-8)
  # Points are untouched: labels only move, the input is unchanged
  expect_equal(vals, c(0.37, 0.38, 0.38, 0.38))
})

test_that("a dense group near the lower boundary stays inside the panel", {
  res <- spread_labels_x(c(0.02, 0.03, 0.03), min_gap = 0.05, limits = c(0, 1),
                         details = TRUE)

  left_edges <- res$x - res$half_width
  expect_true(all(left_edges >= 0 - 1e-8))
  expect_gte(min_sorted_gap(res$x), 0.05 - 1e-8)
  expect_true(res$feasible)
})

test_that("a dense group near the upper boundary stays inside the panel", {
  res <- spread_labels_x(c(0.97, 0.98, 0.98), min_gap = 0.05, limits = c(0, 1),
                         details = TRUE)

  right_edges <- res$x + res$half_width
  expect_true(all(right_edges <= 1 + 1e-8))
  expect_gte(min_sorted_gap(res$x), 0.05 - 1e-8)
  expect_true(res$feasible)
})

test_that("labels with different widths are spaced by their rendered dimensions", {
  vals <- c(0.30, 0.31, 0.32)
  res  <- spread_labels_x(
    x       = vals,
    labels  = c("3%", "31%", "100%"),
    limits  = c(0, 1),
    details = TRUE
  )

  hw <- res$half_width
  x  <- res$x
  ord <- order(x)
  x  <- x[ord]
  hw <- hw[ord]
  # Every adjacent pair clears the sum of half-widths (boxes do not overlap)
  gaps <- diff(x)
  needed <- hw[-length(hw)] + hw[-1]
  expect_true(all(gaps >= needed - 1e-6))
})

test_that("already-separated labels are returned unchanged", {
  vals <- c(0.1, 0.5, 0.9)
  res  <- spread_labels_x(vals, min_gap = 0.03, details = TRUE)

  expect_equal(res$x, vals)
  expect_false(res$collided)
  expect_equal(res$max_displacement, 0)
})

test_that("unsorted input with duplicates preserves original row order", {
  vals <- c(0.90, 0.10, 0.38, 0.38, 0.50)
  res  <- spread_labels_x(vals, min_gap = 0.03)

  # Order among elements matches the stable order of the input
  expect_equal(order(res), order(vals, seq_along(vals)))
  expect_gte(min_sorted_gap(res), 0.03 - 1e-8)
})

test_that("an impossible fit warns and reports feasible = FALSE", {
  expect_warning(
    res <- spread_labels_x(c(0.5, 0.5, 0.5), min_gap = 1, limits = c(0, 1),
                           details = TRUE),
    "cannot fit"
  )
  expect_false(res$feasible)
  # Separations are still preserved even when the group overflows
  expect_gte(min_sorted_gap(res$x), 1 - 1e-8)
})

test_that("the helper works on non-percentage continuous scales", {
  vals <- c(1000, 1001, 1002, 1002)
  res  <- spread_labels_x(vals, min_gap = 25, limits = c(0, 2000))

  expect_gte(min_sorted_gap(res), 25 - 1e-8)
  expect_true(all(res >= 0 & res <= 2000))
})

test_that("output is deterministic across repeated runs", {
  vals <- c(0.37, 0.38, 0.38, 0.38, 0.40)
  a <- spread_labels_x(vals, min_gap = 0.03, limits = c(0, 1))
  b <- spread_labels_x(vals, min_gap = 0.03, limits = c(0, 1))
  expect_identical(a, b)

  # Text path is deterministic too
  labs <- scales::percent(vals, accuracy = 1)
  expect_identical(
    spread_labels_x(vals, labels = labs, limits = c(0, 1)),
    spread_labels_x(vals, labels = labs, limits = c(0, 1))
  )
})

test_that("NA positions are preserved and the solve runs on the rest", {
  vals <- c(0.5, NA, 0.5, 0.5)
  res  <- spread_labels_x(vals, min_gap = 0.04)

  expect_true(is.na(res[2]))
  expect_gte(min_sorted_gap(res), 0.04 - 1e-8)
})

test_that("preserve_center = FALSE anchors the group at the first label", {
  vals <- c(0.5, 0.5, 0.5)
  res  <- spread_labels_x(vals, min_gap = 0.04, preserve_center = FALSE)

  expect_equal(min(res), 0.5)             # forward pass keeps the first anchor
  expect_gte(min_sorted_gap(res), 0.04 - 1e-8)
})

test_that("the helper works independently within grouped data", {
  df <- data.frame(
    grp = rep(c("A", "B"), each = 3),
    val = c(0.5, 0.5, 0.5, 0.1, 0.5, 0.9)
  )
  out <- unlist(lapply(split(df$val, df$grp), spread_labels_x, min_gap = 0.04),
                use.names = FALSE)

  # Group A spreads; group B was already separated and stays put
  expect_gte(min_sorted_gap(out[1:3]), 0.04 - 1e-8)
  expect_equal(out[4:6], c(0.1, 0.5, 0.9))
})

test_that("invalid inputs raise clear errors", {
  expect_error(spread_labels_x("a"), "`x` must be a numeric")
  expect_error(spread_labels_x(c(1, 2)), "Provide either `min_gap`")
  expect_error(spread_labels_x(c(1, 2), min_gap = -1), "non-negative")
  expect_error(spread_labels_x(c(1, 2), labels = "only-one"), "same length")
  expect_error(spread_labels_x(c(1, 2), labels = c("a", "b")), "`limits` is required")
  expect_error(
    spread_labels_x(c(1, 2), min_gap = 0.1, limits = c(1, 0)),
    "lower < upper"
  )
})
