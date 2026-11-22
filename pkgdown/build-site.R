# Run from the package root with Rscript pkgdown/build-site.R.
# This builds from the current source, never from an older installed release.
stopifnot(file.exists("DESCRIPTION"), dir.exists("inst/examples"))
root <- normalizePath(".")
expected_version <- unname(read.dcf("DESCRIPTION")[1, "Version"])
work <- tempfile("offlineatlas-website-")
dir.create(work)
lib <- file.path(work, "library")
dir.create(lib)
.libPaths(c(lib, .libPaths()))
# R CMD INSTALL and pkgdown's child processes inherit these library paths.
Sys.setenv(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep))
status <- system2(file.path(R.home("bin"), "R"),
  c("CMD", "INSTALL", "--no-docs", "--no-help", "--no-demo",
    paste0("--library=", shQuote(lib)), shQuote(root)))
if (status != 0L) stop("Could not install the current package for the website.")
library(offlineatlas)
library(ggplot2)
if (!identical(as.character(utils::packageVersion("offlineatlas")), expected_version))
  stop("Website must use the package version in the current source.")

out <- file.path(work, "examples")
dir.create(out)
setwd(out)
run_example <- function(name) {
  env <- new.env(parent = globalenv())
  sys.source(system.file("examples", paste0(name, ".R"), package = "offlineatlas"), env)
  env
}
# Discover every bundled script so new examples cannot be missed by this build.
# Each run uses a fresh directory and only bundled data, with no data downloads.
example_names <- sub("\\.R$", "", list.files(system.file("examples", package = "offlineatlas"),
  pattern = "\\.R$"))
examples <- setNames(lapply(example_names, run_example), example_names)
bilateral <- examples$fdi_bilateral
regional <- examples$regional

ggsave("static/regional.png", as_ggplot(set_preset(regional$regional, "compact")),
  width = 7, height = 6, dpi = 150, bg = "white")
ggsave("static/bilateral.png",
  as_ggplot(set_preset(set_inset(bilateral$fdi, c(-15, 34, 35, 62), visible = FALSE), "compact"), time = 2024) +
    labs(title = "Bilateral FDI in 2024", caption = paste(
      "Nine-country teaching sample, USD millions. Negative flows retain their direction.",
      "Source: UNCTAD (CC BY 3.0 IGO); Natural Earth (public domain). No UN endorsement.", sep = "\n")),
  width = 9, height = 6, dpi = 150, bg = "white")
setwd(root)

# Initialise first so pkgdown recognises docs/ and images exist during rendering.
pkgdown::init_site()
dest <- file.path(root, "docs")
dir.create(file.path(dest, "demos"), showWarnings = FALSE)
dir.create(file.path(dest, "images"), showWarnings = FALSE)
dir.create(file.path(dest, "examples"), showWarnings = FALSE)
copy_checked <- function(from, to) {
  if (!all(file.copy(from, to, overwrite = TRUE))) stop("Failed to copy website assets.")
}
copy_checked(list.files(out, pattern = "\\.html$", full.names = TRUE), file.path(dest, "demos"))
copy_checked(list.files(file.path(out, "static"), pattern = "\\.(png|pdf|svg)$", full.names = TRUE), file.path(dest, "images"))
copy_checked(list.files(file.path(root, "inst/examples"), pattern = "\\.R$", full.names = TRUE), file.path(dest, "examples"))
# Record every freshly generated asset, including static figures that have no
# visible version badge. The checker rejects missing or mismatched assets.
asset_paths <- c(file.path("demos", list.files(out, pattern = "\\.html$")),
  file.path("images", list.files(file.path(out, "static"), pattern = "\\.(png|pdf|svg)$")),
  file.path("examples", paste0(example_names, ".R")))
manifest <- list(package_version = expected_version, scripts = example_names,
  files = data.frame(path = asset_paths,
    md5 = unname(tools::md5sum(file.path(dest, asset_paths)))))
jsonlite::write_json(manifest, file.path(dest, "example-build.json"),
  auto_unbox = TRUE, pretty = TRUE, dataframe = "rows")
pkgdown::build_site(preview = FALSE, install = FALSE, new_process = FALSE)
file.create(file.path(dest, ".nojekyll"))
source(file.path(root, "pkgdown/check-site.R"), local = TRUE)
check_site(dest, expected_version, example_names)
message("Website ready in ", dest)
message("Preview with python3 -m http.server 8000 --directory docs")
