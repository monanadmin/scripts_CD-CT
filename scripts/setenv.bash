#!/bin/bash

# Load modules:

module purge
module load ohpc
module unload openmpi4
module load phdf5
module load netcdf 
module load netcdf-fortran 
module load mpich-4.0.2-gcc-9.4.0-gpof2pv
module load hwloc
module load phdf5
module load cdo-2.0.4-gcc-9.4.0-bjulvnd
module load opengrads/2.2.1
module load nco-5.0.1-gcc-11.2.0-u37c3hb
module load metis
module list







# Set environment variables and importants directories-------------------------------------------------- 


# MONAN-suite install root directories:
# Put your directories:
export DIR_SCRIPTS=$(dirname $(dirname $(pwd)))
export DIR_DADOS=$(dirname $(dirname $(pwd)))
export MONANDIR=/mnt/beegfs/monan/users/renato/teste/scripts_CD-CT/sources/MONAN-Model_release/1.1.0

# Submiting variables:

# PRE-Static phase:
export STATIC_QUEUE="batch"
export STATIC_ncores=32
export STATIC_nnodes=1
export STATIC_ncpn=32
export STATIC_jobname="Pre.static"
export STATIC_walltime="02:00:00"

# PRE-Degrib phase:
export DEGRIB_QUEUE="batch"
export DEGRIB_ncores=1
export DEGRIB_nnodes=1
export DEGRIB_ncpn=1
export DEGRIB_jobname="Pre.degrib"
### export DEGRIB_walltime="00:30:00" not used yet - using STATIC_walltime

# PRE-Init Atmosphere phase:
export INITATMOS_QUEUE="batch"
export INITATMOS_ncores=64
export INITATMOS_nnodes=1
### export INITATMOS_ncpn=1 not used yet  - using INITATMOS_ncores 
export INITATMOS_jobname="Pre.InitAtmos"
### export INITATMOS_walltime="01:00:00" not used yet - using STATIC_walltime


# Model phase:
export MODEL_QUEUE="batch"
export MODEL_ncores=512
export MODEL_nnodes=8
export MODEL_ncpn=64
export MODEL_jobname="Model.MONAN"
export MODEL_walltime="8:00:00"


# Post phase:
export POST_QUEUE="batch"
### export POST_ncores=1 not used yet
export POST_nnodes=1
export POST_ncpn=32
export POST_jobname="Post.MONAN"
export POST_walltime="8:00:00"


# Products phase:
export PRODS_QUEUE="batch"
export PRODS_ncores=1
export PRODS_nnodes=1
export PRODS_ncpn=1
export PRODS_jobname="Prods.MONAN"
export PRODS_walltime="8:00:00"


#-----------------------------------------------------------------------
# We discourage changing the variables below:

# Others variables:
export OMP_NUM_THREADS=1
export OMPI_MCA_btl_openib_allow_ib=1
export OMPI_MCA_btl_openib_if_include="mlx5_0:1"
export PMIX_MCA_gds=hash
export MPI_PARAMS="-iface ib0 -bind-to core -map-by core"

# Libraries paths:
export NETCDF=/mnt/beegfs/monan/libs/netcdf
export PNETCDF=/mnt/beegfs/monan/libs/PnetCDF
export NETCDFDIR=${NETCDF}
export PNETCDFDIR=${PNETCDF}
export DIRDADOS=/mnt/beegfs/monan/dados/MONAN_v0.5.0
export OPERDIR=/oper/dados/ioper/tempo

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
   how_many_nodes=$(echo "${how_many_nodes_int}+${how_many_nodes_left}" | bc )
   #echo "INT number of nodes needed: \${how_many_nodes_int}  = ${how_many_nodes_int}"
   #echo "number of nodes left:       \${how_many_nodes_left} = ${how_many_nodes_left}"
   echo "The number of nodes needed: \${how_many_nodes}  = ${how_many_nodes}"
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


clean_post_tmp_files () {

   echo "Removing all temporary files from last POST run trash."

   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts/dir.*
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts/PostAtmos_*.sh
   
   echo ""
   
}
#----------------------------------------------------------------------------------------------



clean_pre_tmp_files () {

   echo "Removing all temporary files from last PRE run trash."

   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts/log.*.0000.out
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts/x1.*.init.nc
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts/GFS*
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts/init_atmosphere_model
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts/namelist*
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts/streams.init_atmosphere
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts/x1.*.graph.info.part.*
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts/x1.*.static.nc
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts/ungrib.exe
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts/Vtable
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts/*.log
   
   
   echo ""
   
}
#----------------------------------------------------------------------------------------------




