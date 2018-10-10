#!/bin/bash
##This is an adaptation of what Beard did in 2017 a la /data/jux/BBL/projects/beardr2star/scripts/n2416_scripts/n2416_means_20170627.sh
maxjobs=20

demographicsFile=/data/joy/BBL/studies/pnc/n2416_dataFreeze/clinical/n2416_demographics_20170310.csv
t2starDataDir=/data/joy/BBL/studies/pnc/processedData/b0mapwT2star/
t1DataDir=/data/joy/BBL/studies/pnc/processedData/structural/antsCorticalThickness/
jlfDataDir=/data/joy/BBL/studies/pnc/processedData/structural/jlf/

forcewrite=0; #Do we want to overwrite the outputs?

#make output directory
outdir=/data/jux/BBL/projects/brain_iron/t2starData
[[ ! -r $outdir ]]&&mkdir $outdir

#Loop over subjects
sed 1d $demographicsFile | while IFS=, read bblid sid other; do
	(
	echo $bblid $sid
	
	#set variables and check if files exist
	thisT2=$(ls $t2starDataDir/$bblid/*${sid}/${bblid}*x${sid}_t2star.nii.gz 2>/dev/null)||{ echo "missing T2 star data for sub ${bblid}, scan ${sid}!!!!"; continue ; }
	thisT1=$(ls $t1DataDir/$bblid/*${sid}/ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing T1 data for sub ${bblid}, scan ${sid}!!!!"; continue ; }
	thisJLF=$( ls $jlfDataDir/$bblid/*${sid}/${bblid}*x${sid}_jlfLabels.nii.gz 2>/dev/null)||{ echo "missing JLF data for sub ${bblid}, scan ${sid}!!!!"; continue ; }

	#make sure the files exist
	## Integrated this into the above command
	#[[ ! -r $(ls $thisT2) ]]&& echo "missing T2 star data for sub ${bblid}, scan ${sid}!!!!"&& continue
	#[[ ! -r $(ls $thisT1) ]]&& echo "missing T1 data for sub ${bblid}, scan ${sid}!!!!"&& continue
	#[[ ! -r $(ls $thisJLF) ]]&& echo "missing JLF data for sub ${bblid}, scan ${sid}!!!!"&& continue
	
	#make the output dirs
	thisOutDir=$outdir/$bblid/$sid
	[[ ! -r $outdir/$bblid ]] &&mkdir $outdir/$bblid 
	[[ ! -r $thisOutDir ]]&&mkdir $thisOutDir
	
	[[ -r $thisOutDir/${bblid}_${sid}_t2star_ROI.csv ]] && [[ $forcewrite -ne 1 ]]&& continue
	
	# Use flirt to register t1 brain to t2star
	flirt -in $thisT1 -ref $thisT2 -out $thisOutDir/${bblid}_${sid}_t1_in_t2star_space.nii.gz -omat $thisOutDir/${bblid}_${sid}_t1_to_t2star.mat -dof 6
	
	# Use flirt to apply resulting transformation to jlf labels
	flirt -interp nearestneighbour -dof 6 -in $thisJLF -ref $thisT2 -applyxfm -init $thisOutDir/${bblid}_${sid}_t1_to_t2star.mat -out $thisOutDir/${bblid}_${sid}_jlf_in_t2starSpace.nii.gz
	
	# Link T2* brain here as well
	ln -s $thisT2 $thisOutDir
	
	#Extract ROI values
	3dROIstats -mask $thisOutDir/${bblid}_${sid}_jlf_in_t2starSpace.nii.gz -nzmean -nomeanout -numROI 207 -zerofill NA $thisT2 | sed s@'\t'@','@g >> $thisOutDir/t2star_ROI.csv
	echo -e "bblid,sid\n${bblid},${sid}" >$thisOutDir/sublabel.csv
	paste -d, $thisOutDir/sublabel.csv $thisOutDir/t2star_ROI.csv >$thisOutDir/${bblid}_${sid}_t2star_ROI.csv
	rm $thisOutDir/sublabel.csv $thisOutDir/t2star_ROI.csv
	)&

	while [ $(jobs -p|wc -l) -ge $maxjobs ]; do sleep 2s; done

done 
wait
