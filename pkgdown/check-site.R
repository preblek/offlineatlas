# Run by build-site.R, including on GitHub Actions.
check_site <- function(dest) {
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
  invisible(TRUE)
}
