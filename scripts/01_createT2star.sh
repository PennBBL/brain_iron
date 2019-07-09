#!/bin/bash
#set -xe
maxjobs=30
scan_list="/data/jux/BBL/projects/brain_iron/scripts/xnat/xnat_table.csv"
#scan_list="/data/jux/BBL/projects/brain_iron/scripts/xnat/missing_data_xnat_table.csv"
baseOutputPath="/data/jux/BBL/projects/brain_iron/t2starData/"

PNCrawDataDir="/data/joy/BBL/studies/pnc/rawData/"
PNCt1DataDir="/data/joy/BBL/studies/pnc/processedData/structural/antsCorticalThickness/"
PNCjlfDataDir="/data/joy/BBL/studies/pnc/processedData/structural/jlf/"
GRMPYt1DataDir="/data/joy/BBL/studies/grmpy/processedData/structural/struct_pipeline_20170716/" #"/data/joy/BBL/studies/grmpy/processedData/structural/struct_pncxcp_20181225/"
REWt1DataDir="/data/joy/BBL/studies/reward/processedData/struc_pnc_template/"
#CONTEt1DataDir="/data/joy/BBL/studies/conte/processedData/structural/conte_design3_n118_structural_201706051547/"
CONTEt1DataDir="/data/joy/BBL/studies/conte/processedData/structural_20190402/"

d=$(date +%F)
logfile=logfile_01_createT2star_${d}.log
echo $d>$logfile

echofile=echotimes.csv
echo "bblid,scanid,project,sequence,te1,te2,dTE">$echofile

sed 1d $scan_list |while IFS=, read zbblid zscanid sessionid f4 project f6 scannum f8 f9 desc other; do
	(
	bblid=$(echo ${zbblid}|sed 's/^0*//')
	scanid=$(echo ${zscanid}|sed 's/^0*//')
	subjOutputDir="${baseOutputPath}/${bblid}/${scanid}/"
	#dicoms=$(ls -d ${subjOutputDir}/${scannum}_*/Dicoms)||{ echo "Missing ${subjOutputDir}/${scannum}_*/Dicoms for $bblid $scanid $porject" | tee -a $logfile; continue ; }
	dicoms=$(ls -d ${subjOutputDir}/${scannum}_${desc}/Dicoms 2>/dev/null)||{ echo "Missing ${dicoms} for $bblid $scanid $project" | tee -a $logfile; continue ; }
	[[ ! -r ${subjOutputDir}/Dicoms ]] && ln -s ${dicoms} ${subjOutputDir}
	dicomdir=${subjOutputDir}/Dicoms/
	niftidir=${subjOutputDir}/nifti/

	
	# --- Dicom to nifti if we need to start from scratch ---#
	if [ ! -r ${niftidir}/mag2.nii.gz ]; then
		## We need to convert the dicoms to nifti
		#First dicom to nifti
		maglist1="";maglist2="";
		for d in $(ls ${dicomdir}/*dcm*);do 
			line=$(dicom_hdr $d |grep -i "echo number");
			echoNum=${line##*Number//}; 
			if [ $echoNum -eq 1 ]; then 
				maglist1="$maglist1 $d"; 
			elif [ $echoNum -eq 2 ]; then 
				maglist2="$maglist2 $d"; 
			else echo "\nbad echo count for $bblid $scanid $d">>$logfile;
			fi
		done
		mkdir -p ${niftidir}/mag1
		mkdir -p ${niftidir}/mag2
		dcm2nii -d N -e N -v N -o ${niftidir}/mag1 $maglist1 2>>$logfile
		dcm2nii -d N -e N -v N -o ${niftidir}/mag2 $maglist2 2>>$logfile
		# sym links
		ln -sf ${niftidir}/mag1/*nii.gz ${niftidir}/mag1.nii.gz
		ln -sf ${niftidir}/mag2/*nii.gz ${niftidir}/mag2.nii.gz
	fi
	mag1=${niftidir}/mag1.nii.gz
	mag2=${niftidir}/mag2.nii.gz
		
	# --- Process Structurals --- #
	case $project in 
	EONS_* |EONS3*)
		rawT1=$(ls $PNCrawDataDir/$bblid/*${scanid}/mprage/${bblid}_*t1.nii.gz 2>/dev/null)||{ echo "missing Raw T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		betT1=$(ls $PNCt1DataDir/$bblid/*${scanid}/ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		t1mask=$(ls $PNCt1DataDir/$bblid/*${scanid}/BrainExtractionMask.nii.gz 2>/dev/null)||{ echo "missing brain mask for sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		jlf=$(ls ${PNCjlfDataDir}/${bblid}/*${scanid}/${bblid}*jlfLabels.nii.gz 2>/dev/null)||{ echo "missing JLF labels for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		;;
	GRMPY* |EONSX* )
		rawT1=$(ls ${GRMPYt1DataDir}/${bblid}/*${scanid}/antsCT/${bblid}*RawInputImage.nii.gz 2>/dev/null)||{ echo "missing Raw T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		betT1=$(ls ${GRMPYt1DataDir}/${bblid}/*${scanid}/antsCT/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		t1mask=$(ls ${GRMPYt1DataDir}/${bblid}/*${scanid}/antsCT/${bblid}*BrainExtractionMask.nii.gz 2>/dev/null)||{ echo "missing mask for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		jlf=$(ls ${GRMPYt1DataDir}/${bblid}/*${scanid}/jlf/${bblid}*Labels.nii.gz 2>/dev/null)||{ echo "missing JLF labels for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		;;
	NODRA*)
		thisRawDir="$( ls -d /data/joy/BBL/studies/reward/rawData/${bblid}/*x${scanid}/t1 2>/dev/null)"||{ echo "missing Raw T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		rawT1=$(ls ${thisRawDir}/nifti/${bblid}_*x${scanid}_t1.nii.gz 2>/dev/null)||{ echo "missing Raw T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		betT1=$(ls ${REWt1DataDir}/${bblid}/${scanid}/struc/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		t1mask=$(ls ${REWt1DataDir}/${bblid}/${scanid}/struc/${bblid}*BrainExtractionMask.nii.gz 2>/dev/null)||{ echo "missing mask for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		#jlf=$(ls ${REWt1DataDir}/${bblid}/*${scanid}/jlf/${bblid}*Labels.nii.gz 2>/dev/null)||{ echo "missing JLF labels for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		;;
	NEFF* | FNDM* |DAY2*)
		thisRawDir="$( ls -d /data/joy/BBL/studies/reward/rawData/${bblid}/*x${scanid}/t1 2>/dev/null)"||{ echo "missing Raw T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		rawT1=$(ls ${thisRawDir}/nifti/${bblid}_*x${scanid}_t1.nii.gz 2>/dev/null)||{ echo "missing Raw T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		betT1=$(ls ${REWt1DataDir}/${bblid}/*${scanid}/antsCT/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		t1mask=$(ls ${REWt1DataDir}/${bblid}/*x${scanid}/antsCT/${bblid}*BrainExtractionMask.nii.gz 2>/dev/null)||{ echo "missing mask for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		jlf=$(ls ${REWt1DataDir}/${bblid}/*${scanid}/jlf/${bblid}*Labels.nii.gz 2>/dev/null)||{ echo "missing JLF labels for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		;;
	#CONTE* )
	#	rawT1=$(ls ${CONTEt1DataDir}/${bblid}/*x${scanid}/antsCT/${bblid}*RawInputImage.nii.gz 2>/dev/null)||{ echo "missing Raw T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
	#	betT1=$(ls ${CONTEt1DataDir}/${bblid}/*x${scanid}/antsCT/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
	#	t1mask=$(ls ${CONTEt1DataDir}/${bblid}/*x${scanid}/antsCT/${bblid}*BrainExtractionMask.nii.gz 2>/dev/null)||{ echo "missing mask for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
	#	jlf=$(ls ${CONTEt1DataDir}/${bblid}/*${scanid}/jlf/${bblid}*Labels.nii.gz 2>/dev/null)||{ echo "missing JLF labels for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
	#	;;
	CONTE* )
		t1DataDir="${CONTEt1DataDir}/${bblid}/${scanid}/struc/"
		rawT1=$(ls /data/joy/BBL/studies/conte/rawData/${bblid}/*${scanid}/*MPRAGE*/nifti/*MPRAGE*.nii.gz  2>/dev/null)||{ echo "missing Raw T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		betT1=$(ls ${t1DataDir}/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		t1mask=$(ls ${t1DataDir}/${bblid}*BrainExtractionMask.nii.gz 2>/dev/null)||{ echo "missing mask for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		#jlf=echo "no JLF labels for ONM" 
		;;
	ONM* )
		t1DataDir="/data/joy/BBL/studies/onm/processedData/structural/${bblid}/${scanid}/struc/"
		rawT1=$(ls /data/joy/BBL/studies/onm/rawData/${bblid}/${scanid}/MPRAGE_TI1110_ipat2_moco3/nifti/MPRAGETI1110ipat2moco3.nii.gz 2>/dev/null)||{ echo "missing Raw T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		betT1=$(ls ${t1DataDir}/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		t1mask=$(ls ${t1DataDir}/${bblid}*BrainExtractionMask.nii.gz 2>/dev/null)||{ echo "missing mask for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		#jlf=echo "no JLF labels for ONM" 
		;;
	AGGY* )
		t1DataDir="/data/joy/BBL/studies/aggy/processedData/structural_20190315/${bblid}/${scanid}/struc/"
		rawT1=$(ls /data/joy/BBL/studies/aggy/rawData/${bblid}/*${scanid}/mprage/nifti/*MPRAGE*.nii.gz 2>/dev/null)||{ echo "missing Raw T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		betT1=$(ls ${t1DataDir}/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		t1mask=$(ls ${t1DataDir}/${bblid}*BrainExtractionMask.nii.gz 2>/dev/null)||{ echo "missing mask for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		#jlf=echo "no JLF labels for ONM" 
		;;
		
	SYRP* )
		t1DataDir="/data/joy/BBL/studies/SYRP/processedData/structural_20190402/${bblid}/${scanid}/struc/"
		rawT1="$(ls -d /data/joy/BBL/studies/SYRP/rawData/${bblid}/*x${scanid}/*MPRAGE*/nifti/*MPRAGE*.nii.gz 2>/dev/null)" ||{ echo "missing Raw T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		betT1=$(ls ${t1DataDir}/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		t1mask=$(ls ${t1DataDir}/${bblid}*BrainExtractionMask.nii.gz 2>/dev/null)||{ echo "missing mask for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		#jlf=echo "no JLF labels for ONM" 
		;;

	OLIFE* )
		echo "No structural data yet for ${project}. Skipping for now..."| tee -a $logfile
		continue
		;;
	*)
		echo "${project} Project not recognized"
		continue
	esac
	
	if [ ! -r ${niftidir}/mask_in_mag1.nii.gz ]; then
		mkdir -p ${subjOutputDir}/structural/
		ln -sf $rawT1 ${subjOutputDir}/structural/${bblid}_${scanid}_T1.nii.gz
		ln -sf $betT1 ${subjOutputDir}/structural/${bblid}_${scanid}_T1_BET.nii.gz
		ln -sf $t1mask ${subjOutputDir}/structural/${bblid}_${scanid}_brain_mask.nii.gz
		#ln -sf $jlf ${subjOutputDir}/structural/${bblid}_${scanid}_jlf.nii.gz
	
		flirt -in $rawT1 -ref $mag1 -o ${niftidir}/T1_in_mag1.nii.gz  -omat ${niftidir}/t1_to_mag1.mat -dof 6
		flirt -in $betT1 -ref $mag1 -o ${niftidir}/betT1_in_mag1.nii.gz -init ${niftidir}/t1_to_mag1.mat -applyxfm -interp nearestneighbour
		flirt -in $t1mask -ref $mag1 -o ${niftidir}/mask_in_mag1.nii.gz -init ${niftidir}/t1_to_mag1.mat -applyxfm -interp nearestneighbour	
		#flirt -in $jlf -ref $mag1 -o ${niftidir}/jlf_in_mag1.nii.gz -init ${niftidir}/t1_to_mag1.mat -applyxfm -interp nearestneighbour	
	fi
	

	# --- Calculate T2* ---
	# [ ! -r ${subjOutputDir}/${bblid}_${scanid}_t2star.nii.gz ]; then
		# get the echo times
		for d in $(ls ${dicomdir}/*dcm*);do 
			echoline=$(dicom_hdr $d |grep -i "echo number");
			echoNum=${echoline##*Number//}; 
			timeline=$(dicom_hdr $d |grep -i "echo time");
			echoTime=${timeline##*Time//};
			if [ $echoNum -eq 1 ]; then 
				te1=$echoTime
			elif [ $echoNum -eq 2 ]; then 
				te2=$echoTime 
			else echo "\nbad echo numbers for $bblid $scanid $d">>$logfile;
			fi
		done
		dTE=$(echo $te2 - $te1 |bc) #bc does floating point math
		#echo "Detected TE1 = $te1, TE2 = $te2; dTE = $dTE"
		echo "${bblid},${scanid},${project},${desc},${te1},${te2},$dTE">>$echofile
	
	# T2*
	if [ ! -r ${subjOutputDir}/${bblid}_${scanid}_t2star.nii.gz ]; then

		mask=${niftidir}/mask_in_mag1.nii.gz 2>>$logfile
		fslmaths $mag1 -s 3 ${subjOutputDir}/mag1sm.nii.gz
		fslmaths $mag2 -s 3 ${subjOutputDir}/mag2sm.nii.gz
		mag1sm=${subjOutputDir}/mag1sm.nii.gz
		mag2sm=${subjOutputDir}/mag2sm.nii.gz
		3dcalc -a $mag1sm -b $mag2sm -expr "-$dTE/(log(b/a))" -prefix ${subjOutputDir}/${bblid}_${scanid}_t2star.nii.gz -overwrite
		3dcalc -a ${subjOutputDir}/${bblid}_${scanid}_t2star.nii.gz -b $mask -expr '(a*b)' -prefix ${subjOutputDir}/${bblid}_${scanid}_t2star.nii.gz -overwrite
		rm $mag1sm $mag2sm
	fi
	if [ ! -r ${subjOutputDir}/${bblid}_${scanid}_r2star.nii.gz ]; then
		3dcalc -a ${subjOutputDir}/${bblid}_${scanid}_t2star.nii.gz '(1000/a)' -prefix ${subjOutputDir}/${bblid}_${scanid}_r2star.nii.gz -overwrite # convert T2* (msec) to R2*(sec)
	fi
	) &
	while [ $(jobs -p|wc -l) -ge $maxjobs ]; do sleep 1s; done

done
echo "Script completed at $(date)"|tee -a $logfile

