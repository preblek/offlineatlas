\name{set_palette}
\alias{set_palette}
\title{Change Area Colors Without Rebuilding an Atlas}
\description{Change palettes, zero and missing colors, and polygon boundaries
on an existing atlas. Data, geometry, periods and other settings are preserved.}
\usage{
set_palette(x, colors = NULL, variable = NULL, zero_color = NULL,
            missing_color = NULL, border_color = NULL, border_width = NULL,
            zero_label = "Recorded zero")
}
\arguments{
\item{x}{An atlas with area variables.}
\item{colors}{NULL to keep existing palettes, or a character vector of six-digit
hex colors, one per interval or category. The same vector is applied to each
selected variable, so they must have the same number of classes.}
\item{variable}{NULL for all numeric area variables, or a character vector of
source column names. Select categorical variables explicitly.}
\item{zero_color}{A six-digit hex color for exactly zero, separate from numeric
intervals. Omit to keep the current setting; explicitly pass NULL to restore
ordinary interval coloring. Only for numeric variables.}
\item{missing_color}{A six-digit hex color for missing or unmatched values.
Omit to keep the setting; explicitly pass NULL to restore the default.}
\item{border_color}{A six-digit hex color for all area boundaries. Omit to keep
the setting; explicitly pass NULL to restore white boundaries. The selected
area still has an orange outline.}
\item{border_width}{Boundary width from 0 to 10, in SVG pixels, held constant
during zoom. Static figures use one quarter of this value in millimetres.
Omit to keep the setting; NULL restores the default.}
\item{zero_label}{Legend text for a separate zero key. Defaults to Recorded zero
when setting zero_color. Omit in later calls to keep an existing label.}
}
\details{
These settings apply to HTML, browser figure downloads and static area plots.
Zero coloring does not change thresholds or observations. The interval that
contains zero is labeled as excluding zero when a separate zero color is used.
Choose a different missing color so unavailable data cannot be mistaken for zero.
Calling this function does not modify the original object unless you assign
the result back to its name. It does not recolor network nodes or edges.
}
\value{An offline_atlas object.}
\examples{
a <- example_data("world_paths")[1:3, ]
a$value <- c(0, 150.5, NA_real_)
m <- atlas() |> add_areas(a, values = "value", breaks = list(c(100, 1000)))
blue <- set_palette(m, c("#6BAED6", "#3182BD", "#08519C"),
  zero_color = "#E6E6E6", missing_color = "#FFFFFF",
  border_color = "#000000", border_width = 0.6)
}
\seealso{\code{\link{add_areas}}, \code{\link{set_number_format}}}
