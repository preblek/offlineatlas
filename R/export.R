html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

export_html <- function(x, file, overwrite = FALSE) {
  check_atlas(x)
  scalar_text(file, "file")
  if (is.null(x$nodes) && is.null(x$areas)) stop("Add nodes or areas before export", call. = FALSE)
  if (!is.logical(overwrite) || length(overwrite) != 1 || is.na(overwrite)) stop("overwrite must be TRUE or FALSE", call. = FALSE)
  if (file.exists(file) && !overwrite) stop("File exists; use overwrite = TRUE", call. = FALSE)
  for (key in names(x$legend$labels)) {
    variable <- Filter(function(v) identical(v$source_column, key), x$variables)
    if (length(variable) != 1L) stop("Unknown legend variable: ", key, call. = FALSE)
    v <- variable[[1]]
    count <- if (identical(v$type, "categorical")) length(v$categories) else length(v$breaks) + 1L
    if (length(x$legend$labels[[key]]) != count)
      stop("Legend labels need one entry per interval or category for ", key, call. = FALSE)
  }
  if (!is.null(x$controls$initial_source) &&
      (!x$directed || !x$controls$initial_source %in% x$edges$from))
    stop("initial_source must identify a source in directed edges", call. = FALSE)
  times <- c(x$edges$time, vapply(x$area_frames, function(frame) frame$time, character(1)))
  if (!is.null(x$controls$initial_time) && !x$controls$initial_time %in% times)
    stop("initial_time is not present in the relationships or area periods", call. = FALSE)
  browser_data <- unclass(x)
  attr(browser_data, "area_geometry") <- NULL
  attr(browser_data, "node_attributes") <- NULL
  attr(browser_data, "network_layout") <- NULL
  payload <- jsonlite::toJSON(browser_data, auto_unbox = TRUE, na = "null", null = "null",
    dataframe = "rows", digits = NA)
  # Escape '<' even inside ordinary labels so a closing script tag is inert.
  payload <- gsub("<", "\\u003c", payload, fixed = TRUE)
  read_asset <- function(name) paste(readLines(system.file("runtime", name,
    package = "offlineatlas", mustWork = TRUE), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  # Fixed assembly keeps user data out of template replacement expressions.
  html <- paste0('<!doctype html>\n<html lang="en"><head><meta charset="utf-8">',
    '<meta name="viewport" content="width=device-width,initial-scale=1">',
    '<meta http-equiv="Content-Security-Policy" content="default-src \'none\'; script-src \'unsafe-inline\'; style-src \'unsafe-inline\'; img-src blob: data:; font-src \'none\'; connect-src \'none\'; base-uri \'none\'; form-action \'none\'">',
    '<title>', html_escape(x$title), '</title><style>', read_asset("atlas.css"), '</style></head><body>',
    read_asset("body.html"), '<script id="atlas-data" type="application/json">', payload,
    '</script><script>', read_asset("atlas.js"), '</script></body></html>\n')
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  con <- base::file(file, open = "wb")
  on.exit(close(con))
  writeBin(charToRaw(enc2utf8(html)), con)
  invisible(normalizePath(file, mustWork = TRUE))
}
