# Sex pangenome

Variables:

```shell
DIR_BASE=/lizardfs/guarracino/tree_of_life_alignment
RUN_PGGB=/home/guarracino/tools/pggb/pggb-288a395abf4a9f4755375633093f8ac3af59a081
```

## Input preparation

Put all sex chromosomes in the same file:

```shell
cd $DIR_BASE/assemblies

rm primates14.chrXY.fa*
ls *fa.gz | while read f; do
  echo $f
  samtools faidx $f $(grep 'chrX\|chrY' $f.fai | cut -f 1 | sort) >> primates14.chrXY.fa
done

bgzip -@ 48 primates14.chrXY.fa
samtools faidx primates14.chrXY.fa.gz
```

## Pangenome building

Run `pggb`:

```shell
cd $DIR_BASE
mkdir -p $DIR_BASE/graphs/

sbatch -p workers -c 48 --job-name primates-pggb --wrap "hostname; $RUN_PGGB -i $DIR_BASE/assemblies/primates14.chrXY.fa.gz -p 70 -s 20000 -n 14 -o $DIR_BASE/graphs/primates14.chrXY -V chm13v2:# -D /scratch;"
```