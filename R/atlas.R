# The prepared object is deliberately independent of its browser presentation.
scalar_text <- function(x, what, empty = FALSE) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || (!empty && !nzchar(x)))
    stop(what, " must be one text value", call. = FALSE)
  x
}

check_atlas <- function(x) {
  if (!inherits(x, "offline_atlas")) stop("Expected an atlas object", call. = FALSE)
}

column <- function(data, name) {
  if (!is.data.frame(data)) stop("Input must be a data frame", call. = FALSE)
  scalar_text(name, "Column name")
  if (!name %in% names(data)) stop("Missing column: ", name, call. = FALSE)
  data[[name]]
}

identifiers <- function(x, what) {
  x <- as.character(x)
  if (anyNA(x) || any(!nzchar(trimws(x))) || any(grepl("[[:cntrl:]]", x)))
    stop(what, " must be nonempty identifiers without control characters", call. = FALSE)
  x
}

numbers <- function(x, what, missing = FALSE) {
  if (!is.numeric(x) || any(is.infinite(x)) || any(is.nan(x)) || (!missing && anyNA(x)))
    stop(what, " must contain finite numbers", if (missing) " or NA", call. = FALSE)
  as.numeric(x)
}

atlas <- function(title = "Offline atlas", description = "", notice = "",
                  sources = character(), units = "",
                  entity_name = "entity", entity_names = "entities") {
  scalar_text(title, "title")
  for (v in list(description, notice, units)) scalar_text(v, "Text", empty = TRUE)
  if (!is.character(sources) || anyNA(sources)) stop("sources must be text", call. = FALSE)
  scalar_text(entity_name, "entity_name")
  scalar_text(entity_names, "entity_names")
  structure(list(schema_version = "0.1", package_version = "0.0.8",
    title = title, description = description, notice = notice, sources = unname(as.list(sources)),
    units = units, entity_name = entity_name, entity_names = entity_names,
    coordinates = NULL, nodes = NULL, edges = NULL, areas = NULL, spatial = list(),
    variables = NULL, area_frames = NULL, view = NULL, background = NULL, inset = NULL, weighted = FALSE, directed = FALSE, signed = FALSE,
    coverage = NULL, controls = list(initial_source = NULL, initial_time = NULL,
      drag = TRUE)), class = "offline_atlas")
}

add_nodes <- function(x, data, id, label = id, longitude = NULL, latitude = NULL,
                      layout_x = NULL, layout_y = NULL,
                      coordinates = c("geographic", "schematic")) {
  check_atlas(x)
  if (!is.null(x$nodes)) stop("Nodes have already been added", call. = FALSE)
  coordinates <- match.arg(coordinates)
  if (inherits(data, "sf") && (coordinates != "geographic" || !is.null(longitude) || !is.null(latitude)))
    stop("sf nodes use POINT geometry directly; omit longitude/latitude and use geographic coordinates", call. = FALSE)
  ids <- identifiers(column(data, id), "Node IDs")
  labels <- identifiers(column(data, label), "Node labels")
  if (!length(ids) || anyDuplicated(ids)) stop("Node IDs must be unique and nonempty", call. = FALSE)
  if (coordinates == "geographic") {
    if (inherits(data, "sf")) {
      prepared <- sf_node_coordinates(data, ids)
      a <- prepared$coordinates[, 1]; b <- prepared$coordinates[, 2]
      x$spatial$nodes <- prepared$metadata
    } else {
      a <- numbers(column(data, longitude), "Longitude")
      b <- numbers(column(data, latitude), "Latitude")
    }
    if (any(abs(a) > 180 | b < -60 | b > 85))
      stop("Prototype geography requires longitude [-180,180], latitude [-60,85]", call. = FALSE)
    px <- 30 + (a + 180) / 360 * 940
    py <- 92 + (85 - b) / 145 * 380
  } else {
    if (!is.null(x$areas)) stop("Geographic areas cannot use schematic coordinates", call. = FALSE)
    a <- numbers(column(data, layout_x), "Layout x")
    b <- numbers(column(data, layout_y), "Layout y")
    if (any(a < 30 | a > 970 | b < 30 | b > 600))
      stop("Schematic coordinates must fit x [30,970], y [30,600]", call. = FALSE)
    px <- a; py <- b
  }
  x$nodes <- data.frame(id = ids, label = labels, x = px, y = py,
    longitude = if (coordinates == "geographic") a else NA_real_,
    latitude = if (coordinates == "geographic") b else NA_real_, stringsAsFactors = FALSE)
  x$coordinates <- coordinates
  x
}

add_edges <- function(x, data, from, to, weight = NULL, time = NULL,
                      layer = NULL, directed = FALSE,
                      coverage = c("edge_list", "observed_rows", "complete_panel"),
                      signed = FALSE, provenance = NULL) {
  check_atlas(x)
  if (is.null(x$nodes)) stop("Add nodes before edges", call. = FALSE)
  if (!is.null(x$edges)) stop("Edges have already been added", call. = FALSE)
  coverage <- match.arg(coverage)
  if (!is.logical(directed) || length(directed) != 1L || is.na(directed))
    stop("directed must be TRUE or FALSE", call. = FALSE)
  a <- identifiers(column(data, from), "Source IDs")
  b <- identifiers(column(data, to), "Target IDs")
  if (!length(a)) stop("Provide at least one relationship row", call. = FALSE)
  if (any(!c(a, b) %in% x$nodes$id)) stop("Unmatched edge endpoint", call. = FALSE)
  if (any(a == b)) stop("Self-links are not supported in this prototype", call. = FALSE)
  w <- if (is.null(weight)) rep(1, length(a)) else numbers(column(data, weight), "Weights", TRUE)
  if (!is.logical(signed) || length(signed) != 1L || is.na(signed))
    stop("signed must be TRUE or FALSE", call. = FALSE)
  if (any(w < 0, na.rm = TRUE) && !signed)
    stop("Signed weights require signed = TRUE", call. = FALSE)
  if (!is.null(weight) && coverage == "edge_list")
    stop("Weighted data require observed_rows or complete_panel coverage", call. = FALSE)
  t <- if (is.null(time)) rep(NA_character_, length(a)) else identifiers(column(data, time), "Times")
  l <- if (is.null(layer)) rep("Relationships", length(a)) else identifiers(column(data, layer), "Layers")
  key <- data.frame(from = if (directed) a else pmin(a, b),
    to = if (directed) b else pmax(a, b), time = t, layer = l)
  if (anyDuplicated(key)) stop("Duplicate endpoint/layer/time relationship", call. = FALSE)
  if (coverage == "complete_panel") {
    if (!directed || is.null(time)) stop("complete_panel requires directed edges and time", call. = FALSE)
    expected <- expand.grid(from = unique(a), to = unique(b), time = unique(t), layer = unique(l),
      stringsAsFactors = FALSE)
    expected <- expected[expected$from != expected$to, , drop = FALSE]
    if (nrow(key) != nrow(expected))
      stop("Incomplete panel: supply every source-target-time-layer row; use NA for unavailable values", call. = FALSE)
  }
  x$edges <- data.frame(from = a, to = b, weight = w, time = t, layer = l,
    status = ifelse(is.na(w), "unavailable", ifelse(w == 0, "zero", "observed")), stringsAsFactors = FALSE)
  if (!is.null(provenance)) x$edges$provenance <- identifiers(column(data, provenance), "Provenance")
  x$weighted <- !is.null(weight); x$directed <- directed; x$coverage <- coverage; x$signed <- signed
  x
}

add_areas <- function(x, data, id = "id", path = "path", label = id,
                      values = character(), labels = values, breaks = NULL,
                      matched = NULL, colors = NULL, categories = NULL,
                      time = NULL, notes = NULL) {
  check_atlas(x)
  if (!is.null(x$areas)) stop("Areas have already been added", call. = FALSE)
  if (identical(x$coordinates, "schematic")) stop("Areas require geographic coordinates", call. = FALSE)
  ids <- identifiers(column(data, id), "Area IDs")
  times <- if (is.null(time)) NULL else identifiers(column(data, time), "Area times")
  if (!length(ids) || (is.null(times) && anyDuplicated(ids))) stop("Area IDs must be unique and nonempty", call. = FALSE)
  if (!is.null(times) && anyDuplicated(data.frame(id = ids, time = times)))
    stop("Duplicate area ID/time observation", call. = FALSE)
  if (inherits(data, "sf")) {
    prepared <- sf_area_paths(data, ids)
    paths <- prepared$paths
    x$spatial$areas <- prepared$metadata
  } else paths <- as.character(column(data, path))
  if (anyNA(paths) || any(!grepl("^[MmLlHhVvCcSsQqTtAaZz0-9eE., +\\-]+$", paths)))
    stop("Areas require SVG path data in the documented world projection", call. = FALSE)
  if (!is.character(values) || anyDuplicated(values) || length(values) != length(labels) || anyNA(labels))
    stop("Provide distinct variable column names and one label each", call. = FALSE)
  if (is.null(categories)) categories <- rep(list(NULL), length(values))
  if (!is.list(categories) || length(categories) != length(values))
    stop("categories must be a list with one entry per variable", call. = FALSE)
  if (is.null(breaks) && all(!vapply(categories, is.null, logical(1)))) breaks <- rep(list(NULL), length(values))
  if (length(values) && (is.null(breaks) || length(breaks) != length(values)))
    stop("Provide fixed numeric breaks for each area variable", call. = FALSE)
  if (!is.null(colors) && (!is.list(colors) || length(colors) != length(values)))
    stop("colors must be a list with one palette per variable", call. = FALSE)
  areas <- data.frame(id = ids, label = identifiers(column(data, label), "Area labels"), path = paths)
  if (!is.null(notes)) {
    areas$notes <- column(data, notes)
    if (!is.character(areas$notes) || anyNA(areas$notes)) stop("notes must be text with no missing values", call. = FALSE)
  }
  areas$matched <- if (is.null(matched)) rep(TRUE, length(ids)) else column(data, matched)
  if (!is.logical(areas$matched) || anyNA(areas$matched))
    stop("matched must identify a logical column with no missing values", call. = FALSE)
  vars <- list()
  for (i in seq_along(values)) {
    levels <- categories[[i]]
    categorical <- !is.null(levels)
    if (categorical) {
      if (!is.character(levels) || !length(levels) || anyNA(levels) || anyDuplicated(levels) || any(!nzchar(levels)))
        stop("Category levels must be distinct nonempty text", call. = FALSE)
      v <- column(data, values[i])
      if (!is.character(v) && !is.factor(v)) stop("Categorical values must be text or factors", call. = FALSE)
      v <- as.character(v)
      if (any(!is.na(v) & !v %in% levels)) stop("Unknown category in ", values[i], call. = FALSE)
    } else v <- numbers(column(data, values[i]), values[i], TRUE)
    if (any(!areas$matched & !is.na(v)))
      stop("Unmatched areas must have NA values", call. = FALSE)
    bs <- if (categorical) numeric() else numbers(breaks[[i]], "Breaks")
    if (!categorical && (length(bs) < 1 || length(bs) > 5 || is.unsorted(bs, strictly = TRUE)))
      stop("Use 1 to 5 strictly increasing breaks", call. = FALSE)
    if (categorical && !is.null(breaks[[i]])) stop("Categorical variables do not use numeric breaks", call. = FALSE)
    key <- paste0("value_", i)
    areas[[key]] <- v
    vars[[i]] <- list(key = key, source_column = values[i], label = labels[i], breaks = as.list(bs),
      type = if (categorical) "categorical" else "numeric", categories = if (categorical) as.list(levels) else NULL)
    if (categorical && is.null(colors)) stop("Supply an explicit color palette for categorical variables", call. = FALSE)
    if (!is.null(colors)) {
      palette <- colors[[i]]
      if (!is.character(palette) || anyNA(palette) || length(palette) != (if (categorical) length(levels) else length(bs) + 1L) ||
          any(!grepl("^#[0-9a-fA-F]{6}$", palette)))
        stop("Each palette needs one six-digit hex color per interval", call. = FALSE)
      vars[[i]]$colors <- as.list(palette)
    }
  }
  if (!is.null(times)) {
    first <- !duplicated(ids)
    reference <- areas[first, c("id", "label", "path")]
    groups <- split(seq_along(times), times)
    x$area_frames <- lapply(names(groups), function(t) {
      rows <- areas[groups[[t]], , drop = FALSE]
      if (!setequal(rows$id, reference$id)) stop("Area time series requires every ID in every period; supply NA values explicitly", call. = FALSE)
      rows <- rows[match(reference$id, rows$id), , drop = FALSE]
      if (!identical(rows$path, reference$path) || !identical(rows$label, reference$label))
        stop("Area time series requires fixed geometry and labels across periods", call. = FALSE)
      list(time = t, data = rows[, setdiff(names(rows), c("label", "path")), drop = FALSE])
    })
    areas <- areas[first, , drop = FALSE]
    if (!is.null(x$spatial$areas)) {
      x$spatial$areas$features <- nrow(areas)
      x$spatial$areas$periods <- length(x$area_frames)
    }
  }
  x$areas <- areas; x$variables <- vars; x$coordinates <- "geographic"
  if (inherits(data, "sf")) attr(x, "area_geometry") <- list(
    ids = ids[!duplicated(ids)], geometry = prepared$geometry[!duplicated(ids)])
  x
}

set_view <- function(x, bounds = NULL, title = "Regional view", padding = 0.05) {
  check_atlas(x)
  if (!identical(x$coordinates, "geographic")) stop("A regional view requires geographic data", call. = FALSE)
  if (is.null(bounds)) bounds <- auto_view_bounds(x, padding)
  bounds <- numbers(bounds, "View bounds")
  if (length(bounds) != 4L || bounds[1] >= bounds[3] || bounds[2] >= bounds[4] ||
      any(abs(bounds[c(1,3)]) > 180) || bounds[2] < -60 || bounds[4] > 85)
    stop("View bounds must be west, south, east, north within the supported world extent", call. = FALSE)
  scalar_text(title, "View title")
  x$view <- list(west = bounds[1], south = bounds[2], east = bounds[3], north = bounds[4], title = title)
  x
}

set_inset <- function(x, bounds, title = "Regional detail", visible = TRUE) {
  check_atlas(x)
  if (!identical(x$coordinates, "geographic"))
    stop("Add geographic nodes or areas before configuring an inset", call. = FALSE)
  bounds <- numbers(bounds, "Inset bounds")
  if (length(bounds) != 4L || bounds[1] >= bounds[3] || bounds[2] >= bounds[4] ||
      any(abs(bounds[c(1, 3)]) > 180) || bounds[2] < -60 || bounds[4] > 85)
    stop("Inset bounds must be west, south, east, north within the world projection, without crossing the dateline", call. = FALSE)
  scalar_text(title, "Inset title")
  if (!is.logical(visible) || length(visible) != 1L || is.na(visible))
    stop("visible must be TRUE or FALSE", call. = FALSE)
  x$inset <- list(title = title, west = bounds[1], south = bounds[2],
    east = bounds[3], north = bounds[4], visible = visible)
  x
}

set_background <- function(x, file) {
  check_atlas(x)
  if (!identical(x$coordinates, "schematic")) stop("Illustrations require schematic coordinates", call. = FALSE)
  raw <- paste(readLines(file, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  if (grepl("<!DOCTYPE|<!ENTITY", raw, ignore.case = TRUE)) stop("SVG declarations are not allowed", call. = FALSE)
  doc <- xml2::read_xml(raw, options = "NONET")
  if (length(xml2::xml_find_all(doc, "//processing-instruction()"))) stop("SVG processing instructions are not allowed", call. = FALSE)
  elements <- xml2::xml_find_all(doc, "//*")
  tags <- xml2::xml_name(elements)
  allowed <- c("svg", "g", "defs", "path", "rect", "circle", "ellipse", "line", "polyline", "polygon", "use", "text", "tspan", "title", "desc")
  if (any(!tags %in% allowed)) stop("Background contains unsupported SVG elements", call. = FALSE)
  if (xml2::xml_name(doc) != "svg" || !identical(xml2::xml_attr(doc, "viewBox"), "0 0 1000 650"))
    stop("Background must be SVG with viewBox 0 0 1000 650", call. = FALSE)
  for (node in elements) {
    attrs <- xml2::xml_attrs(node)
    attrs <- attrs[!grepl("^xmlns", names(attrs))]
    if (any(grepl("^on|^style$|(^|:)base$", names(attrs), ignore.case = TRUE)) ||
        any(grepl("url\\s*\\(|javascript:|data:|https?:|file:|^//", attrs, ignore.case = TRUE)))
      stop("Background contains active or external content", call. = FALSE)
    href <- attrs[grepl("href$", names(attrs))]
    if (length(href) && any(!grepl("^#[A-Za-z][A-Za-z0-9_-]*$", href)))
      stop("SVG references must be local fragments", call. = FALSE)
  }
  x$background <- paste(vapply(xml2::xml_children(doc), as.character, character(1)), collapse = "\n")
  x
}

set_controls <- function(x, initial_source = NULL, initial_time = NULL, drag = TRUE,
                         visible = NULL, position = c("top", "above_map", "sidebar"),
                         labels = NULL, playback_interval = 1400) {
  check_atlas(x)
  if (!is.null(initial_source)) scalar_text(initial_source, "initial_source")
  if (!is.null(initial_time)) initial_time <- scalar_text(as.character(initial_time), "initial_time")
  if (!is.logical(drag) || length(drag) != 1 || is.na(drag)) stop("drag must be TRUE or FALSE", call. = FALSE)
  position <- match.arg(position)
  named_options(visible, c("time", "playback", "source", "variable", "layers", "size",
    "background", "inset", "reset", "zoom", "search", "selection", "downloads", "history"), "visible", logical = TRUE)
  named_options(labels, c("time", "source", "variable", "layers", "size", "background",
    "inset", "previous", "play", "pause", "next", "reset", "zoom_in", "zoom_out",
    "fit", "search", "selection", "clear_focus", "select_all", "select_none",
    "export_svg", "export_png", "export_csv", "export_json", "history_csv"), "labels")
  if (!is.numeric(playback_interval) || length(playback_interval) != 1L ||
      is.na(playback_interval) || !is.finite(playback_interval) ||
      playback_interval < 200 || playback_interval > 60000)
    stop("playback_interval must be 200 to 60000 milliseconds", call. = FALSE)
  x$controls <- list(initial_source = initial_source, initial_time = initial_time, drag = drag,
    visible = as.list(visible), position = position, labels = as.list(labels),
    playback_interval = playback_interval)
  x
}

# Accept only documented keys and plain text, never CSS or executable markup.
named_options <- function(value, keys, what, logical = FALSE) {
  if (is.null(value)) return(invisible(NULL))
  valid_type <- if (logical) is.logical(value) else is.character(value)
  if (!valid_type || !length(value) || is.null(names(value)) || anyNA(value) ||
      anyNA(names(value)) || anyDuplicated(names(value)) || any(!names(value) %in% keys) ||
      (!logical && any(!nzchar(value))))
    stop(what, " must be a named ", if (logical) "logical" else "character",
      " vector using documented keys", call. = FALSE)
  invisible(NULL)
}

set_legend <- function(x, title = "Reading this view", position = c("below", "above", "sidebar"),
                       columns = NULL, visible = TRUE, show_counts = TRUE,
                       note = NULL, labels = NULL, missing_label = "Unavailable or unmatched") {
  check_atlas(x)
  scalar_text(title, "Legend title");scalar_text(missing_label, "missing_label")
  position <- match.arg(position)
  if (!is.null(columns) && (!is.numeric(columns) || length(columns) != 1L ||
      is.na(columns) || !columns %in% 1:4)) stop("columns must be NULL or an integer from 1 to 4", call. = FALSE)
  for (value in list(visible, show_counts))
    if (!is.logical(value) || length(value) != 1L || is.na(value)) stop("Legend flags must be TRUE or FALSE", call. = FALSE)
  if (!is.null(note)) scalar_text(note, "Legend note", empty = TRUE)
  if (!is.null(labels)) {
    if (!is.list(labels) || !length(labels) || is.null(names(labels)) ||
        anyNA(names(labels)) || any(!nzchar(names(labels))) || anyDuplicated(names(labels)))
      stop("Legend labels must be a named list keyed by area variable column", call. = FALSE)
    for (value in labels) if (!is.character(value) || !length(value) || anyNA(value) || any(!nzchar(value)))
      stop("Legend labels must contain nonempty character vectors", call. = FALSE)
    labels <- lapply(labels, function(value) unname(as.list(value)))
  }
  x$legend <- list(title = title, position = position, columns = columns, visible = visible,
    show_counts = show_counts, note = note, labels = labels, missing_label = missing_label)
  x
}

set_style <- function(x, font_family = c("system", "sans", "serif", "mono"),
                      heading_family = c("serif", "system", "sans", "mono")) {
  check_atlas(x)
  x$style <- list(font_family = match.arg(font_family), heading_family = match.arg(heading_family))
  x
}

example_file <- function(name) {
  scalar_text(name, "name")
  if (basename(name) != name) stop("Use an example filename, not a path", call. = FALSE)
  file <- system.file("extdata", name, package = "offlineatlas", mustWork = TRUE)
  file
}

example_data <- function(name) {
  scalar_text(name, "name")
  utils::read.csv(example_file(paste0(name, ".csv")), stringsAsFactors = FALSE,
    check.names = FALSE, na.strings = "NA", fileEncoding = "UTF-8")
}

print.offline_atlas <- function(x, ...) {
  cat(x$title, "\n", NROW(x$nodes), "nodes,", NROW(x$edges), "relationships,",
    NROW(x$areas), "areas\nUse export_html() to create a standalone file.\n")
  invisible(x)
}
