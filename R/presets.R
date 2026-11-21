# Presets only set presentation fields; source data and semantic options survive.
set_preset <- function(x, preset = c("compact", "presentation")) {
  check_atlas(x)
  preset <- match.arg(preset)
  x$preset <- preset
  x$controls$position <- if (preset == "compact") "above_map" else "top"
  x$legend$position <- "below"
  x$legend$columns <- NULL
  x$style <- list(font_family = "sans", heading_family = "sans")
  x
}
