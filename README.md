# Template-MD-start
This is how I run MD simulations on Slurm

There are two directories array has the files I use to set up and start 3 MD simualtions from the s ame strucutre 

Normal starts one simualtion for a larger system with dependences

In both cases I add a pdb starting structure and run:
module load amber
pdb4amber -i UPLOAD.pdb -o starting_structure.pdb -y #-y removes hydrogens 

Change the names in tleap.input 

tleap -f tleap.input |& tee tleap.output
bash iones.bash SYSTEM_NAME.pdb 
tleap -f tleap.input |& tee tleap.output

change name and add peptide length in jobs_submission.bash 

bash jobs_submission.bash 
