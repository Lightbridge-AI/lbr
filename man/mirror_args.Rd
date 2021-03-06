% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/usethis.R
\name{mirror_args}
\alias{mirror_args}
\title{Mirror function arguments}
\usage{
mirror_args(..., .new_line = F)
}
\arguments{
\item{...}{Arguments that has \code{Name = Value} pair}

\item{.new_line}{(logical) Print out each arguments in new line or not}
}
\value{
print to console
}
\description{
Mirror names of ... to Rt side. Use to write function argument faster
}
\examples{
mirror_args(x = 5, y = NULL, z = "hi")
}
