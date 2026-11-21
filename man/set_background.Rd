\name{set_background}
\alias{set_background}
\title{Add a Local Schematic Illustration}
\description{Embed a passive SVG illustration behind a schematic network.}
\usage{
set_background(x, file)
}
\arguments{
\item{x}{An atlas object.}
\item{file}{Local SVG filename. Its root viewBox must be exactly "0 0 1000 650" and it must use the supported passive SVG subset.}
}
\details{
Add schematic nodes before setting a background. The illustration is
embedded in the HTML and requires no external file when viewed. The browser
can toggle its visibility, and visible artwork is included in SVG and PNG
exports. An illustration does not imply geographic node positions.

Supported SVG elements are svg, g, defs, path, rect, circle, ellipse, line,
polyline, polygon, use, text, tspan, title and desc. References must be local
fragments. External resources, scripts, style attributes, event attributes,
DOCTYPE declarations, entities and processing instructions are rejected.
}
\value{An \code{offline_atlas} object, suitable for piping into another
configuration function or \code{\link{export_html}}.}
\seealso{\code{\link{add_nodes}}, \code{\link{set_controls}}, \code{\link{export_html}}.

For the tutorial, see the \code{\link{offlineatlas}} package overview.}
\examples{
families <- example_data("florence_nodes")
m <- atlas("Florentine families") |>
  add_nodes(families, "id", "label", layout_x = "x", layout_y = "y",
            coordinates = "schematic")
m <- set_background(m, example_file("florence.svg"))
}
