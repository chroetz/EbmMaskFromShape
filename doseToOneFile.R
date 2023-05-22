library(tidyverse)
library(RNetCDF)

outFile <- "countryMasksDose30arcmin.nc"

inFileNames <- dir(".", pattern = "^countryMasksDose_\\d+_to_\\d+.nc$")

meta <- read_csv("DoseRegions.csv")

  
# TODO: change ncdf4 calls to RNetCDF
ncOne <- ncdf4::nc_open(inFileNames[1])
ncdf4::nc_close(ncOne)

dimLon <- ncOne$dim$lon$vals
dimLat <- ncOne$dim$lat$vals
nLon <- length(dimLon)
nLat <- length(dimLat)

rnc <- create.nc(outFile, format = "netcdf4")
dim.def.nc(rnc, "lon", dimlength = nLon)
var.def.nc(rnc, "lon", "NC_DOUBLE", "lon")
var.put.nc(rnc, "lon", dimLon)
att.put.nc(rnc, "lon", "units", "NC_CHAR", "degree east")
dim.def.nc(rnc, "lat", dimlength = nLat)
var.def.nc(rnc, "lat", "NC_DOUBLE", "lat")
var.put.nc(rnc, "lat", dimLat)
att.put.nc(rnc, "lat", "units", "NC_CHAR", "degree north")

for (fileName in inFileNames) {
  
  cat("Processing", fileName, "\n")
  ncIn <- ncdf4::nc_open(fileName)
  
  for (i in seq_len(ncIn$nvars)) {
    
    varName <- ncIn$var[[i]]$name
    
    valueMatrix <- ncdf4::ncvar_get(ncIn, varName)
    var.def.nc(rnc, varName, "NC_DOUBLE", c("lon", "lat"), deflate = 9)
    var.put.nc(rnc, varName, valueMatrix)
    
    att.put.nc(rnc, varName, "units", "NC_CHAR", "1")
    
    meta1 <- meta |> filter(GID_1 == varName)
    if (nrow(meta1) != 1) stop()
    for (i in seq_along(meta1)) {
      att.put.nc(rnc, varName, names(meta1)[i], "NC_CHAR", meta1[[i]])
    }
    
  }
  
  ncdf4::nc_close(ncIn)
}

close.nc(rnc)

