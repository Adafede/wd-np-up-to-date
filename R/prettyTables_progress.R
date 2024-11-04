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
  p <- progressr::progressor(along = xs)
  future.apply::future_lapply(
    X = xs,
    FUN = function(x, qids) {
      p()
      temp_gt_function(
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
