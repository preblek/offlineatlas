library(offlineatlas)
europe <- sf::st_read(example_file("europe_sf.geojson"), quiet = TRUE)
gdp <- example_data("worldbank_gdp")
region <- europe[europe$id %in% c("BEL", "NLD", "LUX"), ]
stopifnot(nrow(region) == 3)
joined <- match(region$id, gdp$id)
region$gdp <- gdp$gdp_per_capita[joined]
region$matched <- !is.na(joined)
regional <- atlas(
  "GDP per capita in the Benelux countries", units = "USD",
  entity_name = "country", entity_names = "countries",
  description = "A regional sf example with automatic framing and reusable styling.",
  notice = "2024 observations in current US dollars. Missing values are not imputed.",
  sources = c("World Bank WDI, 2024 (CC BY 4.0). Natural Earth 1:50m boundaries (public domain).")
) |>
  add_areas(region, label = "label", values = "gdp", labels = "GDP per capita",
            matched = "matched", breaks = list(c(40000, 80000))) |>
  set_view(title = "Benelux")
regional_audit <- summary(regional)
export_html(set_preset(regional, "compact"), "regional-gdp.html", overwrite = TRUE)
export_html(set_preset(regional, "presentation"), "regional-presentation.html", overwrite = TRUE)
