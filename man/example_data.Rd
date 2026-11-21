\name{example_data}
\alias{example_data}
\title{Read a Bundled Example Table}
\description{Read an installed CSV fixture as a data frame without downloading data.}
\usage{
example_data(name)
}
\arguments{
\item{name}{CSV basename without the .csv extension.}
}
\details{
Available tables are aid, aid_nodes, florence_nodes, florence_edges,
world_paths, worldbank_gdp, fdi_national, fdi_nodes, fdi_bilateral and
eu_membership. Use names without the .csv extension.

Aid data are fictional. Florence positions are schematic and ties describe
a teaching subset with marriage and business layers. GDP values describe 2024
in current US dollars. National FDI contains 1990--2025 inward flows; the
bilateral fixture is a separate nine-country 2020--2024 sample, not national
totals. EU membership records supply accession dates for timeline construction.
Prepared world paths are in the renderer's fixed projection.

Inspect column names and source metadata before joining. Identifiers join
exactly; historical economies are not automatically reassigned to successors.
Natural Earth boundaries are public domain, World Bank indicators retain
CC BY 4.0 attribution, and Florence data retain ODbL/DbCL notices. Bundled
metadata and notice files are accessible with \code{\link{example_file}}.
The source snapshots do not update when this function is called.
}
\value{A data frame with the bundled table columns.}
\seealso{\code{\link{example_file}}, \code{\link{add_nodes}}, \code{\link{add_edges}}, \code{\link{add_areas}}.

For the tutorial, see the \code{\link{offlineatlas}} package overview.}
\examples{
families <- example_data("florence_nodes")
names(families)
head(families)
}
