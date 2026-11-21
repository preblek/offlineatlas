\name{as_ggplot}
\alias{as_ggplot}
\title{Create an Editable Static Area Map}
\description{Convert one variable and period of an sf-backed area atlas into
a regular ggplot object. ggplot2 and sf are required authoring dependencies installed with offlineatlas;
saved figures and HTML viewers need neither package.}
\usage{as_ggplot(x, variable = NULL, time = NULL)}
\arguments{
\item{x}{An offline_atlas object created with sf polygon input to add_areas.}
\item{variable}{An original area variable column name. NULL uses the first variable.}
\item{time}{One period value, such as 2025. NULL uses the configured initial time,
or the latest supplied period if no initial time is set. Do not supply time
for a static area table with no time column.}
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
Visible insets produce a warning and are omitted. Networks are not supported
by this initial adapter and produce an error.

The default display uses an equirectangular projection, the atlas regional
bounds if set, or longitude -180 to 180 and latitude -60 to 85 otherwise.
Holes, islands and dateline splitting use the same prepared sf geometry as
the HTML export. Changing coordinates with ggplot2::coord_sf is possible;
explicit limits and an appropriate default_crs may be needed.

set_legend titles, aliases, columns, visibility, notes, missing labels and
counts are honored. Legend positions above, below and sidebar map to top,
bottom and right. set_style fonts map to local sans, serif or mono graphics
device families. Exact font appearance depends on the rendering device.
Interactive control configuration does not affect a static plot.

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
\value{A ggplot object with sf data containing id, label, value, status,
notes, time, fill_key and geometry. fill_key identifies the fixed legend class.}
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
}
}
