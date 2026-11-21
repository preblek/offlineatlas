library(offlineatlas)

if (requireNamespace("sf", quietly = TRUE)) {
  fails <- function(expr, pattern) {
    error <- tryCatch({ force(expr); NULL }, error = identity)
    stopifnot(inherits(error, "error"), grepl(pattern, conditionMessage(error)))
  }
  rect <- function(w, s, e, n) rbind(c(w,s),c(e,s),c(e,n),c(w,n),c(w,s))
  shape <- sf::st_multipolygon(list(list(rect(0,0,10,10),rect(3,3,7,7)),list(rect(20,0,22,2))))
  areas <- sf::st_sf(id = "islands", value = -3, private = "not exported",
    geometry = sf::st_sfc(shape, crs = "OGC:CRS84"))
  original <- areas
  before_s2 <- sf::sf_use_s2()
  result <- add_areas(atlas(), areas, values = "value", breaks = list(0))
  path <- result$areas$path
  stopifnot(lengths(regmatches(path, gregexpr("M", path))) == 3,
    lengths(regmatches(path, gregexpr("Z", path))) == 3,
    result$areas$value_1 == -3, identical(areas, original), identical(sf::sf_use_s2(), before_s2),
    !"private" %in% names(result$areas), result$spatial$areas$input == "sf")
  projected <- sf::st_transform(areas, 3857)
  same <- add_areas(atlas(), projected, values = "value", breaks = list(0))
  stopifnot(identical(path, same$areas$path))
  point <- sf::st_sf(id = c("A", "B"), geometry = sf::st_sfc(sf::st_point(c(-74,40)),
    sf::st_point(c(2,49)), crs = 4326))
  nodes <- add_nodes(atlas(), sf::st_transform(point, 3857), id = "id")
  stopifnot(max(abs(nodes$nodes$longitude-c(-74,2))) < 1e-8,
    max(abs(nodes$nodes$latitude-c(40,49))) < 1e-8)
  edge <- data.frame(from = "A", to = "B", value = -1)
  network <- add_edges(nodes, edge, "from", "to", weight = "value",
    directed = TRUE, signed = TRUE, coverage = "observed_rows")
  stopifnot(network$edges$weight == -1)
  fails(add_nodes(atlas(), point, "id", longitude = "x"), "omit longitude")
  fails(add_nodes(atlas(), point, "id", coordinates = "schematic"), "geographic")
  fails(add_nodes(atlas(), areas, "id"), "POINT")
  fails(add_areas(atlas(), point), "POLYGON")
  fails(add_areas(atlas(), sf::st_set_crs(areas, NA)), "declared CRS")
  fails(add_areas(atlas(), rbind(areas, areas)), "unique")
  empty <- areas; sf::st_geometry(empty) <- sf::st_sfc(sf::st_polygon(), crs = 4326)
  fails(add_areas(atlas(), empty), "Empty")
  bad <- areas; sf::st_geometry(bad) <- sf::st_sfc(sf::st_polygon(list(
    rbind(c(0,0),c(10,10),c(0,10),c(10,0),c(0,0)))), crs = 4326)
  fails(add_areas(atlas(), bad), "Invalid sf polygon.*islands")
  outside <- areas; sf::st_geometry(outside) <- sf::st_sfc(sf::st_polygon(list(rect(0,86,1,87))), crs=4326)
  fails(add_areas(atlas(), outside), "outside.*extent")
  point_z <- sf::st_sf(id="z", geometry=sf::st_sfc(sf::st_point(c(1,2,3)), crs=4326))
  fails(add_nodes(atlas(), point_z, "id"), "XY")
  invalid_point <- point; sf::st_geometry(invalid_point)[[1]] <- sf::st_point(c(Inf,40))
  fails(add_nodes(atlas(), invalid_point, "id"), "finite")
  seam <- sf::st_sf(id="seam", geometry=sf::st_sfc(sf::st_polygon(list(
    rbind(c(170,10),c(-170,10),c(-170,20),c(170,20),c(170,10)))),crs=4326))
  seam_map <- add_areas(atlas(), seam)
  parts <- strsplit(seam_map$areas$path, "Z", fixed=TRUE)[[1]]
  stopifnot(length(parts)==2)
  for (part in parts) {
    xy <- matrix(as.numeric(strsplit(gsub("[ML]", "", gsub("L", " ", part)), "[ ,]+")[[1]]),ncol=2,byrow=TRUE)
    stopifnot(diff(range(xy[,1])) < 30) # Short seam pieces, never a world-wide chord.
  }
  world <- sf::st_read(example_file("world_sf.geojson"), quiet=TRUE)
  stopifnot(identical(world$id, example_data("world_paths")$id), nrow(world)==176,
    all(sf::st_is_valid(sf::st_set_crs(sf::st_geometry(world),NA))))
  stopifnot(nrow(add_areas(atlas(),world)$areas)==176)
  cat("sf polygons, holes, islands, projected points, CRS validation, and dateline checks passed\n")
} else message("Skipping optional sf tests because sf is not installed")
