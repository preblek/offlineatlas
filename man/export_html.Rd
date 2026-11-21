\name{export_html}
\alias{export_html}
\title{Export a Standalone Offline Atlas}
\description{Write one HTML file containing the atlas data, geometry, scripts, styles and artwork.}
\usage{
export_html(x, file, overwrite = FALSE)
}
\arguments{
\item{x}{An atlas object.}
\item{file}{Output HTML filename. Parent directories are created if needed.}
\item{overwrite}{Allow replacement of an existing output file. Defaults to FALSE.}
}
\details{
Search narrows the selection list and rankings without changing the map,
statistics, or exports. Clear focus restores all entities while preserving
filters, layout, and zoom. SVG and PNG captions identify the enabled layers,
source, year, background, and selected entities. Selection uses an outer ring
without changing the zero or unavailable symbols. The interactive legend uses
readable HTML; exported figures contain a vector legend from the same model.

HTML exports include a content security policy that prevents network access.
SVG and PNG downloads preserve the current visible view. CSV downloads follow
the current filters and selection; JSON downloads include all embedded data.
CSV strings beginning with spreadsheet formula characters are prefixed with
an apostrophe. JSON preserves their original text.

Add at least areas or nodes before exporting. The output can be copied by
itself and opened directly in a browser without R, a server or internet.
All supplied periods and mapped data remain embedded, even when controls are
hidden. Hiding controls is not a method for removing data from an export.
Authoring-only sf geometry attributes are excluded from the HTML payload.

Image and CSV exports pause timeline playback and identify the selected
period. A visible numeric area history chart and geographic inset are included
in image downloads. History CSV contains every period for the selected area;
view CSV follows the current period and selection. JSON retains original
prepared coordinates, even if schematic nodes have been dragged in the viewer.
Sources and notices accompany downloads. Re-export from R to incorporate
new source data; the HTML never refreshes from an online service.
}
\value{The normalized output path, invisibly. The HTML file is written to disk.}
\seealso{\code{\link{atlas}}, \code{\link{add_areas}}, \code{\link{add_edges}}, \code{\link{as_ggplot}}.

For the tutorial, see the \code{\link{offlineatlas}} package overview.}
\examples{
families <- example_data("florence_nodes")
m <- atlas("Florentine families") |>
  add_nodes(families, "id", "label", layout_x = "x", layout_y = "y",
            coordinates = "schematic")
m <- add_edges(m, example_data("florence_edges"), "from", "to",
               layer = "layer")
file <- tempfile(fileext = ".html")
export_html(m, file)
stopifnot(file.exists(file))
unlink(file)
}
