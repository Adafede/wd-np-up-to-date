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
        x |>
          dplyr::left_join(structures_classified) |>
          dplyr::mutate(structureImage = RCurl::curlEscape(structureSmiles)) |>
          dplyr::relocate(structureImage, .after = structure) |>
          dplyr::relocate(structureLabel, .before = structure) |>
          dplyr::select(-references_ids, -structure_id, -structureSmiles) |>
          splitstackshape::cSplit(
            c("taxa", "taxaLabels", "references", "referencesLabels"),
            sep = "|",
            direction = "long"
          ) |>
          dplyr::group_by(structure) |>
          tidyr::fill(c("taxa", "taxaLabels", "references", "referencesLabels"),
                      .direction = "downup") |>
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
            `Taxon Name` = taxaLabels,
            `Taxon ID` = taxa,
            `Reference Title` = referencesLabels,
            `Reference ID` = references
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
