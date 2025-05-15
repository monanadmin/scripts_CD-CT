#! /bin/bash +x

# conda deactivate

. setenv_libs_and_pio.bash

mkdir -p $YOUR_INSTALL_ROOT

#
# Checking paths...
#
echo "event=$EDIR" 
echo "hwloc=$HLDIR" 
echo "zlib=$ZDIR" 
echo "hdf5=$H5DIR" 
echo "netcdf=$NFDIR" 
echo "pnetcdf=$PNDIR" 
echo "pio=$PIODIR" 
echo "path=$PATH"


#
# Downloading all libs...
#

echo "Downloading all libs, please wait and check all at the end!"

mkdir -p $MY_LOCAL_DIR/src

event_version=event-2.1.12
echo " "
echo "Downloading event version $event_version ... please wait"
echo " "
cd $MY_LOCAL_DIR/src
wget https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz
tar xvfz libevent-2.1.12-stable.tar.gz
mv libevent-2.1.12-stable event_src

hwloc_version=hwloc-2.5.0
echo " "
echo "Downloading hwloc version $hwloc_version ... please wait"
echo " "
cd $MY_LOCAL_DIR/src
wget https://download.open-mpi.org/release/hwloc/v2.5/hwloc-2.5.0.tar.gz 
tar xvfz hwloc-2.5.0.tar.gz
mv hwloc-2.5.0 hwloc_src

zlib_version=v1.3.1
echo " "
echo "Downloading zlib version $zlib_version ... please wait"
echo " "
cd $MY_LOCAL_DIR/src
git clone https://github.com/madler/zlib zlib_src
cd zlib_src   
git checkout tags/$zlib_version -b branch_$zlib_version

hdf5_version=hdf5-1_12_1
echo " "
echo "Downloading hdf5 version $hdf5_version ... please wait"
echo " "
cd $MY_LOCAL_DIR/src
git clone https://github.com/HDFGroup/hdf5 hdf5_src  
cd hdf5_src
git checkout tags/$hdf5_version -b branch_$hdf5_version

netcdf_c_version=v4.8.1
echo " "
echo "Downloading netcdf-c version $netcdf_c_version ... please wait"
echo " "
cd $MY_LOCAL_DIR/src
git clone http://github.com/Unidata/netcdf-c netcdf-c_src 
cd netcdf-c_src
git checkout tags/${netcdf_c_version} -b branch_${netcdf_c_version}

pnetcdf_version=checkpoint.1.12.2
echo " "
echo "Downloading pnetcdf version $pnetcdf_version ... please wait"
echo " "
cd $MY_LOCAL_DIR/src
git clone https://github.com/Parallel-NetCDF/PnetCDF PnetCDF_src
cd PnetCDF_src
git checkout tags/$pnetcdf_version -b branch_$pnetcdf_version

netcdff_version=v4.5.4
echo " "
echo "Downloading netcdf-fortran version $netcdff_version ... please wait"
echo " "
cd $MY_LOCAL_DIR/src
git clone http://github.com/Unidata/netcdf-fortran netcdf-fortran_src
cd netcdf-fortran_src
git checkout tags/${netcdff_version} -b branch_${netcdff_version} 

#pio_version=pio1_7_1
#pio_version=pio1_9_23
pio_version=pio2_5_4
echo " "
echo "Downloading pio version $pio_version ... please wait"
echo " "
cd $MY_LOCAL_DIR/src
wget https://github.com/NCAR/ParallelIO/releases/download/pio2_5_4/pio-2.5.4.tar.gz
tar xvfz pio-2.5.4.tar.gz
#git clone https://github.com/NCAR/ParallelIO pio_src
#cd pio_src/pio
#git checkout tags/$pio_version -b branch_$pio_version

wps_version=v4.5
echo " "
echo "Downloading ungrib version $wps_version ... please wait"
echo " "
cd $MY_LOCAL_DIR/src
git clone https://github.com/wrf-model/WPS wps_src
cd wps_src
git checkout tags/$wps_version -b branch_$wps_version


cd $MY_LOCAL_DIR


#
# Installing libs...
#



#
# EVENT
#

echo " "
echo "Installing event version $event_version ... please wait"
echo " "
rm -rf $YOUR_INSTALL_ROOT/event_src
cp -r $MY_LOCAL_DIR/src/event_src $YOUR_INSTALL_ROOT
cd $YOUR_INSTALL_ROOT/event_src
mkdir -p ${EDIR}
./configure --prefix=${EDIR}
make
make install
cd $MY_LOCAL_DIR

#
# HWLOC
#

echo " "
echo "Installing hwloc version $hwloc_version ... please wait"
echo " "
rm -rf $YOUR_INSTALL_ROOT/hwloc_src
cp -r $MY_LOCAL_DIR/src/hwloc_src $YOUR_INSTALL_ROOT
cd $YOUR_INSTALL_ROOT/hwloc_src
mkdir -p ${HLDIR}
./configure --prefix=${HLDIR}
make check
make install
cd $MY_LOCAL_DIR


#
# ZLIB
#

echo " "
echo "Installing zlib version $zlib_version ... please wait"
echo " "
rm -rf $YOUR_INSTALL_ROOT/zlib_src
cp -r $MY_LOCAL_DIR/src/zlib_src $YOUR_INSTALL_ROOT
cd $YOUR_INSTALL_ROOT/zlib_src   
mkdir -p ${ZDIR}
./configure --prefix=${ZDIR}
make check
make install
cd $MY_LOCAL_DIR


#
# HDF5
#

echo " "
echo "Installing hdf5 version $hdf5_version ... please wait"
echo " "
rm -rf $YOUR_INSTALL_ROOT/hdf5_src
cp -r $MY_LOCAL_DIR/src/hdf5_src $YOUR_INSTALL_ROOT
cd $YOUR_INSTALL_ROOT/hdf5_src
mkdir -p ${H5DIR}
./configure --enable-parallel --enable-fortran --prefix=${H5DIR} --with-zlib=${ZDIR}
make
make install
cd $MY_LOCAL_DIR


#
# NETCDF-C
#

echo " "
echo "Installing netcdf-c version $netcdf_c_version ... please wait"
echo " "
rm -rf $YOUR_INSTALL_ROOT/netcdf-c_src
cp -r $MY_LOCAL_DIR/src/netcdf-c_src $YOUR_INSTALL_ROOT
cd $YOUR_INSTALL_ROOT/netcdf-c_src
mkdir ${NFDIR}
CPPFLAGS="-I${H5DIR}/include -I$ZDIR/include"
LDFLAGS="-L${H5DIR}/lib -L$ZDIR/lib"
./configure --prefix=${NFDIR}  --enable-netcdf4 --disable-hdf5 --disable-shared
make 
make check
make install
cd $MY_LOCAL_DIR


#
# PNETCDF
#

export LD_LIBRARY_PATH=${H5DIR}/lib:$ZDIR/lib:$NFDIR/lib:$HLDIR/lib:$EDIR/lib:${LD_LIBRARY_PATH}
#export LIBS="-lhwloc -levent_core -levent_pthreads"

echo "ld_library_path=$LD_LIBRARY_PATH"
#echo "libs=$LIBS"

echo " "
echo "Installing pnetcdf version $pnetcdf_version ... please wait"
echo " "
rm -rf $YOUR_INSTALL_ROOT/PnetCDF_src
cp -r $MY_LOCAL_DIR/src/PnetCDF_src $YOUR_INSTALL_ROOT
cd $YOUR_INSTALL_ROOT/PnetCDF_src
autoreconf -i
mkdir $PNDIR
#FC=/opt/ohpc/pub/mpi/openmpi4-gnu9/4.1.1/bin/mpif90
#CC=/opt/ohpc/pub/mpi/openmpi4-gnu9/4.1.1/bin/mpicc
#CXX=/opt/ohpc/pub/mpi/openmpi4-gnu9/4.1.1/bin/mpicxx
#./configure --prefix=$PNDIR \
#                  MPICC=mpicc   MPICXX=mpicxx \
#                  MPIF77=mpif77 MPIF90=mpif90 \
#                  CC=gcc CXX=g++ F77=gfortran FC=gfortran
FC=mpif90
CC=mpicc
CXX=mpicxx
./configure --prefix=$PNDIR
make -j8
make install
cd $MY_LOCAL_DIR
#
#
#
# NETCDF-FORTRAN
#

FC=mpif90
CC=mpicc
#export CC=/opt/ohpc/pub/mpi/openmpi4-gnu9/4.1.1/bin/mpicc
#export FC=/opt/ohpc/pub/mpi/openmpi4-gnu9/4.1.1/bin/mpif90
export CPPFLAGS="-I$H5DIR/include -I$ZDIR/include -I$NFDIR/include"
export LDFLAGS="-L$H5DIR/lib -L$ZDIR/lib -L$NFDIR/lib"
export LD_LIBRARY_PATH=${H5DIR}/lib:$ZDIR/lib:$NFDIR/lib:${LD_LIBRARY_PATH}
export LIBS="-lnetcdf -lhdf5_hl -lhdf5 -lz"

echo "cc=$CC" 
echo "fc=$FC" 
echo "cppflags=$CPPFLAGS" 
echo "ldflags=$LDFLAGS" 
echo "ld_library_path=$LD_LIBRARY_PATH" 
echo "libs=$LIBS"

echo " "
echo "Installing netcdf-fortran version $netcdff_version ... please wait"
echo " "
rm -rf $YOUR_INSTALL_ROOT/netcdf-fortran_src
cp -r $MY_LOCAL_DIR/src/netcdf-fortran_src $YOUR_INSTALL_ROOT
cd $YOUR_INSTALL_ROOT/netcdf-fortran_src
./configure --disable-shared --prefix=${NCDIR}
make
make install
cd $MY_LOCAL_DIR


#
# PIO
#

#export CC=/opt/ohpc/pub/mpi/openmpi4-gnu9/4.1.1/bin/mpicc
#export FC=/opt/ohpc/pub/mpi/openmpi4-gnu9/4.1.1/bin/mpif90
#export CPPFLAGS="-I$PNDIR/include -I$NCDIR/include -I$NFDIR/include"
#export LDFLAGS="-L$PNDIR/lib -L$NCDIR/lib"
#export CFLAGS='-g -Wall'
#export CPPFLAGS="-I$H5DIR/include -I$ZDIR/include -I$NFDIR/include -I$PNDIR/include"
#export LDFLAGS="-L$H5DIR/lib -L$ZDIR/lib -L$NFDIR/lib -L$PNDIR/lib"
#export LD_LIBRARY_PATH=${H5DIR}/lib:$ZDIR/lib:$NFDIR/lib:$PNDIR/lib:${LD_LIBRARY_PATH}
#export LIBS="-lpnetcdf -lnetcdf -lhdf5_hl -lhdf5 -lz"
#export PNETCDF_PATH=$PNDIR
#export NETCDF_PATH=$NFDIR

#export CPPFLAGS="-I/opt/mpi/openmpi/4.1.6.15.1/fortran-gnu/include -I/opt/mpi/openmpi/4.1.6.15.1include"
#export LDFLAGS="-L/opt/mpi/openmpi/4.1.6.15.1/fortran-gnu/lib -L/opt/mpi/openmpi/4.1.6.15.1/lib"
#export LD_LIBRAY_PATH=/opt/mpi/openmpi/4.1.6.15.1/fortran-gnu/lib:/opt/mpi/openmpi/4.1.6.15.1/lib:${LD_LIBRARY_PATH}

FC=mpif90
CC=mpicc

echo " "
echo "Installing pio version $pio_version ... please wait"
echo " "
#autoreconf -i
#./configure --prefix=${PIODIR} --enable-fortran
#./configure --prefix=${PIODIR}
#./configure --prefix=${PIODIR} --enable-pnetcdf --enable-netcdf4
#rm -rf $MY_LOCAL_DIR/lib/pio_src $PIODIR
#cp -r $MY_LOCAL_DIR/src/pio_src $MY_LOCAL_DIR/lib
#cd pio_src/pio   
#rm -rf $MY_LOCAL_DIR/lib/pio-2.5.4.tar.gz $MY_LOCAL_DIR/lib/pio-2.5.4 $PIODIR
rm -rf $YOUR_INSTALL_ROOT/pio-2.5.4 $PIODIR
cp -r $MY_LOCAL_DIR/src/pio-2.5.4 $YOUR_INSTALL_ROOT
cd $YOUR_INSTALL_ROOT/pio-2.5.4
mkdir -p ${PIODIR}
#./configure --prefix=${PIODIR} --enable-fortran
cmake -DCMAKE_INSTALL_PREFIX=$PIODIR -Wno-dev -DCMAKE_C_COMPILER=mpicc -DCMAKE_Fortran_COMPILER=mpif90 -D NetCDF_C_PATH=$NCDIR -D NetCDF_Fortran_PATH=$NFDIR -D PnetCDF_PATH=$PNDIR -D PIO_ENABLE_EXAMPLES=OFF .
make check
make install
cd $MY_LOCAL_DIR


#
# WPS
#

export NETCDF=$NFDIR
echo "NETCDF=$NETCDF"
#./configure --nowrf

echo " "
echo "Installing ungrib version $wps_version ... please wait"
echo " "
rm -rf $YOUR_INSTALL_ROOT/wps_src
cp -r $MY_LOCAL_DIR/src/wps_src $YOUR_INSTALL_ROOT
cd $YOUR_INSTALL_ROOT/wps_src
./configure --build-grib2-libs --nowrf
#./compile ungrib
#module load general/anaconda3/2024.10
#source activate $HOME/conda-env/test-tf
#conda install conda-forge::tcsh
#ln -s /scratch/cptec/eduardo.khamis/conda-env/test-tf/bin/tcsh /scratch/cptec/eduardo.khamis/bin
tcsh ./compile ungrib
cd $MY_LOCAL_DIR



#
# Moving/Copying libs...
#

# Nothing here yet
