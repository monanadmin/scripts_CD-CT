#!/bin/bash 
#-----------------------------------------------------------------------------#
# !SCRIPT: run_poducts
#
# !DESCRIPTION:
#     Script to run the products of pos-processing of MONAN model .
#     
#     Performs the following tasks:
# 
#        o Check all input files before (post-processed files)
#        o Creates the submition script
#        o Submit the products scripts
#        o Veriffy all products generated
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


# Standart directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT; mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_CD-CT;   mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;           mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;             mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;           mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;           mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;               mkdir -p ${EXECS}
#----------------------------------------------------------------------



# Input variables:--------------------------------------
EXP=${1};         #EXP=GFS
RES=${2};         #RES=1024002
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2024012000
FCST=${4};        #FCST=6
#-------------------------------------------------------


# Local variables--------------------------------------
yyyymmddi=${YYYYMMDDHHi:0:8}
hhi=${YYYYMMDDHHi:8:2}
#-------------------------------------------------------
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Prods/logs


#for nh in $(seq 1 ${FCST})
#do 
   nh=2
   yyyymmddhhf=$(date -u +"%Y%m%d%H" -d "${yyyymmddi} ${hhi}:00 ${nh} hours" )
   yyyymmddhhff=$(date -u +"%Y%m%d%H" -d "${yyyymmddi} ${hhi}:00 $((nh+1)) hours" )

rm -f ${DATAOUT}/${YYYYMMDDHHi}/Prods/MONAN_PREC_${EXP}_${YYYYMMDDHHi}_${yyyymmddhhff}.00.00.x${RES}L55.png 
rm -f ${SCRIPTS}/prec.gs
cat << EOGS > ${SCRIPTS}/prec.gs
'reinit'
'set display color white'
'c'
'set gxout shaded'

'sdfopen ${DATAOUT}/${YYYYMMDDHHi}/Post/MONAN_DIAG_G_POS_${EXP}_${YYYYMMDDHHi}_${yyyymmddhhf}.00.00.x${RES}L55.nc'
'sdfopen ${DATAOUT}/${YYYYMMDDHHi}/Post/MONAN_DIAG_G_POS_${EXP}_${YYYYMMDDHHi}_${yyyymmddhhff}.00.00.x${RES}L55.nc'
'set mpdset mres'
'set grads off'

'set lon 276.25 339.5'
'set lat -55.75 14.25'

'pr1=rainc.1+rainnc.1'
'pr25=rainc.2(t=1)+rainnc.2(t=1)'

'set clevs 0.5 1 2 4 8 16 32 64 128'
'set ccols 0 14 11 5 13 10 7 12 2 6'

'd pr25-pr1'
'set gxout contour'

'cbar'
'draw title Previsao de Precipitacao \ MONAN: prod: 2024010100 valid: 2024010102'

'set strsiz 0.15 0.15'
'draw string 7.8 0.3 (mm)'
'set strsiz 0.10 0.10'
'set string 1 l 5'
'draw string 0.1 0.1 MONAN v.0.4.0'


'printim ${DATAOUT}/${YYYYMMDDHHi}/Prods/MONAN_PREC_${EXP}_${YYYYMMDDHHi}_${yyyymmddhhff}.00.00.x${RES}L55.png'
'quit'



EOGS


cat << EOF0 > ${SCRIPTS}/prods.bash 
#!/bin/bash
#SBATCH --job-name=${PRODS_jobname}
#SBATCH --nodes=${PRODS_nnodes}
#SBATCH --ntasks=${PRODS_ncores}
#SBATCH --tasks-per-node=${PRODS_ncpn}
#SBATCH --partition=${PRODS_QUEUE}
#SBATCH --time=${PRODS_walltime}
#SBATCH --output=${DATAOUT}/${YYYYMMDDHHi}/Prods/logs/prods.bash.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/${YYYYMMDDHHi}/Prods/logs/prods.bash.e%j     # File name for standard error output
##SBATCH --exclusive
##SBATCH --mem=500000


ulimit -c unlimited
ulimit -v unlimited
ulimit -s unlimited

. $(pwd)/setenv.bash

cd ${SCRIPTS}

date
time grads -bpcx "run prec.gs"
date


EOF0
chmod a+x ${SCRIPTS}/prods.bash


echo -e  "${GREEN}==>${NC} Submitting MONAN atmosphere model Products and waiting for finish before exit... \n"
echo -e  "${GREEN}==>${NC} Logs being generated at ${DATAOUT}/${YYYYMMDDHHi}/Prods/logs... \n"
echo -e  "sbatch ${SCRIPTS}/prods.bash"
sbatch --wait ${SCRIPTS}/prods.bash
rm -f ${SCRIPTS}/prods.bash
