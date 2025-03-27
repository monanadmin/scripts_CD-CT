#!/bin/bash

# Load modules:

module purge
module use /scratch/cptec/nvidia/x86_64/hpc_sdk/modulefiles/ 
module load nvhpc/23.1
module list

# Set environment variables and importants directories-------------------------------------------------- 


# MONAN-suite install root directories:
# Put your directories:
export DIR_SCRIPTS=$(dirname $(dirname $(pwd)))
export DIR_DADOS=$(dirname $(dirname $(pwd)))
export MONANDIR=$MONANDIR

# Submiting variables:

# PRE-Static phase:
export STATIC_QUEUE="lncc-h100"
export STATIC_gres=""
export STATIC_ncores=48
export STATIC_nnodes=1
export STATIC_ncpn=48
export STATIC_jobname="Pre.static"
export STATIC_walltime="02:00:00"

# PRE-Degrib phase:
export DEGRIB_QUEUE="lncc-h100"
export DEGRIB_gres=""
export DEGRIB_ncores=1
export DEGRIB_nnodes=1
export DEGRIB_ncpn=1
export DEGRIB_jobname="Pre.degrib"
### export DEGRIB_walltime="00:30:00" not used yet - using STATIC_walltime

# PRE-Init Atmosphere phase:
export INITATMOS_QUEUE="lncc-h100"
export INITATMOS_gres=""
export INITATMOS_ncores=48
export INITATMOS_nnodes=1
### export INITATMOS_ncpn=1 not used yet  - using INITATMOS_ncores 
export INITATMOS_jobname="Pre.InitAtmos"
### export INITATMOS_walltime="01:00:00" not used yet - using STATIC_walltime


# Model phase:
export MODEL_QUEUE="lncc-h100"
export MODEL_gres=""
export MODEL_ncores=48
export MODEL_nnodes=2
export MODEL_ncpn=96
export MODEL_jobname="Model.MONAN"
export MODEL_walltime="0:20:00"


# Post phase:
export POST_QUEUE="lncc-h100"
### export POST_ncores=1 not used yet
export POST_nnodes=1
export POST_ncpn=48
export POST_jobname="Post.MONAN"
export POST_walltime="8:00:00"


# Products phase:
export PRODS_QUEUE="lncc-h100"
export PRODS_ncores=1
export PRODS_nnodes=1
export PRODS_ncpn=1
export PRODS_jobname="Prods.MONAN"
export PRODS_walltime="8:00:00"


#-----------------------------------------------------------------------
# We discourage changing the variables below:

# Others variables:
export OMP_NUM_THREADS=1
#export OMPI_MCA_btl_openib_allow_ib=1
#export OMPI_MCA_btl_openib_if_include="mlx5_0:1"
export PMIX_MCA_gds=hash
#export MPI_PARAMS="-iface ib0 -bind-to core -map-by core"
export MPI_PARAMS="-iface eno12399np0 -bind-to core -map-by core"
export OMPI_MCA_coll_hcoll_enable=0

# Libraries paths:
#export NETCDF=/mnt/beegfs/monan/libs/netcdf
#export PNETCDF=/mnt/beegfs/monan/libs/PnetCDF
#export PIO=$(spack location -i parallelio)
#export NETCDF=$(spack location -i netcdf-fortran)
#export PNETCDF=$(spack location -i parallel-netcdf)
export NETCDF=/scratch/cptec/libs_nvhpc/netcdf
export PNETCDF=/scratch/cptec/libs_nvhpc/PnetCDF
#export PIO=/scratch/cptec/libs_nvhpc/pio
export NETCDFDIR=${NETCDF}
export PNETCDFDIR=${PNETCDF}
export DIRDADOS=/scratch/cptec/dados
export OPERDIR=/scratch/cptec/dados/CIs/GFS


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

   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/atmosphere_model
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/*TBL
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/*DBL
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/*DATA
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/x1.*.nc
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/x1.*.graph.info.part.*
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/Vtable.GFS
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/streams.atmosphere
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/stream_list.atmosphere.surface
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/stream_list.atmosphere.output
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/stream_list.atmosphere.diagnostics
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/namelist.atmosphere
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/MONAN_DIAG_*
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/log.atmosphere.*
   echo ""
   
}
#----------------------------------------------------------------------------------------------


clean_post_tmp_files () {

   echo "Removing all temporary files from last POST run trash."

   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/dir.*
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/PostAtmos_*.sh
   
   echo ""
   
}
#----------------------------------------------------------------------------------------------



clean_pre_tmp_files () {

   echo "Removing all temporary files from last PRE run trash."

   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/log.*.0000.out
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/x1.*.init.nc
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/GFS*
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/init_atmosphere_model
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/namelist*
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/streams.init_atmosphere
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/x1.*.graph.info.part.*
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/x1.*.static.nc
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/ungrib.exe
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/Vtable
   rm -fr ${DIR_SCRIPTS}/scripts_CD-CT/scripts.sdumont/*.log
   
   
   echo ""
   
}
#----------------------------------------------------------------------------------------------




