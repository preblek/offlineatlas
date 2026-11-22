# Run by build-site.R, including on GitHub Actions.
check_site <- function(dest, expected_version = as.character(utils::packageVersion("offlineatlas")),
                       expected_scripts = sub("\\.R$", "", list.files(
                         system.file("examples", package = "offlineatlas"), pattern = "\\.R$"))) {
  manifest <- jsonlite::fromJSON(file.path(dest, "example-build.json"))
  if (!identical(manifest$package_version, expected_version))
    stop("Example build version differs from the current package.")
  if (!setequal(manifest$scripts, expected_scripts))
    stop("Example build must run every bundled example script.")
  files <- manifest$files
  if (!nrow(files) || anyDuplicated(files$path) || anyNA(files$md5))
    stop("Invalid example asset manifest.")
  hashes <- unname(tools::md5sum(file.path(dest, files$path)))
  if (anyNA(hashes) || !identical(hashes, files$md5))
    stop("Generated example assets are missing or changed since this build.")
  actual <- unlist(lapply(c("demos", "images", "examples"), function(folder)
    file.path(folder, list.files(file.path(dest, folder), pattern = "\\.(html|png|pdf|svg|R)$"))))
  if (!setequal(actual, files$path))
    stop("Unexpected example assets; remove stale generated files and rebuild.")
  demos <- files$path[startsWith(files$path, "demos/")]
  if (!length(demos)) stop("No generated HTML examples found.")
  for (demo in demos) {
    doc <- xml2::read_html(file.path(dest, demo), options = c("RECOVER", "NOERROR", "NOWARNING", "HUGE"))
    node <- xml2::xml_find_first(doc, "//script[@id='atlas-data']")
    payload <- xml2::xml_text(node)
    if (identical(xml2::xml_attr(node, "data-encoding"), "gzip"))
      payload <- rawToChar(memDecompress(jsonlite::base64_dec(payload), "gzip"))
    data <- jsonlite::fromJSON(payload)
    badge <- xml2::xml_text(xml2::xml_find_first(doc, "//span[@class='badge']"))
    if (!identical(data$package_version, expected_version) ||
        is.na(badge) || !endsWith(badge, paste0(" ", expected_version)))
      stop("Example version does not match the package: ", demo)
  }
  site_url <- "https://preblek.github.io/offlineatlas/"
  pages <- list.files(dest, pattern = "\\.html$", recursive = TRUE, full.names = TRUE)
  broken <- character()
  external_assets <- character()
  for (page in pages) {
    doc <- xml2::read_html(page, options = c("RECOVER", "NOERROR", "NOWARNING", "HUGE"))
    links <- xml2::xml_attr(xml2::xml_find_all(doc, "//a[@href]"), "href")
    assets <- c(
      xml2::xml_attr(xml2::xml_find_all(doc, "//script[@src] | //img[@src]"), "src"),
      xml2::xml_attr(xml2::xml_find_all(doc, "//link[@rel='stylesheet']"), "href")
    )
    external <- assets[grepl("^(https?:)?//", assets) & !startsWith(assets, site_url)]
    if (length(external)) external_assets <- c(external_assets, paste(basename(page), external))
    paths <- c(links, assets)
    # pkgdown's 404 page uses absolute, same-site URLs so it works at any depth.
    same_site <- !is.na(paths) & startsWith(paths, site_url)
    same_targets <- file.path(dest, utils::URLdecode(sub("[?#].*$", "", substring(paths[same_site], nchar(site_url) + 1L))))
    if (any(!file.exists(same_targets))) broken <- c(broken, paste(basename(page), paths[same_site][!file.exists(same_targets)], sep = " -> "))
    paths <- paths[!is.na(paths) & !grepl("^(#|[[:alpha:]][[:alnum:]+.-]*:|//)", paths)]
    paths <- unique(utils::URLdecode(sub("[?#].*$", "", paths)))
    paths <- paths[nzchar(paths)]
    targets <- file.path(dirname(page), paths)
    missing <- !file.exists(targets)
    if (any(missing)) broken <- c(broken, paste(basename(page), paths[missing], sep = " -> "))
  }
  if (length(broken)) stop("Broken local website links:\n", paste(broken, collapse = "\n"))
  if (length(external_assets)) stop("Unexpected external website assets:\n", paste(external_assets, collapse = "\n"))
  gallery <- xml2::read_html(file.path(dest, "articles/demo-gallery.html"))
  downloads <- xml2::xml_attr(xml2::xml_find_all(gallery, "//a[@download]"), "href")
  if (length(downloads) != 8L || anyDuplicated(downloads)) stop("Expected eight distinct demo downloads.")
  message("Validated ", length(pages), " HTML pages, local links, local assets, and eight demo downloads.")
  message("Verified ", length(demos), " HTML example versions and ", nrow(files),
    " freshly built assets for offlineatlas ", expected_version, ".")
  invisible(TRUE)
}
