
require(abind)
require(av)
library(magick)
require(ggplot2)
library(tesseract)


dir = "<insert path to folders with brinno.avi files. Can be multiple folders>"
setwd(dir)

fps = NULL # how many fps to extract? If NULL, all frames will be extracted


folders = dir(getwd() , recursive = T, include.dirs = T, full.names = T)
folders = folders[-which(grepl(".AVI", folders))]; folders
folders = folders[-which(grepl("png", folders))]; folders


for(folder_id in 1:length(folders)){
  setwd(folders[folder_id])
  seqs = list.files(pattern = "AVI")  # load sequences

  if(length(seqs)>0){
    
    for(sequence in 1:length(seqs)){  # only apply loop for those videos that are "usable"
      
      # define output directory
      destdir = paste0(dir, "time_series_imagery")
      destdir_temp = paste0(destdir, "/temp")
      
      # create folders
      unlink(destdir_temp, recursive=TRUE) # clean target directory (if existent already)
      dir.create(destdir_temp) # create target directory # av_video_images will create a folder on its own
      
      # convert avi to jpeg 
      av_video_images(seqs[sequence], destdir = destdir_temp, format = "png", fps = fps) # to png, jpeg induces artefacts
      
      # read time stamp from jpeg
      lim_top = 690
      lim_bottom = 720
      lim_left = 395
      lim_right = 900
      
      eng = tesseract(options = list(tessedit_char_whitelist = "0123456789/: "), language = "eng") 
      
      all_pics = list.files(destdir_temp, full.names = T, pattern = "png")
      date_time = list()
      
      if(dim(image_read(all_pics[1])[[1]])[2] > 1200){
        
        for(pic in 1:length(all_pics)){
          input <- image_read(all_pics[pic]) %>%   # image_convert(type = 'Grayscale') %>%
            .[[1]] %>% 
            as.numeric()
          input_cut = input[c(lim_top:lim_bottom),c(lim_left:lim_right),] # crop time stamp section
          input_cut = (abs(input_cut-1)) # convert to black font on white background
          input_cut[input_cut <= 0.3] = 0 # set threshold
          input_cut[input_cut > 0.3] = 1 # set threshold
          input_cut[1:15,,] = 1 # insert upper margin; enhances character detection
          input_cut = abind(input_cut, input_cut[1:12,,], along=1)  # insert lower margin; enhances character detection
          
          date_time[[pic]] = input_cut  %>% image_read() %>% image_resize("280x") %>% tesseract::ocr(engine = eng) # resizing enahnces character detection
        }
        
        date_time = do.call(rbind, date_time)
        
        # remove unecessary chars
        date_time = apply(date_time, 2, substr, start=5, stop=23)
        
        # convert to POSIXct and copy date from file creation date (more safe than tesseract; not possible for time however)  
        date_time = as.POSIXct(date_time, tz = "Europe/Berlin", format = "%Y/%m/%d %H:%M:%OS") # check summer / winter time
        date_time = paste0(substr(file.info(seqs[sequence])$mtime, 1,10), substr(date_time, 11,20))
        date_time = as.POSIXct(date_time, tz = "Europe/Berlin", format = "%Y-%m-%d %H:%M:%OS")
        
        # remove outliers due to wrong date/time estimation
        outliers = which(is.na(date_time)) # in case PSIXct cannot reveal date time format (e.g., if estimated day in month exceeds total days of that month)
        outliers = c(outliers, which(abs(scale(date_time[-outliers])) > 2))
        if(length(outliers) > 0)
        {
          date_time = date_time[-outliers]
          file.remove(all_pics[outliers])
          all_pics = all_pics[-outliers]
        }
        
        # cut date / time area
        if(length(date_time)>0){
          for(pic in 1:length(all_pics)){
            input <- image_read(all_pics[pic]) %>%# image_convert(type = 'Grayscale') %>%
              .[[1]] %>% 
              as.numeric()
            input_cut = input[c(1:lim_top),,] # crop time stamp section
            input_cut  %>% image_read() %>% image_write(path = all_pics[pic])
          }
          file.rename(list.files(destdir_temp, full.names = T), paste0(destdir, "/",substr(basename(dir), 11, 16), "_",gsub("/", "_", substr(folders[folder_id], 50, 60)),"_",format(date_time, "%Y-%m-%d_%H-%M-%S"), ".png"))
        }
      }
    }
  }
}
