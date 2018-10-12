function compare_bbr_mi
% Input data from calc_spatial_corrs.sh
%% spatial corr script:
%%
%  #!/bin/bash
%  # The purpose is to calculate the similarity (spatial correlation) between two different alingment cost functions, MI and BBR
%  demographicsFile=/data/joy/BBL/studies/pnc/n2416_dataFreeze/clinical/n2416_demographics_20170310.csv
%  template_mask=/data/jux/BBL/projects/brain_iron/input_data/pnc_template_brain_mask_4mm.nii.gz
%  outfile=/data/jux/BBL/projects/brain_iron/results/bbr_mi_ccs.csv
%  echo -n >$outfile
%  echo "bblid,scanid,cc">>$outfile
%    
%  sed 1d $demographicsFile |head -55 | while IFS=, read bblid scanid other; do
%    
%  thisDataDir=/data/jux/BBL/projects/brain_iron/t2starData/${bblid}/${scanid}
%    
%  mi=${thisDataDir}/${bblid}_${scanid}_t2star_pnc_mi.nii.gz
%  bbr=${thisDataDir}/${bblid}_${scanid}_t2star_pnc_bbr.nii.gz
%    
%  thisCC=$(fslcc -m $template_mask $bbr $mi|awk '{print $3}')
%   
%  echo "${bblid},${scanid},${thisCC}">>$outfile
%  done

%% simply print the histogram
dataTable = readtable('../../results/bbr_mi_ccs.csv');

figure;histogram(dataTable.cc,15);
xlabel('Spatial correlation (r)')
ylabel('Count')
box off
snapnow