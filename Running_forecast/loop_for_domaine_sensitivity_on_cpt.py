#!/usr/bin/env ipython
# coding: utf-8
import os
import sys
import xarray as xr
import numpy as np
import pandas as pd
import subprocess
from pycpt_functions_seasonal import *
from pycpt_dictionary import dic_sea, dic_sea_elr
from scipy.stats import t
import cartopy.crs as ccrs
from cartopy.feature import NaturalEarthFeature, LAND, COASTLINE
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
from cartopy.mpl.gridliner import LONGITUDE_FORMATTER, LATITUDE_FORMATTER
import calendar
print("Python libraries loaded")
print("Now in the work folder:")
from IPython import get_ipython
print("Creating working folders, if not already there...")
print("Work directory is:")

cptdir='/data/cft/Optimum/iri-pycpt_oct2021/CPT/16.5.8/bin/'

# Set up CPT environment
os.environ["CPT_BIN_DIR"] = cptdir
print("CPT environment loaded...")
#workdir = '/mnt/c/Users/Patri/OneDrive/Columbia_Academics/S2S4/iri-pycpt/'
workdir = '/data/cft/Optimum/Loop/OND/'
savedir = workdir  # location in which the current .ipynb is located, for saving Jupyter notebooks
# PATH to CPT root directory
#cptdir='/mnt/c/Users/Patri/Downloads/CPT/16.5.8/'
work = 'ONDicSep_GI_for_ENACTS'
print("PyCPT folder is:")
get_ipython().run_line_magic('cd', '$workdir')
get_ipython().system('mkdir -p $work')
#%cd $workdir
get_ipython().run_line_magic('cd', '$work')
get_ipython().system('mkdir -p input')
get_ipython().system('mkdir -p input/noMOS')
get_ipython().system('mkdir -p output')
get_ipython().system('mkdir -p scripts')
get_ipython().system('rm -Rf scripts/*')
get_ipython().system('mkdir -p output/figures')

models=['EU-C3S-ECMWF-SEAS5','GFDL-SPEAR','COLA-RSMAS-CCSM4','NCEP-CFSv2','NASA-GEOSS2S']

########Obs (choose between CPC-CMAP-URD, CHIRPS, TRMM, CPC, Chilestations)
obs='ENACTS-MG'
station=False
########MOS method (choose between None, PCR, CCA)
MOS='CCA'
########Predictand (choose between PRCP, RFREQ)
PREDICTAND='PRCP'
########Predictor (choose between GCM's PRCP, VQ, UQ)
#VQ and UQ only works with models=['NCEP-CFSv2']
PREDICTOR='PRCP'
pressure='850'  # UQ VQ: for desired horizontal moisture fluxes in the U (Zonal) and V (Meridional) directions at a geopotential height of P (user-definable: 700, 850, 925, etc.). 
#(Tip: change your work foldername after changing the pressure)
#PREDICTOR='T2M'
########Target seasons and related parameters
##If more targets, increase the arrays accordingly
mons =['Sep']
#mons=['Dec']
tgtii=['1.5']  #S: start for the DL
tgtff=['3.5']   #S: end for the DL
#tgtii=['1.5','2.5']  #S: start for the DL
#tgtff=['1.5','2.5']   #S: end for the DL
#tgtii=['1.5','2.5']  #S: start for the DL
#tgtii='1.5'  #S: start for the DL
#tgtff='3.5'   #S: end for the DL
#for now, just write the target period (for DL)
tgts =['Oct-Dec'] #'Aug-Oct','Mar-May','Apr-Jun','May-Jul']   #Needs to be any of the seasons computed.
monss = tgts 
#Start and end of the training period: (must be >1982 for NMME models. Because of CanSIPSv2, probably end in 2018)
tini=1991
tend=2020
## mila atao min optim aloha
xmodes_min = 1
xmodes_max = 12
ymodes_min = 1
ymodes_max = 10
ccamodes_min = 1
ccamodes_max = 10
########Forecast date  
monf='Sep'	# Initialization month 
fyr=2021	# Forecast year
########Switches:
force_download = False   #force download of data files, even if they already exist locally
single_models = True     #Switch Single_model plots on or off
#cca_timeseries = False   #Switch to plot cca time series or not (this function is currently still in development)
forecast_anomaly=False
forecast_spi = False
confidence_level=95
#################################################"
# Want to add a topo background to the domain plots?
use_topo=True
map_color='WindowsCPT' #set to "WindowsCPT" for CPT colorscheme
colorbar_option=True
use_ocean=False
workdir = os.getcwd()
(rainfall_frequency,threshold_pctle,wetday_threshold,obs_source,hdate_last,mpref,L,ntrain,fprefix, x_offset, y_offset)=setup_params(PREDICTOR,PREDICTAND,obs,MOS,tini,tend)
#########################################################"
# elo2=110 	# Easternmost longitude
# Eto no mila variation min max ho an'ny lat sy ny lon
# Spatial domain for predictand, fixena aloha ny predictand, domaine ny MDG v3 1deg ity a
nla2=-10 	# Northernmost latitude
sla2=-26.5 	# Southernmost latitude
wlo2=41 	# Westernmost longitude
elo2=52	# Easternmost longitude

#######################################################
### Domaine max ny predictor, afaka atao zone ngoda 
nlatmax=20
slatmax=-50
wlonmax=0
elonmax=90
for model in models:
    for mo in range(len(mons)):
        mon=mons[mo]
        tar=tgts[mo]
        tgti=tgtii[mo]
        tgtf=tgtff[mo]
        get_ipython().run_line_magic('cd', '$workdir/input')
        PrepFiles(fprefix, PREDICTAND, threshold_pctle, tini, tend, wlonmax, wlo2,elonmax, elo2, slatmax, sla2, nlatmax, nla2, tgti, tgtf, mon, monf, fyr, os, wetday_threshold, tar, model, obs, obs_source, hdate_last, force_download, station, dic_sea, dic_sea_elr, pressure, MOS)
# ########Spatial domain for predictor, ny redicteur no atao mobil
for latmin in range(-10,5,2):
        for latmax in range(-38,-27,2):
                for lonmin in range(10,41,2):
                        for lonmax in range(53,71,2):
                                nla1=latmin # Northernmost latitude
                                sla1=latmax # Southernmost latitude
                                wlo1=lonmin # Westernmost longitude
                                elo1=lonmax # Easternmost longitude
                                
                                for model in models:
                                    print('')
                                    print('')
                                    print('\033[1m----Starting process for '+model+'----\033[0;0m')
                                    for mo in range(len(mons)):
                                        mon=mons[mo]
                                        tar=tgts[mo]
                                        tgti=tgtii[mo]
                                        tgtf=tgtff[mo]
                                        print("New folder:")
                                        get_ipython().run_line_magic('cd', '$workdir/input')
                                        print('Preparing CPT files for \033[1m'+model+'\033[0;0m. Target: \033[1m'+tar+'\033[0;0m - Initialization \033[1m'+mon+'\033[0;0m...')
                                        PrepFiles(fprefix, PREDICTAND, threshold_pctle, tini, tend, wlo1, wlo2,elo1, elo2, sla1, sla2, nla1, nla2, tgti, tgtf, mon, monf, fyr, os, wetday_threshold, tar, model, obs, obs_source, hdate_last, force_download, station, dic_sea, dic_sea_elr, pressure, MOS)
                                        print("New folder:")
                                        get_ipython().run_line_magic('cd', '$workdir/scripts')
                                        CPTscriptMDG(model,PREDICTAND, mon,monf, fyr, tini,tend,nla1,sla1,wlo1,elo1,nla2,sla2,wlo2,elo2,fprefix,mpref,tar,ntrain,MOS,station, xmodes_min, xmodes_max, ymodes_min, ymodes_max, ccamodes_min, ccamodes_max, forecast_anomaly, forecast_spi)
                                        print('Executing CPT for \033[1m'+model+'\033[0;0m. Target: \033[1m'+tar+'\033[0;0m - Initialization \033[1m'+mon+'\033[0;0m...')
                                        try:
                                            subprocess.check_output(cptdir+'CPT.x < params > CPT_log_'+model+'_'+tar+'_'+mon+'.txt',stderr=subprocess.STDOUT, shell=True)
                                        except subprocess.CalledProcessError as e:
                                            print(e.output.decode())
                                            raise
                                        print('------------------------------------')
                                        print('Calculations for Target: \033[1m'+tar+'\033[0;0m - Initialization \033[1m'+mon+'\033[0;0m completed!')
                                        print('See output folder, and check scripts/CPT_log_'+model+'_'+tar+'_'+mon+'.txt for log')
                                        print('\033[1mQuick error report from CPT (if any):\033[0;0m')
                                        with open('CPT_log_'+model+'_'+tar+'_'+mon+'.txt', "r") as fp:
                                            for line in lines_that_contain("Error:", fp):
                                                print (line)
                                        print('----------------------------------------------')
                                        print('----------------------------------------------')
                                        get_ipython().run_line_magic('cd', '$workdir/output')
###############################################################################

