#!/bin/bash

# !!!!! Requires vtx-mpas-meshes: https://github.com/marta-gil/vtx-mpas-meshes !!!!!

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash

# Standard directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT; mkdir -p ${DIRHOMES}
DIRHOMED=${DIR_DADOS}/scripts_CD-CT;   mkdir -p ${DIRHOMED}
SCRIPTS=${DIRHOMES}/scripts;           mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;             mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;           mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;           mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;               mkdir -p ${EXECS}
#----------------------------------------------------------------------

echo -e  "${GREEN}==>${NC} creating fixed directory to save mesh... \n"
mkdir -p ${DATAIN}/fixed


# Activate conda vtx_env environment
CONDA_PATH="$(conda info --root)"
source "$CONDA_PATH/etc/profile.d/conda.sh"
conda activate vtx_env

# Select parameters from input_file.txt
echo "Reading input parameters:"
while IFS="=" read -r name value; do
    if [[ ! "$name" =~ ^\# ]]; then
	declare -r $name=$value
        echo $name":" $value
    fi	
done < mesh_input_file.txt

# Run script
cd $vtx_mpas_meshes_dir
python3 create_regional_mesh.py --vtx_mpas_meshes_dir $vtx_mpas_meshes_dir --exp_dir $exp_dir --meshes_dir $meshes_dir --N $N --lon $lon --lat $lat --inner_radius $inner_radius --outer_radius $outer_radius --n_layers $n_layers --high_res $high_res --low_res $low_res --do_regional $do_regional --grid_type $grid_type

cd -

# Select parameters from input_file.txt
echo "Reading input parameters:"
while IFS="=" read -r name value; do
    if [[ ! "$name" =~ ^\# ]]; then
        declare -r $name=$value
        echo $name":" $value
    fi
done < mesh_input_file.txt

# copy relevant files to fixed/
cd ${meshes_dir}/${file_name}
cp *.grid.nc *.graph.info ../  
