require(package = purrr, quietly = TRUE)
require(package = yaml, quietly = TRUE)


#' Title
#'
#' @return
#' @export
#'
#' @examples
parse_yaml_paths <- function() {
  message("Loading paths")
  suppressWarnings(paths <- yaml::read_yaml(
    file = "paths.yaml",
    handlers = list(
      seq = function(x) {
        purrr::flatten(x)
      }
    )
  ))
  setwd(paths$base_dir)

  return(paths)
}
