\name{set_view}
\alias{set_view}
\title{Set the Initial Geographic View}
\description{Frame the main map around a region without changing the display projection.}
\usage{
set_view(x, bounds = NULL, title = "Regional view", padding = 0.05)
}
\arguments{
\item{x}{An atlas object.}
\item{bounds}{NULL to calculate the extent of all supplied geographic layers,
or a numeric vector of west, south, east, north in degrees for one
geographic inset or initial regional view. Bounds must lie within the supported world projection and
must not cross the dateline. Geographic nodes or areas must already exist.}
\item{title}{Plain-text regional view title.}
\item{padding}{Fraction of the data span added on each side for automatic
framing, from 0 to 0.5. Ignored when bounds are supplied explicitly.}
}
\details{
Add geographic nodes or areas first. Fit and Reset return to this extent.
The viewer can still pan and zoom beyond it. This camera setting does not clip
or remove observations from the embedded data. It also supplies the default
extent to \code{\link{as_ggplot}}. Arbitrary display projections are not implemented.

With bounds = NULL, sf area bounds and geographic node positions are combined.
Missing values, current filters and selection do not exclude any geometry.
Call this function after adding all desired layers; bounds are calculated at
that moment, not recalculated when later layers are added. Repeat the call
if you add another geographic layer. Explicit bounds remain supported.

Padding is clipped to longitude -180 to 180 and latitude -60 to 85. Each axis
has a minimum one-degree span before padding, so coincident points and very
small regions have usable framing. Islands and outlying territories remain
included. The display cannot wrap across the dateline; seam-crossing geometry
uses its full minimum-to-maximum longitude extent, which may show the world.
Subset the input explicitly if a smaller region is desired.

Prepared SVG path tables require explicit bounds. sf atlases created before
version 0.0.8 can use retained geometry when sf is installed; new atlases store
plain geographic bounds for this calculation. No new geometry is downloaded.
}
\value{An \code{offline_atlas} object, suitable for piping into another
configuration function or \code{\link{export_html}}.}
\seealso{\code{\link{add_areas}}, \code{\link{add_nodes}}, \code{\link{set_inset}}, \code{\link{as_ggplot}}.

For the tutorial, see the \code{\link{offlineatlas}} package overview.}
\examples{
places <- data.frame(id = c("Paris", "Rome"),
                     lon = c(2.35, 12.50), lat = c(48.86, 41.90))
m <- atlas("Places") |>
  add_nodes(places, "id", longitude = "lon", latitude = "lat")
m <- set_view(m, title = "Both cities")
# Explicit framing remains available.
m <- set_view(m, c(-10, 35, 25, 60), title = "Europe")
}
