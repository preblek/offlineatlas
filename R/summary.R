# Count supplied observations, never inferred pairs or absent source records.
atlas_periods <- function(values) {
  values <- unique(as.character(values[!is.na(values)]))
  numeric_values <- suppressWarnings(as.numeric(values))
  values[order(if (length(values) && all(is.finite(numeric_values))) numeric_values else values)]
}

observation_counts <- function(value, numeric, matched = rep(TRUE, length(value))) {
  missing <- is.na(value)
  data.frame(total = length(value), observed = sum(!missing), missing = sum(missing),
    unmatched = sum(!matched), unavailable = sum(missing & matched),
    negative = if (numeric) sum(value < 0, na.rm = TRUE) else NA_integer_,
    zero = if (numeric) sum(value == 0, na.rm = TRUE) else NA_integer_,
    positive = if (numeric) sum(value > 0, na.rm = TRUE) else NA_integer_)
}

summary.offline_atlas <- function(object, ...) {
  check_atlas(object)
  area_rows <- list(); category_rows <- list(); edge_rows <- list()
  frames <- if (length(object$area_frames)) {
    periods <- atlas_periods(vapply(object$area_frames, function(f) f$time, character(1)))
    object$area_frames[match(periods, vapply(object$area_frames, function(f) f$time, character(1)))]
  } else if (!is.null(object$areas)) list(list(time = NA_character_, data = object$areas)) else list()
  for (frame in frames) for (variable in object$variables) {
    value <- frame$data[[variable$key]]
    numeric <- !identical(variable$type, "categorical")
    area_rows[[length(area_rows) + 1L]] <- cbind(data.frame(
      variable = variable$source_column, label = variable$label,
      type = if (numeric) "numeric" else "categorical", time = frame$time),
      observation_counts(value, numeric, frame$data$matched))
    if (!numeric) {
      levels <- unlist(variable$categories, use.names = FALSE)
      category_rows[[length(category_rows) + 1L]] <- data.frame(
        variable = variable$source_column, time = frame$time, category = levels,
        count = tabulate(match(value, levels), nbins = length(levels)))
    }
  }
  edges <- object$edges
  if (NROW(edges)) {
    periods <- atlas_periods(edges$time)
    if (!length(periods)) periods <- NA_character_
    for (period in periods) for (layer in unique(edges$layer)) {
      rows <- edges[edges$layer == layer &
        (if (is.na(period)) is.na(edges$time) else !is.na(edges$time) & edges$time == period), , drop = FALSE]
      if (!nrow(rows)) next
      counts <- observation_counts(rows$weight, isTRUE(object$weighted))
      # Relationship endpoints are validated on input. Area matching does not apply.
      counts$unmatched <- NULL
      edge_rows[[length(edge_rows) + 1L]] <- cbind(data.frame(time = period, layer = layer), counts)
    }
  }
  bind <- function(rows, empty) if (length(rows)) do.call(rbind, rows) else empty
  area_empty <- data.frame(variable=character(),label=character(),type=character(),time=character(),
    total=integer(),observed=integer(),missing=integer(),unmatched=integer(),unavailable=integer(),
    negative=integer(),zero=integer(),positive=integer())
  edge_empty <- data.frame(time=character(),layer=character(),total=integer(),observed=integer(),
    missing=integer(),unavailable=integer(),negative=integer(),zero=integer(),positive=integer())
  result <- list(title = object$title, coordinates = object$coordinates,
    entities = c(nodes = NROW(object$nodes), relationships = NROW(edges), areas = NROW(object$areas)),
    periods = atlas_periods(c(edges$time, vapply(frames, function(f) f$time, character(1)))),
    weighted = isTRUE(object$weighted), directed = isTRUE(object$directed), coverage = object$coverage,
    area_observations = sum(vapply(frames, function(f) nrow(f$data), integer(1))),
    areas = bind(area_rows, area_empty),
    categories = bind(category_rows, data.frame(variable=character(),time=character(),category=character(),count=integer())),
    relationships = bind(edge_rows, edge_empty),
    view = object$view, preset = object$preset)
  structure(result, class = "summary_offline_atlas")
}

print.summary_offline_atlas <- function(x, ..., max_rows = 12L) {
  if (!is.numeric(max_rows) || length(max_rows) != 1L || is.na(max_rows) ||
      !is.finite(max_rows) || max_rows < 1 || max_rows != floor(max_rows))
    stop("max_rows must be a positive integer", call. = FALSE)
  cat(x$title, "\n")
  cat(x$entities[["nodes"]], "nodes,", x$entities[["relationships"]], "relationship rows,",
      x$entities[["areas"]], "areas\n")
  cat("Periods:", if (length(x$periods)) paste(utils::head(x$periods, max_rows), collapse = ", ") else "none (static)",
      if (length(x$periods) > max_rows) paste0(" ... (", length(x$periods), " supplied)"), "\n")
  show <- function(table, label, field) {
    if (!nrow(table)) return(invisible(NULL))
    cat("\n", label, "\n", sep = "")
    print(utils::head(table, max_rows), row.names = FALSE)
    if (nrow(table) > max_rows) cat("Showing", max_rows, "of", nrow(table), paste0("rows; inspect $", field, " for all rows.\n"))
  }
  show(x$areas, "Area observations by variable and period", "areas")
  show(x$categories, "Category counts, including unused levels", "categories")
  show(x$relationships, "Supplied relationships by period and layer", "relationships")
  cat("\nMissing includes unmatched areas and matched-but-unavailable observations.\n")
  cat("Numeric sign counts are NA for categories and unweighted ties. No absent rows are inferred.\n")
  invisible(x)
}
