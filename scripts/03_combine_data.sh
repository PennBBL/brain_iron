#!/bin/bash 

## Here we just cat all of the files from 01 together
#Grab header line
awk 'FNR==1' ../t2starData/84891/6616/84891_6616_t2star_ROI.csv > ../results/t2star_ROIs_noName.csv
awk 'FNR>1' ../t2starData/*/*/*t2star_ROI.csv >> ../results/t2star_ROIs_noName.csv

matlab -nodisplay -nojvm -r "relabel_02_2; exit"
