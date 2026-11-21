network_seed <- function(seed) {
  if (!is.numeric(seed) || length(seed) != 1L || !is.finite(seed) ||
      seed < 0 || seed > .Machine$integer.max || seed != floor(seed))
    stop("seed must be an integer between 0 and .Machine$integer.max", call. = FALSE)
  as.integer(seed)
}

# Only observed, nonzero ties enter topology. All vertices, including isolates,
# stay in the graph. Layouts collapse direction and repeated layer/year ties.
network_graph <- function(ids, edges, directed = FALSE) {
  ties <- if (is.null(edges)) data.frame(from = character(), to = character()) else
    edges[!is.na(edges$weight) & edges$weight != 0, c("from", "to"), drop = FALSE]
  g <- igraph::graph_from_data_frame(ties, directed = directed,
    vertices = data.frame(name = ids, stringsAsFactors = FALSE))
  igraph::simplify(g, remove.multiple = TRUE, remove.loops = TRUE)
}

layout_network <- function(x, layout = c("fr", "kk", "circle"), seed = 1) {
  check_atlas(x)
  if (is.null(x$nodes) || !identical(x$coordinates, "schematic"))
    stop("Automatic layouts require schematic nodes; geographic locations stay fixed", call. = FALSE)
  layout <- match.arg(layout); seed <- network_seed(seed)
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit(if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv) else
    if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv))
  set.seed(seed)
  ids <- sort(x$nodes$id)
  graph <- network_graph(ids, x$edges)
  if (length(ids) == 1) positions <- matrix(c(0, 0), ncol = 2)
  else positions <- switch(layout,
    fr = igraph::layout_with_fr(graph, niter = 500, grid = "nogrid"),
    kk = igraph::layout_with_kk(graph), circle = igraph::layout_in_circle(graph))
  if (any(!is.finite(positions))) stop("Layout produced non-finite positions", call. = FALSE)
  if (layout != "circle" && diff(range(positions[,2])) > diff(range(positions[,1])))
    positions <- cbind(positions[,2], -positions[,1])
  centers <- apply(positions, 2, function(v) mean(range(v)))
  spans <- apply(positions, 2, function(v) diff(range(v)))
  scale <- min(c(880, 500) / pmax(spans, .Machine$double.eps))
  positions <- sweep(positions, 2, centers) * scale
  positions <- sweep(positions, 2, c(500, 315), "+")
  positions <- positions[match(x$nodes$id, ids), , drop = FALSE]
  x$nodes$x <- positions[, 1]; x$nodes$y <- positions[, 2]
  attr(x, "network_layout") <- list(method = layout, seed = seed)
  if (!is.null(x$background)) {
    warning("Automatic layout removes the illustrated background; add it again explicitly if appropriate", call. = FALSE)
    x$background <- NULL
  }
  x
}

network_metric_names <- function() c(degree = "Distinct partners", in_degree = "Incoming partners",
  out_degree = "Outgoing partners", strength = "Known absolute incident weight",
  in_strength = "Known absolute incoming weight", out_strength = "Known absolute outgoing weight",
  betweenness = "Unweighted betweenness", component = "Connected component")

network_node_data <- function(x, edges) {
  nodes <- x$nodes
  attributes <- attr(x, "node_attributes", exact = TRUE)
  if (!is.null(attributes)) for (name in setdiff(names(attributes), "id"))
    nodes[[name]] <- attributes[[name]][match(nodes$id, attributes$id)]
  g <- network_graph(nodes$id, edges, directed = isTRUE(x$directed))
  undirected <- if (isTRUE(x$directed)) igraph::as_undirected(g, mode = "collapse") else g
  nodes$degree <- as.numeric(igraph::degree(undirected))
  nodes$in_degree <- as.numeric(igraph::degree(g, mode = "in"))
  nodes$out_degree <- as.numeric(igraph::degree(g, mode = "out"))
  nodes$betweenness <- as.numeric(igraph::betweenness(g, directed = isTRUE(x$directed), weights = NA, normalized = FALSE))
  nodes$component <- factor(igraph::components(undirected)$membership)
  for (kind in c("strength", "in_strength", "out_strength")) {
    totals <- lapply(nodes$id, function(id) {
      keep <- if (!isTRUE(x$directed) || kind == "strength") edges$from == id | edges$to == id else
        if (kind == "in_strength") edges$to == id else edges$from == id
      values <- edges$weight[keep]
      c(value = if (length(values) && all(is.na(values))) NA_real_ else sum(abs(values), na.rm = TRUE),
        partial = anyNA(values))
    })
    nodes[[kind]] <- vapply(totals, function(v) unname(v["value"]), numeric(1))
    nodes[[paste0(kind, "_partial")]] <- vapply(totals, function(v) as.logical(v["partial"]), logical(1))
  }
  nodes
}

network_style_value <- function(nodes, name, option, numeric_only = FALSE) {
  if (is.null(name)) return(NULL)
  scalar_text(name, option)
  allowed <- c(names(network_metric_names()), setdiff(names(nodes),
    c("id", "label", "x", "y", "longitude", "latitude", "plot_x", "plot_y",
      "strength_partial", "in_strength_partial", "out_strength_partial")))
  if (!name %in% allowed || !name %in% names(nodes))
    stop(option, " must name a retained node attribute or network metric", call. = FALSE)
  value <- nodes[[name]]
  if (numeric_only && (!is.numeric(value) || any(value < 0, na.rm = TRUE)))
    stop(option, " requires a nonnegative numeric attribute or metric", call. = FALSE)
  value
}

network_style_title <- function(name, units = "") {
  titles <- network_metric_names()
  title <- if (name %in% names(titles)) unname(titles[name]) else name
  if (name %in% c("strength", "in_strength", "out_strength") && nzchar(units))
    title <- paste0(title, " (", units, ")")
  title
}

network_number_labels <- function(values) {
  divisor <- ifelse(abs(values) >= 1e9, 1e9, ifelse(abs(values) >= 1e6, 1e6, ifelse(abs(values) >= 1e3, 1e3, 1)))
  suffix <- ifelse(divisor == 1e9, "B", ifelse(divisor == 1e6, "M", ifelse(divisor == 1e3, "K", "")))
  paste0(format(values / divisor, trim = TRUE, scientific = FALSE, digits = 3), suffix)
}
