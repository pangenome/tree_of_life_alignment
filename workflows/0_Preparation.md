# Preparation

Variables:

```shell
DIR_BASE=/lizardfs/guarracino/tree_of_life_alignment
RUN_FASTIX=/home/guarracino/tools/fastix/target/release/fastix-331c1159ea16625ee79d1a82522e800c99206834
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
git checkout f483f9ed5a514a531fbd64833d49cd931ea59943
git submodule update --init --recursive
cmake -H. -Bbuild && cmake --build build -- -j 48
mv bin/odgi bin/odgi-f483f9ed5a514a531fbd64833d49cd931ea59943
cd ..

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

# T2T.primates_assemblies.urls.txt refers to assemblies in https://genomeark.github.io/t2t-draft-assembly/, but took from https://genomeark.s3.amazonaws.com/index.html?prefix=species/ (11 January 2023)
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
