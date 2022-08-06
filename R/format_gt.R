require(package = dplyr, quietly = TRUE)
require(package = gt, quietly = TRUE)
require(package = htmltools, quietly = TRUE)
require(package = purrr, quietly = TRUE)

#' Title
#'
#' @param table
#'
#' @return
#' @export
#'
#' @examples
temp_gt_function <- function(table, title, subtitle) {
  sub_wiki <- function(x) {
    x |>
      gsub(pattern = "http://www.wikidata.org/entity/",
           replacement = "",
           x = x)
  }
  prettyTable <- table %>%
    dplyr::mutate(
      `Structure ID` = purrr::map(`Structure ID`, ~ htmltools::a(href = .x, sub_wiki(.x))),
      `Structure ID` = purrr::map(`Structure ID`, ~ gt::html(as.character(.x)))
    ) %>%
    dplyr::mutate(
      `Taxon ID` = purrr::map(`Taxon ID`, ~ htmltools::a(href = .x, sub_wiki(.x))),
      `Taxon ID` = purrr::map(`Taxon ID`, ~ gt::html(as.character(.x)))
    ) %>%
    dplyr::mutate(
      `Reference ID` = purrr::map(`Reference ID`, ~ htmltools::a(href = .x, sub_wiki(.x))),
      `Reference ID` = purrr::map(`Reference ID`, ~ gt::html(as.character(.x)))
    ) %>%
    gt::gt() %>%
    gt::cols_width(everything() ~ px(200)) %>%
    gt::tab_header(title = title) %>%
    gt::text_transform(locations = gt::cells_body(columns = `Structure Depiction`),
                       fn = molinfo)
  return(prettyTable)
}
