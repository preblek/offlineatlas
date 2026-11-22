library(offlineatlas)

fails <- function(expr, pattern) {
  error <- tryCatch({ force(expr); NULL }, error = identity)
  stopifnot(inherits(error, "error"), grepl(pattern, conditionMessage(error)))
}
nodes <- data.frame(id = c("a", "b", "c"),
  label = c("Caf\u00e9 \u6771\u4eac", "</script><script>alert(1)</script>", "Literal \\n and &"),
  x = c(100, 450, 800), y = c(200, 300, 200))
edges <- data.frame(from = c("a", "b", "c"), to = c("b", "c", "a"),
  value = c(-5.12345678901234, 0, NA_real_), year = c(2023, 2024, 2024))
x <- atlas("Compression integrity") |>
  add_nodes(nodes, "id", "label", layout_x = "x", layout_y = "y", coordinates = "schematic") |>
  add_edges(edges, "from", "to", weight = "value", time = "year",
    coverage = "observed_rows", directed = TRUE, signed = TRUE)
folder <- tempfile("compression-")
dir.create(folder)
plain <- file.path(folder, "plain.html")
explicit <- file.path(folder, "explicit.html")
packed <- file.path(folder, "packed.html")
export_html(x, plain)
export_html(x, explicit, compress = FALSE)
export_html(x, packed, compress = TRUE)
bytes <- function(path) readBin(path, "raw", n = file.info(path)$size)
stopifnot(identical(bytes(plain), bytes(explicit)))
payload <- function(path) {
  doc <- xml2::read_html(path)
  node <- xml2::xml_find_first(doc, "//*[@id='atlas-data']")
  list(node = node, text = xml2::xml_text(node), doc = doc)
}
original <- payload(plain)
compressed <- payload(packed)
stopifnot(xml2::xml_attr(compressed$node, "data-encoding") == "gzip")
gzip <- jsonlite::base64_dec(compressed$text)
# Reject the zlib stream that memCompress(type = "gzip") would produce.
stopifnot(identical(as.integer(gzip[1:3]), c(31L, 139L, 8L)))
restored <- memDecompress(gzip, type = "gzip")
stopifnot(identical(restored, charToRaw(enc2utf8(original$text))))
data <- jsonlite::fromJSON(rawToChar(restored))
stopifnot(identical(data$nodes$label, nodes$label),
  identical(data$edges$weight, edges$value),
  !grepl("</script>", original$text, fixed = TRUE))
# Both formats keep the same policy forbidding network connections.
csp <- function(doc) xml2::xml_attr(xml2::xml_find_first(doc,
  "//meta[@http-equiv='Content-Security-Policy']"), "content")
stopifnot(identical(csp(original$doc), csp(compressed$doc)),
  grepl("connect-src 'none'", csp(compressed$doc), fixed = TRUE))
before <- bytes(packed)
fails(export_html(x, packed, compress = TRUE), "File exists")
stopifnot(identical(before, bytes(packed)))
for (bad in list(NA, NULL, 1, "gzip", c(TRUE, FALSE))) {
  fails(export_html(x, packed, overwrite = TRUE, compress = bad), "compress must")
  stopifnot(identical(before, bytes(packed)))
}
export_html(x, packed, overwrite = TRUE, compress = TRUE)
stopifnot(identical(before, bytes(packed)))
unlink(folder, recursive = TRUE)
