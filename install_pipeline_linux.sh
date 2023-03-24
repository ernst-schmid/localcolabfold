#!/bin/bash

type wget || { echo "wget command is not installed. Please install it at first using apt or yum." ; exit 1 ; }
type curl || { echo "curl command is not installed. Please install it at first using apt or yum. " ; exit 1 ; }

CURRENTPATH=`pwd`
COLABFOLDDIR="${CURRENTPATH}/colabfold_batch"

mkdir -p ${COLABFOLDDIR}
cd ${COLABFOLDDIR}
wget -q -P . https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash ./Miniconda3-latest-Linux-x86_64.sh -b -p ${COLABFOLDDIR}/conda
rm Miniconda3-latest-Linux-x86_64.sh
. "${COLABFOLDDIR}/conda/etc/profile.d/conda.sh"
export PATH="${COLABFOLDDIR}/conda/condabin:${PATH}"
conda create -p $COLABFOLDDIR/colabfold-conda python=3.9 -y
conda activate $COLABFOLDDIR/colabfold-conda
conda update -n base conda -y
conda install -c conda-forge python=3.9 cudnn==8.2.1.32 cudatoolkit==11.1.1 openmm==7.5.1 pdbfixer -y

# install alignment tools
conda install -c conda-forge -c bioconda kalign2=2.04 hhsuite=3.3.0 mmseqs2=14.7e284 -y
# install ColabFold and Jaxlib
# colabfold-conda/bin/python3.9 -m pip install "colabfold[alphafold] @ git+https://github.com/sokrypton/ColabFold"
colabfold-conda/bin/python3.9 -m pip install --upgrade pip
colabfold-conda/bin/python3.9 -m pip install --no-warn-conflicts "colabfold[alphafold-minus-jax] @ git+https://github.com/ernst-schmid/ColabFold.git"
colabfold-conda/bin/python3.9 -m pip install https://storage.googleapis.com/jax-releases/cuda11/jaxlib-0.3.25+cuda11.cudnn82-cp39-cp39-manylinux2014_x86_64.whl
colabfold-conda/bin/python3.9 -m pip install jax==0.3.25 biopython==1.79

# Use 'Agg' for non-GUI backend
cd ${COLABFOLDDIR}/colabfold-conda/lib/python3.9/site-packages/colabfold
sed -i -e "s#from matplotlib import pyplot as plt#import matplotlib\nmatplotlib.use('Agg')\nimport matplotlib.pyplot as plt#g" plot.py
# modify the default params directory
sed -i -e "s#appdirs.user_cache_dir(__package__ or \"colabfold\")#\"${COLABFOLDDIR}/colabfold\"#g" download.py
# remove cache directory
rm -rf __pycache__

# start downloading weights
cd ${COLABFOLDDIR}
colabfold-conda/bin/python3.9 -m colabfold.download
cd ${CURRENTPATH}

echo "Download of alphafold2 weights finished."
echo "-----------------------------------------"
echo "Installation of colabfold_batch finished."
echo "Add ${COLABFOLDDIR}/colabfold-conda/bin to your environment variable PATH to run 'colabfold_batch'."
echo "i.e. For Bash, export PATH=\"${COLABFOLDDIR}/colabfold-conda/bin:\$PATH\""
echo "For more details, please type 'colabfold_batch --help'."

echo "Making standalone command 'colabfold'..."
cd ${COLABFOLDDIR}
mkdir -p bin && cd bin
cat << EOF > colabfold_batch
#!/bin/bash

export TF_FORCE_UNIFIED_MEMORY="1"
export CUDA_VISIBLE_DEVICES=\$1
export XLA_PYTHON_CLIENT_MEM_FRACTION="8.0"
export COLABFOLDPATH=${COLABFOLDDIR}
export PATH="\$COLABFOLDPATH/colabfold-conda/bin:\$PATH"
\$COLABFOLDPATH/colabfold-conda/bin/colabfold_batch "\${@:2}" & echo \$! > ${CURRENTPATH}/colabfold_gpu_\$1'_pid.txt'
EOF
chmod +x ./colabfold_batch

echo export COLABFOLD_FOLDER=${COLABFOLDDIR} >> ~/.bashrc 
echo 'export PATH="$COLABFOLD_FOLDER/bin:$PATH"' >> ~/.bashrc 

export COLABFOLD_FOLDER=${COLABFOLDDIR}
export PATH="${COLABFOLD_FOLDER}/bin:${PATH}"

cd ~
echo "Download python helper scripts to analyze the outputs from colabfold"
read -p "Enter the github access token: " github_token
curl -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${github_token}" -H "X-GitHub-Api-Version: 2022-11-28"  https://api.github.com/repos/ernst-schmid/foldserver/zipball/ -o github_analysis_scripts.zip
unzip github_analysis_scripts.zip
find ./ -maxdepth 1 -name *ernst* -exec mv {} analysis_scripts \;
rm -r github_analysis_scripts.zip

echo "Installing helper script to upload files to dropbox"
cd ~
wget -q https://raw.githubusercontent.com/ernst-schmid/localcolabfold/main/upload_to_dbx.sh
chmod +x upload_to_dbx.sh

echo "Setting up dropbox account command line interface for backing up colabfold data."
mkdir ~/bin
cd ~/bin
wget https://github.com/dropbox/dbxcli/releases/download/v3.0.0/dbxcli-linux-amd64
mv dbxcli-linux-amd64 dbxcli
chmod +x dbxcli
~/bin/dbxcli account

echo "all done"
