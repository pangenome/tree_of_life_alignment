#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=128
#SBATCH --partition=thin
#SBATCH --time=48:00:00

hostname

module load 2022
module load Miniconda3/4.12.0

# Miniconda/Anaconda path. Modify it according to your installation path
CONDA_PATH="/sw/arch/RHEL8/EB_production/2022/software/Miniconda3/4.12.0"

# Source the conda script
source "${CONDA_PATH}/etc/profile.d/conda.sh"
conda activate ~/tools/conda

DIR_BASE=/home/aguarracino/tree_of_life_alignment

PATH_TARGET_SEQUENCE_FASTA="$1"
PATH_QUERY_SEQUENCES_FASTA="$2"
NAME_TARGET=$(basename $PATH_TARGET_SEQUENCE_FASTA)
NAME_QUERIES=$(basename $PATH_QUERY_SEQUENCES_FASTA)

\time -v wfmash $PATH_TARGET_SEQUENCE_FASTA $PATH_QUERY_SEQUENCES_FASTA -p 70 -s 20k -n 1 --approx-map -t 128 | pigz -9 > $DIR_BASE/mappings/$NAME_QUERIES.vs.$NAME_TARGET.p70.s20k.mappings.paf.gz

conda deactivate
