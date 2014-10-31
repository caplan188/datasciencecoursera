library(XLConnect)
library(RJDBC)
drv <- JDBC("com.microsoft.sqlserver.jdbc.SQLServerDriver","C:/Users/user/Downloads/sqljdbc4.jar") 
con <- dbConnect(drv, "jdbc:sqlserver://174.34.53.123:1433", "mcaplan", "notnineguy")

###Loads Excel File###
AllWinsRaw <<- file.path("D:/Work/Spikes/EF Removal/Spikes 10.23.14.csv")
print(AllWinsRaw)
AllWins <- read.csv(AllWinsRaw, header = T)

EF <- subset(AllWins)


  EF$SQL<-paste0("and a.CHURN_WINNING_SP = '",EF$CHURN_WINNING_SP,"' and a.CHURN_LOSING_SP = '",EF$CHURN_LOSING_SP,"' and a.CHURN_DATE >= '",EF$Churn_Date," 00:00:00' and a.CHURN_DATE <= '", EF$Churn_Date," 23:59:59' and BTA_NAME = '",EF$BTA_Name,"'")
print(EF$SQL)



n <- as.integer(nrow(EF))
i <- 1
churn <- list()
while (i <= n) {
  churn[[i]] <- dbGetQuery(con, paste0("select a.TN, CHURN_DATE, win.COMMON_NAME as Winner, a.CHURN_WINNING_SP as winning_sp, lose.COMMON_NAME as Loser, a.CHURN_Losing_sp as losing_sp, a.TN_Movement_Type, b.BTA from COM_CDM..F_FINAL_CHURN as a join com_cdm..F_ZIP as b on a.ZIP_RC_KBLOCK = b.ZIP join com_cdm..D_COMMON_OCN as win on a.CHURN_WINNING_SP = win.OCN_COMMON_DIM_ID join com_cdm..D_COMMON_OCN as lose on a.CHURN_LOSING_SP = lose.OCN_COMMON_DIM_ID where CHURN_TYPE = 'EF DSV' ",EF$SQL[i]," order by CHURN_DATE"))
  if(nrow(churn[[i]]) != 0) {churn[[i]]$SpikeID <- EF$SpikeID[i]}
  i <- i+1
}

file.exists("D:/Work/Spikes/EF Removal/Spikes_10.23.xslx")


result <- list()
q <- as.integer(length(churn))
w <- 1
while (w <= q) {
  if(nrow(churn[[w]]) != 0) {
    resultdf <- do.call("rbind", churn[w])
    resultdf$CHURN_DATE<-as.POSIXlt(resultdf$CHURN_DATE, format="%Y-%m-%d %H:%M:%S")
    resultdf$CHURN_DATE_ROUNDED<-as.POSIXlt(round(as.double(resultdf$CHURN_DATE)/(900))*(900),origin=(as.POSIXlt('1970-01-01')))
    
    rounded<-data.frame(table(as.factor(as.character(resultdf$CHURN_DATE_ROUNDED))))
    
    resultdf$CHURN_DATE_ROUNDED <- as.character(resultdf$CHURN_DATE_ROUNDED)
    rounded$Var1 <- as.character(rounded$Var1)
    
    frequency <- merge(x=resultdf,y=rounded, by.x = "CHURN_DATE_ROUNDED", by.y = "Var1")
    
    n <- as.integer(nrow(frequency))
    i <- 1
    while (i <= n) {
      if(frequency$Freq[i] > 5) {
        frequency$Status[i] <- "3"
        i<-i+1
      } else {frequency$Status[i] <- "0"
              i<-i+1}
    }
    
    result[[w]] <- frequency
    w<-w+1
  } else {w <- w+1}
}

final <- do.call("rbind", result)

write.csv(final, "D:/Work/Spikes/EF Removal/TNsForRemoval.csv", row.names = FALSE)