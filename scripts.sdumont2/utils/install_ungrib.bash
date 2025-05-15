#! /bin/bash +x

#module load general/anaconda3/2024.10
#conda create --prefix $HOME/conda-env/test-tf python=3.12
#source activate $HOME/conda-env/test-tf
#conda install conda-forge::tcsh
#ln -s /scratch/cptec/eduardo.khamis/conda-env/test-tf/bin/tcsh /scratch/cptec/eduardo.khamis/bin
#exit

module purge
module load openmpi/gnu/4.1.6.15.1
#module use /scratch/cptec/nvidia/x86_64/hpc_sdk/modulefiles/
#module load nvhpc/23.1
module list

workdir=/scratch/cptec
#version=v0.23.1
#spackdir=${workdir}/spack/${version}
#source ${spackdir}/share/spack/setup-env.sh
#
#export SPACK_USER_CONFIG_PATH=${workdir}/.spack/${version}
#
#export NETCDF=$(spack location -i netcdf-fortran)
#export PNETCDF=$(spack location -i parallel-netcdf)

export NETCDF=/scratch/cptec/eduardo.khamis/libs_openmpi.ok/netcdf
export PNETCDF=/scratch/cptec/eduardo.khamis/libs_openmpi.ok/PnetCDF

export PATH=${PATH}:$NETCDF/lib
export PATH=${PATH}:$NETCDF/include
export PATH=${PATH}:$PNETCDF/lib
export PATH=${PATH}:$PNETCDF/include

export LD_LIBRARY_PATH=$NETCDF/lib:$PNETCDF/lib:$LD_LIBRARY_PATH


export MY_LOCAL_DIR=$(pwd)
export YOUR_INSTALL_ROOT=${workdir}/eduardo.khamis/ungrib

export FC=mpif90
export CC=mpicc
export CXX=mpicxx

mkdir -p $MY_LOCAL_DIR/src
mkdir -p $YOUR_INSTALL_ROOT

#
# WPS
#

wps_version=v4.5

echo " "
echo "Downloading ungrib version $wps_version ... please wait"
echo " "

#cd $MY_LOCAL_DIR/src
#rm -rf wps_src
#git clone https://github.com/wrf-model/WPS wps_src
#cd wps_src
#git checkout tags/$wps_version -b branch_$wps_version

echo " "
echo "Installing ungrib version $wps_version ... please wait"
echo " "

echo "netcdf=$NETCDF"
echo "path=$PATH"

rm -rf $YOUR_INSTALL_ROOT/wps_src
cp -r $MY_LOCAL_DIR/src/wps_src $YOUR_INSTALL_ROOT
cd $YOUR_INSTALL_ROOT/wps_src
# escolher opcao 1 - gnu serial
./configure --build-grib2-libs --nowrf
#./configure --nowrf --build-grib2-libs
#./configure --nowrf
tcsh ./compile ungrib
cp -f $YOUR_INSTALL_ROOT/wps_src/ungrib/src/ungrib.exe $YOUR_INSTALL_ROOT
cd $MY_LOCAL_DIR


