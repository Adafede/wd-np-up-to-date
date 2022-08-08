#' Title
#'
#' @param xs
#'
#' @return
#' @export
#'
#' @examples
tables_progress <- function(xs) {
  p <- progressr::progressor(along = xs)
  future.apply::future_lapply(
    X = xs,
    FUN = function(x) {
      p()
      if (nrow(x != 0)) {
        y <-  x |>
          dplyr::left_join(structures_classified) |>
          dplyr::mutate(structureImage = RCurl::curlEscape(structureSmiles)) |>
          dplyr::relocate(structureImage, .after = structure) |>
          dplyr::relocate(structureLabel, .before = structure) |>
          dplyr::select(-art_doi, -structure_id, -structureSmiles) |>
          dplyr::group_by(chemical_class) |>
          dplyr::add_count(sort = TRUE) |>
          dplyr::select(-n) |>
          dplyr::group_by(chemical_superclass) |>
          dplyr::add_count(sort = TRUE) |>
          dplyr::select(-n) |>
          dplyr::group_by(chemical_pathway) |>
          dplyr::add_count(sort = TRUE) |>
          dplyr::select(-n) |>
          dplyr::distinct() |>
          dplyr::select(
            `Structure Name` = structureLabel,
            `Structure ID` = structure,
            `Structure Depiction` = structureImage,
            `Structure Exact Mass` = structure_exact_mass,
            `Structure XLogP` = structure_xlogp,
            `Chemical Pathway` = chemical_pathway,
            `Chemical Superclass` = chemical_superclass,
            `Chemical Class` = chemical_class,
            `Taxon Name` = taxon_name,
            `Taxon ID` = taxon,
            `Reference Title` = art_title,
            `Reference ID` = art
          )
      } else {
        data.frame() |>
          dplyr::mutate(
            `Structure Name` = NA,
            `Structure ID` = NA,
            `Structure Depiction` = NA,
            `Structure Exact Mass` = NA,
            `Structure XLogP` = NA,
            `Chemical Pathway` = NA,
            `Chemical Superclass` = NA,
            `Chemical Class` = NA,
            `Taxon Name` = NA,
            `Taxon ID` = NA,
            `Reference Title` = NA,
            `Reference ID` = NA
          )
      }
    }
  )
}
