\name{set_inset}
\alias{set_inset}
\title{Add a Geographic Detail Inset}
\description{Configure one rectangular inset that shares data and selection with the main map.}
\usage{
set_inset(x, bounds, title = "Regional detail", visible = TRUE)
}
\arguments{
\item{x}{An atlas object.}
\item{bounds}{Numeric vector of west, south, east, north in degrees for one
geographic inset or initial regional view. Bounds must lie within the supported world projection and
must not cross the dateline. Geographic nodes or areas must already exist.}
\item{title}{Plain-text inset title.}
\item{visible}{Logical flag controlling initial inset visibility. The viewer can toggle it.}
}
\details{
An optional geographic inset uses a fixed rectangular extent and shares
filters, focus, area colors, and point/line size scales with the main map.
Only edges with an endpoint in the inset are included; external connections
are clipped at its boundary. Selecting a node or area in either view updates
both. Main-map pan and zoom do not change the inset extent. SVG and PNG include
the inset when visible, with its title and geographic bounds in the caption.

Add geographic nodes or areas first. Calling set_inset again replaces the
previous inset. Automatic cluster detection and dateline-crossing bounds are
not supported. \code{\link{as_ggplot}} omits visible insets with a warning.
}
\value{An \code{offline_atlas} object, suitable for piping into another
configuration function or \code{\link{export_html}}.}
\seealso{\code{\link{set_view}}, \code{\link{set_controls}}, \code{\link{export_html}}.

For the tutorial, see the \code{\link{offlineatlas}} package overview.}
\examples{
places <- data.frame(id = c("Paris", "Rome"),
                     lon = c(2.35, 12.50), lat = c(48.86, 41.90))
m <- atlas("Places") |>
  add_nodes(places, "id", longitude = "lon", latitude = "lat")
m <- set_inset(m, c(-10, 35, 25, 60), title = "Europe detail")
}
