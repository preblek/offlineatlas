\name{atlas}
\alias{atlas}
\title{Create an Empty Atlas}
\description{Start an atlas with a title, explanatory text, units and source attribution.
Add areas or nodes and relationships before exporting it.}
\usage{
atlas(title = "Offline atlas", description = "", notice = "",
      sources = character(), units = "",
      entity_name = "entity", entity_names = "entities")
}
\arguments{
\item{title}{Plain text for the atlas title.}
\item{description}{Plain text for the introductory explanation.}
\item{notice}{Plain text for the interpretation notice.}
\item{sources}{Character vector of source and attribution text. URLs remain
plain text and do not load external resources.}
\item{units}{Plain text for the numeric units.}
\item{entity_name}{Singular entity term, such as family or country, used in
search, selection instructions and figure captions.}
\item{entity_names}{Plural entity term, such as families or countries.}
}
\details{
Metadata are plain text. Columns are mapped by quoted names in the layer
functions. Areas, nodes and relationships can each be added once. Add nodes
before relationships. Geographic areas can be combined with geographic nodes;
schematic nodes cannot be combined with geographic areas.

R prepares the atlas. The exported HTML embeds its data, geometry, JavaScript,
CSS and optional illustration. Viewing it requires no R installation, server,
API key or internet connection. The API is experimental.
}
\value{An \code{offline_atlas} object, suitable for piping into another
configuration function or \code{\link{export_html}}.}
\seealso{\code{\link{add_areas}}, \code{\link{add_nodes}}, \code{\link{add_edges}}, \code{\link{export_html}}.

For the tutorial, see the \code{\link{offlineatlas}} package overview.}
\examples{
m <- atlas("My atlas", description = "A small research example",
           units = "USD", entity_name = "country", entity_names = "countries")
print(m)
}
