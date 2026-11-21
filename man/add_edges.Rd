\name{add_edges}
\alias{add_edges}
\title{Add Relationships Between Nodes}
\description{Add unweighted ties or weighted flows between nodes already in an atlas.}
\usage{
add_edges(x, data, from, to, weight = NULL, time = NULL,
          layer = NULL, directed = FALSE,
          coverage = c("edge_list", "observed_rows", "complete_panel"),
          signed = FALSE, provenance = NULL)
}
\arguments{
\item{x}{An atlas object.}
\item{data}{A data frame containing relationship endpoints and optional attributes.}
\item{from}{Column names containing relationship endpoint identifiers.}
\item{to}{Column names containing relationship endpoint identifiers.}
\item{weight}{Optional numeric weight column. Finite values and NA are supported.
Negative values require signed = TRUE. NA and zero remain distinct.}
\item{time}{Optional column name for discrete, nonmissing time values. The viewer uses numeric-aware text sorting.}
\item{layer}{Optional column name for nonempty relationship types, such as Marriage or Business.}
\item{directed}{Whether relationships have a direction.}
\item{coverage}{An unweighted edge list, observed rows without inferred
zeros, or a complete directed source-target-time-layer panel. The latter
requires every combination except self-links, with explicit NA rows for
unavailable observations. This contract is based on the IDs and times supplied.}
\item{signed}{Allow signed weights. Line color and dash encode sign. Arrow
direction is preserved, circle area uses absolute incoming flows, and totals
retain signs. Signed mode uses sign styling instead of source/layer styling.}
\item{provenance}{Optional column name for per-row reporting provenance,
retained in the inspector, table, CSV, and JSON.}
}
\details{
Each layer can be added once. Nodes must precede relationships. Self-links,
and duplicate relationships are rejected in this prototype. Signed weights
require explicit opt-in.
Multiple relationship types between the same endpoints are allowed.
Distinct-partner degree uses enabled layers. Selection highlights incident
relationships without redefining the degree population.

Weighted data require coverage = "observed_rows" or "complete_panel".
For observed rows, an absent pair is not inferred to have a zero value.
Complete panels require directed = TRUE and a time column. The expected
roster is the Cartesian product of the distinct source IDs, target IDs,
times and layers occurring in the supplied relationship table, excluding
self-links. It is not inferred from all node IDs. Supply explicit NA rows
for unavailable observations. Undirected duplicates include reversed pairs
within the same time and layer.

Zero and missing weighted rows remain in data exports but draw no lines.
Signed weights preserve arrow direction; negative lines are dashed amber and
positive lines solid teal. Node circle areas use absolute incoming flows;
totals retain signs. Source, year and enabled layers affect network totals;
node focus highlights incident relationships.
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
ties <- example_data("florence_edges")
m <- add_edges(m, ties, "from", "to", layer = "layer")

# An observed signed flow table, without inferred zeros.
places <- data.frame(id = c("Paris", "Rome"),
                     lon = c(2.35, 12.50), lat = c(48.86, 41.90))
m <- atlas("Places") |>
  add_nodes(places, "id", longitude = "lon", latitude = "lat")
flows <- data.frame(from = "Paris", to = "Rome", amount = -5)
flows_map <- add_edges(m, flows, "from", "to", weight = "amount",
                       directed = TRUE, signed = TRUE,
                       coverage = "observed_rows")
}
