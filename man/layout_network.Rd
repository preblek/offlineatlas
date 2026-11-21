\name{layout_network}
\alias{layout_network}
\title{Calculate a Reproducible Schematic Network Layout}
\description{Compute node coordinates in R and retain them in an atlas for
standalone HTML exports or static ggplot2 figures.}
\usage{layout_network(x, layout = c("fr", "kk", "circle"), seed = 1)}
\arguments{
\item{x}{An atlas with schematic nodes and, optionally, edges. Geographic
networks are rejected because their coordinates represent real locations.}
\item{layout}{An igraph layout. fr uses Fruchterman-Reingold, kk uses
Kamada-Kawai, and circle places nodes around a circle in sorted ID order.}
\item{seed}{A nonnegative integer for reproducibility. The caller's random
number state is restored after the layout is calculated.}
}
\details{
Add nodes and edges before calling this function. For schematic nodes,
\code{\link{add_nodes}} can omit both layout_x and layout_y, which gives a
circular starting arrangement. All nodes, including isolates, are retained.
Layout coordinates are scaled uniformly into the supported schematic canvas.

The graph used for layouts is the union of observed nonzero ties across all
supplied years and layers. Directions, repeated ties and weights are ignored
for placement. A negative observed weight contributes a tie; zero and missing
weights do not. This full-network basis keeps positions stable when comparing
different periods, layers or sources in static figures. Subset the input
edge table first to calculate a layout from only part of the network.
Results are reproducible with the same seed, input and igraph version;
different library versions may change numerical layouts.

An attached SVG illustration is removed with a warning because new positions
may no longer align with the artwork. Add it again explicitly if appropriate.
Computed coordinates are embedded by \code{\link{export_html}}. Neither
igraph nor R is needed to view the exported file. The HTML viewer does not
rerun layouts when its filters change.

Use layout in \code{\link{as_ggplot}} to change only a static figure's layout,
without changing the atlas object. Layout metadata are retained in an
authoring-only attribute and excluded from the HTML payload.
}
\value{An offline_atlas object with new schematic x and y node positions.}
\seealso{\code{\link{add_nodes}}, \code{\link{as_ggplot}}, \code{\link{export_html}}}
\examples{
families <- example_data("florence_nodes")
ties <- example_data("florence_edges")
m <- atlas("Florentine families") |>
  add_nodes(families, "id", "label", coordinates = "schematic") |>
  add_edges(ties, "from", "to", layer = "layer") |>
  layout_network("fr", seed = 7)
stopifnot(all(is.finite(m$nodes$x)))
}
