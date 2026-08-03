#!/bin/bash

# Load modules:

module purge
module load ohpc
module load phdf5
module load netcdf 
module load netcdf-fortran 
module load cdo-2.0.4-gcc-9.4.0-bjulvnd
module load opengrads/2.2.1
module load nco-5.0.1-gcc-11.2.0-u37c3hb
module load metis
module list


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
export DEGRIB_walltime="02:00:00" 

# PRE-Init Atmosphere phase:
export INITATMOS_QUEUE="batch"
export INITATMOS_ncores=64
export INITATMOS_nnodes=1
export INITATMOS_ncpn=64
export INITATMOS_jobname="Pre.InitAtmos"
export INITATMOS_walltime="02:00:00" 


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
export POST_ncores=1
export POST_nnodes=1
export POST_ncpn=32
export POST_jobname="Post.MONAN"
export POST_walltime="8:00:00"





# Libraries paths:
export NETCDF=/mnt/beegfs/monan/libs_openmpi/netcdf
export PNETCDF=/mnt/beegfs/monan/libs_openmpi/PnetCDF
export NETCDFDIR=${NETCDF}
export PNETCDFDIR=${PNETCDF}
export DIRDADOS=/mnt/beegfs/monan/dados/MONAN_v2.0.x
export OPERDIR=/oper/dados/ioper/tempo
export GCCCIS=/mnt/beegfs/monan/CIs


# --- Others Vabriables ---
# OpenMPI:
export OMPI_MCA_btl_openib_allow_ib=1
export OMPI_MCA_btl_openib_if_include="mlx5_0:1"
# PMIx (process management for MPI):
export PMIX_MCA_gds=hash
# MPI:
export MPI_PARAMS="-iface ib0 -bind-to core -map-by core"
# OpenMP:
export OMP_NUM_THREADS=1

