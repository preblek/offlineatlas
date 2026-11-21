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
