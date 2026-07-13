#' Validate Data Structure for WJPr Charts
#'
#' @description
#' `wjp_check_data()` validates that a data frame has the correct structure
#' for use with WJPr visualization functions. It checks for required columns,
#' correct data types, and common issues.
#'
#' @param data A data frame to validate.
#' @param type A string specifying the chart type. Options are: "bars", "dots",
#'   "lines", "slope", "dumbbells", "divbars", "radar", "rose", "gauge",
#'   "lollipops", "edgebars", "groupbars".
#' @param target A string specifying the column name for values to plot.
#' @param grouping A string specifying the column name for categories. Default is NULL.
#' @param colors A string specifying the column name for color grouping. Default is NULL.
#' @param cvec A named vector of colors. Default is NULL.
#' @param labels A string specifying the column name for labels. Default is NULL.
#' @param verbose A logical value. If TRUE (default), prints detailed messages.
#'   If FALSE, returns a list with validation results silently.
#'
#' @return If verbose = TRUE, prints validation messages and returns TRUE/FALSE invisibly.
#'   If verbose = FALSE, returns a list with elements: valid (logical), errors (character vector),
#'   warnings (character vector), info (character vector).
#'
#' @export
#'
#' @examples
#' library(dplyr)
#'
#' # Prepare sample data
#' sample_data <- data.frame(
#'   country = c("Atlantis", "Narnia", "Neverland"),
#'   trust = c(45.2, 38.1, 52.3),
#'   year = c("2022", "2022", "2022")
#' )
#'
#' # Check if data is valid for bar chart
#' wjp_check_data(
#'   data     = sample_data,
#'   type     = "bars",
#'   target   = "trust",
#'   grouping = "country",
#'   colors   = "year"
#' )
#'
#' # Check with color vector
#' wjp_check_data(
#'   data     = sample_data,
#'   type     = "bars",
#'   target   = "trust",
#'   grouping = "country",
#'   colors   = "country",
#'   cvec     = c("Atlantis" = "#482d8b", "Narnia" = "#2894aa")
#' )
#'
wjp_check_data <- function(
    data,
    type,
    target,
    grouping = NULL,
    colors   = NULL,
    cvec     = NULL,
    labels   = NULL,
    verbose  = TRUE
) {

  # Initialize results
  errors   <- character()
  warnings <- character()
  info     <- character()

  # Valid chart types
  valid_types <- c("bars", "dots", "lines", "slope", "dumbbells",
                   "divbars", "radar", "rose", "gauge", "lollipops",
                   "edgebars", "groupbars")

  # Check chart type
  if (!type %in% valid_types) {
    errors <- c(errors, paste0(
      "Invalid chart type '", type, "'. ",
      "Valid options: ", paste(valid_types, collapse = ", ")
    ))
  }

  # Check if data is a data frame
  if (!is.data.frame(data)) {
    errors <- c(errors, "Input 'data' must be a data frame.")
    return(.wjp_check_return(errors, warnings, info, verbose))
  }

  # Check number of rows
  if (nrow(data) == 0) {
    errors <- c(errors, "Data frame has 0 rows.")
    return(.wjp_check_return(errors, warnings, info, verbose))
  }

  info <- c(info, paste0("Data has ", nrow(data), " rows and ", ncol(data), " columns."))

  # Check target column
  if (!target %in% names(data)) {
    errors <- c(errors, paste0(
      "Column '", target, "' not found in data. ",
      "Available columns: ", paste(names(data), collapse = ", ")
    ))
  } else {
    # Check if target is numeric
    if (!is.numeric(data[[target]])) {
      errors <- c(errors, paste0(
        "Column '", target, "' should be numeric, found ",
        class(data[[target]])[1], ". ",
        "Tip: Use as.numeric() to convert."
      ))
    } else {
      # Check for NA values
      na_count <- sum(is.na(data[[target]]))
      if (na_count > 0) {
        warnings <- c(warnings, paste0(
          "Column '", target, "' has ", na_count, " NA values ",
          "(", round(na_count / nrow(data) * 100, 1), "% of data)."
        ))
      }

      # Check value range for percentage-based charts
      if (type %in% c("bars", "dots", "lines", "slope", "dumbbells",
                      "divbars", "lollipops", "edgebars")) {
        max_val <- max(data[[target]], na.rm = TRUE)
        min_val <- min(data[[target]], na.rm = TRUE)

        if (max_val > 100 && type != "divbars") {
          warnings <- c(warnings, paste0(
            "Maximum value in '", target, "' is ", round(max_val, 1),
            ". Most WJPr charts expect values between 0-100."
          ))
        }

        if (min_val < 0 && type != "divbars") {
          warnings <- c(warnings, paste0(
            "Minimum value in '", target, "' is ", round(min_val, 1),
            ". Negative values may not display correctly (except for divbars)."
          ))
        }
      }

      info <- c(info, paste0(
        "Column '", target, "' (target): numeric, range [",
        round(min(data[[target]], na.rm = TRUE), 2), ", ",
        round(max(data[[target]], na.rm = TRUE), 2), "]"
      ))
    }
  }

  # Check grouping column
  if (!is.null(grouping)) {
    if (!grouping %in% names(data)) {
      errors <- c(errors, paste0(
        "Column '", grouping, "' not found in data."
      ))
    } else {
      n_groups <- length(unique(data[[grouping]]))
      info <- c(info, paste0(
        "Column '", grouping, "' (grouping): ", n_groups, " unique values."
      ))

      if (n_groups > 20) {
        warnings <- c(warnings, paste0(
          "Column '", grouping, "' has ", n_groups, " unique values. ",
          "Charts may be hard to read with many categories."
        ))
      }
    }
  }

  # Check colors column
  if (!is.null(colors)) {
    if (!colors %in% names(data)) {
      errors <- c(errors, paste0(
        "Column '", colors, "' not found in data."
      ))
    } else {
      color_values <- unique(data[[colors]])
      n_colors <- length(color_values)
      info <- c(info, paste0(
        "Column '", colors, "' (colors): ", n_colors, " unique values: ",
        paste(head(color_values, 5), collapse = ", "),
        ifelse(n_colors > 5, "...", "")
      ))

      # Check cvec if provided
      if (!is.null(cvec)) {
        if (!is.vector(cvec) || is.null(names(cvec))) {
          errors <- c(errors,
            "Parameter 'cvec' must be a named vector (e.g., c('A' = '#482d8b'))."
          )
        } else {
          # Check if all color values have a mapping
          missing_colors <- setdiff(as.character(color_values), names(cvec))
          if (length(missing_colors) > 0) {
            warnings <- c(warnings, paste0(
              "Values in '", colors, "' without color mapping in cvec: ",
              paste(missing_colors, collapse = ", "), ". ",
              "These will use default colors."
            ))
          }

          # Check if cvec has extra values not in data
          extra_colors <- setdiff(names(cvec), as.character(color_values))
          if (length(extra_colors) > 0) {
            info <- c(info, paste0(
              "cvec has colors for values not in data: ",
              paste(extra_colors, collapse = ", ")
            ))
          }

          # Validate color codes
          invalid_colors <- cvec[!grepl("^#[0-9A-Fa-f]{6}$|^#[0-9A-Fa-f]{8}$", cvec)]
          if (length(invalid_colors) > 0) {
            warnings <- c(warnings, paste0(
              "Some cvec values may not be valid hex colors: ",
              paste(names(invalid_colors), collapse = ", ")
            ))
          }
        }
      } else {
        info <- c(info,
          "No cvec provided. Default colors will be used."
        )
      }
    }
  }

  # Check labels column
  if (!is.null(labels)) {
    if (!labels %in% names(data)) {
      errors <- c(errors, paste0(
        "Column '", labels, "' not found in data."
      ))
    } else {
      na_labels <- sum(is.na(data[[labels]]))
      if (na_labels > 0) {
        info <- c(info, paste0(
          "Column '", labels, "' has ", na_labels, " NA values (will show as blank)."
        ))
      }
    }
  }

  # Chart-specific checks
  if (type == "radar") {
    if (is.null(grouping)) {
      errors <- c(errors, "Radar charts require 'grouping' (axis_var) parameter.")
    }
    if (is.null(colors)) {
      errors <- c(errors, "Radar charts require 'colors' parameter.")
    }
  }

  if (type == "dumbbells") {
    info <- c(info,
      "For dumbbells, ensure you have exactly 2 values per grouping category."
    )
  }

  if (type == "divbars") {
    info <- c(info,
      "For divbars, ensure negative values are properly set for one direction."
    )
  }

  # Return results
  return(.wjp_check_return(errors, warnings, info, verbose))
}


#' Internal function to format and return check results
#' @noRd
.wjp_check_return <- function(errors, warnings, info, verbose) {

  is_valid <- length(errors) == 0

  if (verbose) {
    # Print header
    if (is_valid) {
      cat("\n", crayon_green("\u2714 Data structure is valid for WJPr!\n"), sep = "")
    } else {
      cat("\n", crayon_red("\u2718 Data structure has issues.\n"), sep = "")
    }

    # Print errors
    if (length(errors) > 0) {
      cat("\n", crayon_red("Errors:\n"), sep = "")
      for (e in errors) {
        cat("  ", crayon_red("\u2718"), " ", e, "\n", sep = "")
      }
    }

    # Print warnings
    if (length(warnings) > 0) {
      cat("\n", crayon_yellow("Warnings:\n"), sep = "")
      for (w in warnings) {
        cat("  ", crayon_yellow("\u26A0"), " ", w, "\n", sep = "")
      }
    }

    # Print info
    if (length(info) > 0) {
      cat("\n", crayon_blue("Info:\n"), sep = "")
      for (i in info) {
        cat("  ", crayon_blue("\u2139"), " ", i, "\n", sep = "")
      }
    }

    cat("\n")
    return(invisible(is_valid))

  } else {
    return(list(
      valid    = is_valid,
      errors   = errors,
      warnings = warnings,
      info     = info
    ))
  }
}


# Helper functions for colored output (work without cli package)
crayon_green <- function(x) {
  if (requireNamespace("cli", quietly = TRUE)) {
    cli::col_green(x)
  } else {
    x
  }
}

crayon_red <- function(x) {
  if (requireNamespace("cli", quietly = TRUE)) {
    cli::col_red(x)
  } else {
    x
  }
}

crayon_yellow <- function(x) {
  if (requireNamespace("cli", quietly = TRUE)) {
    cli::col_yellow(x)
  } else {
    x
  }
}

crayon_blue <- function(x) {
  if (requireNamespace("cli", quietly = TRUE)) {
    cli::col_cyan(x)
  } else {
    x
  }
}
