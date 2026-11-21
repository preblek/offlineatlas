\name{add_nodes}
\alias{add_nodes}
\title{Add Geographic or Schematic Nodes}
\description{Add entities positioned by geographic coordinates or schematic coordinates,
with optional node attributes for static figure styling.}
\usage{
add_nodes(x, data, id, label = id, longitude = NULL, latitude = NULL,
          layout_x = NULL, layout_y = NULL,
          coordinates = c("geographic", "schematic"), attributes = NULL)
}
\arguments{
\item{x}{An atlas object.}
\item{data}{A data frame, or an sf object with POINT geometry.}
\item{id}{Column name for stable, unique, nonempty node identifiers.}
\item{label}{Column name for nonempty display labels. Defaults to id.}
\item{longitude}{Column names for numeric geographic coordinates.
Omit both for sf POINT input, which supplies coordinates through its geometry.
The prototype accepts longitude from -180 to 180 and latitude from -60 to 85.}
\item{latitude}{Column names for numeric geographic coordinates.
Omit both for sf POINT input, which supplies coordinates through its geometry.
The prototype accepts longitude from -180 to 180 and latitude from -60 to 85.}
\item{layout_x}{Column names for schematic positions in a 1000 by
650 view. Allowed ranges are x from 30 to 970 and y from 30 to 600.}
\item{layout_y}{Column names for schematic positions in a 1000 by
650 view. Allowed ranges are x from 30 to 970 and y from 30 to 600.}
\item{coordinates}{Geographic positions or schematic graph positions.}
\item{attributes}{Optional character vector of additional column names retained
for static node size, fill or shape mapping. These columns stay in R and are
not included in the HTML export. Default NULL retains none.}
}
\details{
Nodes must have unique, nonempty IDs and nonempty labels. Add nodes once,
before calling \code{\link{add_edges}}. Only mapped columns and explicitly
requested attributes are retained. Omit both layout_x and layout_y for a
circular starting arrangement. After adding edges, use
\code{\link{layout_network}} for an automatic schematic layout. No
polygon-to-point conversion is performed.

Attributes may be plain numeric, character, factor or logical columns, with
NA allowed. Infinite values, matrices and list columns are rejected. Names
cannot overlap node coordinates or the reserved metrics degree, in_degree,
out_degree, strength, in_strength, out_strength, betweenness and component,
their strength_partial flags, or names starting with .node. Original attribute
values are available in the static plot's data and survive saveRDS. They do
not change the browser's node styling or get included in browser downloads.

For sf POINT input, omit longitude and latitude and use geographic coordinates.
A declared CRS is required; projected coordinates are transformed to
OGC:CRS84. Empty points, missing or non-finite coordinates, Z/M dimensions,
and out-of-range locations are rejected. No CRS is guessed or repaired.
Geographic coordinates stay fixed in the viewer. Schematic nodes may be
moved by dragging when enabled with \code{\link{set_controls}}.
See \code{\link{add_areas}} for the shared geographic display projection.
}
\value{An \code{offline_atlas} object, suitable for piping into another
configuration function or \code{\link{export_html}}.}
\seealso{\code{\link{atlas}}, \code{\link{add_edges}}, \code{\link{add_areas}}, \code{\link{layout_network}}, \code{\link{as_ggplot}}, \code{\link{set_background}}.

For the tutorial, see the \code{\link{offlineatlas}} package overview.}
\examples{
places <- data.frame(id = c("Paris", "Rome"),
                     lon = c(2.35, 12.50), lat = c(48.86, 41.90))
m <- atlas("Places") |>
  add_nodes(places, "id", longitude = "lon", latitude = "lat")

families <- example_data("florence_nodes")
m <- atlas("Florentine families") |>
  add_nodes(families, "id", "label", layout_x = "x", layout_y = "y",
            coordinates = "schematic")
}
