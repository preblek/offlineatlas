# Generated from the worked vignette by pkgdown/sync-tutorial-scripts.R.
# Run in a folder you own. Exports replace previous files with the same names.
# All inputs are bundled with offlineatlas; no data download is needed.

## ----load-package-------------------------------------------------------------
library(offlineatlas)
stopifnot(packageVersion("offlineatlas") >= "0.0.14")




## ----ofac-1-------------------------------------------------------------------
# example_data() reads the CSV from the installed package.
# It works regardless of your working directory.
ofac <- example_data("ofac_state_penalties_2009_2025")

# Inspect the column names and first few observations.

names(ofac)
head(ofac)

# The data contain annual average and maximum monetary penalties.
# Both amounts have already been converted to constant 2025 dollars.
#
# Zero means no qualifying monetary penalty recorded in the source
# for that state and year. Missing values should remain NA.


## ----ofac-2-------------------------------------------------------------------
# These are US Census Bureau 2024 cartographic boundaries at 1:20m.
# They are simplified for display and already contain just the 50 states.
us_states <- sf::st_read(
  example_file("us_states_sf.geojson"),
  quiet = TRUE
)

nrow(us_states)  # 50 states.
sf::st_crs(us_states)  # Longitude and latitude, EPSG:4326.




## ----ofac-3-------------------------------------------------------------------
ofac_2025 <- subset(ofac, year == 2025)

# Check that each state appears exactly once in this year's data.

stopifnot(
  nrow(ofac_2025) == 50,
  !anyDuplicated(ofac_2025$state),
  setequal(ofac_2025$state, state.name)
)

# The CSV uses "state" for state names.
# The boundary file uses "NAME".
# character(0) means every data name has a boundary match.

setdiff(ofac_2025$state, us_states$NAME)

# Attach the observations to the geographic shapes.
# all.x = TRUE retains every state boundary.

states_ofac <- merge(
  us_states,
  ofac_2025,
  by.x = "NAME",
  by.y = "state",
  all.x = TRUE
)

# Verify that the join preserved all 50 states and their values.

stopifnot(
  nrow(states_ofac) == 50,
  !anyNA(states_ofac$average_penalty_2025_usd),
  !anyNA(states_ofac$max_penalty_2025_usd)
)


## ----ofac-4-------------------------------------------------------------------
# Use a temporary folder while learning. To keep your exports,
# replace this with a folder you own, such as "ofac_maps".

output_dir <- "."

dir.create(
  output_dir,
  showWarnings = FALSE,
  recursive = TRUE
)

# Five breakpoints create six color intervals.
# The same thresholds let us compare average and maximum penalties.
# A value exactly on a breakpoint enters the higher interval.

penalty_breaks <- c(
  1000000,
  5000000,
  10000000,
  50000000,
  100000000
)

# Set the opening view to the contiguous United States.
# The order is west, south, east, north.
# Alaska and Hawaii remain in the atlas data.

us_bounds <- c(-125, 24, -66, 50)

# Create a reusable starting object.
# This contains the title and explanatory text, but no areas yet.

ofac_base <- atlas(
  title = "OFAC penalties by state, 2025",
  units = "2025 USD",
  entity_name = "state",
  entity_names = "states",
  notice = paste(
    "US-based entities. Amounts adjusted using the GDP deflator.",
    "Zero indicates no qualifying monetary penalty recorded."
  ),
  sources = c(
    "Prepared OFAC state-year penalty data, 2009–2025.",
    "BEA GDP implicit price deflator, via FRED.",
    "US Census Bureau, 2024 cartographic state boundaries."
  )
)


## ----ofac-5-------------------------------------------------------------------
# Start from ofac_base, which has no area layer.
# STUSPS supplies unique state identifiers.
# NAME supplies the state names displayed to readers.

ofac_map <- add_areas(
  ofac_base,
  data = states_ofac,
  id = "STUSPS",
  label = "NAME",
  values = "average_penalty_2025_usd",
  labels = "Average penalty (2025 USD)",
  breaks = list(penalty_breaks)
)

ofac_map <- set_view(
  ofac_map,
  bounds = us_bounds,
  title = "Contiguous United States"
)

# Inspect the prepared atlas before exporting.

summary(ofac_map)

# Each export contains the data, shapes, scripts, and styles.
# Compression reduces file size without changing the observations.

file1 <- file.path(
  output_dir,
  "ofac-states-2025-average.html"
)

export_html(
  ofac_map,
  file = file1,
  compress = TRUE,
  overwrite = TRUE
)

# Open this example manually when you want to inspect it.
# The interactive() check prevents browser windows opening while knitting.

if (interactive()) {
  browseURL(normalizePath(file1))
}


## ----ofac-6-------------------------------------------------------------------
# Create another atlas from the empty base.
# Do not add areas to ofac_map again: it already has an area layer.
#
# Supplying two variables creates a dropdown in the viewer.
# It switches between measures on the same map.

ofac_map2 <- add_areas(
  ofac_base,
  data = states_ofac,
  id = "STUSPS",
  label = "NAME",
  values = c(
    "average_penalty_2025_usd",
    "max_penalty_2025_usd"
  ),
  labels = c(
    "Average penalty (2025 USD)",
    "Maximum penalty (2025 USD)"
  ),
  breaks = list(
    penalty_breaks,
    penalty_breaks
  )
)

ofac_map2 <- set_view(
  ofac_map2,
  bounds = us_bounds,
  title = "Contiguous United States"
)

file2 <- file.path(
  output_dir,
  "ofac-states-2025-average-and-max.html"
)

export_html(
  ofac_map2,
  file = file2,
  compress = TRUE,
  overwrite = TRUE
)


## ----ofac-7-------------------------------------------------------------------
# Six colors are needed for our six intervals.
# Colors run from lower values to higher values.

blues <- c(
  "#6BAED6",
  "#4292C6",
  "#2171B5",
  "#08519C",
  "#083E7D",
  "#062B58"
)

# Change the appearance of the existing atlas.
# There is no need to repeat atlas() or add_areas().
#
# Assigning the result to a new name preserves ofac_map2.
# By default, this palette applies to all numeric area variables.

ofac_map3 <- set_palette(
  ofac_map2,
  colors = blues
)

# units = "2025 USD" supplies a label.
# set_number_format() controls how the numbers themselves appear.
#
# This displays 150.5 as $150.50 and 0 as $0.00.
# It does not change the underlying observations.

ofac_map3 <- set_number_format(
  ofac_map3,
  style = "currency",
  currency = "USD",
  digits = 2
)

file3 <- file.path(
  output_dir,
  "ofac-states-2025-blue.html"
)

export_html(
  ofac_map3,
  file = file3,
  compress = TRUE,
  overwrite = TRUE
)


## ----ofac-8-------------------------------------------------------------------
# Exactly zero gets its own gray fill.
# Positive penalties retain the blue interval colors.
# Missing observations get a separate white fill.
#
# Omitting colors preserves the blue palette already applied.

ofac_map4 <- set_palette(
  ofac_map3,
  zero_color = "#E6E6E6",
  zero_label = "No recorded monetary penalty",
  missing_color = "#FFFFFF",
  border_color = "#000000",
  border_width = 0.6
)

# Replace the separate legend boxes with adjoining color bands.
# These bands represent the existing fixed intervals.
# Their widths are not proportional to numeric distance.
# Zero and missing observations retain separate small keys.

ofac_map4 <- set_legend(
  ofac_map4,
  type = "bar",
  title = "Penalty amount (2025 USD)"
)

file4 <- file.path(
  output_dir,
  "ofac-states-2025-color-bar.html"
)

export_html(
  ofac_map4,
  file = file4,
  compress = TRUE,
  overwrite = TRUE
)

if (interactive()) {
  browseURL(normalizePath(file4))
}


## ----ofac-9-------------------------------------------------------------------
# Selecting one state shows its active value in a card.
# Available positions are top_right, top_left,
# bottom_right, and bottom_left.
#
# On narrow screens, the card moves below the map.

ofac_map5 <- set_selection_card(
  ofac_map4,
  visible = TRUE,
  position = "bottom_left"
)

# Supply default headings for SVG and PNG downloads.
# prompt = TRUE lets readers edit these headings in the browser.
# Editing a download heading does not change the atlas or its data.

ofac_map5 <- set_export_options(
  ofac_map5,
  title = "OFAC penalties by state, 2025",
  subtitle = "US-based entities; amounts in constant 2025 US dollars",
  prompt = TRUE
)

file5 <- file.path(
  output_dir,
  "ofac-states-2025-customized.html"
)

export_html(
  ofac_map5,
  file = file5,
  compress = TRUE,
  overwrite = TRUE
)

if (interactive()) {
  browseURL(normalizePath(file5))
}


## ----ofac-10------------------------------------------------------------------
# These create alternate objects without changing ofac_map5.
# Export any of them with export_html() to inspect the result.

# Return to separate legend boxes.
# Include the title again because set_legend() resets its own settings.

ofac_boxes <- set_legend(
  ofac_map5,
  type = "boxes",
  title = "Penalty amount (2025 USD)",
  columns = 2
)

# Put the color-bar legend above the map.

ofac_legend_above <- set_legend(
  ofac_map5,
  type = "bar",
  title = "Penalty amount (2025 USD)",
  position = "above"
)

# Hide the selected-state card.

ofac_without_card <- set_selection_card(
  ofac_map5,
  visible = FALSE
)

# Skip the heading dialog when downloading an image.

ofac_quick_download <- set_export_options(
  ofac_map5,
  title = "OFAC penalties by state, 2025",
  subtitle = "Amounts in constant 2025 US dollars",
  prompt = FALSE
)

# Apply a different palette to only the maximum-penalty variable.
# This illustrates per-variable styling. Using the same palette
# for both measures remains useful when comparing their magnitudes.

purples <- c(
  "#BCBDDC",
  "#9E9AC8",
  "#807DBA",
  "#6A51A3",
  "#54278F",
  "#3F007D"
)

ofac_mixed_palettes <- set_palette(
  ofac_map5,
  variable = "max_penalty_2025_usd",
  colors = purples
)


## ----export-alternative-------------------------------------------------------
export_html(
  ofac_boxes,
  file.path(output_dir, "ofac-states-2025-boxes.html"),
  compress = TRUE, overwrite = TRUE
)


## ----ofac-11------------------------------------------------------------------
# Choose one variable for the static figure.
# The palette, zero/missing colors, boundaries, currency formatting,
# and color-bar legend carry through to the static area map.
#
# The browser's selection card and download-heading dialog do not
# apply to static figures. Set their headings with ggplot2::labs().

average_figure <- as_ggplot(
  ofac_map5,
  variable = "average_penalty_2025_usd"
)

average_figure <- average_figure +
  ggplot2::labs(
    title = "Average OFAC penalty by state, 2025",
    subtitle = "US-based entities; amounts in constant 2025 US dollars",
    caption = paste(
      "Prepared OFAC teaching snapshot; zero means no qualifying penalty recorded.",
      "BEA GDP deflator via FRED; US Census Bureau 2024 boundaries (public domain).",
      sep = "\n"
    )
  )

print(average_figure)

dir.create(file.path(output_dir, "static"), showWarnings = FALSE)

ggplot2::ggsave(
  filename = file.path(output_dir, "static", "ofac-average-2025.pdf"),
  plot = average_figure,
  width = 11,
  height = 7,
  units = "in",
  bg = "white"
)

# A PNG preview is useful for slides and web pages.
ggplot2::ggsave(
  file.path(output_dir, "static", "ofac-average-2025.png"),
  plot = average_figure, width = 11, height = 7, dpi = 150, bg = "white"
)


## ----ofac-12------------------------------------------------------------------
list.files(
  output_dir,
  pattern = "\\.html$"
)

# Each HTML file is independent and works offline.
# Changing an R object does not update an existing HTML file.
# Run export_html() again to save your latest changes.

