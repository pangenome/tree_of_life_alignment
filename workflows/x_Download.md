```shell
mkdir -p ~/tools/ncbi_datasets
cd ~/tools/ncbi_datasets

curl -o datasets 'https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/v2/linux-amd64/datasets'
curl -o dataformat 'https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/v2/linux-amd64/dataformat'
chmod +x datasets dataformat


DATASETS=~/tools/ncbi_datasets/datasets

cd ~/tree_of_life_alignment/data
#awk -v FS='\t' '$14 != ""' VGP\ Ordinal\ List\ -\ VGP\ Phase\ 1+.tsv | cut -f 14 | grep GCA | sed '1d' | wc -l > VGP.assemblies.2023.07.04.txt

cd /scratch
# https://www.ncbi.nlm.nih.gov/datasets/docs/v2/how-tos/genomes/download-genome/
$DATASETS download genome accession --inputfile /lizardfs/guarracino/tree_of_life_alignment/data/VGP.assemblies.2023.07.04.txt --filename xxx.zip

mkdir -p /lizardfs/guarracino/tree_of_life_alignment/assemblies/vgp
cd /lizardfs/guarracino/tree_of_life_alignment/assemblies/vgp
mv /scratch/xxx.zip xxx.zip
unzip xxx.zip
rm xxx.zip README.md

FASTIX=/home/guarracino/tools/fastix/target/release/fastix-331c1159ea16625ee79d1a82522e800c99206834

# Trim headers and add prefixes
ls ncbi_dataset/data/*/*.fna | while read f; do
  NAME=$(basename $f)
  PREFIX=$(echo $NAME | sed 's/_genomic.fna//g');
  echo $PREFIX

  # `cut -f 1` to trim the headers
  $FASTIX -p "${PREFIX}#1#" <(cat $f | cut -f 1) | bgzip -@ 48 -l 9 -c > $PREFIX.fa.gz;
  samtools faidx $PREFIX.fa.gz
done

cat ncbi_dataset/data/*/*.fna | bgzip -@ 48 -l 9 > VGP.assemblies.2023.07.04.backup.fna.gz
rm -rf ncbi_dataset

zcat GCA*.fa.gz | bgzip -@ 48 -l 9 > vgp290.fa.gz
samtools faidx vgp290.fa.gz
```