library(offlineatlas)

fails <- function(expr, pattern) {
  error <- tryCatch({ force(expr); NULL }, error = identity)
  stopifnot(inherits(error, "error"), grepl(pattern, conditionMessage(error)))
}
nodes <- example_data("aid_nodes")
rows <- example_data("aid")
base <- atlas("Test") |> add_nodes(nodes, id = "country_id", label = "country_name",
  longitude = "longitude", latitude = "latitude")
aid <- add_edges(base, rows, from = "donor_id", to = "recipient_id", weight = "aid_usd",
  time = "year", directed = TRUE, coverage = "complete_panel")
stopifnot(nrow(aid$edges) == 120, sum(aid$edges$weight[aid$edges$time == "2024"], na.rm = TRUE) == 78400000)
can22 <- subset(aid$edges, from == "CAN" & time == "2022")
stopifnot(sum(can22$weight, na.rm = TRUE) == 20500000,
  can22$status[can22$to == "SEN"] == "zero", can22$status[can22$to == "BGD"] == "unavailable")
bad <- nodes; bad$country_id[2] <- bad$country_id[1]
fails(add_nodes(atlas(), bad, "country_id", longitude = "longitude", latitude = "latitude"), "unique")
bad <- nodes; bad$latitude[1] <- 100
fails(add_nodes(atlas(), bad, "country_id", longitude = "longitude", latitude = "latitude"), "latitude")
bad <- rows; bad$recipient_id[1] <- "unknown"
fails(add_edges(base, bad, "donor_id", "recipient_id"), "Unmatched")
fails(add_edges(base, rbind(rows, rows[1, ]), "donor_id", "recipient_id", time = "year"), "Duplicate")
fails(add_edges(base, rows[-1, ], "donor_id", "recipient_id", weight = "aid_usd", time = "year",
  directed = TRUE, coverage = "complete_panel"), "Incomplete panel")
bad <- rows; bad$aid_usd[1] <- -1
fails(add_edges(base, bad, "donor_id", "recipient_id", weight = "aid_usd", coverage = "observed_rows"), "Signed")
signed_test <- add_edges(base, bad, "donor_id", "recipient_id", weight = "aid_usd",
  time = "year", directed = TRUE, signed = TRUE, coverage = "complete_panel")
stopifnot(signed_test$signed, signed_test$edges$weight[1] == -1)
fails(add_edges(base, rows, "donor_id", "recipient_id", weight = "aid_usd"), "coverage")
families <- example_data("florence_nodes"); ties <- example_data("florence_edges")
florence <- atlas() |> add_nodes(families, "id", "label", layout_x = "x", layout_y = "y", coordinates = "schematic") |>
  add_edges(ties, "from", "to", layer = "layer") |>
  set_background(example_file("florence.svg"))
stopifnot(nrow(florence$nodes) == 16, nrow(florence$edges) == 35,
  sum(ties$layer == "Marriage") == 20, sum(ties$layer == "Business") == 15,
  !"11" %in% c(florence$edges$from, florence$edges$to))
reverse <- ties[1, ]; reverse$from <- ties$to[1]; reverse$to <- ties$from[1]
fbase <- atlas() |> add_nodes(families, "id", "label", layout_x = "x", layout_y = "y", coordinates = "schematic")
fails(add_edges(fbase, rbind(ties, reverse), "from", "to", layer = "layer"), "Duplicate")
fails(add_areas(fbase, example_data("world_paths")), "geographic")
gdp <- example_data("worldbank_gdp")
stopifnot(!anyDuplicated(gdp$id), all(gdp$year == 2024), !"WLD" %in% gdp$id,
  all(gdp$gdp_per_capita >= 0, na.rm = TRUE))
world <- example_data("world_paths"); world$v <- seq_len(nrow(world))
fails(add_areas(atlas(), world, values = "v", breaks = list(c(10, 5))), "increasing")
world$matched <- TRUE; world$matched[1] <- FALSE
fails(add_areas(atlas(), world, values = "v", breaks = list(10), matched = "matched"), "Unmatched areas")
world$v[1:2] <- NA_real_
checked <- add_areas(atlas(entity_name = "country", entity_names = "countries"),
  world, values = "v", breaks = list(10), matched = "matched")
stopifnot(!checked$areas$matched[1], checked$areas$matched[2],
  all(is.na(checked$areas$value_1[1:2])), checked$entity_names == "countries")
world$matched <- as.integer(world$matched)
fails(add_areas(atlas(), world, matched = "matched"), "logical")
fails(atlas(entity_names = NA_character_), "entity_names")
detail <- set_inset(base, c(-15, 34, 35, 62), "Europe detail")
stopifnot(detail$inset$west == -15, detail$inset$north == 62, detail$inset$visible)
fails(set_inset(fbase, c(-15, 34, 35, 62)), "geographic")
fails(set_inset(base, c(35, 34, -15, 62)), "bounds")
fails(set_inset(base, c(-15, 34, 35, 90)), "bounds")
fails(set_inset(base, c(-15, 34, 35)), "bounds")
fails(set_inset(base, c(-15, 34, 35, 62), visible = NA), "visible")
fdi <- example_data("fdi_bilateral")
stopifnot(nrow(fdi) == 360, sum(fdi$value < 0, na.rm = TRUE) == 49,
  sum(fdi$value == 0, na.rm = TRUE) == 40, sum(is.na(fdi$value)) == 40,
  all(fdi$value[!is.na(fdi$direct_usd_millions)] == fdi$direct_usd_millions[!is.na(fdi$direct_usd_millions)]))
national <- example_data("fdi_national")
stopifnot(national$inflow_usd_millions[national$id == "AUT" & national$year == 2025] == -7561.847)
world$matched <- TRUE
palette <- add_areas(atlas(), world, values = "v", breaks = list(10), colors = list(c("#ffffff", "#112233")))
stopifnot(identical(palette$variables[[1]]$colors, as.list(c("#ffffff", "#112233"))))
fails(add_areas(atlas(), world, values = "v", breaks = list(10), colors = list("#ffffff")), "palette")
fails(add_areas(atlas(), world, values = "v", breaks = list(10), colors = list(c("red", "blue"))), "palette")
temp <- tempfile(fileext = ".svg")
writeLines('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 650"><script>alert(1)</script></svg>', temp)
fails(set_background(fbase, temp), "unsupported")
writeLines('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 650"><use href="https://example.invalid/image.svg"/></svg>', temp)
fails(set_background(fbase, temp), "external")
writeLines('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 650"><path onclick="alert(1)" d="M0 0L1 1"/></svg>', temp)
fails(set_background(fbase, temp), "active")
unlink(temp)
hostile <- base; hostile$title <- "</title><script>throw new Error('bad')</script>"
hostile$nodes$label[1] <- "</script><script>throw new Error('bad')</script>"
file <- tempfile(fileext = ".html"); export_html(hostile, file)
html <- paste(readLines(file, warn = FALSE), collapse = "\n")
stopifnot(grepl("&lt;/title&gt;", html, fixed = TRUE), grepl("\\u003c", html, fixed = TRUE),
  grepl("connect-src 'none'", html, fixed = TRUE))
fails(export_html(hostile, file), "File exists")
export_html(hostile, file, overwrite = TRUE)
unlink(file)
cat("R validation and data semantics passed\n")
