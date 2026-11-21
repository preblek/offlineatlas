library(offlineatlas)

florence_atlas <- atlas(
  "Connections in Renaissance Florence",
  entity_name = "family", entity_names = "families",
  description = "Explore marriage alliances and business ties among 16 Florentine families. Compare layers or select families to follow their relationships.",
  notice = "Teaching subset. Family positions show network structure, not historical residences.",
  sources = c("Padgett / CoMuNe Lab data (ODbL 1.0; DbCL 1.0). Schematic © Keith A. Preble, 2026.",
    "Padgett, John F., and Christopher K. Ansell. 1993. Robust Action and the Rise of the Medici, 1400-1434. American Journal of Sociology 98(6), 1259-1319. https://doi.org/10.1086/230190",
    "Data provider: CoMuNe Lab / Manlio De Domenico. Padgett-Florentine-Families Multiplex Network. https://github.com/CoMuNeLab/Padgett-Florentine-Families",
    "Original and adapted database: ODbL 1.0. Individual contents: DbCL 1.0. Retain attribution and license notices. The All data JSON download supplies the adapted machine-readable data.",
    "License texts: https://opendatacommons.org/licenses/odbl/1-0/ and https://opendatacommons.org/licenses/dbcl/1-0/",
    "Changes inherited from the demo: expanded family names, rescaled graph coordinates, repositioned Pucci. Ties are unchanged. This is not the complete network in the 1993 article and has no annual series.",
    "Original schematic illustration © 2026 Keith A. Preble / Engaged Thinking. Architecture and placement are illustrative, including a cathedral dome shown under construction.")) |>
  add_nodes(example_data("florence_nodes"), id = "id", label = "label",
    layout_x = "x", layout_y = "y", coordinates = "schematic") |>
  add_edges(example_data("florence_edges"), from = "from", to = "to", layer = "layer",
    directed = FALSE, coverage = "edge_list") |>
  set_background(example_file("florence.svg"))

export_html(florence_atlas, "florence-families.html", overwrite = TRUE)
