# Maps and networks, ready to share

<div class="atlas-intro">
<p class="atlas-kicker">THE OFFLINEATLAS R PACKAGE</p>
<p class="atlas-lead">Build an interactive atlas in R. Share a single HTML file that anyone can open, even without an internet connection.</p>
<p>Explore variables across countries, follow change over time, or connect places and people. Make editable static figures with ggplot2 from the same atlas.</p>
<p class="atlas-actions"><a class="btn btn-primary" href="articles/getting-started.html">Start the tutorial</a> <a class="btn btn-outline-primary" href="articles/demo-gallery.html">Explore the demos</a></p>
</div>

<figure class="atlas-hero">
<a href="demos/world-bank-gdp.html" aria-label="Open the interactive World Bank GDP map"><img src="images/gdp_2024.png" alt="World map of GDP per capita in 2024, with a compact color legend and source notes." width="1350" height="780"></a>
<figcaption>A static preview of the World Bank GDP example. <a href="demos/world-bank-gdp.html">Open the interactive map</a> to select countries and switch variables.</figcaption>
</figure>

## Install and make your first atlas

```r
install.packages("remotes")
remotes::install_github("preblek/offlineatlas")
library(offlineatlas)
```

R 4.1 or later is required. Missing required R packages are installed automatically.
Systems that compile sf from source may need additional
[system libraries](https://r-spatial.github.io/sf/#installing).

The [getting-started tutorial](articles/getting-started.html) walks through a
GDP map, a Florence family network, an FDI timeline, customization, and static
figures. The [demo gallery](articles/demo-gallery.html) pairs working examples
with their R scripts.

## From R to a file you can share

1. **Build** an atlas from data frames or sf boundaries. Add variables, relationships, or time periods.
2. **Customize** legends, controls, labels, and presentation through R functions.
3. **Export** a standalone HTML file with `export_html()`, or an editable ggplot2 figure with `as_ggplot()`.

The HTML includes its data, geometry, JavaScript, CSS, and artwork. Viewers need
no R installation, Shiny server, API key, or online map tiles. You can email the
file, open it locally, or place it on a static website such as GitHub Pages.
Included data can be read by anyone who receives the file, so export only data
you intend to share.

## Choose an example

- **Maps of variables** · GDP, regional sf boundaries, and national FDI inflows.
- **Change over time** · EU enlargement waves and FDI timelines.
- **Networks** · Florence family ties, fictional aid, and bilateral FDI.
- **Static figures** · ggplot2 maps and networks, automatic layouts, and node styling.

[See every example in the demo gallery](articles/demo-gallery.html).

## A living example

[FDI Atlas](https://fdiatlas.engagedthinking.com/) is a related, more customized
web project showing how this approach can be used for a public-facing atlas.
The package examples here are standalone files. Their source and data notices
travel with each exported viewer.

offlineatlas is an early release. [Report a problem or suggest an improvement](https://github.com/preblek/offlineatlas/issues).
