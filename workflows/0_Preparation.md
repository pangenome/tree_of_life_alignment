# Preparation

Variables on `octopus`:

```shell
DIR_BASE=/lizardfs/guarracino/tree_of_life_alignment
RUN_FASTIX=/home/guarracino/tools/fastix/target/release/fastix-331c1159ea16625ee79d1a82522e800c99206834
RUN_WFMASH=/home/guarracino/tools/wfmash/build/bin/wfmash-191afe12042962d3c0d5c62936528561753b3da0
```

## Tools

```shell
mkdir -p ~/tools/
cd ~/tools/
```

On `octopus`:

```shell
git clone --recursive https://github.com/waveygang/wfmash
cd wfmash
git checkout master
git pull
git checkout 8ba3c53f327731ca515abd1ef32179f15acb9732
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

On `snellius`:

```shell
# wfmash from scratch: load modules on Snellius (Jemalloc is missing!)
#module load 2022
#module load binutils/2.38-GCCcore-11.3.0 # to avoid "as: unrecognized option '--gdwarf-5'"
#module load CMake/3.23.1-GCCcore-11.3.0 # to avoid "cmake: symbol lookup error"
#module load HTSlib/1.15.1-GCC-11.3.0
#module load zlib/1.2.12-GCCcore-11.3.0
#module load GSL/2.7-GCC-11.3.0
#module load HTSlib/1.15.1-GCC-11.3.0

module load 2022

# Parallel
module load parallel/20220722-GCCcore-11.3.0

# Prepare conda and install wfmash and seqwish
module load Miniconda3/4.12.0
conda create --prefix=~/tools/conda
conda activate ~/tools/conda
conda install -c bioconda -c conda-forge wfmash==0.10.3
conda install -c bioconda -c conda-forge seqwish==0.7.9

# Prepare Rust and build fastix
module load Rust/1.60.0-GCCcore-11.3.0

git clone --recursive https://github.com/ekg/fastix.git
cd fastix
git checkout 331c1159ea16625ee79d1a82522e800c99206834
cargo build --release
mv target/release/fastix target/release/fastix-331c1159ea16625ee79d1a82522e800c99206834

# wfmash via nix
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

cargo install nix-user-chroot
echo 'export PATH="$PATH:/home/aguarracino/.cargo/bin"' >> ~/.bashrc
source ~/.bashrc


curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

cargo install nix-user-chroot

mkdir -m 0755 ~/.nix
nix-user-chroot ~/.nix bash -c 'curl -L https://nixos.org/nix/install | sh'
. /home/aguarracino/.nix-profile/etc/profile.d/nix.sh

cd ~/tools
git clone https://github.com/ekg/using-nix.git
echo 'export PATH="$PATH:/home/aguarracino/tools/using-nix"' >> ~/.bashrc
source ~/.bashrc

git clone --recursive https://github.com/waveygang/wfmash.git
cd wfmash
nix-user-chroot ~/.nix $SHELL
nix-build && nix-env -i ./result
```
