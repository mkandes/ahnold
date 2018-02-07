#!/usr/bin/env bash
# ======================================================================
# NAME
#
#     run-gromacs-compute.slurm
#
# DESCRIPTION
#
#     An example Slurm [1] batch job script that is configured to run a
#     multinode, hybrid MPI + OpenMP molecular dynamics simulation with
#     GROMACS [2] on SDSC's Comet supercomputer [3] in its 'compute' 
#     resource partition.
#
# USAGE
#
#     Copy the directory containing the example batch job scripts to 
#     your $HOME directory.
#
#         cp -r /share/apps/examples/gromacs ~/
#
#     Make this copy your working directory.
#     
#         cd ~/gromacs
#
#     Modify the 
#
#         #SBATCH --account=use300
#
#     line below to charge the job's resource request and usage to one 
#     of your active Project IDs. To list the Project IDs your username
#     is currently associated with and authorized to use, run the
#
#         show_accounts
#
#     command. XSEDE users may also use their XSEDE Allocation ID. e.g.,
#
#         #SBATCH --account=TG-STA160003
#
#     Once an appropriate Project ID (or XSEDE Allocation ID) has been
#     provided, you can submit the job to scheduler with the
#
#         sbatch run-gromacs-compute.sh
#
#     command.
#
# REFERENCES
#
#     [1] https://slurm.schedmd.com
#     [2] http://manual.gromacs.org/documentation/2016-latest/index.html
#     [3] http://www.sdsc.edu/support/user_guides/comet.html
#
# LAST UPDATED
#
#     Tuesday, February 6th, 2018
#
# ----------------------------------------------------------------------

#SBATCH --account=use300      # Modify this line to use your Project ID!

#SBATCH --partition=compute   # Request 4 'compute' nodes for up to 1 
#SBATCH --nodes=4             # hour.
#SBATCH --ntasks-per-node=4
#SBATCH --time=01:00:00

#SBATCH --job-name=gromacs-compute
#SBATCH --output=gromacs-compute.o%j.%N

#SBATCH --no-requeue       # Do not requeue job under any circumstances.

declare -xr INPUT_DIR="${PWD}/water-cut1.0_GMX50_bare/3072"
declare -xr INPUT_TARBALL='water_GMX50_bare.tar.gz'
declare -xr INPUT_URL='ftp://ftp.gromacs.org/pub/benchmarks'

module purge                  # Unload Comet's default software modules,
module load gnutools/2.69     # then load the software modules required
module load gnu/4.9.2         # to run GROMACS.
module load intel/2016.3.210
module load intelmpi/2016.3.210
module load gromacs/2016.3
module list
source "${GROMACSHOME}/bin/GMXRC"
printenv

if [[ ! -d "${INPUT_DIR}" ]]; then
  if [[ ! -f "${INPUT_TARBALL}" ]]; then
    wget "${INPUT_URL}/${INPUT_TARBALL}" # Download the input data.
  fi
  tar -xzvf ${INPUT_TARBALL}             # Extract the input data.
fi

# Run the input data through the GROMACS preprocessor.
time -p mpirun -np 1 gmx_mpi grompp \
  -f "${INPUT_DIR}/pme.mdp" \
  -c "${INPUT_DIR}/conf.gro" \
  -p "${INPUT_DIR}/topol.top"

# Run the simulation!
export OMP_NUM_THREADS=6
time -p mpirun gmx_mpi mdrun \
  -nb cpu \
  -pin on \
  -resethway \
  -noconfout \
  -nsteps 8000 \
  -cpo "state.cpt" \
  -e "ener.edr" \
  -g "md.log" \
  -v

# ======================================================================
