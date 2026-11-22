# offlineatlas 0.0.14

* Added a step-by-step OFAC state-map vignette, based on the worked tutorial.
  It preserves separate stages for average penalties, a two-variable dropdown,
  currency formatting, palettes, zero/missing colors, boundaries, legends,
  selection cards, image headings, and static PDF/PNG figures.
* Added a Japan prefecture-population vignette with a three-variable dropdown
  for 2020, preliminary 2025, and absolute change. It demonstrates checked
  joins, comparable year scales, a separate change palette, alternative
  legends, a geographic inset, and static figures.
* Bundled both CSV datasets and simplified sf-readable boundaries, with
  source dates, preparation details, limitations, and reuse notices. Tutorials
  run from installed package assets without personal paths or data downloads.
* Added both tutorials to website navigation and the homepage, plus gallery
  examples, complete R scripts, CSV/boundary downloads and static PDF links.
  Website builds refresh tutorial scripts and all example exports from the
  current source. No viewer or public function behavior changed.

# offlineatlas 0.0.13

* Added set_palette() to recolor an existing area atlas without adding its
  geometry or data again. Palettes can target one or several variables.
  Separate zero and missing colors, a zero legend label, and boundary color
  and width are configurable. The settings also apply to static area figures.
* Added set_number_format() for currency symbols and fixed decimal places,
  including amounts such as $150.50. Area variables can use different formats.
  Formatting changes presentation only; CSV and JSON retain numeric values.
* Added set_legend(type = "bar") for compact numeric legends with adjoining
  interval bands and separate zero/missing keys. HTML, SVG/PNG and static area
  figures support the option; box legends remain the default.
* Selecting one area now shows its active value in a prominent card. The card
  follows variable and timeline changes, moves below the map on narrow screens,
  and is included in SVG and PNG downloads. set_selection_card() controls its
  visibility and position.
* SVG and PNG download buttons now offer editable titles and subtitles placed
  above the figure. set_export_options() supplies defaults or disables the
  dialog for immediate downloads. Blank headings are omitted, and the atlas
  title and data are unchanged.
* Updated presentation documentation and bundled examples. All exported maps,
  cards, number formatting and download controls work standalone and offline.

# offlineatlas 0.0.12

* Atlas objects and exported viewer badges now obtain their version from the
  installed package. Re-exporting an older object records the current exporter
  version without modifying the original object.
* The website build runs every bundled example script and checks demo versions
  and generated-file checksums before deployment, including static figures.

# offlineatlas 0.0.11

* Added optional internal compression with export_html(..., compress = TRUE).
  Compressed files remain standalone HTML and work offline. Data and geometry
  are restored losslessly in the browser; figures and data downloads are unchanged.
* Uncompressed exports remain the default. Compressed exports display a clear
  message when browser decompression is unavailable or the payload is damaged.
* Added compression guidance and checks for payload integrity, Unicode,
  missing and signed values, and unchanged default exports.

# offlineatlas 0.0.10

* Added reproducible Fruchterman-Reingold, Kamada-Kawai and circular layouts
  through layout_network() and the static adapter. Computed schematic
  coordinates can be embedded in offline HTML. Geographic nodes stay fixed.
* Added ggrepel label placement and static node size, fill and shape mappings
  from explicitly retained attributes or filtered network measures. Missing
  values and isolates remain visible. Original attributes stay out of HTML.
* Added igraph and ggrepel as required authoring dependencies, installed
  automatically. Neither is required by exported viewers or image files.
* Added editable ggplot2 output for schematic and geographic networks, with
  relationship layer, year and directed source filters, optional labels and
  adjustable fixed node size. Isolates and original positions are retained.
* Added arrows, stable layer colors, separate parallel and reciprocal paths,
  and dateline splitting. Line width uses absolute weight on a fixed scale;
  dashed negative flows retain their direction. Zero and missing rows are
  preserved in plot metadata without drawing lines.
* Added Florence and geographic aid static examples and tutorial coverage.
  Geographic network boundaries use sf input. Illustrations and visible
  insets are omitted with warnings. HTML exports remain standalone and offline.

# offlineatlas 0.0.9

* Moved sf and ggplot2 from Suggests to Imports so standard GitHub and local
  dependency-aware installation includes them automatically when missing.
* Updated installation guidance and help pages. The tutorial now runs every
  geographic and static section with the required dependencies.
* Exported HTML remains standalone and offline; its viewers need no R packages.

# offlineatlas 0.0.8

* Added summary() tables for area variables, categories and relationships,
  with per-period missing, unmatched, unavailable, zero and negative counts.
* Added automatic geographic framing when set_view() receives no bounds,
  with controlled padding and support for sf polygons and geographic points.
* Added compact and presentation presets for standalone HTML and ggplot2
  figures, preserving semantic options and allowing subsequent overrides.
* Added regional Benelux examples and tutorial coverage for all three features.

# offlineatlas 0.0.7

* Applied consistent compact styling to all three static examples. World maps
  use two-row legends; the EU map uses three rows with shorter category labels.
  Export dimensions now follow each map's geographic extent.
* Made static legend keys and labels smaller, aligned titles and captions with
  the figure, and added a compact FDI static example with a two-row legend.
* Shortened default numeric interval labels in HTML and static maps while
  preserving their lower-inclusive boundaries.

* Split the combined reference into a package overview and individual help
  pages for all 14 exported functions, with examples and cross-references.
* Added an installed getting-started vignette covering GDP, Florence marriages,
  an FDI timeline, presentation options, offline exports and static figures.
  knitr and rmarkdown are optional documentation-build dependencies.
* Added optional `as_ggplot()` output for one variable and period of sf-backed
  area maps. Returned ggplot objects support ordinary themes, labels and layers.
* Preserved fixed numeric intervals, category order, colors, missing values,
  legend aliases, regional framing and source captions in static output.
* Retained validated geometry in an authoring-only R attribute. Browser exports
  exclude that attribute and retain their standalone offline behavior.
* Added FDI, GDP and EU examples saved as PNG, PDF and SVG.
* Static network plots are not supported. Visible insets are omitted with a
  warning. Older atlas objects and path-only inputs require rebuilding with sf.

# offlineatlas 0.0.6

* Added R options for legends, controls, playback speed and local fonts.

# offlineatlas 0.0.5

* Added the full national FDI timeline, country history charts and history CSV.

# offlineatlas 0.0.4

* Added categorical area panels, period playback, regional framing and the EU example.

# offlineatlas 0.0.3

* Added optional sf polygon and point input.
