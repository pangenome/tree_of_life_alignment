#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=thin
#SBATCH --time=06:00:00

module load 2022
module load HTSlib/1.15.1-GCC-11.3.0 # for bgzip
module load SAMtools/1.15.1-GCC-11.3.0 # for samtools

DIR_BASE=/home/aguarracino/tree_of_life_alignment

TEMP_DIR=$(mktemp -d -p /scratch-shared)

echo $TEMP_DIR/vgp290.fasta.gz
zcat $DIR_BASE/assemblies/vgp/*fa.gz | bgzip -@ 64 > $TEMP_DIR/vgp290.fasta.gz
samtools faidx $TEMP_DIR/vgp290.fasta.gz
