library(offlineatlas)

version <- as.character(utils::packageVersion("offlineatlas"))
x <- atlas("Version reporting") |>
  add_nodes(data.frame(id = c("a", "b")), "id", coordinates = "schematic")
stopifnot(identical(x$package_version, version))

# Old saved objects must not stamp an outdated version onto a new viewer.
for (old_version in list(version, "0.0.1", NULL)) {
  x$package_version <- old_version
  original <- x
  for (compress in c(FALSE, TRUE)) {
    file <- tempfile(fileext = ".html")
    export_html(x, file, compress = compress)
    doc <- xml2::read_html(file)
    badge <- xml2::xml_text(xml2::xml_find_first(doc, "//span[@class='badge']"))
    payload <- xml2::xml_text(xml2::xml_find_first(doc, "//script[@id='atlas-data']"))
    if (compress) payload <- rawToChar(memDecompress(jsonlite::base64_dec(payload), "gzip"))
    data <- jsonlite::fromJSON(payload)
    stopifnot(endsWith(badge, paste0(" ", version)),
      identical(data$package_version, version), identical(x, original),
      !grepl("{{PACKAGE_VERSION}}", paste(readLines(file, warn = FALSE), collapse = "\n"), fixed = TRUE))
    unlink(file)
  }
}
