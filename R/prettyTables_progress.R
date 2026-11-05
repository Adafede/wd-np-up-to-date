#' Title
#'
#' @param xs Xs
#' @param qids Qids
#'
#' @return NULL
#' @export
#'
#' @examples NULL
prettyTables_progress <- function(xs, qids) {
  lapply(
    xs,
    function(x) {
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
    }
  )
}
