#!/bin/bash 

#-----------------------------------------------------------------------------#
# !SCRIPT: install_mpassit
#
# !DESCRIPTION:
#     Script to install the MONAN-MPASSIT pos-processing.
#     
#     Performs the following tasks:
# 
#        o Clone the MONAN-MPASSIT github repository in a local directory
#        o Compiles the MONAN-MPASSIT
#
#  Author: Carlos Renato
#-----------------------------------------------------------------------------#


#Functions -------------------------------------------------------------------#
function checkout_system() {
  local source_dir=$1
  local github_link=$2
  local tag_or_branch_name=$3
  if [ -d "${source_dir}" ]; then
      echo -e  "${GREEN}==>${NC} Source dir already exists, updating it ...\n"
  else
      echo -e  "${GREEN}==>${NC} Cloning your fork repository...\n"
      git clone ${github_link} ${source_dir}
      if [ ! -d "${source_dir}" ]; then
          echo -e "${RED}==>${NC} An error occurred while cloning your fork. Possible causes:  wrong URL, user or password.\n"
          exit -1
      fi
  fi

  cd ${source_dir}
  if git checkout "${tag_or_branch_name}" 2>/dev/null; then
      git pull
      echo -e "${GREEN}==>${NC} Successfully checked out and updated: ${BLUE}${tag_or_branch_name}"
  else
      echo -e "${RED}==>${NC} Failed to check out branch: ${BLUE}${tag_or_branch_name}"
      echo -e "${RED}==>${NC} Please check if you have this branch. Exiting ..."
      exit -1
  fi
  git log | head -1
}
#-----------------------------------------------------------------------------#

if [ $# -lt 1 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} [G] [M]"
   echo ""
   echo "G   :: MONAN-MPASSIT GitHub link of your personal fork, eg: https://github.com/MYUSER/yMONAN-MPASSIT-puro.git"
   echo "M   :: MONAN-MPASSIT tag or branch name of your personal fork. (will be used 'develop' if not informed)" 
   echo ""
   exit
fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash
echo ""
echo "---- Installing the MPASSIT ----"
echo ""



# Standart directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/${myDIR};  mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/${myDIR};    mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;            mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;              mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;            mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;            mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;                mkdir -p ${EXECS}
#----------------------------------------------------------------------


# Input variables:-----------------------------------------------------
github_link_MPASSIT=${1}
tag_or_branch_name_MPASSIT=${2}
tag_or_branch_name_MPASSIT=${tag_or_branch_name_MPASSIT:="1.4.3-rc"}
echo "MPASSIT branch name in use: ${tag_or_branch_name_MPASSIT}"
#----------------------------------------------------------------------

# Local variables:-----------------------------------------------------
MPASSIT_DIR=${SOURCES}/MPASSIT_${tag_or_branch_name_MPASSIT}
#----------------------------------------------------------------------

$(sed -i "s;MPASSIT_DIR=.*$;MPASSIT_DIR=$MPASSIT_DIR;" setenv.bash)
chmod 755 ${SCRIPTS}/setenv.bash
. ${SCRIPTS}/setenv.bash

#----------------------------------------------------------------------
# Here some differences that must be loaded just for MPASSIT install/use, 
# in the future, we will put all togheter in one setenv.bash, 
# but for now need to load them here:
#
# Compiladores Cray
export CMAKE_C_COMPILER=cc
export CMAKE_Fortran_COMPILER=ftn
# Load modules
module purge
module load PrgEnv-gnu
module load craype-x86-turin
module load cray-hdf5-parallel/1.14.3.3
module load cray-netcdf-hdf5parallel/4.9.0.15
module load cray-parallel-netcdf/1.12.3.15
module load xpmem/0.2.119-1.3_gef379be13330
module load cray-pals
module load esmf/8.9.1-gcc13
module load METIS/5.1.0
module load grads

# NetCDF paralelo - NETCDF_DIR eh definido pelo modulo cray-netcdf-hdf5parallel
export NETCDF=${NETCDF_DIR}
export LD_LIBRARY_PATH=${NETCDF_DIR}/lib:${LD_LIBRARY_PATH}
# ESMF compilado com NetCDF paralelo NA JACI:
export ESMF_INCDIR=${ESMF_DIR}/include
export ESMF_LIBDIR=${ESMF_DIR}/lib/libO/Unicos.gfortran.64.mpi.default
export ESMF_MODDIR=${ESMF_DIR}/mod/modO/Unicos.gfortran.64.mpi.default
export LIBRARY_PATH=${LIBRARY_PATH}:${ESMF_LIBDIR}
export PATH=${PATH}:${ESMF_DIR}/bin/binO/Unicos.gfortran.64.mpi.default
export ESMF_FFLAGS="-I${ESMF_MODDIR} -I${ESMF_INCDIR}"
export ESMF_LDFLAGS="-L${ESMF_LIBDIR} -lesmf"
export ESMF_COMPILER="gfortran"
export ESMF_F90COMPILER=ftn
export ESMF_CXXCOMPILER=CC
export ESMF_CCCOMPILER=cc
export ESMF_F90LINKER=ftn
# Confirma que NETCDF_DIR aponta para o paralelo
echo "NETCDF_DIR = ${NETCDF_DIR}"
echo -n "NETCDF_DIR paralelo? "
nc-config --has-parallel4

#----------------------------------------------------------------------

checkout_system ${MPASSIT_DIR} ${github_link_MPASSIT} ${tag_or_branch_name_MPASSIT}

MPASSITVERSION=MPASSIT.$(head -n 1 ${MPASSIT_DIR}/VERSION.txt)
cd ${MPASSIT_DIR}

export CMAKE_FLAGS="-DCMAKE_INSTALL_PREFIX=../ \
  -DEMC_EXEC_DIR=ON \
  -DBUILD_TESTING=OFF \
  -DCMAKE_C_COMPILER=cc \
  -DCMAKE_CXX_COMPILER=CC \
  -DCMAKE_Fortran_COMPILER=ftn \
  -DCMAKE_BUILD_TYPE=Release \
  -DNETCDF_C_LIBRARY=${NETCDF_DIR}/lib/libnetcdf.so \
  -DNETCDF_Fortran_LIBRARY=${NETCDF_DIR}/lib/libnetcdff.so \
  -DNETCDF_C_INCLUDE_DIR=${NETCDF_DIR}/include \
  -DNETCDF_Fortran_INCLUDE_DIR=${NETCDF_DIR}/include \
  -DCMAKE_BUILD_TYPE=Release"

mkdir -p ./build && cd ./build || exit 0

# Build:
cmake .. ${CMAKE_FLAGS}
make -j 8 VERBOSE=1
make install



if [ -s "${MPASSIT_DIR}/bin/mpassit" ] ; then
   mkdir -p ${EXECS}/${MPASSITVERSION}
   cp -f ${MPASSIT_DIR}/bin/mpassit ${EXECS}/${MPASSITVERSION}
   cp -f ${MPASSIT_DIR}/VERSION.txt ${EXECS}/${MPASSITVERSION}/MPASSIT-VERSION.txt
    echo ""
    echo -e "${GREEN}==>${NC} File convert_mpas generated Sucessfully in ${MPASSIT_DIR}/bin and copied to ${EXECS}/${MPASSITVERSION} !"
    echo
else
    echo -e "${RED}==>${NC} !!! An error occurred during convert_mpas build. Check output"
    exit -1
fi



