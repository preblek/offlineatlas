\name{set_controls}
\alias{set_controls}
\title{Customize Browser Controls}
\description{Choose initial filters, toolbar placement, labels, visibility and playback speed.}
\usage{
set_controls(x, initial_source = NULL, initial_time = NULL, drag = TRUE,
             visible = NULL, position = c("top", "above_map", "sidebar"),
             labels = NULL, playback_interval = 1400)
}
\arguments{
\item{x}{An atlas object.}
\item{initial_source}{Optional initial source identifier. Requires directed
relationships and an identifier present in their source column.}
\item{initial_time}{Optional initial period, present in the relationship data
or area frames.}
\item{drag}{Allow node dragging in schematic mode. Geographic nodes do not move.}
\item{visible}{NULL or a named logical vector choosing applicable controls. Unspecified controls retain automatic visibility. See details for keys.}
\item{position}{Toolbar location: top, above_map, or sidebar.}
\item{labels}{NULL or a named character vector of interface text overrides. See details for keys.}
\item{playback_interval}{Milliseconds between observations, from 200 to 60000.}
}
\details{
set_controls visibility keys are time, playback, source, variable, layers,
size, background, inset, reset, zoom, search, selection, downloads, and history.
Hiding a selector retains its initial state and does not remove embedded data.
Hiding selection controls does not disable selecting entities on the map.
Hiding downloads also hides the country history CSV button. A control only
appears when applicable to the data, even if explicitly requested as visible.
Text keys are time, source, variable, layers, size, background, inset, previous,
play, pause, next, reset, zoom_in, zoom_out, fit, search, selection, clear_focus,
select_all, select_none, export_svg, export_png, export_csv, export_json, and
history_csv. Specify play and pause together to customize both playback states.

Configuration replaces the previous control options using the supplied
arguments and defaults. Supply all desired overrides in the same call.
Text is plain text, not HTML or JavaScript. Quote reserved R names in named
vectors, for example c("next" = "Later"). Playback advances between observed
periods at equal intervals, without interpolating missing years. It works
entirely in the browser. See \code{\link{export_html}} for search and
selection behavior.
}
\value{An \code{offline_atlas} object, suitable for piping into another
configuration function or \code{\link{export_html}}.}
\seealso{\code{\link{set_legend}}, \code{\link{set_style}}, \code{\link{add_areas}}, \code{\link{export_html}}.

For the tutorial, see the \code{\link{offlineatlas}} package overview.}
\examples{
m <- atlas("Custom controls") |>
  set_controls(position = "above_map", playback_interval = 1800,
    visible = c(search = TRUE, downloads = TRUE),
    labels = c(play = "Animate", pause = "Pause", "next" = "Later"))
}
