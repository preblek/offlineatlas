# Maintaining the documentation website

The website is built with pkgdown and hosted on GitHub Pages. The published
address is https://preblek.github.io/offlineatlas/ once Pages is enabled.

## First deployment

1. Upload this package's changed files to the root of preblek/offlineatlas.
   Keep the `.github/workflows/pkgdown.yaml` path intact.
2. In GitHub, open **Settings → Pages**. Under **Build and deployment**, set
   **Source** to **GitHub Actions**. No branch or custom domain is needed.
3. Open **Actions → Documentation website**. If the first run failed before
   Pages was enabled, choose **Re-run all jobs**, or use **Run workflow** on main.
4. Wait for both the build and deployment jobs to pass. The deployment job
   supplies the live site URL.

Future pushes to main rebuild the site automatically. Pull requests build the
site but do not deploy it. The existing three-platform R package checks remain
separate. Publishing a GitHub release is not required for documentation updates.

## Build locally

From this package directory, with the package dependencies and Pandoc installed,

```r
install.packages("pkgdown")
source("pkgdown/build-site.R")
```

For a clean session, prefer `Rscript pkgdown/build-site.R` in a terminal. The
script installs the current source into a temporary library, runs the bundled
examples, renders the tutorial and function reference, and writes the site to
`docs/`. It does not download example datasets. Installation and setup of build
tools can require an internet connection.

Preview with `python3 -m http.server 8000 --directory docs` and open
http://localhost:8000/. Generated `docs/` files are ignored by Git and excluded
from the R source package. GitHub Actions uploads them as the Pages artifact.

## Where to edit

- `pkgdown/index.md` is the website home page.
- `vignettes/getting-started.Rmd` is the tutorial and package vignette.
- `vignettes/articles/demo-gallery.Rmd` is the gallery.
- `_pkgdown.yml` controls navigation, colors, and reference groups.
- `pkgdown/extra.css` handles the gallery and home-page layout.
- `inst/examples/*.R` supplies the downloadable example code.

Demo HTML files embed their data and rendering assets. The site links directly
to them, and each can be downloaded and opened alone without R or a server.
Documentation pages use ordinary static website assets; the entire documentation
site is not packaged as a single HTML file. Data attribution and reuse notices
remain in the demos. The site's static previews are generated with ggplot2.
