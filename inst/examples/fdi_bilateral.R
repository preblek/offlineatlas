library(offlineatlas)

meta <- jsonlite::fromJSON(example_file("fdi_metadata.json"))
locations <- sf::st_as_sf(example_data("fdi_nodes"),
  coords = c("longitude", "latitude"), crs = 4326)
fdi <- atlas("Bilateral FDI in a nine-country sample",
  entity_name = "country", entity_names = "countries",
  description = "Explore investor-to-host FDI links among Brazil, China, France, Germany, India, Japan, Singapore, the United Kingdom, and the United States, 2020–2024.",
  notice = "Host reporting perspective, direct-first with existing mirror fallback. Direct zeroes retained. Negative values keep the investor-to-host direction. Totals cover this sample only and may be incomplete.",
  units = "USD millions",
  sources = c("UNCTAD FDI/MNE bilateral data, reused from the local FDI Atlas. CC BY 3.0 IGO attribution retained. Natural Earth boundaries (public domain). Independent visualization; no UNCTAD or United Nations endorsement is implied.",
    "Direct numeric inflows take precedence, including zero and negative values; existing mirror reports fill missing direct values. Reciprocal partner reports and mirror-assisted substitutions are not used in this demonstration.",
    "Inflows and outflows are alternative reporting perspectives, not additive measures. This example uses inflows only. Missing reports stay missing; zero and missing rows do not create lines.",
    "Circle area uses the sum of absolute incoming flows, while tables and totals preserve signs. Negative flows do not automatically mean a complete investment exit.",
    paste("Derived source SHA-256", meta$bilateral_source_sha256),
    "United Nations Trade and Development (UNCTAD) Data Hub source and reuse terms: https://unctadstat.unctad.org/EN/About.html. See bundled FDI-NOTICE.txt.",
    "License reference: https://creativecommons.org/licenses/by/3.0/igo/")) |>
  add_areas(sf::st_read(example_file("world_sf.geojson"), quiet = TRUE)) |>
  add_nodes(locations, id = "id", label = "label") |>
  add_edges(example_data("fdi_bilateral"), from = "from_id", to = "to_id",
    weight = "value", time = "year", directed = TRUE, coverage = "complete_panel",
    signed = TRUE, provenance = "provenance") |>
  set_controls(initial_time = "2024") |>
  set_inset(c(-15, 34, 35, 62), title = "Europe detail")
export_html(fdi, "fdi-bilateral.html", overwrite = TRUE)
