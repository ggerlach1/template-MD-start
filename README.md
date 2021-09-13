# Template-MD-start
This is how I run MD simulations on Slurm. There are two directories:
* array- the files I use to set up and start 3 MD simualtions of the same starting structure 
* Normal- starts one simualtion for a larger system with simulations broken into 10ns dependencies
* Normal Improved - has more changable variables and instructions for running simulations with ligands though more needs to be changed in the tleap.input file 

Generally:
1. Create a directory with your starting structure
2. copy the whole directory of one of the above places 
3. Make changes in `tleap.input` if running with ligand, or other not just protein 
4. run `bash setup.bash NAME` 
5. run `sb run_system.slurm`

Improvements to the array one are still in the works, but the single one is nice and I can easily change the number of nanoseconds in a section.
