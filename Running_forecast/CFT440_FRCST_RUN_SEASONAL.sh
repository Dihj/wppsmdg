#!/bin/bash
##########################################################################################
###### To run forecast in CFT with linux 
# To run this script, do: bash FRCST_RUN_SEASONAL.sh Month_start_frcst Year_start_Frcst Month_Predictor, 
# e.g. bash FRCST_RUN_SEASONAL.sh Oct 2024 Jul (initialization on July for FOrcst OND 2024)
# You need to edit manually setting.json file according to your need before runiing this especially on the repository and the zoning file
##########################################################################################

# Define variables
MONTH=$1  # Month to forecast (e.g., Oct, Nov, etc.)
YEAR=$2   # Year to forecast
#SEASON=$3 # Season to forecast (e.g., OND for Oct-Nov-Dec, DJF for Dec-Jan-Feb, etc.)

# Define the month, first year, and last year for the download links
MONTH_VAR=$3  # e.g., Sep
FIRST_YEAR=1960 # e.g., 1960
#LAST_YEAR=$6  # e.g., 2023

# Convert month to URL format (e.g., "Sep" to "%20Sep%20")
URL_MONTH="%20${MONTH_VAR}%20"

# Directory to save downloaded predictor files
DATA_DIR="./Frcst_RUN/data/cft_inputs"

# Define predictor URLs with specific date ranges and filenames
declare -A PREDICTORS
PREDICTORS=(
    ["SST"]="https://iridl.ldeo.columbia.edu/SOURCES/.NOAA/.NCDC/.ERSST/.version5/.sst/T/(${URL_MONTH}${FIRST_YEAR}-${YEAR})/RANGEEDGES/T/12/STEP/data.nc"
    ["HGP850"]="https://iridl.ldeo.columbia.edu/SOURCES/.NOAA/.NCEP-NCAR/.CDAS-1/.MONTHLY/.Intrinsic/.PressureLevel/.phi/P/(850)/VALUES/T/(${URL_MONTH}${FIRST_YEAR}-${YEAR})/RANGEEDGES/T/12/STEP/data.nc"
    ["HGP500"]="https://iridl.ldeo.columbia.edu/SOURCES/.NOAA/.NCEP-NCAR/.CDAS-1/.MONTHLY/.Intrinsic/.PressureLevel/.phi/P/(500)/VALUES/T/(${URL_MONTH}${FIRST_YEAR}-${YEAR})/RANGEEDGES/T/12/STEP/data.nc"
    ["U850"]="https://iridl.ldeo.columbia.edu/SOURCES/.NOAA/.NCEP-NCAR/.CDAS-1/.MONTHLY/.Intrinsic/.PressureLevel/.u/P/(850)/VALUES/T/(${URL_MONTH}${FIRST_YEAR}-${YEAR})/RANGEEDGES/T/12/STEP/data.nc"
    ["U200"]="https://iridl.ldeo.columbia.edu/SOURCES/.NOAA/.NCEP-NCAR/.CDAS-1/.MONTHLY/.Intrinsic/.PressureLevel/.u/P/(200)/VALUES/T/(${URL_MONTH}${FIRST_YEAR}-${YEAR})/RANGEEDGES/T/12/STEP/data.nc"
    ["V850"]="https://iridl.ldeo.columbia.edu/SOURCES/.NOAA/.NCEP-NCAR/.CDAS-1/.MONTHLY/.Intrinsic/.PressureLevel/.v/P/(850)/VALUES/T/(${URL_MONTH}${FIRST_YEAR}-${YEAR})/RANGEEDGES/T/12/STEP/data.nc"
    ["V200"]="https://iridl.ldeo.columbia.edu/SOURCES/.NOAA/.NCEP-NCAR/.CDAS-1/.MONTHLY/.Intrinsic/.PressureLevel/.v/P/(200)/VALUES/T/(${URL_MONTH}${FIRST_YEAR}-${YEAR})/RANGEEDGES/T/12/STEP/data.nc"
    ["MSLP"]="https://iridl.ldeo.columbia.edu/SOURCES/.NOAA/.NCEP-NCAR/.CDAS-1/.MONTHLY/.Intrinsic/.MSL/.pressure/SOURCES/.NOAA/.NCEP-NCAR/.CDAS-1/.MONTHLY/.Intrinsic/.MSL/.pressure/T/(${URL_MONTH}${FIRST_YEAR}-${YEAR})/RANGEEDGES/T/12/STEP/data.nc"
)

# Check and download missing predictors
for predictor in "${!PREDICTORS[@]}"; do
    FILE="${DATA_DIR}/${predictor}_${MONTH_VAR}_${FIRST_YEAR}-${YEAR}.nc"
    if [ ! -f "$FILE" ]; then
        echo "Downloading $predictor data..."
        wget "${PREDICTORS[$predictor]}" -O "$FILE"
    else
        echo "$predictor data already exists."
    fi
done

# Create the predictorList for the JSON settings
PREDICTOR_LIST="["
for predictor in "${!PREDICTORS[@]}"; do
    PREDICTOR_LIST+="\"${DATA_DIR}/${predictor}_${MONTH_VAR}_${FIRST_YEAR}-${YEAR}.nc\","
done
PREDICTOR_LIST="${PREDICTOR_LIST%,}]"

# Update the settings JSON file
SETTINGS_FILE="settings.json"
jq --argjson predictorList "$PREDICTOR_LIST" \
   --arg fcstPeriodStartMonth "$MONTH" \
   --arg predictorMonth "$MONTH_VAR" \
   --arg fcstyear "$YEAR" \
   '.predictorList = $predictorList | .fcstPeriodStartMonth = $fcstPeriodStartMonth | .predictorMonth = $predictorMonth | .fcstyear = ($fcstyear | tonumber)' \
   "$SETTINGS_FILE" > "settings_updated.json"

# Run the forecast model
source python3/bin/activate
#python3 cft.py settings_updated.json # wondering why this is not working, need mpi
mpirun -n 2 python3 cft_mpi.py settings_updated.json
