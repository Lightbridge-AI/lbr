% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/write_custom_excel.R
\name{write_custom_xlsx}
\alias{write_custom_xlsx}
\title{Write Custom Excel}
\usage{
write_custom_xlsx(
  x,
  file,
  asTable = F,
  borders = "columns",
  keepNA = F,
  colWidths = 8.43,
  freeze_firstRow = F,
  freeze_firstCol = F,
  head_text = "bold",
  head_fgfill = "#d9ead3",
  head_border = "TopBottomLeftRight",
  head_halign = "center",
  head_valign = "center",
  return_wb = F,
  ...
)
}
\arguments{
\item{x}{Object or a list of objects that can be handled by \code{openxlsx::writeData} to write to file}

\item{file}{xlsx file name}

\item{asTable}{Write using writeDataTable as opposed to writeData}

\item{borders}{Cell borders, Either "surrounding", "columns" or "rows" or NULL. If "surrounding", a border is drawn around the data. If "rows", a surrounding border is drawn a border around each row. If "columns", a surrounding border is drawn with a border between each column. If "all" all cell borders are drawn}

\item{keepNA}{If \code{TRUE}, NA values are converted to #N/A (or na.string, if not \code{NULL}) in Excel, else \code{NA} cells will be empty. Defaults to \code{FALSE}.}

\item{colWidths}{May be a single value for all columns (or "auto"), or a list of vectors that will be recycled for each sheet}

\item{freeze_firstRow}{If \code{TRUE}, freezes the first row (equivalent to firstActiveRow = 2)}

\item{freeze_firstCol}{If \code{TRUE}, freezes the first column (equivalent to firstActiveCol = 2)}

\item{head_text}{Header text styling - one of "bold", "strikeout", "italic", "underline", "underline2" (passed to \code{openxlsx::createStyle})}

\item{head_fgfill}{Header cell foreground fill colour. (passed to \code{openxlsx::createStyle})}

\item{head_border}{Header Cell border. A vector of "top", "bottom", "left", "right" or a single string). (passed to \code{openxlsx::createStyle})}

\item{head_halign}{Header Horizontal alignment of cell contents (passed to \code{openxlsx::createStyle})}

\item{head_valign}{Header Vertical alignment of cell contents (passed to \code{openxlsx::createStyle})}

\item{return_wb}{If \code{TRUE} Return workbook object.}

\item{...}{to \code{openxlsx::write.xlsx}}
}
\value{
Input Data \code{x} or workbook object
}
\description{
A Wrapper around \code{openxlsx::write.xlsx}
}
\examples{
# write_custom_xlsx(list(a = iris, b = mtcars), "path/to/file.xlsx")
}
