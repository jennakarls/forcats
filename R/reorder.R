#' Reorder factor levels by sorting along another variable
#'
#' `fct_reorder()` is useful for 1d displays where the factor is mapped to
#' position; `fct_reorder2()` for 2d displays where the factor is mapped to
#' a non-position aesthetic. `last2()` and `first2()` are helpers for `fct_reorder2()`;
#' `last2()` finds the last value of `y` when sorted by `x`; `first2()` finds the first value.
#'
#' @param .f A factor (or character vector).
#' @param .x,.y The levels of `f` are reordered so that the values
#'    of `.fun(.x)` (for `fct_reorder()`) and `fun(.x, .y)` (for `fct_reorder2()`)
#'    are in ascending order.
#' @param .fun n summary function. It should take one vector for
#'   `fct_reorder`, and two vectors for `fct_reorder2`, and return a single
#'   value.
#' @param ... Other arguments passed on to `.fun`. A common argument is
#'   `na.rm = TRUE`.
#' @param .desc Order in descending order? Note the default is different
#'   between `fct_reorder` and `fct_reorder2`, in order to
#'   match the default ordering of factors in the legend.
#' @importFrom stats median
#' @export
#' @examples
#' boxplot(Sepal.Width ~ Species, data = iris)
#' boxplot(Sepal.Width ~ fct_reorder(Species, Sepal.Width), data = iris)
#' boxplot(Sepal.Width ~ fct_reorder(Species, Sepal.Width, .desc = TRUE), data = iris)
#'
#' chks <- subset(ChickWeight, as.integer(Chick) < 10)
#' chks <- transform(chks, Chick = fct_shuffle(Chick))
#'
#' if (require("ggplot2")) {
#' ggplot(chks, aes(Time, weight, colour = Chick)) +
#'   geom_point() +
#'   geom_line()
#'
#' # Note that lines match order in legend
#' ggplot(chks, aes(Time, weight, colour = fct_reorder2(Chick, Time, weight))) +
#'   geom_point() +
#'   geom_line() +
#'   labs(colour = "Chick")
#' }
fct_reorder <- function(.f, .x, .fun = median, ..., .desc = FALSE) {
  f <- check_factor(.f)
  stopifnot(length(f) == length(.x))
  ellipsis::check_dots_used()

  summary <- tapply(.x, .f, .fun, ...)
  # This is a bit of a weak test, but should detect the most common case
  # where `.fun` returns multiple values.
  if (is.list(summary)) {
    stop("`fun` must return a single value per group", call. = FALSE)
  }

  lvls_reorder(f, order(summary, decreasing = .desc))
}

#' @export
#' @rdname fct_reorder
fct_reorder2 <- function(.f, .x, .y, .fun = last2, ..., .desc = TRUE) {
  f <- check_factor(.f)
  stopifnot(length(f) == length(.x), length(.x) == length(.y))
  ellipsis::check_dots_used()

  summary <- tapply(seq_along(.x), f, function(i) .fun(.x[i], .y[i], ...))
  if (is.list(summary)) {
    stop("`fun` must return a single value per group", call. = FALSE)
  }

  lvls_reorder(.f, order(summary, decreasing = .desc))
}


#' @export
#' @rdname fct_reorder
last2 <- function(.x, .y) {
  .y[order(.x, na.last = FALSE)][length(.y)]
}

#' @export
#' @rdname fct_reorder
first2 <- function(.x, .y) {
  .y[order(.x)][1]
}



#' Reorder factors levels by first appearance, frequency, or numeric order.
#'
#' @inheritParams lvls_reorder
#' @param f A factor
#' @export
#' @examples
#' f <- factor(c("b", "b", "a", "c", "c", "c"))
#' f
#' fct_inorder(f)
#' fct_infreq(f)
#'
#' fct_inorder(f, ordered = TRUE)
#'
#' f <- factor(sample(1:10))
#' fct_inseq(f)
fct_inorder <- function(f, ordered = NA) {
  f <- check_factor(f)

  idx <- as.integer(f)[!duplicated(f)]
  idx <- idx[!is.na(idx)]
  lvls_reorder(f, idx, ordered = ordered)
}

#' @export
#' @rdname fct_inorder
fct_infreq <- function(f, ordered = NA) {
  f <- check_factor(f)

  lvls_reorder(f, order(table(f), decreasing = TRUE), ordered = ordered)
}

#' @export
#' @rdname fct_inorder
fct_inseq <- function(f, ordered = NA) {
  f <- check_factor(f)

  num_levels <- suppressWarnings(as.numeric(levels(f)))
  new_levels <- sort(num_levels)

  if (length(new_levels) == 0) {
    stop("At least one existing level must be coercible to numeric.", call. = FALSE)
  }

  refactor(f, new_levels, ordered = ordered)
}

