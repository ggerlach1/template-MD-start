#!/bin/bash

#SBATCH --job-name=xxxBASExxx

#SBATCH --nodes=1
##SBATCH --constraint="TitanV|V100|Turing|Xp|gtx1080Ti"        #"|gtx1080"
#SBATCH --ntasks-per-node=1
##SBATCH --nodelist=n141
#SBATCH --gres=gpu:1
#SBATCH --time=24:00:00
#SBATCH --partition=dept_gpu,camacho_gpu
#SBATCH --mail-type=None
#SBATCH --error=sbatch.%A.stderr
#SBATCH --output=sbatch.%A.stdout

#----PARAMETERS------------------------------------------------------------

#scratch drive folder to work in
JOBID=$(echo $SLURM_JOB_ID| grep -oP '^\d+')
SCRATCH_DIR=/scr/$USER/$SLURM_JOB_NAME/$JOBID

#if the scratch drive doesn't exist (it shouldn't) make it.
if [[ ! -e ${SCRATCH_DIR} ]]; then
    mkdir -p ${SCRATCH_DIR} && echo "scratch drive ${SCRATCH_DIR}"
fi

echo $SLURMD_NODENAME

# change to scratch directory so job runs locally isntead of over the network
# (slows everyone down)
cd ${SCRATCH_DIR}

# copy files to working directory
# IMPORTANT: change NAME_BASE, QUEUE
SYSTEM=xxxNAMExxx
INIT=${SYSTEM}
ISTEP=xxxISTEPxxx
INPUT=xxxINPUTxxx
INITCOOR=xxxINITCOORxxx

rsync -av \
      ${SLURM_SUBMIT_DIR}/mdin/${INPUT}.mdin    \
      ${SLURM_SUBMIT_DIR}/${INIT}.parm7    \
      ${SLURM_SUBMIT_DIR}/rst/${INITCOOR}.rst7 \
      ${SCRATCH_DIR}


#copy files on exit or interrupt
trap clean_up EXIT

#define clean_up
clean_up(){
    echo 'copying files'
    rsync -av ${SCRATCH_DIR}/${INPUT}.mdin ${SLURM_SUBMIT_DIR}/mdin
    rsync -av ${SCRATCH_DIR}/${ISTEP}.mdout ${SLURM_SUBMIT_DIR}/mdout
    rsync -av ${SCRATCH_DIR}/${INIT}.parm7 ${SLURM_SUBMIT_DIR}
    rsync -av ${SCRATCH_DIR}/${INITCOOR}.rst7 ${SLURM_SUBMIT_DIR}/rst
    rsync -av ${SCRATCH_DIR}/${ISTEP}.rst7 ${SLURM_SUBMIT_DIR}/rst
    rsync -av ${SCRATCH_DIR}/${ISTEP}.nc ${SLURM_SUBMIT_DIR}/nc
    rsync -av ${SCRATCH_DIR}/${ISTEP}.mdinfo ${SLURM_SUBMIT_DIR}/mdinfo
    rsync -av ${SCRATCH_DIR}/${ISTEP}.amber.out ${SLURM_SUBMIT_DIR}/mdout
}

#----FOR RUNNING AMBER--------------------------------------------------
module load amber/20

# executable of gpu amber
pmemd.cuda -O  -i ${INPUT}.mdin -o ${ISTEP}.mdout  -p  ${INIT}.parm7  -c ${INITCOOR}.rst7 -r ${ISTEP}.rst7 -x ${ISTEP}.nc -inf ${ISTEP}.mdinfo -ref ${INITCOOR}.rst7 > ${ISTEP}.amber.out

# pmemd.cuda -O                    \   # overwrite the outputfiles
#            -i   ${INPUT}.mdin    \   # input file
#            -o   ${ISTEP}.mdout   \   # output file
#            -p   ${INIT}.parm7    \   # parameter and topology
#            -c   ${INITCOOR}.rst7 \   # inicial coordinates
#            -r   ${ISTEP}.rst7    \   # output restart (coor & velocities)
#            -x   ${ISTEP}.nc      \   # trajectory
#            -inf ${ISTEP}.mdinfo      # MD info status

#--------------------------------------------------------------------------
# Leave this line to tell slurm that the script finished correctly
exit 0
