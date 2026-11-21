library(offlineatlas)
fails <- function(expr,pattern) {
  error <- tryCatch({force(expr);NULL},error=identity)
  stopifnot(inherits(error,"error"),grepl(pattern,conditionMessage(error)))
}
shape <- example_data("world_paths")[1:2,]
d <- rbind(shape,shape);d$period <- rep(c(2000,2005),each=2)
d$group <- c("Outside","A","B",NA);d$number <- c(0,1,-1,NA_real_)
make <- function(data) add_areas(atlas(),data,values="group",categories=list(c("A","B","Outside")),
  colors=list(c("#112233","#445566","#eeeeee")),time="period")
x <- make(d)
stopifnot(nrow(x$areas)==2,length(x$area_frames)==2,
  x$area_frames[[2]]$data$value_1[1]=="B",is.na(x$area_frames[[2]]$data$value_1[2]),
  x$variables[[1]]$type=="categorical")
numeric <- add_areas(atlas(),d,values="number",breaks=list(0),time="period")
stopifnot(numeric$area_frames[[2]]$data$value_1[1]==-1)
mixed <- add_areas(atlas(),d,values=c("number","group"),time="period",
  breaks=list(0,NULL),categories=list(NULL,c("A","B","Outside")),
  colors=list(c("#112233","#445566"),c("#112233","#445566","#eeeeee")))
stopifnot(mixed$variables[[1]]$type=="numeric",mixed$variables[[2]]$type=="categorical")
fails(make(d[-4,]),"every ID")
fails(make(rbind(d,d[1,])),"Duplicate")
bad <- d;bad$path[3] <- "M1,1L2,2Z";fails(make(bad),"fixed geometry")
bad <- d;bad$group[1] <- "unknown";fails(make(bad),"Unknown category")
fails(add_areas(atlas(),shape,values="id",categories=list(shape$id)),"palette")
fails(set_view(x,c(10,30,-10,50)),"bounds")
x <- set_controls(x,initial_time=2005)
file <- tempfile(fileext=".html");export_html(x,file);unlink(file)
x <- set_controls(x,initial_time=1990);fails(export_html(x,tempfile()),"initial_time")
if(requireNamespace("sf",quietly=TRUE)) {
  temp <- tempfile();dir.create(temp);previous <- getwd();setwd(temp)
  source(system.file("examples","eu.R",package="offlineatlas"),local=TRUE)
  setwd(previous)
  counts <- vapply(eu$area_frames,function(frame)sum(frame$data$value_1!="Not a member"),integer(1))
  stopifnot(identical(unname(counts),c(6L,9L,10L,12L,15L,25L,27L,28L,27L)),
    "MLT" %in% eu$areas$id, "CYP" %in% eu$areas$id,
    !any(c("CYN","ALA","GRL") %in% eu$areas$id))
  for(frame in eu$area_frames) {
    if(as.integer(frame$time)>=2004)stopifnot(frame$data$value_1[frame$data$id=="MLT"]=="2004")
  }
  unlink(temp,recursive=TRUE)
}
cat("Categorical areas, complete time panels, and EU membership counts passed\n")
