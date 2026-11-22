# Presentation setters preserve prepared data, geometry, frames and other options.
area_variable_indices <- function(x, variable = NULL, numeric_only = FALSE) {
  check_atlas(x)
  if (!length(x$variables)) stop("Add area variables first", call. = FALSE)
  columns <- vapply(x$variables, function(v) v$source_column, character(1))
  numeric <- !vapply(x$variables, function(v) identical(v$type, "categorical"), logical(1))
  if (is.null(variable)) indices <- if (numeric_only) which(numeric) else seq_along(columns)
  else {
    if (!is.character(variable) || !length(variable) || anyNA(variable) || anyDuplicated(variable) ||
        any(!variable %in% columns)) stop("variable must name existing area variables", call. = FALSE)
    indices <- match(variable, columns)
  }
  if (!length(indices)) stop("No numeric area variables selected", call. = FALSE)
  if (numeric_only && any(!numeric[indices])) stop("Select numeric area variables", call. = FALSE)
  indices
}

hex_colors <- function(value, what, nullable = FALSE) {
  if (nullable && is.null(value)) return(invisible(NULL))
  if (!is.character(value) || !length(value) || anyNA(value) ||
      any(!grepl("^#[0-9a-fA-F]{6}$", value)))
    stop(what, " must use six-digit hex colors", call. = FALSE)
  invisible(NULL)
}

set_palette <- function(x, colors = NULL, variable = NULL, zero_color = NULL,
                        missing_color = NULL, border_color = NULL, border_width = NULL,
                        zero_label = "Recorded zero") {
  check_atlas(x)
  # Numeric variables are the default; categorical palettes require an explicit variable.
  indices <- area_variable_indices(x, variable, numeric_only = is.null(variable))
  for (name in c("zero_color", "missing_color", "border_color")) {
    value <- get(name)
    hex_colors(value, name, nullable = TRUE)
    if (!is.null(value) && length(value) != 1L) stop(name, " must be one color", call. = FALSE)
  }
  if (!is.null(border_width) && (!is.numeric(border_width) || length(border_width) != 1L ||
      !is.finite(border_width) || border_width < 0 || border_width > 10))
    stop("border_width must be a number from 0 to 10", call. = FALSE)
  scalar_text(zero_label, "zero_label")
  if (!is.null(colors)) hex_colors(colors, "colors")
  for (i in indices) {
    v <- x$variables[[i]]
    categorical <- identical(v$type, "categorical")
    if (!is.null(colors)) {
      count <- if (categorical) length(v$categories) else length(v$breaks) + 1L
      if (length(colors) != count) stop("colors needs one color per interval or category for ", v$source_column, call. = FALSE)
      v$colors <- unname(as.list(colors))
    }
    if (!missing(zero_color)) {
      if (categorical && !is.null(zero_color)) stop("zero_color is only for numeric variables", call. = FALSE)
      v$zero_color <- zero_color
    }
    if (!missing(zero_label) || !missing(zero_color)) v$zero_label <- zero_label
    if (!missing(missing_color)) v$missing_color <- missing_color
    x$variables[[i]] <- v
  }
  if (!missing(border_color)) x$area_style$border_color <- border_color
  if (!missing(border_width)) x$area_style$border_width <- border_width
  x
}

set_number_format <- function(x, style = c("number", "currency"), currency = "USD",
                              digits = NULL, variable = NULL) {
  check_atlas(x)
  style <- match.arg(style)
  if (!is.character(currency) || length(currency) != 1L || is.na(currency) ||
      !grepl("^[A-Z]{3}$", currency)) stop("currency must be a three-letter uppercase currency code", call. = FALSE)
  if (is.null(digits)) digits <- if (style == "currency") 2L else NULL
  if (!is.null(digits) && (!is.numeric(digits) || length(digits) != 1L ||
      !is.finite(digits) || digits != as.integer(digits) || digits < 0 || digits > 6))
    stop("digits must be NULL or an integer from 0 to 6", call. = FALSE)
  format <- list(style = style, currency = currency, digits = digits)
  if (length(x$variables)) {
    indices <- area_variable_indices(x, variable, numeric_only = TRUE)
    for (i in indices) x$variables[[i]]$number_format <- format
  } else {
    if (!is.null(variable)) stop("variable is only available for area variables", call. = FALSE)
    x$number_format <- format
  }
  x
}

format_atlas_numbers <- function(values, options = NULL) {
  if (is.null(options)) return(format(round(values, 2), trim = TRUE, scientific = FALSE, big.mark = ","))
  digits <- options$digits
  if (is.null(digits)) return(format_atlas_numbers(values))
  out <- formatC(abs(values), format = "f", digits = digits, big.mark = ",")
  symbol <- ""
  if (identical(options$style, "currency")) {
    symbols <- c(USD = "$", EUR = "\u20ac", GBP = "\u00a3", JPY = "\u00a5", CAD = "$", AUD = "$")
    symbol <- if (options$currency %in% names(symbols)) unname(symbols[options$currency]) else paste0(options$currency, " ")
  }
  paste0(ifelse(values < 0, "-", ""), symbol, out)
}

set_selection_card <- function(x, visible = TRUE,
                               position = c("top_right", "top_left", "bottom_right", "bottom_left")) {
  check_atlas(x)
  if (!is.logical(visible) || length(visible) != 1L || is.na(visible))
    stop("visible must be TRUE or FALSE", call. = FALSE)
  x$selection_card <- list(visible = visible, position = match.arg(position))
  x
}

set_export_options <- function(x, title = NULL, subtitle = NULL, prompt = TRUE) {
  check_atlas(x)
  if (!is.null(title)) scalar_text(title, "Export title", empty = TRUE)
  if (!is.null(subtitle)) scalar_text(subtitle, "Export subtitle", empty = TRUE)
  if (!is.logical(prompt) || length(prompt) != 1L || is.na(prompt))
    stop("prompt must be TRUE or FALSE", call. = FALSE)
  x$figure_export <- list(title = title, subtitle = subtitle, prompt = prompt)
  x
}
