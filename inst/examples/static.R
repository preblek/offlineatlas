library(offlineatlas)
library(ggplot2)
dir.create("static", showWarnings = FALSE)
source(system.file("examples", "fdi_national.R", package = "offlineatlas"), local = TRUE)
source(system.file("examples", "eu.R", package = "offlineatlas"), local = TRUE)
source(system.file("examples", "gdp.R", package = "offlineatlas"), local = TRUE)

# These ordinary ggplot2 settings keep the maps prominent in all three examples.
# Adjust columns, fonts, keys or export dimensions for your own publication.
compact_static <- function(p, title, subtitle, columns, caption) {
  p +
    labs(title = title, subtitle = subtitle, caption = caption) +
    guides(fill = guide_legend(title = NULL, ncol = columns, byrow = TRUE)) +
    theme(
      text = element_text(family = "sans"),
      plot.title = element_text(family = "sans", face = "bold", size = 16),
      plot.subtitle = element_text(size = 10),
      legend.position = "bottom",
      legend.text = element_text(size = 8),
      legend.key.size = grid::unit(3, "mm"),
      plot.caption = element_text(size = 8, hjust = 0),
      plot.margin = margin(10, 10, 10, 10)
    )
}

# Shorter category names retain the same order, colors and per-period counts.
eu_static <- set_legend(eu, labels = list(wave = c(
  "1958 founders", "1973", "1981", "1986", "1995", "2004", "2007", "2013",
  "Not a member"
)))
plots <- list(
  fdi_2025 = compact_static(
    as_ggplot(set_preset(fdi, "compact"), time = 2025),
    title = "FDI inflows in 2025",
    subtitle = "Millions of current US dollars", columns = 4,
    caption = paste(
      "Annual inward flows. Negative values and zeroes are retained; missing observations are not imputed.",
      "Present-day boundaries; historical economies are not reassigned. Estimate and revision status are not supplied.",
      "Source: UNCTAD FDI export. Natural Earth boundaries (public domain). No UN endorsement is implied.",
      sep = "\n"
    )
  ),
  eu_2004 = compact_static(
    as_ggplot(set_preset(eu_static, "compact"), time = 2004),
    title = "EU membership after the 2004 enlargement",
    subtitle = "Accession year | Country and area counts in parentheses", columns = 3,
    caption = paste(
      "Membership after 1 May 2004. Founding members refer to the EEC in 1958.",
      "Present-day boundaries; historical territorial coverage is not reconstructed.",
      "Sources: Council of the European Union; Natural Earth 1:50m boundaries (public domain).",
      sep = "\n"
    )
  ),
  gdp_2024 = compact_static(
    as_ggplot(set_preset(gdp_atlas, "compact"), variable = "gdp_per_capita"),
    title = "GDP per capita in 2024", subtitle = "Current US dollars per person", columns = 4,
    caption = paste(
      "Not adjusted for inflation or purchasing power. Missing observations are not imputed.",
      "Source: World Bank WDI, 2024 (CC BY 4.0). Present-day Natural Earth boundaries (public domain).",
      sep = "\n"
    )
  )
)

# Europe needs a taller panel than the world maps. Keep a common nine-inch width.
figure_heights <- c(fdi_2025 = 5.3, eu_2004 = 7, gdp_2024 = 5.2)
for (name in names(plots)) {
  p <- plots[[name]]
  height <- unname(figure_heights[name])
  ggsave(file.path("static", paste0(name, ".png")), p,
         width = 9, height = height, dpi = 150, bg = "white")
  ggsave(file.path("static", paste0(name, ".pdf")), p,
         width = 9, height = height, device = grDevices::cairo_pdf, bg = "white")
  ggsave(file.path("static", paste0(name, ".svg")), p,
         width = 9, height = height, device = grDevices::svg, bg = "white")
}
