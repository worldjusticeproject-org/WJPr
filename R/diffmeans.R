#' Difference of Means Analysis
#'
#' @description
#' `diffmeans()` performs statistical hypothesis testing for differences in means between
#' two groups across multiple target variables and grouping variables. It supports both
#' categorical (proportion test) and continuous (t-test) variables.
#'
#' @param data A data frame containing the data to be analyzed.
#' @param target_vars A character vector specifying the column names of the target variables to analyze.
#' @param group_vars A character vector specifying the column names of the binary grouping variables (must contain values 0 and 1).
#' @param geo_var A string specifying the column name of the geographic or stratification variable used to group results.
#' @param type A string specifying the type of test to perform. Options are:
#'   \itemize{
#'     \item \code{"categorical"}: Uses \code{prop.test()} for proportion comparisons (default)
#'     \item \code{"continuous"}: Uses \code{t.test()} for mean comparisons
#'   }
#' @param t A numeric value specifying the significance threshold for determining statistical significance. Default is 0.1.
#' @param collapse A logical value. If TRUE (default), results are collapsed into a single data frame. If FALSE, returns a nested list.
#' @param verbose A logical value. If TRUE, prints progress messages during execution. Default is FALSE.
#'
#' @return A list of data frames (one per grouping variable) containing:
#'   \itemize{
#'     \item \code{geovar}: The geographic/stratification variable values
#'     \item \code{variable}: The target variable name (if collapse = TRUE)
#'     \item \code{mean_A}: Mean for group A (grouping == 1)
#'     \item \code{mean_B}: Mean for group B (grouping == 0)
#'     \item \code{diff}: Difference between means (mean_A - mean_B)
#'     \item \code{stat}: Test statistic (chi-squared for prop.test, t for t.test)
#'     \item \code{p_value}: P-value from the statistical test
#'     \item \code{stat_sig}: Logical indicating if p_value <= t
#'   }
#'
#' @export
#'
#' @examples
#' library(dplyr)
#'
#' # Preparing data
#' gpp_data <- WJPr::gpp %>%
#'   mutate(
#'     q1a = as.double(unclass(q1a)),
#'     q1b = as.double(unclass(q1b)),
#'     gend = as.double(unclass(gend)),
#'     trust_a = case_when(q1a <= 2 ~ 1, q1a <= 4 ~ 0),
#'     trust_b = case_when(q1b <= 2 ~ 1, q1b <= 4 ~ 0),
#'     female = case_when(gend == 2 ~ 1, gend == 1 ~ 0)
#'   )
#'
#' # Test differences in trust by gender across countries
#' results <- diffmeans(
#'   data        = gpp_data,
#'   target_vars = c("trust_a", "trust_b"),
#'   group_vars  = c("female"),
#'   geo_var     = "country",
#'   type        = "categorical",
#'   t           = 0.05
#' )
#'
diffmeans <- function(data, target_vars, group_vars, geo_var, type = "categorical", t = 0.1, collapse = TRUE, verbose = FALSE){
  
  # Looping through grouping alternatives
  groloop <- lapply(
    group_vars %>% set_names(group_vars),
    function(grouping){
      
      if (verbose == TRUE){
        print("=================")
        print(grouping)
      }
      
      # Looping through target variables
      varloop <- lapply(
        target_vars %>% set_names(target_vars),
        function(target){
          
          if (verbose == TRUE){
            print("--------------")
            print(target)
          }
          
          # Preparing data for tests
          data_subset <- data %>%
            select(
              grouping = all_of(grouping),
              target   = all_of(target),
              geovar   = all_of(geo_var)
            )
          
          # Defining a function to estimate the results.
          if (type == "continuous") {
            stat_function <- function(df) {
              group_A <- df %>% filter(grouping == 1) %>% pull(target)
              group_B <- df %>% filter(grouping == 0) %>% pull(target)
              mean_A  <- mean(group_A, na.rm = TRUE)
              mean_B  <- mean(group_B, na.rm = TRUE)
              ttest_result <- t.test(group_A, group_B, paired = FALSE)
              
              data.frame(
                mean_A  = mean_A,
                mean_B  = mean_B,
                diff    = mean_A - mean_B,
                stat    = ttest_result$statistic,
                p_value = ttest_result$p.value
              )
            }
          }
          if (type == "categorical") {
            stat_function <- function(df) {
              count_table      <- table(df$grouping, df$target)
              prop_test_result <- prop.test(count_table)
              mean_A <- mean(df$target[df$grouping == 1], na.rm = TRUE)
              mean_B <- mean(df$target[df$grouping == 0], na.rm = TRUE)
              
              data.frame(
                mean_A  = mean_A,
                mean_B  = mean_B,
                diff    = mean_A - mean_B,
                stat    = prop_test_result$statistic,
                p_value = prop_test_result$p.value
              )
            }
          }
          
          results <- data_subset %>%
            group_by(geovar) %>%
            nest() %>%
            mutate(
              dim_results = map(data, stat_function)
            ) %>%
            unnest(dim_results) %>%
            select(-data) %>%
            mutate(
              across(
                c(stat, p_value),
                ~if_else(is.na(diff), NA_real_, .x)
              ),
              stat_sig = if_else(p_value <= t, TRUE, FALSE, missing = FALSE),
            )
        }
      )
      
      if (collapse == TRUE){
        varloop <- imap_dfr(
          varloop,
          function(df, var){
            df %>%
              mutate(
                variable = var
              ) %>%
              relocate(variable)
          }
        ) 
      } else {
        varloop <- varloop
      }
      
      return(varloop)

    }
  )

  return(groloop)
}
