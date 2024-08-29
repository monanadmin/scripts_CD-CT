#!/bin/bash

# Load modules:

source spack/env.sh
spack load mpas-model%gcc@11.4.0
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
export MONANDIR=/home/usuario/repo/scripts_CD-CT/sources/MONAN-Model_1.0.0

# Submiting variables:
# PRE-Static phase:
export STATIC_ncores=8

# PRE-Degrib phase:
export DEGRIB_ncores=1

# PRE-Init Atmosphere phase:
export INITATMOS_ncores=8

# Model phase:
export MODEL_ncores=8

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


# Functions: ======================================================================================================

how_many_nodes () { 
   nume=${1}   
   deno=${2}
   num=$(echo "${nume}/${deno}" | bc -l)  
   how_many_nodes_int=$(echo "${num}/1" | bc)
   dif=$(echo "scale=0; (${num}-${how_many_nodes_int})*100/1" | bc)
   rest=$(echo "scale=0; (((${num}-${how_many_nodes_int})*${deno})+0.5)/1" | bc -l)
   if [ ${dif} -eq 0 ]; then how_many_nodes_left=0; else how_many_nodes_left=1; fi
   if [ ${how_many_nodes_int} -eq 0 ]; then how_many_nodes_int=1; how_many_nodes_left=0; rest=0; fi
   
   echo "INT number of nodes needed: \${how_many_nodes_int}  = ${how_many_nodes_int}"
   echo "number of nodes left:       \${how_many_nodes_left} = ${how_many_nodes_left}"
   echo ""
}
#----------------------------------------------------------------------------------------------



clean_model_tmp_files () {

   echo "Removing all temporary files from last MODEL run trash."

   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/atmosphere_model
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/*TBL
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/*DBL
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/*DATA
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/x1.*.nc
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/x1.*.graph.info.part.*
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/Vtable.GFS
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/streams.atmosphere
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/stream_list.atmosphere.surface
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/stream_list.atmosphere.output
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/stream_list.atmosphere.diagnostics
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/namelist.atmosphere
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/MONAN_DIAG_*
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/log.atmosphere.*
   echo ""
   
}
#----------------------------------------------------------------------------------------------

