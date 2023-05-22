source("shapefileUtil.R")


rasterMask <- function(maskFile, raster) {
  cntry <- sf::read_sf(maskFile)
  mask <- coverage_fraction(raster, cntry)
  stopifnot(length(mask) == 1)
  res <- t(as.matrix(mask[[1]]))
  stopifnot(dim(res) == c(nLon, nLat))
  return(res)
}



path <- "~/shapefiles/isimip"

varNames <- dir(path, pattern="^([A-Z]+)$") 
filePaths <- file.path(path, varNames, "country.geojson")
sel <- file.exists(filePaths)
filePaths <- filePaths[sel]
varNames <- varNames[sel]

nLon <- 720
nLat <- 360

outFile <- "countryMasksIsimip.nc"



globe <- getGlobalRaster(nLon, nLat)

maskArray <- sapply(
  filePaths, 
  simplify = "array",
  rasterMask,
  raster = globe$raster
)

dimnames(maskArray) <- list(lon = character(0), lat = character(0), varName = varNames)

writeMasksAsNetCdf(outFile, maskArray, dimLon = globe$dimLon, dimLat = globe$dimLat)



# Check...
str(maskArray)
x <- maskArray
dim(x) <- c(prod(dim(x)[1:2]), dim(x)[3])
str(x)
colnames(x) <- varNames
y <- rowSums(x)
sel <- y > 1.01
y[sel] # some cells are counted more than once...
z <- colSums(x[sel, ])
z[z > 0] # these countries have parts in cells that are counted more than once


