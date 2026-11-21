library(offlineatlas)
# Reuse the complete FDI example and its provenance.
source(system.file("examples", "fdi_national.R", package = "offlineatlas"), local = TRUE)
customized <- fdi |>
  set_legend(title = "Annual inward investment", position = "above", columns = 2,
    labels = list(inflow = c("<-10,000", "-10,000 to <0", "0 to <1,000",
      "1,000 to <10,000", "10,000 to <100,000", "\u2265100,000")),
    missing_label = "No available value",
    note = "Millions of current US dollars. Fixed intervals across all years.") |>
  set_controls(initial_time = "1990", position = "above_map",
    visible = c(variable = FALSE), playback_interval = 900,
    labels = c(time = "Observation year", play = "Animate", pause = "Pause animation",
      previous = "Earlier", "next" = "Later", reset = "Start again", fit = "Fit map")) |>
  set_style(font_family = "sans", heading_family = "sans")
export_html(customized, "customized-fdi.html", overwrite = TRUE)
