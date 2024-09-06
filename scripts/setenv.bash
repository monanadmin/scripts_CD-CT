#!/bin/bash

# Load modules:

echo -e "\033[1;32m==>\033[0m Executing setenv.bash: loading environment...\n"
. ./spack/env.sh
spack env activate myenv
spack load mpas-model
spack load wps
spack load metis
spack load --list


# Baixar pelo menos 1 vez o pacote de dados abaixo em scripts_CD-CT/datain:
# wget https://ftp.cptec.inpe.br/pesquisa/dmdcc/volatil/Renato/scripts_CD-CT_datain.tgz
# Baixar a CI do GFS em scripts_CD-CT/datain:
# wget https://ftp.cptec.inpe.br/pesquisa/dmdcc/volatil/Renato/GFS:2024-08-07_00


# Set environment variables and importants directories-------------------------------------------------- 

# MONAN-suite install root directories:
export DIR_SCRIPTS=$(dirname $(dirname $(pwd)))
export DIR_DADOS=$(dirname $(dirname $(pwd)))
# MONAN DIR IS MODIFIED BY script 1.install.bash
export MONANDIR=WILLBEFILLEDBYSCRIPT1

# Submiting variables:
# PRE-Static phase:
export STATIC_ncores=2

# PRE-Degrib phase:
export DEGRIB_ncores=1

# PRE-Init Atmosphere phase:
export INITATMOS_ncores=2

# Model phase:
export MODEL_ncores=2

# Post phase:
export POST_ncores=1 



#-----------------------------------------------------------------------
# We discourage changing the variables below:

# Others variables:
export OMP_NUM_THREADS=1
export OMPI_MCA_btl_openib_allow_ib=1
export OMPI_MCA_btl_openib_if_include="mlx5_0:1"
export PMIX_MCA_gds=hash
export MPI_PARAMS="-iface ib0 -bind-to core -map-by core"

# Libraries paths:
# $(spack location -i pacote)
export NETCDF=/home/user/scripts_CD-CT/scripts/spack/opt/spack/linux-ubuntu18.04-skylake/gcc-9.4.0/netcdf-c-4.9.2-wtzgun3w5as3xah4cdiaphd7geurfqqn
export PNETCDF=/home/user/scripts_CD-CT/scripts/spack/opt/spack/linux-ubuntu18.04-skylake/gcc-9.4.0/parallel-netcdf-1.12.3-ctuelfvjop3kyhy74z5ggtf644glvo7f
export NETCDFF=/home/user/scripts_CD-CT/scripts/spack/opt/spack/linux-ubuntu18.04-skylake/gcc-9.4.0/netcdf-fortran-4.6.1-vvb6bm27p6jd7hhv3jvkwilq2c2nefbo


export NETCDFDIR=${NETCDF}
export PNETCDFDIR=${PNETCDF}
export NETCDF_FORTRAN_DIR=${NETCDFF}
export NETCDF_FORTRAN_BIN=${NETCDFF}/bin
export NETCDF_FORTRAN_LIB=${NETCDFF}/lib
export NETCDF_FORTRAN_INC=${NETCDFF}/include

echo "NETCDFDIR=${NETCDFDIR}"
echo "PNETCDFDIR=${PNETCDFDIR}"
# Colors:
export GREEN='\033[1;32m'  # Green
export RED='\033[1;31m'    # Red
export NC='\033[0m'        # No Color
export BLUE='\033[01;34m'  # Blue
