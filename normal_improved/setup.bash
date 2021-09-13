#!/bin/bash

module load amber/20 

BASE_NAME=$1 
ADD_NHE=0 #1 to add NHE 0 to not do that 
FINAL_RESIDUE=ASP #CHANGE THIS IF USING ABOVE 
SEQ=$(pdb2fasta $BASE_NAME.pdb)
PROTEIN_LENGTH=${#SEQ} 
RESTART=0  
NUM_STEPS=13 ## with 50 PROD_SIZE this gives 300ns of production       
PROD_SIZE=50
SLURM_NAME_FILE=run_system.slurm

##reunumber and remove hydrogens, will not work if the peptide was built in pymol using a for loop, need to remove hydrogens there
pdb4amber -i $BASE_NAME.pdb -o starting_structure.pdb -y

#generate tleap input file 
sed -i "s/xxxBASExxx/${BASE_NAME}/g" tleap.input

## run tleap 1st time, generates info into tleap.output to use in iones.bash
tleap -f tleap.input |& tee tleap.output

if [ $ADD_NHE == 1 ];
then
echo $ADD_NHE
tac <${BASE_NAME}_tleap.pdb | sed '3s/OXT/N  /' | tac >middle.pdb
tac <middle.pdb | sed "3s/${FINAL_RESIDUE}/NHE/g" | tac >${BASE_NAME}_NHE.pdb
sed -i "s/starting_structure/${BASE_NAME}_NHE/g" tleap.input
bash iones.bash ${BASE_NAME}_NHE.pdb
else
bash iones.bash ${BASE_NAME}.pdb
fi
tleap -f tleap.input |& tee tleap.output
	

# write number of residues into the .mdin files
sed "s/xxxPROTEIN_LENGTHxxx/${PROTEIN_LENGTH}/g" mdin_var/1_mini.mdin > mdin/1_mini.mdin
sed "s/xxxPROTEIN_LENGTHxxx/${PROTEIN_LENGTH}/g" mdin_var/2_heat.mdin > mdin/2_heat.mdin
sed "s/xxxPROTEIN_LENGTHxxx/${PROTEIN_LENGTH}/g" mdin_var/3_heat.mdin > mdin/3_heat.mdin
sed "s/xxxPROTEIN_LENGTHxxx/${PROTEIN_LENGTH}/g" mdin_var/4_heat.mdin > mdin/4_heat.mdin
sed "s/xxxPROTEIN_LENGTHxxx/${PROTEIN_LENGTH}/g" mdin_var/5_heat.mdin > mdin/5_heat.mdin

sed -i "s/xxxBASExxx/${BASE_NAME}/g" ${SLURM_NAME_FILE}
sed -i "s/xxxNUM_STEPSxxx/${NUM_STEPS}/g" ${SLURM_NAME_FILE}
sed -i "s/xxxPROD_SIZExxx/${PROD_SIZE}/g" ${SLURM_NAME_FILE}

exit 0
