#!/bin/bash

module load amber/18-cluster 

BASE_NAME=$1 #CHANGE THIS 
ADD_NHE=0 #1 to add NHE 0 to not do that 
FINAL_RESIDUE=ASP #CHANGE THIS 
SEQ=$(pdb2fasta $BASE_NAME.pdb)
PROTEIN_LENGTH=${#SEQ} #CHANGE THIS 

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
	
	
sed -i "s/xxxBASE_FROMxxx/${BASE_NAME}/g" jobs_submission_array.bash
sed -i "s/xxxLENGTHxxx/${PROTEIN_LENGTH}/g" jobs_submission_array.bash
