#!/usr/bin/Rscript
###########"###########################################################
########### Script hanaovana evaluation ny CFT ########################"
###########DhjJuin2021##########################################
########################################################################"
##### ONLY EDIT HERE
rm(list = ls())
start_time <- Sys.time()
season <- "SON"  # eg "SON" for 3 month, monthly eg "JAN"
year <- 2023  ### année atao évaluation
param <- "TMEAN"   # Choose between "TMEAN" for temperature and "RR" for rainfall
country <- "BTK"  # Choose your country or region
rr <- read.csv("Data_TMEAN_BTK_4km_CFT_Format_ENACTSv4.csv", na.strings = "-99.9") # File data in CFT format
resultat <- paste(country,"_",param,"_",season, ".txt",sep = "")  # Name of the output result in SEAFORDS format "Country-param-season"

########################################################################

if (file.exists("tt2.csv")) {file.remove("tt2.csv")}
if (file.exists("tt.csv")) {file.remove("tt.csv")}
coord <- rr[,1:4]
coord2 <- rr[,1:3]
if (season=="JAN"){mm <- rr[,5]; cb <- cbind(coord, mm)}
if (season=="FEB"){mm <- rr[,6]; cb <- cbind(coord, mm)}
if (season=="MAR"){mm <- rr[,7]; cb <- cbind(coord, mm)}
if (season=="APR"){mm <- rr[,8]; cb <- cbind(coord, mm)}
if (season=="MAY"){mm <- rr[,9]; cb <- cbind(coord, mm)}
if (season=="JUN"){mm <- rr[,10]; cb <- cbind(coord, mm)}
if (season=="JUL"){mm <- rr[,11]; cb <- cbind(coord, mm)}
if (season=="AUG"){mm <- rr[,12]; cb <- cbind(coord, mm)}
if (season=="SEP"){mm <- rr[,13]; cb <- cbind(coord, mm)}
if (season=="OCT"){mm <- rr[,14]; cb <- cbind(coord, mm)}
if (season=="NOV"){mm <- rr[,15]; cb <- cbind(coord, mm)}
if (season=="DEC"){mm <- rr[,16]; cb <- cbind(coord, mm)}

if (param=="RR"){
  if (season=="JFM"){rrsea <- rr[,5:7]; mm <- apply(rrsea, 1, sum) ; cb <- cbind(coord, mm)}
  if (season=="FMA"){rrsea <- rr[,6:8]; mm <- apply(rrsea, 1, sum); cb <- cbind(coord, mm)}
  if (season=="MAM"){rrsea <- rr[,7:9]; mm <- apply(rrsea, 1, sum); cb <- cbind(coord, mm)}
  if (season=="AMJ"){rrsea <- rr[,8:10]; mm <- apply(rrsea, 1, sum); cb <- cbind(coord, mm)}
  if (season=="MJJ"){rrsea <- rr[,9:11]; mm <- apply(rrsea, 1, sum); cb <- cbind(coord, mm)}
  if (season=="JJA"){rrsea <- rr[,10:12]; mm <- apply(rrsea, 1, sum); cb <- cbind(coord, mm)}
  if (season=="JAS"){rrsea <- rr[,11:13]; mm <- apply(rrsea, 1, sum); cb <- cbind(coord, mm)}
  if (season=="ASO"){rrsea <- rr[,12:14]; mm <- apply(rrsea, 1, sum); cb <- cbind(coord, mm)}
  if (season=="SON"){rrsea <- rr[,13:15]; mm <- apply(rrsea, 1, sum); cb <- cbind(coord, mm)}
  if (season=="OND"){rrsea <- rr[,14:16]; mm <- apply(rrsea, 1, sum); cb <- cbind(coord, mm)}

  #library(magicfor)
  #magic_for(print, silent = TRUE)
  mmi <- NULL
  mpp <- list()
  mppp <- NULL
  mmo <- list()
  if (season=="NDJ" | season=="DJF" | season=="ONDJFMA"){
    fn <- "tmp.csv"
    if (file.exists(fn)) {file.remove(fn)}
    for (i in unique(rr$ID)){
      
      rrs <- rr[rr$ID==i,]
      for(a in rrs$Year){
        rrk <- rrs[rrs$Year==a,]
        if (a==year){rrj <- rrs[rrs$Year==a,]}
        if (a!=year){rrj <- rrs[rrs$Year==a+1,]}
        if (season=="NDJ"){mmo <- sum(rrk[,15], rrk[,16], rrj[,5])}
        if (season=="DJF"){mmo <- sum(rrk[,16], rrj[,5], rrj[,6])}
        if (season=="ONDJFMA"){mmo <- sum(rrk[,14],rrk[,15],rrk[,16], rrj[,5],rrj[,6], rrj[,7],rrj[,8])}
        mp <- print(paste(i, a, mmo, sep = ","))
        write(mp, "tmp.csv", append = TRUE)
      }
      
    }
    tmp <- read.csv("tmp.csv", header = FALSE)
    cb <- merge(unique(coord2), tmp, by.x = c("ID"), by.y = c("V1"))
    names(cb) <- c("ID", "Lat", "Lon","Year", "mm")
  }
}
if (param=="TMEAN"){
  if (season=="JFM"){rrsea <- rr[,5:7]; mm <- apply(rrsea, 1, mean) ; cb <- cbind(coord, mm)}
  if (season=="FMA"){rrsea <- rr[,6:8]; mm <- apply(rrsea, 1, mean); cb <- cbind(coord, mm)}
  if (season=="MAM"){rrsea <- rr[,7:9]; mm <- apply(rrsea, 1, mean); cb <- cbind(coord, mm)}
  if (season=="AMJ"){rrsea <- rr[,8:10]; mm <- apply(rrsea, 1, mean); cb <- cbind(coord, mm)}
  if (season=="MJJ"){rrsea <- rr[,9:11]; mm <- apply(rrsea, 1, mean); cb <- cbind(coord, mm)}
  if (season=="JJA"){rrsea <- rr[,10:12]; mm <- apply(rrsea, 1, mean); cb <- cbind(coord, mm)}
  if (season=="JAS"){rrsea <- rr[,11:13]; mm <- apply(rrsea, 1, mean); cb <- cbind(coord, mm)}
  if (season=="ASO"){rrsea <- rr[,12:14]; mm <- apply(rrsea, 1, mean); cb <- cbind(coord, mm)}
  if (season=="SON"){rrsea <- rr[,13:15]; mm <- apply(rrsea, 1, mean); cb <- cbind(coord, mm)}
  if (season=="OND"){rrsea <- rr[,14:16]; mm <- apply(rrsea, 1, mean); cb <- cbind(coord, mm)}

  #library(magicfor)
  #magic_for(print, silent = TRUE)
  mmi <- NULL
  mpp <- list()
  mppp <- NULL
  mmo <- list()
  if (season=="NDJ" | season=="DJF" | season=="ONDJFMA"){
    fn <- "tmp.csv"
    if (file.exists(fn)) {file.remove(fn)}
    for (i in unique(rr$ID)){
      
      rrs <- rr[rr$ID==i,]
      for(a in rrs$Year){
        rrk <- rrs[rrs$Year==a,]
        if (a==year){rrj <- rrs[rrs$Year==a,]}
        if (a!=year){rrj <- rrs[rrs$Year==a+1,]}
        if (season=="NDJ"){mmo <- mean(rrk[,15], rrk[,16], rrj[,5])}
        if (season=="DJF"){mmo <- mean(rrk[,16], rrj[,5], rrj[,6])}
        if (season=="ONDJFMA"){mmo <- mean(rrk[,14],rrk[,15],rrk[,16], rrj[,5],rrj[,6], rrj[,7],rrj[,8])}
        mp <- print(paste(i, a, mmo, sep = ","))
        write(mp, "tmp.csv", append = TRUE)
      }
      
    }
    tmp <- read.csv("tmp.csv", header = FALSE)
    cb <- merge(unique(coord2), tmp, by.x = c("ID"), by.y = c("V1"))
    names(cb) <- c("ID", "Lat", "Lon","Year", "mm")
  }
}



## Efa nahazo ny valeur saisonniC(re teto dia mamadikanyformat amin'izay
#rb <- rbind(unique(rrs$ID), unique(rrs$Lat), unique(rrs$Lon))
tt <- c("STN", "LAT", "LON")
mat <- matrix(cb$mm, nrow = length(unique(cb$Year)), byrow = F)
coordcb <- cb[,1:3]
unccb <- unique(coordcb)
#coord3 <- unique(coord2)
tcoord <- t(unccb)
write.csv(tcoord, "tt.csv", row.names = c("STN", "LAT", "LON"))
tro <- read.csv("tt.csv", header = F)
tro2 <- tro[-1,]
cbb <- cbind(unique(cb$Year), mat)
write.csv(cbb, "tt2.csv", row.names = F)
trobe <- read.csv("tt2.csv", header = F)
trobe2 <- trobe[-1,]
dd <- rbind(tro2, trobe2)
write.table(dd, resultat, row.names = F, col.names = F, sep = '\t', na ="-99.9")
if (file.exists("tt2.csv")) {file.remove("tt2.csv")}
if (file.exists("tt.csv")) {file.remove("tt.csv")}
end_time <- Sys.time()
print(end_time - start_time)
print("...........Conversion CFT format to SEAFORD format finished..........")


