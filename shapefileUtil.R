library(exactextractr)
library(sf)
library(raster)
library(RNetCDF)


getGlobalRaster <- function(nLon, nLat) {
  
  rangeLon <- c(-180, 180)
  rangeLat <- c(-90, 90)
  
  rasterGlobal <- raster(
    nrows = nLat, 
    ncols = nLon, 
    xmn = rangeLon[1], xmx = rangeLon[2], 
    ymn = rangeLat[1], ymx = rangeLat[2])
  
  return(list(
    raster = rasterGlobal, 
    dimLon = xFromCol(rasterGlobal), 
    dimLat = yFromRow(rasterGlobal), 
    coordinates = coordinates(rasterGlobal)))
}


writeMasksAsNetCdf <- function(outFile, maskArray, dimLon, dimLat) {
  stopifnot(
    length(dimLon) == dim(maskArray)[1],
    length(dimLat) == dim(maskArray)[2])
  nLon <- length(dimLon)
  nLat <- length(dimLat)
  varNames <- dimnames(maskArray)[[3]]
  rnc <- create.nc(outFile, format = "netcdf4")
  dim.def.nc(rnc, "lon", dimlength = nLon)
  var.def.nc(rnc, "lon", "NC_DOUBLE", "lon")
  var.put.nc(rnc, "lon", dimLon)
  att.put.nc(rnc, "lon", "units", "NC_CHAR", "degree east")
  dim.def.nc(rnc, "lat", dimlength = nLat)
  var.def.nc(rnc, "lat", "NC_DOUBLE", "lat")
  var.put.nc(rnc, "lat", dimLat)
  att.put.nc(rnc, "lat", "units", "NC_CHAR", "degree north")
  for (varName in varNames) {
    var.def.nc(rnc, varName, "NC_DOUBLE", c("lon", "lat"), deflate = 9)
    att.put.nc(rnc, varName, "units", "NC_CHAR", "1")
    var.put.nc(rnc, varName, maskArray[,,varName])
  }
  close.nc(rnc)
}
