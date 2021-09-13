### Instructions

These vary with the patching on the ends of the simulations. No patch or only the N-terminal patch are very straight forward having C-terminal patching I do not yet have a good automated method.

In all cases ensure the starting structure does not have any hydrogen atoms, is in the directory you want to run simulations from, and is named something that you are fine with the jobs being named based on.

#### Option 1 - no patching, no special residues  
1. Copy everything in this directory to your working directory 
1. Run the setup script as `bash setup.bash NAME` where NAME is what your PDB file is called without the `.pdb`
1. Run the job submission script `bash jobs_submission_array.bash` this will auto submit minimization-> equilibration as slurm dependencies. 
1. Once these are completed you can (a) submit the production arrays (2) use the last frame of the equilibration as a new starting structure. This is useful when starting from a linear structure. 

#### Option 2 - N-terminal patching, no special residues 
1. Copy everything in this directory to your working directory
1. Open `setup.bash` input the name of the final amino acid  
1. Run the setup script as `bash setup.bash NAME` where NAME is what your PDB file is called without the `.pdb`. 
1. Open the `_tleap.pdb` file, make sure there has been an additional residue added and it has N, H1,H2
1. Continue as in option 1 

#### Option 3 - N and C-terminal patching, no special residues  
1. Complete steps 1-4 as above.
1. Open the `_NHE.pdb` file and (1) change the N of the first amino acid to a C and rename the residue `ACE` (2) remove all hydrogen atoms bonded to this atom (usually there are 3).
1. Run `tleap -f tleap |& tee tleap.output`
2. Run `bash iones.bash _tleap.pdb`
3. Open `tleap.input` change the number after the second set of add ions lines to the number produced by `iones.bash` 
2. Run `bash iones.bash _tleap.pdb`
1. Run the job submission script `bash jobs_submission_array.bash` this will auto submit minimization-> equilibration as slurm dependencies. 
1. Once these are completed you can (a) submit the production arrays (2) use the last frame of the equilibration as a new starting structure. This is useful when starting from a linear structure. 

#### Option 4 - Add non-natural residues
1. Obtain the necessary forcefield parameters (this is usually 2 files, there are a couple of websites which have some options)
1. Open `tleap.input` uncomment or add additional parameters 
2. Open the pdb starting structure and change the name of the amino acid you have modified and the atom names
1. Continue as the other options for your system 
