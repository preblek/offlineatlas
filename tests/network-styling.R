library(offlineatlas)
fails <- function(expr, pattern) {
  error <- tryCatch({ force(expr); NULL }, error = identity)
  stopifnot(inherits(error, "error"), grepl(pattern, conditionMessage(error)))
}
nodes <- data.frame(id = LETTERS[1:4], label = c("Alpha family", "Beta family", "Gamma family", "Isolated family"),
  faction = c("One", "Two", "One", NA), wealth = c(2, 8, 0, NA),
  change = c(-3, 2, 0, NA), private_note = "Do not export this attribute")
ties <- data.frame(from = c("A", "B", "A", "B", "C", "D"),
  to = c("B", "C", "B", "A", "D", "A"), value = c(2, 3, 4, -1, 0, NA),
  layer = c("One", "One", "Two", "One", "One", "One"))
x <- atlas("Styled network") |>
  add_nodes(nodes, id = "id", label = "label", coordinates = "schematic",
    attributes = c("faction", "wealth", "change", "private_note")) |>
  add_edges(ties, from = "from", to = "to", weight = "value", layer = "layer",
    directed = TRUE, signed = TRUE, coverage = "observed_rows")
original <- x$nodes
set.seed(96); before <- .Random.seed
a <- layout_network(x, seed = 13)
stopifnot(identical(before, .Random.seed), identical(x$nodes, original),
  identical(a$nodes, layout_network(x, seed = 13)$nodes),
  !identical(a$nodes, layout_network(x, seed = 14)$nodes))
for (layout in c("fr", "kk", "circle")) {
  placed <- layout_network(x, layout)
  stopifnot(nrow(placed$nodes) == 4, all(is.finite(placed$nodes$x)),
    all(placed$nodes$x >= 30 & placed$nodes$x <= 970),
    all(placed$nodes$y >= 30 & placed$nodes$y <= 600))
}
rm(".Random.seed", envir = .GlobalEnv)
invisible(layout_network(x))
stopifnot(!exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
single <- atlas() |> add_nodes(data.frame(id = "Only"), "id", coordinates = "schematic")
stopifnot(layout_network(single)$nodes$x == 500, layout_network(single)$nodes$y == 315)
isolates <- atlas() |> add_nodes(nodes, "id", coordinates = "schematic")
stopifnot(all(is.finite(layout_network(isolates, "kk")$nodes$x)))

p <- as_ggplot(x, layout = "fr", seed = 13, node_size_by = "degree",
  node_fill_by = "faction", node_shape_by = "faction")
stopifnot(identical(p$data$degree, c(1, 2, 1, 0)),
  identical(p$data$in_degree, c(1, 1, 1, 0)),
  identical(p$data$out_degree, c(1, 2, 0, 0)),
  identical(p$data$strength, c(7, 10, 3, 0)),
  identical(p$data$strength_partial, c(TRUE, FALSE, FALSE, TRUE)),
  identical(p$data$betweenness, c(0, 1, 0, 0)),
  nlevels(p$data$component) == 2,
  identical(p$data$plot_x, a$nodes$x),
  inherits(p$layers[[length(p$layers)]]$geom, "GeomLabelRepel"),
  !inherits(as_ggplot(x, repel = FALSE)$layers[[4]]$geom, "GeomLabelRepel"))
q <- as_ggplot(x, layers = "Two", node_size_by = "degree")
stopifnot(identical(q$data$degree, c(1, 1, 0, 0)))
b <- ggplot2::ggplot_build(p)
points <- b$data[[3]]
stopifnot(nrow(points) == 4, points$size[2] > points$size[1], points$size[4] > 0,
  points$shape[4] == 4, points$fill[4] == "#bdbdbd")
stopifnot(nrow(attr(p + ggplot2::labs(title = "Edited"), "offlineatlas_edges")) == 6)
for (args in list(list(node_size_by = "wealth", node_fill_by = "change"),
                  list(node_fill_by = "component"), list(layers = character(), node_size_by = "degree"))) {
  figure <- do.call(as_ggplot, c(list(x = x), args))
  invisible(ggplot2::ggplotGrob(figure))
}
unavailable <- x
unavailable$edges$weight[] <- NA_real_
unavailable$edges$status[] <- "unavailable"
missing <- as_ggplot(unavailable, node_size_by = "strength", node_fill_by = "strength")
stopifnot(all(is.na(missing$data$strength)))
invisible(ggplot2::ggplotGrob(missing))
all_missing <- x
attr(all_missing, "node_attributes")$faction[] <- NA_character_
invisible(ggplot2::ggplotGrob(as_ggplot(all_missing, node_fill_by = "faction", node_shape_by = "faction")))
fails(as_ggplot(x, node_size_by = "change"), "nonnegative")
fails(as_ggplot(x, node_shape_by = "wealth"), "categorical")
fails(as_ggplot(x, node_fill_by = "missing_column"), "retained node attribute")
fails(as_ggplot(x, node_fill = "not_a_color"), "valid R color")
fails(as_ggplot(x, repel = NA), "TRUE or FALSE")
fails(layout_network(x, seed = -1), "seed")
fails(add_nodes(atlas(), transform(nodes, degree = 0), "id", coordinates = "schematic", attributes = "degree"), "reserved")
fails(add_nodes(atlas(), nodes, "id", coordinates = "schematic", layout_x = "wealth"), "both")
geo <- atlas() |> add_nodes(data.frame(id = "A", lon = 0, lat = 0), "id", longitude = "lon", latitude = "lat")
fails(as_ggplot(geo, layout = "fr"), "geographic locations stay fixed")
places <- data.frame(id = c("Inside", "Outside"), lon = c(5, 100), lat = c(50, 20))
region <- atlas() |> add_nodes(places, "id", longitude = "lon", latitude = "lat") |>
  set_view(c(-15, 34, 35, 62))
regional <- as_ggplot(region)
stopifnot(nrow(regional$data) == 2,
  identical(regional$layers[[length(regional$layers)]]$data$id, "Inside"))
# Node-order changes do not change an automatic layout for the same graph.
reordered <- x; reordered$nodes <- x$nodes[4:1, ]
ordered_back <- layout_network(reordered, seed = 13)$nodes
stopifnot(isTRUE(all.equal(a$nodes$x, ordered_back$x[match(a$nodes$id, ordered_back$id)])))
# Positions are based on the full network even when the plotted layer changes.
filtered <- as_ggplot(x, layers = "Two", layout = "fr", seed = 13)
stopifnot(identical(filtered$data$plot_x, a$nodes$x))
# The circular layout is calculated once and embedded; extra attributes stay in R.
file <- tempfile(fileext = ".html")
export_html(a, file)
html <- paste(readLines(file, warn = FALSE), collapse = "\n")
stopifnot(!grepl('Do not export this attribute|"node_attributes"|"network_layout"', html))
unlink(file)
file <- tempfile(); saveRDS(a, file)
stopifnot(identical(attr(readRDS(file), "node_attributes"), attr(a, "node_attributes")))
unlink(file)
file <- tempfile(fileext = ".png")
set.seed(15); before <- .Random.seed
ggplot2::ggsave(file, p, width = 9, height = 7, dpi = 72)
stopifnot(identical(before, .Random.seed), file.info(file)$size > 1000)
unlink(file)
cat("Automatic layouts, isolated nodes, filtered measures, attribute styling, missing values, repel labels and offline isolation passed\n")
