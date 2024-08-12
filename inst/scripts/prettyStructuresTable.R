start <- Sys.time()

source(file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/check_export_dir.R")
source(file = "https://raw.githubusercontent.com/taxonomicallyinformedannotation/tima-r/main/R/create_dir.R")
source(file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/format_gt.R")
source(file = "https://raw.githubusercontent.com/taxonomicallyinformedannotation/tima-r/main/R/get_default_paths.R")
source(file = "https://raw.githubusercontent.com/taxonomicallyinformedannotation/tima-r/main/R/get_file.R")
source(file = "https://raw.githubusercontent.com/taxonomicallyinformedannotation/tima-r/main/R/get_last_version_from_zenodo.R")
source(file = "https://raw.githubusercontent.com/taxonomicallyinformedannotation/tima-r/main/R/log_debug.R")
source(file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/molinfo.R")
source(file = "https://raw.githubusercontent.com/taxonomicallyinformedannotation/tima-r/main/R/parse_yaml_params.R")
source(file = "R/prettyTables_progress.R")
source(file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/queries_progress.R")
source(file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/save_prettySubtables_progress.R")
source(file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/save_prettyTables_progress.R")
source(file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/subtables_progress.R")
source(file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/tables_progress.R")
source(file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/wiki_progress.R")

progressr::handlers(global = TRUE)
progressr::handlers("progress")

paths <-
  get_default_paths(yaml = "https://raw.githubusercontent.com/Adafede/cascade/main/paths.yaml")
params <-
  parse_yaml_params(def = "params.yaml", usr = "params.yaml")

get_last_version_from_zenodo(
  doi = paths$url$lotus$doi,
  pattern = paths$urls$lotus$pattern,
  path = paths$data$source$libraries$lotus
)

exports <-
  list(paths$data$path, paths$data$tables$path)

qids <- params$organisms$wikidata |> as.list()

genera <-
  names(qids)[!grepl(
    pattern = " ",
    x = names(qids),
    fixed = TRUE
  )]

message("Loading LOTUS classified structures")
structures_classified <- readr::read_delim(
  file = paths$data$source$libraries$lotus,
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
  dplyr::distinct()

query_part_1 <- readr::read_file(paths$inst$scripts$sparql$review_1)
query_part_2 <- readr::read_file(paths$inst$scripts$sparql$review_2)
query_part_3 <- readr::read_file(paths$inst$scripts$sparql$review_3)
query_part_4 <- readr::read_file(paths$inst$scripts$sparql$review_4)

message("Building queries")
queries <- queries_progress(xs = qids)

message("Querying Wikidata")
results <- wiki_progress(xs = queries)

message("Cleaning tables and adding columns")
tables <- tables_progress(results)

message("Re-ordering")
tables <- tables |>
  lapply(function(x) {
    x |>
      dplyr::relocate(structure_smiles_no_stereo, .after = structureImage) |>
      dplyr::relocate(structure_exact_mass, .after = structure_smiles_no_stereo) |>
      dplyr::relocate(structure_xlogp, .after = structure_exact_mass) |>
      dplyr::relocate(chemical_superclass, .before = structureLabel) |>
      dplyr::relocate(chemical_class, .after = chemical_superclass) |>
      dplyr::mutate(structureImage = molinfo(structureImage))
  })

# message("Generating subtables based on chemical classification")
# subtables <- subtables_progress(tables)

message("Generating pretty tables")
prettyTables <- prettyTables_progress(tables) |>
  lapply(function(x) {
    x |>
      opt_interactive(use_filters = TRUE)
  })

# message("Generating pretty subtables")
# prettySubtables <- prettyTables_progress(subtables)

message("Exporting html tables")
gt::gtsave(data = prettyTables[[1]], filename = "output/index.html")

end <- Sys.time()

message("Script finished in ", format(end - start))
