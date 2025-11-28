start <- Sys.time()

source(
  file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/check_export_dir.R"
)
source(
  file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/format_gt.R"
)
source(
  file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/molinfo.R"
)
source(
  file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/queries_progress.R"
)
source(
  file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/tables_progress.R"
)
source(
  file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/wiki_progress.R"
)
source(
  file = "https://raw.githubusercontent.com/taxonomicallyinformedannotation/tima-r/main/R/constants.R"
)
source(
  file = "https://raw.githubusercontent.com/taxonomicallyinformedannotation/tima-r/main/R/create_dir.R"
)
source(
  file = "https://raw.githubusercontent.com/taxonomicallyinformedannotation/tima/main/R/get_file.R"
)
source(
  file = "https://raw.githubusercontent.com/taxonomicallyinformedannotation/tima/main/R/get_last_version_from_zenodo.R"
)
source(
  file = "https://raw.githubusercontent.com/taxonomicallyinformedannotation/tima/main/R/logs_utils.R"
)
source(
  file = "https://raw.githubusercontent.com/taxonomicallyinformedannotation/tima/main/R/validations_utils.R"
)
source(file = "R/prettyTables_progress.R")

message("Getting last LOTUS version")
get_last_version_from_zenodo(
  doi = "10.5281/zenodo.5794106",
  pattern = "frozen_metadata.csv.gz",
  "data/source/libraries/lotus.csv.gz"
)

qids <- list(c("Swertia" = "Q163970"))

genera <-
  names(qids)[
    !grepl(
      pattern = " ",
      x = names(qids),
      fixed = TRUE
    )
  ]

message("Loading LOTUS classified structures")
structures_classified <- readr::read_delim(
  file = "data/source/libraries/lotus.csv.gz",
  col_select = c(
    "structure_id" = "structure_inchikey",
    "structure_smiles_no_stereo" = "structure_smiles_2D",
    "structure_exact_mass",
    "structure_xlogp",
    "chemical_pathway" = "structure_taxonomy_npclassifier_01pathway",
    "chemical_superclass" = "structure_taxonomy_npclassifier_02superclass",
    "chemical_class" = "structure_taxonomy_npclassifier_03class"
  )
) |>
  tidytable::distinct()

query_part_1 <- "SELECT DISTINCT ?structure ?structureLabel ?structure_id ?structureSmiles ?taxaLabels ?taxa ?referencesLabels ?references_ids ?references WHERE {\n  ?taxa (wdt:P171*) wd:"
query_part_2 <- ";\n  wdt:P225 ?taxaLabels. \n  ?structure wdt:P235 ?structure_id;\n  wdt:P233 ?structureSmiles;\n  p:P703 ?statement.\n  ?statement ps:P703 ?taxa;\n  prov:wasDerivedFrom ?ref.\n  ?ref pr:P248 ?references.\n  SERVICE <https://query-scholarly.wikidata.org/sparql> { \n ?references wdt:P1476 ?referencesLabels;\n  wdt:P356 ?references_ids;\n  wdt:P577 ?art_date.\n  }\n FILTER(((YEAR(?art_date)) >= "
query_part_3 <- " ) && ((YEAR(?art_date)) <= "
query_part_4 <- " ))\n  SERVICE wikibase:label { bd:serviceParam wikibase:language \"[AUTO_LANGUAGE], mul, en\". }\n}"

message("Building queries")
queries <- queries_progress(
  xs = qids,
  query_part_1 = query_part_1,
  query_part_2 = query_part_2,
  query_part_3 = query_part_3,
  query_part_4 = query_part_4
)

message("Querying Wikidata")
results <- wiki_progress(xs = queries)

message("Cleaning tables and adding columns")
tables <- tables_progress(
  results,
  structures_classified = structures_classified
) |>
  purrr::map(
    .f = function(x) {
      x |> tidytable::distinct(structure, taxa, references, .keep_all = TRUE)
    }
  )

message("Re-ordering")
tables <- tables |>
  purrr::map(
    .f = function(x) {
      x |>
        tidytable::relocate(
          structure_smiles_no_stereo,
          .after = structureImage
        ) |>
        tidytable::relocate(
          structure_exact_mass,
          .after = structure_smiles_no_stereo
        ) |>
        tidytable::relocate(structure_xlogp, .after = structure_exact_mass) |>
        tidytable::relocate(chemical_pathway, .before = structureLabel) |>
        tidytable::relocate(chemical_superclass, .after = chemical_pathway) |>
        tidytable::relocate(chemical_class, .after = chemical_superclass) |>
        tidytable::mutate(structureImage = molinfo(structureImage)) |>
        tidytable::group_by(chemical_pathway)
    }
  )

# message("Generating subtables based on chemical classification")
# subtables <- subtables_progress(tables)

message("Generating pretty tables")
prettyTables <- prettyTables_progress(tables, qids = qids) |>
  purrr::map(
    .f = function(x) {
      x |>
        gt::opt_interactive(use_filters = TRUE)
    }
  )

# message("Generating pretty subtables")
# prettySubtables <- prettyTables_progress(subtables)

message("Exporting html tables")
gt::gtsave(data = prettyTables[[1]], filename = "output/index.html")

end <- Sys.time()

message("Script finished in ", format(end - start))
