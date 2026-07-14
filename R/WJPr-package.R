#' @keywords internal
"_PACKAGE"

if (getRversion() >= "2.15.1") {
  utils::globalVariables(c(
    ".",
    "alabels_var",
    "ci_lower_var",
    "ci_upper_var",
    "color",
    "color_type",
    "color_var",
    "colors_var",
    "coords",
    "dim_results",
    "end",
    "end_group",
    "fill",
    "geovar",
    "group",
    "group_var",
    "grouping_var",
    "hjust",
    "id",
    "lab0",
    "lab1",
    "label",
    "label_value",
    "label_var",
    "label_x",
    "labels_var",
    "labp0",
    "labp1",
    "labpos",
    "labpos_var",
    "levels_var",
    "lower",
    "maincat_var",
    "order_var",
    "p_value",
    "primary",
    "r",
    "rows_var",
    "sample_size_var",
    "scaled_val",
    "sd_pct",
    "sd_var",
    "se",
    "secondary",
    "start",
    "start_group",
    "stat",
    "target_pct",
    "target_var",
    "upper",
    "value",
    "variable",
    "x",
    "x_var",
    "xmax",
    "xmin",
    "xposition",
    "y",
    "y_id",
    "y_value",
    "ymax",
    "ymin"
  ))
}

# =============================================================================
# Package startup
# =============================================================================

#' @title Package Load Hook
#' @description Runs when the package is loaded. Verifies critical dependencies.
#' @param libname Library name
#' @param pkgname Package name
#' @keywords internal
#' @noRd
.onLoad <- function(libname, pkgname) {

 # Core dependencies that must be available
 core_deps <- c("ggplot2", "dplyr", "tidyr", "magrittr")

 missing_core <- vapply(core_deps, function(pkg) {
    !requireNamespace(pkg, quietly = TRUE)
  }, logical(1))

  if (any(missing_core)) {
    missing_names <- core_deps[missing_core]
    warning(
      "WJPr: Missing core dependencies: ",
      paste(missing_names, collapse = ", "),
      "\nInstall with: install.packages(c('",
      paste(missing_names, collapse = "', '"),
      "'))",
      call. = FALSE
    )
  }
}

#' @title Package Attach Hook
#' @description Runs when the package is attached. Shows startup message.
#' @param libname Library name
#' @param pkgname Package name
#' @keywords internal
#' @noRd
.onAttach <- function(libname, pkgname) {

 # Check for optional dependencies
 optional_deps <- c("ggtext", "ggrepel", "ggh4x")

 missing_optional <- vapply(optional_deps, function(pkg) {
    !requireNamespace(pkg, quietly = TRUE)
  }, logical(1))

  if (any(missing_optional)) {
    missing_names <- optional_deps[missing_optional]
    packageStartupMessage(
      "WJPr: Some optional packages are not installed: ",
      paste(missing_names, collapse = ", "),
      "\nSome chart features may be limited. ",
      "Run wjp_check_deps() for details."
    )
  }
}

NULL
