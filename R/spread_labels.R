#' Spread overlapping point labels horizontally
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `spread_labels_x()` is a low-level, deterministic helper for row-based point
#' charts (for example [wjp_dots()] or [wjp_lollipops()]). When several
#' observations in the same row share equal or nearly equal values, the
#' percentage labels placed above their points overlap and become unreadable.
#'
#' The helper keeps every point at its true value and every label on the same
#' vertical level, and moves **only the labels horizontally** by the minimum
#' distance required to prevent collisions. This avoids the vertical
#' stair-stepping and connector lines produced by general-purpose repulsion,
#' yielding a compact result that stays consistent with the visual language of
#' the chart.
#'
#' @details
#' The function returns adjusted horizontal positions for the labels; the points
#' themselves are never modified. It works within a single row or group at a
#' time, so it is meant to be called inside a `dplyr::group_by()` /
#' `dplyr::mutate()` pipeline (see Examples).
#'
#' Two ways to size the required separation are supported:
#' \itemize{
#'   \item \strong{`min_gap`} (data units): a fixed minimum centre-to-centre
#'     distance between adjacent labels. This path needs no graphics device and
#'     produces fully reproducible output; it is the simplest option when the
#'     labels are similar in width.
#'   \item \strong{`labels`} (text): the rendered width of each string is
#'     measured (with \pkg{systemfonts} when available, otherwise a deterministic
#'     character-count estimate) and converted to data units using `limits` and
#'     `panel_width`. Use this path when the strings differ substantially in
#'     width.
#' }
#'
#' The solver is deterministic. With `preserve_center = TRUE` (default) it uses
#' an isotonic (pool-adjacent-violators) fit that minimises the total squared
#' displacement, which keeps the centre of the label group on the original
#' centroid. With `preserve_center = FALSE` it uses a single forward pass
#' anchored at the first label, pushing labels forward only. In both cases,
#' labels that are already separated are left untouched, identical inputs always
#' produce identical output, and the original row order is restored on return.
#'
#' When `limits` is supplied, the whole label group is rigidly shifted back
#' inside the panel if it crosses a boundary; a rigid shift preserves the
#' separations, so boundary handling never reintroduces collisions. If the
#' combined label widths cannot fit inside `limits`, the function emits a warning
#' and returns a best-effort, left-aligned layout with `feasible = FALSE` (see
#' `details`) rather than silently overlapping labels.
#'
#' The helper targets Cartesian, continuous horizontal scales. Logarithmic,
#' transformed, or otherwise non-linear scales are not handled: convert the
#' positions to the linear coordinate system before calling.
#'
#' @param x Numeric vector of the original point positions, in data units.
#'   `NA` positions are returned as `NA` and excluded from the solve.
#' @param labels Optional character vector (same length as `x`) whose rendered
#'   width is used to size the required separation. Requires `limits`. Ignored
#'   when `min_gap` is supplied. Default is `NULL`.
#' @param min_gap Optional numeric scalar giving a fixed minimum centre-to-centre
#'   distance between adjacent labels, in data units. Takes precedence over
#'   `labels`. Default is `NULL`.
#' @param limits Optional numeric vector of length 2, `c(lower, upper)`, giving
#'   the panel range in data units. The whole label group is kept inside these
#'   limits. Required when `labels` is used (to convert text widths to data
#'   units). Default is `NULL`.
#' @param preserve_center Logical. If `TRUE` (default) the adjusted group is kept
#'   centred on the original centroid (minimum squared displacement). If `FALSE`,
#'   a forward-only pass is used. Default is `TRUE`.
#' @param padding Extra space added between adjacent label bounding boxes, as a
#'   [grid::unit] (converted to data units via `limits`/`panel_width`) or a
#'   numeric value in data units. Only used on the `labels` path. Default is
#'   `grid::unit(1.5, "mm")`.
#' @param panel_width Physical width of the plotting panel, as a [grid::unit] or
#'   a numeric value in millimetres. Together with `limits` it sets the
#'   data-units-per-millimetre scale used to convert measured text widths. Only
#'   used on the `labels` path. Default is `grid::unit(150, "mm")`.
#' @param font_size Numeric. Label size in the same units as `ggplot2`
#'   `geom_text(size = )` (millimetres). Only used on the `labels` path. Default
#'   is `3.514598` (the WJP 10 pt value-label size).
#' @param family String. Font family used to measure the labels. Only used on the
#'   `labels` path. Default is the active WJP family (see [wjp_font_family()]).
#' @param tol Numeric. Numerical tolerance used when comparing gaps and panel
#'   limits. Default is `1e-8`.
#' @param details Logical. If `TRUE`, returns a list with the adjusted positions
#'   plus diagnostics instead of a bare numeric vector. Default is `FALSE`.
#'
#' @return
#' By default, a numeric vector of adjusted horizontal positions in the original
#' order of `x`. If `details = TRUE`, a list with:
#' \describe{
#'   \item{`x`}{Adjusted positions (original order).}
#'   \item{`input`}{The original `x`.}
#'   \item{`displacement`}{`x` adjusted minus `x` input.}
#'   \item{`max_displacement`}{Maximum absolute displacement.}
#'   \item{`half_width`}{Per-label half-width in data units (original order).}
#'   \item{`collided`}{`TRUE` if the input positions overlapped.}
#'   \item{`feasible`}{`FALSE` if the labels cannot fit inside `limits`.}
#' }
#'
#' @importFrom stats isoreg
#' @importFrom grid convertWidth is.unit unit
#'
#' @export
#'
#' @examples
#' # Fixed-gap mode: four nearly identical values kept from overlapping
#' spread_labels_x(c(0.37, 0.38, 0.38, 0.38), min_gap = 0.03)
#'
#' # Already-separated values are returned unchanged
#' spread_labels_x(c(0.1, 0.5, 0.9), min_gap = 0.03)
#'
#' # The group is kept inside the panel limits
#' spread_labels_x(c(0.95, 0.96, 0.97), min_gap = 0.04, limits = c(0, 1))
#'
#' # Diagnostics
#' spread_labels_x(c(0.5, 0.5, 0.5), min_gap = 0.05, details = TRUE)
#'
#' # Text mode: separation sized from the rendered width of each label
#' vals <- c(0.37, 0.38, 0.38)
#' spread_labels_x(
#'   x      = vals,
#'   labels = scales::percent(vals, accuracy = 1),
#'   limits = c(0, 1)
#' )
#'
#' \donttest{
#' # Typical use inside a plotting pipeline
#' library(dplyr)
#' library(ggplot2)
#' wjp_fonts()
#'
#' chart_data <- tibble::tibble(
#'   outcome  = rep(c("Row A", "Row B"), each = 3),
#'   category = rep(c("G1", "G2", "G3"), times = 2),
#'   value    = c(0.37, 0.38, 0.38, 0.20, 0.55, 0.90)
#' )
#'
#' label_data <- chart_data %>%
#'   group_by(outcome) %>%
#'   mutate(
#'     label   = scales::percent(value, accuracy = 1),
#'     label_x = spread_labels_x(value, labels = label, limits = c(0, 1))
#'   ) %>%
#'   ungroup()
#'
#' ggplot(label_data, aes(value, outcome, color = category)) +
#'   geom_point(size = 3) +
#'   geom_text(aes(x = label_x, label = label), vjust = -0.8, show.legend = FALSE) +
#'   scale_x_continuous(limits = c(0, 1)) +
#'   WJP_theme()
#' }
#'
spread_labels_x <- function(
    x,
    labels          = NULL,
    min_gap         = NULL,
    limits          = NULL,
    preserve_center = TRUE,
    padding         = grid::unit(1.5, "mm"),
    panel_width     = grid::unit(150, "mm"),
    font_size       = 3.514598,
    family          = wjp_font_family(),
    tol             = 1e-8,
    details         = FALSE
) {

  # ---- Validate inputs ------------------------------------------------------
  if (!is.numeric(x)) {
    stop("`x` must be a numeric vector.", call. = FALSE)
  }
  if (length(preserve_center) != 1 || !is.logical(preserve_center) ||
      is.na(preserve_center)) {
    stop("`preserve_center` must be TRUE or FALSE.", call. = FALSE)
  }
  if (length(details) != 1 || !is.logical(details) || is.na(details)) {
    stop("`details` must be TRUE or FALSE.", call. = FALSE)
  }
  if (!is.null(limits)) {
    if (!is.numeric(limits) || length(limits) != 2 || any(!is.finite(limits)) ||
        limits[2] <= limits[1]) {
      stop("`limits` must be a numeric vector `c(lower, upper)` with lower < upper.",
           call. = FALSE)
    }
  }
  if (!is.null(labels) && length(labels) != length(x)) {
    stop("`labels` must have the same length as `x`.", call. = FALSE)
  }

  n <- length(x)

  # Empty input: nothing to solve.
  if (n == 0) {
    return(if (details) {
      list(x = x, input = x, displacement = numeric(0),
           max_displacement = 0, half_width = numeric(0),
           collided = FALSE, feasible = TRUE)
    } else {
      x
    })
  }

  keep <- !is.na(x)

  # ---- Determine per-label half-widths (data units) -------------------------
  half_width <- rep(NA_real_, n)

  if (!is.null(min_gap)) {
    if (length(min_gap) != 1 || !is.numeric(min_gap) || !is.finite(min_gap) ||
        min_gap < 0) {
      stop("`min_gap` must be a single non-negative number.", call. = FALSE)
    }
    # A uniform gap is modelled as each label occupying `min_gap / 2` per side.
    half_width[keep] <- min_gap / 2
    pad_data <- 0
  } else if (!is.null(labels)) {
    if (is.null(limits)) {
      stop("`limits` is required when sizing the gap from `labels`. ",
           "Supply `limits`, or use `min_gap` for a fixed separation.",
           call. = FALSE)
    }
    scale       <- diff(limits) / wjp_unit_mm(panel_width, "panel_width")
    widths_mm   <- wjp_text_width_mm(as.character(labels)[keep], font_size, family)
    half_width[keep] <- (widths_mm / 2) * scale
    pad_data <- if (grid::is.unit(padding)) {
      wjp_unit_mm(padding, "padding") * scale
    } else if (is.numeric(padding) && length(padding) == 1) {
      padding
    } else {
      stop("`padding` must be a grid unit or a single number.", call. = FALSE)
    }
  } else {
    stop("Provide either `min_gap` (fixed separation) or `labels` ",
         "(measured separation).", call. = FALSE)
  }

  # ---- Solve on the non-missing positions -----------------------------------
  out      <- x
  feasible <- TRUE
  collided <- FALSE

  if (any(keep)) {
    solved <- wjp_solve_nonoverlap(
      x               = x[keep],
      half_width      = half_width[keep],
      pad             = pad_data,
      limits          = limits,
      preserve_center = preserve_center,
      tol             = tol
    )
    out[keep] <- solved$x
    feasible  <- solved$feasible
    collided  <- solved$collided
  }

  if (!feasible) {
    warning(
      "Labels cannot fit inside `limits`; returning a best-effort layout. ",
      "Consider a different design for this row.",
      call. = FALSE
    )
  }

  if (!details) {
    return(out)
  }

  displacement <- out - x
  list(
    x                = out,
    input            = x,
    displacement     = displacement,
    max_displacement = if (any(keep)) max(abs(displacement[keep])) else 0,
    half_width       = half_width,
    collided         = collided,
    feasible         = feasible
  )
}


#' Deterministic one-dimensional non-overlap solver
#'
#' Places labels on a line so that adjacent (sorted) centres are separated by at
#' least `half_width[k] + half_width[k+1] + pad`, minimising displacement from
#' `x`. Returns positions in the original order.
#'
#' @noRd
wjp_solve_nonoverlap <- function(x, half_width, pad, limits, preserve_center, tol) {

  n   <- length(x)
  ord <- order(x, seq_len(n))            # stable tie-break by original index
  xs  <- x[ord]
  hw  <- half_width[ord]

  # Required centre-to-centre gaps between neighbouring (sorted) labels.
  g <- if (n >= 2) hw[-n] + hw[-1] + pad else numeric(0)

  collided <- n >= 2 && any(diff(xs) < g - tol)

  if (preserve_center) {
    # Isotonic (pool-adjacent-violators) fit: the L2-optimal, centroid-
    # preserving arrangement. Constraint centre[k+1] - centre[k] >= g[k]
    # becomes "the shifted sequence must be non-decreasing".
    offset  <- c(0, cumsum(g))
    fitted  <- stats::isoreg(xs - offset)$yf
    centers <- fitted + offset
  } else {
    # Forward-only pass anchored at the first label.
    centers <- xs
    if (n >= 2) {
      for (k in 2:n) {
        centers[k] <- max(centers[k], centers[k - 1] + g[k - 1])
      }
    }
  }

  # ---- Keep the whole group inside the panel via a rigid shift --------------
  feasible <- TRUE
  if (!is.null(limits)) {
    lo   <- limits[1]
    hi   <- limits[2]
    left  <- centers[1] - hw[1]
    right <- centers[n] + hw[n]

    if ((right - left) > (hi - lo) + tol) {
      # The labels are wider than the panel: left-align, keep separations,
      # and flag as infeasible instead of clipping individual labels.
      feasible <- FALSE
      centers  <- centers + (lo - left)
    } else if (left < lo - tol) {
      centers <- centers + (lo - left)
    } else if (right > hi + tol) {
      centers <- centers + (hi - right)
    }
  }

  out      <- numeric(n)
  out[ord] <- centers
  list(x = out, feasible = feasible, collided = collided)
}


#' Measure the rendered width of label strings, in millimetres
#'
#' Uses \pkg{systemfonts} when available for true rendered metrics; otherwise
#' falls back to a deterministic character-count estimate. Both paths are
#' device-free and reproducible.
#'
#' @noRd
wjp_text_width_mm <- function(labels, font_size, family) {
  labels <- as.character(labels)
  if (length(labels) == 0) return(numeric(0))

  # ggplot2 text `size` is in millimetres; the point size is size * .pt.
  pt_size <- font_size * ggplot2::.pt

  if (requireNamespace("systemfonts", quietly = TRUE)) {
    widths <- tryCatch(
      systemfonts::string_width(labels, family = family, size = pt_size),
      error = function(e) NULL
    )
    if (!is.null(widths) && length(widths) == length(labels) &&
        all(is.finite(widths))) {
      # string_width returns points (1/72 inch) at the default resolution.
      return(widths * (25.4 / 72))
    }
  }

  # Fallback: average advance width ~ 0.5 em for proportional fonts.
  em_mm <- pt_size * (25.4 / 72.27)
  nchar(labels) * 0.5 * em_mm
}


#' Convert a grid unit (or millimetre scalar) to millimetres
#'
#' @noRd
wjp_unit_mm <- function(u, arg) {
  if (grid::is.unit(u)) {
    grid::convertWidth(u, "mm", valueOnly = TRUE)
  } else if (is.numeric(u) && length(u) == 1 && is.finite(u) && u > 0) {
    u
  } else {
    stop(sprintf("`%s` must be a grid unit or a single positive number (mm).", arg),
         call. = FALSE)
  }
}
