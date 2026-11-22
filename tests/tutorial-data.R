library(offlineatlas)

# Bundled tutorials must have complete, unique joins and preserve source totals.
ofac <- example_data("ofac_state_penalties_2009_2025")
states <- sf::st_read(example_file("us_states_sf.geojson"), quiet = TRUE)
stopifnot(nrow(ofac) == 850L, nrow(states) == 50L,
  identical(sort(unique(ofac$year)), 2009:2025),
  !anyDuplicated(ofac[c("year", "state")]),
  setequal(states$STUSPS, state.abb), setequal(states$NAME, ofac$state),
  !anyNA(ofac), all(is.finite(ofac$average_penalty_2025_usd)),
  all(ofac$max_penalty_2025_usd >= ofac$average_penalty_2025_usd),
  all(ofac$average_penalty_2025_usd >= 0),
  all(sf::st_is_valid(states)))
ca <- subset(ofac, year == 2025 & state == "California")
stopifnot(ca$average_penalty_2025_usd == 108516824.5,
  ca$max_penalty_2025_usd == 215988868)

japan <- example_data("japan_prefecture_population_2020_2025")
shapes <- sf::st_read(example_file("japan_prefectures_sf.geojson"), quiet = TRUE)
stopifnot(nrow(japan) == 47L, nrow(shapes) == 47L,
  !anyDuplicated(japan$prefecture_id), !anyDuplicated(shapes$prefecture_id),
  setequal(japan$prefecture_id, shapes$prefecture_id),
  !anyNA(japan), all(sf::st_is_valid(shapes)),
  sum(japan$population_2020) == 126146099,
  sum(japan$population_2025) == 123049524,
  sum(japan$population_change) == -3096575,
  all(japan$population_change == japan$population_2025 - japan$population_2020),
  all(japan$population_change_pct == round(
    100 * japan$population_change / japan$population_2020, 4)))

for (notice in c("OFAC-NOTICE.txt", "JAPAN-NOTICE.txt"))
  stopifnot(file.info(example_file(notice))$size > 0)
