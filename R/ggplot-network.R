# Network geometry stays in ordinary ggplot layers; no browser runtime changes.
network_ggplot <- function(x, variable, time, layers, source, labels, node_size,
                           seed, repel, node_size_by, node_fill_by, node_shape_by, node_fill) {
  if (!is.null(variable)) stop("variable is only available for area maps; network boundaries are neutral", call. = FALSE)
  if (!is.logical(labels) || length(labels) != 1L || is.na(labels))
    stop("labels must be TRUE or FALSE", call. = FALSE)
  if (!is.numeric(node_size) || length(node_size) != 1L || !is.finite(node_size) || node_size <= 0)
    stop("node_size must be a positive finite number in millimetres", call. = FALSE)
  if (!is.logical(repel) || length(repel) != 1L || is.na(repel))
    stop("repel must be TRUE or FALSE", call. = FALSE)
  scalar_text(node_fill, "node_fill")
  tryCatch(grDevices::col2rgb(node_fill), error = function(e) stop("node_fill must be a valid R color", call. = FALSE))
  geographic <- identical(x$coordinates, "geographic")
  retained <- attr(x, "area_geometry", exact = TRUE)
  if (!is.null(x$areas) && is.null(retained))
    stop("Rebuild the network boundaries with sf input to add_areas; SVG paths cannot be used in static maps", call. = FALSE)
  if (!is.null(x$inset) && isTRUE(x$inset$visible))
    warning("Static output includes only the main map; the configured inset is omitted", call. = FALSE)
  if (!is.null(x$background))
    warning("The illustrated SVG background is omitted; static output retains the schematic node positions", call. = FALSE)
  all_edges <- x$edges
  if (is.null(all_edges)) all_edges <- data.frame(from = character(), to = character(),
    weight = numeric(), time = character(), layer = character(), status = character())
  available_layers <- unique(all_edges$layer)
  if (is.null(layers)) layers <- available_layers
  if (!is.character(layers) || anyNA(layers) || anyDuplicated(layers) || any(!layers %in% available_layers))
    stop("layers must contain distinct supplied relationship layer names", call. = FALSE)
  periods <- unique(all_edges$time[!is.na(all_edges$time)])
  if (length(periods)) {
    if (is.null(time)) time <- x$controls$initial_time
    if (is.null(time)) {
      numeric_periods <- suppressWarnings(as.numeric(periods))
      time <- periods[utils::tail(order(if (anyNA(numeric_periods)) periods else numeric_periods), 1)]
    }
    time <- scalar_text(as.character(time), "time")
    if (!time %in% periods) stop("Unknown network period: ", time, call. = FALSE)
  } else if (!is.null(time)) stop("time is only available for a network time series", call. = FALSE)
  if (!is.null(source)) {
    scalar_text(source, "source")
    if (!isTRUE(x$directed)) stop("source filtering requires directed edges", call. = FALSE)
    if (!source %in% all_edges$from) stop("Unknown network source: ", source, call. = FALSE)
  }
  selected <- all_edges$layer %in% layers
  if (!is.null(time)) selected <- selected & !is.na(all_edges$time) & all_edges$time == time
  if (!is.null(source)) selected <- selected & all_edges$from == source
  edges <- all_edges[selected, , drop = FALSE]
  edges$drawn <- !is.na(edges$weight) & edges$weight != 0
  nodes <- network_node_data(x, edges)
  nodes$plot_x <- if (geographic) nodes$longitude else nodes$x
  nodes$plot_y <- if (geographic) nodes$latitude else nodes$y
  size_values <- network_style_value(nodes, node_size_by, "node_size_by", numeric_only = TRUE)
  fill_values <- network_style_value(nodes, node_fill_by, "node_fill_by")
  shape_values <- network_style_value(nodes, node_shape_by, "node_shape_by")
  categorical <- function(value) {
    if (is.factor(value)) return(value)
    factor(value, levels = sort(unique(value[!is.na(value)])))
  }
  # Only the drawing helper uses the minimum size for NA. Original attribute
  # and metric columns keep NA, separately from observed zero values.
  if (!is.null(size_values)) nodes$.node_size <- ifelse(is.na(size_values), 0, size_values)
  if (!is.null(fill_values)) nodes$.node_fill <- if (is.numeric(fill_values)) fill_values else categorical(fill_values)
  if (!is.null(shape_values)) {
    if (is.numeric(shape_values)) stop("node_shape_by requires a categorical attribute or component", call. = FALSE)
    nodes$.node_shape <- categorical(shape_values)
    if (nlevels(nodes$.node_shape) > 5)
      stop("node_shape_by supports at most five categories; use fill for more groups", call. = FALSE)
  }
  bounds <- if (is.null(x$view)) c(-180, -60, 180, 85) else
    unlist(x$view[c("west", "south", "east", "north")])

  # Allocate separate lanes to reciprocal and multilayer ties, consistently
  # across periods and filters. Integer node indices avoid delimiter collisions.
  keys <- unique(all_edges[c("from", "to", "layer")])
  a <- match(keys$from, nodes$id); b <- match(keys$to, nodes$id)
  groups <- split(seq_len(nrow(keys)), paste(pmin(a, b), pmax(a, b), sep = ":"))
  keys$lane <- numeric(nrow(keys))
  for (g in groups) keys$lane[g] <- seq_along(g) - (length(g) + 1) / 2
  routes <- list(); arrows <- list(); coincident <- 0L
  for (i in which(edges$drawn)) {
    e <- edges[i, ]; a <- match(e$from, nodes$id); b <- match(e$to, nodes$id)
    start <- c(nodes$plot_x[a], nodes$plot_y[a]); end <- c(nodes$plot_x[b], nodes$plot_y[b])
    if (geographic && abs(end[1] - start[1]) > 180)
      end[1] <- end[1] + if (end[1] > start[1]) -360 else 360
    delta <- end - start; distance <- sqrt(sum(delta^2))
    if (distance == 0) { edges$drawn[i] <- FALSE; coincident <- coincident + 1L; next }
    lane <- keys$lane[keys$from == e$from & keys$to == e$to & keys$layer == e$layer]
    control <- (start + end) / 2 + c(-delta[2], delta[1]) * .22 * lane * if (a < b) 1 else -1
    curve <- function(t) data.frame(
      plot_x = (1-t)^2 * start[1] + 2*(1-t)*t * control[1] + t^2 * end[1],
      plot_y = (1-t)^2 * start[2] + 2*(1-t)*t * control[2] + t^2 * end[2])
    decorate <- function(points) {
      points$edge_id <- i
      points$layer <- e$layer
      points$magnitude <- abs(e$weight)
      points$sign <- if (e$weight < 0) "Negative" else "Positive"
      points
    }
    route <- decorate(curve(seq(0, 1, length.out = 61)))
    if (geographic) route <- network_wrap_route(route)
    else route$route_id <- paste0(i, ".1")
    routes[[length(routes) + 1L]] <- route
    # Arrowheads sit along the route so node symbols never hide their direction.
    if (isTRUE(x$directed)) {
      arrow <- decorate(curve(seq(.60, .65, length.out = 5)))
      if (geographic) arrow <- network_wrap_route(arrow)
      else arrow$route_id <- paste0(i, ".1")
      arrows[[length(arrows) + 1L]] <- arrow[arrow$route_id == utils::tail(arrow$route_id, 1), , drop = FALSE]
    }
  }
  if (coincident) warning(coincident, " relationship(s) between coincident node positions omitted", call. = FALSE)
  paths <- if (length(routes)) do.call(rbind, routes) else data.frame(
    plot_x = numeric(), plot_y = numeric(), edge_id = integer(), layer = character(),
    magnitude = numeric(), sign = character(), route_id = character())
  arrow_paths <- if (length(arrows)) do.call(rbind, arrows) else paths[FALSE, ]
  colors <- stats::setNames(rep(c("#177b7b", "#b46c3b", "#6462a0", "#497aaf", "#9a4673", "#64854a"),
    length.out = length(available_layers)), available_layers)
  active_layers <- available_layers[available_layers %in% layers]
  # Bind aesthetics locally for R CMD check without adding a dependency on rlang.
  plot_x <- plot_y <- route_id <- layer <- magnitude <- sign <- label <- NULL
  .node_size <- .node_fill <- .node_shape <- NULL
  mapping <- ggplot2::aes(x = plot_x, y = plot_y, group = route_id, colour = layer)
  if (isTRUE(x$weighted)) mapping$linewidth <- ggplot2::aes(linewidth = magnitude)$linewidth
  if (isTRUE(x$signed)) mapping$linetype <- ggplot2::aes(linetype = sign)$linetype
  p <- ggplot2::ggplot(nodes)
  if (!is.null(retained)) p <- p + ggplot2::geom_sf(
    data = sf::st_sf(geometry = retained$geometry), inherit.aes = FALSE,
    fill = "#e5e8e3", colour = "white", linewidth = .15)
  path_args <- list(mapping = mapping, data = paths, inherit.aes = FALSE, lineend = "round")
  if (!isTRUE(x$weighted)) path_args$linewidth <- .65
  p <- p + do.call(ggplot2::geom_path, path_args)
  if (nrow(arrow_paths)) {
    path_args$data <- arrow_paths
    path_args$arrow <- grid::arrow(length = grid::unit(2.2, "mm"), type = "closed")
    path_args$show.legend <- FALSE
    p <- p + do.call(ggplot2::geom_path, path_args)
  }
  point_mapping <- ggplot2::aes(x = plot_x, y = plot_y)
  if (!is.null(size_values)) point_mapping$size <- ggplot2::aes(size = .node_size)$size
  if (!is.null(fill_values)) point_mapping$fill <- ggplot2::aes(fill = .node_fill)$fill
  if (!is.null(shape_values)) point_mapping$shape <- ggplot2::aes(shape = .node_shape)$shape
  point_args <- list(mapping = point_mapping, colour = "#35595d", stroke = .4)
  if (is.null(size_values)) point_args$size <- node_size
  if (is.null(fill_values)) point_args$fill <- node_fill
  if (is.null(shape_values)) point_args$shape <- 21
  p <- p + do.call(ggplot2::geom_point, point_args)
  if (labels) {
    # Off-map labels must not be pulled into a regional map by the solver.
    label_nodes <- if (geographic) nodes[nodes$longitude >= bounds[1] & nodes$longitude <= bounds[3] &
      nodes$latitude >= bounds[2] & nodes$latitude <= bounds[4], , drop = FALSE] else nodes
    label_args <- list(data = label_nodes, mapping = ggplot2::aes(x = plot_x, y = plot_y, label = label),
      size = 3, colour = "#183f45", fill = "white", label.padding = grid::unit(.08, "lines"))
    if (repel) {
      label_args <- c(label_args, list(seed = seed, max.overlaps = Inf, max.time = Inf,
        max.iter = 10000, box.padding = .35, point.padding = .3,
        point.size = if (is.null(size_values)) node_size else 6,
        min.segment.length = 0, segment.color = "#809292", segment.size = .25,
        label.size = 0, linewidth = 0))
      p <- p + do.call(ggrepel::geom_label_repel, label_args)
    } else {
      label_args$nudge_y <- if (geographic) (bounds[4] - bounds[2]) * .024 else 18
      label_args$linewidth <- 0
      p <- p + do.call(ggplot2::geom_label, label_args)
    }
  }
  legend <- x$legend
  columns <- if (is.null(legend$columns)) 3L else legend$columns
  if (!is.null(size_values)) p <- p + ggplot2::scale_size_continuous(
    name = network_style_title(node_size_by, x$units), range = c(2, 6),
    limits = c(0, max(c(1, size_values), na.rm = TRUE)),
    breaks = function(limits) {
      if (node_size_by %in% c("degree", "in_degree", "out_degree"))
        unique(round(seq(0, limits[2], length.out = 3)))
      else { ticks <- pretty(limits, n = 2); ticks[ticks >= 0 & ticks <= limits[2]] }
    }, labels = network_number_labels)
  if (!is.null(fill_values)) {
    title <- network_style_title(node_fill_by, x$units)
    if (is.numeric(fill_values)) {
      if (any(fill_values < 0, na.rm = TRUE)) p <- p + ggplot2::scale_fill_gradient2(
        name = title, low = "#b05b3a", mid = "#faf8ee", high = "#177b7b", midpoint = 0,
        na.value = "#bdbdbd", labels = network_number_labels)
      else p <- p + ggplot2::scale_fill_gradient(name = title, low = "#d7ebdc", high = "#12616c",
        na.value = "#bdbdbd", labels = network_number_labels)
    } else {
      palette <- grDevices::hcl.colors(max(1, nlevels(nodes$.node_fill)), "Dark 3")
      p <- p + ggplot2::scale_fill_manual(name = title,
        values = stats::setNames(palette[seq_len(nlevels(nodes$.node_fill))], levels(nodes$.node_fill)),
        drop = FALSE, na.value = "#bdbdbd")
    }
  }
  if (!is.null(shape_values)) p <- p + ggplot2::scale_shape_manual(name = network_style_title(node_shape_by),
    values = stats::setNames((21:25)[seq_len(nlevels(nodes$.node_shape))], levels(nodes$.node_shape)),
    drop = FALSE, na.value = 4)
  if (length(active_layers)) p <- p + ggplot2::scale_colour_manual(values = colors,
    limits = active_layers, drop = FALSE, name = if (is.null(legend$title)) "Relationship" else legend$title)
  if (isTRUE(x$weighted)) {
    maximum <- max(c(0, abs(all_edges$weight)), na.rm = TRUE)
    p <- p + ggplot2::scale_linewidth_continuous(name = paste0("Absolute weight",
      if (nzchar(x$units)) paste0(" (", x$units, ")")), range = c(.3, 2),
      limits = c(0, if (maximum > 0) maximum else 1),
      breaks = function(limits) {
        ticks <- pretty(limits, n = 3)
        ticks[ticks > 0 & ticks <= limits[2]]
      }, labels = function(values) {
        divisor <- ifelse(values >= 1e9, 1e9, ifelse(values >= 1e6, 1e6, ifelse(values >= 1e3, 1e3, 1)))
        suffix <- ifelse(divisor == 1e9, "B", ifelse(divisor == 1e6, "M", ifelse(divisor == 1e3, "K", "")))
        paste0(format(values / divisor, trim = TRUE, scientific = FALSE, digits = 3), suffix)
      })
  }
  if (isTRUE(x$signed)) p <- p + ggplot2::scale_linetype_manual(
    values = c(Positive = "solid", Negative = "dashed"), limits = c("Positive", "Negative"),
    drop = FALSE, name = "Weight sign")
  if (geographic) p <- p + ggplot2::coord_sf(
    crs = "+proj=eqc +lat_ts=0 +datum=WGS84 +units=m +no_defs", default_crs = "OGC:CRS84",
    datum = NA, xlim = bounds[c(1,3)], ylim = bounds[c(2,4)], expand = FALSE)
  else p <- p + ggplot2::scale_y_reverse() + ggplot2::coord_fixed(
    xlim = range(nodes$x) + c(-60, 60), ylim = rev(range(nodes$y) + c(-40, 40)))
  position <- if (is.null(legend$position)) "bottom" else
    switch(legend$position, above = "top", below = "bottom", sidebar = "right")
  if (identical(legend$visible, FALSE)) position <- "none"
  family <- c(system = "sans", sans = "sans", serif = "serif", mono = "mono")
  font <- if (is.null(x$style$font_family)) "sans" else unname(family[x$style$font_family])
  heading <- if (is.null(x$style$heading_family)) "sans" else unname(family[x$style$heading_family])
  large <- identical(x$preset, "presentation")
  layout_info <- attr(x, "network_layout", exact = TRUE)
  caption <- c(if (is.null(size_values)) "Equal-size symbols identify nodes; symbol size does not encode a value." else
      paste0("Symbol size shows ", network_style_title(node_size_by, x$units), "; a minimum size keeps zero and missing values visible."),
    if (!is.null(fill_values) && anyNA(fill_values)) "Gray node fill indicates a missing attribute or metric.",
    if (!is.null(shape_values) && anyNA(shape_values)) "Crosses indicate missing shape categories.",
    if (any(vapply(nodes[c("strength_partial", "in_strength_partial", "out_strength_partial")], any, logical(1))) &&
        any(c(node_size_by, node_fill_by) %in% c("strength", "in_strength", "out_strength")))
      "Strength sums known absolute weights only; missing records make some totals incomplete.",
    if (!is.null(layout_info)) paste0("Automatic ", layout_info$method, " layout from all supplied periods and layers; seed ", layout_info$seed, "."),
    if (isTRUE(x$weighted)) "Line width shows absolute weight, using a fixed scale across all supplied periods and layers.",
    if (isTRUE(x$directed)) paste0("Arrows indicate source-to-target direction",
      if (isTRUE(x$signed)) ", including negative flows." else "."),
    if (geographic) "Present-day boundaries. Lines show schematic connections, not travel routes." else "Schematic layout, not geographic locations.",
    if (any(edges$status %in% c("zero", "unavailable")))
      paste0(sum(edges$status == "zero"), " zero and ", sum(edges$status == "unavailable"),
        " unavailable relationship rows retained in plot metadata; neither creates a line."),
    if (!is.null(x$background)) "Illustrated background omitted.",
    if (!identical(legend$visible, FALSE)) legend$note,
    x$notice, if (length(x$sources)) x$sources[[1]])
  caption <- paste(vapply(caption[nzchar(caption)], function(s)
    paste(strwrap(s, width = 110), collapse = "\n"), character(1)), collapse = "\n")
  subtitle <- c(if (length(active_layers)) paste(active_layers, collapse = " + ") else "No relationship layers selected",
    if (!is.null(time)) paste("Year", time),
    if (!is.null(source)) paste("Source", nodes$label[match(source, nodes$id)]))
  p <- p + ggplot2::labs(title = x$title, subtitle = paste(subtitle, collapse = " | "), caption = caption) +
    ggplot2::guides(colour = ggplot2::guide_legend(ncol = columns, byrow = TRUE),
      linewidth = ggplot2::guide_legend(ncol = columns, byrow = TRUE),
      linetype = ggplot2::guide_legend(ncol = columns, byrow = TRUE)) +
    ggplot2::guides(size = ggplot2::guide_legend(ncol = columns, byrow = TRUE),
      shape = ggplot2::guide_legend(ncol = columns, byrow = TRUE)) +
    ggplot2::theme_void(base_family = font) + ggplot2::theme(
      legend.position = position, legend.box = "vertical", legend.title = ggplot2::element_text(size = if (large) 11 else 9),
      legend.text = ggplot2::element_text(size = if (large) 10 else 8),
      legend.key.size = grid::unit(3.2, "mm"), legend.key.width = grid::unit(9, "mm"),
      legend.margin = ggplot2::margin(2, 0, 2, 0), legend.spacing.y = grid::unit(1, "mm"),
      plot.title = ggplot2::element_text(family = heading, face = "bold", size = if (large) 20 else 16),
      plot.title.position = "plot", plot.subtitle = ggplot2::element_text(size = if (large) 12 else 10),
      plot.caption.position = "plot", plot.caption = ggplot2::element_text(size = 8, hjust = 0, margin = ggplot2::margin(t = 7)),
      plot.margin = ggplot2::margin(10, 10, 10, 10))
  attr(p, "offlineatlas_edges") <- edges
  attr(p, "offlineatlas_layout") <- layout_info
  p
}

# Split an unwrapped, sampled route exactly at the dateline. Never draw a
# spurious segment across the world. Interpolation keeps endpoints connected.
network_wrap_route <- function(points) {
  zone <- floor((points$plot_x + 180) / 360)
  result <- list(); part <- 1L
  first <- points[1, ]; first$plot_x <- first$plot_x - 360 * zone[1]
  first$route_id <- paste0(first$edge_id, ".", part); result[[1]] <- first
  for (j in seq.int(2L, nrow(points))) {
    if (zone[j] != zone[j-1]) {
      boundary <- if (zone[j] > zone[j-1]) 180 + 360 * zone[j-1] else -180 + 360 * zone[j-1]
      fraction <- (boundary - points$plot_x[j-1]) / (points$plot_x[j] - points$plot_x[j-1])
      cross <- points[j-1, ]; cross$plot_x <- boundary - 360 * zone[j-1]
      cross$plot_y <- points$plot_y[j-1] + fraction * (points$plot_y[j] - points$plot_y[j-1])
      cross$route_id <- paste0(cross$edge_id, ".", part); result[[length(result)+1L]] <- cross
      part <- part + 1L; cross$plot_x <- boundary - 360 * zone[j]
      cross$route_id <- paste0(cross$edge_id, ".", part); result[[length(result)+1L]] <- cross
    }
    point <- points[j, ]; point$plot_x <- point$plot_x - 360 * zone[j]
    point$route_id <- paste0(point$edge_id, ".", part); result[[length(result)+1L]] <- point
  }
  do.call(rbind, result)
}
