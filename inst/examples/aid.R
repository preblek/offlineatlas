library(offlineatlas)

aid_atlas <- atlas(
  "A fictional aid atlas",
  entity_name = "country", entity_names = "countries",
  description = "Explore three donors, eight recipients, and five years of fictional aid. Select a source and year, then inspect a recipient.",
  notice = "Fictional teaching data. Amounts are invented; locations are approximate country display points.",
  units = "USD",
  sources = c("Fictional aid teaching example. Boundaries from Natural Earth (public domain).",
    "Present-day boundaries, simplified equirectangular projection. Lines are schematic relationships, not delivery routes.",
    "Natural Earth source and terms: https://www.naturalearthdata.com/about/terms-of-use/")) |>
  add_areas(example_data("world_paths")) |>
  add_nodes(example_data("aid_nodes"), id = "country_id", label = "country_name",
    longitude = "longitude", latitude = "latitude") |>
  add_edges(example_data("aid"), from = "donor_id", to = "recipient_id",
    weight = "aid_usd", time = "year", directed = TRUE, coverage = "complete_panel") |>
  set_controls(initial_source = "CAN", initial_time = "2024")

export_html(aid_atlas, "aid-atlas.html", overwrite = TRUE)
