\name{set_legend}
\alias{set_legend}
\title{Customize Legends and Display Labels}
\description{Set the legend title, placement, columns, explanatory note and area display aliases.}
\usage{
set_legend(x, title = "Reading this view",
           position = c("below", "above", "sidebar"),
           columns = NULL, visible = TRUE, show_counts = TRUE,
           note = NULL, labels = NULL, missing_label = "Unavailable or unmatched",
           type = c("boxes", "bar"))
}
\arguments{
\item{x}{An atlas object.}
\item{title}{Plain-text legend title.}
\item{position}{Legend location: below, above, or sidebar.}
\item{columns}{NULL for responsive legend columns, or an integer from 1 to 4.
Narrow screens and sidebar legends collapse to one column. Figure exports use
the specified number, or three by default.}
\item{visible}{Show legend keys and explanation in the viewer and image exports.}
\item{show_counts}{Include current-period counts in categorical legend labels.}
\item{note}{Optional legend explanation. NULL retains the generated explanation;
an empty string suppresses it. Captions, source attribution and notices remain.}
\item{labels}{NULL or a named list keyed by original area variable column, with one display label per interval or category. Missing labels are configured separately.}
\item{missing_label}{Legend wording for unavailable or unmatched areas.}
\item{type}{Separate boxes (default), or a compact bar for numeric area maps.
The bar uses adjoining, equal-width color bands for the configured intervals,
with threshold ticks. Its width is not a linear numeric scale. Zero and missing
keys stay separate. Categorical and network legends retain their ordinary keys.}
}
\details{
Legend labels affect display only; original values and category names remain
unchanged. Bar legends work in HTML, browser SVG/PNG downloads and static area
figures. They do not interpolate colors or change interval thresholds. Explicit
interval labels appear at band centers instead of threshold ticks.

Numeric label vectors follow interval order; category labels
follow declared category order. Their lengths and variable names are checked
at export, so presentation may be configured before adding data. For network
legends, relationship names come from the supplied layer column. Custom legend
text and fonts are preserved in SVG and PNG. Placement affects the HTML layout;
exported legend keys follow the map and optional history chart. Configuration
functions replace their own options using the supplied arguments and defaults.
These settings contain plain text and enumerated choices, not arbitrary CSS,
HTML, or JavaScript. All configuration is embedded in the standalone export.

Hiding a legend retains source attribution and export captions. A custom note
replaces the automatic explanation, so keep any information needed to interpret
symbols. The static area adapter honors these options where applicable.
}
\value{An \code{offline_atlas} object, suitable for piping into another
configuration function or \code{\link{export_html}}.}
\seealso{\code{\link{add_areas}}, \code{\link{set_controls}}, \code{\link{set_style}}, \code{\link{as_ggplot}}.

For the tutorial, see the \code{\link{offlineatlas}} package overview.}
\examples{
m <- atlas("Custom legend") |>
  set_legend(title = "How to read this map", position = "below",
             columns = 2, missing_label = "No observation")
}
