\name{summary.offline_atlas}
\alias{summary.offline_atlas}
\alias{print.summary_offline_atlas}
\title{Inspect Atlas Coverage and Observation Counts}
\description{Summarize supplied areas and relationships before exporting.
Return inspectable tables without changing the atlas or inferring absent rows.}
\usage{
\method{summary}{offline_atlas}(object, ...)
\method{print}{summary_offline_atlas}(x, ..., max_rows = 12L)
}
\arguments{
\item{object}{An offline_atlas object.}
\item{x}{The result of summary on an atlas.}
\item{...}{Reserved for method compatibility; currently unused.}
\item{max_rows}{Positive integer limiting printed rows per table and listed
periods. All rows remain available in the returned object.}
}
\details{
Area counts are grouped by original variable and period. Static records have
NA in the time column. Periods sort numerically when all can be read as finite
numbers, and otherwise lexically. A multi-variable panel counts each area-period
once in area_observations; each variable has its own diagnostic table rows.

Missing is the total number of NA values. Unmatched counts areas flagged
matched = FALSE. Unavailable counts NA values in matched areas. Thus missing
equals unmatched plus unavailable; these columns are not three disjoint groups.
Observed counts nonmissing values. Negative, zero and positive counts apply
only to numeric variables and weighted relationships. They are NA for categories
and unweighted ties, whose implicit unit weights are not measurements.

Category counts retain original category names and all declared levels,
including unused levels with zero observations. Missing categories appear in
the areas table, not as a fabricated category. Relationships are grouped by
supplied period and layer. Their endpoints were validated when added, so area
matching diagnostics do not apply. Omitted observed pairs are not counted as
zero or missing. A summary cannot report source rows that were discarded before
constructing the atlas, or identify which periods ought to have been supplied.

The summary uses all supplied periods and data, regardless of initial browser
filters or legend aliases. It performs no download or geometry conversion.
}
\value{A summary_offline_atlas list containing title, coordinates, entities
(unique node and area counts and relationship row count), periods, weighted,
directed, coverage, area_observations, areas, categories, relationships, view,
and preset. The three diagnostic tables are data frames, including when empty.
The print method returns its input invisibly.}
\seealso{\code{\link{add_areas}}, \code{\link{add_edges}},
\code{\link{export_html}}}
\examples{
shapes <- example_data("world_paths")[1:3, ]
shapes$value <- c(-2, 0, NA_real_)
shapes$matched <- c(TRUE, TRUE, FALSE)
x <- atlas("Coverage example") |>
  add_areas(shapes, values = "value", matched = "matched",
            breaks = list(c(0, 10)))
audit <- summary(x)
audit$areas
print(audit, max_rows = 3)
}
