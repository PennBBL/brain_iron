# Basic steps are:
# 1. Use flirt to align B0Map to mprage
# 2. Use c3d_affine_tool to convert to itk
# 3. Use antsApplyTransforms to do b0->mprage->template
scan_list="/data/jux/BBL/projects/brain_iron/scripts/xnat/xnat_table.csv"
#scan_list="/data/jux/BBL/projects/brain_iron/scripts/xnat/missing_data_xnat_table.csv"
maxjobs=20
baseOutputPath=/data/jux/BBL/projects/brain_iron/t2starData/


#bblid=112269;scanid=4339;
# 	bblid=12410;scanid=9982;rw sub
 sed 1d $scan_list |while IFS=, read zbblid zscanid sessionid f4 project f6 scannum f8 f9 desc other; do
	(
	bblid=$(echo ${zbblid}|sed 's/^0*//')
	scanid=$(echo ${zscanid}|sed 's/^0*//')
	subjOutputDir="${baseOutputPath}/${bblid}/${scanid}/"
	niftidir=${subjOutputDir}/nifti/
		
	# --- Process Structurals --- #
	case $project in 
	EON*)
		proj_label='pnc'
		# Uses PNC template
		template_brain=/data/jux/BBL/projects/brain_iron/input_data/pnc_template_brain_4mm.nii.gz
		t1DataDir=/data/joy/BBL/studies/pnc/processedData/structural/antsCorticalThickness/
		thisAff=$(ls ${t1DataDir}/${bblid}/*${scanid}/SubjectToTemplate0GenericAffine.mat)||{ echo "missing Affine mat for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		thisWarp=$(ls ${t1DataDir}/${bblid}/*${scanid}/SubjectToTemplate1Warp.nii.gz)||{ echo "missing warp coefs for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		betT1=$(ls $t1DataDir/$bblid/*${scanid}/ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		;;
	GRMPY* )
		proj_label='grmpy'
		# Uses PNC template
		template_brain=/data/jux/BBL/projects/brain_iron/input_data/pnc_template_brain_4mm.nii.gz
		t1DataDir="/data/joy/BBL/studies/grmpy/processedData/structural/struct_pipeline_20170716/"
		rthisAff=$(ls ${t1DataDir}/${bblid}/*${scanid}/antsCT/${bblid}*SubjectToTemplate0GenericAffine.mat 2>/dev/null)||{ echo "missing Affine mat for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		thisWarp=$(ls ${t1DataDir}/${bblid}/*${scanid}/antsCT/${bblid}*SubjectToTemplate1Warp.nii.gz 2>/dev/null)||{ echo "missing Warp coefs for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		betT1=$(ls ${t1DataDir}/${bblid}/*${scanid}/antsCT/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		;;
	NEFF* | FNDM* |DAY2*)
		proj_label='reward'
		# Uses Reward template
		template_brain=/data/jux/BBL/projects/brain_iron/input_data/reward_template_brain_4mm.nii.gz
		t1DataDir="/data/joy/BBL/studies/reward/processedData/structural/struct_pipeline_201705311006/"
		thisAff=$(ls ${t1DataDir}/${bblid}/*${scanid}/antsCT/${bblid}*SubjectToTemplate0GenericAffine.mat 2>/dev/null)||{ echo "missing Affine mat for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		thisWarp=$(ls ${t1DataDir}/${bblid}/*${scanid}/antsCT/${bblid}*SubjectToTemplate1Warp.nii.gz 2>/dev/null)||{ echo "missing Warp coefs for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		betT1=$(ls ${t1DataDir}/${bblid}/*${scanid}/antsCT/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		;;
	NODRA*)
		proj_label='reward'
		# Uses Reward template
		#template_brain=/data/jux/BBL/projects/brain_iron/input_data/reward_template_brain_4mm.nii.gz
		# Now use PNC
		template_brain=/data/jux/BBL/projects/brain_iron/input_data/pnc_template_brain_4mm.nii.gz
		t1DataDir="/data/joy/BBL/studies/reward/processedData/struc_pnc_template/"
		thisAff=$(ls ${t1DataDir}/${bblid}/${scanid}/struc/${bblid}*SubjectToTemplate0GenericAffine.mat 2>/dev/null)||{ echo "missing Affine mat for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		thisWarp=$(ls ${t1DataDir}/${bblid}/${scanid}/struc/${bblid}*SubjectToTemplate1Warp.nii.gz 2>/dev/null)||{ echo "missing Warp coefs for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		betT1=$(ls ${t1DataDir}/${bblid}/*${scanid}/struc/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		;;
	#CONTE* )
	#	proj_label='conte'
	#	# Uses PNC template
	#	template_brain=/data/jux/BBL/projects/brain_iron/input_data/pnc_template_brain_4mm.nii.gz
	#	t1DataDir="/data/joy/BBL/studies/conte/processedData/structural/conte_design3_n118_structural_201706051547/"
	#	thisAff=$(ls ${t1DataDir}/${bblid}/*${scanid}/antsCT/${bblid}*SubjectToTemplate0GenericAffine.mat 2>/dev/null)||{ echo "missing Affine mat for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
	#	thisWarp=$(ls ${t1DataDir}/${bblid}/*${scanid}/antsCT/${bblid}*SubjectToTemplate1Warp.nii.gz 2>/dev/null)||{ echo "missing Warp coefs for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
	#	betT1=$(ls ${t1DataDir}/${bblid}/*${scanid}/antsCT/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
	#	;;
		
	CONTE* )
		proj_label='conte'
		# Uses PNC template
		template_brain=/data/jux/BBL/projects/brain_iron/input_data/pnc_template_brain_4mm.nii.gz
		t1DataDir="/data/joy/BBL/studies/conte/processedData/structural_20190402/"
		thisAff=$(ls ${t1DataDir}/${bblid}/*${scanid}/struc/${bblid}*SubjectToTemplate0GenericAffine.mat 2>/dev/null)||{ echo "missing Affine mat for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		thisWarp=$(ls ${t1DataDir}/${bblid}/*${scanid}/struc/${bblid}*SubjectToTemplate1Warp.nii.gz 2>/dev/null)||{ echo "missing Warp coefs for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		betT1=$(ls ${t1DataDir}/${bblid}/*${scanid}/struc/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		;;
	ONM* )
		template_brain=/data/jux/BBL/projects/brain_iron/input_data/pnc_template_brain_4mm.nii.gz
		t1DataDir="/data/joy/BBL/studies/onm/processedData/structural/"
		thisAff=$(ls ${t1DataDir}/${bblid}/${scanid}/struc/${bblid}*SubjectToTemplate0GenericAffine.mat 2>/dev/null)||{ echo "missing Affine mat for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		thisWarp=$(ls ${t1DataDir}/${bblid}/${scanid}/struc/${bblid}*SubjectToTemplate1Warp.nii.gz 2>/dev/null)||{ echo "missing Warp coefs for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		betT1=$(ls ${t1DataDir}/${bblid}/${scanid}/struc/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		;;
	AGGY* )
		template_brain=/data/jux/BBL/projects/brain_iron/input_data/pnc_template_brain_4mm.nii.gz
		t1DataDir="/data/joy/BBL/studies/aggy/processedData/structural_20190315/"
		thisAff=$(ls ${t1DataDir}/${bblid}/*${scanid}/struc/${bblid}*SubjectToTemplate0GenericAffine.mat 2>/dev/null)||{ echo "missing Affine mat for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		thisWarp=$(ls ${t1DataDir}/${bblid}/*${scanid}/struc/${bblid}*SubjectToTemplate1Warp.nii.gz 2>/dev/null)||{ echo "missing Warp coefs for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		betT1=$(ls ${t1DataDir}/${bblid}/*${scanid}/struc/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		;;
	SYRP* )
		template_brain=/data/jux/BBL/projects/brain_iron/input_data/pnc_template_brain_4mm.nii.gz
		t1DataDir="/data/joy/BBL/studies/SYRP/processedData/structural_20190402/${bblid}/${scanid}/struc/"
		thisAff=$(ls ${t1DataDir}/${bblid}*SubjectToTemplate0GenericAffine.mat 2>/dev/null)||{ echo "missing Affine mat for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		thisWarp=$(ls ${t1DataDir}/${bblid}*SubjectToTemplate1Warp.nii.gz 2>/dev/null)||{ echo "missing Warp coefs for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
		betT1=$(ls ${t1DataDir}/${bblid}*ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing bet T1 data for PROJECT ${project} sub ${bblid}, scan ${scanid}!!!!" | tee -a $logfile; continue ; }
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

	
	[[ -f $subjOutputDir/${bblid}_${scanid}_r2star_templatespace.nii.gz ]] && continue

	# --- 1. Flirt ---
	thisT2s=$(ls ${subjOutputDir}/${bblid}_${scanid}_t2star.nii.gz 2>/dev/null)|| { echo "missing T2star data for ${bblid}, scan ${scanid}!!!"; continue ;}

	flirt -in $thisT2s -ref $betT1 -omat $subjOutputDir/${bblid}_${scanid}_t2star_to_t1.mat -dof 6 -cost mutualinfo -o $subjOutputDir/${bblid}_${scanid}_t2star_to_t1.nii.gz

	# --- 2. Convert the matrix ---
	c3d_affine_tool -ref $betT1 -src $thisT2s $subjOutputDir/${bblid}_${scanid}_t2star_to_t1.mat -fsl2ras -oitk $subjOutputDir/${bblid}_${scanid}_t2star_to_t1.tfm

	# --- 3. Apply the xforms ---
	#antsApplyTransforms -d 3 -i $thisT2s -r $template_brain -o $subjOutputDir/${bblid}_${scanid}_t2star_templatespace.nii.gz -t $thisWarp $thisAff $subjOutputDir/${bblid}_${scanid}_t2star_to_t1.tfm -n HammingWindowedSinc
	# R2star too
	thisR2s=$(ls ${subjOutputDir}/${bblid}_${scanid}_r2star.nii.gz 2>/dev/null)|| { echo "missing R2star data for ${bblid}, scan ${scanid}!!!"; continue ;}
	antsApplyTransforms -d 3 -i $thisR2s -r $template_brain -o $subjOutputDir/${bblid}_${scanid}_r2star_templatespace.nii.gz -t $thisWarp $thisAff $subjOutputDir/${bblid}_${scanid}_t2star_to_t1.tfm -n HammingWindowedSinc
	
	)&

while [ $(jobs -p|wc -l) -ge $maxjobs ]; do sleep 8s; done

done
wait
