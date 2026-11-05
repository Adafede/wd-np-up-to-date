start <- Sys.time()

source(
  file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/cascade-package.R"
)
source(
  file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/load.R"
)
source(
  file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/annotations.R"
)
source(
  file = "https://raw.githubusercontent.com/Adafede/cascade/main/R/query_wikidata.R"
)
source(file = "R/prettyTables_progress.R")

lotus_path <- "data/source/libraries/lotus.csv.gz"
message("Getting last LOTUS version")
get_zenodo_file(
  doi = "10.5281/zenodo.5794106",
  pattern = "frozen_metadata.csv.gz",
  path = lotus_path
)

qids <- list(c("Swertia" = "Q163970"))

message("Loading LOTUS classified structures")
structures_classified <- fread_gz(
  file = lotus_path,
  select = c(
    "structure_inchikey",
    "structure_smiles_2D",
    "structure_exact_mass",
    "structure_xlogp",
    "structure_taxonomy_npclassifier_01pathway",
    "structure_taxonomy_npclassifier_02superclass",
    "structure_taxonomy_npclassifier_03class"
  )
)
data.table::setnames(
  structures_classified,
  old = c(
    "structure_inchikey",
    "structure_smiles_2D",
    "structure_taxonomy_npclassifier_01pathway",
    "structure_taxonomy_npclassifier_02superclass",
    "structure_taxonomy_npclassifier_03class"
  ),
  new = c(
    "structure_id",
    "structure_smiles_no_stereo",
    "chemical_pathway",
    "chemical_superclass",
    "chemical_class"
  )
)
structures_classified <- unique(structures_classified)

message("Building queries")
queries <- queries_progress(xs = qids)

message("Querying Wikidata")
results <- wiki_progress(xs = queries)

message("Cleaning tables and adding columns")
tables <- lapply(
  tables_progress(
    results,
    structures_classified = structures_classified
  ),
  unique,
  by = c("structure", "taxa", "references")
)

message("Re-ordering")
col_order <- c(
  "chemical_pathway",
  "chemical_superclass",
  "chemical_class",
  "structureLabel",
  "structure",
  "structureImage",
  "structure_smiles_no_stereo",
  "structure_exact_mass",
  "structure_xlogp"
)
tables <- lapply(
  tables,
  function(x) {
    first_cols <- intersect(col_order, names(x))
    data.table::setcolorder(x, c(first_cols, setdiff(names(x), first_cols)))
    data.table::set(x, j = "structureImage", value = molinfo(x$structureImage))
    x
  }
)

message("Generating pretty tables")
prettyTables <- lapply(
  prettyTables_progress(tables, qids = qids),
  gt::opt_interactive,
  use_filters = TRUE
)

message("Exporting html tables")
check_export_dir("output")
gt::gtsave(data = prettyTables[[1]], filename = "output/index.html")

end <- Sys.time()

message("Script finished in ", format(end - start))
