best <- function(state, outcome) {
  data <- read.csv("D:/Work/outcome-of-care-measures.csv", header=TRUE)
  if (outcome == 'heart attack') {
    col = 11
  }
  else if (outcome == 'heart failure') {
    col = 17
  }
  else if (outcome == 'pneumonia') {
    col = 23
  }
  else {
    stop("invalid outcome")
  }
  states <- unique(data[,7])
  test <- match(state, states)
  if (is.na(test)) {
    stop("invalid state")
  }
  stored <- subset(data, data$State == state)
  row <- which.min(stored[,col])
  print(as.character(stored[row,2]))
} 

