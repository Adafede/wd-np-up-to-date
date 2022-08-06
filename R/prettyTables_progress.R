#' Title
#'
#' @param xs
#'
#' @return
#' @export
#'
#' @examples
prettyTables_progress <- function(xs) {
  p <- progressr::progressor(along = xs)
  future.apply::future_lapply(
    X = xs,
    FUN = function(x) {
      p()
      temp_gt_function(table = x,
                       title = paste(
                         "Compounds found in",
                         names(params$organisms$wikidata),
                         "on ",
                         as.Date(Sys.Date(), "%m/%d/%y")
                       ))
    }
  )
}
