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
  xs |>
   furrr::future_map(
     .f = function(x, qids) {
       p()
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
