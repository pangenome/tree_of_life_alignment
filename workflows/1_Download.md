# Download

Prepare the tool:

```shell
mkdir -p ~/tools/ncbi_datasets
cd ~/tools/ncbi_datasets

curl -o datasets 'https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/v2/linux-amd64/datasets'
curl -o dataformat 'https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/v2/linux-amd64/dataformat'
chmod +x datasets dataformat
```

Prepare the accessions:

```shell
awk -v FS='\t' '$14 != ""' VGP\ Ordinal\ List\ -\ VGP\ Phase\ 1+.tsv | cut -f 14 | grep GCA | sed '1d' > VGP.assemblies.2023.07.04.txt
```

Download the data:

```shell
sbatch 00_download2.sh
```

PanSN:

```shell
sbatch 01_pansn.sh
```

Merge all assemblies, putting the file on `/scratch-shared`. This folder is visible from all nodes and keep data up to 14 days.

```shell
sbatch 02_merge.sh
```


```shell
mkdir -p $DIR_BASE/mappings
cd $DIR_BASE/mappings
DIR_BASE=/home/aguarracino/tree_of_life_alignment
ls $DIR_BASE/assemblies/vgp/*.fa.gz | while read TARGET; do
  sbatch 03_mapping.sh $TARGET /scratch-shared/tmp.6i2z9n9QzB/vgp290.fasta.gz
done
```
