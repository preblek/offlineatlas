\name{set_preset}
\alias{set_preset}
\title{Apply a Reusable Presentation Preset}
\description{Choose compact or presentation styling for the browser viewer
and static area figures, without altering data or classification.}
\usage{
set_preset(x, preset = c("compact", "presentation"))
}
\arguments{
\item{x}{An offline_atlas object.}
\item{preset}{A named preset. Compact favors small keys and concise layouts;
presentation uses larger text and keys for display.}
}
\details{
Both presets choose local sans-serif body and heading fonts, put the legend
below the map, and clear an explicit legend column count. Compact places the
browser toolbar directly above the map; presentation places it at the top.
Browser styling is embedded CSS with responsive layouts, not external assets.

Presets preserve title text, source notes, units, category and interval labels,
legend visibility and counts, control labels and visibility, initial time,
initial source, playback interval, geometry and data. Only the layout and font
fields described above are replaced. Use a preset before further configuration.
Later calls to set_controls, set_legend or set_style can override it, following
those functions' documented replacement behavior.

In as_ggplot, compact uses 8-point legend text and small keys; presentation
uses 11-point text and larger keys. Unless an explicit column count is set,
compact uses up to four columns for short numeric labels and three for
categorical or longer labels. Presentation uses up to three. A sidebar legend
uses one column by default. Custom legend titles are preserved; when no title
was configured, presets omit the automatic legend title. Categories, colors,
cutpoints, missing labels and data are unchanged.

Presets do not choose an export file size, change projection or crop geometry.
Use ggsave width and height for the intended medium. Typical compact examples
use nine-inch widths and heights near 5.3 inches for a world map or 7 inches
for Europe. Long captions or category labels may need further adjustment.
Any ordinary ggplot2 theme, guide or label adjustment can be added afterwards.
}
\value{An offline_atlas object with the selected presentation settings.}
\seealso{\code{\link{set_legend}}, \code{\link{set_controls}},
\code{\link{set_style}}, \code{\link{as_ggplot}}}
\examples{
x <- atlas("Compact atlas") |>
  set_controls(initial_time = "2025", labels = c(play = "Animate")) |>
  set_preset("compact")
stopifnot(x$controls$initial_time == "2025")
x <- set_legend(x, columns = 2)
}
