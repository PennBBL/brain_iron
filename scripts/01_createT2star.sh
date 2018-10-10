demographicsFile=/data/joy/BBL/studies/pnc/n2416_dataFreeze/clinical/n2416_demographics_20170310.csv
baseOutputPath="/data/jux/BBL/projects/brain_iron/t2starData/"
baseRawDataPath="/data/joy/BBL/studies/pnc/rawData/"
t1DataDir=/data/joy/BBL/studies/pnc/processedData/structural/antsCorticalThickness/
pncB0DataDir=/data/joy/BBL/studies/pnc/processedData/b0mapwT2star/

t2only=1;
#sed 1d $demographicsFile |head | while IFS=, read bblid scanid other; do
bblid=80557;scanid=3476;
    subjRawData="${baseRawDataPath}${bblid}/*x${scanid}"
    subjB0Maps=`find ${subjRawData} -name "B0MAP*" -type d`
    subjB0Maps1=`echo ${subjB0Maps} | cut -f 1 -d ' '`
    subjB0Maps2=`echo ${subjB0Maps} | cut -f 2 -d ' '`
    subjOutputDir="${baseOutputPath}/${bblid}/${scanid}/"
	
	mkdir -p ${subjOutputDir}
	rawT1=$(ls $subjRawData/*mprage*/*t1.nii.gz)||{ echo "missing Raw T1 data for sub ${bblid}, scan ${sid}!!!!"; continue ; }
	betT1=$(ls $t1DataDir/$bblid/*${sid}/ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for sub ${bblid}, scan ${sid}!!!!"; continue ; }
	
	if [ $t2only -ne 1 ]; then
		#Run the script for b0map processing and T2 generation
		/data/jux/BBL/projects/pncReproc2015/pncReproc2015Scripts/dico/dico_b0calc_v4_afgr.sh -2 ${subjOutputDir}${bblid}_${scanid} ${subjB0Maps1}/ ${subjB0Maps2}/ ${rawT1} ${betT1}
		for i in `ls ${subjOutputDir}*nii` ; do 
			/share/apps/fsl/5.0.8/bin/fslchfiletype NIFTI_GZ ${i} ; 
		done  
	else
		# --- Just calculate T2* ---
		# get the echo times
		te1_line=$(dicom_hdr $(find $subjB0Maps1 | sort -n |sed -n 2p)|grep -i "echo time")
		te1=${te1_line##*Time//}
		te2_line=$(dicom_hdr $(find $subjB0Maps1 | sort -n |tail -1)|grep -i "echo time")
		te2=${te2_line##*Time//}
		dTE=$(echo $te2 - $te1 |bc) #bc does floating point math
		echo "Detected TE1 = $te1, TE2 = $te2; dTE = $dTE"

		# T2*
		mask=$(find ${pncB0DataDir}/$bblid/*${scanid}/${bblid}*mask*.nii.gz)
		mag1=$(find ${pncB0DataDir}/$bblid/*${scanid}/${bblid}*mag1.nii.gz)
		mag2=$(find ${pncB0DataDir}/$bblid/*${scanid}/${bblid}*mag2.nii.gz)
		fslmaths $mag1 -s 3 ${subjOutputDir}/mag1sm.nii.gz
		fslmaths $mag2 -s 3 ${subjOutputDir}/mag2sm.nii.gz
		mag1sm=${subjOutputDir}/mag1sm.nii.gz
		mag2sm=${subjOutputDir}/mag2sm.nii.gz
		3dcalc -a $mag1sm -b $mag2sm -expr "-$dTE/(log(b/a))" -prefix ${subjOutputDir}/${bblid}_${scanid}_t2star.nii.gz -overwrite
		3dcalc -a ${subjOutputDir}/${bblid}_${scanid}_t2star.nii.gz -b $mask -expr '(a*b)' -prefix ${subjOutputDir}/${bblid}_${scanid}_t2star.nii.gz -overwrite
		rm $mag1sm $mag2sm
	fi
#done
