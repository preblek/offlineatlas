# Keep the complete downloadable R scripts in sync with the worked vignettes.
# Run from the package root. purl=FALSE chunks cover optional downloads and
# vignette setup, so installed scripts need only the package's Imports.
for (entry in c("ofac-states", "japan-population")) {
  extracted <- tempfile(fileext = ".R")
  knitr::purl(file.path("vignettes", paste0(entry, ".Rmd")),
    output = extracted, documentation = 1L, quiet = TRUE)
  lines <- readLines(extracted, warn = FALSE)
  # Vignettes use temporary output folders; complete example scripts write
  # into the caller's chosen working directory, like the other bundled demos.
  lines[grepl('^output_dir <- file.path\\(tempdir\\(\\), "offlineatlas-(ofac|japan)"\\)$', lines)] <- 'output_dir <- "."'
  header <- c("# Generated from the worked vignette by pkgdown/sync-tutorial-scripts.R.",
    "# Run in a folder you own. Exports replace previous files with the same names.",
    "# All inputs are bundled with offlineatlas; no data download is needed.", "")
  writeLines(c(header, lines), file.path("inst/examples",
    paste0(gsub("-", "_", entry), ".R")))
  unlink(extracted)
}
