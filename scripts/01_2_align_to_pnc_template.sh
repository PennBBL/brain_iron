# Basic steps are:
# 1. Use flirt to align B0Map to mprage
# 2. Use c3d_affine_tool to convert to itk
# 3. Use antsApplyTransforms to do b0->mprage->template

maxjobs=20
demographicsFile=/data/joy/BBL/studies/pnc/n2416_dataFreeze/clinical/n2416_demographics_20170310.csv
t1DataDir=/data/joy/BBL/studies/pnc/processedData/structural/antsCorticalThickness/
outdir=/data/jux/BBL/projects/brain_iron/t2starData/
#template_brain=/data/joy/BBL/studies/pnc/n1601_dataFreeze/neuroimaging/pncTemplate/pnc_template_brain.nii.gz 
template_brain=/data/jux/BBL/projects/brain_iron/input_data/pnc_template_brain_4mm.nii.gz

#bblid=122895;scanid=8449;
sed 1d $demographicsFile |head -25 | while IFS=, read bblid scanid other; do

(thisOutDir=${outdir}/${bblid}/${scanid}/
thisAff=$(ls ${t1DataDir}/${bblid}/*${scanid}/SubjectToTemplate0GenericAffine.mat)
thisWarp=$(ls ${t1DataDir}/${bblid}/*${scanid}/SubjectToTemplate1Warp.nii.gz)
[[ -f $thisOutDir/${bblid}_${scanid}_t2star_pnc_bbr.nii.gz ]] && continue

# --- 1. Flirt ---
thisT1=$(ls $t1DataDir/$bblid/*${scanid}/ExtractedBrain0N4.nii.gz 2>/dev/null)||{ echo "missing T1 data for sub ${bblid}, scan ${scanid}!!!!"; continue ; }
thisSeg=$(ls $t1DataDir/$bblid/*${scanid}/BrainSegmentation.nii.gz 2>/dev/null)||{ echo "missing Segmentation data for sub ${bblid}, scan ${scanid}!!!!"; continue ; }
thisT2s=$(ls ${thisOutDir}/${bblid}_*x${scanid}_t2star.nii.gz 2>/dev/null)|| { echo "missing T2star data for ${bblid}, scan ${scanid}!!!"; continue ;}

#get wm seg
3dcalc -a $thisSeg -expr 'equals(a,3)' -prefix $thisOutDir/T1_wmseg.nii.gz -overwrite
echo "flirt bbr starting for ${bblid} ${scanid}..."
flirt -in $thisT2s -ref $thisT1 -omat $thisOutDir/${bblid}_${scanid}_t2star_to_t1_bbr.mat -dof 6 -cost bbr -wmseg $thisOutDir/T1_wmseg.nii.gz -o $thisOutDir/${bblid}_${scanid}_t2star_to_t1_bbr.nii.gz
flirt -in $thisT2s -ref $thisT1 -omat $thisOutDir/${bblid}_${scanid}_t2star_to_t1_mi.mat -dof 6 -cost mutualinfo -o $thisOutDir/${bblid}_${scanid}_t2star_to_t1_mi.nii.gz

# --- 2. Convert the matrix ---
c3d_affine_tool -ref $thisT1 -src $thisT2s $thisOutDir/${bblid}_${scanid}_t2star_to_t1_mi.mat -fsl2ras -oitk $thisOutDir/${bblid}_${scanid}_t2star_to_t1_mi.tfm
c3d_affine_tool -ref $thisT1 -src $thisT2s $thisOutDir/${bblid}_${scanid}_t2star_to_t1_bbr.mat -fsl2ras -oitk $thisOutDir/${bblid}_${scanid}_t2star_to_t1_bbr.tfm

# --- 3. Apply the xforms ---
antsApplyTransforms -d 3 -i $thisT2s -r $template_brain -o $thisOutDir/${bblid}_${scanid}_t2star_pnc_mi.nii.gz -t $thisWarp $thisAff $thisOutDir/${bblid}_${scanid}_t2star_to_t1_mi.tfm -n HammingWindowedSinc
antsApplyTransforms -d 3 -i $thisT2s -r $template_brain -o $thisOutDir/${bblid}_${scanid}_t2star_pnc_bbr.nii.gz -t $thisWarp $thisAff $thisOutDir/${bblid}_${scanid}_t2star_to_t1_bbr.tfm -n HammingWindowedSinc)&

while [ $(jobs -p|wc -l) -ge $maxjobs ]; do sleep 1; done

done
