## Assemblies

On `octopus`:

```shell
mkdir -p $DIR_BASE/assemblies

# T2T.primates_assemblies.urls.txt refers to assemblies in https://genomeark.github.io/t2t-draft-assembly/, but they were taken from https://genomeark.s3.amazonaws.com/index.html?prefix=species/ (11 January 2023)
# https://docs.google.com/spreadsheets/d/1bWZ1SjCn6I34QMqXeg-zwzK7D-EDizw1GQCkQ_Ily6E/edit#gid=0
sbatch -c 1 --wrap "cd $DIR_BASE/assemblies; (echo https://hgdownload.soe.ucsc.edu/goldenPath/hs1/bigZips/hs1.fa.gz; cat ../data/T2T.primates_assemblies.urls.txt) | parallel -j 8 'wget -q {} && echo got {}'"
mv hs1.fa.gz chm13v2.fasta.gz

# Apply PanSN-spec
ls *fasta.gz | while read f; do
  echo $f
  prefix=$(echo $f | cut -f 1 -d '.')

  $RUN_FASTIX -p "${prefix}#" <(zcat $f ) | sed -e 's/haplotype//g' -e 's/-/#/g' -e 's/unassigned/U/g' | bgzip -c -@ 48 > $prefix.fa.gz
  samtools faidx $prefix.fa.gz
done
```

On `snellius`:

```shell
#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --partition=thin
#SBATCH --time=01:00:00

hostname

module load 2022
module load parallel/20220722-GCCcore-11.3.0
module load HTSlib/1.15.1-GCC-11.3.0 # for bgzip
module load SAMtools/1.15.1-GCC-11.3.0

DIR_BASE=/home/aguarracino/tree_of_life_alignment
RUN_FASTIX=~/tools/fastix/target/release/fastix-331c1159ea16625ee79d1a82522e800c99206834

cd $DIR_BASE/assemblies

(echo https://hgdownload.soe.ucsc.edu/goldenPath/hs1/bigZips/hs1.fa.gz; cat $DIR_BASE/data/T2T.primates_assemblies.urls.txt) | parallel -j 8 'wget -q {} && echo got {}'

# Apply PanSN-spec
ls *fasta.gz | while read f; do
  echo $f
  prefix=$(echo $f | cut -f 1 -d '.')

  $RUN_FASTIX -p "${prefix}#" <(zcat $f ) | sed -e 's/haplotype//g' -e 's/-/#/g' -e 's/unassigned/U/g' | bgzip -c -@ 8 > $prefix.fa.gz
  samtools faidx $prefix.fa.gz
done

mv hs1.fa.gz chm13v2.fasta.gz
$RUN_FASTIX -p "chm13v2#1#" <(zcat chm13v2.fasta.gz ) | bgzip -c -@ 8 > chm13v2.fa.gz
samtools faidx chm13v2.fa.gz

rm *fasta.gz

zcat *fa.gz | bgzip -c -@ 8 > primates13.fasta.gz
mv primates13.fasta.gz primates13.fa.gz
samtools faidx primates13.fa.gz
```

```shell
sbatch download.sh
```

### Chromosome partitioning

Map contigs against the references:

```shell
mkdir -p $DIR_BASE/partitioning
cd $DIR_BASE/partitioning

REFS=/lizardfs/guarracino/chromosome_communities/assemblies/chm13v2+grch38masked.fa.gz

ls $DIR_BASE/assemblies/*.fa.gz | while read FASTA; do
  SPECIES=$(basename $FASTA .fa.gz | cut -f 1,2 -d '.');
  echo $SPECIES
  
  PAF=$DIR_BASE/partitioning/$SPECIES.vs.ref.p90.paf
  sbatch -p workers -c 20 --wrap "$RUN_WFMASH -t 20 -m -N -s 50k -l 150k -p 90 -H 0.001 $REFS $FASTA > $PAF"
done
```

Collect unmapped contigs and remap them in split mode:

```shell
REFS=/lizardfs/guarracino/chromosome_communities/assemblies/chm13v2+grch38masked.fa.gz

(ls $DIR_BASE/assemblies/*.fa.gz | grep 'chm13\|primates' -v) | while read FASTA; do
  SPECIES=$(basename $FASTA .fa.gz | cut -f 1,2 -d '.');
  echo $SPECIES
  
  UNALIGNED=$DIR_BASE/partitioning/$SPECIES.unaligned
  
  PAF=$DIR_BASE/partitioning/$SPECIES.vs.ref.p90.paf
  comm -23 <(cut -f 1 $FASTA.fai | sort) <(cut -f 1 $PAF | sort) > $UNALIGNED.txt
  if [[ $(wc -l $UNALIGNED.txt | cut -f 1 -d ' ' ) != 0 ]];
  then 
    samtools faidx $FASTA $(tr '\n' ' ' < $UNALIGNED.txt) > $UNALIGNED.fa
    samtools faidx $UNALIGNED.fa
    sbatch -p workers -c 20 --wrap "$RUN_WFMASH -t 20 -m -s 50k -l 150k -p 90 -H 0.001 $REFS $UNALIGNED.fa > $UNALIGNED.split.vs.ref.p90.paf"
  fi
done
```

Collect our best mapping for each of our attempted split rescues:

```shell
ls *.unaligned.split.vs.ref.p90.paf | while read PAF; do
  cat $PAF | awk -v OFS='\t' '{ print $1,$11,$0 }' | sort -n -r -k 1,2 | \
    awk -v OFS='\t' '$1 != last { print($3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15); last = $1; }'
done > rescues.paf
```

Collect partitioned contigs:

```shell
# Take only haplotype-assigned contigs
( seq 6 7 8 ) | while read i; do cat *paf | grep -P -e "[chm13|grch38]#chr$i\t" | grep '#U#' -v | cut -f 1 | sort | uniq | awk '{print($0"$")}' > chr$i.contigs.txt; done

( seq 6 7 8  ) | while read i; do
    echo chr$i

    rm chr$i.fa*
    (ls $DIR_BASE/assemblies/*.fa.gz | grep 'chm13\|primates' -v) | while read FASTA; do
      echo $FASTA

      samtools faidx $FASTA $(cut -f 1 $FASTA.fai | grep -f chr$i.contigs.txt) >> chr$i.fa
    done
done

REFS=/lizardfs/guarracino/chromosome_communities/assemblies/chm13v2+grch38masked.fa.gz

# Only chr 6 and 7 are available from primates4
( seq 6 7 ) | while read i; do
    echo chr$i
    # 4 haplotypes (from primates4) + 12 haplotypes (6 diploid assemblies) + 1 haplotype (chm13#chr$i)
    cat \
      chr$i.fa \
      <(zcat /lizardfs/guarracino/pggb-paper/assemblies/primates4.chr$i.fa.gz) \
      <(samtools faidx $REFS $(grep chm13#chr$i $REFS.fai | cut -f 1)) \
      > primates17.chr$i.fa
    bgzip -@ 48 primates17.chr$i.fa
    samtools faidx primates17.chr$i.fa.gz
done

( seq 8 8 ) | while read i; do
    echo chr$i
    # 12 haplotypes (6 diploid assemblies) + 2 haplotype (chm13#chr$i and grch38#chr$i)
    cat \
      chr$i.fa \
      <(samtools faidx $REFS $(grep hr$i $REFS.fai | cut -f 1)) \
      > primates14.chr$i.fa
    bgzip -@ 48 primates14.chr$i.fa
    samtools faidx primates14.chr$i.fa.gz
done
```
