# sf is an optional authoring dependency. The browser receives only plain paths
# and coordinates, with no CRS transformation or geometry library at runtime.
sf_geometry <- function(data, ids, types) {
  if (!requireNamespace("sf", quietly = TRUE))
    stop("Install the optional sf package to use sf inputs", call. = FALSE)
  geometry <- sf::st_geometry(data)
  crs <- sf::st_crs(geometry)
  if (is.na(crs)) stop("sf input needs a declared CRS; assign its known source CRS before mapping", call. = FALSE)
  if (!all(as.character(sf::st_geometry_type(geometry)) %in% types))
    stop("Expected sf ", paste(types, collapse = " or "), " geometry; no automatic centroids or type conversion", call. = FALSE)
  if (any(vapply(geometry, function(g) !identical(class(g)[1], "XY"), logical(1))))
    stop("sf inputs must have XY geometry; explicitly remove Z/M dimensions first", call. = FALSE)
  bad <- sf::st_is_empty(geometry)
  if (any(bad)) stop("Empty sf geometry for IDs: ", paste(ids[bad], collapse = ", "), call. = FALSE)
  if (any(!is.finite(sf::st_coordinates(geometry))))
    stop("sf coordinates must be finite", call. = FALSE)
  transformed <- tryCatch(sf::st_transform(geometry, "OGC:CRS84", partial = FALSE,
    allow_ballpark = FALSE), error = function(e)
      stop("Could not transform sf geometry to longitude/latitude: ", conditionMessage(e), call. = FALSE))
  if (any(sf::st_is_empty(transformed)) || any(!is.finite(sf::st_coordinates(transformed))))
    stop("CRS transformation produced empty or non-finite geometry", call. = FALSE)
  list(geometry = transformed, metadata = list(input = "sf", source_crs = crs$input,
    target_crs = "OGC:CRS84", display_projection = "fixed equirectangular",
    features = length(ids)))
}

sf_bounds <- function(geometry, ids) {
  bad <- vapply(geometry, function(g) {
    coords <- sf::st_coordinates(g)
    any(coords[, 1] < -180 - 1e-8 | coords[, 1] > 180 + 1e-8 |
      coords[, 2] < -60 - 1e-8 | coords[, 2] > 85 + 1e-8)
  }, logical(1))
  if (any(bad)) stop("sf geometry outside the supported longitude [-180,180], latitude [-60,85] extent for IDs: ",
    paste(ids[bad], collapse = ", "), ". Subset or clip explicitly before mapping.", call. = FALSE)
}

sf_area_paths <- function(data, ids) {
  prepared <- sf_geometry(data, ids, c("POLYGON", "MULTIPOLYGON"))
  # Split seam-crossing polygons before planar validation and SVG serialization.
  # No global sf_use_s2 setting is changed and invalid shapes are not repaired.
  geometry <- tryCatch(sf::st_wrap_dateline(prepared$geometry,
    options = c("WRAPDATELINE=YES", "DATELINEOFFSET=180"), quiet = TRUE),
    error = function(e) stop("Could not split sf geometry at the dateline: ", conditionMessage(e), call. = FALSE))
  if (any(!as.character(sf::st_geometry_type(geometry)) %in% c("POLYGON", "MULTIPOLYGON")))
    stop("Dateline processing must retain polygon geometry; inspect the supplied shapes", call. = FALSE)
  reasons <- sf::st_is_valid(sf::st_set_crs(geometry, NA), reason = TRUE)
  bad <- is.na(reasons) | reasons != "Valid Geometry" | sf::st_is_empty(geometry)
  if (any(bad)) stop("Invalid sf polygon geometry: ",
    paste(paste0(ids[bad], " (", reasons[bad], ")"), collapse = "; "),
    ". Inspect and repair explicitly with sf::st_make_valid().", call. = FALSE)
  sf_bounds(geometry, ids)
  ring_path <- function(ring) {
    px <- 30 + (ring[, 1] + 180) / 360 * 940
    py <- 92 + (85 - ring[, 2]) / 145 * 380
    xy <- paste0(formatC(px, format = "f", digits = 6, decimal.mark = "."), ",",
      formatC(py, format = "f", digits = 6, decimal.mark = "."))
    paste0("M", paste(xy, collapse = "L"), "Z")
  }
  prepared$paths <- vapply(geometry, function(g) {
    polygons <- if (inherits(g, "POLYGON")) list(g) else g
    paste(vapply(polygons, function(p) paste(vapply(p, ring_path, character(1)), collapse = ""), character(1)), collapse = "")
  }, character(1))
  prepared$metadata$bounds <- as.list(unname(as.numeric(sf::st_bbox(geometry))))
  prepared$metadata$dateline <- "split at +/-180 degrees"
  prepared$metadata$holes <- "preserved using even-odd fill"
  prepared$geometry <- geometry
  prepared
}

sf_node_coordinates <- function(data, ids) {
  prepared <- sf_geometry(data, ids, "POINT")
  sf_bounds(prepared$geometry, ids)
  prepared$coordinates <- sf::st_coordinates(prepared$geometry)[, 1:2, drop = FALSE]
  prepared$geometry <- NULL
  prepared
}

# Fit all supplied geographic layers, independent of values or current filters.
auto_view_bounds <- function(x, padding) {
  if (!is.numeric(padding) || length(padding) != 1L || is.na(padding) ||
      !is.finite(padding) || padding < 0 || padding > 0.5)
    stop("padding must be a fraction from 0 to 0.5", call. = FALSE)
  bounds <- list()
  if (NROW(x$areas)) {
    box <- x$spatial$areas$bounds
    if (is.null(box)) {
      retained <- attr(x, "area_geometry", exact = TRUE)
      if (is.null(retained))
        stop("Automatic area framing needs sf input; supply explicit bounds for SVG path tables", call. = FALSE)
      if (!requireNamespace("sf", quietly = TRUE))
        stop("Install sf to frame this older atlas, or supply explicit bounds", call. = FALSE)
      box <- as.numeric(sf::st_bbox(retained$geometry))
    }
    bounds[[length(bounds) + 1L]] <- unlist(box, use.names = FALSE)
  }
  if (NROW(x$nodes)) bounds[[length(bounds) + 1L]] <- c(
    min(x$nodes$longitude), min(x$nodes$latitude),
    max(x$nodes$longitude), max(x$nodes$latitude))
  if (!length(bounds)) stop("Add geographic areas or nodes before automatic framing", call. = FALSE)
  box <- c(min(vapply(bounds, `[`, numeric(1), 1)), min(vapply(bounds, `[`, numeric(1), 2)),
           max(vapply(bounds, `[`, numeric(1), 3)), max(vapply(bounds, `[`, numeric(1), 4)))
  expand <- function(lo, hi, limit) {
    center <- (lo + hi) / 2
    # A minimum one-degree span keeps coincident points usable.
    span <- max(hi - lo, 1) * (1 + 2 * padding)
    c(max(limit[1], center - span / 2), min(limit[2], center + span / 2))
  }
  lon <- expand(box[1], box[3], c(-180, 180))
  lat <- expand(box[2], box[4], c(-60, 85))
  c(lon[1], lat[1], lon[2], lat[2])
}
