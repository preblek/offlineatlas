\name{set_export_options}
\alias{set_export_options}
\title{Set Browser Figure Download Headings}
\description{Configure the titles and subtitles used by the viewer's SVG and
PNG downloads, and whether users can edit them before downloading.}
\usage{
set_export_options(x, title = NULL, subtitle = NULL, prompt = TRUE)
}
\arguments{
\item{x}{An atlas object.}
\item{title}{Figure title. NULL uses the atlas title; an empty string omits it.}
\item{subtitle}{Figure subtitle. NULL uses the atlas description, or the active
area variable and period if the description is empty. An empty string omits it.}
\item{prompt}{TRUE opens an editable heading dialog when downloading SVG or
PNG. FALSE downloads immediately using these defaults.}
}
\details{
Headings appear above the exported figure. Viewer edits apply only to image
downloads and are remembered for that browser session; they do not change the
atlas title, observations or downloaded JSON. The dialog accepts plain text.
Captions, legends, provenance and other visible figure components are retained.
All processing happens locally, without R, a server or an internet connection.
This function does not change ggplot titles, which can be edited with ggplot2::labs.
}
\value{An offline_atlas object.}
\examples{
m <- atlas("Study atlas") |>
  set_export_options(title = "Figure 1. Geographic variation",
    subtitle = "Amounts in 2025 dollars")
immediate <- set_export_options(m, title = "Study atlas", prompt = FALSE)
}
\seealso{\code{\link{export_html}}, \code{\link{as_ggplot}}}
