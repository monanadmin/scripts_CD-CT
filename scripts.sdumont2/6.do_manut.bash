#!/bin/bash 
#-----------------------------------------------------------------------------#
# !SCRIPT: do_manut
#
# !DESCRIPTION:
#     Script that maintains the MONAN model suite healthy.
#     
#     Performs the following tasks:
# 
#        o Feeds public areas (FTP) with important files (figures, outputs,
#           clippings, etc.)
#        o Removes temporary files with no value that are eventually generated 
#           during integration.
#        o Performs maintenance on the area occupied by the model, moving old 
#           outputs to their destination area.
#        
#
#-----------------------------------------------------------------------------#


if [ $# -ne 4 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} EXP_NAME RESOLUTION LABELI FCST"
   echo ""
   echo "EXP_NAME    :: Forcing: GFS"
   echo "            :: Others options to be added later..."
   echo "RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)"
   echo "LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100"
   echo "FCST        :: Forecast hours, e.g.: 24 or 36, etc."
   echo ""
   echo "24 hour forcast example:"
   echo "${0} GFS 1024002 2024010100 24"
   echo ""

   exit
fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash


# Standart directories variables:----------------------
DIRHOME=${DIRWORK}/../../MONAN;  mkdir -p ${DIRHOME}
SCRIPTS=${DIRHOME}/scripts;      mkdir -p ${SCRIPTS}
DATAIN=${DIRHOME}/datain;        mkdir -p ${DATAIN}
DATAOUT=${DIRHOME}/dataout;      mkdir -p ${DATAOUT}
SOURCES=${DIRHOME}/sources;      mkdir -p ${SOURCES}
EXECS=${DIRHOME}/execs;          mkdir -p ${EXECS}
#-------------------------------------------------------


# Input variables:--------------------------------------
EXP=${1};         #EXP=GFS
RES=${2};         #RES=1024002
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2024012000
FCST=${4};        #FCST=24
#-------------------------------------------------------
cp -f setenv.bash ${SCRIPTS}


# Local variables--------------------------------------
#-------------------------------------------------------


# TODO compress all output files

# +cat > Compress_exe.sh <<EOF0
# +#!/bin/bash
# +#SBATCH --job-name=Compress
# +#SBATCH --nodes=1
# +#SBATCH --partition=PESQ3 
# +#SBATCH --tasks-per-node=1
# +#SBATCH --time=24:00:00
# +#SBATCH --output=${LOGDIR}/my_job_compress.o%j    # File name for standard output
# +#SBATCH --error=${LOGDIR}/my_job_compress.e%j     # File name for standard error output
# +#SBATCH --exclusive
# +
# +echo -e  "Compressing post processed diagnostics file...\n" >> ${LOG_FILE} 2>&1
# +tar -cf - diagnostics_${START_DATE_YYYYMMDD}.nc | xz -9 -c - > diagnostics_${START_DATE_YYYYMMDD}.tar.xz
# +
# +#echo -e  "Compressing all /monanprd/diag*.nc files...\n" >> ${LOG_FILE} 2>&1
# +#tar -cf - ${EXPDIR}/monanprd | xz -9 -c - > monanprd_${START_DATE_YYYYMMDD}.tar.xz
# +
# +exit 0
# +EOF0
# +
# +chmod +x Compress_exe.sh


