#!/bin/bash

# Define the input files
coordinate_file="synop_station.csv"  # The file containing the station names and coordinates
netcdf_file="RR_ENACTS_MON_Jan1981-May2022.nc"           # The NetCDF file with the daily data

# Define the output file for the combined extracted data
output_file="combined_extracted_test.csv"

# Count total number of stations
total_stations=$(wc -l < "$coordinate_file")

# Clean previous output file if it exists
rm -f "$output_file"

# Temporary files to store individual station data
temp_dir="temp_data"
mkdir -p "$temp_dir"

# Arrays to store station names, longitudes, and latitudes
station_names=()
longitudes=()
latitudes=()

# Initialize progress variables
station_progress=0
write_progress=0

# Function to update station progress
update_station_progress() {
    ((station_progress++))
    percentage=$((station_progress * 100 / total_stations))
    echo "Processing station $station_progress of $total_stations ($percentage%)..."
}

# Function to update write progress
update_write_progress() {
    percentage=$((write_progress * 100 / total_dates))
    echo -ne "Writing to output file ($percentage%)...\r"
}

# Process each coordinate pair from the coordinate file
while IFS= read -r line
do
    # Update station progress
    update_station_progress
    
    # Assuming the coordinate file is in the format: station_name,lat,lon
    station_name=$(echo "$line" | cut -d',' -f1)
    lat=$(echo "$line" | cut -d',' -f3)
    lon=$(echo "$line" | cut -d',' -f2)
    
    # Add station name, longitude, and latitude to arrays
    station_names+=("$station_name")
    longitudes+=("$lon")
    latitudes+=("$lat")
    
    # Temporary file to store the output from CDO
    temp_output="$temp_dir/${station_name}_temp.txt"
    
    # Use CDO to extract the value at the given coordinate
    cdo -outputtab,date,value -remapnn,lon=${lon}_lat=${lat} "$netcdf_file" > "$temp_output"
    
    # Remove the unwanted header lines and rename the "value" column
    tail -n +3 "$temp_output" | awk '{print $1,$2}' > "${temp_output}.clean"
done < "$coordinate_file"

# Write the headers to the combined output file
{
    # First row: station names
    echo -n "STN"
    for station in "${station_names[@]}"; do
        echo -n ",$station"
    done
    echo ""
    
    # Second row: latitudes
    echo -n "LAT"
    for lat in "${latitudes[@]}"; do
        echo -n ",$lat"
    done
    echo ""
    
    # Third row: longitudes
    echo -n "LON"
    for lon in "${longitudes[@]}"; do
        echo -n ",$lon"
    done
    echo ""
} >> "$output_file"

# Extract dates from the first station's cleaned file and combine the data
first_station_file="$temp_dir/${station_names[0]}_temp.txt.clean"
dates=$(cut -d' ' -f1 "$first_station_file")
total_dates=$(echo "$dates" | wc -l)

# Loop over dates and combine the data
while IFS= read -r date
do
    echo -n "$date" >> "$output_file"
    for station in "${station_names[@]}"; do
        station_file="$temp_dir/${station}_temp.txt.clean"
        value=$(grep "$date" "$station_file" | awk '{print $2}')
        echo -n ", $value" >> "$output_file"
    done
    echo "" >> "$output_file"
    
    # Update write progress
    ((write_progress++))
    update_write_progress
done <<< "$dates"

# Clean up temporary files
rm -rf "$temp_dir"

echo "Extraction complete. Results are saved in $output_file."
