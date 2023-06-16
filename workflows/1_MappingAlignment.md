# Mapping and Alignment

## Mapping

On `snellius`:

```shell
#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=128
#SBATCH --partition=fat
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

mkdir -p $DIR_BASE/alignments

\time -v wfmash $DIR_BASE/assemblies/primates13.fa.gz -s 10k -l 50k -p 90 -n 13 -Y '#' --approx-map -t 128 > $DIR_BASE/alignments/primates13.s10k.l50k.p90.n13.Y.mappings.paf
```

```shell
sbatch mapping.sh
```

Evaluation:

```shell
PAF=primates14.xxx.mappings.paf

cat $PAF | awk -v OFS='\t' '{print $1, $3, $4, "", "", $5}'  > intervals.bed
cat $PAF | awk -v OFS='\t' '{print $6, $8, $9, "", "", "+"}' >> intervals.bed

cat $PAF | awk -v OFS='\t' '{print $1, "0", $2}' | sort | uniq > sequences.bed
cat $PAF | awk -v OFS='\t' '{print $6, "0", $7}' | sort | uniq >> sequences.bed

cat sequences.bed | while read name start end; do
  echo $name;
  
  covered=$(bedtools subtract \
    -a <(echo $name $start $end | tr ' ' '\t') \
    -b <(grep "^$name" intervals.bed) | awk '{sum += $3 - $2} END {print sum}')
  
  ratio=$(echo "scale=4; $covered / $end" | bc)
  echo $covered $end $ratio
done
```