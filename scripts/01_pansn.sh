#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=thin
#SBATCH --time=06:00:00

module load 2022
module load HTSlib/1.15.1-GCC-11.3.0 # for bgzip

DIR_BASE=/home/aguarracino/tree_of_life_alignment
FASTIX=~/tools/fastix/target/release/fastix-331c1159ea16625ee79d1a82522e800c99206834

cd $DIR_BASE/assemblies/vgp
ls xxx_*.zip | while read f; do
	SUFFIX=$(echo $f | cut -f 2 -d '_' | cut -f 1 -d '.');
	echo $SUFFIX;

	unzip $f;
	rm $f README.md

	# Trim headers and add prefixes
	ls ncbi_dataset/data/*/*.fna | while read g; do
	  NAME=$(basename $g)
	  PREFIX=$(echo $NAME | sed 's/_genomic.fna//g');
	  echo $PREFIX

	  # `cut -f 1` to trim the headers
	  $FASTIX -p "${PREFIX}#1#" <(cat $g | cut -f 1) | bgzip -@ 64 -l 9 -c > $PREFIX.fa.gz;
	  rm $g
	done

	rm ncbi_dataset -rf
done
