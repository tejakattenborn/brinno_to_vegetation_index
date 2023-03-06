
library(magick)
require(foreach)
require(doParallel)
require(zoo)


dir = "<insert path to folders with brinno.avi files. Can be multiple folders>"


setwd(dir)
allpic = list.files("time_series_imagery"); allpic

n_cores = 5
cl <- parallel::makeCluster(n_cores)
doParallel::registerDoParallel(cl)

output = data.frame()
output <- foreach(i=1:length(allpic), .combine=rbind) %dopar% {
  
  library(magick)
  
  # list of potential indices: https://rdrr.io/cran/uavRst/man/rgb_indices.html

  grvi = function(dat){
    (dat[,,2]-dat[,,1])/(dat[,,2]+dat[,,1])
  }
  
  g2rb = function(dat){
    (2* dat[,,2]-dat[,,1]-dat[,,3])
  }
  
  gb = function(dat){
    (dat[,,2]-dat[,,3])
  }
  
  input <- image_read(allpic[i]) %>%# image_convert(type = 'Grayscale') %>%
    .[[1]] %>% as.numeric() # %>% grvi() %>% mean(na.rm=T)
  
  #samp = data.frame(pic = NA, block = NA, plot = NA, date_time = NA, vi = NA)
  samp = data.frame(block = NA, plot = NA, date_time = NA, grvi = NA, g2rb = NA, gb = NA)
  #samp[,1] =  allpic[i]
  samp[,1] =  substr(allpic[i], 7, 13)
  samp[,2] =  substr(allpic[i], 15, 17)
  samp[,3] =  as.POSIXct(substr(allpic[i], 19, 37), tz = "Europe/Berlin", format = "%Y-%m-%d_%H-%M-%OS")
  samp[,4] =  grvi(input) %>% mean(na.rm=T)
  samp[,5] =  g2rb(input) %>% mean(na.rm=T)
  samp[,6] =  gb(input) %>% mean(na.rm=T)
  return(samp)
}

stopCluster(cl)

output$date_time = as.POSIXct(output$date_time, origin = "1970-01-01")
output
write.csv(output, file = "1_exported_vi_v1.csv")
