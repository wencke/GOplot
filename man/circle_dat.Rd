% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/GOCore.R
\name{circle_dat}
\alias{circle_dat}
\title{Creates a plotting object.}
\usage{
circle_dat(terms, genes)
}
\arguments{
\item{terms}{A data frame with columns for 'category', 'ID', 'term', adjusted
p-value ('adj_pval') and 'genes'}

\item{genes}{A data frame with columns for 'ID', 'logFC'}
}
\description{
The function takes the results from a functional analysis (for
  example DAVID) and combines it with a list of selected genes and their
  logFC. The resulting data frame can be used as an input for various ploting
  functions.
}
\details{


Since most of the gene- annotation enrichment analysis are based on
  the gene ontology database the package was build with this structure in
  mind, but is not restricted to it. Gene ontology is structured as an
  acyclic graph and it provides terms covering different areas. These terms
  are grouped into three independent \code{categories}: BP (biological
  process), CC (cellular component) or MF (molecular function).

  The "ID" and "term" columns of the \code{terms} data frame refer to the ID
  and term description, whereas the ID is optional.

  The "ID" column of the \code{genes} data frame can contain any unique
  identifier. Nevertheless, the identifier has to be the same as in "genes"
  from \code{terms}.
}
\examples{
\dontrun{
#Load the included dataset
data(EC)

#Building the circ object
circ<-circular_dat(EC$david, EC$genelist)
}
}

