#!/bin/bash

#SBATCH --job-name=jn

#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
##SBATCH --nodelist=n141
#SBATCH --time=24:00:00
#SBATCH --partition=dept_cpu
#SBATCH --cpus-per-task=1
#SBATCH --mail-type=None
#SBATCH --exclude=n017,n004,n003
#SBATCH --error=sbatch_array.stderr
#SBATCH --output=sbatch_array.stdout
## get tunneling info
XDG_RUNTIME_DIR=""
ipnport=$(shuf -i8000-9999 -n1)
ipnip=$(hostname -i)
## print tunneling instructions to jupyter-log-{jobid}.txt
echo -e "
Copy/Paste this in your local terminal to ssh tunnel with remote
-----------------------------------------------------------------
ssh -N -L $ipnport:$ipnip:$ipnport gjg21@cluster.csb.pitt.edu
-----------------------------------------------------------------
Then open a browser on your local machine to the following address
------------------------------------------------------------------
localhost:$ipnport  (prefix w/ https:// if using password)
------------------------------------------------------------------
"
## start an ipcluster instance and launch jupyter server
module load anaconda/3-cluster
jupyter-notebook --NotebookApp.iopub_data_rate_limit=100000000000000 \
   --port=$ipnport --ip=$ipnip --NotebookApp.password='' --NotebookApp.token='' --no-browser

