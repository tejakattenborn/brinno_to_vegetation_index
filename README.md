# brinno_to_vegetation_index
These R-Scripts extract timeseries of image frames of Brinno TLC-200Pro .avi files and calculate RGB vegetation indices.

For each extract image frame the date and time will be extracted using pattern recognition from the image time-stamp at the bottom of the image. Based on these imagery 3 vegetation indices are calculated:
* GRVI (Green-Red Vegetation Index)
* G2-R-B
* G-B

The list of indices can be easily extended. The output (date and index) can be written to a file.
