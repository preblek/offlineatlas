library(offlineatlas)
library(ggplot2)
dir.create("static", showWarnings = FALSE)

# Build the schematic example without a browser illustration.
florence <- atlas("Marriage alliances in Florence",
  notice = "Teaching subset. Family positions are schematic, not historical residences.",
  sources = "Padgett / CoMuNe Lab data (ODbL 1.0; DbCL 1.0).") |>
  add_nodes(example_data("florence_nodes"), id = "id", label = "label",
    layout_x = "x", layout_y = "y", coordinates = "schematic") |>
  add_edges(example_data("florence_edges"), from = "from", to = "to", layer = "layer") |>
  set_preset("compact")
source(system.file("examples", "aid.R", package = "offlineatlas"), local = TRUE)
network_plots <- list(
  florence_marriages = as_ggplot(florence, layers = "Marriage"),
  florence_layers = as_ggplot(florence) + labs(title = "Relationships in Renaissance Florence"),
  aid_2024 = as_ggplot(set_preset(aid_atlas, "compact"), time = 2024, source = "CAN", labels = FALSE) +
    labs(title = "Canada's fictional aid relationships in 2024")
)
# Add selected labels using the returned node table to avoid a crowded region.
aid_plot <- network_plots$aid_2024
label_nodes <- aid_plot$data[aid_plot$data$id %in% c("CAN", "HTI", "GHA", "KEN", "JOR", "VNM"), ]
network_plots$aid_2024 <- aid_plot + geom_label(data = label_nodes,
  aes(x = plot_x, y = plot_y, label = label), nudge_y = 4,
  size = 3, linewidth = 0, label.padding = grid::unit(.08, "lines"))
for (name in names(network_plots)) {
  p <- network_plots[[name]]
  for (format in c("png", "pdf", "svg")) {
    device <- switch(format, png = "png", pdf = grDevices::cairo_pdf, svg = grDevices::svg)
    ggsave(file.path("static", paste0(name, ".", format)), p, device = device,
      width = 9, height = 7, dpi = 200, bg = "white")
  }
}
