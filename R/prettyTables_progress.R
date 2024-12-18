#' Title
#'
#' @param xs
#' @param qids
#'
#' @return NULL
#' @export
#'
#' @examples NULL
prettyTables_progress <- function(xs, qids) {
  xs |>
    purrr::map(
      .progress = TRUE,
      .f = function(x, qids) {
        format_gt(
          table = x,
          title = paste(
            "Compounds found in",
            names(qids[[1]]),
            "on ",
            as.Date(Sys.Date(), "%m/%d/%y")
          ),
          subtitle = "All compounds"
        )
      },
      qids = qids
    )
}
