#######################################################################"
#### manao format CFT############################################"""""
#### Tsy mila fichier coordinate intsony fa fichier format CFT de ampy ######"
####################################################################
rr <- read.csv('TMEAN_monthly_BTK_grid_04km.csv', header = F)

year<-c(1961:2022)
coor <- rr[1:3,2:dim(rr)[2]]
coort <- t(coor)
stn <- rep(coort[,1], each=length(year))
lon <- rep(coort[,2], each=length(year))
lat <- rep(coort[,3], each=length(year))
yy <- rep(rep(year, each=1), dim(coor)[2])
dat <- data.frame(stn, lat, lon, yy)

rr2 <- rr[4:dim(rr)[1],2:dim(rr)[2]]
st <- stack(rr2)
mat <- matrix(st$values, ncol = 12, byrow = TRUE)
cb <- cbind(dat, mat)
names(cb) <- c("ID", "Lat", "Lon", "Year", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
write.csv(cb, "Data_TMEAN_BTK_4km_CFT_Format_ENACTSv4.csv", row.names = FALSE, na="-99.9")

######################################################################"