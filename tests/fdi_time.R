library(offlineatlas)
if (requireNamespace("sf", quietly = TRUE)) {
  temporary <- tempfile();dir.create(temporary);previous <- getwd();setwd(temporary)
  source(system.file("examples", "fdi_national.R", package = "offlineatlas"), local = TRUE)
  setwd(previous)
  source_data <- example_data("fdi_national")
  stopifnot(length(fdi$area_frames) == 36, nrow(fdi$areas) == 176,
    identical(fdi$controls$initial_time, "2025"))
  counts <- c(negative = 0, zero = 0, missing = 0, notes = 0)
  for (frame in fdi$area_frames) {
    original <- source_data[source_data$year == as.integer(frame$time), ]
    joined <- match(frame$data$id, original$id)
    stopifnot(identical(frame$data$value_1, original$inflow_usd_millions[joined]),
      identical(frame$data$matched, !is.na(joined)))
    expected_notes <- original$inflow_usd_millions_footnote[joined]
    for(i in which(!is.na(expected_notes) & nzchar(expected_notes)))
      stopifnot(grepl(expected_notes[i],frame$data$notes[i],fixed=TRUE))
    counts <- counts + c(sum(frame$data$value_1 < 0,na.rm=TRUE),
      sum(frame$data$value_1 == 0,na.rm=TRUE),sum(is.na(frame$data$value_1)),
      sum(nzchar(frame$data$notes)))
  }
  stopifnot(all(counts > 0))
  unlink(temporary,recursive=TRUE)
  cat("All 6,336 area/year observations reconciled, including negatives, zeroes, missing records and footnotes\n")
}
