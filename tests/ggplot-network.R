library(offlineatlas)
fails <- function(expr, pattern) {
  error <- tryCatch({force(expr); NULL}, error = identity)
  stopifnot(inherits(error, "error"), grepl(pattern, conditionMessage(error)))
}
nodes <- data.frame(id = c("A", "B", "C", "D"), name = c("Alpha", "Beta", "Gamma", "Isolate"),
  x = c(100, 400, 700, 850), y = c(100, 300, 100, 500))
ties <- data.frame(from = c("A", "A", "B"), to = c("B", "B", "C"),
  layer = c("Marriage", "Business", "Marriage"))
x <- atlas("Schematic") |>
  add_nodes(nodes, id = "id", label = "name", layout_x = "x", layout_y = "y", coordinates = "schematic") |>
  add_edges(ties, from = "from", to = "to", layer = "layer")
p <- as_ggplot(x, layers = "Marriage")
stopifnot(inherits(p, "ggplot"), identical(p$data$id, nodes$id),
  identical(p$data$plot_y, as.numeric(nodes$y)), nrow(attr(p, "offlineatlas_edges")) == 2,
  all(attr(p, "offlineatlas_edges")$drawn), identical(x$nodes$id, nodes$id))
# All labels and isolates are retained, schematic y runs downwards.
built <- ggplot2::ggplot_build(p)
stopifnot(nrow(built$data[[2]]) == 4, nrow(built$data[[3]]) == 4,
  identical(built$data[[2]]$y, -nodes$y))
stopifnot(length(as_ggplot(x, labels = FALSE)$layers) == 2,
  as_ggplot(set_legend(x, visible = FALSE))$theme$legend.position == "none")
both <- as_ggplot(x)$layers[[1]]$data
lanes <- split(both[both$edge_id %in% c(1, 2), ], both$edge_id[both$edge_id %in% c(1, 2)])
stopifnot(!identical(lanes[[1]]$plot_y, lanes[[2]]$plot_y))
edited <- p + ggplot2::labs(title = "Edited") + ggplot2::theme(legend.position = "right")
stopifnot(edited$labels$title == "Edited")
empty <- as_ggplot(x, layers = character())
stopifnot(nrow(attr(empty, "offlineatlas_edges")) == 0, nrow(empty$data) == 4)
invisible(ggplot2::ggplotGrob(empty))
fails(as_ggplot(x, time = 2000), "time is only")
fails(as_ggplot(x, layers = "unknown"), "layer names")
fails(as_ggplot(x, source = "A"), "directed")
fails(as_ggplot(x, variable = "other"), "only available for area")
fails(as_ggplot(x, node_size = NA), "positive finite")
fails(as_ggplot(x, labels = NA), "TRUE or FALSE")

geo <- data.frame(id = c("A", "B", "C", "D"), lon = c(170, -170, 10, 30), lat = c(30, 40, 10, 50))
flows <- data.frame(from = c("A", "B", "A", "A", "A", "B", "A", "A"),
  to = c("B", "A", "C", "D", "B", "A", "C", "D"),
  value = c(-10, 20, 0, NA, 100, 200, NA, 0), year = rep(c(2000, 2005), each = 4))
y <- atlas("Geographic", units = "USD") |>
  add_nodes(geo, id = "id", longitude = "lon", latitude = "lat") |>
  add_edges(flows, from = "from", to = "to", weight = "value", time = "year",
    directed = TRUE, signed = TRUE, coverage = "observed_rows") |>
  set_controls(initial_time = 2000, initial_source = "A")
p <- as_ggplot(y, labels = FALSE)
records <- attr(p, "offlineatlas_edges")
stopifnot(identical(records$weight, flows$value[1:4]), identical(records$drawn, c(TRUE, TRUE, FALSE, FALSE)),
  all(records$time == "2000"), nrow(p$data) == 4)
paths <- p$layers[[1]]$data
stopifnot(all(paths$edge_id %in% c(1, 2)), all(abs(paths$plot_x) <= 180),
  any(paths$plot_x == 180), any(paths$plot_x == -180))
for (route in split(paths, paths$route_id)) stopifnot(all(abs(diff(route$plot_x)) < 10))
stopifnot(identical(records$from, flows$from[1:4]), records$weight[1] < 0,
  !is.null(p$layers[[2]]$geom_params$arrow))
# One arrow path per drawn edge; reciprocal routes occupy different lanes.
stopifnot(length(unique(p$layers[[2]]$data$edge_id)) == 2)
stopifnot(identical(p$scales$get_scales("linewidth")$limits,
  as_ggplot(y, time = 2005)$scales$get_scales("linewidth")$limits))
stopifnot(nrow(attr(as_ggplot(y, source = "A"), "offlineatlas_edges")) == 3)
fails(as_ggplot(y, time = 1990), "Unknown network period")
fails(as_ggplot(y, source = "unknown"), "Unknown network source")
invisible(ggplot2::ggplotGrob(p))
world <- sf::st_read(example_file("world_sf.geojson"), quiet = TRUE)
with_map <- add_areas(y, world)
mapped <- as_ggplot(with_map, labels = FALSE)
stopifnot(inherits(mapped$layers[[1]]$data, "sf"))
invisible(ggplot2::ggplotGrob(mapped))
fails(as_ggplot(add_areas(y, example_data("world_paths"))), "sf input")
lonely <- atlas() |> add_nodes(geo, id = "id", longitude = "lon", latitude = "lat")
invisible(ggplot2::ggplotGrob(as_ggplot(lonely)))
# Serialization and figure exports work independently of browser exports.
saved <- tempfile(); saveRDS(with_map, saved)
stopifnot(nrow(attr(as_ggplot(readRDS(saved)), "offlineatlas_edges")) == 4)
unlink(saved)
image <- tempfile(fileext = ".png")
ggplot2::ggsave(image, mapped, width = 9, height = 6, dpi = 72)
stopifnot(file.info(image)$size > 1000); unlink(image)
html <- tempfile(fileext = ".html"); export_html(with_map, html)
text <- paste(readLines(html, warn = FALSE), collapse = "\n")
stopifnot(!grepl('"offlineatlas_edges"|"route_id"|"plot_x"|"area_geometry"', text))
unlink(html)
cat("Static networks preserve nodes, layers, time, direction, signs, zero/NA rows and dateline routes\n")
