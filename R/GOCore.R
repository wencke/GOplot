#' Transcriptomic information of endothelial cells.
#' 
#' The data set contains the transcriptomic information of endothelial cells
#' from two steady state tissues (brain and heart). More detailed information
#' can be found in the paper by Nolan et al. 2013. The data was normalized and a
#' statistical analysis was performed to determine differentially expressed
#' genes. DAVID functional annotation tool was used to perform a gene-
#' annotation enrichment analysis of the set of differentially expressed genes
#' (adjusted p-value < 0.05).
#' 
#' @docType data
#' @keywords datasets
#' @name EC
#' @usage data(EC)
#' @format A list containing 5 items 
#' @source \url{http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE47067}
"EC"

#' theme blank
#'
#' @name theme_blank
#' @import ggplot2
#' 

theme_blank <- theme(axis.line = element_blank(), axis.text.x = element_blank(),
                     axis.text.y = element_blank(), axis.ticks = element_blank(), axis.title.x = element_blank(),
                     axis.title.y = element_blank(), panel.background = element_blank(), panel.border = element_blank(),
                     panel.grid.major = element_blank(), panel.grid.minor = element_blank(), plot.background = element_blank())

#' draw table
#'
#' @name draw_table
#' @param data data frame; GO ID and GO term
#' @param col character; defines color of table header
#' @import ggplot2
#' @import gridExtra  
#' 

draw_table <- function(data, col = ''){
  id <- term <- NULL
  colnames(data) <- tolower(colnames(data))
  if (length(col) == 1){
    tt1 <- ttheme_default()
  }else{
    text.col <- c(rep(col[1], sum(data$category == 'BP')), rep(col[2], sum(data$category == 'CC')), rep(col[3], sum(data$category == 'MF')))
    tt1 <- ttheme_minimal(core=list(fg.par = list(size = 4), bg.par = list(fill = text.col, col=NA, alpha= 1/3)), colhead=list(fg.par=list(col="black")))
  }
  table <- tableGrob(subset(data, select = c(id, term)), cols = c('ID', 'Describtion'), rows = NULL, theme = tt1)
  return(table)
}

#' bezier
#'
#' @name bezier
#' @param data data frame x.start,x.end,y.start,y.end
#' @param process.col Color of the processes
#' @import grDevices
#' 

bezier <- function(data, process.col){
  x <- c()
  y <- c()
  Id <- c()
  sequ <- seq(0, 1, by = 0.01)
  N <- dim(data)[1]
  sN <- seq(1, N, by = 2)
  if (process.col[1] == '') col_rain <- grDevices::rainbow(N) else col_rain <- process.col
  for (n in sN){
    xval <- c(); xval2 <- c(); yval <- c(); yval2 <- c()
    for (t in sequ){
      xva <- (1 - t) * (1 - t) * data$x.start[n] + t * t * data$x.end[n]
      xval <- c(xval, xva)
      xva2 <- (1 - t) * (1 - t) * data$x.start[n + 1] + t * t * data$x.end[n + 1]
      xval2 <- c(xval2, xva2)
      yva <- (1 - t) * (1 - t) * data$y.start[n] + t * t * data$y.end[n]	
      yval <- c(yval, yva)
      yva2 <- (1 - t) * (1 - t) * data$y.start[n + 1] + t * t * data$y.end[n + 1]
      yval2 <- c(yval2, yva2)			
    }
    x <- c(x, xval, rev(xval2))
    y <- c(y, yval, rev(yval2))
    Id <- c(Id, rep(n, 2 * length(sequ)))
  }
  df <- data.frame(lx = x, ly = y, ID = Id)
  return(df)
}

#' 
#' @name circle_dat
#' @title Creates a plotting object.
#' @description The function takes the results from a functional analysis (for 
#'   example DAVID) and combines it with a list of selected genes and their 
#'   logFC. The resulting data frame can be used as an input for various ploting
#'   functions.
#' @param terms A data frame with columns for 'category', 'ID', 'term', adjusted
#'   p-value ('adj_pval') and 'genes'
#' @param genes A data frame with columns for 'ID', 'logFC'
#' @details Since most of the gene- annotation enrichment analysis are based on 
#'   the gene ontology database the package was build with this structure in 
#'   mind, but is not restricted to it. Gene ontology is structured as an 
#'   acyclic graph and it provides terms covering different areas. These terms 
#'   are grouped into three independent \code{categories}: BP (biological 
#'   process), CC (cellular component) or MF (molecular function).
#'   
#'   The "ID" and "term" columns of the \code{terms} data frame refer to the ID 
#'   and term description, whereas the ID is optional.
#'   
#'   The "ID" column of the \code{genes} data frame can contain any unique 
#'   identifier. Nevertheless, the identifier has to be the same as in "genes" 
#'   from \code{terms}.
#' @examples
#' \dontrun{
#' #Load the included dataset
#' data(EC)
#' 
#' #Building the circ object
#' circ<-circular_dat(EC$david, EC$genelist)
#' }
#' @export

circle_dat <- function(terms, genes){
  
  colnames(terms) <- tolower(colnames(terms))
  terms$genes <- toupper(terms$genes)
  genes$ID <- toupper(genes$ID)
  tgenes <- strsplit(as.vector(terms$genes), ', ')
  if (length(tgenes[[1]]) == 1) tgenes <- strsplit(as.vector(terms$genes), ',')
  count <- sapply(1:length(tgenes), function(x) length(tgenes[[x]]))
  logFC <- sapply(unlist(tgenes), function(x) genes$logFC[match(x, genes$ID)])
  if(class(logFC) == 'factor'){
    logFC <- gsub(",", ".", gsub("\\.", "", logFC))
    logFC <- as.numeric(logFC)
  }
  s <- 1; zsc <- c()
  for (c in 1:length(count)){
    value <- 0
    e <- s + count[c] - 1
    value <- sapply(logFC[s:e], function(x) ifelse(x > 0, 1, -1))
    zsc <- c(zsc, sum(value) / sqrt(count[c]))
    s <- e + 1
  }
  if (is.null(terms$id)){
    df <- data.frame(category = rep(as.character(terms$category), count), term = rep(as.character(terms$term), count),
                     count = rep(count, count), genes = as.character(unlist(tgenes)), logFC = logFC, adj_pval = rep(terms$adj_pval, count),
                     zscore = rep(zsc, count), stringsAsFactors = FALSE)
  }else{
    df <- data.frame(category = rep(as.character(terms$category), count), ID = rep(as.character(terms$id), count), term = rep(as.character(terms$term), count),
                     count = rep(count, count), genes = as.character(unlist(tgenes)), logFC = logFC, adj_pval = rep(terms$adj_pval, count),
                     zscore = rep(zsc, count), stringsAsFactors = FALSE)
  }
  return(df)
}

#' 
#' @name chord_dat
#' @title Creates a binary matrix.
#' @description The function creates a matrix which represents the binary 
#'   relation (1= is related to, 0= is not related to) between selected genes 
#'   (row) and processes (column). The resulting matrix can be visualized with 
#'   the \code{\link{GOChord}} function.
#' @param data A data frame with at least two coloumns: GO ID|term and genes. 
#'   Each row contains exactly one GO ID|term and one gene. A column containing
#'   logFC values is optional and might be used if \code{genes} is missing.
#' @param genes A character vector of selected genes OR data frame with coloumns
#'   for gene ID and logFC.
#' @param limit A vector with two cutoff values (default= c(0,0)). The first 
#'   value defines the minimum number of terms a gene has to be assigned to. The
#'   second the minimum number of genes assigned to a selected term.
#' @details If more than one logFC value for each gene is at disposal, only one 
#'   should be used to create the binary matrix. The other values have to be 
#'   added manually later. The parameter \code{limit} can be used to reduce the 
#'   dimension of the calculated matrix. This might be useful to represent the 
#'   data more clearly with \code{GOChord} later on. The first value of the 
#'   vector defines the threshold for the minimum number of terms a gene has to 
#'   be assigned to in order to be represented in the plot. Most of the time it 
#'   is more meaningful to represent genes with various functions. A value of 3 
#'   excludes all genes with less than three term assignments. Whereas the 
#'   second value of the parameter restricts the number of terms according to 
#'   the number of assigned genes. All terms with a count smaller or equal to 
#'   the threshold are excluded.
#' @param process A character vector of selected processes
#' @return A binary matrix
#' @seealso \code{\link{GOChord}}
#' @examples
#' \dontrun{
#' # Load the included dataset
#' data(EC)
#' 
#' # Building the circ object
#' circ <- circular_dat(EC$david, EC$genelist)
#' 
#' # Building the binary matrix
#' chord <- chord_dat(circ, EC$genes, EC$process)
#' 
#' # Excluding genes which are assigned only to a single term
#' chord <- chord_dat(circ, EC$genes, EC$process, limit = c(1,0))
#' 
#' # Excluding terms with a count smaller than 5
#' chord <- chord_dat(circ, EC$genes, EC$process, limit = c(0,5))
#' 
#' }
#' @export

chord_dat <- function(data, genes, process, limit){
  id <- term <- logFC <- BPprocess <- NULL

  if (missing(limit)) limit <- c(0, 0)
  if (missing(genes)){
    if (is.null(data$logFC)){
      genes <- unique(data$genes)
    }else{
      genes <- subset(data, !duplicated(genes), c(genes, logFC))
    }
  }else{
    if(is.vector(genes)){
      genes <- as.character(genes) 
    }else{
      if(class(genes[, 2]) != 'numeric') genes[, 2] <- as.numeric(levels(genes[, 2]))[genes[, 2]]
      genes[, 1] <- as.character(genes[, 1])
      colnames(genes) <- c('genes', 'logFC')
    }
  }
  if (missing(process)){
    process <- unique(data$term)
  }else{
    if(class(process) != 'character') process <- as.character(process)
  }
  if (strsplit(process[1],':')[[1]][1] == 'GO'){
    subData <- subset(data, id%in%process)
    colnames(subData)[which(colnames(subData) == 'id')] <- 'BPprocess'
  }else{
    subData <- subset(data, term%in%process)
    colnames(subData)[which(colnames(subData) == 'term')] <- 'BPprocess'
  }
  
  if(is.vector(genes)){
    M <- genes[genes%in%unique(subData$genes)]
    mat <- matrix(0, ncol = length(process), nrow = length(M))
    rownames(mat) <- M
    colnames(mat) <- process
    for (p in 1:length(process)){
      sub2 <- subset(subData, BPprocess == process[p])
      for (g in 1:length(M)) mat[g, p] <- ifelse(M[g]%in%sub2$genes, 1, 0)
    }
  }else{
    genes <- subset(genes, genes %in% unique(subData$genes))
    N <- length(process) + 1
    M <- genes[,1] 
    mat <- matrix(0, ncol = N, nrow = length(M))
    rownames(mat) <- M
    colnames(mat) <- c(process, 'logFC') 
    mat[,N] <- genes[,2]
    for (p in 1:(N-1)){
      sub2 <- subset(subData, BPprocess == process[p])
      for (g in 1:length(M)) mat[g, p] <- ifelse(M[g]%in%sub2$genes, 1, 0)
    }
  }
  return(mat)
}

#' 
#' @name GOBubble
#' @title Bubble plot.
#' @description The function creates a bubble plot of the input \code{data}. The
#'   input \code{data} can be created with the help of the 
#'   \code{\link{circle_dat}} function.
#' @param data A data frame with coloumns for category, GO ID, term, adjusted 
#'   p-value, z-score, count(num of genes)
#' @param display A character vector. Indicates whether it should be a single 
#'   plot ('single') or a facet plot with panels for each category 
#'   (default='single')
#' @param title The title (on top) of the plot
#' @param color A character vector which defines the color of the bubbles for 
#'   each category
#' @param labels Sets a threshold for the displayed labels. The threshold refers
#'   to the -log(adjusted p-value) (default=5)
#' @param ID If TRUE then labels are IDs else terms
#' @param table.legend Defines whether a table of GO ID and GO term should be 
#'   displayed on the right side of the plot or not (default = TRUE)
#' @param table.col If TRUE then the table entries are colored according to 
#'   their category, if FALSE then entries are black
#' @details The x- axis of the plot represents the z-score. The negative
#'   logarithm of the adjusted p-value (corresponding to the significance of the
#'   term) is displayed on the y-axis. The area of the plotted circles is 
#'   proportional to the number of genes assigned to the term. Each circle is 
#'   colored according to its category and labeled alternatively with the ID or 
#'   term name.If static is set to FALSE the mouse hover effect will be enabled.
#' @import ggplot2
#' @import gridExtra
#' @import graphics
#' @examples
#' \dontrun{
#' #Load the included dataset
#' data(EC)
#' 
#' #Building the circ object
#' circ<-circular_dat(EC$david, EC$genelist)
#' 
#' #Creating the bubble plot coloring the table entries according to the category
#' GOBubble(circ, table.col=T)
#' 
#' #Creating the bubble plot displaying the term instead of the ID and without the table
#' GOBubble(circ,ID=F,table.legend=F)
#' 
#' #Faceting the plot
#' GOBubble(circ, display='multiple')
#' }
#' @export
GOBubble <- function(data, display, title, color, labels, ID = T, table.legend = T, table.col = T){
  zscore <- adj_pval <- category <- count <- id <- term <- NULL
  if (missing(display)) display <- 'single'
  if (missing(title)) title <- ''
  if (missing(color)) cols <- c("chartreuse4", "brown2", "cornflowerblue") else cols <- color
  if (missing(labels)) labels <- 5
  
  colnames(data) <- tolower(colnames(data))
  if(!'count'%in%colnames(data)){
    rang <- c(5, 5)
    data$count <- rep(1, dim(data)[1])
  }else {rang <- c(1, 30)}
  data$adj_pval <- -log(data$adj_pval, 10)
  sub <- data[!duplicated(data$term), ]
  g <- ggplot(sub, aes(zscore, adj_pval))+
    labs(title = title, x = 'z-score', y = '-log (adj p-value)')+
    geom_point(aes(col = category, size = count), alpha = 1 / 2)+
    geom_hline(yintercept = 1.3, col = 'orange')+
    scale_size(range = rang, guide = 'none')
  if (!is.character(labels)) sub2 <- subset(sub, subset = sub$adj_pval >= labels) else sub2 <- subset(sub, sub$id%in%labels | sub$term%in%labels)
  if (display == 'single'){
    g <- g + scale_colour_manual('Category', values = cols, labels = c('Biological Process', 'Cellular Component', 'Molecular Function'))+
      theme(legend.position = 'bottom')+
      annotate ("text", x = min(sub$zscore), y = 1.5, label = "threshold", colour = "orange", size = 3)
    if (ID) g <- g+ geom_text(data = sub2, aes(x = zscore, y = adj_pval, label = id), size = 5) else g <- g + geom_text(data = sub2, aes(x = zscore, y = adj_pval, label = term), size = 4)
    if (table.legend){
      if (table.col) table <- draw_table(sub2, col = cols) else table <- draw_table(sub2)
      g <- g + theme(axis.line = element_line(color = 'grey80'), axis.ticks = element_line(color = 'grey80'), panel.background = element_blank(),
                     panel.grid.minor = element_blank(), panel.grid.major = element_line(color = 'grey80'), plot.background = element_blank()) 
      graphics::par(mar = c(0.1, 0.1, 0.1, 0.1))
      grid.arrange(g, table, ncol = 2)
    }else{
      g + theme(axis.line = element_line(color = 'grey80'), axis.ticks = element_line(color = 'grey80'), panel.background = element_blank(),
                panel.grid.minor = element_blank(), panel.grid.major = element_line(color = 'grey80'), plot.background = element_blank())
    }
  }else{
    g <- g + facet_grid(.~category, space = 'free_x', scales = 'free_x') + scale_colour_manual(values = cols, guide ='none')
    if (ID) {
      g + geom_text(data = sub2, aes(x = zscore, y = adj_pval, label = id), size = 5) + 
        theme(axis.line = element_line(color = 'grey80'), axis.ticks = element_line(color = 'grey80'), panel.border = element_rect(fill = 'transparent', color = 'grey80'),
              panel.background = element_blank(), panel.grid = element_blank(), plot.background = element_blank()) 
    }else{
      g + geom_text(data = sub2, aes(x = zscore, y = adj_pval, label = term), size = 5) + 
        theme(axis.line = element_line(color = 'grey80'), axis.ticks = element_line(color = 'grey80'), panel.border = element_rect(fill = 'transparent', color = 'grey80'),
              panel.background = element_blank(), panel.grid = element_blank(), plot.background = element_blank())
    }
  }
}

#' 
#' @name GOBar
#' @title Z-score colored barplot.
#' @description Z-score colored barplot of terms ordered alternatively by 
#'   z-score or the negative logarithm of the adjusted p-value
#' @param data A data frame containing at least the term ID and/or term, the 
#'   adjusted p-value and the z-score. A possible input can be generated with 
#'   the \code{circle_dat} function
#' @param display A character vector indicating whether a single plot ('single')
#'   or a facet plot with panels for each category should be drawn 
#'   (default='single')
#' @param order.by.zscore Defines the order of the bars. If TRUE the bars are 
#'   ordered according to the z-scores of the processes. Otherwise the bars are 
#'   ordered by the negative logarithm of the adjusted p-value
#' @param title The title of the plot
#' @param zsc.col Character vector to define the color scale for the z-score of 
#'   the form c(high, midpoint,low)
#' @details If \code{display} is used to facet the plot the width of the panels 
#'   will be proportional to the length of the x scale.
#' @import ggplot2
#' @import gridExtra
#' @import stats
#' @examples
#' \dontrun{
#' #Load the included dataset
#' data(EC)
#' 
#' #Building the circ object
#' circ<-circular_dat(EC$david, EC$genelist)
#' 
#' #Creating the bar plot
#' GOBar(circ)
#' 
#' #Faceting the plot
#' GOBar(circ, display='multiple')
#' }
#' @export

GOBar <- function(data, display, order.by.zscore = T, title, zsc.col){
  id <- adj_pval <- zscore <- NULL
  if (missing(display)) display <- 'single'
  if (missing(title)) title <- ''
  if (missing(zsc.col)) zsc.col <- c('red', 'white', 'blue')
  colnames(data) <- tolower(colnames(data))
  data$adj_pval <- -log(data$adj_pval, 10)
  sub <- data[!duplicated(data$term), ]
  
  if (order.by.zscore == T) {
    sub <- sub[order(sub$zscore, decreasing = T), ]
    leg <- theme(legend.position = 'bottom')
    g <-  ggplot(sub, aes(x = factor(id, levels = stats::reorder(id, adj_pval)), y = adj_pval, fill = zscore)) +
      geom_bar(stat = 'identity', color = 'black') +
      scale_fill_gradient2('z-score', low = zsc.col[3], mid = zsc.col[2], high = zsc.col[1], guide = guide_colorbar(title.position = "top", title.hjust = 0.5), 
                           breaks = c(min(sub$zscore), max(sub$zscore)), labels = c('decreasing', 'increasing')) +
      labs(title = title, x = '', y = '-log (adj p-value)') +
      leg
  }else{
    sub <- sub[order(sub$adj_pval, decreasing = T), ]
    leg <- theme(legend.justification = c(1, 1), legend.position = c(0.98, 0.995), legend.background = element_rect(fill = 'transparent'),
                 legend.box = 'vertical', legend.direction = 'horizontal')
    g <-  ggplot(sub, aes( x = factor(id, levels = reorder(id, adj_pval)), y = zscore, fill = adj_pval)) +
      geom_bar(stat = 'identity', color = 'black') +
      scale_fill_gradient2('Significance', guide = guide_colorbar(title.position = "top", title.hjust = 0.5), breaks = c(min(sub$adj_pval), max(sub$adj_pval)), labels = c('low', 'high')) +
      labs(title = title, x = '', y = 'z-score') +
      leg
  }
  if (display == 'single'){
    g + theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1), axis.line = element_line(color = 'grey80'), axis.ticks = element_line(color = 'grey80'),
              panel.background = element_blank(), panel.border = element_blank(), panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(), plot.background = element_blank())        
  }else{
    g + theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1), axis.line = element_line(color = 'grey80'), axis.ticks = element_line(color = 'grey80'),
              panel.background = element_blank(), panel.border = element_blank(), panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(), plot.background = element_blank())+
      facet_grid(.~category, space = 'free_x', scales = 'free_x')
  }
}

#' 
#' @name GOCircle
#' @title Circular visualization of the results of a functional analysis.
#' @description The circular plot combines gene expression and gene- annotation 
#'   enrichment data. A subset of terms is displayed like the \code{GOBar} plot 
#'   in combination with a scatterplot of the gene expression data. The whole 
#'   plot is drawn on a specific coordinate system to achieve the circular 
#'   layout.The segments are labeled with the term ID.
#' @param data A special data frame which should be the result of 
#'   \code{circle_dat}
#' @param title The title of the plot
#' @param nsub A numeric or character vector. If it's numeric then the number 
#'   defines how many processes are displayed (starting from the first row of 
#'   \code{data}). If it's a character string of processes then these processes 
#'   are displayed
#' @param rad1 The radius of the inner circle (default=2)
#' @param rad2 The radius of the outer circle (default=3)
#' @param table.legend Shall a table be displayd or not? (default=TRUE)
#' @param zsc.col Character vector to define the color scale for the z-score of 
#'   the form c(high, midpoint,low)
#' @param lfc.col A character vector specifying the color for up- and 
#'   down-regulated genes
#' @param label.size Size of the segment labels (default=5)
#' @param label.fontface Font style of the segment labels (default='bold')
#' @details The outer circle shows a scatter plot for each term of the logFC of 
#'   the assigned genes. The colors can be changed with the argument 
#'   \code{lfc.col}.
#'   
#'   The \code{nsub} argument needs a bit more explanation to be used wisely. First of 
#'   all, it can be a numeric or a character vector. If it is a character vector
#'   then it contains the IDs or term descriptions of the displayed processes.If
#'   \code{nsub} is a numeric vector then the number defines how many terms are 
#'   displayed. It starts with the first row of the input data frame.
#' @import ggplot2
#' @import gridExtra
#' @import stats
#' @import graphics
#' @seealso \code{\link{circle_dat}}, \code{\link{GOBar}}
#' @examples
#' \dontrun{
#' #Load the included dataset
#' data(EC)
#' 
#' #Building the circ object
#' circ<-circular_dat(EC$david, EC$genelist)
#' 
#' #Creating the circular plot
#' GOCircle(circ)
#' 
#' #Creating the circular plot with a different color scale
#' GOCircle(circ,zsc.col=c('yellow','black','cyan'))
#' 
#' #Creating the circular plot with different font style
#' GOCircle(circ,label.size=5,label.fontface='italic')
#' }
#' @export

GOCircle <- function(data, title, nsub, rad1, rad2, table.legend = T, zsc.col, lfc.col, label.size, label.fontface){
  xmax <- y1<- zscore <- y2 <- ID <- logx <- logy2 <- logy <- logFC <- NULL
  if (missing(title)) title <- ''
  if (missing(nsub)) if (dim(data)[1] > 10) nsub <- 10 else nsub <- dim(data)[1]
  if (missing(rad1)) rad1 <- 2
  if (missing(rad2)) rad2 <- 3
  if (missing(zsc.col)) zsc.col <- c('red', 'white', 'blue')
  if (missing(lfc.col)) lfc.col <- c('cornflowerblue', 'firebrick1') else lfc.col <- rev(lfc.col)
  if (missing(label.size)) label.size = 5
  if (missing(label.fontface)) label.fontface = 'bold'
  
  data$adj_pval <- -log(data$adj_pval, 10)
  suby <- data[!duplicated(data$term), ]
  if (is.numeric(nsub) == T){		
    suby <- suby[1:nsub, ]
  }else{
    if (strsplit(nsub[1], ':')[[1]][1] == 'GO'){
      suby <- suby[suby$ID%in%nsub, ]
    }else{
      suby <- suby[suby$term%in%nsub, ]
    }
    nsub <- length(nsub)}
  N <- dim(suby)[1]
  r_pval <- round(range(suby$adj_pval), 0) + c(-2, 2)
  ymax <- c()
  for (i in 1:length(suby$adj_pval)){
    val <- (suby$adj_pval[i] - r_pval[1]) / (r_pval[2] - r_pval[1])
    ymax <- c(ymax, val)}
  df <- data.frame(x = seq(0, 10 - (10 / N), length = N), xmax = rep(10 / N - 0.2, N), y1 = rep(rad1, N), y2 = rep(rad2, N), ymax = ymax, zscore = suby$zscore, ID = suby$ID)
  scount <- data[!duplicated(data$term), which(colnames(data) == 'count')][1:nsub]
  idx_term <- which(!duplicated(data$term) == T)
  xm <- c(); logs <- c()
  for (sc in 1:length(scount)){
    idx <- c(idx_term[sc], idx_term[sc + 1] - 1)
    val <- stats::runif(scount[sc], df$x[sc] + 0.06, (df$x[sc] + df$xmax[sc] - 0.06))
    xm <- c(xm, val)
    r_logFC <- round(range(data$logFC[idx[1]:idx[2]]), 0) + c(-1, 1)
    for (lfc in idx[1]:idx[2]){
      val <- (data$logFC[lfc] - r_logFC[1]) / (r_logFC[2] - r_logFC[1])
      logs <- c(logs, val)}
  }
  cols <- c()
  for (ys in 1:length(logs)) cols <- c(cols, ifelse(data$logFC[ys] > 0, 'upregulated', 'downregulated'))
  dfp <- data.frame(logx = xm, logy = logs, logFC = factor(cols), logy2 = rep(rad2, length(logs)))
  c <-	ggplot()+
    geom_rect(data = df, aes(xmin = x, xmax = x + xmax, ymin = y1, ymax = y1 + ymax, fill = zscore), colour = 'black') +
    geom_rect(data = df, aes(xmin = x, xmax = x + xmax, ymin = y2, ymax = y2 + 1), fill = 'gray70') +
    geom_rect(data = df, aes(xmin = x, xmax = x + xmax, ymin = y2 + 0.5, ymax = y2 + 0.5), colour = 'white') +
    geom_rect(data = df, aes(xmin = x, xmax = x + xmax, ymin = y2 + 0.25, ymax = y2 + 0.25), colour = 'white') +
    geom_rect(data = df, aes(xmin = x, xmax = x + xmax, ymin = y2 + 0.75, ymax = y2 + 0.75), colour = 'white') +
    geom_text(data = df, aes(x = x + (xmax / 2), y = y2 + 1.3, label = ID, angle = 360 - (x = x + (xmax / 2)) / (10 / 360)), size = label.size, fontface = label.fontface) +
    coord_polar() +
    labs(title = title) +
    ylim(1, rad2 + 1.6) +
    xlim(0, 10) +
    theme_blank +
    scale_fill_gradient2('z-score', low = zsc.col[3], mid = zsc.col[2], high = zsc.col[1], guide = guide_colorbar(title.position = "top", title.hjust = 0.5), breaks = c(min(df$zscore), max(df$zscore)),labels = c('decreasing', 'increasing')) +
    theme(legend.position = 'bottom', legend.background = element_rect(fill = 'transparent'), legend.box = 'horizontal', legend.direction = 'horizontal') +	
    geom_point(data = dfp, aes(x = logx, y = logy2 + logy), pch = 21, fill = 'transparent', color = 'black', size = 3)+
    geom_point(data = dfp, aes(x = logx, y = logy2 + logy, color = logFC), size = 2.5)+
    scale_colour_manual(values = lfc.col, guide = guide_legend(title.position = "top", title.hjust = 0.5))		
  
  if (table.legend){
    table <- draw_table(suby, col = 'black')
    graphics::par(mar = c(0.1, 0.1, 0.1, 0.1))
    grid.arrange(c, table, ncol = 2)
  }else{
    c + theme(plot.background = element_rect(fill = 'aliceblue'), panel.background = element_rect(fill = 'white'))
  }
}	
