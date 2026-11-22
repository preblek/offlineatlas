library(offlineatlas)
# Reuse the existing regional example, then change its appearance only.
source(system.file("examples", "regional.R", package="offlineatlas"), local=TRUE)
blue_region <- regional |>
  set_palette(c("#6BAED6", "#3182BD", "#08519C"),
    zero_color="#E6E6E6", missing_color="#FFFFFF",
    border_color="#000000", border_width=0.6) |>
  set_number_format(style="currency", currency="USD") |>
  set_legend(type="bar", title="GDP per capita") |>
  set_selection_card(position="top_right") |>
  set_export_options(subtitle="GDP per capita, current US dollars")
export_html(blue_region, "regional-blue.html", compress=TRUE, overwrite=TRUE)
# regional is still available with its original presentation.
