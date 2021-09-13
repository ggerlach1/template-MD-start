#!/bin/bash

#SBATCH --job-name=xxxBASExxx

#SBATCH --nodes=1
##SBATCH --constraint="2080Ti" #tanV|V100|Turing|gtx1080Ti|Xp"
#SBATCH --ntasks-per-node=1
##SBATCH --nodelist=g101
#SBATCH --gres=gpu:1
#SBATCH --exclude=g019
###SBATCH --time=24:00:00

##SBATCH --partition=any_gpu
#SBATCH --partition=dept_gpu
##SBATCH --partition=camacho_gpu
#SBATCH --mail-type=NONE
#SBATCH --error=sbatch_array.%A_%a.stderr
#SBATCH --output=sbatch_array.%A_%a.stdout
#SBATCH --array=1-xxxTASKSxxx

#----PARAMETERS------------------------------------------------------------

##scratch drive folder to work in
JOBID=$(echo $SLURM_JOB_ID| grep -oP '^\d+')
SCRATCH_DIR=/scr/$USER/$SLURM_JOB_NAME/$JOBID
echo $JOBID

#if the scratch drive doesn't exist (it shouldn't) make it.
if [[ ! -e ${SCRATCH_DIR} ]]; then
    mkdir -p ${SCRATCH_DIR} && echo "scratch drive ${SCRATCH_DIR}"
fi

# change to scratch directory so job runs locally instead of over the network
# (slows everyone down)
cd ${SCRATCH_DIR}


SYSTEM=$SLURM_JOB_NAME
RESTART=0
NUM_STEPS=xxxNUM_STEPSxxx ##CHANGE
STEP_SIZE=xxxPROD_SIZExxx ##CHANGE 
INIT=$SYSTEM

AUX=$(( (NUM_STEPS-7)*STEP_SIZE))
SYSTEM_ARRAY1=(${SYSTEM}_presim{1..7} )
eval SYSTEM_ARRAY2=(${SYSTEM}_{$STEP_SIZE..$AUX..$STEP_SIZE}ns )        # eval is necesary for brace expantion
SYSTEM_ARRAY=(${SYSTEM_ARRAY1[@]} ${SYSTEM_ARRAY2[@]})

TYPES_ARRAY=(1_mini {2..6}_heat 7_equi_den 8_prod)
echo ${TYPES_ARRAY[*]}
echo ${TYPES_ARRAY[-1]}

## -----------------------    RUN AMBER    ---------------------------------------------

module load amber/20

for ((i=$RESTART; i<${NUM_STEPS}; i++))
do
	#echo -n "$i "
	if ([[   ${i} -gt 7 ]]); then INPUT=${TYPES_ARRAY[-1]};           else INPUT=${TYPES_ARRAY[$i]};    fi
	if ([[ ! ${i} == 0 ]]);  then INITCOOR=${SYSTEM_ARRAY[$((i-1))]}; else INITCOOR=${INIT};            fi
	ISTEP=${SYSTEM_ARRAY[$i]}
				
rsync -av \
      ${SLURM_SUBMIT_DIR}/mdin/${INPUT}.mdin    \
      ${SLURM_SUBMIT_DIR}/${INIT}_${SLURM_ARRAY_TASK_ID}.parm7    \
      ${SLURM_SUBMIT_DIR}/rst/${INITCOOR}_${SLURM_ARRAY_TASK_ID}.rst7 \
	  ${SLURM_SUBMIT_DIR}/cmds.txt \
	  ${SLURM_SUBMIT_DIR}/analysis/cpptraj.input \
	  ${SCRATCH_DIR}

	# Write cpptraj for stripping later 
	if ([[   ${i} -gt 7 ]])
	then
		for ((j=1; j<$((NUM_STEPS-6)); j++))
		do
    		OUTPUT_NUM=$((j*${STEP_SIZE}))
			LINE="trajin ../nc/${SLURM_JOB_NAME}_${OUTPUT_NUM}ns_${SLURM_ARRAY_TASK_ID}.nc 1 last 1"
			sed -i "/LINE/i ${LINE}" cpptraj.input 
		done
		sed -i "s/xxxBASExxx/${SLURM_JOB_NAME}/g" cpptraj.input
	fi
	
	# executable of gpu amber
	cmd=`sed -n "${SLURM_ARRAY_TASK_ID}p" cmds.txt`
	eval $cmd
	echo  "*******************"      
	echo  ${SCRATCH_DIR}             
	squeue  --format "%.18i %.9P %.50j %.8u %.2t %.10M %.6D %.6C %R" | \
		grep gjg21 | grep -P '(R|Prio)'  | nl 

	# copy partial results
    echo 'copying files'
    rsync -av ${SCRATCH_DIR}/${INPUT}.mdin ${SLURM_SUBMIT_DIR}/mdin
    rsync -av ${SCRATCH_DIR}/${ISTEP}_${SLURM_ARRAY_TASK_ID}.mdout ${SLURM_SUBMIT_DIR}/mdout
    rsync -av ${SCRATCH_DIR}/${INIT}_${SLURM_ARRAY_TASK_ID}.parm7 ${SLURM_SUBMIT_DIR}
    rsync -av ${SCRATCH_DIR}/${INITCOOR}_${SLURM_ARRAY_TASK_ID}.rst7 ${SLURM_SUBMIT_DIR}/rst
    rsync -av ${SCRATCH_DIR}/${ISTEP}_${SLURM_ARRAY_TASK_ID}.rst7 ${SLURM_SUBMIT_DIR}/rst
    rsync -av ${SCRATCH_DIR}/${ISTEP}_${SLURM_ARRAY_TASK_ID}.nc ${SLURM_SUBMIT_DIR}/nc
    rsync -av ${SCRATCH_DIR}/${ISTEP}_${SLURM_ARRAY_TASK_ID}.mdinfo ${SLURM_SUBMIT_DIR}/mdinfo
    rsync -av ${SCRATCH_DIR}/${ISTEP}_${SLURM_ARRAY_TASK_ID}.amber.out ${SLURM_SUBMIT_DIR}/mdout
    rsync -av ${SCRATCH_DIR}/cpptraj.input ${SLURM_SUBMIT_DIR}/analysis/cpptraj_long.input

	
done


#--------------------------------------------------------------------------
# Leave this line to tell slurm that the script finished correctly
exit 0
