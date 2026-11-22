\name{offlineatlas}
\alias{offlineatlas}
\alias{offlineatlas-package}
\docType{package}
\title{Standalone Offline Maps and Networks}
\description{Create geographic area maps, geographic networks and schematic
networks in R, then share them as a single offline HTML file. The viewer
requires no R installation, server, API key or internet connection.}
\details{
Start with \code{\link{atlas}}. Add geographic variables with
\code{\link{add_areas}}, or entities and connections with
\code{\link{add_nodes}} and \code{\link{add_edges}}.
Finish with \code{\link{export_html}}.

The API is experimental. sf, ggplot2, igraph and ggrepel are required authoring dependencies.
The installer includes them automatically when missing. sf handles
polygon and point inputs; ggplot2 creates editable static area maps and networks through
\code{\link{as_ggplot}}. igraph supplies layouts and network measures;
ggrepel places static labels. Saved HTML and image files require no R packages.
Installing authoring dependencies may need internet access. Preparing the
bundled examples and viewing their exports use local resources.
}
\section{Getting started}{
Read the installed tutorial with
\code{vignette("getting-started", package = "offlineatlas")}.
It covers a GDP map, Florence marriages, an FDI timeline, presentation
options, and static figures. \code{\link{example_data}} reads bundled tables;
\code{\link{example_file}} locates local assets and notices.
}
\section{Presentation}{
Use \code{\link{set_view}} for explicit or automatic regional framing.
Choose \code{\link{set_preset}} for compact or presentation defaults.
Add one geographic detail panel with \code{\link{set_inset}}.
Use \code{\link{set_background}} for a schematic illustration.
\code{\link{set_controls}}, \code{\link{set_legend}} and
\code{\link{set_style}} customize the viewer from R.
Use \code{\link{set_palette}} to recolor existing area maps without rebuilding
their data or geometry, and \code{\link{set_number_format}} for decimal places
and currency. \code{\link{set_selection_card}} configures the selected area
card; \code{\link{set_export_options}} supplies browser download headings.
Most configuration functions replace their own settings using supplied arguments
and defaults. set_palette preserves omitted appearance settings.
}
\section{Time and missing data}{
Use \code{\link{summary.offline_atlas}} through summary(x) to inspect
coverage, missing values and numeric sign counts before export.
Area panels use fixed geometry and labels, with one row per area and period.
Numeric breaks and categorical colors stay fixed across periods. Explicit NA,
zero and negative observations remain distinct. See \code{\link{add_areas}}
for panel requirements and \code{\link{add_edges}} for network coverage rules.
Playback, selection and numeric country histories run in the browser.
}
\section{Current limits}{
HTML maps use one equirectangular display projection, with longitude -180 to
180 and latitude -60 to 85. Regional framing does not change projection.
One rectangular geographic inset is supported. Schematic layouts can be
supplied or computed with \code{\link{layout_network}}. Self-links, changing historical boundaries
and synchronized map/network panels are not implemented. Large-data
performance is unmeasured. Static ggplot output supports sf area maps and
networks, without insets or SVG illustrations. Automatic label placement is
best-effort; crowded figures may need more space. Read source notes
and preserve dataset attribution.
}
\seealso{\code{\link{atlas}}, \code{\link{export_html}},
\code{\link{as_ggplot}}}
\keyword{package}
