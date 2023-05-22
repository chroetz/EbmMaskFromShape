library(tidyverse)
source("shapefileUtil.R")


path <- "~/shapefiles/DOSE/W2013Final.gpkg"

nLon <- 720
nLat <- 360



cat("read geodata file...")
pt <- proc.time()[3]
sf <- sf::read_sf(path)
cat(" done after", proc.time()[3] - pt, "s\n")


meta <- 
  unclass(sf)[c("GID_0","GID_1","NAME_0","NAME_1","ENGTYPE_1")] |> 
  as_tibble() |> 
  arrange(GID_0, GID_1)
write_csv(meta, "DoseRegions.csv")


globe <- getGlobalRaster(nLon, nLat)


# Doing all in one consumes too much memory...
# results <- coverage_fraction(globe$raster, sf)
# maskArray <- sapply(results, \(x) t(as.matrix(x)), simplify="array")


# Prepare Batches.
n <- nrow(sf)
batchSize <- 100
allIndices <- seq_len(n)
nBatches <- ceiling(n/batchSize)
batchIndexList <- lapply(
  seq_len(nBatches), 
  \(i) allIndices[((i-1)*batchSize+1):min(n, i*batchSize)])
outFileNames <- sapply(
  batchIndexList,
  \(batchIndices) paste0(
    "countryMasksDose_", min(batchIndices), "_to_", max(batchIndices), ".nc"))


cat("Start\n")
for (k in seq_len(nBatches)) {
  
  # Don't overwrite
  if (file.exists(outFileNames[k])) next
  
  batchIndices <- batchIndexList[[k]]
  
  cat("Start Batch ", k, "/", nBatches, 
      "from", min(batchIndices), "to", max(batchIndices), "\n")
  
  pt <- proc.time()[3]
  
  cat("claculate fraction; ")
  results <- coverage_fraction(globe$raster, sf[batchIndices, ])
  cat("reformat array; ")
  maskArray <- sapply(results, \(x) t(as.matrix(x)), simplify="array")
  
  dimnames(maskArray) <- list(
    lon = character(0), 
    lat = character(0), 
    varName = sf$GID_1[batchIndices])
  
  cat("write file; ")
  writeMasksAsNetCdf(
    outFileNames[k], 
    maskArray, 
    dimLon = globe$dimLon, dimLat = globe$dimLat)

  cat("Finished after", proc.time()[3] - pt, "s\n")
}
