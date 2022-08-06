start <- Sys.time()

#' Packages
packages_cran <-
  c(
    "devtools",
    "dplyr",
    "future",
    "future.apply",
    "ggplot2",
    "gt",
    "htmltools",
    "plotly",
    "progressr",
    "purrr",
    "RCurl",
    "readr",
    "rotl",
    "splitstackshape",
    "tidyr",
    "WikidataQueryServiceR",
    "yaml"
  )

source(file = "R/check_export_dir.R")
source(file = "R/format_gt.R")
source(file = "R/load_lotus.R")
source(file = "R/molinfo.R")
source(file = "R/parse_yaml_params.R")
source(file = "R/parse_yaml_paths.R")
source(file = "R/prettyTables_progress.R")
source(file = "R/queries_progress.R")
source(file = "R/save_prettySubtables_progress.R")
source(file = "R/save_prettyTables_progress.R")
source(file = "R/subtables_progress.R")
source(file = "R/tables_progress.R")
source(file = "R/wiki_progress.R")

devtools::source_url(
  "https://raw.githubusercontent.com/taxonomicallyinformedannotation/tima-r/main/R/get_lotus.R"
)

progressr::handlers(global = TRUE)
progressr::handlers("progress")

paths <- parse_yaml_paths()
params <- parse_yaml_params()

load_lotus()

exports <-
  list(paths$data$path,
       paths$data$tables$path)

qids <- params$organisms$wikidata |>  as.list()

genera <-
  names(qids)[!grepl(pattern = " ",
                     x = names(qids),
                     fixed = TRUE)]

query_part_1 <- readr::read_file(paths$inst$scripts$sparql$review_1)
query_part_2 <- readr::read_file(paths$inst$scripts$sparql$review_2)
query_part_3 <- readr::read_file(paths$inst$scripts$sparql$review_3)
query_part_4 <- readr::read_file(paths$inst$scripts$sparql$review_4)

message("Loading LOTUS classified structures")
structures_classified <- readr::read_delim(
  file = paths$inst$extdata$source$libraries$lotus,
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

message("Building queries")
queries <- queries_progress(xs =  qids)

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
