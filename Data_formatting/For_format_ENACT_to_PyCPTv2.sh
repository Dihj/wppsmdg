#!/bin/bash

# This is a script to make a format of data netcdf file for Pycptv2 netcdf file
# Using CDO and R script
mo1='06'
mo2='07'
mo3='08'
seas='JJA'

cdo selmon,$mo1,$mo2,$mo3 RR_ENACTS_MON_Jan1981-May2022.nc tmp.nc
cdo yearsum tmp.nc $seas.nc

# Add time T, Ti and Tf 
# Add reftime to day units
cdo -setreftime,'1981-'$mo1'-17,00:00:00,1day' -setcalendar,proleptic_gregorian $seas.nc out1.nc
# Remap attributs
#'''
# Dont need this if we use cdo to extract data for seasonal quarter
#ncatted -O -a units,Lon,o,c,'degree_east' tmp.nc
#ncatted -O -a units,Lat,o,c,'degree_north' tmp.nc
#ncrename -d Lon,X -v Lon,X tmp.nc
#ncrename -d Lat,Y -v Lat,Y tmp.nc
#'''
# To run code line
cat << EOF > format.R
#!/usr/bin/Rscript
# By: Fehizoro, DGM 
# date: March 22, 2023

library(ncdf4)
library(ncdf4.helpers)
library(nat)

###########################
#### Edit this part #######

di_init <- "1981/06/01"
di_fin <- "2021/06/01"
d_init <- "1981/07/17"
d_fin <- "2021/07/17"
df_init <- "1981/08/31"
df_fin <- "2021/08/31"

##########################

nc1 <- nc_open("out1.nc")
nc2 <- nc_open("ENACTS-MADAGASCAR.PRCP-orig.nc")
# Initial month, Ti
d1 <- seq.Date(as.Date(di_init), as.Date(di_fin), by = "years") # init by first day of the month
Ti_res <-  d1 - as.Date(di_init)

# Month in reftime, T
dd <- seq.Date(as.Date(d_init), as.Date(d_fin), by = "years") # in the middle day of the month
t_res <- (dd - as.Date(d_init))*24 # conversion en heure (afaka tadiavana methode hafa

# Final month, Tf
d2 <- seq.Date(as.Date(df_init), as.Date(df_fin), by = "years") # by end of month day
tf_res <- d2 - as.Date(df_init) 

rfe <- ncvar_get(nc1, "rfe")

la2 <- ncvar_get(nc2, "Y")
lo2 <- ncvar_get(nc2, "X")

#rfe_res <- apply(rfe, 2, rev) # raha tsy misy library nat, ka mety
rfe_res <- flip(rfe, 2) #mamadika ny tableau ho decroissant ny latitude

nc.lat<-ncdim_def("Y","",la2, longname="")
nc.lon<-ncdim_def("X","",lo2,  longname="")
nc.te<-ncdim_def("T",paste("hours since ", d_init, "00:00:00", sep=" "), as.numeric(t_res), longname="")

# nc.rfe<-ncvar_def(name= "rfe",units = "mm",dim= list(nc.lon,nc.lat, nc.te), missval= -999, prec = "double")
nc.rfe<-ncvar_def(name= "rfe",units = "mm",dim= list(nc.lon,nc.lat, nc.te), prec = "double")
#nc.rfe<-ncvar_def(name= "tmean",units = "Celsius_scale",dim= list(nc.lon,nc.lat, nc.te), prec = "double")
nc.Ti<-ncvar_def("Ti",paste("days since", di_init, "00:00:00", sep=" "),list( nc.te),prec= "integer")  
nc.Tf<-ncvar_def("Tf",paste("days since", df_init, "00:00:00", sep=" "),list(nc.te), prec = "integer")

nc_res<-nc_create("rfe_map.nc",nc.Ti)
#nc_res<-nc_create("tmoy_map.nc",nc.Ti)
ncvar_put(nc_res,"Ti",Ti_res)

nc_res <- ncvar_add(nc_res, nc.Tf)
nc_res <- ncvar_add(nc_res, nc.rfe)

ncvar_put(nc_res,"Tf",tf_res)
ncvar_put(nc_res,"rfe",rfe_res)
nc.copy.atts(nc2, 'rfe', nc_res, 'rfe')

#nc.copy.atts(nc2, 'rfe', nc_res, 'tmean')
nc.copy.atts(nc2, 'Ti', nc_res, 'Ti', exception.list = 'units')
nc.copy.atts(nc2, 'Tf', nc_res, 'Tf', exception.list = 'units')
nc.copy.atts(nc2, 'X', nc_res, 'X')
nc.copy.atts(nc2, 'Y', nc_res, 'Y')
nc.copy.atts(nc2, 'T', nc_res, 'T',exception.list = 'units')
nc_close(nc_res)

EOF
./format.R
# We have rfe_map.nc file with T, Ti and Tf reference time.
rm format.R
#'''
#ncatted -O -a _FillValue,rfe,o,d,NaN rfe_map.nc
#ncatted -O -a _FillValue,Y,o,d,NaN rfe_map.nc
#ncatted -O -a _FillValue,X,o,d,NaN rfe_map.nc
#ncatted -O -a _FillValue,X,o,f,NaN rfe_map.nc
#ncatted -O -a calendar,T,o,c,proleptic_gregorian rfe_map.nc
#ncatted -O -a calendar,Ti,o,c,proleptic_gregorian rfe_map.nc
#ncatted -O -a calendar,Tf,o,c,proleptic_gregorian rfe_map.nc
#ncatted -O -a nrow,rfe,o,c,387 rfe_map.nc
#ncatted -O -a ncol,rfe,o,c,267 rfe_map.nc
#ncatted -O -a missing,rfe,o,c,-999 rfe_map.nc
#ncatted -O -a row,rfe,o,c,Y rfe_map.nc
#ncatted -O -a col,rfe,o,c,X rfe_map.nc
#ncatted -O -a coordinates,rfe,o,c,Tf Ti rfe_map.nc
#ncatted -O -a field,rfe,o,c,rfe rfe_map.nc
#'''
ncdump -h rfe_map.nc
cp rfe_map.nc ENACTS-MADAGASCAR.PRCP_$seas.nc
rm rfe_map.nc out1.nc
