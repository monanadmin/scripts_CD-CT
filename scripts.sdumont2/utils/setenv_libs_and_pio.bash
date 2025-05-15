#! /bin/bash -x

module purge
#module load ohpc
#module load cmake/3.21.3
#module load cmake-3.24.2-gcc-9.4.0-s7wmakm
module load openmpi/gnu/4.1.6.15.1
module list

export MY_LOCAL_DIR=$(pwd)
export YOUR_INSTALL_ROOT=/scratch/cptec/eduardo.khamis/libs_openmpi

export  EDIR=${YOUR_INSTALL_ROOT}/event
export HLDIR=${YOUR_INSTALL_ROOT}/hwloc
export  ZDIR=${YOUR_INSTALL_ROOT}/zlib
export H5DIR=${YOUR_INSTALL_ROOT}/hdf5
export NFDIR=${YOUR_INSTALL_ROOT}/netcdf
export NCDIR=${NFDIR}
export PNDIR=${YOUR_INSTALL_ROOT}/PnetCDF
export PIODIR=${YOUR_INSTALL_ROOT}/pio

export PATH=${PATH}:$EDIR/lib
export PATH=${PATH}:$EDIR/include
export PATH=${PATH}:$HLDIR/lib
export PATH=${PATH}:$HLDIR/include
export PATH=${PATH}:$ZDIR/lib
export PATH=${PATH}:$ZDIR/include
export PATH=${PATH}:$H5DIR/lib
export PATH=${PATH}:$H5DIR/include
export PATH=${PATH}:$NFDIR/bin
export PATH=${PATH}:$NFDIR/lib
export PATH=${PATH}:$NFDIR/include
export PATH=${PATH}:$PNDIR/lib
export PATH=${PATH}:$PNDIR/include
export PATH=${PATH}:$PIODIR/lib
export PATH=${PATH}:$PIODIR/include
export PATH=${PATH}:/usr/lib64/

ulimit -s unlimited
