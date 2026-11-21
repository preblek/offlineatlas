# Run from the package root with Rscript pkgdown/build-site.R.
# This builds from the current source, never from an older installed release.
stopifnot(file.exists("DESCRIPTION"), dir.exists("inst/examples"))
root <- normalizePath(".")
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

out <- file.path(work, "examples")
dir.create(out)
setwd(out)
run_example <- function(name) {
  env <- new.env(parent = globalenv())
  sys.source(system.file("examples", paste0(name, ".R"), package = "offlineatlas"), env)
  env
}
# These scripts use only data bundled in the package. No data downloads occur.
static <- run_example("static")
networks <- run_example("static_networks")
florence <- run_example("florence")
bilateral <- run_example("fdi_bilateral")
regional <- run_example("regional")

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
pkgdown::build_site(preview = FALSE, install = FALSE, new_process = FALSE)
file.create(file.path(dest, ".nojekyll"))
source(file.path(root, "pkgdown/check-site.R"), local = TRUE)
check_site(dest)
message("Website ready in ", dest)
message("Preview with python3 -m http.server 8000 --directory docs")
