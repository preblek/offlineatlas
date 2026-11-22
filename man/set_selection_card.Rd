\name{set_selection_card}
\alias{set_selection_card}
\title{Configure the Selected Area Value Card}
\description{Show the selected area's active variable and value prominently
beside the map. The default is a visible card in the top right corner.}
\usage{
set_selection_card(x, visible = TRUE,
  position = c("top_right", "top_left", "bottom_right", "bottom_left"))
}
\arguments{
\item{x}{An atlas object.}
\item{visible}{Whether to show the card when exactly one area is selected.}
\item{position}{Corner of the map for the card.}
}
\details{
The card follows the active variable, selected area and period. On narrow
screens it appears below the map for readability. It is included in SVG and
PNG exports at the configured corner. It does not appear for multiple selected
areas or for networks. Static ggplot figures have no selection card.
}
\value{An offline_atlas object.}
\examples{
m <- atlas() |> set_selection_card(position = "bottom_left")
}
\seealso{\code{\link{set_number_format}}, \code{\link{set_export_options}}}
