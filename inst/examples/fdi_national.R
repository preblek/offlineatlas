library(offlineatlas)

world <- sf::st_read(example_file("world_sf.geojson"), quiet = TRUE)
data <- example_data("fdi_national")
meta <- jsonlite::fromJSON(example_file("fdi_metadata.json"))
years <- sort(unique(data$year))
# Use source economy labels when available, retaining explicit names for unmatched areas.
names_by_id <- setNames(data$label, data$id)
world$label <- unname(names_by_id[world$id])
fallback <- c(ATF = "French Southern and Antarctic Lands", CYN = "Northern Cyprus",
  ESH = "Western Sahara", FLK = "Falkland Islands", SOL = "Somaliland")
for (id in world$id[is.na(world$label)]) world$label[world$id == id] <-
  if (id %in% names(fallback)) fallback[[id]] else id
observations <- do.call(rbind, lapply(years, function(period) {
  year <- data[data$year == period, ]
  stopifnot(!anyDuplicated(year$id[nzchar(year$id)]))
  frame <- world
  joined <- match(frame$id, year$id)
  frame$year <- period
  frame$matched <- !is.na(joined)
  frame$inflow <- year$inflow_usd_millions[joined]
  frame$note <- vapply(seq_along(joined), function(i) {
    if (is.na(joined[i])) return("No source record for this country and year. Historical economies are not reassigned to successors.")
    row <- year[joined[i], ]
    parts <- c(row$inflow_usd_millions_missing_reason, row$inflow_usd_millions_footnote)
    parts <- parts[!is.na(parts) & nzchar(parts)]
    if (length(parts)) paste(parts, collapse = ". ") else ""
  }, character(1))
  frame
}))
fdi <- atlas("FDI inflows across countries",
  entity_name = "country or area", entity_names = "countries and areas",
  description = "Explore national inward FDI flows from 1990 to 2025. Play through the years or select a country to see its history. Map color intervals stay fixed across all years.",
  notice = "Annual inward flows in millions of current US dollars, without inflation adjustment. Negative values and recorded zeroes are retained. Missing observations are not imputed. Present-day boundaries are used throughout; historical economies are not reassigned. Estimate and revision status are not supplied.",
  units = "USD millions",
  sources = c("United Nations Trade and Development (UNCTAD) Data Hub, FDI flows and stock. CC BY 3.0 IGO. Natural Earth boundaries (public domain). Independent visualization; no UNCTAD or United Nations endorsement is implied.",
    "Data reuse terms: https://unctadstat.unctad.org/EN/About.html. License: https://creativecommons.org/licenses/by/3.0/igo/. Adapted subset; retain attribution and identify changes. See bundled FDI-NOTICE.txt.",
    "Source file US_FdiFlowsStock.csv. Flow 08 (Flow), Direction 1 (Inward). Stocks, outward measures, and 73 regional aggregates excluded.",
    "Numeric economy identifiers mapped through a saved countrycode 1.9.0 crosswalk. Kosovo 412 joins KOS explicitly. Historical economies are not reassigned to successors. Small economies without polygons remain in the cleaned country table.",
    "Bundled sf boundary preparation explicitly repairs USA and Sudan geometry with GEOS. See world_sf_metadata.json.",
    "National totals are separate from the bilateral sample and must not be treated as sums of that sample.",
    "Per-observation missing reasons and reporting footnotes are retained in country details, history tables, and data downloads. Some observations use an asset/liability basis.",
    paste("Source SHA-256", meta$national_source_sha256))) |>
  add_areas(observations, label = "label", matched = "matched", values = "inflow",
    labels = "FDI inflows (USD millions)", time = "year", notes = "note",
    breaks = list(c(-10000, 0, 1000, 10000, 100000)),
    colors = list(c("#a9602d", "#e4b87e", "#edf4db", "#8fc1a0", "#247577", "#164c60"))) |>
  set_controls(initial_time = "2025")
export_html(fdi, "fdi-national-inflows.html", overwrite = TRUE)
