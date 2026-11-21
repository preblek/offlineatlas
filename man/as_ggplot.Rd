\name{as_ggplot}
\alias{as_ggplot}
\title{Create an Editable Static Map or Network}
\description{Convert a geographic or schematic network, or one variable and period of an sf-backed area atlas, into
a regular ggplot object. ggplot2, sf, igraph and ggrepel are required authoring
dependencies installed with offlineatlas; saved figures and HTML viewers need no R packages.}
\usage{as_ggplot(x, variable = NULL, time = NULL, layers = NULL,
  source = NULL, labels = TRUE, node_size = 3,
  layout = c("existing", "fr", "kk", "circle"), seed = 1,
  repel = TRUE, node_size_by = NULL, node_fill_by = NULL,
  node_shape_by = NULL, node_fill = "#177b7b")}
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
\item{labels}{Whether to draw network node labels. Ignored for area maps.}
\item{node_size}{Positive fixed network node size in millimetres. Default 3.
Used when node_size_by is NULL. Ignored for area maps.}
\item{layout}{Keep existing node coordinates, or calculate an automatic fr, kk
or circle layout for a schematic network. Geographic coordinates stay fixed.
See \code{\link{layout_network}} for graph construction and layout definitions.}
\item{seed}{Nonnegative integer seed for layouts and label repulsion.}
\item{repel}{Use ggrepel to move static labels away from one another and node
symbols, with leader lines to their nodes. Default TRUE. FALSE uses simple
offset labels. This does not move nodes or change browser label behavior.}
\item{node_size_by}{Name of a retained nonnegative numeric node attribute or a
network metric. NULL uses fixed node_size. Scaled symbols range from 2 to 6 mm.}
\item{node_fill_by}{Name of a numeric or categorical node attribute or metric.
NULL uses the fixed node_fill color. Missing fills are gray.}
\item{node_shape_by}{Name of a categorical node attribute or component.
Up to five categories use filled symbols; missing categories use crosses.
NULL uses circles.}
\item{node_fill}{A fixed R color for nodes when node_fill_by is NULL.}
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

Networks preserve all nodes, including isolates. Supplied positions are used
unless layout requests an automatic arrangement.
Schematic coordinates run downwards as in the HTML viewer. Geographic
networks use longitude and latitude, with neutral sf boundaries when supplied.
Network plots do not color boundaries by an area variable; leave variable NULL.
SVG illustrations are omitted with a warning. SVG-path-only boundaries must
be rebuilt with sf input. Static automatic layouts use the full supplied
network across periods and layers, so filtering does not rearrange nodes.

With repel = TRUE, ggrepel attempts to avoid label overlaps at the output
device dimensions. Labels within the configured map bounds are not discarded
when crowded. Nodes outside regional bounds are not labeled. Very dense plots
may still need a larger figure, shorter labels or labels = FALSE. Fixed seeds
and iteration limits make repeated renders reproducible at the same dimensions
and library versions. Placement can change with figure dimensions and fonts.

Retain attributes with attributes in \code{\link{add_nodes}}. Computed network
metrics are degree (distinct partners regardless of direction), in_degree,
out_degree, strength (sum of known absolute incident weights), in_strength,
out_strength, unnormalized unweighted betweenness, and weakly connected
component. In undirected networks, incoming and outgoing metrics equal their
undirected counterparts. Metrics use the selected period, layers and source.
Degree and betweenness collapse repeated ties; strength sums layer-specific
records. In unweighted networks, strength counts layer-specific ties using
implicit unit weights. Observed negative weights contribute topology and absolute strength.
Zero and missing weights do not contribute topology. Betweenness ignores
weight magnitudes. These are measures of the supplied observed network,
not estimates of missing ties.

Strength includes known values only. All-missing incident records yield NA;
no supplied incident records yield zero known weight. The strength_partial,
in_strength_partial and out_strength_partial columns flag supplied missing
records. Original metric and attribute values retain NA. The drawing helper
uses minimum size for missing and zero size values so nodes remain visible.
Categorical fills and shapes retain factor levels. Numeric fills use a
diverging palette centered at zero when negative values are present.
Component identifiers are local to the selected network; they are not persistent
community labels across periods. Node styling scales are calculated for each plotted snapshot. Set fixed
ggplot2 scale limits yourself for comparisons across years or filters.
Use scale_size_continuous, scale_fill_manual or scale_fill_gradient, and
scale_shape_manual to override ranges, palettes, legend titles and limits.

Relationship colors identify layers. Parallel and reciprocal ties have
separate curved paths. Geographic paths take the shorter longitude span and
split at the dateline; they are schematic connections, not geodesics or travel
routes. Directed networks have arrows along each line. Negative weights keep
their original direction and use dashed lines. Width encodes absolute weight,
with a fixed scale over all supplied periods and layers. Zero and unavailable
rows create no lines and remain distinct in the edge metadata. Relationships
between coincident positions are omitted with a warning. Nodes default to
equal-size circles; the node mapping arguments enable other encodings. These
static styling choices do not change the browser's node styling. All nodes remain visible
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
plot_x and plot_y, retained attributes and computed metrics. Internal .node
columns are drawing helpers. The offlineatlas_layout attribute records an
automatic layout method and seed when used. The offlineatlas_edges attribute contains the filtered edge
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
  p <- as_ggplot(network, layers = "Marriage", layout = "fr", seed = 7,
                 node_size_by = "degree", node_fill_by = "component")
  stopifnot(nrow(p$data) == 16)
}
}
