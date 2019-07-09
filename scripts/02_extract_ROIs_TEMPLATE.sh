#!/bin/bash
##This is an adaptation of what Beard did in 2017 a la /data/jux/BBL/projects/beardr2star/scripts/n2416_scripts/n2416_means_20170627.sh
maxjobs=30

#sublist="/data/jux/BBL/projects/brain_iron/input_data/pnc_scans.csv"
sublist="/data/jux/BBL/projects/brain_iron/scripts/xnat/xnat_table.csv"
#sublist="/data/jux/BBL/projects/brain_iron/scripts/xnat/missing_data_xnat_table.csv"

t2starDataDir="/data/jux/BBL/projects/brain_iron/t2starData"
jlf="/data/jux/BBL/projects/brain_iron/input_data/pnc_jlf_4mm.nii.gz"

forcewrite=0; #Do we want to overwrite the outputs?

#Loop over subjects
#sed 1d $sublist  |while IFS=, read proj bblid scanid other; do
sed 1d $sublist | while IFS=, read zbblid zscanid other; do
	(
	bblid=$(echo ${zbblid}|sed 's/^0*//')
	scanid=$(echo ${zscanid}|sed 's/^0*//')
	thisSubDir="${t2starDataDir}/${bblid}/${scanid}/"
	
	#set variables and check if files exist
	thisT2=$(ls ${thisSubDir}/${bblid}_${scanid}_t2star_templatespace.nii.gz 2>/dev/null)||{ echo "missing T2 data for sub ${bblid}, scan ${scanid}!!!!"; continue ; }
	thisR2=$(ls ${thisSubDir}/${bblid}_${scanid}_r2star_templatespace.nii.gz 2>/dev/null)||{ echo "missing R2 data for sub ${bblid}, scan ${scanid}!!!!"; continue ; }
	
	[[ -r $thisSubDir/${bblid}_${scanid}_r2star_ROI_TEMPLATE.csv ]] && [[ $forcewrite -ne 1 ]]&& continue
	
	#Extract ROI values
	
	echo -n >$thisSubDir/${bblid}_${scanid}_r2star_ROI_TEMPLATE.csv
	3dROIstats -mask ${jlf} -nzmean -nomeanout -numROI 207 -zerofill NA $thisR2 | sed s@'\t'@','@g > $thisSubDir/r2star_ROI.csv
	echo -e "bblid,scanid\n${bblid},${scanid}" >$thisSubDir/sublabel.csv
	paste -d, $thisSubDir/sublabel.csv $thisSubDir/r2star_ROI.csv >$thisSubDir/${bblid}_${scanid}_r2star_ROI_TEMPLATE.csv
	rm $thisSubDir/sublabel.csv $thisSubDir/r2star_ROI.csv
	
	echo -n >$thisSubDir/${bblid}_${scanid}_r2star_sigma_ROI_TEMPLATE.csv
	3dROIstats -mask ${jlf} -nzsigma -nomeanout -numROI 207 -zerofill NA $thisT2 | sed s@'\t'@','@g > $thisSubDir/r2star_sigma_ROI.csv
	echo -e "bblid,scanid\n${bblid},${scanid}" >$thisSubDir/sublabel.csv
	paste -d, $thisSubDir/sublabel.csv $thisSubDir/r2star_sigma_ROI.csv >$thisSubDir/${bblid}_${scanid}_r2star_sigma_ROI_TEMPLATE.csv
	rm $thisSubDir/sublabel.csv $thisSubDir/r2star_sigma_ROI.csv
	
	
	echo "working on $bblid $scanid"
	echo -n >$thisSubDir/${bblid}_${scanid}_t2star_ROI_TEMPLATE.csv
	3dROIstats -mask ${jlf} -nzmean -nomeanout -numROI 207 -zerofill NA $thisT2 | sed s@'\t'@','@g > $thisSubDir/t2star_ROI.csv
	echo -e "bblid,scanid\n${bblid},${scanid}" >$thisSubDir/sublabel.csv
	paste -d, $thisSubDir/sublabel.csv $thisSubDir/t2star_ROI.csv >$thisSubDir/${bblid}_${scanid}_t2star_ROI_TEMPLATE.csv
	rm $thisSubDir/sublabel.csv $thisSubDir/t2star_ROI.csv
	
	echo -n >$thisSubDir/${bblid}_${scanid}_t2star_sigma_ROI_TEMPLATE.csv
	3dROIstats -mask ${jlf} -nzsigma -nomeanout -numROI 207 -zerofill NA $thisT2 | sed s@'\t'@','@g > $thisSubDir/t2star_sigma_ROI.csv
	echo -e "bblid,scanid\n${bblid},${scanid}" >$thisSubDir/sublabel.csv
	paste -d, $thisSubDir/sublabel.csv $thisSubDir/t2star_sigma_ROI.csv >$thisSubDir/${bblid}_${scanid}_t2star_sigma_ROI_TEMPLATE.csv
	rm $thisSubDir/sublabel.csv $thisSubDir/t2star_sigma_ROI.csv
	)&

	while [ $(jobs -p|wc -l) -ge $maxjobs ]; do sleep 2s; done

done 
wait
