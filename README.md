# Template-MD-start
This is how I run MD simulations on Slurm. There are two directories:
* array- the files I use to set up and start 3 MD simualtions of the same starting structure 
* Normal- starts one simualtion for a larger system with simulations broken into 10ns dependencies

In both cases I add a pdb starting structure and run:
1. module load amber
1. pdb4amber -i UPLOAD.pdb -o starting_structure.pdb -y #-y removes hydrogens 
	1. Change the names in tleap.input 
1. tleap -f tleap.input |& tee tleap.output
1. bash iones.bash SYSTEM_NAME.pdb 
1. tleap -f tleap.input |& tee tleap.output
	1.change name and add peptide length in jobs_submission.bash 

1. bash jobs_submission.bash 
