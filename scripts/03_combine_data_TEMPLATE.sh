#!/bin/bash 

## Here we just cat all of the files from ROI extraction together
#Grab header line#!/bin/bash 

## Here we just cat all of the files from ROI extraction together
#Grab header line
awk 'FNR==1' ../t2starData/84891/6616/84891_6616_t2star_ROI_TEMPLATE.csv > ../results/t2star_ROIs_TEMPLATE_noName.csv
awk 'FNR>1' ../t2starData/*/*/*t2star_ROI_TEMPLATE.csv >> ../results/t2star_ROIs_TEMPLATE_noName.csv

awk 'FNR==1' ../t2starData/84891/6616/84891_6616_t2star_sigma_ROI_TEMPLATE.csv > ../results/t2star_sigma_ROIs_TEMPLATE_noName.csv
awk 'FNR>1' ../t2starData/*/*/*t2star_sigma_ROI_TEMPLATE.csv >> ../results/t2star_sigma_ROIs_TEMPLATE_noName.csv

matlab -nodisplay -nojvm -r "relabel_03_2_TEMPLATE; exit"
