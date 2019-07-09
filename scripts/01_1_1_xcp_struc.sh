study=reward

COHORTXCP=/data/joy/BBL/studies/${study}/${study}_anat_cohort.csv
cp /data/jux/BBL/projects/brain_iron/scripts/anatstruct.dsn /data/joy/BBL/studies/${study}/anatstruct.dsn
DESIGN=/data/joy/BBL/studies/${study}/anatstruct.dsn #modified from xcp github mimimal
OUTPUT=/data/joy/BBL/studies/${study}/processedData/struc_pnc_template/

$XCPEDIR/xcpEngine -c $COHORTXCP -d $DESIGN -m c -o $OUTPUT