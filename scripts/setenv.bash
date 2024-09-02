#!/bin/bash

# Load modules:

echo -e "\033[1;32m==>\033[0m Executing setenv.bash: loading environment...\n"
source spack/env.sh
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
# Put your directories:
export DIR_SCRIPTS=$(dirname $(dirname $(pwd)))
export DIR_DADOS=$(dirname $(dirname $(pwd)))
export MONANDIR=/dados/repo/scripts_CD-CT/sources/MONAN-Model_1.0.0

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
export NETCDF=/home/usuario/repo/scripts_CD-CT/scripts/spack/opt/spack/linux-ubuntu22.04-haswell/gcc-11.4.0/netcdf-c-4.9.2-mrzvvju2bmuw76i6r6byrx2kn6ygyhqg
export PNETCDF=/home/usuario/repo/scripts_CD-CT/scripts/spack/opt/spack/linux-ubuntu22.04-haswell/gcc-11.4.0/parallel-netcdf-1.12.3-dgphmay73qspxoi3pkqkpzocf4gb2oq3
export NETCDFF=/home/usuario/repo/scripts_CD-CT/scripts/spack/opt/spack/linux-ubuntu22.04-haswell/gcc-11.4.0/netcdf-fortran-4.6.1-d7raeuf3klp5kvkmulvp2f6rj2bckeej


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
