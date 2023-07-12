#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --partition=thin
#SBATCH --time=00:30:00

hostname

module load 2022
module load parallel/20220722-GCCcore-11.3.0 # for parallel
module load HTSlib/1.15.1-GCC-11.3.0 # for bgzip
module load SAMtools/1.15.1-GCC-11.3.0 # for samtools

DIR_BASE=/home/aguarracino/tree_of_life_alignment
RUN_FASTIX=~/tools/fastix/target/release/fastix-331c1159ea16625ee79d1a82522e800c99206834

cd $DIR_BASE/assemblies

(echo https://hgdownload.soe.ucsc.edu/goldenPath/hs1/bigZips/hs1.fa.gz; cat $DIR_BASE/data/T2T.primates_assemblies.urls.txt) | parallel -j 8 'wget -q {} && echo got {}'
mv hs1.fa.gz chm13v2.fasta.gz

# Apply PanSN-spec
ls *fasta.gz | while read f; do
  echo $f
  prefix=$(echo $f | cut -f 1 -d '.')

  $RUN_FASTIX -p "${prefix}#" <(zcat $f ) | sed -e 's/haplotype//g' -e 's/-/#/g' -e 's/unassigned/U/g' | bgzip -c -@ 8 > $prefix.fa.gz
  samtools faidx $prefix.fa.gz
done
