\name{example_file}
\alias{example_file}
\title{Locate a Bundled Example Asset}
\description{Return the local path to a bundled boundary, illustration, metadata file or data table.}
\usage{
example_file(name)
}
\arguments{
\item{name}{Exact bundled filename, including its extension. Missing files produce an error.}
}
\details{
Assets live in the installed package extdata directory. Examples include
\itemize{
\item \file{world_sf.geojson} and \file{europe_sf.geojson} boundaries.
\item The \file{florence.svg} schematic illustration.
\item \file{WORLD-NOTICE.txt} and \file{FLORENCE-NOTICE.txt} source notices.
}
Metadata JSON files record source preparation and attribution. Paths refer
to local files; no download is performed.

Read boundaries with sf::st_read.
Use \code{\link{set_background}} for illustrations.
Read CSV tables with \code{\link{example_data}}.
Complete runnable scripts live separately in the installed examples directory;
locate them with
\preformatted{system.file("examples", "gdp.R", package = "offlineatlas")}
Do not write into the installed package directory.
}
\value{A local filename as a character string.}
\seealso{\code{\link{example_data}}, \code{\link{add_areas}}, \code{\link{set_background}}.

For the tutorial, see the \code{\link{offlineatlas}} package overview.}
\examples{
path <- example_file("world_sf.geojson")
stopifnot(file.exists(path))
}
