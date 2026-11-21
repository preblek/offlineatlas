library(offlineatlas)
europe <- sf::st_read(example_file("europe_sf.geojson"),quiet=TRUE)
membership <- example_data("eu_membership")
periods <- c(1958,1973,1981,1986,1995,2004,2007,2013,2020)
waves <- c("Founding members (1958)","1973","1981","1986","1995","2004","2007","2013","Not a member")
palette <- c("#176f70","#d08a28","#7d62a3","#bf5b60","#689b43","#3d8db8","#ac7348","#bd6aa0","#e1e5e1")
joined <- match(europe$id,membership$id)
observations <- do.call(rbind,lapply(periods,function(year) {
  frame <- europe
  frame$year <- year
  accession <- membership$accession_year[joined]
  member <- !is.na(accession) & accession<=year & !(frame$id=="GBR" & year>=2020)
  frame$wave <- "Not a member"
  frame$wave[member] <- as.character(accession[member])
  frame$wave[member & accession==1958] <- waves[1]
  frame$note <- "Not a member in this period."
  known <- !is.na(joined)
  frame$note[known] <- paste0("Accession date ",membership$accession_date[joined[known]],".")
  frame$note[frame$id=="GBR"] <- paste0(frame$note[frame$id=="GBR"]," Withdrew on 31 January 2020.")
  frame$note[frame$id=="CYP"] <- paste0(frame$note[frame$id=="CYP"]," The whole of Cyprus is EU territory; EU law is suspended where the Republic's government does not exercise effective control.")
  frame
}))
eu <- atlas("European enlargement over time",
  entity_name="country or area",entity_names="countries and areas",
  description="Step through the founding group and seven enlargement waves. Countries keep their accession-wave color after joining. The final period shows the UK's withdrawal.",
  notice="Periods show membership immediately after each enlargement, plus the UK's withdrawal in 2020. Founding countries refer to the EEC in 1958. Present-day boundaries are used throughout; historical territorial coverage is not reconstructed.",
  sources=c("Accession dates from the Council of the European Union. Natural Earth 1:50m boundaries, public domain.",
    "https://www.consilium.europa.eu/en/policies/how-enlargement-works/timeline-accession-eu-member-states/",
    "Snapshots are 1 January in 1958, 1973, 1981, 1986, 1995 and 2007; 1 May 2004; 1 July 2013; and after the UK withdrawal on 31 January 2020.",
    "Countries outside membership in the selected period are neutral gray. This example does not classify candidacy or negotiations.",
    "Cyprus is one membership record combining the source's CYP and CYN areas. EU law is suspended in areas outside the effective control of the Republic's government. https://european-union.europa.eu/principles-countries-history/eu-countries/cyprus_en",
    "Aland is included in Finland's 1995 membership record. https://um.fi/the-special-status-of-the-aland-islands",
    "Boundaries are cropped to Europe. Greenland and overseas territories are excluded. Malta is included as a real polygon, not an enlarged point.")) |>
  add_areas(observations,label="label",values="wave",labels="Accession wave",
    categories=list(waves),colors=list(palette),time="year",notes="note") |>
  set_controls(initial_time="1958") |>
  set_view(c(-25,33,45,72),title="Europe")
export_html(eu,"eu-enlargement.html",overwrite=TRUE)
