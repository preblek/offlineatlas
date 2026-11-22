# A banded guide preserves the existing discrete map scale and its open tails.
bar_tick_labels <- function(values, options = NULL) {
  vapply(values, function(value) {
    divisor <- if (abs(value) >= 1e9) 1e9 else if (abs(value) >= 1e6) 1e6 else if (abs(value) >= 1e3) 1e3 else 1
    scaled <- value / divisor
    if (divisor == 1 || abs(scaled * 100 - round(scaled * 100)) > 1e-8)
      return(format_atlas_numbers(value, options))
    format <- if (is.null(options)) list(style = "number") else options
    format$digits <- if (scaled == round(scaled)) 0L else 2L
    paste0(format_atlas_numbers(scaled, format), if(divisor==1e9) "B" else if(divisor==1e6) "M" else "K")
  }, character(1), USE.NAMES = FALSE)
}

area_bar_guide <- function(v, colors, labels, title, family, position, aliases = NULL) {
  n <- length(v$breaks) + 1L
  ticks <- if (is.null(aliases)) bar_tick_labels(unlist(v$breaks), v$number_format) else unlist(aliases)
  ticks <- vapply(ticks, function(s) paste(strwrap(s, width=14), collapse="\n"), character(1))
  positions <- if (is.null(aliases)) seq_len(n-1) / n else (seq_len(n) - .5) / n
  special <- if (length(labels)>n) seq.int(n+1,length(labels)) else integer()
  special_labels <- vapply(labels[special],function(s)paste(strwrap(s,width=65),collapse="\n"),character(1))
  lines <- function(s) lengths(strsplit(s,"\n",fixed=TRUE))
  tick_height <- max(lines(ticks)) * 3.4
  special_heights <- pmax(5, lines(special_labels) * 3.4 + 2)
  height <- 23 + tick_height + sum(special_heights)
  width <- if(position=="right") 90 else 140
  left <- 8;bar_width <- width-16
  mm <- function(n)grid::unit(n,"mm")
  parts <- list(grid::rectGrob(x=mm(left+(seq_len(n)-.5)*bar_width/n), y=mm(height-5),
    width=mm(bar_width/n), height=mm(4), gp=grid::gpar(fill=colors[seq_len(n)],col=NA)))
  parts[[length(parts)+1]] <- grid::rectGrob(x=mm(width/2),y=mm(height-5),width=mm(bar_width),height=mm(4),gp=grid::gpar(fill=NA,col="#8a9a92",lwd=.5))
  parts[[length(parts)+1]] <- grid::segmentsGrob(x0=mm(left+positions*bar_width),x1=mm(left+positions*bar_width),y0=mm(height-7),y1=mm(height-9),gp=grid::gpar(col="#203d42",lwd=.5))
  parts[[length(parts)+1]] <- grid::textGrob(ticks,x=mm(left+positions*bar_width),y=mm(height-10),just=c("centre","top"),gp=grid::gpar(fontsize=8,fontfamily=family,col="#203d42"))
  y <- height-12-tick_height
  parts[[length(parts)+1]] <- grid::textGrob("Equal-width bands show intervals, not a linear numeric scale.",x=mm(left),y=mm(y),just=c("left","top"),gp=grid::gpar(fontsize=7,fontfamily=family,col="#5d7073"))
  y <- y-7
  for (j in seq_along(special)) {
    i <- special[j]
    parts[[length(parts)+1]] <- grid::rectGrob(x=mm(left+1.5),y=mm(y-1.5),width=mm(3),height=mm(3),gp=grid::gpar(fill=colors[i],col="#8a9a92",lwd=.5))
    parts[[length(parts)+1]] <- grid::textGrob(special_labels[j],x=mm(left+6),y=mm(y),just=c("left","top"),gp=grid::gpar(fontsize=8,fontfamily=family,col="#203d42"))
    y <- y-special_heights[j]
  }
  if (!is.null(title) && nzchar(title)) {
    heading <- paste(strwrap(title,width=75),collapse="\n")
    extra <- lines(heading)*4+3
    parts[[length(parts)+1]] <- grid::textGrob(heading,x=mm(left),y=mm(height+extra-1),
      just=c("left","top"),gp=grid::gpar(fontsize=9,fontfamily=family,col="#203d42"))
    height <- height+extra
  }
  grob <- grid::gTree(children=do.call(grid::gList,parts),name="offlineatlas-color-bar")
  ggplot2::guide_custom(grob,width=mm(width),height=mm(height),position=position)
}
