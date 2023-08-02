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
awk -v FS='\t' '$14 != ""' VGP\ Ordinal\ List\ -\ VGP\ Phase\ 1+.tsv | cut -f 14 | grep GCA | sed '1d' | wc -l > VGP.assemblies.2023.07.04.txt
```

Download the data:

```shell
sbatch 00_download2.sh
```

PanSN:

```shell
sbatch 01_pansh.sh
```

Merge all assemblies, putting the file on `/scratch-shared`. This folder is visible from all nodes and keep data up to 14 days.

```shell
sbatch 02_merge.sh
```