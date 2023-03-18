start <- Sys.time()

source(file = "https://raw.githubusercontent.com/Adafede/cascade/dev/R/check_export_dir.R")
source(file = "https://raw.githubusercontent.com/taxonomicallyinformedannotation/tima-r/main/R/create_dir.R")
source(file = "https://raw.githubusercontent.com/Adafede/cascade/dev/R/format_gt.R")
source(file = "https://raw.githubusercontent.com/taxonomicallyinformedannotation/tima-r/main/R/get_file.R")
source(file = "https://raw.githubusercontent.com/Adafede/cascade/dev/R/load_lotus.R")
source(file = "https://raw.githubusercontent.com/Adafede/cascade/dev/R/molinfo.R")
source(file = "https://raw.githubusercontent.com/taxonomicallyinformedannotation/tima-r/main/R/parse_yaml_params.R")
source(file = "https://raw.githubusercontent.com/taxonomicallyinformedannotation/tima-r/main/R/parse_yaml_paths.R")
source(file = "R/prettyTables_progress.R")
source(file = "https://raw.githubusercontent.com/Adafede/cascade/dev/R/queries_progress.R")
source(file = "https://raw.githubusercontent.com/Adafede/cascade/dev/R/save_prettySubtables_progress.R")
source(file = "https://raw.githubusercontent.com/Adafede/cascade/dev/R/save_prettyTables_progress.R")
source(file = "https://raw.githubusercontent.com/Adafede/cascade/dev/R/subtables_progress.R")
source(file = "https://raw.githubusercontent.com/Adafede/cascade/dev/R/tables_progress.R")
source(file = "https://raw.githubusercontent.com/Adafede/cascade/dev/R/wiki_progress.R")

progressr::handlers(global = TRUE)
progressr::handlers("progress")

paths <-
  parse_yaml_paths(file = "https://raw.githubusercontent.com/Adafede/cascade/dev/paths.yaml")
params <-
  parse_yaml_params(def = "params.yaml", usr = "params.yaml")

load_lotus()

exports <-
  list(
    paths$data$path,
    paths$data$tables$path
  )

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
    "structure_smiles_2D",
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

# message("Generating subtables based on chemical classification")
# subtables <- subtables_progress(tables)

message("Generating pretty tables")
prettyTables <- prettyTables_progress(tables)

# message("Generating pretty subtables")
# prettySubtables <- prettyTables_progress(subtables)

message("Exporting html tables")
gt::gtsave(data = prettyTables[[1]], filename = "output/index.html")

end <- Sys.time()

message("Script finished in ", format(end - start))
