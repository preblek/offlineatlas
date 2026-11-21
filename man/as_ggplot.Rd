\name{as_ggplot}
\alias{as_ggplot}
\title{Create an Editable Static Map or Network}
\description{Convert a geographic or schematic network, or one variable and period of an sf-backed area atlas, into
a regular ggplot object. ggplot2 and sf are required authoring dependencies installed with offlineatlas;
saved figures and HTML viewers need neither package.}
\usage{as_ggplot(x, variable = NULL, time = NULL, layers = NULL,
  source = NULL, labels = TRUE, node_size = 3)}
\arguments{
\item{x}{An offline_atlas object. Area maps and network boundaries require sf polygon input to add_areas. Networks may also omit boundaries.}
\item{variable}{An original area variable column name. NULL uses the first variable.}
\item{time}{One period value, such as 2025. NULL uses the configured initial time,
or the latest supplied period if no initial time is set. Do not supply time
for a static area or edge table with no time column.}
\item{layers}{Network relationship layer names. NULL includes all supplied layers;
character(0) shows nodes without relationships. Colors remain stable across filters.}
\item{source}{For directed networks, one source node ID to show its outgoing ties.
NULL includes all sources, independently of the HTML initial_source control.}
\item{labels}{Whether to draw network node labels. All labels are drawn when TRUE;
automatic label repulsion is not implemented. Ignored for area maps.}
\item{node_size}{Positive fixed network node size in millimetres. Default 3.
Circle size does not encode degree or weight. Ignored for area maps.}
}
\details{
The result retains fixed numeric intervals, their lower-inclusive thresholds,
category order, colors, missing-value fill, legend aliases and optional counts.
Original values, IDs, labels, missing status and notes are available in the
plot's sf data. Missing values remain NA and are not converted to zero.
Unused categories stay in the legend. The source caption and interpretation
notice are included and may be edited with ggplot2::labs.

Add ordinary ggplot2 themes, labels and layers to the returned object. Use
ggplot2::ggsave to create PNG, PDF or SVG. SVG output with grDevices::svg uses
the Cairo device. A plot is one static snapshot; HTML search, playback,
selection, history charts and browser camera state do not carry into it.
Visible insets produce a warning and are omitted.

Networks preserve supplied node positions and all nodes, including isolates.
Schematic coordinates run downwards as in the HTML viewer. Geographic
networks use longitude and latitude, with neutral sf boundaries when supplied.
Network plots do not color boundaries by an area variable; leave variable NULL.
SVG illustrations are omitted with a warning. SVG-path-only boundaries must
be rebuilt with sf input. Automatic network layouts are not computed.

Relationship colors identify layers. Parallel and reciprocal ties have
separate curved paths. Geographic paths take the shorter longitude span and
split at the dateline; they are schematic connections, not geodesics or travel
routes. Directed networks have arrows along each line. Negative weights keep
their original direction and use dashed lines. Width encodes absolute weight,
with a fixed scale over all supplied periods and layers. Zero and unavailable
rows create no lines and remain distinct in the edge metadata. Relationships
between coincident positions are omitted with a warning. Nodes use equal-size
circles, unlike the browser's degree or flow sizing. All nodes remain visible
after source and layer filtering. Schematic illustrations and insets are not
included in static network figures.

The default display uses an equirectangular projection, the atlas regional
bounds if set, or longitude -180 to 180 and latitude -60 to 85 otherwise.
Holes, islands and dateline splitting use the same prepared sf geometry as
the HTML export. Changing coordinates with ggplot2::coord_sf is possible;
explicit limits and an appropriate default_crs may be needed.

set_legend titles, aliases, columns, visibility, notes, missing labels and
counts are honored. Legend positions above, below and sidebar map to top,
bottom and right. set_style fonts map to local sans, serif or mono graphics
device families. Exact font appearance depends on the rendering device.
The configured initial time is used when time is omitted. Other interactive
control configuration does not affect a static plot. In network plots,
legend titles, placement, columns, visibility and notes apply; area category
aliases and counts do not. Use ggplot2 color, linewidth and linetype scales
to customize the relationship legends.

Use \code{\link{set_preset}} before conversion for reusable compact or
presentation styling. Static legends otherwise use compact keys and text. Override them with ggplot2::theme
and ggplot2::guides. For example, use
\preformatted{p + ggplot2::guides(fill = ggplot2::guide_legend(
  title = NULL, ncol = 4, byrow = TRUE))}
to remove the legend title and arrange keys in four columns. Set legend.text,
legend.key.size and legend.position with ggplot2::theme. Numeric interval
labels such as "0 to <1,000" include zero and exclude 1,000, including decimal
values below that limit. The top interval uses a greater-than-or-equal symbol.
For PDF output with Unicode labels, use grDevices::cairo_pdf in ggsave.

Geometry is retained as an authoring-only attribute of the R atlas, once per
area. It is excluded from HTML and browser JSON payloads. saveRDS preserves it.
Objects created by earlier package versions or from SVG path tables must be
rebuilt with sf input. The original sf attribute table is not retained.
}
\value{A ggplot object. Area plots have sf data containing id, label, value,
status, notes, time, fill_key and geometry. fill_key identifies the fixed
legend class. Network plots have node data with id, label, original coordinates,
plot_x and plot_y. The offlineatlas_edges attribute contains the filtered edge
table, including original signed weights, zero and unavailable rows, provenance
when supplied, and a drawn flag. Route data are in the ggplot layers.}
\seealso{\code{\link{add_areas}}, \code{\link{set_legend}},
\code{\link{set_style}}, \code{\link{export_html}}}
\examples{
if (requireNamespace("sf", quietly = TRUE) &&
    requireNamespace("ggplot2", quietly = TRUE)) {
  world <- sf::st_read(example_file("world_sf.geojson"), quiet = TRUE)
  gdp <- example_data("worldbank_gdp")
  world$value <- gdp$gdp_per_capita[match(world$id, gdp$id)]
  m <- atlas("GDP per capita", units = "USD") |>
    add_areas(world, values = "value", breaks = list(c(1000, 10000, 40000)))
  p <- as_ggplot(m) + ggplot2::theme(legend.position = "bottom")
  stopifnot(inherits(p, "ggplot"))
  families <- example_data("florence_nodes")
  network <- atlas("Florentine marriages") |>
    add_nodes(families, id = "id", label = "label", layout_x = "x",
              layout_y = "y", coordinates = "schematic") |>
    add_edges(example_data("florence_edges"), from = "from", to = "to",
              layer = "layer")
  p <- as_ggplot(network, layers = "Marriage")
  stopifnot(nrow(p$data) == 16)
}
}
