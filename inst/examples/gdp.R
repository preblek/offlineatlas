library(offlineatlas)

world <- sf::st_read(example_file("world_sf.geojson"), quiet = TRUE)
gdp <- example_data("worldbank_gdp")
metadata <- jsonlite::fromJSON(example_file("worldbank_metadata.json"))
matched <- match(world$id, gdp$id)
world$label <- ifelse(is.na(matched), world$id, gdp$label[matched])
# Display labels for unmatched Natural Earth features do not change the joins.
fallback <- c(ATF = "French Southern and Antarctic Lands", CYN = "Northern Cyprus",
  ESH = "Western Sahara", FLK = "Falkland Islands", KOS = "Kosovo",
  SOL = "Somaliland", TWN = "Taiwan")
missing_label <- is.na(matched) & world$id %in% names(fallback)
world$label[missing_label] <- unname(fallback[world$id[missing_label]])
world$matched <- !is.na(matched)
world$gdp_per_capita <- gdp$gdp_per_capita[matched]
world$gdp_total <- gdp$gdp_total[matched]

gdp_atlas <- atlas(
  "World Bank GDP across countries",
  entity_name = "country or area", entity_names = "countries and areas",
  description = "Compare GDP per capita or total GDP in 2024. Country colors show fixed value intervals; select an area to inspect both measures.",
  notice = "2024 observations. Current US dollars, not adjusted for inflation or purchasing power. No values are imputed.",
  units = "USD",
  sources = c("World Bank WDI (CC BY 4.0), 2024. Natural Earth boundaries (public domain).",
    "GDP per capita (current US$), NY.GDP.PCAP.CD: https://data.worldbank.org/indicator/NY.GDP.PCAP.CD",
    "GDP (current US$), NY.GDP.MKTP.CD: https://data.worldbank.org/indicator/NY.GDP.MKTP.CD",
    paste("Data snapshot retrieved", metadata$retrieved_at, "from the World Bank API. Aggregate regions excluded."),
    "Bundled sf boundary preparation explicitly repairs USA and Sudan geometry with GEOS. See world_sf_metadata.json.",
    "Exact country-code joins to 176 bundled geographic areas. Some small economies lack visible polygons; unmatched areas are gray. This is not a complete map of every reporting economy.",
    paste("Areas without a World Bank country match:", paste(metadata$areas_without_country_match, collapse = ", ")),
    "Current-dollar changes reflect prices and exchange rates as well as output. This single-year map is not a growth comparison.")) |>
  add_areas(world, label = "label", matched = "matched", values = c("gdp_per_capita", "gdp_total"),
    labels = c("GDP per capita (2024)", "Total GDP (2024)"),
    breaks = list(c(1000, 5000, 15000, 40000, 80000), c(1e10, 1e11, 5e11, 1e12, 5e12)))

export_html(gdp_atlas, "world-bank-gdp.html", overwrite = TRUE)
