#!/usr/bin/Rscript
##################################################################################
###    Script for data format conversion from CFT format to SEAFORDS format    ####
###                       Updated with season_list support                    ####
###                       Dhj Jun 2021 (Update September 2024)                ####
##################################################################################

rm(list = ls())
start_time <- Sys.time()
##################################################################################
#####                           ONLY EDIT HERE                              ######
# Define parameters
season_list <- c("NDJ", "DJF", "OND", "JFM", "FMA", "MAM", "AMJ", "MJJ", "JJA", "JAS", "ASO", "SON")  # List of seasons to process
year <- 2022  # Year for verification, the last year
param <- "rainfall"  # Choose between "rainfall" or "temperature"
param_name <- "RRsZone"  # Name of the parameter (PREC, RR, PRCTOT, TMAX, TX, TMIN, TN ...)
country <- "MAD"  # Choose your country or region
file_path <- "RR_MONTHLY_ZonageCLIM_MAD_FormatCFT.csv"  # Input file (CFT Format)
missing_value <- "-99"  # Missing value indicator
##################################################################################

rr <- read.csv(file_path, na.strings = missing_value)

for (season in season_list) {
  # Output file name specific to each season
  resultat <- paste0(country, "_", param_name, "_", season, ".txt")
  
  # Remove temporary files if they exist
  if (file.exists("tt2.csv")) { file.remove("tt2.csv") }
  if (file.exists("tt.csv")) { file.remove("tt.csv") }
  
  # Extract coordinates
  coord <- rr[, 1:4]
  coord2 <- rr[, 1:3]
  
  # Monthly data selection
  month_indices <- list(
    JAN = 5, FEB = 6, MAR = 7, APR = 8, MAY = 9, JUN = 10, 
    JUL = 11, AUG = 12, SEP = 13, OCT = 14, NOV = 15, DEC = 16
  )
  
  season_indices <- list(
    JFM = 5:7, FMA = 6:8, MAM = 7:9, AMJ = 8:10, MJJ = 9:11,
    JJA = 10:12, JAS = 11:13, ASO = 12:14, SON = 13:15, OND = 14:16,
    NDJ = c(15, 16, 5), DJF = c(16, 5, 6), ONDJFMA = c(14, 15, 16, 5, 6, 7, 8)
  )
  
  # Helper function to process season data with missing value handling
  process_season <- function(rr, indices, func, coord) {
    rrsea <- rr[, indices]
    mm <- apply(rrsea, 1, function(x) {
      if (any(is.na(x))) {
        return(NA)  # Assign NA if any missing value
      } else {
        return(func(x))
      }
    })
    mm <- round(mm, 2)
    cbind(coord, mm)
  }
  
  # Choose appropriate indices and function
  if (season %in% names(month_indices)) {
    cb <- process_season(rr, month_indices[[season]], mean, coord)
  } else if (param == "rainfall" && season %in% names(season_indices)) {
    cb <- process_season(rr, season_indices[[season]], sum, coord)
  } else if (param == "temperature" && season %in% names(season_indices)) {
    cb <- process_season(rr, season_indices[[season]], mean, coord)
  } else {
    stop("Invalid season or parameter combination")
  }
  
  # Special cases for multi-year seasons
  if (season %in% c("NDJ", "DJF", "ONDJFMA")) {
    fn <- "tmp.csv"
    if (file.exists(fn)) { file.remove(fn) }
    
    unique_ids <- unique(rr$ID)
    
    for (i in unique_ids) {
      rrs <- subset(rr, ID == i)
      for (a in rrs$Year) {
        rrk <- subset(rrs, Year == a)
        rrj <- subset(rrs, Year == ifelse(a == year, a, a + 1))
        
        # Handle last year (no data for the following year)
        if (a == year) {
          mmo <- NA  # Assign NA for the last year
        } else if (param == "rainfall") {
          mmo <- switch(
            season,
            NDJ = if (any(is.na(c(rrk[, 15], rrk[, 16], rrj[, 5])))) NA else round(sum(rrk[, 15], rrk[, 16], rrj[, 5]), 2),
            DJF = if (any(is.na(c(rrk[, 16], rrj[, 5], rrj[, 6])))) NA else round(sum(rrk[, 16], rrj[, 5], rrj[, 6]), 2),
            ONDJFMA = if (any(is.na(c(rrk[, 14:16], rrj[, 5:8])))) NA else round(sum(rrk[, 14:16], rrj[, 5:8]), 2)
          )
        } else if (param == "temperature") {
          mmo <- switch(
            season,
            NDJ = if (any(is.na(c(rrk[, 15], rrk[, 16], rrj[, 5])))) NA else round(mean(rrk[, 15], rrk[, 16], rrj[, 5]), 2),
            DJF = if (any(is.na(c(rrk[, 16], rrj[, 5], rrj[, 6])))) NA else round(mean(rrk[, 16], rrj[, 5], rrj[, 6]), 2),
            ONDJFMA = if (any(is.na(c(rrk[, 14:16], rrj[, 5:8])))) NA else round(mean(rrk[, 14:16], rrj[, 5:8]), 2)
          )
        } else {
          stop("Invalid parameter combination")
        }

        write(paste(i, a, mmo, sep = ","), fn, append = TRUE)
      }
    }
    
    tmp <- read.csv(fn, header = FALSE)
    cb <- merge(unique(coord2), tmp, by.x = "ID", by.y = "V1")
    names(cb) <- c("ID", "Lat", "Lon", "Year", "mm")
  }
  
  # Convert seasonal values to SEAFORDS format
  mat <- matrix(cb$mm, nrow = length(unique(cb$Year)), byrow = FALSE)
  coordcb <- cb[, 1:3]
  unccb <- unique(coordcb)
  tcoord <- t(unccb)
  
  # Write temporary files
  write.csv(tcoord, "tt.csv", row.names = c("STN", "LAT", "LON"))
  tro <- read.csv("tt.csv", header = FALSE)
  tro2 <- tro[-1, ]
  
  cbb <- cbind(unique(cb$Year), mat)
  write.csv(cbb, "tt2.csv", row.names = FALSE)
  trobe <- read.csv("tt2.csv", header = FALSE)
  trobe2 <- trobe[-1, ]
  
  dd <- rbind(tro2, trobe2)
  write.table(dd, resultat, row.names = FALSE, col.names = FALSE, sep = '\t', quote = FALSE, na = "-99.9")
  
  # Clean up temporary files
  if (file.exists("tt2.csv")) { file.remove("tt2.csv") }
  if (file.exists("tt.csv")) { file.remove("tt.csv") }
  if (file.exists("tmp.csv")) { file.remove("tmp.csv") }
}

end_time <- Sys.time()
print(end_time - start_time)
print("...........Conversion CFT format to SEAFORD format finished..........")
