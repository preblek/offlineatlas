library(offlineatlas)
if (requireNamespace("sf",quietly=TRUE) && requireNamespace("ggplot2",quietly=TRUE)) {
  fails <- function(expr,pattern) {
    error <- tryCatch({force(expr);NULL},error=identity)
    stopifnot(inherits(error,"error"),grepl(pattern,conditionMessage(error)))
  }
  rect <- function(w,s,e,n) rbind(c(w,s),c(e,s),c(e,n),c(w,n),c(w,s))
  shapes <- sf::st_sf(id=LETTERS[1:4],value=c(-1,0,10,NA_real_),
    geometry=sf::st_sfc(sf::st_polygon(list(rect(0,0,8,8),rect(2,2,4,4))),
      sf::st_polygon(list(rect(10,0,18,8))),sf::st_polygon(list(rect(20,0,28,8))),
      sf::st_polygon(list(rect(30,0,38,8))),crs=4326))
  x <- atlas("Static check",sources="Synthetic fixture",units="units") |>
    add_areas(shapes,values="value",breaks=list(c(0,10)),colors=list(c("#112233","#445566","#778899")))
  p <- as_ggplot(x)
  stopifnot(inherits(p,"ggplot"),identical(p$data$value,shapes$value),
    identical(ggplot2::ggplot_build(p)$data[[1]]$fill,c("#112233","#445566","#778899","#d8dbd7")),
    length(sf::st_geometry(p$data)[[1]])==2,
    identical(sf::st_crs(p$data),sf::st_crs("OGC:CRS84")))
  # Familiar ggplot additions remain available.
  edited <- p + ggplot2::labs(title="Edited title") + ggplot2::theme(legend.position="right")
  stopifnot(edited$labels$title=="Edited title",edited$theme$legend.position=="right")
  file <- tempfile(fileext=".html");export_html(x,file)
  html <- paste(readLines(file,warn=FALSE),collapse="\n")
  stopifnot(!grepl('"area_geometry"|"sfc_POLYGON"|"sfc_MULTIPOLYGON"',html));unlink(file)
  file <- tempfile();saveRDS(x,file);stopifnot(identical(as_ggplot(readRDS(file))$data$value,shapes$value));unlink(file)
  panel <- rbind(shapes,shapes);panel$year <- rep(c(2000,2005),each=4);panel$value[5:8] <- c(10,-1,0,NA_real_)
  timed <- atlas() |> add_areas(panel,values="value",time="year",breaks=list(c(0,10))) |>
    set_controls(initial_time=2000) |> set_view(c(-1,-1,40,10))
  stopifnot(identical(as_ggplot(timed)$data$value,panel$value[1:4]),
    identical(as_ggplot(timed,time=2005)$data$value,panel$value[5:8]),
    length(attr(timed,"area_geometry")$geometry)==4)
  fails(as_ggplot(timed,time=1990),"Unknown area period")
  fails(as_ggplot(x,time=2000),"time is only")
  fails(as_ggplot(x,variable="other"),"Unknown area variable")
  paths <- example_data("world_paths")[1:2,];paths$value <- 1:2
  fails(as_ggplot(add_areas(atlas(),paths,values="value",breaks=list(0))),"sf input")
  shapes$group <- c("Member","Other",NA,"Member")
  catmap <- atlas() |> add_areas(shapes,values="group",categories=list(c("Member","Other","Future")),
    colors=list(c("#112233","#445566","#778899"))) |>
    set_legend(labels=list(group=c("Joined","Outside","Later")))
  catplot <- as_ggplot(catmap)
  stopifnot(identical(catplot$data$value,shapes$group),
    identical(catplot$scales$scales[[1]]$labels,c("Joined (2)","Outside (1)","Later (0)","Unavailable or unmatched")))
  stopifnot(as_ggplot(set_legend(catmap,visible=FALSE))$theme$legend.position=="none")
  cat("Static map values, threshold colors, missing values, category order, holes, period choice and HTML isolation passed\n")
}
