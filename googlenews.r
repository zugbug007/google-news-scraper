news <- function(term) {
  require(dplyr)
  require(xml2)
  require(rvest)
  require(urltools)
  
  html_dat <- read_html(paste0("https://news.google.com/search?q=",term,"&hl=en-GB&gl=GB&ceid=GB%3Aen"))
  filename <- paste(term, Sys.Date(),".xlsx",sep="")

  dat <- data.frame(Link = html_dat %>%
                      html_nodes('.VDXfz') %>% 
                      html_attr('href')) %>% 
    mutate(Link = gsub("./articles/","https://news.google.com/articles/",Link))
  
  news_dat <- data.frame(
    Title = html_dat %>%
      html_nodes('.DY5T1d') %>% 
      html_text(),
    Link = dat$Link,
    Description =  html_dat %>%
      html_nodes('.Rai5ob') %>% 
      html_text()
  ) 
  
  # Extract Source and Time (To avoid missing content)
  prod <- html_nodes(html_dat, ".SVJrMe")
  Source <- lapply(prod, function(x) {
    norm <- tryCatch(html_node(x, "a") %>% html_text() ,
                     error=function(err) {NA})
  })
  
  time <- lapply(prod, function(x) {
    norm <- tryCatch(html_node(x, "time") %>% html_text(),
                     error=function(err) {NA})
  })
  
  mydf <- data.frame(Source = do.call(rbind, Source), Time = do.call(rbind, time), stringsAsFactors = F)
  dff <- cbind(news_dat, mydf) %>% distinct(Time, .keep_all = TRUE)
  search_term <- term
  return(dff)
}

search_term <- URLdecode('national%20trust')
newsdf <- news(URLencode(search_term))

# Create Workbook
library(openxlsx)
#require(ggplot2)

filename <- paste(search_term, Sys.Date(),".xlsx",sep="")

wb <- createWorkbook()
options("openxlsx.borderColour" = "#4F80BD")
options("openxlsx.borderStyle" = "thin")
modifyBaseFont(wb, fontSize = 10, fontName = "Calibri")

addWorksheet(wb, sheetName = "newsdf", gridLines = FALSE)
freezePane(wb, sheet = 1, firstRow = TRUE, firstCol = TRUE) ## freeze first row and column
writeDataTable(wb, sheet = 1, x = newsdf, colNames = TRUE, rowNames = TRUE, tableStyle = "TableStyleLight9")

saveWorkbook(wb, filename, overwrite = TRUE) ## save to working directory

