library(offlineatlas)
fails <- function(expr, pattern) {
  error <- tryCatch({force(expr); NULL}, error=identity)
  stopifnot(inherits(error,"error"),grepl(pattern,conditionMessage(error)))
}
# Summary counts each supplied area-period once, even with multiple variables.
paths <- example_data("world_paths")[1:4, ]
panel <- rbind(paths, paths)
panel$year <- rep(c(2,10),each=4)
panel$value <- c(-1,0,NA,NA, 10,NA,0,-2)
panel$matched <- c(TRUE,TRUE,TRUE,FALSE, TRUE,TRUE,TRUE,TRUE)
panel$group <- c("A","A",NA,NA, "B",NA,"A","B")
x <- atlas("Summary fixture") |> add_areas(panel,values=c("value","group"),
  breaks=list(c(0,10),NULL),categories=list(NULL,c("A","B","Unused")),
  colors=list(c("#112233","#445566","#778899"),c("#112233","#445566","#778899")),
  time="year",matched="matched")
s <- summary(x)
stopifnot(inherits(s,"summary_offline_atlas"),identical(s$periods,c("2","10")),
  s$area_observations==8, s$entities[["areas"]]==4, nrow(s$areas)==4,
  sum(s$categories$count)==5)
a <- s$areas[s$areas$variable=="value",]
stopifnot(identical(a$missing,c(2L,1L)),identical(a$unmatched,c(1L,0L)),
  identical(a$unavailable,c(1L,1L)),identical(a$zero,c(1L,1L)),
  identical(a$negative,c(1L,1L)),all(is.na(s$areas$zero[s$areas$type=="categorical"])),
  all(s$categories$count[s$categories$category=="Unused"]==0))
stopifnot(any(grepl("Showing",capture.output(print(s,max_rows=1)))))
fails(print(s,max_rows=0),"positive integer")
stopifnot(nrow(summary(atlas())$areas)==0,summary(atlas())$area_observations==0)
families <- example_data("florence_nodes")
n <- atlas() |> add_nodes(families,"id","label",layout_x="x",layout_y="y",coordinates="schematic")
ties <- data.frame(from=families$id[1:3],to=families$id[2:4],value=c(-4,0,NA),year=c(1,1,2))
w <- add_edges(n,ties,"from","to",weight="value",time="year",signed=TRUE,coverage="observed_rows")
e <- summary(w)$relationships
stopifnot(sum(e$total)==3,sum(e$negative)==1,sum(e$zero)==1,sum(e$missing)==1)
u <- add_edges(n,ties,"from","to")
stopifnot(all(is.na(summary(u)$relationships$zero)),sum(summary(u)$relationships$total)==3)
# Presets preserve semantic options and filters; later setters can override layout.
x <- set_controls(x,initial_time=2,visible=c(search=FALSE),labels=c(play="Run")) |>
  set_legend(title="Custom",show_counts=FALSE,labels=list(group=c("One","Two","Three")),note="Retain me")
p <- set_preset(x,"compact")
stopifnot(identical(p$areas,x$areas),identical(p$area_frames,x$area_frames),
  identical(p$controls$initial_time,"2"),identical(p$controls$visible,x$controls$visible),
  identical(p$legend$labels,x$legend$labels),identical(p$legend$note,"Retain me"),
  identical(p$legend$title,"Custom"),!p$legend$show_counts,p$controls$position=="above_map")
stopifnot(set_controls(p,position="sidebar")$controls$position=="sidebar",
  set_legend(p,columns=1)$legend$columns==1)
fails(set_preset(x,"unknown"),"arg")
fails(set_view(n),"geographic")
fails(set_view(x),"sf input")
# Data-frame geographic points, one-point extents, and world-limit padding.
points <- data.frame(id=c("a","b"),lon=c(2,12),lat=c(40,50))
g <- atlas() |> add_nodes(points,"id",longitude="lon",latitude="lat")
v <- set_view(g)$view
stopifnot(isTRUE(all.equal(unname(unlist(v[1:4])),c(1.5,39.5,12.5,50.5))))
point <- points[1,];point$lon <- 180;point$lat <- 85
one <- atlas() |> add_nodes(point,"id",longitude="lon",latitude="lat") |> set_view()
stopifnot(one$view$east==180,one$view$north==85,one$view$west<180,one$view$south<85)
fails(set_view(g,padding=-1),"padding")
if(requireNamespace("sf",quietly=TRUE)) {
  rect <- function(w,s,e,n) sf::st_polygon(list(rbind(c(w,s),c(e,s),c(e,n),c(w,n),c(w,s))))
  shapes <- sf::st_sf(id=c("a","b"),value=c(0,NA),geometry=sf::st_sfc(
    rect(2,40,4,42),rect(10,48,12,50),crs=4326))
  make <- function(z) atlas() |> add_areas(z,values="value",breaks=list(c(0,10)))
  a <- set_view(make(shapes));b <- set_view(make(sf::st_transform(shapes,3857)))
  stopifnot(isTRUE(all.equal(a$view,b$view,tolerance=1e-7)),
    isTRUE(all.equal(unname(unlist(a$view[1:4])),c(1.5,39.5,12.5,50.5))))
  timed <- rbind(shapes,shapes);timed$year <- rep(c(1,2),each=2)
  t <- atlas() |> add_areas(timed,values="value",time="year",breaks=list(c(0,10))) |> set_view()
  stopifnot(identical(a$view,t$view))
  mixed <- add_nodes(make(shapes),data.frame(id="c",lon=-10,lat=35),"id",longitude="lon",latitude="lat") |> set_view(padding=0)
  stopifnot(mixed$view$west==-10,mixed$view$south==35,mixed$view$east==12)
  seam <- sf::st_sf(id="seam",geometry=sf::st_sfc(rect(170,10,190,20),crs=4326))
  seam <- atlas() |> add_areas(seam) |> set_view(padding=0)
  stopifnot(seam$view$west==-180,seam$view$east==180)
  # Older serialized sf atlases have retained geometry but no bounds metadata.
  older <- make(shapes);older$spatial$areas$bounds <- NULL
  stopifnot(identical(set_view(older)$view,a$view))
  if(requireNamespace("ggplot2",quietly=TRUE)) {
    compact <- as_ggplot(set_preset(a,"compact"))
    large <- as_ggplot(set_preset(a,"presentation"))
    stopifnot(identical(compact$data,large$data),compact$theme$legend.text$size==8,
      large$theme$legend.text$size==11, is.null(compact$scales$scales[[1]]$name),
      isTRUE(all.equal(ggplot2::ggplot_build(compact)$data[[1]]$fill,
                       ggplot2::ggplot_build(large)$data[[1]]$fill)))
    overridden <- as_ggplot(set_legend(set_preset(a),title="Keep",columns=1))
    stopifnot(overridden$scales$scales[[1]]$name=="Keep",
      overridden$guides$guides$fill$params$ncol==1)
  }
}
cat("Summary accounting, framing and presentation presets passed\n")
