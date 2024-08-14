#!/usr/bin/Rscript
# Fichier exécutable
# ONLY FOR SEAFORDS version 2407 (last version for July 2024)
rm(list = ls())
#########################################################################################
###########                             EDIT ONLY HERE                              #####
###########  Requirement:                                                           #####
###########     1- You have downloaded all data required for the forecast leadtime  #####
###########     2- Config-optim for your zone is available and optimized            #####
###########     3- Climate analysis from TOOLS already done, etc ...                #####
###########     4- On Sesonal_outlook.R, rmlist and config_model put as comment     #####
#########################################################################################
# Namelist configuration
experience_name <- "LRF_by_Zone_"  # Your experiment name, avoid space and extra character
parametres_a_traiter = c("PREC","U850","V850","SST","PMER","U200")
annee = "2024" # from 2022 to 2024
current_month <- "06" # Necessary 2 digits, this is the month fro the run model
hindcast1 = "HINDCAST" # ERA5 or HINDCAST
score = "HINDCAST"  # HINDCAST or ERA5 or ...
param_loc = "PRECTOT" # PRECTOT, RR, 
by.zone = "yes" # "yes" (colored polygons) or "no" (colored points at station locations) 
country = "MAD"  
postes.a.eliminer <- c("")
domaine_choisi = c(-50,10,20,110)
cca.optim = "yes"
nb_modes_auto = "yes"
seuil_CorCan = 0.5
nbvc_mini=2
tercile_final_utilise = "obs"
minYear = 2001
maxYear = 2015
minQ = 0.10
maxQ = 0.90
seuil_correlation_zone = 0.00
language <- "english"				
bp.plot <- TRUE
bp.width  <- 0.08 
bp.height <- 0.12	
bp.text <- 0.9
h.density = "no" 
fact.density = 1.5
sym.fact <- 2.0
verb=1
#############                                                                          #####
############################################################################################

# Mapping des mois aux saisons et leadtimes
saison_leadtime_mapping <- list(
  "01" = list("FMA" = 1, "MAM" = 2, "AMJ" = 3),
  "02" = list("MAM" = 1, "AMJ" = 2, "MJJ" = 3),
  "03" = list("AMJ" = 1, "MJJ" = 2, "JJA" = 3),
  "04" = list("MJJ" = 1, "JJA" = 2, "JAS" = 3),
  "05" = list("JJA" = 1, "JAS" = 2, "ASO" = 3),
  "06" = list("JAS" = 1, "ASO" = 2, "SON" = 3),
  "07" = list("ASO" = 1, "SON" = 2, "OND" = 3),
  "08" = list("SON" = 1, "OND" = 2, "NDJ" = 3),
  "09" = list("OND" = 1, "NDJ" = 2, "DJF" = 3),
  "10" = list("NDJ" = 1, "DJF" = 2, "JFM" = 3),
  "11" = list("DJF" = 1, "JFM" = 2, "FMA" = 3),
  "12" = list("JFM" = 1, "FMA" = 2, "MAM" = 3)
)

# Need this if you use crontab task
#current_month <- format(Sys.Date(), "%m")

# Get saison and corresponding leadtime
saison_leadtimes <- saison_leadtime_mapping[[current_month]]

# Loop from models, only those here available, 
for (modelo in c("CEP51", "NCEP", "MF8")) {
  for (saison in names(saison_leadtimes)) {
 #   source("../fic_env.R")
#    setwd(user.path.bin)
    hindcast <- hindcast1
    leadtime <- saison_leadtimes[[saison]]
    modele_prevision <- modelo
    saison_list <- saison
    exp_name <- paste0(experience_name, modele_prevision, "_lt", leadtime)
    
    print(paste("...... Forecast for", saison, "with", modele_prevision, "..lt...", leadtime))
    
    # Exécution du script Seasonal_Outlook.R avec les paramètres modifiés
    source("Seasonal_Outlook.R")
#    source("../fic_env.R")
#    setwd(user.path.bin)
  }
}

##################################################################
## For MIXGCM
exp_name = paste0(experience_name, "MixGCM")

# GCM Forecast references
#------------------------
model_list = c("CEP51","MF8","NCEP")  
#param_list = c("U850","V850","PMER","U200","PREC","SST","T2M")
param_list = c()
domain_GCM = domaine_choisi
#sais = "OND"
year = annee

for (saison in names(saison_leadtimes)) {
  leadtime <- saison_leadtimes[[saison]]
  sais <- saison
  hindcast <- hindcast1
  #modele_prevision <- modelo
  # I have made some change on the file names output to avoid overwriting during process.
  if (hindcast == "ERA5") {
    filefcst1=paste("Synthesis_",country,"_",model_list,"_",param_loc,"_",sais,year,"_MODEL_ERA5.txt",sep="")
    filefcst2=paste("Synthesis-values_",country,"_",model_list,"_",param_loc,"_",sais,year,"_lt",leadtime,"_",hindcast,".txt",sep="")
    repfcst=paste("./OUTPUT/",experience_name,model_list,"_lt",leadtime,"/",country,"/",sais,"/",param_loc,sep="")
    print(paste("...... Mix Forecast for", sais, "with", "..lt...", leadtime))
    source("MixGCM.R")
  } else {
    filefcst1=paste("Synthesis_",country,"_",model_list,"_",param_loc,"_",sais,year,"_MODEL_",hindcast,"_",model_list,"_lt",leadtime,".txt",sep="")
    filefcst2=paste("Synthesis-values_",country,"_",model_list,"_",param_loc,"_",sais,year,"_lt",leadtime,"_",hindcast,"_",model_list,"_lt",leadtime,".txt",sep="")
    repfcst=paste("./OUTPUT/",experience_name,model_list,"_lt",leadtime,"/",country,"/",sais,"/",param_loc,sep="")
    print(paste("...... Mix Forecast for", sais, "with", "..lt...", leadtime))
    source("MixGCM.R")
    
  }
}
