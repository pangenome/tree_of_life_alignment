#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=thin
#SBATCH --time=48:00:00

hostname

DIR_BASE=/home/aguarracino/tree_of_life_alignment
RUN_DATASETS=~/tools/ncbi_datasets/datasets

mkdir -p $DIR_BASE/assemblies/vgp
cd $DIR_BASE/assemblies/vgp

split -n l/20 $DIR_BASE/data/VGP.assemblies.2023.07.04.txt VGP.assemblies.2023.07.04_

ls VGP.assemblies.2023.07.04_* | while read f; do
  SUFFIX=$(echo $f | cut -f 2 -d '_');
  echo $SUFFIX;

  $RUN_DATASETS download genome accession --inputfile $f --filename xxx_${SUFFIX}.zip
done

rm VGP.assemblies.2023.07.04_*
