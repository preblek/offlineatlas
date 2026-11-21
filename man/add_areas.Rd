\name{add_areas}
\alias{add_areas}
\title{Add Numeric or Categorical Area Maps}
\description{Add geographic polygons with optional variables and discrete time periods.
Numeric values use fixed intervals; categorical values use declared levels.}
\usage{
add_areas(x, data, id = "id", path = "path", label = id,
          values = character(), labels = values, breaks = NULL,
          matched = NULL, colors = NULL, categories = NULL,
          time = NULL, notes = NULL)
}
\arguments{
\item{x}{An atlas object.}
\item{data}{An sf POLYGON or MULTIPOLYGON object, or a data frame with prepared SVG paths. Only mapped attributes are retained.}
\item{id}{Column name for stable area identifiers, unique within each period.}
\item{path}{Column name with SVG path strings for data-frame input.
For sf input, paths are generated from geometry and this argument is ignored.
Bundled world paths are available through example_data.}
\item{label}{Column name for nonempty area labels. Defaults to id.}
\item{values}{Column names to expose in the area variable selector. Numeric
columns use breaks; text or factor columns require categories.}
\item{labels}{Character vector of display labels, one per column in values.}
\item{breaks}{One list entry per variable, containing 1 to 5 finite, strictly
increasing interval boundaries for numeric variables, or NULL for categorical
variables. Intervals are lower-inclusive. Omit for an entirely categorical map.}
\item{matched}{Optional name of a logical column indicating whether each area
matched a source dataset record. FALSE requires NA for every supplied value.
This distinguishes an unmatched area from a matched record with an unavailable
observation in the inspector, CSV, and JSON. Defaults to all matched.}
\item{colors}{Optional list of six-digit hex color vectors, one per area
variable and one color per interval or category. Numeric variables default to
the sequential palette. Categorical variables require an explicit palette.}
\item{categories}{Optional list with one entry per area variable. NULL entries
identify numeric variables; character vectors give the complete ordered levels
for categorical variables. Unknown categories are rejected; NA is allowed.}
\item{time}{Optional column name for discrete, nonmissing periods. Omit for a static map.}
\item{notes}{Optional area column containing text with no missing values,
shown in country details and retained in CSV and JSON.}
}
\details{
The geographic projection is equirectangular with
x = 30 + (longitude + 180) / 360 * 940 and
y = 92 + (85 - latitude) / 145 * 380.
Data-frame area paths must use that same coordinate system. sf inputs must
declare their actual source CRS. They are transformed to OGC:CRS84 longitude
and latitude, then converted to the fixed display projection. Projected input
is supported; arbitrary display projections are not. Islands and holes remain
in one area record, using even-odd SVG fill. Dateline-crossing polygons are
split at +/-180 degrees. No automatic simplification is applied; coordinates
are serialized to six decimal places in SVG units.

The sf adapter rejects empty shapes, non-finite coordinates, Z/M dimensions,
unsupported geometry types, invalid polygons, and geometry outside the
supported latitude extent. It does not guess a CRS, repair invalid geometry,
create centroids, or drop features silently. Repairs or clipping must be
performed explicitly before calling add_areas or add_nodes. Validation uses
planar GEOS after dateline splitting and does not change sf_use_s2(). Source
CRS and preparation metadata are retained in the prepared object and JSON.

sf is an optional authoring dependency. The GDP and FDI examples use it;
data-frame workflows and exported HTML viewers do not require it. The
world_sf.geojson fixture contains 176 Natural Earth features, with explicit
USA and Sudan repairs recorded in world_sf_metadata.json. Identifiers join
exactly; no fuzzy matching is performed. Join attributes to shapes by their
identifiers before mapping, and use matched to flag unmatched records.

Area time series require one row per ID and period, with the same complete ID
roster, geometry, and labels in every period. Supply explicit NA values for
missing observations. Only values, matched status, and notes vary over time.
Geometry is embedded once. Fixed numeric breaks and categorical colors apply
to every period. Previous, next, and play controls operate entirely in the
browser. Playback advances through observations at equal intervals, with no
interpolation between periods. Exports pause playback and identify the selected
period; JSON retains all periods. Selecting one area in a numeric series
shows its history, with a fixed per-country vertical scale including zero.
Missing observations break the line. The accessible history table and history
CSV retain all periods and notes. SVG and PNG include the visible history chart.
Categorical variables do not show a numeric trend chart.


Add areas only once. IDs are unique in a static table, or unique within each
period in a time series. Labels need not be unique but must be nonempty.
A blank geographic background can omit values. For mixed numeric and
categorical variables, supply lists in values order, using NULL for numeric
categories and categorical breaks. Exact cutpoints belong to the higher
interval: breaks = list(c(0, 10)) gives values below 0, from 0 to below 10,
and 10 or greater. NA is separate from every interval, including zero.

For a regional camera, use \code{\link{set_view}}. An sf-backed area atlas
can be converted to a static plot with \code{\link{as_ggplot}}.
}
\value{An \code{offline_atlas} object, suitable for piping into another
configuration function or \code{\link{export_html}}.}
\seealso{\code{\link{atlas}}, \code{\link{set_view}}, \code{\link{set_inset}}, \code{\link{set_legend}}, \code{\link{as_ggplot}}.

For the tutorial, see the \code{\link{offlineatlas}} package overview.}
\examples{
if (requireNamespace("sf", quietly = TRUE)) {
  world <- sf::st_read(example_file("world_sf.geojson"), quiet = TRUE)
  gdp <- example_data("worldbank_gdp")
  joined <- match(world$id, gdp$id)
  world$gdp <- gdp$gdp_per_capita[joined]
  world$matched <- !is.na(joined)
  m <- atlas("GDP per capita in 2024", units = "USD") |>
    add_areas(world, label = "label", values = "gdp", matched = "matched",
              breaks = list(c(1000, 5000, 15000, 40000, 80000)))
}

# Categorical data can also use the bundled prepared SVG paths.
shapes <- example_data("world_paths")
shapes$group <- ifelse(shapes$id == "ITA", "Highlighted", "Other")
m <- atlas("Italy") |>
  add_areas(shapes, values = "group",
            categories = list(c("Highlighted", "Other")),
            colors = list(c("#176f70", "#e1e5e1")))
}
