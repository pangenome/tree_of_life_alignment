# Sex pangenome

Variables:

```shell
DIR_BASE=/lizardfs/guarracino/tree_of_life_alignment
RUN_PGGB=/home/guarracino/tools/pggb/pggb-288a395abf4a9f4755375633093f8ac3af59a081
RUN_ODGI=/home/guarracino/tools/odgi/bin/odgi-f483f9ed5a514a531fbd64833d49cd931ea59943 
```

## Input preparation

Put all sex chromosomes in the same file:

```shell
cd $DIR_BASE/assemblies

rm primates14.chrXY.fa*
ls *fa.gz | grep primates -v | while read f; do
  echo $f
  samtools faidx $f $(grep 'chrX\|chrY' $f.fai | cut -f 1 | sort) >> primates14.chrXY.fa
done

bgzip -@ 48 primates14.chrXY.fa
samtools faidx primates14.chrXY.fa.gz


rm primates7.chrY.fa*
ls *fa.gz | grep primates -v | while read f; do
  echo $f
  samtools faidx $f $(grep 'chrY' $f.fai | cut -f 1 | sort) >> primates7.chrY.fa
done

bgzip -@ 48 primates7.chrY.fa
samtools faidx primates7.chrY.fa.gz
```

## Pangenome building

Run `pggb`:

```shell
cd $DIR_BASE
mkdir -p $DIR_BASE/graphs/

# ToDo:
# 1) when 122181 is finished, rename graph folder from s5k to s5000
for p in 95 90 85 80 70; do
  for s in 50000 20000 10000 5000; do
    if [ ! -d "$DIR_BASE/graphs/primates14.chrXY.p$p.s$s" ] 
    then
      echo $p $s
      sbatch -p workers -x octopus03,octopus11 -c 48 --job-name $p-$s-pXY --wrap "hostname; $RUN_PGGB -i $DIR_BASE/assemblies/primates14.chrXY.fa.gz -p $p -s $s -n 14 -o $DIR_BASE/graphs/primates14.chrXY.p$p.s$s -V chm13v2:# -D /scratch;"
    fi
  done
done

sbatch -p workers -c 48 --job-name primY-pggb --wrap "hostname; $RUN_PGGB -i $DIR_BASE/assemblies/primates7.chrY.fa.gz -p 70 -s 5000 -n 7 -o $DIR_BASE/graphs/primates7.chrY.p70.s5k -V chm13v2:# -D /scratch;"
```

```shell
echo chm13v2#chrY > ref_path.txt
sbatch -p workers -c 48 --job-name primXY-pggb --wrap "hostname; \time -v $RUN_ODGI sort -P -p Ygs --temp-dir /scratch -t 48 -i /lizardfs/guarracino/tree_of_life_alignment/graphs/primates7.chrY.p70.s5k/primates7.chrY.fa.gz.0b00573.417fcdf.3678c97.smooth.final.og -o /lizardfs/guarracino/tree_of_life_alignment/graphs/primates7.chrY.p70.s5k/primates7.chrY.fa.gz.0b00573.417fcdf.3678c97.smooth.final.sort_by_ref.og -H /lizardfs/guarracino/tree_of_life_alignment/ref_path.txt"

$RUN_ODGI viz -i /lizardfs/guarracino/tree_of_life_alignment/graphs/primates7.chrY.p70.s5k/primates7.chrY.fa.gz.0b00573.417fcdf.3678c97.smooth.final.sort_by_ref.og -o /lizardfs/guarracino/tree_of_life_alignment/graphs/primates7.chrY.p70.s5k/primates7.chrY.fa.gz.0b00573.417fcdf.3678c97.smooth.final.sort_by_ref.og.viz_multiqc.png -x 1500 -y 500 -a 10 -I Consensus_
$RUN_ODGI viz -i /lizardfs/guarracino/tree_of_life_alignment/graphs/primates7.chrY.p70.s5k/primates7.chrY.fa.gz.0b00573.417fcdf.3678c97.smooth.final.sort_by_ref.og -o /lizardfs/guarracino/tree_of_life_alignment/graphs/primates7.chrY.p70.s5k/primates7.chrY.fa.gz.0b00573.417fcdf.3678c97.smooth.final.sort_by_ref.og.viz_pos_multiqc.png -x 1500 -y 500 -a 10 -u -d -I Consensus_
$RUN_ODGI viz -i /lizardfs/guarracino/tree_of_life_alignment/graphs/primates7.chrY.p70.s5k/primates7.chrY.fa.gz.0b00573.417fcdf.3678c97.smooth.final.sort_by_ref.og -o /lizardfs/guarracino/tree_of_life_alignment/graphs/primates7.chrY.p70.s5k/primates7.chrY.fa.gz.0b00573.417fcdf.3678c97.smooth.final.sort_by_ref.og.viz_depth_multiqc.png -x 1500 -y 500 -a 10 -m -I Consensus_
$RUN_ODGI viz -i /lizardfs/guarracino/tree_of_life_alignment/graphs/primates7.chrY.p70.s5k/primates7.chrY.fa.gz.0b00573.417fcdf.3678c97.smooth.final.sort_by_ref.og -o /lizardfs/guarracino/tree_of_life_alignment/graphs/primates7.chrY.p70.s5k/primates7.chrY.fa.gz.0b00573.417fcdf.3678c97.smooth.final.sort_by_ref.og.viz_inv_multiqc.png -x 1500 -y 500 -a 10 -z -I Consensus_
$RUN_ODGI viz -i /lizardfs/guarracino/tree_of_life_alignment/graphs/primates7.chrY.p70.s5k/primates7.chrY.fa.gz.0b00573.417fcdf.3678c97.smooth.final.sort_by_ref.og -o /lizardfs/guarracino/tree_of_life_alignment/graphs/primates7.chrY.p70.s5k/primates7.chrY.fa.gz.0b00573.417fcdf.3678c97.smooth.final.sort_by_ref.og.viz_O_multiqc.png -x 1500 -y 500 -a 10 -O -I Consensus_

```
