# Optional authoring adapter. No ggplot2 or sf code is needed by exported viewers.
as_ggplot <- function(x, variable = NULL, time = NULL) {
  check_atlas(x)
  if (!requireNamespace("ggplot2", quietly = TRUE) || !requireNamespace("sf", quietly = TRUE))
    stop("Install optional ggplot2 and sf packages to create static maps", call. = FALSE)
  if (is.null(x$areas) || !is.null(x$nodes) || !length(x$variables))
    stop("as_ggplot supports area maps with variables; network plots are not yet supported", call. = FALSE)
  retained <- attr(x, "area_geometry", exact = TRUE)
  if (is.null(retained)) stop("Rebuild this atlas with sf input to add_areas; static maps need retained sf geometry", call. = FALSE)
  if (!is.null(x$inset) && isTRUE(x$inset$visible))
    warning("Static output includes only the main map; the configured inset is omitted", call. = FALSE)
  if (is.null(variable)) variable <- x$variables[[1]]$source_column
  scalar_text(variable, "variable")
  found <- Filter(function(v) identical(v$source_column, variable), x$variables)
  if (length(found) != 1L) stop("Unknown area variable: ", variable, call. = FALSE)
  v <- found[[1]];rows <- x$areas
  if (length(x$area_frames)) {
    periods <- vapply(x$area_frames, function(f) f$time, character(1))
    if (is.null(time)) {
      time <- x$controls$initial_time
      if (is.null(time)) {
        numeric_periods <- suppressWarnings(as.numeric(periods))
        time <- periods[utils::tail(order(if (anyNA(numeric_periods)) periods else numeric_periods), 1)]
      }
    }
    time <- scalar_text(as.character(time), "time")
    index <- match(time, periods)
    if (is.na(index)) stop("Unknown area period: ", time, call. = FALSE)
    frame <- x$area_frames[[index]]$data
    frame <- frame[match(rows$id, frame$id), , drop = FALSE]
    for (key in setdiff(names(frame), "id")) rows[[key]] <- frame[[key]]
  } else if (!is.null(time)) stop("time is only available for an area time series", call. = FALSE)
  value <- rows[[v$key]];categorical <- identical(v$type, "categorical")
  legend <- x$legend
  if (categorical) {
    levels <- unlist(v$categories, use.names = FALSE)
    bins <- match(value, levels)
    labels <- levels
  } else {
    breaks <- unlist(v$breaks, use.names = FALSE)
    bins <- findInterval(value, breaks) + 1L
    formatted <- format(round(breaks, 2), trim = TRUE, scientific = FALSE, big.mark = ",")
    labels <- c(paste0("<", formatted[1]),
      if (length(breaks)>1) paste0(utils::head(formatted,-1)," to <",utils::tail(formatted,-1)),
      paste0("\u2265", utils::tail(formatted,1)))
  }
  aliases <- legend$labels[[variable]]
  if (!is.null(aliases)) {
    if (length(aliases) != length(labels)) stop("Legend labels need one entry per interval or category", call. = FALSE)
    labels <- unlist(aliases, use.names = FALSE)
  }
  if (categorical && !identical(legend$show_counts, FALSE))
    labels <- paste0(labels, " (", tabulate(bins, nbins = length(labels)), ")")
  keys <- paste0("class_", seq_along(labels));missing_key <- "missing"
  colors <- if (is.null(v$colors)) c("#edf4db","#c7dfb1","#8fc1a0","#4c9d91","#247577","#164c60")[seq_along(labels)] else unlist(v$colors, use.names = FALSE)
  include_missing <- !categorical || anyNA(value)
  if (include_missing) {
    keys <- c(keys, missing_key);colors <- c(colors, "#d8dbd7")
    labels <- c(labels, if (is.null(legend$missing_label)) "Unavailable or unmatched" else legend$missing_label)
  }
  fill_key <- ifelse(is.na(value), missing_key, paste0("class_", bins))
  geometry_index <- match(rows$id, retained$ids)
  if (anyNA(geometry_index)) stop("Retained geometry does not match area IDs", call. = FALSE)
  plot_data <- sf::st_sf(id = rows$id, label = rows$label, value = value,
    status = ifelse(!rows$matched, "No dataset match", ifelse(is.na(value), "Unavailable observation", "Observed")),
    notes = if (is.null(rows$notes)) rep("", nrow(rows)) else rows$notes,
    time = if (is.null(time)) rep(NA_character_, nrow(rows)) else rep(time, nrow(rows)),
    fill_key = factor(fill_key, levels = keys), geometry = retained$geometry[geometry_index])
  family <- c(system = "sans", sans = "sans", serif = "serif", mono = "mono")
  body_font <- if (is.null(x$style$font_family)) "sans" else unname(family[x$style$font_family])
  heading_font <- if (is.null(x$style$heading_family)) "serif" else unname(family[x$style$heading_family])
  position <- if (is.null(legend$position)) "bottom" else switch(legend$position, above="top", below="bottom", sidebar="right")
  if (identical(legend$visible,FALSE)) position <- "none"
  preset <- x$preset
  preset_columns <- if (categorical || max(nchar(labels)) > 23) 3L else 4L
  if (identical(preset, "presentation")) preset_columns <- min(preset_columns, 3L)
  columns <- if (!is.null(legend$columns)) legend$columns else if (position == "right") 1L else
    if (is.null(preset)) 2L else min(preset_columns, length(keys))
  display_title <- if (!is.null(legend$title)) legend$title else if (is.null(preset)) v$label else NULL
  large <- identical(preset, "presentation")
  bounds <- if (is.null(x$view)) c(-180,-60,180,85) else unlist(x$view[c("west","south","east","north")])
  caption <- c(if (!is.null(legend$note) && !identical(legend$visible,FALSE)) legend$note,
    "Present-day boundaries.",x$notice,if (length(x$sources)) x$sources[[1]])
  caption <- paste(vapply(caption[nzchar(caption)], function(s) paste(strwrap(s,width=115),collapse="\n"),character(1)),collapse="\n")
  # Local binding avoids an undeclared-global warning from ggplot's aesthetic DSL.
  fill_key <- NULL
  ggplot2::ggplot(plot_data, ggplot2::aes(fill = fill_key)) +
    ggplot2::geom_sf(colour = "white", linewidth = 0.15, show.legend = TRUE) +
    ggplot2::scale_fill_manual(values = stats::setNames(colors,keys), limits = keys,
      breaks = keys, labels = vapply(labels,function(s)paste(strwrap(s,width=29),collapse="\n"),character(1),USE.NAMES=FALSE),
      drop = FALSE, na.value = "#d8dbd7", name = display_title) +
    ggplot2::coord_sf(crs = "+proj=eqc +lat_ts=0 +datum=WGS84 +units=m +no_defs",
      default_crs = "OGC:CRS84", datum = NA, xlim = bounds[c(1,3)], ylim = bounds[c(2,4)], expand = FALSE) +
    ggplot2::labs(title = x$title, subtitle = paste(c(v$label,if(!is.null(time))paste("Year",time),
      if(nzchar(x$units))paste("Units",x$units)),collapse=" | "), caption = caption) +
    ggplot2::guides(fill = ggplot2::guide_legend(ncol = columns, byrow = TRUE,
      title.position = "top")) +
    ggplot2::theme_void(base_size = 11, base_family = body_font) +
    ggplot2::theme(legend.position = position, plot.title = ggplot2::element_text(family=heading_font,face="bold",size=if (large) 20 else if (!is.null(preset)) 16 else 17),
      plot.title.position = "plot", plot.caption.position = "plot",
      plot.subtitle = ggplot2::element_text(size=if (large) 12 else 10,margin=ggplot2::margin(b=6)),
      legend.title = ggplot2::element_text(size=if (large) 12 else 9,margin=ggplot2::margin(b=3)),
      legend.text = ggplot2::element_text(size=if (large) 11 else 8),
      legend.key.size = grid::unit(if (large) 4.5 else 3.2,"mm"),
      legend.margin = ggplot2::margin(3,0,3,0),
      legend.box.spacing = grid::unit(2,"mm"),
      plot.caption = ggplot2::element_text(hjust=0,size=if (large) 9 else 8,margin=ggplot2::margin(t=6)),
      plot.margin = ggplot2::margin(10,10,10,10))
}
