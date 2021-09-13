#!/bin/bash

BASE_NAME=hs_s1 #CHANGE THIS 
PROTEIN_LENGTH=15 #CHANGE THIS 
RESTART=7
NUM_STEPS=13        # 300ns + equilibrium + minimization + heat
                    # in ARRAY_EXIT:
                    # index = 0; minimization water
                    # index = 1; minimization prot(backbone)
                    # index = 2; minimization system
		    # index = 3; heat wat
                    # index = 4; heat prot
		    # index = 5; heat sys
		    # index = 6; heat sys to 300, density equilibrium
                    # index = 7; production   10ns...
#QUEUE=dept_gpu I have been submitting to dept_gpu and camacho_gpu in a list in amber.slurm
#QUEUE=any_gpu
#QUEUE=camacho_gpu
SLURM_NAME_FILE0=array_step1.slurm
SLURM_NAME_FILE1=array.slurm

# step 1
sed -e "s/xxxBASExxx/${BASE_NAME}_60ns/"  \
    -e "s/xxxNAMExxx/${BASE_NAME}/"       \
    -e "s/xxxQUEUExxx/${QUEUE}/"          \
    -e "s/xxxSYSTEMxxx/${BASE_NAME}/"     \
    -e "s/xxxISTEPxxx/${BASE_NAME}_60ns/"  \
    -e "s/xxxINPUTxxx/8_prod/"        \
    -e "s/xxxINITCOORxxx/${BASE_NAME}_0ns/" \
    ${SLURM_NAME_FILE0} > ${BASE_NAME}_60ns.slurm
ARRAY_SLURM[7]=${BASE_NAME}_60ns.slurm


# production, NPT
for ((i=2; i<$((NUM_STEPS-6)); i++))
do
    INPUT_NUM=$((i*60-60))
    OUTPUT_NUM=$((i*60))
    SYSTEM_NAME=${BASE_NAME}_${OUTPUT_NUM}ns

    sed -e "s/xxxBASExxx/${SYSTEM_NAME}/"     \
        -e "s/xxxNAMExxx/${BASE_NAME}/"       \
        -e "s/xxxQUEUExxx/${QUEUE}/"          \
        -e "s/xxxSYSTEMxxx/${BASE_NAME}/"     \
        -e "s/xxxISTEPxxx/${BASE_NAME}_${OUTPUT_NUM}ns/" \
        -e "s/xxxINPUTxxx/8_prod/"              \
        -e "s/xxxINITCOORxxx/${BASE_NAME}_${INPUT_NUM}ns/"          \
        ${SLURM_NAME_FILE1} > ${SYSTEM_NAME}.slurm
    ARRAY_SLURM[$((i+6))]=${SYSTEM_NAME}.slurm
done


INIT=$RESTART
# first step
#ARRAY_EXIT[$INIT]=$(sbatch ${ARRAY_SLURM[$INIT]})
#echo "****${ARRAY_EXIT[$INIT]}****"


#ARRAY_EXIT[$INIT]=$(sbatch --dependency=afterok:38309 \
#			   ${ARRAY_SLURM[$INIT]})
#echo "*****${ARRAY_EXIT[$INIT]}"

#ARRAY_EXIT[$INIT]=$(sbatch --dependency=afterok:$(echo ${ARRAY_EXIT[0]} | awk '{print $NF}') \
#			   ${ARRAY_SLURM[$INIT]})
#echo ${ARRAY_EXIT[$INIT]}

# heat, quilibrium, production
# the 2nd, 3rd, ...
#for ((i=$((INIT+1)); i<${NUM_STEPS}; i++))
#do
 #   ARRAY_EXIT[$i]=$(sbatch --dependency=afterok:$(echo ${ARRAY_EXIT[$((i-1))]} | awk '{print $NF}') \
#                            ${ARRAY_SLURM[$i]} )
 #   echo "****${ARRAY_EXIT[$i]}****"
#done

exit 0
