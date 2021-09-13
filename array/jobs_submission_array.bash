#!/bin/bash

BASE_NAME=xxxBASE_FROMxxx #CHANGE THIS 
PROTEIN_LENGTH=xxxLENGTHxxx #CHANGE THIS 
RESTART=0
NUM_STEPS=14 #This gives slurm files for 0-600 ns and submits the minimization to equilibration as dependencies but not the producttion runs
        # 300ns + equilibrium + minimization + heat
                    # in ARRAY_EXIT:
                    # index = 0; minimization water
                    # index = 1; minimization prot(backbone)
                    # index = 2; minimization system
		    # index = 3; heat wat
                    # index = 4; heat prot
		    # index = 5; heat sys
		    # index = 6; heat sys to 300, density equilibrium
                    # index = 7; production   60ns...
#QUEUE=dept_gpu I have been submitting to dept_gpu and camacho_gpu in a list in amber.slurm
#QUEUE=any_gpu
#QUEUE=camacho_gpu
SLURM_NAME_FILE0=array_step1.slurm
SLURM_NAME_FILE1=array.slurm
SLURM_NAME_FILE=amber.slurm

# write number of residues into the .mdin files
sed "s/xxxPROTEIN_LENGTHxxx/${PROTEIN_LENGTH}/g" mdin_var/1_mini.mdin > mdin/1_mini.mdin
sed "s/xxxPROTEIN_LENGTHxxx/${PROTEIN_LENGTH}/g" mdin_var/2_heat.mdin > mdin/2_heat.mdin
sed "s/xxxPROTEIN_LENGTHxxx/${PROTEIN_LENGTH}/g" mdin_var/3_heat.mdin > mdin/3_heat.mdin
sed "s/xxxPROTEIN_LENGTHxxx/${PROTEIN_LENGTH}/g" mdin_var/4_heat.mdin > mdin/4_heat.mdin
sed "s/xxxPROTEIN_LENGTHxxx/${PROTEIN_LENGTH}/g" mdin_var/5_heat.mdin > mdin/5_heat.mdin

# Write cpptraj for stripping later 
for ((j=1; j<4;j++))
	do
	for ((i=1; i<$((NUM_STEPS-7)); i++))
	do
	    OUTPUT_NUM=$((i*100))
		LINE="trajin ../nc/${BASE_NAME}_${OUTPUT_NUM}ns_${j}.nc 1 last 1"
		sed -i "/LINES/i ${LINE}" analysis/cpptraj_${j}.input 
	done
done


# minimization system, NVT
sed -e "s/xxxBASExxx/${BASE_NAME}_mini/"  \
    -e "s/xxxNAMExxx/${BASE_NAME}/"       \
    -e "s/xxxQUEUExxx/${QUEUE}/"          \
    -e "s/xxxSYSTEMxxx/${BASE_NAME}/"     \
    -e "s/xxxISTEPxxx/${BASE_NAME}_mini/" \
    -e "s/xxxINPUTxxx/1_mini/"              \
    -e "s/xxxINITCOORxxx/\$INIT/" \
    ${SLURM_NAME_FILE} > ${BASE_NAME}_mini.slurm
ARRAY_SLURM[0]=${BASE_NAME}_mini.slurm

# heat water (protein hold), NPT, 10 Kcal/mol
sed -e "s/xxxBASExxx/${BASE_NAME}_heat1/"    \
    -e "s/xxxNAMExxx/${BASE_NAME}/"         \
    -e "s/xxxQUEUExxx/${QUEUE}/"            \
    -e "s/xxxSYSTEMxxx/${BASE_NAME}/"       \
    -e "s/xxxISTEPxxx/${BASE_NAME}_heat1/"   \
    -e "s/xxxINPUTxxx/2_heat/"          \
    -e "s/xxxINITCOORxxx/${BASE_NAME}_mini/"\
    ${SLURM_NAME_FILE} > ${BASE_NAME}_heat1.slurm
ARRAY_SLURM[1]=${BASE_NAME}_heat1.slurm

# heat water (protein hold), NPT, 5 Kcal/mol
sed -e "s/xxxBASExxx/${BASE_NAME}_heat2/"    \
    -e "s/xxxNAMExxx/${BASE_NAME}/"         \
    -e "s/xxxQUEUExxx/${QUEUE}/"            \
    -e "s/xxxSYSTEMxxx/${BASE_NAME}/"       \
    -e "s/xxxISTEPxxx/${BASE_NAME}_heat2/"   \
    -e "s/xxxINPUTxxx/3_heat/"          \
    -e "s/xxxINITCOORxxx/${BASE_NAME}_heat1/"\
    ${SLURM_NAME_FILE} > ${BASE_NAME}_heat2.slurm
ARRAY_SLURM[2]=${BASE_NAME}_heat2.slurm

# heat water (protein backbone hold), NPT, 2.5 Kcal/mol
sed -e "s/xxxBASExxx/${BASE_NAME}_heat3/"    \
    -e "s/xxxNAMExxx/${BASE_NAME}/"         \
    -e "s/xxxQUEUExxx/${QUEUE}/"            \
    -e "s/xxxSYSTEMxxx/${BASE_NAME}/"       \
    -e "s/xxxISTEPxxx/${BASE_NAME}_heat3/"   \
    -e "s/xxxINPUTxxx/4_heat/"          \
    -e "s/xxxINITCOORxxx/${BASE_NAME}_heat2/"\
    ${SLURM_NAME_FILE} > ${BASE_NAME}_heat3.slurm
ARRAY_SLURM[3]=${BASE_NAME}_heat3.slurm

# heat water (protein backbone hold), NPT, 1.0 Kcal/mol
sed -e "s/xxxBASExxx/${BASE_NAME}_heat4/"    \
    -e "s/xxxNAMExxx/${BASE_NAME}/"         \
    -e "s/xxxQUEUExxx/${QUEUE}/"            \
    -e "s/xxxSYSTEMxxx/${BASE_NAME}/"       \
    -e "s/xxxISTEPxxx/${BASE_NAME}_heat4/"   \
    -e "s/xxxINPUTxxx/5_heat/"          \
    -e "s/xxxINITCOORxxx/${BASE_NAME}_heat3/"\
    ${SLURM_NAME_FILE} > ${BASE_NAME}_heat4.slurm
ARRAY_SLURM[4]=${BASE_NAME}_heat4.slurm

# heat water (protein free), NPT,
sed -e "s/xxxBASExxx/${BASE_NAME}_heat5/"    \
    -e "s/xxxNAMExxx/${BASE_NAME}/"         \
    -e "s/xxxQUEUExxx/${QUEUE}/"            \
    -e "s/xxxSYSTEMxxx/${BASE_NAME}/"       \
    -e "s/xxxISTEPxxx/${BASE_NAME}_heat5/"   \
    -e "s/xxxINPUTxxx/6_heat/"          \
    -e "s/xxxINITCOORxxx/${BASE_NAME}_heat4/"\
    ${SLURM_NAME_FILE} > ${BASE_NAME}_heat5.slurm
ARRAY_SLURM[5]=${BASE_NAME}_heat5.slurm

# equilibrium baric, NPT
sed -e "s/xxxBASExxx/${BASE_NAME}_equi_den/"  \
    -e "s/xxxNAMExxx/${BASE_NAME}/"       \
    -e "s/xxxQUEUExxx/${QUEUE}/"          \
    -e "s/xxxSYSTEMxxx/${BASE_NAME}/"     \
    -e "s/xxxISTEPxxx/${BASE_NAME}_0ns/"  \
    -e "s/xxxINPUTxxx/7_equi_den/"        \
    -e "s/xxxINITCOORxxx/${BASE_NAME}_heat5/" \
    ${SLURM_NAME_FILE} > ${BASE_NAME}_0ns.slurm
ARRAY_SLURM[6]=${BASE_NAME}_0ns.slurm



# step 1
sed -e "s/xxxBASExxx/${BASE_NAME}_100ns/"  \
    -e "s/xxxNAMExxx/${BASE_NAME}/"       \
    -e "s/xxxQUEUExxx/${QUEUE}/"          \
    -e "s/xxxSYSTEMxxx/${BASE_NAME}/"     \
    -e "s/xxxISTEPxxx/${BASE_NAME}_100ns/"  \
    -e "s/xxxINPUTxxx/8_prod/"        \
    -e "s/xxxINITCOORxxx/${BASE_NAME}_0ns/" \
    ${SLURM_NAME_FILE0} > ${BASE_NAME}_100ns.slurm
ARRAY_SLURM[7]=${BASE_NAME}_100ns.slurm


# production, NPT
for ((i=2; i<$((NUM_STEPS-7)); i++))
do
    INPUT_NUM=$((i*100-100))
    OUTPUT_NUM=$((i*100))
    SYSTEM_NAME=${BASE_NAME}_${OUTPUT_NUM}ns

    sed -e "s/xxxBASExxx/${SYSTEM_NAME}/"     \
        -e "s/xxxNAMExxx/${BASE_NAME}/"       \
        -e "s/xxxQUEUExxx/${QUEUE}/"          \
        -e "s/xxxSYSTEMxxx/${BASE_NAME}/"     \
        -e "s/xxxISTEPxxx/${BASE_NAME}_${OUTPUT_NUM}ns/" \
        -e "s/xxxINPUTxxx/8_prod/"              \
        -e "s/xxxINITCOORxxx/${BASE_NAME}_${INPUT_NUM}ns/"          \
        ${SLURM_NAME_FILE1} > ${SYSTEM_NAME}.slurm
    ARRAY_SLURM[$((i+7))]=${SYSTEM_NAME}.slurm
done


INIT=$RESTART
# first step
ARRAY_EXIT[$INIT]=$(sbatch ${ARRAY_SLURM[$INIT]})
echo "****${ARRAY_EXIT[$INIT]}****"


#ARRAY_EXIT[$INIT]=$(sbatch --dependency=afterok:38309 \
#			   ${ARRAY_SLURM[$INIT]})
#echo "*****${ARRAY_EXIT[$INIT]}"

#ARRAY_EXIT[$INIT]=$(sbatch --dependency=afterok:$(echo ${ARRAY_EXIT[0]} | awk '{print $NF}') \
#			   ${ARRAY_SLURM[$INIT]})
#echo ${ARRAY_EXIT[$INIT]}

# heat, quilibrium, production
# the 2nd, 3rd, ...
for ((i=$((INIT+1)); i<11; i++))
do
    ARRAY_EXIT[$i]=$(sbatch --dependency=afterok:$(echo ${ARRAY_EXIT[$((i-1))]} | awk '{print $NF}') \
                            ${ARRAY_SLURM[$i]} )
    echo "****${ARRAY_EXIT[$i]}****"
done

exit 0
