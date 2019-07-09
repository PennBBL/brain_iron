sublist=SubjectList.csv 

pnclist=""
grmpylist=""
contelist=""
rewlist=""

while IFS=, read id scanid proj; do 
	thispath="/data/jux/BBL/projects/brain_iron/t2starData/${id}/${scanid}/${id}_${scanid}_t2star_templatespace.nii.gz"
	[[ ! -r $thispath ]]&&continue
	case $proj in
	EONS_* | EONS3*)
		pnclist="$pnclist ${thispath}"
		;;
	GRMPY* | EONSX* )
		grmpylist="$grmpylist ${thispath}"
		;;
	NODRA* | NEFF* | FNDM* |DAY2*)
		rewlist="$rewlist ${thispath}"
		;;
	CONTE*)
		contelist="$contelist ${thispath}"
		;;
	esac
done <<<"$(sed 1d $sublist)"
# 3dbucket -prefix "../input_data/rew.nii.gz" $rewlist
# 3dbucket -prefix "../input_data/grmpy.nii.gz" $grmpylist
# 3dbucket -prefix "../input_data/conte.nii.gz" $contelist
3dbucket -prefix "../input_data/pnc.nii.gz" $pnclist