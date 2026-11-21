library(offlineatlas)
library(ggplot2)
dir.create("static", showWarnings = FALSE)

# Build the schematic example without a browser illustration.
families <- example_data("florence_nodes")
# An explicit display category, not an additional historical measurement.
families$family_role <- ifelse(families$label == "Medici", "Medici", "Other families")
florence <- atlas("Marriage alliances in Florence",
  notice = "Teaching subset. Family positions are schematic, not historical residences.",
  sources = "Padgett / CoMuNe Lab data (ODbL 1.0; DbCL 1.0).") |>
  add_nodes(families, id = "id", label = "label",
    layout_x = "x", layout_y = "y", coordinates = "schematic", attributes = "family_role") |>
  add_edges(example_data("florence_edges"), from = "from", to = "to", layer = "layer") |>
  set_preset("compact")
source(system.file("examples", "aid.R", package = "offlineatlas"), local = TRUE)
network_plots <- list(
  florence_marriages = as_ggplot(florence, layers = "Marriage"),
  florence_layers = as_ggplot(florence) + labs(title = "Relationships in Renaissance Florence"),
  florence_automatic = as_ggplot(florence, layers = "Marriage", layout = "fr", seed = 7,
    node_size_by = "degree", node_fill_by = "family_role", node_shape_by = "family_role") +
    labs(title = "Florentine marriages with an automatic layout") +
    scale_fill_manual(name = "Family", values = c(Medici = "#b46c3b", "Other families" = "#177b7b")) +
    scale_shape_manual(name = "Family", values = c(Medici = 23, "Other families" = 21)),
  aid_2024 = as_ggplot(set_preset(aid_atlas, "compact"), time = 2024, source = "CAN") +
    labs(title = "Canada's fictional aid relationships in 2024")
)
# Precomputed coordinates also work in the standalone HTML export.
export_html(layout_network(florence, "fr", seed = 7), "florence-automatic.html", overwrite = TRUE)
for (name in names(network_plots)) {
  p <- network_plots[[name]]
  for (format in c("png", "pdf", "svg")) {
    device <- switch(format, png = "png", pdf = grDevices::cairo_pdf, svg = grDevices::svg)
    ggsave(file.path("static", paste0(name, ".", format)), p, device = device,
      width = 9, height = 7, dpi = 200, bg = "white")
  }
}
