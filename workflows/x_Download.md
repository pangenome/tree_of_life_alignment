```shell
mkdir -p ~/tools/ncbi_datasets
cd ~/tools/ncbi_datasets

curl -o datasets 'https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/v2/linux-amd64/datasets'
curl -o dataformat 'https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/v2/linux-amd64/dataformat'
chmod +x datasets dataformat


DATASETS=~/tools/ncbi_datasets/datasets

mkdir -p /lizardfs/guarracino/tree_of_life_alignment/assemblies/vgp
cd /lizardfs/guarracino/tree_of_life_alignment/assemblies/vgp
$DATASETS download genome accession --inputfile /lizardfs/guarracino/tree_of_life_alignment/data/VGP.assemblies.2023.07.04.txt --filename xxx.zip
```