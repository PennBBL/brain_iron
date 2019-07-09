#!/bin/bash
#set -xe
maxjobs=30
scan_list="/data/jux/BBL/projects/brain_iron/scripts/xnat/xnat_table.csv"
#scan_list="/data/jux/BBL/projects/brain_iron/scripts/xnat/missing_data_xnat_table.csv"

PNCrawDataDir="/data/joy/BBL/studies/pnc/rawData/"
PNCt1DataDir="/data/joy/BBL/studies/pnc/processedData/structural/antsCorticalThickness/"
PNCjlfDataDir="/data/joy/BBL/studies/pnc/processedData/structural/jlf/"
GRMPYt1DataDir="/data/joy/BBL/studies/grmpy/processedData/structural/struct_pncxcp_20181225/"
#REWt1DataDir="/data/joy/BBL/studies/reward/processedData/structural/struct_pipeline_201705311006/"
REWt1DataDir="/data/joy/BBL/studies/reward/processedData/struc_pnc_template/"
CONTEt1DataDir="/data/joy/BBL/studies/conte/processedData/structural/conte_design3_n118_structural_201706051547/"

d=$(date +%F)
logfile=logs/logfile_01_1_proc_structural_${d}.log
echo $d>$logfile

# sed 1d $scan_list | while IFS=, read zbblid zscanid sessionid f4 project f6 scannum sdate f9 desc other; do
sed 1d $scan_list | grep -i  "NODRA" | while IFS=, read zbblid zscanid sessionid f4 project f6 scannum sdate f9 desc other; do
	(
	scandate="$(echo $sdate | sed 's/-//g')" # remove the dashes from the date
	bblid=$(echo ${zbblid}|sed 's/^0*//') # remove the leading zeros
	scanid=$(echo ${zscanid}|sed 's/^0*//') # remove the leading zeros
	
	# --- Process Structurals --- #
	missing_t1=0
	missing_final=0
	is_rew=0
	case $project in 
	EON*)
		continue #haven't fixed this yet
		proj_name="pnc"
		thisRawDir="$( ls -d /data/joy/BBL/studies/pnc/rawData/${bblid}/*${scanid}/mprage 2>/dev/null)"||{ thisRawDir="/data/joy/BBL/studies/pnc/rawData/${bblid}/${scandate}x${scanid}/mprage/"; mkdir -p $thisRawDir ; }
		rawT1=$(ls $PNCrawDataDir/$bblid/*${scanid}/mprage/${bblid}_*t1.nii.gz 2>/dev/null)||missing_t1=1
		thisFinalDir="$(ls $PNCt1DataDir/$bblid/*${scanid}/ 2>/dev/null)"||{ thisFinalDir="$PNCt1DataDir/$bblid/${scanid}/"; mkdir -p $thisFinalDir ; }
		betT1=$(ls ${thisFinalDir}/ExtractedBrain0N4.nii.gz 2>/dev/null)|| missing_final=1
		;;
	GRMPY* )
		proj_name="grmpy"
		sdesc=("MPRAGE_TI1100_ipat2")
		s=${sdesc[0]}; fs=$(echo $s|sed 's/_//g')
		thisRawDir="$( ls -d /data/joy/BBL/studies/grmpy/rawData/${bblid}/*${scanid}/ 2>/dev/null)"||{ thisRawDir="/data/joy/BBL/studies/grmpy/rawData/${bblid}/${scandate}x${scanid}/"; mkdir -p $thisRawDir ; }
		if [ $(ls ${thisRawDir}/${s}/nifti/*${s}.nii.gz 2>/dev/null) ]; then
			rawT1=$(ls ${thisRawDir}/${s}/nifti/*${s}.nii.gz 2>/dev/null)
		elif [ $(ls ${thisRawDir}/${s}/nifti/*${fs}.nii.gz 2>/dev/null) ]; then
			rawT1=$(ls ${thisRawDir}/${s}/nifti/*${fs}.nii.gz 2>/dev/null)
		else
			missing_t1=1;
		fi
		betT1=$(ls ${GRMPYt1DataDir}/${bblid}/*${scanid}/antsCT/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||missing_final=1
		;;
	NODRA*)
		proj_name="reward"
		sdesc=("MPRAGE_TI1110_ipat2_moco3" "MPRAGE_TI1110_ipat2_moco3" "MPRAGE_TI1100_ipat2")
		thisRawDir="$( ls -d /data/joy/BBL/studies/reward/rawData/${bblid}/*x${scanid}/t1 2>/dev/null)"||{ thisRawDir="/data/joy/BBL/studies/conte/rawData/${bblid}/${scandate}x${scanid}/t1/"; mkdir -p $thisRawDir ; }
		rawT1=$(ls ${thisRawDir}/nifti/${bblid}_*x${scanid}_t1.nii.gz 2>/dev/null)||missing_t1=1
		#betT1=$(ls ${REWt1DataDir}/${bblid}/*x${scanid}/antsCT/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||missing_final=1
		betT1=$(ls ${REWt1DataDir}/${bblid}/${scanid}/struc/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||missing_final=1
		is_rew=1;
		;;
	NEFF* | FNDM* |DAY2*)
		proj_name="reward"
		sdesc=("MPRAGE_TI1110_ipat2_moco3" "MPRAGE_TI1110_ipat2_moco3" "MPRAGE_TI1100_ipat2")
		thisRawDir="$( ls -d /data/joy/BBL/studies/reward/rawData/${bblid}/*x${scanid}/t1 2>/dev/null)"||{ thisRawDir="/data/joy/BBL/studies/conte/rawData/${bblid}/${scandate}x${scanid}/t1/"; mkdir -p $thisRawDir ; }
		rawT1=$(ls ${thisRawDir}/nifti/${bblid}_*x${scanid}_t1.nii.gz 2>/dev/null)||missing_t1=1
		#betT1=$(ls ${REWt1DataDir}/${bblid}/*x${scanid}/antsCT/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||missing_final=1
		betT1=$(ls ${REWt1DataDir}/${bblid}/${scanid}/struc/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||missing_final=1
		is_rew=1;
		;;
	CONTE*)
		proj_name="conte"
		sdesc=("mprage_TI1100" "MPRAGE_TI1100_ipat2 MPRAGE_TI1110_ipat2_moco3" "MPRAGE_TI1100_ipat2")
		thisRawDir="$( ls -d /data/joy/BBL/studies/conte/rawData/${bblid}/*${scanid} 2>/dev/null)"||{ thisRawDir="/data/joy/BBL/studies/conte/rawData/${bblid}/${scandate}x${scanid}/"; mkdir -p $thisRawDir ; }
		for s in ${sdesc[@]}; do
			fs=$(echo $s|sed 's/_//g')
			if [ $(ls ${thisRawDir}/${s}/nifti/*${fs}.nii.gz 2>/dev/null) ]; then
				rawT1=$(ls ${thisRawDir}/${s}/nifti/*${fs}.nii.gz) 
				missing_t1=0
				break 1
			elif [ $(ls ${thisRawDir}/${s}/nifti/*${s}*.nii.gz 2>/dev/null) ]; then
				rawT1=$(ls ${thisRawDir}/${s}/nifti/*${s}*.nii.gz) 
				missing_t1=0
				break 1
				
			else
				missing_t1=1
			fi
		done
		betT1=$(ls ${CONTEt1DataDir}/${bblid}/*x${scanid}/antsCT/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||missing_final=1
		;;
	ONM*)
		sdesc=("MPRAGE_TI1110_ipat2_moco3")
		s=${sdesc[0]}; fs=$(echo $s|sed 's/_//g')
		proj_name="onm"
		thisRawDir="/data/joy/BBL/studies/${proj_name}/rawData/${bblid}/${scanid}/"
		mkdir -p $thisRawDir
		rawT1="$(ls ${thisRawDir}/*${s}*/nifti/*${fs}.nii.gz 2>/dev/null)"|| missing_t1=1
		thisFinalDir="/data/joy/BBL/studies/${proj_name}/processedData/structural/antsCT/${bblid}/${scanid}/"
		betT1="$(ls ${thisFinalDir}/*ExtractedBrain0N4.nii.gz 2>/dev/null)"||missing_final=1
		;;
	OLIFE*)
		proj_name="olife"
		sdesc=("MPRAGE_TI1100")
		s=${sdesc[0]}; fs=$(echo $s|sed 's/_//g')
		thisRawDir="/data/joy/BBL/studies/${proj_name}/rawData/${bblid}/${scanid}/"
		mkdir -p $thisRawDir
		rawT1="$(ls ${thisRawDir}/*${s}*/nifti/*${fs}.nii.gz 2>/dev/null)"|| missing_t1=1
		thisFinalDir="/data/joy/BBL/studies/${proj_name}/processedData/structural/antsCT/${bblid}/${scanid}/"
		betT1="$(ls ${thisFinalDir}/*ExtractedBrain0N4.nii.gz 2>/dev/null)"||missing_final=1
		;;
	SYRP*)
		proj_name="SYRP"
		sdesc=("MPRAGE_TI1110_ipat2_moco3")
		s=${sdesc[0]}; fs=$(echo $s|sed 's/_//g')
		thisRawDir="$(ls -d /data/joy/BBL/studies/${proj_name}/rawData/${bblid}/*${scanid}/ 2>/dev/null)" || { thisRawDir="/data/joy/BBL/studies/${proj_name}/rawData/${bblid}/${scandate}x${scanid}/"; mkdir -p $thisRawDir ; }
		rawT1="$(ls ${thisRawDir}/*${s}/nifti/*${s}_SEQ04.nii.gz 2>/dev/null)" || mising_t1=1
		thisFinalDir="/data/joy/BBL/studies/${proj_name}/processedData/structural/antsCT/${bblid}/${scanid}/"
		betT1="$(ls ${thisFinalDir}/*ExtractedBrain0N4.nii.gz 2>/dev/null)"||missing_final=1
		;;
	AGGY*)
		proj_name="aggy"
		sdesc=("MPRAGE_TI1100")
		thisRawDir="$(ls -d /data/joy/BBL/studies/${proj_name}/rawData/${bblid}/*${scanid}/mprage 2>/dev/null)" || { thisRawDir="/data/joy/BBL/studies/${proj_name}/rawData/${bblid}/${scandate}x${scanid}/mprage"; mkdir -p $thisRawDir ; }
		rawT1="$(ls ${thisRawDir}/nifti/*${s}*.nii.gz 2>/dev/null)" || mising_t1=1
		thisFinalDir="/data/joy/BBL/studies/${proj_name}/processedData/structural/antsCT/${bblid}/${scanid}/"
		betT1="$(ls ${thisFinalDir}/*ExtractedBrain0N4.nii.gz 2>/dev/null)"||missing_final=1
		;;
	*)
		echo "${project} Project not recognized"
		continue
	esac

	if [ $missing_final -eq 0 ]; then
		# we already have the processed structural $betT1
		continue
	fi

	if [ $missing_t1 -eq 1 ]; then
		# nifti doesn't exist
		# download the dicoms (func will skip if they already exist)
		/share/apps/python/Python-2.7.9/bin/python xnat/xnat_struct_downloader.py ${sessionid} ${thisRawDir} ${sdesc[@]} 

		this_sdesc=$(cat ${sessionid}_series_desc.txt)
		if [ "$this_sdesc" == "none" ]; then
			echo "didn't find a matching series description in XNAT for $project $bblid $scanid ${sdesc[@]}"|tee -a $logfile 
			continue
		fi
		[[ -r ${sessionid}_series_desc.txt ]]&&rm ${sessionid}_series_desc.txt

		# convert the dicoms to nifti
		scan_dir=$(ls -d ${thisRawDir}/*${this_sdesc}*)
		num_scan_dir=$(ls -d ${thisRawDir}/*${this_sdesc}*|wc -l)
		if [ $num_scan_dir -ne 1 ]; then
			echo "Sub ${bblid} Scan: ${scanid} number of struct dirs not equal to one"|tee -a $logfile
			echo "These are the dirs: $scan_dir"|tee -a $logfile
			continue
		fi
		outdir=${scan_dir}/nifti
		mkdir -p $outdir
		dcm2nii -d N -e N -v N -o ${outdir} ${scan_dir}/Dicoms/*dcm 2>>$logfile
		if [ $is_rew -eq 1 ]; then
			ln -s ${outdir} ${thisRawDir}/nifti
			ln -s ${outdir}/*gz ${thisRawDir}/nifti/${bblid}_${scandate}x${scanid}_t1.nii.gz
		fi
		rawT1=$(ls ${outdir/*gz})
	fi
	# make a link in a folder that matches PNC -- skip for now
	# subdir="${thisRawDir%%mprage*}"
# 	mkdir -p ${subdir}/mprage
# 	ln -s ${outdir}/*gz ${subdir}/mprage/${bblid}_${scanid}_t1.nii.gz
	if [ $missing_final -eq 1 ]; then
		# add the raw nifti to the cohort file for processing
		cohort_file="/data/joy/BBL/studies/${proj_name}/${proj_name}_anat_cohort.csv"
		if [ ! -r $cohort_file ]; then
			echo "id0,id1,img">$cohort_file
		fi
		echo "${bblid},${scanid},${rawT1}">> $cohort_file
		
		##The below is no longer correct, bacl to using xcp
		# We are no longer creating cohort files and running xcp. Instead, execute this code:
		#final_dir="/data/joy/BBL/studies/${proj_name}/processedData/structural/"
		#/data/joy/BBL/applications/ants_20151007/bin/antsCorticalThickness.sh \
		#-d 3 \
		#-a ${rawT1} \
		#-e /data/joy/BBL/studies/pnc/template/template.nii.gz \
		#-m /data/joy/BBL/studies/pnc/template/templateMask.nii.gz \
		#-f /data/joy/BBL/studies/pnc/template/templateMaskDil.nii.gz \
		#-p /data/joy/BBL/studies/pnc/template/priors/prior_00%d.nii.gz \
		#-w 0.2 \
		#-t /data/joy/BBL/studies/pnc/template/pnc_template_brain.nii.gz \
		#-o ${thisFinalDir}/
	fi

	) &
	while [ $(jobs -p|wc -l) -ge $maxjobs ]; do sleep 10s; done

done
wait
echo "Script completed at $(date)"|tee -a $logfile

