# Untangling

Variables:

```shell
DIR_BASE=/lizardfs/guarracino/tree_of_life_alignment
RUN_ODGI=/home/guarracino/tools/odgi/bin/odgi-861fcc33b211e4add6c07bdbb56cc563fe17df25 
```

Untangle with respect to each sex chromosome of each species:

```shell
mkdir -p $DIR_BASE/untangle/
cd $DIR_BASE/untangle/

e=50000
m=1000
p=90
s=20000
DIR_OUTPUT=$DIR_BASE/untangle/primates14.chrXY.p$p.s$s-23226f9ff02a8a9cd575394c8e2ffd6674c451db
mkdir -p $DIR_OUTPUT
CHR=chrX
TARGET=chm13v2#chrX
PATH_UNTANGLE_BED_GZ=$DIR_OUTPUT/$TARGET.e$e.m$m.j0.n28.bed.gz
PATH_GRAPH_OG=$DIR_BASE/graphs/primates14.chrXY.p$p.s$s/primates14.chrXY.fa.gz.*.smooth.final.og
sbatch -p workers -c 14 --job-name untangle-pXY --wrap "hostname; \time -v $RUN_ODGI untangle -i $PATH_GRAPH_OG -r $TARGET -e $e -m $m -j 0 -n 28 -t 14 -P | pigz -c > $PATH_UNTANGLE_BED_GZ"

e=50000
m=1000
for p in 95 90 85 80 70; do
  for s in 50000 20000 10000 5000; do
    p=90
    s=20000
    DIR_OUTPUT=$DIR_BASE/untangle/primates14.chrXY.p$p.s$s
    mkdir -p $DIR_OUTPUT

    for CHR in chrX chrY; do
      grep $CHR $DIR_BASE/assemblies/primates14.chrXY.fa.gz.fai | cut -f 1 | while read TARGET; do
        PATH_UNTANGLE_BED_GZ=$DIR_OUTPUT/$TARGET.e$e.m$m.j0.n28.bed.gz

        if [[ ! -s ${PATH_UNTANGLE_BED_GZ} ]]; then
          PATH_GRAPH_OG=$DIR_BASE/graphs/primates14.chrXY.p$p.s$s/primates14.chrXY.fa.gz.*.smooth.final.og
          echo -p $p -s $s $TARGET
          sbatch -p workers -c 14 --job-name untangle-pXY --wrap "hostname; cd /scratch; $RUN_ODGI stepindex -i $PATH_GRAPH_OG -a 0 -t 14 -P; \time -v $RUN_ODGI untangle -i $PATH_GRAPH_OG -a $PATH_GRAPH_OG.stpidx -r $TARGET -e $e -m $m -j 0 -n 28 -t 14 -P | pigz -c > $PATH_UNTANGLE_BED_GZ"
          #sbatch -p workers -c 14 --job-name untangle-pXY --wrap "hostname; \time -v $RUN_ODGI untangle -i $PATH_GRAPH_OG -r $TARGET -e $e -m $m -j 0 -n 28 -t 14 -P | pigz -c > $PATH_UNTANGLE_BED_GZ"
        fi
      done
    done
  done
done
```

Plots:

```shell
mkdir -p $DIR_BASE/untangle/plots
cd $DIR_BASE/untangle/plots

e=50000
m=1000
for p in 95 90 85 80 70; do
  for s in 50000 20000 10000 5000; do
    DIR_OUTPUT=$DIR_BASE/untangle/primates14.chrXY.p$p.s$s
    mkdir -p $DIR_OUTPUT

    for CHR in chrX chrY; do
      grep $CHR $DIR_BASE/assemblies/primates14.chrXY.fa.gz.fai | cut -f 1 | while read TARGET; do
        echo -p $p -s $s $TARGET
        
        PATH_UNTANGLE_BED_GZ=$DIR_OUTPUT/$TARGET.e$e.m$m.j0.n28.bed.gz
        
        Rscript ../../scripts/plot_untangle.R \
          $PATH_UNTANGLE_BED_GZ \
          0 -1 \
          40 \
          "-p $p -s $s -r $TARGET -e $e -m $m" \
          1 \
          0.0 \
          "primates14.chrXY.p$p.s$s.$TARGET.e$e.m$m.png"
      done
    done
  done
done
```
