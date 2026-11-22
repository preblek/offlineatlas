**offlineatlas prototype**

[Documentation website](https://preblek.github.io/offlineatlas/) ·
[Getting-started tutorial](https://preblek.github.io/offlineatlas/articles/getting-started.html) ·
[Demo gallery](https://preblek.github.io/offlineatlas/articles/demo-gallery.html) ·
[Function reference](https://preblek.github.io/offlineatlas/reference/index.html)

This R package builds independent HTML visualizations from data frames. The
aid network, Florence network, World Bank GDP map, national FDI map, and
bilateral FDI sample, and EU enlargement timeline use the same renderer.
All required data, geometry, JavaScript, CSS, and artwork are embedded. The
viewer needs no R installation, server, API key, cache, or internet connection.

Install from GitHub with

```r
install.packages("remotes")
remotes::install_github("preblek/offlineatlas")
```

R 4.1 or later is required. The installer automatically installs missing required
R packages, including sf for geographic inputs, ggplot2 for static figures,
igraph for layouts and network measures, and ggrepel for static label placement.
It checks their minimum versions. You do not need separate installation commands
for these dependencies. Do not disable dependency installation with
`dependencies = FALSE`.

Installing packages may require internet access. On systems that build sf from
source, additional system libraries or build tools may be needed; see the
[sf installation guide](https://r-spatial.github.io/sf/#installing).
The exported HTML viewer needs no R packages, Python, Node, Pandoc, Shiny or
online tiles. Rebuilding the bundled examples performs no data downloads.

From a local checkout, `remotes::install_local(".")` also resolves dependencies.
`R CMD INSTALL .` is a lower-level alternative when dependencies are already
installed; it does not download missing packages.

The example scripts use bundled data and write standalone HTML into the
working directory. Run them in a dedicated output folder. The scripts replace
previous files with the same names; `export_html()` itself rejects overwriting
unless explicitly requested. Each HTML file can be copied by itself and opened
directly in a browser.

For a smaller standalone file, opt into internal compression when exporting.

```r
export_html(my_atlas, "my-atlas.html", compress = TRUE)
```

Replace `my_atlas` with your atlas object. The browser unpacks the embedded
data locally, without R, a server, or an internet connection. All observations,
geometry, and numeric precision are preserved, and the viewer's figure and data
downloads work as usual. Compression is not encryption and does not hide data.
Savings vary with the dataset, and unpacked data still needs browser memory.

Compressed exports need a current browser with built-in gzip decompression
support. Use `compress = FALSE` (the default) for older browsers. No additional
R packages are needed for compression.

To run one example from R in a chosen output directory, use

```r
library(offlineatlas)
source(system.file("examples", "aid.R", package = "offlineatlas"))
```

Use florence.R, gdp.R, fdi_national.R, fdi_bilateral.R, eu.R, customized.R, or
regional.R for the other examples. These scripts use the installed
sample data and write their HTML into the working directory. See
`help("offlineatlas")` for the package overview and `help(package = "offlineatlas")`
for the function index. Every exported function has its own help page.

**Getting started**

The installed tutorial walks through a GDP map, Florence marriage network,
national FDI timeline, custom controls and legends, and a static ggplot figure.
It explains identifier joins, fixed time-series geometry, missing values,
source attribution, and standalone exports. Open it with

```r
vignette("getting-started", package = "offlineatlas")
```

To include the rendered tutorial when installing from this source checkout,
first install the optional documentation tools knitr and rmarkdown, with
Pandoc available, then build and install the source archive:

```sh
R CMD build .
R CMD INSTALL offlineatlas_0.0.10.tar.gz
```

Building the vignette executes all tutorial sections using the required sf
and ggplot2 dependencies. Using the package or installing its built archive
with dependencies already present does not require the documentation tools.
Direct `R CMD INSTALL` on the source directory does not build the vignette.

The interface supports source and year selection, network layers, multiple
entity selection, distinct-partner or equal node sizes, incoming-weight sizes,
schematic dragging, background toggling, zoom, and pan. A geographic view keeps
coordinates fixed. Selection highlights ties involving any selected entity;
Florence degree counts use the full enabled-layer network. The weighted total
uses the current source, year, and layers, independent of node focus. The table
and CSV follow both filters and focus.

Search matches names or codes without filtering data. Clear focus restores the
overview while retaining filters and zoom. Keyboard focus survives selection,
and geographic maps can be panned by dragging land or using arrow keys.
Selection rings preserve zero and missing symbols. Responsive legends stay
readable on mobile screens, and figure captions describe active layers and focus.

The map and network can be downloaded as SVG or PNG from the browser. CSV
downloads contain the current filtered rows with units, notice, and sources.
JSON downloads contain all embedded data and metadata. Node dragging changes
the visible layout and figure exports; the all-data JSON retains original
prepared coordinates. CSV string cells that could be interpreted as formulas
are escaped with an apostrophe; JSON preserves the original strings.

**Static figures with ggplot2**

as_ggplot returns a regular ggplot object for an area map or a network.
Area maps and geographic network boundaries must use sf polygon input.
Schematic networks retain their supplied node positions.
ggplot2 and sf are required authoring dependencies installed with offlineatlas. The saved figures and
interactive HTML need neither R nor these packages to view.

```r
library(offlineatlas)
library(ggplot2)
source(system.file("examples", "fdi_national.R", package = "offlineatlas"))
p <- as_ggplot(fdi, variable = "inflow", time = 2025) +
  labs(title = "FDI inflows in 2025") +
  theme(legend.position = "bottom", plot.title = element_text(size = 18))
ggsave("fdi-2025.png", p, width = 11, height = 8.5, dpi = 300)
ggsave("fdi-2025.pdf", p, width = 11, height = 8.5)
ggsave("fdi-2025.svg", p, device = grDevices::svg, width = 11, height = 8.5)
```

Numeric intervals, category order, palettes, missing fill, and legend aliases
are retained. Custom legend placement, columns, counts, fonts, and notes are
honored where applicable. Titles and source/interpretation captions can be
edited with labs. The plot's data contain original values, IDs, labels, notes,
status, time, fill classes, and sf geometry for further annotation.

If time is omitted, the configured initial time is used, otherwise the latest
supplied period. If variable is omitted, the first variable is used. A static
map has no browser selection or camera state. Regional set_view bounds carry
over. Configured visible insets produce a warning and are omitted.
SVG-path-only area inputs are unsupported in static output.
Rebuild older objects with sf input; saveRDS preserves the retained geometry.
The original sf attribute table is not retained, and authoring geometry is
excluded from HTML/JSON payloads. The HTML stays independent and compact.

Networks support a selected year, relationship layers and an optional source
filter for directed links. For example, after running the Florence example:

```r
source(system.file("examples", "florence.R", package = "offlineatlas"))
p <- as_ggplot(florence_atlas, layers = "Marriage", node_size = 3) +
  labs(title = "Marriage alliances in Florence") +
  theme(legend.position = "bottom")
ggsave("florence-marriages.png", p, width = 9, height = 7, dpi = 300)
```

The Florence illustration is omitted with a warning, while the node positions
and ties are retained. Circles have equal size by default. Use `labels = FALSE`
to hide labels or `repel = FALSE` for simple offset labels. By default, ggrepel
places labels with leader lines and keeps every label within the map bounds. Very dense figures can
still need more space. All nodes, including isolates, stay visible.

For geographic networks, supply boundaries as sf polygons to `add_areas()`.
The installed aid and bilateral FDI examples use this input. For example,
`as_ggplot(aid_atlas, time = 2024, source = "CAN")` shows Canada's outgoing
ties. `source = NULL` includes all sources, independently of HTML controls.
Colors identify layers; weighted line widths show absolute values on a fixed
scale across all supplied years. Arrows preserve direction, and negative
weights use dashed lines. Zero and missing rows do not create lines. Inspect
the original filtered rows with `attr(p, "offlineatlas_edges")`; `p$data`
contains the nodes. Reciprocal ties use separate curves, and geographic paths
split at the dateline. Paths are schematic connections, not travel routes.

Run `examples/static_networks.R` from the installed package for Florence and
geographic aid figures in PNG, PDF and SVG. Network styling can be changed
with normal ggplot2 color, linewidth, linetype, fill, size, shape and theme settings.

**Automatic layouts and node styling**

For schematic networks, choose `layout = "fr"` (Fruchterman-Reingold), `"kk"`
(Kamada-Kawai), or `"circle"` in `as_ggplot()`. The default `"existing"` retains
supplied positions. Geographic nodes stay at their real locations. Layouts
use the union of observed nonzero ties over all supplied periods and layers,
without using direction or weight magnitude, so filters do not rearrange nodes.
Fixed seeds make results reproducible with the same library versions.

```r
p <- as_ggplot(florence_atlas, layers = "Marriage",
               layout = "fr", seed = 7, node_size_by = "degree")
```

To retain a layout for both HTML and figures, use `layout_network()` after
adding edges. You can omit schematic `layout_x` and `layout_y` in `add_nodes()`
to start from a circle. `layout_network()` removes any attached illustration
with a warning because new positions may not align with the artwork.

```r
arranged <- layout_network(florence_atlas, "fr", seed = 7)
export_html(arranged, "florence-automatic.html", overwrite = TRUE)
```

Use `attributes = c("group", "wealth")` in `add_nodes()` to explicitly retain
columns for static styling. They stay in R and are excluded from HTML.
Then use `node_fill_by = "group"`, `node_shape_by = "group"`, or
`node_size_by = "wealth"`. Size requires nonnegative numeric values; shape
supports up to five categories. Missing fills are gray, missing shape categories
use crosses, and zero or missing size values use a small visible symbol.
Original values, including NA, remain available in `p$data`.

Built-in measures include `degree` (distinct partners), `in_degree`,
`out_degree`, `strength`, `in_strength`, `out_strength`, `betweenness` and
`component`. Measures use the selected year, layers and source. Strength sums
known absolute weights and flags incomplete totals in the corresponding
`*_partial` columns. Betweenness is unweighted and unnormalized. Node styling
scales adapt to each figure; use fixed ggplot2 scale limits for comparisons
across years. See `?as_ggplot` for exact definitions and missing-data behavior.

These label and node styling options apply to static figures. The computed
layout can also be embedded in HTML. No R packages are needed to view either
export, and the browser does not recalculate the layout.

Run examples/static.R from the installed package to build FDI, GDP, and EU
examples as PNG, PDF, and SVG in a static folder. The standard nine
HTML examples do not require ggplot2. Static appearance is independently
customizable with ggplot2 and does not change the HTML presentation.
The static script uses a shared compact style with small keys, concise captions
and no redundant legend title. FDI and GDP use two-row legends; EU membership
uses three rows with category counts. All figures are nine inches wide, with
heights of 5.3 inches for FDI, 5.2 for GDP and 7 for Europe. Edit the ordinary
ggplot2 settings and figure_heights in that script to suit another page size.

**Inspect data and frame a region**

`summary(x)` returns an inspectable report. Its `areas` table counts supplied
observations by variable and period, with separate unmatched and unavailable
counts. Missing equals unmatched plus unavailable. Zero and negative values
are counted for numeric variables and weighted relationships. `categories`
retains unused levels with zero counts. `relationships` groups supplied rows
by period and layer. No absent source records or unobserved pairs are inferred.
The print method limits displayed rows; the returned tables retain every row.

```r
audit <- summary(x)
audit$areas
audit$relationships
x <- set_view(x)  # Fit all supplied sf areas and geographic nodes.
```

Call `set_view(x)` after adding all geographic layers. Padding defaults to
five percent per side, clipped to the supported world extent. Missing-valued
features and outlying geometry stay included. Very small extents use a minimum
one-degree span; dateline-crossing geometry can span the world. Prepared SVG
path tables need explicit bounds. Existing `set_view(x, bounds)` calls work
as before. The installed `regional.R` example shows automatic Benelux framing.

**Reusable presentation presets**

```r
x <- set_preset(x, "compact")
p <- as_ggplot(x)
```

Choose compact keys and spacing with `"compact"`, or larger text and keys with
`"presentation"`. Both use local sans-serif fonts. Presets preserve source
notes, labels, data, visibility and initial filters. They set toolbar/legend
placement, clear the explicit legend column count and replace font choices.
Apply further settings afterwards to override these layout defaults. Static
columns adapt to label length and category count unless explicitly supplied.
Presets do not choose saved figure dimensions; use ggplot2::ggsave width and
height for your page. Everything is embedded locally in HTML exports.

**Customize presentation in R**

Use set_controls, set_legend, and set_style before export_html. Each function
replaces its own configuration using the supplied arguments and defaults.
For an existing map called x, for example

```r
x <- x |>
  set_controls(position = "above_map", playback_interval = 900,
    visible = c(variable = FALSE),
    labels = c(time = "Observation year", play = "Animate", pause = "Pause")) |>
  set_legend(title = "How to read this map", position = "below", columns = 2) |>
  set_style(font_family = "sans", heading_family = "sans")
export_html(x, "custom-map.html")
```

Control positions are top, above_map, or sidebar. Visibility keys are time,
playback, source, variable, layers, size, background, inset, reset, zoom, search,
selection, downloads, and history. Only applicable controls appear. Hidden
selectors retain their initial values. Hiding selection controls still allows
map selection. Hiding downloads also hides the country history CSV button.

Text keys are time, source, variable, layers, size, background, inset, previous,
play, pause, next, reset, zoom_in, zoom_out, fit, search, selection, clear_focus,
select_all, select_none, export_svg, export_png, export_csv, export_json, and
history_csv. Quote reserved R names when writing overrides, for example
c("next" = "Later"). Playback intervals are 200 to 60000 milliseconds.

Legend positions are below, above, or sidebar. Set visible = FALSE to omit the
legend from the page and figures while retaining export captions and sources.
Use columns = NULL for responsive layout, or 1 to 4 for explicit columns.
Sidebars and narrow screens use one column. show_counts = FALSE suppresses
categorical counts. note = NULL keeps the automatic explanation; an empty
string removes it. missing_label changes the unavailable/unmatched key.
For area display aliases, use labels = list(variable_column = c(...)), with
one string per numeric interval or category, in the declared order. Aliases
do not change source values, category names, or data exports. Network legend
names come from the supplied layer column.

Fonts use local system, sans, serif, or mono families. Body and figure text
use font_family; HTML headings use heading_family. No fonts are fetched.
Exact appearance depends on the fonts installed on the viewing computer.
SVG and PNG preserve custom legend text and figure fonts. Legend placement
changes the HTML layout; figures keep their keys after the map and chart.

The installed examples/customized.R script demonstrates these options using
the full FDI timeline and writes customized-fdi.html. It also rebuilds the
standard FDI example as its source. No JavaScript or CSS editing is required.

**Categorical areas and time series**

The EU example maps the founding group and enlargement waves in 1958, 1973,
1981, 1986, 1995, 2004, 2007, and 2013, plus the UK withdrawal in 2020.
Each snapshot follows that period's change. Members retain their accession-wave
color; other countries are neutral. The map uses present-day boundaries, not
historical territorial reconstructions. The Cyprus note explains the suspension
of EU law where the Republic's government does not exercise effective control.
The Council accession timeline supplies dates. Bundled Natural Earth 50m
boundaries include Malta and group Aland with Finland. Greenland is excluded
from this European country view. Preparation is recorded in eu_metadata.json.

Use add_areas(categories = list(levels), colors = list(palette), time = "year")
for a categorical panel. Numeric panels use time with fixed breaks as usual.
Supply one row per country and period with identical geometry and labels and
the same complete country roster. Use explicit NA for missing observations.
An optional notes column can vary by period. Mixed numeric and categorical
variables use NULL entries for numeric categories and categorical breaks.
Geometry is embedded once, with separate observations for each period.

The year selector and Previous, Play, and Next controls work offline. Playback
uses equal time between observed periods, without interpolating missing years.
Colors and numeric breaks remain fixed. Country details, legend counts, tables,
and captions update with the period. Image and CSV exports pause playback and
use the selected period; JSON retains the complete series.

Use set_view(x, c(-25, 33, 45, 72), title = "Europe") to frame the main map.
Fit and Reset return to this extent. This is an explicit regional camera,
with the same geographic projection used by the world maps.

**Geographic data with sf**

add_areas accepts sf POLYGON and MULTIPOLYGON objects. add_nodes accepts sf
POINT objects without longitude/latitude arguments. Projected inputs are
converted from their declared CRS to longitude/latitude during authoring.
The HTML contains ordinary SVG geometry and coordinates, with no sf dependency.

```r
library(offlineatlas)
world <- sf::st_read(example_file("world_sf.geojson"), quiet = TRUE)
gdp <- example_data("worldbank_gdp")
joined <- match(world$id, gdp$id)
world$gdp <- gdp$gdp_per_capita[joined]
world$matched <- !is.na(joined)

map <- atlas("GDP per capita in 2024", units = "USD",
  sources = "World Bank WDI, CC BY 4.0. Natural Earth boundaries, public domain.") |>
  add_areas(world, id = "id", label = "label", values = "gdp", matched = "matched",
    breaks = list(c(1000, 5000, 15000, 40000, 80000)))
export_html(map, "gdp-map.html")
```

For your own data, read boundaries with sf::st_read, join values by identifiers,
and pass the resulting sf object to add_areas. Use matched to distinguish
unmatched identifiers from matched records with missing observations. No fuzzy
joins or imputation occur. Only requested attribute fields enter the export.

For a network, pass sf points to add_nodes, then a relationship table to
add_edges. The bilateral FDI script demonstrates this. Multipoints, lines,
geometry collections, and implicit polygon-to-point conversion are unsupported.

Shapes must have a known CRS, finite XY coordinates, and nonempty valid
geometry. Islands and holes are preserved. Polygons crossing the dateline are
split at the seam. Invalid polygons produce an error naming their IDs;
inspect them and apply sf::st_make_valid explicitly when appropriate. The
adapter never guesses a CRS, repairs geometry silently, or changes sf_use_s2().
It validates planar rings after dateline splitting. Source vertices are
transformed without automatic densification or simplification; SVG coordinates
are written to six decimal places.

The display remains the existing world projection, with latitude -60 to 85.
Shapes outside this range are rejected; subset or clip them explicitly.
A regional inset can enlarge local geometry. Automatic framing is available through set_view(x) without explicit bounds.
Arbitrary display projections and geometry simplification remain future work.

The bundled world_sf.geojson retains the same 176 area identifiers as the
legacy SVG fixture. It uses the original Natural Earth coordinates and retains
only id, label, and geometry. Explicit GEOS repairs to USA and Sudan are
recorded in world_sf_metadata.json, along with the source checksum and geometry
library versions. The normal demo build needs only
the bundled fixture and performs no downloads.

The World Bank example embeds 2024 GDP per capita and total GDP in current US
dollars. GDP per capita is the default variable. Fixed intervals are explicit
in the legend. These are nominal values, not inflation-adjusted or PPP measures.
No missing values are imputed. Exact identifier joins link 176 bundled areas;
small economies without a polygon are outside the map. The retrieval metadata
and unmatched-ID audit are in inst/extdata/worldbank_metadata.json. Exporting
and viewing the bundled snapshot do not contact the World Bank. The raw API
responses and snapshot preparation scripts are retained in the maintainer's
research workspace, outside this package repository.

The national FDI example uses 1990–2025 inward flows from the supplied
UNCTAD export, in millions of current US dollars. It excludes regional aggregates
and retains negative values. Its fixed area palette distinguishes negative
intervals. Source footnotes are retained in the source panel. The full cleaned
1990–2025 panel, crosswalk, historical/unmapped records, and audit are in the
maintainer's research workspace, outside this package repository. The bundled
map data and metadata are in inst/extdata. No historical values are reassigned to
successor countries. The source does not supply estimate/revision status.

National and bilateral FDI examples use UNCTAD Data Hub data under
CC BY 3.0 IGO. [FDI-NOTICE.txt](inst/extdata/FDI-NOTICE.txt) records the source,
reuse links and adaptations. Retain attribution and identify changes when
sharing these data or derived visualizations. The package's MIT license does
not replace the data license.

Selecting exactly one area in a numeric time series reveals a country history
chart and an accessible table of all periods. Negative values fall below zero;
missing observations break the line. The chart scale uses the selected country's
full series and stays fixed during playback. Different countries can have
different chart scales. Numeric period labels use proportional spacing.
SVG/PNG exports include the visible chart. Country history CSV exports every
period with notes and units, while View data CSV exports the current map period.
Categorical series such as EU membership keep their existing category display.

The bilateral FDI example uses nine countries in 2020–2024 from the existing
FDI Atlas. Host-perspective direct reports take precedence, including zeroes;
existing mirrors fill missing direct reports. No exploratory substitutions are
applied. Its complete sample panel contains 360 rows, including 49 negative,
40 zero, and 40 unavailable values. These sample totals are not national totals.

Signed network weights require add_edges(signed = TRUE). Positive lines are
solid teal and negative lines dashed amber; arrows keep the supplied direction.
Circle area uses absolute incoming flows on a fixed scale, while totals retain
signs. Offsetting flows with a net total of zero retain a filled magnitude
symbol. Zero and missing edges remain in data exports but produce no lines.
The bilateral example includes a Europe inset. Add one to any geographic
atlas after its nodes or areas with

```r
x <- set_inset(x, bounds = c(-15, 34, 35, 62), title = "Europe detail")
```

Bounds are west, south, east, north in degrees. The optional visible = FALSE
starts it hidden. A browser control shows or hides it. The inset shares year,
source, layers, area variable, focus, and symbol scales, while its geographic
extent stays fixed as the main map pans or zooms. Selecting a node or area in
either view updates both. A purple rectangle marks the inset bounds. Only
connections with an endpoint inside the inset are shown, clipped at the edge.
SVG and PNG include the inset when visible. One rectangular inset is supported;
bounds crossing the dateline and automatic cluster detection are not implemented.

The optional provenance column travels into tables, inspectors, CSV, and JSON.
add_areas(colors = list(...)) accepts an explicit palette for each variable.

The Florence backdrop is illustrative, not historical residential geography.
Marriage and business data retain their existing provenance and ODbL/DbCL
notices. Natural Earth geometry is public domain. World Bank indicators retain
CC BY 4.0 attribution. See the bundled notices and export source panels.

Prototype limits include one fixed geographic display projection,
no self-links, and no synchronized
map/network panels. Geographic areas accept sf polygons or prepared SVG paths. The
example_data("world_paths") fixture remains available for data-frame workflows. Native area membership,
and unlocated nodes are not implemented yet. The
renderer is intended for modest data sizes; large-atlas performance is unmeasured.

This is an experimental development package, not a CRAN release. Original
software and schematic artwork are licensed under the [MIT License](LICENSE.md).
Bundled datasets retain their separate licenses and attribution notices.
Natural Earth geometry is public domain. Florence data retain ODbL 1.0 and
DbCL 1.0 notices in inst/extdata/FLORENCE-NOTICE.txt. World Bank data retain
CC BY 4.0 attribution in inst/extdata/worldbank_metadata.json.
Maintainer contact is preblek25@ecu.edu. Report reproducible problems or suggest
improvements through [GitHub issues](https://github.com/preblek/offlineatlas/issues).

Each push to the main branch rebuilds the documentation and all bundled example
scripts from the current source. The website check verifies the version in
every HTML demo and checksums of the generated figures and downloadable scripts
before deployment. To run the same build locally, use
`Rscript pkgdown/build-site.R` from the package directory.
Existing HTML files already downloaded or shared must be regenerated separately;
standalone files do not update themselves.

R validation tests are in tests/. Run `R CMD build .`, then run
`R CMD check --no-manual` followed by the generated `.tar.gz` filename to check
the package examples, tests and vignette. The filename includes the version
from `DESCRIPTION`. A PDF manual can be built separately with
`R CMD Rd2pdf .` when a working TeX installation is available.

Version 0.0.11 passed local R package checks on macOS, including all ten test
scripts and the getting-started vignette. The previous release also passed
GitHub Actions checks on macOS, Windows, and Ubuntu.

Compressed and uncompressed exports were compared in Chrome 159 and Firefox 160
using local files with network access blocked. Eight fixtures passed checks for
identical data and initial views, controls, and SVG, PNG, CSV, and JSON downloads.
The checks also covered FDI history downloads and readable failure messages.
Safari 27.2 passed interactive local-file checks of compressed FDI, Florence,
and GDP examples, including timeline, country history, relationship filters,
and variable selection. Safari's automation driver could not connect; Safari
downloads were not verified because its download-permission prompt was declined.
These browser checks and their tooling are retained in the research workspace,
outside this package repository.
