#!/bin/bash

# Load modules:
module purge
module load PrgEnv-nvidia/8.6.0
module load craype-x86-turin
module load cray-hdf5/1.14.3.3
module load cray-netcdf/4.9.0.15
module load cray-parallel-netcdf/1.12.3.15
module load xpmem/0.2.119-1.3_gef379be13330
module load grads/2.2.1.oga.1
module load cdo/2.4.2
module load METIS/5.1.0
module load cray-pals
module list


# Submiting variables:

# PRE-Static phase:
export STATIC_QUEUE="pesqextra"
export STATIC_ncores=128
export STATIC_nnodes=4
export STATIC_ncpus=32
export STATIC_ncpn=32
export STATIC_nthreads=1
export STATIC_jobname="Pre.static"
export STATIC_walltime="02:00:00"


# PRE-Degrib phase:
export DEGRIB_QUEUE="pesqextra"
export DEGRIB_ncores=1
export DEGRIB_nnodes=1
export DEGRIB_ncpus=1
export DEGRIB_ncpn=1
export DEGRIB_nthreads=1
export DEGRIB_jobname="Pre.degrib"
export DEGRIB_walltime="02:00:00"


# PRE-Init Atmosphere phase:
export INITATMOS_QUEUE="pesqextra"
export INITATMOS_ncores=512
export INITATMOS_nnodes=4
export INITATMOS_ncpus=128
export INITATMOS_ncpn=128
export INITATMOS_nthreads=1
export INITATMOS_jobname="Pre.InitAtmos"
export INITATMOS_walltime="02:00:00"


# Model phase:
export MODEL_QUEUE="pesqextra"
export MODEL_ncores=2048
export MODEL_nnodes=8
export MODEL_ncpus=256
export MODEL_ncpn=256
export MODEL_nthreads=1
export MODEL_jobname="Model.MONAN"
export MODEL_walltime="8:00:00"
#PBS -l select=8:ncpus=64:mpiprocs=64 ==   512mpi,  8nodes, 64cpn
#PBS -l select=16:ncpus=64:mpiprocs=64 == 1024mpi, 16nodes, 64cpn

# Post phase:
export POST_QUEUE="pesqextra"
export POST_ncores=32
export POST_nnodes=1
export POST_ncpus=32
export POST_ncpn=32
export POST_nthreads=1
export POST_jobname="Post.MONAN"
export POST_walltime="8:00:00"


# Libraries paths:
export NETCDF=${NETCDF_DIR}
export PNETCDF=${PNETCDF_DIR}
export NETCDFDIR=${NETCDF}
export PNETCDFDIR=${PNETCDF}

export OPERDIR=/oper/dados/ioper/tempo
export DIRDADOS=/p/projetos/monan_adm/monan/dados/MONAN_v2.0.x
export GCCCIS=/p/projetos/monan_adm/monan/CIs


# PIO is not necessary for version 8.* If PIO is empty, MPAS Will use SMIOL
export PIO=
export LD_LIBRARY_PATH=$NETCDF/lib:$PNETCDF/lib:$PIO/lib64:$LD_LIBRARY_PATH


# --- Others Variables ---
# HPE Slingshot/Libfabric:
export FI_CXI_REQ_BUF_SIZE=25165824
export FI_CXI_RX_MATCH_MODE=software
export FI_MR_CACHE_MAX_COUNT=0
# MPICH:
# export MPICH_MEMORY_REPORT=2
# OpenMP:
export OMP_NUM_THREADS=1


#
# -------- Tested Configurations ---------
#

#export MODEL_ncores=8192
#export MODEL_nnodes=32
#export MODEL_ncpus=256
#export MODEL_ncpn=256
#export MODEL_nthreads=1

#export MODEL_ncores=7680
#export MODEL_nnodes=30
#export MODEL_ncpus=256
#export MODEL_ncpn=256
#export MODEL_nthreads=1

#export MODEL_ncores=1024
#export MODEL_nnodes=16
#export MODEL_ncpus=256
#export MODEL_ncpn=64
#export MODEL_nthreads=4

#export MODEL_ncores=4096
#export MODEL_nnodes=20
#export MODEL_ncpus=256
#export MODEL_ncpn=256
#export MODEL_nthreads=1

#export MODEL_ncores=6144
#export MODEL_nnodes=24
#export MODEL_ncpus=256
#export MODEL_ncpn=256
#export MODEL_nthreads=1
