\name{set_style}
\alias{set_style}
\title{Choose Local Fonts}
\description{Select local font families for body text, exported figures and HTML headings.}
\usage{
set_style(x, font_family = c("system", "sans", "serif", "mono"),
          heading_family = c("serif", "system", "sans", "mono"))
}
\arguments{
\item{x}{An atlas object.}
\item{font_family}{Local family for body and figure text.}
\item{heading_family}{Local family for HTML headings.}
}
\details{
Choices are system, sans (Arial/Helvetica), serif (Georgia), and mono.
No fonts are downloaded or embedded, so exact appearance depends on fonts
installed on the viewing computer. Body and figure text use font_family;
HTML headings use heading_family. \code{\link{as_ggplot}} maps choices to
local graphics-device sans, serif or mono families. This function replaces
both font settings; unspecified arguments return to their defaults.
}
\value{An \code{offline_atlas} object, suitable for piping into another
configuration function or \code{\link{export_html}}.}
\seealso{\code{\link{set_controls}}, \code{\link{set_legend}}, \code{\link{as_ggplot}}.

For the tutorial, see the \code{\link{offlineatlas}} package overview.}
\examples{
m <- atlas("Local typography") |>
  set_style(font_family = "sans", heading_family = "sans")
}
