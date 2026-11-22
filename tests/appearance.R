library(offlineatlas)
fails <- function(expr, pattern) {
  err <- tryCatch({ force(expr); NULL }, error = identity)
  stopifnot(inherits(err, "error"), grepl(pattern, conditionMessage(err)))
}
square <- function(x) sf::st_polygon(list(matrix(c(x,0,x+1,0,x+1,1,x,1,x,0), ncol=2, byrow=TRUE)))
a <- sf::st_sf(id=letters[1:5], penalty=c(0,0.01,150.5,NA,-2),
  count=c(0,1,2,NA,3), geometry=sf::st_sfc(lapply(0:4, square), crs=4326))
x <- atlas("Currency checks", units="2025 USD") |>
  add_areas(a, values=c("penalty","count"), breaks=list(c(0,100),c(1,2)))
original <- x
y <- set_palette(x, c("#6BAED6","#3182BD","#08519C"), zero_color="#E6E6E6",
  missing_color="#FFFFFF", border_color="#000000", border_width=.6,
  zero_label="No recorded penalty") |>
  set_number_format(style="currency", variable="penalty") |>
  set_selection_card(position="bottom_left") |>
  set_export_options(title="Custom title", subtitle="2025 dollars")
stopifnot(identical(x,original), identical(x$areas,y$areas),
  identical(attr(x,"area_geometry"),attr(y,"area_geometry")),
  is.null(y$variables[[2]]$number_format), y$variables[[1]]$number_format$digits==2)
z <- set_palette(y, variable="penalty", border_width=1)
stopifnot(identical(y$variables,z$variables), identical(y$view,z$view),
  identical(y$controls,z$controls),z$area_style$border_color=="#000000")
reset <- set_palette(y, variable="penalty", zero_color=NULL)
stopifnot(is.null(reset$variables[[1]]$zero_color),!is.null(reset$variables[[2]]$zero_color))
plot <- as_ggplot(y, variable="penalty")
stopifnot(identical(as.character(plot$data$fill_key),c("zero","class_2","class_3","missing","class_1")),
  identical(plot$data$value,c(0,.01,150.5,NA,-2)),
  plot$layers[[1]]$aes_params$colour=="#000000",plot$layers[[1]]$aes_params$linewidth==.15)
scale <- plot$scales$get_scales("fill")
stopifnot(any(grepl("\\$100.00",scale$labels)),"No recorded penalty" %in% scale$labels,
  any(grepl("excluding[[:space:]]+zero",scale$labels)))
bar <- as_ggplot(set_legend(y,type="bar"),variable="penalty")
stopifnot(identical(bar$data,plot$data),inherits(ggplot2::ggplotGrob(bar),"gtable"))
ticks <- getFromNamespace("bar_tick_labels","offlineatlas")
stopifnot(identical(ticks(c(1e6,1.5e6,1333),list(style="currency",currency="USD",digits=2)),c("$1M","$1.50M","$1,333.00")))
fails(set_legend(x,type="gradient"),"arg")
for (compress in c(FALSE,TRUE)) {
  file <- tempfile(fileext=".html");export_html(y,file,compress=compress)
  doc <- xml2::read_html(file);payload <- xml2::xml_text(xml2::xml_find_first(doc,"//script[@id='atlas-data']"))
  if(compress)payload <- rawToChar(memDecompress(jsonlite::base64_dec(payload),"gzip"))
  restored <- jsonlite::fromJSON(payload,simplifyVector=FALSE)
  stopifnot(restored$areas[[3]]$value_1==150.5,restored$areas[[2]]$value_1==.01,
    is.null(restored$areas[[4]]$value_1),restored$variables[[1]]$number_format$digits==2,
    restored$variables[[1]]$zero_color=="#E6E6E6")
  unlink(file)
}
panel <- rbind(transform(a,year=2024),transform(a,year=2025))
timeline <- atlas() |> add_areas(panel,values="penalty",breaks=list(c(0,100)),time="year")
updated <- set_palette(timeline,c("#6BAED6","#3182BD","#08519C"),zero_color="#E6E6E6")
stopifnot(identical(timeline$area_frames,updated$area_frames))
fails(set_palette(x,c("red","blue","green")),"hex")
fails(set_palette(x,"#000000"),"per interval")
fails(set_palette(x,variable="unknown"),"existing area")
fails(set_palette(x,border_width=NA_real_),"border_width")
fails(set_palette(x,missing_color=c("#FFFFFF","#000000")),"one color")
fails(set_number_format(x,digits=1.5),"digits")
fails(set_number_format(x,digits=Inf),"digits")
fails(set_number_format(x,currency="dollars"),"currency")
fails(set_selection_card(x,visible=NA),"TRUE or FALSE")
fails(set_export_options(x,prompt="yes"),"TRUE or FALSE")
fails(set_export_options(x,title=1),"text")
f <- getFromNamespace("format_atlas_numbers","offlineatlas")
stopifnot(identical(f(c(150.5,0,-2),list(style="currency",currency="USD",digits=2)),c("$150.50","$0.00","-$2.00")))
cat("Appearance setters preserve numeric data, geometry and periods; zero, missing and currency stay distinct.\n")
