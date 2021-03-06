% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read_dir_csv_2.R
\name{read_dir_csv_2}
\alias{read_dir_csv_2}
\title{Read CSV files form a directory}
\usage{
read_dir_csv_2(
  dir_path = NULL,
  ...,
  file_pattern = "\\\\.csv$",
  strict_csv_ext = T,
  recursive = F,
  snake_case = F
)
}
\arguments{
\item{dir_path}{Path to desired directory. If \code{NULL}, path to current working directory is assumed.}

\item{...}{Argument to pass to \code{readr::read_csv()}}

\item{file_pattern}{Regular expression to read from file name, default = "\\.csv$"}

\item{strict_csv_ext}{If \code{TRUE} (default): Strictly read only .csv file}

\item{recursive}{If \code{TRUE}: Also read in sub-directory}

\item{snake_case}{If \code{TRUE}: include snake_case in file_names (require snakecase package)}
}
\value{
A list of tibbles
}
\description{
Suggest use \code{lbr::read_dir_csv()} instead.
}
\examples{
# Not run
if(FALSE){
# Read form current working directory by default
  read_dir_csv_2()
# And file names are set to names of each data frame in a list

# Give a directory path
  read_dir_csv_2("path/to/dir")

# Also, can read from every sub-directory of given directory
  read_dir_csv_2("path/to/dir", recursive = T)

# Can specify regular expression of file names to read
  read_dir_csv_2(file_pattern = "[:digit:]+\\\\.csv$")  # file name contains numbers

# If set strict_csv_ext = F and remove regex which require file name ending with .csv
# it might read other file type as well (if you like)
  read_dir_csv_2(file_pattern = "[:digit:]+", strict_csv_ext = F)

# If you want file names in snake_case (require snakecase package)
  read_dir_csv_2(snake_case = T)
}
}
