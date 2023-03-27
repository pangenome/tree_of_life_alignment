# Preparation

Variables:

```shell
DIR_BASE=/lizardfs/guarracino/tree_of_life_alignment
RUN_FASTIX=/home/guarracino/tools/fastix/target/release/fastix-331c1159ea16625ee79d1a82522e800c99206834
RUN_WFMASH=/home/guarracino/tools/wfmash/build/bin/wfmash-191afe12042962d3c0d5c62936528561753b3da0
```

## Tools

```shell
mkdir -p ~/tools/
cd ~/tools/

git clone --recursive https://github.com/waveygang/wfmash
cd wfmash
git checkout master
git pull
git checkout cb0ce952a9bec3f2c8c78b98679375e5275e05db
git submodule update --init --recursive
cmake -H. -DCMAKE_BUILD_TYPE=Release -Bbuild && cmake --build build -- -j $(nproc)
mv build/bin/wfmash build/bin/wfmash-cb0ce952a9bec3f2c8c78b98679375e5275e05db
cd ..

clone --recursive https://github.com/ekg/seqwish
cd seqwish
git checkout master
git pull
git checkout f362f6f5ea89dbb6a0072a8b8ba215e663301d33
git submodule update --init --recursive
cmake -H. -DCMAKE_BUILD_TYPE=Release -DEXTRA_FLAGS='-march=native' -Bbuild && cmake --build build -- -j $(nproc)
mv bin/seqwish bin/seqwish-f362f6f5ea89dbb6a0072a8b8ba215e663301d33
cd ..

git clone --recursive https://github.com/pangenome/smoothxg
cd smoothxg
git checkout master
git pull
git checkout c12f2d2685e566fe04868fd4749e544eb5a6bc37
git submodule update --init --recursive
cmake -H. -DCMAKE_BUILD_TYPE=Release -Bbuild && cmake --build build -- -j $(nproc)
mv bin/smoothxg bin/smoothxg-c12f2d2685e566fe04868fd4749e544eb5a6bc37
cd ..

git clone --recursive https://github.com/pangenome/odgi.git
cd odgi
git checkout master
git pull
git checkout fa95f780bbd2602f4b18a60d6b99f345ca6ec387
git submodule update --init --recursive
cmake -H. -Bbuild && cmake --build build -- -j 48
mv bin/odgi bin/odgi-fa95f780bbd2602f4b18a60d6b99f345ca6ec387
cd ..

# For:
# - odgi stepindex -i graph.og -a 0
# - odgi untangle verbose log
# - odgi untangle speed up
git pull
git checkout 2c78159a1b4bf122493075e436ea9c53033f430f
git submodule update --init --recursive
cmake -H. -Bbuild && cmake --build build -- -j 48
mv bin/odgi bin/odgi-2c78159a1b4bf122493075e436ea9c53033f430f


git clone --recursive https://github.com/pangenome/pggb.git
cd pggb
git checkout master
git pull
git checkout 288a395abf4a9f4755375633093f8ac3af59a081
sed 's,"$fmt" wfmash,"$fmt" ~/tools/wfmash/build/bin/wfmash-cb0ce952a9bec3f2c8c78b98679375e5275e05db,g' pggb -i
sed 's,"$fmt" seqwish,"$fmt" ~/tools/seqwish/bin/seqwish-f362f6f5ea89dbb6a0072a8b8ba215e663301d33,g' pggb -i
sed 's,"$fmt" smoothxg,"$fmt" ~/tools/smoothxg/bin/smoothxg-c12f2d2685e566fe04868fd4749e544eb5a6bc37,g' pggb -i
sed 's,"$fmt" odgi,"$fmt" ~/tools/odgi/bin/odgi-f483f9ed5a514a531fbd64833d49cd931ea59943,g' pggb -i
mv pggb pggb-288a395abf4a9f4755375633093f8ac3af59a081
cd ..

git clone --recursive https://github.com/ekg/fastix.git
cd fastix
git checkout 331c1159ea16625ee79d1a82522e800c99206834
cargo build --release
mv target/release/fastix target/release/fastix-331c1159ea16625ee79d1a82522e800c99206834
cd ..
```


## Assemblies

```shell
mkdir -p $DIR_BASE/assemblies

# T2T.primates_assemblies.urls.txt refers to assemblies in https://genomeark.github.io/t2t-draft-assembly/, but they were taken from https://genomeark.s3.amazonaws.com/index.html?prefix=species/ (11 January 2023)
# https://docs.google.com/spreadsheets/d/1bWZ1SjCn6I34QMqXeg-zwzK7D-EDizw1GQCkQ_Ily6E/edit#gid=0
sbatch -p workers -c 48 --wrap "cd $DIR_BASE/assemblies; (echo https://hgdownload.soe.ucsc.edu/goldenPath/hs1/bigZips/hs1.fa.gz; cat ../data/T2T.primates_assemblies.urls.txt) | parallel -j 4 'wget -q {} && echo got {}'"
mv hs1.fa.gz chm13v2.fasta.gz

# Apply PanSN-spec
ls *fasta.gz | while read f; do
  echo $f
  prefix=$(echo $f | cut -f 1 -d '.')

  $RUN_FASTIX -p "${prefix}#" <(zcat $f ) | bgzip -c -@48 > $prefix.fa.gz
  samtools faidx $prefix.fa.gz
done
```

### Chromosome partitioning

Map contigs against the references:

```shell
mkdir -p $DIR_BASE/partitioning
cd $DIR_BASE/partitioning

REFS=/lizardfs/guarracino/chromosome_communities/assemblies/chm13v2+grch38masked.fa.gz

(ls $DIR_BASE/assemblies/*.fa.gz | grep 'chm13\|primates' -v) | while read FASTA; do
  SPECIES=$(basename $FASTA .fa.gz | cut -f 1,2 -d '.');
  echo $SPECIES
  
  PAF=$DIR_BASE/partitioning/$SPECIES.vs.ref.p90.paf
  sbatch -p headnode -c 20 --wrap "$RUN_WFMASH -t 20 -m -N -s 50k -l 150k -p 90 -H 0.001 $REFS $FASTA > $PAF"
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
    sbatch -p headnode -c 20 --wrap "$RUN_WFMASH -t 20 -m -s 50k -l 150k -p 90 -H 0.001 $REFS $UNALIGNED.fa > $UNALIGNED.split.vs.ref.p90.paf"
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
( seq 6 7 ) | while read i; do cat *paf | grep -P -e "[chm13|grch38]#chr$i\t" | cut -f 1 | sort | uniq | awk '{print($0"$")}' > chr$i.contigs.txt; done

( seq 6 7  ) | while read i; do
    echo chr$i

    rm chr$i.fa*
    (ls $DIR_BASE/assemblies/*.fa.gz | grep 'chm13\|primates' -v) | while read FASTA; do
      echo $FASTA

      samtools faidx $FASTA $(cut -f 1 $FASTA.fai | grep -f chr$i.contigs.txt) >> chr$i.fa
    done
done

REFS=/lizardfs/guarracino/chromosome_communities/assemblies/chm13v2+grch38masked.fa.gz

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
```
