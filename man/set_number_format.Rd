\name{set_number_format}
\alias{set_number_format}
\title{Format Numeric Values and Currency}
\description{Choose decimal places and optional currency symbols without
rounding or changing stored observations.}
\usage{
set_number_format(x, style = c("number", "currency"), currency = "USD",
                  digits = NULL, variable = NULL)
}
\arguments{
\item{x}{An atlas object.}
\item{style}{Number or currency display.}
\item{currency}{Three-letter uppercase currency code, such as USD, EUR or GBP.
USD uses a leading dollar sign. This does not convert currencies.}
\item{digits}{Fixed decimal places, 0 to 6. NULL uses two fixed places for
currency, or the original up-to-two-decimal display for numbers.}
\item{variable}{NULL for all numeric area variables, or selected source column
names. Omit for networks, where the format applies to weights and totals.}
}
\details{
Currency formatting displays amounts such as $150.50. Full values in area
details, tooltips, cards, tables and history use the specified decimals.
Compact ranking and chart-axis labels retain abbreviated amounts such as $1.5M.
Numeric area legend labels and static area legends use the same format;
explicit labels supplied to set_legend remain authoritative. Static network
weight legends also honor this setting. Static currency symbols include USD,
EUR, GBP, JPY, CAD and AUD; other codes are shown as a prefix.
Numeric observations and CSV and JSON downloads retain their original values.
Keep the measurement scale in units or captions, for example USD millions or
2025 USD. Formatting does not adjust for inflation or change the scale.
}
\value{An offline_atlas object.}
\examples{
a <- example_data("world_paths")[1:2, ]
a$penalty <- c(0, 150.5)
m <- atlas(units = "2025 USD") |>
  add_areas(a, values = "penalty", breaks = list(c(100, 1000)))
formatted <- set_number_format(m, style = "currency", currency = "USD")
}
\seealso{\code{\link{set_palette}}, \code{\link{set_legend}}}
