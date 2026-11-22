# Generated from the worked vignette by pkgdown/sync-tutorial-scripts.R.
# Run in a folder you own. Exports replace previous files with the same names.
# All inputs are bundled with offlineatlas; no data download is needed.

## ----population-data----------------------------------------------------------
library(offlineatlas)
stopifnot(packageVersion("offlineatlas") >= "0.0.14")

# Read the installed CSV. No working-directory adjustment is needed.
population <- example_data("japan_prefecture_population_2020_2025")
head(population)
names(population)

# There should be one row per prefecture and no duplicate keys.
stopifnot(
  nrow(population) == 47,
  !anyDuplicated(population$prefecture_id),
  !anyNA(population$population_2020),
  !anyNA(population$population_2025)
)

# Recalculate the change to show exactly what it means.
# Negative values mean fewer residents in 2025 than in 2020.
population$population_change <-
  population$population_2025 - population$population_2020

colSums(population[c("population_2020", "population_2025", "population_change")])




## ----prefecture-boundaries----------------------------------------------------
# Read all 47 prefectures as an sf object.
prefectures <- sf::st_read(
  example_file("japan_prefectures_sf.geojson"),
  quiet = TRUE
)

head(sf::st_drop_geometry(prefectures))
sf::st_crs(prefectures)
sf::st_bbox(prefectures)

stopifnot(
  nrow(prefectures) == 47,
  !anyDuplicated(prefectures$prefecture_id),
  all(sf::st_is_valid(prefectures))
)


## ----join-population----------------------------------------------------------
# Both differences should be character(0), meaning no unmatched keys.
setdiff(population$prefecture_id, prefectures$prefecture_id)
setdiff(prefectures$prefecture_id, population$prefecture_id)
stopifnot(setequal(population$prefecture_id, prefectures$prefecture_id))

# Keep the label already present in the boundary table.
# Only attach the columns needed for this map.
values <- population[c(
  "prefecture_id", "population_2020", "population_2025", "population_change"
)]
japan_data <- merge(
  prefectures, values,
  by = "prefecture_id", all.x = TRUE
)

stopifnot(
  nrow(japan_data) == 47,
  !anyNA(japan_data$population_2020),
  !anyNA(japan_data$population_2025),
  !anyNA(japan_data$population_change)
)


## ----first-japan-map----------------------------------------------------------
# Use a temporary folder while learning. Replace it with "japan_maps"
# or another folder you own if you want to keep the exported files.
output_dir <- "."
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Five thresholds define six color intervals.
# Reuse these for both years so identical colors mean identical ranges.
population_breaks <- c(1000000, 2000000, 4000000, 6000000, 10000000)

japan_base <- atlas(
  title = "Population across Japan's prefectures",
  units = "people",
  entity_name = "prefecture",
  entity_names = "prefectures",
  notice = paste(
    "October 1 counts; 2025 figures are preliminary.",
    "Change is 2025 minus 2020. Fixed 2017 display boundaries.",
    "Source snapshot has not been independently reconciled to the official table."
  ),
  sources = c(
    paste(
      "Population: Wikipedia contributors, List of Japanese prefectures by population,",
      "revision 1384069728, CC BY-SA 4.0; names normalized and change recalculated.",
      "https://en.wikipedia.org/w/index.php?title=List_of_Japanese_prefectures_by_population&oldid=1384069728",
      "https://creativecommons.org/licenses/by-sa/4.0/"
    ),
    paste(
      "Boundaries: copyright OpenStreetMap contributors, via Wambacher / geoBoundaries,",
      "JPN ADM1, 2017; simplified geometry, labels normalized and coordinates rounded.",
      "Adapted database under ODbL 1.0; retain attribution and license notices.",
      "https://www.openstreetmap.org/copyright",
      "https://opendatacommons.org/licenses/odbl/1-0/",
      "Machine-readable adapted boundaries are bundled as japan_prefectures_sf.geojson."
    )
  )
)

japan_2020 <- add_areas(
  japan_base,
  data = japan_data,
  id = "prefecture_id",
  label = "prefecture",
  values = "population_2020",
  labels = "Population in 2020",
  breaks = list(population_breaks)
)

# With sf input, omit bounds to fit every supplied feature.
japan_2020 <- set_view(japan_2020, title = "Japan and its supplied islands")

export_html(
  japan_2020,
  file.path(output_dir, "japan-population-2020.html"),
  compress = TRUE, overwrite = TRUE
)


## ----japan-dropdown-----------------------------------------------------------
# Begin with the empty base again because add_areas() adds one area layer.
# Do not call add_areas() on japan_2020, which already has that layer.
japan_map <- add_areas(
  japan_base,
  data = japan_data,
  id = "prefecture_id",
  label = "prefecture",
  values = c("population_2020", "population_2025", "population_change"),
  labels = c(
    "Population in 2020",
    "Population in 2025 (preliminary)",
    "Population change, 2020 to 2025"
  ),
  breaks = list(
    population_breaks,
    population_breaks,
    c(-100000, -50000, 0, 50000, 100000)
  )
)
japan_map <- set_view(japan_map, title = "Japan and its supplied islands")

summary(japan_map)

export_html(
  japan_map,
  file.path(output_dir, "japan-population-dropdown.html"),
  compress = TRUE, overwrite = TRUE
)


## ----japan-palettes-----------------------------------------------------------
blues <- c("#6BAED6", "#4292C6", "#2171B5", "#08519C", "#083E7D", "#062B58")

# Target both population counts, leaving the change variable separate.
japan_styled <- set_palette(
  japan_map,
  variable = c("population_2020", "population_2025"),
  colors = blues
)

# Warm colors show decline; blue colors show growth.
# Zero has its own neutral key, outside these six intervals.
japan_styled <- set_palette(
  japan_styled,
  variable = "population_change",
  colors = c("#B2182B", "#EF8A62", "#FDDBC7", "#D1E5F0", "#67A9CF", "#2166AC"),
  zero_color = "#E6E6E6",
  zero_label = "No population change"
)

# Apply missing-value and boundary styling to all numeric variables.
# Omitting colors preserves the palettes just assigned.
japan_styled <- set_palette(
  japan_styled,
  missing_color = "#FFFFFF",
  border_color = "#333333",
  border_width = 0.5
)

# These are counts of people, so show whole numbers without a currency sign.
japan_styled <- set_number_format(japan_styled, style = "number", digits = 0)

japan_styled <- set_legend(
  japan_styled, type = "bar", title = "People"
)
japan_styled <- set_selection_card(japan_styled, position = "top_left")

# Rename the dropdown control for this example.
japan_styled <- set_controls(
  japan_styled, labels = c(variable = "Population measure")
)

# Leaving subtitle at NULL uses the active variable in image-download headings.
japan_styled <- set_export_options(
  japan_styled,
  title = "Population across Japan's prefectures",
  prompt = TRUE
)

export_html(
  japan_styled,
  file.path(output_dir, "japan-population.html"),
  compress = TRUE, overwrite = TRUE
)

if (interactive()) {
  browseURL(normalizePath(file.path(output_dir, "japan-population.html")))
}


## ----japan-alternatives-------------------------------------------------------
# Keep the styled atlas and create a box-legend alternative.
japan_boxes <- set_legend(
  japan_styled, type = "boxes", title = "People", columns = 3
)
export_html(
  japan_boxes,
  file.path(output_dir, "japan-population-boxes.html"),
  compress = TRUE, overwrite = TRUE
)

# Another version concentrates on the main archipelago.
# A separate geographic inset shows Okinawa and nearby islands.
japan_focused <- set_view(
  japan_styled,
  bounds = c(128, 30, 146, 46),
  title = "Main archipelago"
)
japan_focused <- set_inset(
  japan_focused,
  bounds = c(122, 24, 131, 30),
  title = "Southwestern islands"
)
export_html(
  japan_focused,
  file.path(output_dir, "japan-population-inset.html"),
  compress = TRUE, overwrite = TRUE
)


## ----japan-static-------------------------------------------------------------
# Choose a single variable. The full-extent atlas has no inset to omit.
change_figure <- as_ggplot(
  japan_styled, variable = "population_change"
) +
  ggplot2::labs(
    title = "Population change across Japan's prefectures",
    subtitle = "2025 minus 2020, in people; 2025 counts are preliminary",
    caption = paste(
      "Population: Wikipedia contributors (CC BY-SA 4.0), revision 1384069728.",
      "Boundaries: OpenStreetMap contributors / Wambacher / geoBoundaries (ODbL 1.0), 2017.",
      "Fixed display boundaries; source counts not independently reconciled to official data.",
      sep = "\n"
    )
  )
print(change_figure)

dir.create(file.path(output_dir, "static"), showWarnings = FALSE)
ggplot2::ggsave(
  file.path(output_dir, "static", "japan-population-change.pdf"),
  plot = change_figure, width = 10, height = 9, units = "in", bg = "white"
)
ggplot2::ggsave(
  file.path(output_dir, "static", "japan-population-change.png"),
  plot = change_figure, width = 10, height = 9, dpi = 150, bg = "white"
)

