#!/usr/bin/env python
#-*- coding: utf-8 -*-
## PyCPT vers 2

import cptdl as dl
import cptio as cio
import cptextras as ce
import cptcore as cc

#print([i for i in list(dl.hindcasts.keys()) if "PRCP" in i ])

import os
import sys
import subprocess
from IPython.testing.globalipapp import get_ipython

import xarray as xr 
import datetime as dt 
from pathlib import Path 
import matplotlib.pyplot as plt 
import cartopy.crs as ccrs
import numpy as np

# Define case directory 
# Need to convert the original path to a magic_ipython comand
caseDir = "pycpt_MadagascarJJA2023_startMayENACTS"
workdir = '/media/andriamihaja/DATA1/FORECAST/PyCPT/Version2/download_data_to_server/'
#case_directory = '/data/cft/PYCPT/PyCPTv2/' + caseDir

# Parameters of our analysis
MOS = 'CCA' # must be one of 'CCA', 'PCR', or "None"
predictor_names = ['CFSv2.PRCP','CanSIPSIC3.PRCP', 'CCSM4.PRCP', 'GEOSS2S.PRCP', 'SPEAR.PRCP']
#predictand_name = 'UCSB.PRCP'
predictand_name = 'ENACTS-MADAGASCAR.PRCP'
ip = get_ipython()
download_args = {
  'fdate': dt.datetime(2023, 5, 1),
  'first_year': 1991,
  'final_year': 2020,
  'predictor_extent': {
    'east': 30,
    'west': 70, 
    'north': -5, 
    'south': -30
  }, 
  'predictand_extent': {
    'east': 42,
    'west': 52, 
    'north': -10, 
    'south': -27
  },
  'lead_low': 1.5,
  'lead_high': 3.5,
  'target': 'Jun-Aug',
  'filetype': 'cptv10.tsv'
}

cpt_args = { 
    'transform_predictand': None,  # transformation to apply to the predictand dataset - None, 'Empirical', 'Gamma'
    'tailoring': None,  # tailoring None, 'Anomaly', 'StdAnomaly', or 'SPI' (SPI only available on Gamma)
    'cca_modes': (3,6), # minimum and maximum of allowed CCA modes 
    'x_eof_modes': (3,9), # minimum and maximum of allowed X Principal Componenets 
    'y_eof_modes': (3,6), # minimum and maximum of allowed Y Principal Components 
    'validation': 'crossvalidation', # the type of validation to use - crossvalidation, retroactive, or doublecrossvalidation
    'drymask': False, #whether or not to use a drymask of -999
    'scree': True, # whether or not to save % explained variance for eof modes
    'crossvalidation_window': 5,  # number of samples to leave out in each cross-validation step 
    'synchronous_predictors': True, # whether or not we are using 'synchronous predictors'
}

force_download = False

# Create directory for output

#extracting domain boundaries and create house keeping
domain = download_args['predictor_extent']
e,w,n,s = domain.values()

domainFolder = 'res' + str(w)+'W-' + str(e)+'E' +"_to_"+ str(s)+'S-' + str(n)+'N'

#domainDir = "/data/cft/PYCPT/PyCPTv2" / caseDir / domainFolder
#domainDir.mkdir(exist_ok=True, parents=True)

dataDir = workdir + caseDir + '/' + domainFolder + '/data'
#dataDir.mkdir(exist_ok=True, parents=True)

figDir = workdir + caseDir + '/' + domainFolder + '/' + 'figures'
#"figDir.mkdir(exist_ok=True, parents=True)

outputDir = workdir + caseDir + '/' + domainFolder + '/' + 'output'
#outputDir.mkdir(exist_ok=True, parents=True)
#Create file with ipython_magic
ip.run_line_magic('cd', '$workdir')
ip.system('mkdir -p $caseDir')
ip.run_line_magic('cd', '$caseDir')

ip.system('mkdir -p $domainFolder')
ip.run_line_magic('cd', '$domainFolder')
ip.system('mkdir -p data')
ip.system('mkdir -p figures')
ip.system('mkdir -p output')


# Create config.file
# Uncomment the following line & change the config filepath to save this configuration: 
config_file = ce.save_configuration(caseDir+'.config', download_args, cpt_args, MOS, predictor_names, predictand_name )

# Download observations
fmon=download_args['fdate'].month
tmon1 = fmon + download_args['lead_low'] # first month of the target season
tmon2 = fmon + download_args['lead_high'] # last month of the target season
download_args_obs = download_args.copy()

if tmon1 <= 12.5 and tmon2 > 12.5:
    download_args_obs['final_year'] +=1    

if tmon1 > 12.5: 
    download_args_obs['first_year'] +=1
    download_args_obs['final_year'] +=1 
    
print(download_args) 
print(download_args_obs)
print('')
print(dataDir)


#########################################
if not Path(dataDir + '/' + '{}.nc'.format(predictand_name)).is_file() or force_download:
        Y = dl.download(dl.observations[predictand_name], dataDir + '/' + (predictand_name +'.tsv'), **download_args_obs, verbose=True, use_dlauth=False)
        Y = getattr(Y, [i for i in Y.data_vars][0])
        Y.to_netcdf(dataDir + '/' + '{}.nc'.format(predictand_name))
else:
        Y = xr.open_dataset(dataDir + '/' + '{}.nc'.format(predictand_name))
        Y = getattr(Y, [i for i in Y.data_vars][0])

print('')
print('-------------------------')
print('Download Observation data')
print('-------------------------')
print('')


########################################
# DOnwload hindcast data
# download training data 
hindcast_data = []
for model in predictor_names: 
    if not Path(dataDir + '/' + (model + '.nc')).is_file() or force_download:
        X = dl.download(dl.hindcasts[model],dataDir + '/' + ( model+'.tsv'), **download_args, verbose=True, use_dlauth=False)
        X = getattr(X, [i for i in X.data_vars][0])
        X.name = Y.name
        X.to_netcdf(dataDir + '/' + '{}.nc'.format(model))
    else:
        X = xr.open_dataset(dataDir + '/' + (model + '.nc'))
        X = getattr(X, [i for i in X.data_vars][0])
        X.name = Y.name
    hindcast_data.append(X)


print('')
print('-------------------------')
print('Download HINDCAST data')
print('-------------------------')
print('')

# Donwload forecast data
# download forecast data 
forecast_data = []
for model in predictor_names: 
    if not Path(dataDir + '/' + (model + '_f.nc')).is_file() or force_download:
        F = dl.download(dl.forecasts[model], dataDir + '/' + (model+'_f.tsv'), **download_args, verbose=True, use_dlauth=False)
        F = getattr(F, [i for i in F.data_vars][0])
        F.name = Y.name
        F.to_netcdf(dataDir + '/' + (model + '_f.nc'))
    else:
        F = xr.open_dataset(dataDir + '/' + (model + '_f.nc'))
        F = getattr(F, [i for i in F.data_vars][0])
        F.name = Y.name
    forecast_data.append(F)

print('')
print('-------------------------')
print('Download Forecast data')
print('-------------------------')
print('')

