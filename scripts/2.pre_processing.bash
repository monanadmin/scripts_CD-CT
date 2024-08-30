#!/bin/bash 
#-----------------------------------------------------------------------------#
# !SCRIPT: pre_processing
#
# !DESCRIPTION:
#     Script to prepare boundary and initials conditions for MONAN model.
#     
#     Performs the following tasks:
# 
#        o Creates topography, land use and static variables
#        o Ungrib GFS data
#        o Interpolates to model the grid
#        o Creates initial and boundary conditions
#        o Creates scripts to run the model and post-processing (CR: to be modified to phase 3 and 4)
#        o Integrates the MONAN model ((CR: to be modified to phase 3)
#        o Post-processing (netcdf for grib2, latlon regrid, crop) (CR: to be modified to phase 4)
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
   echo "                                                                 40962  (120 km)"
   echo "LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100"
   echo "FCST        :: Forecast hours, e.g.: 24 or 36, etc."
   echo ""
   echo "24 hour forecast example for 480km:"
   echo "${0} GFS    2562 2024080800 24"
   echo "24 hour forecast example for 384km:"
   echo "${0} GFS    4002 2024080800 24"
   echo "24 hour forecast example for 240km:"
   echo "${0} GFS   10242 2024080800 24"
   echo "48 hour forecast example for 120km:"
   echo "${0} GFS   40962 2024010100 48"


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
FCST=${4};        #FCST=24
#-------------------------------------------------------


# Local variables--------------------------------------
# Calculating CIs and final forecast dates in model namelist format:
yyyymmddi=${YYYYMMDDHHi:0:8}
hhi=${YYYYMMDDHHi:8:2}
yyyymmddhhf=$(date +"%Y%m%d%H" -d "${yyyymmddi} ${hhi}:00 ${FCST} hours" )
final_date=${yyyymmddhhf:0:4}-${yyyymmddhhf:4:2}-${yyyymmddhhf:6:2}_${yyyymmddhhf:8:2}.00.00
#-------------------------------------------------------


echo -e  "${GREEN}==>${NC} Scripts_CD-CT last commit: \n"
git log -1 --name-only
git branch | head -1


if [ ! -d ${DATAIN}/fixed ]
then
   echo "Please download the tgz data, untar it into the datain directory:"
   echo "datain/fixed"
   echo "datain/WPS_GEOG"
   echo ""
   echo "wget https://ftp.cptec.inpe.br/pesquisa/dmdcc/volatil/Renato/scripts_CD-CT_datain.tgz"
   exit
fi

if [ ! -d ${DATAIN}/WPS_GEOG ]
then
   echo "Please download the tgz data, untar it into the datain directory:"
   echo "datain/fixed"
   echo "datain/WPS_GEOG"
   echo ""
   echo "wget https://ftp.cptec.inpe.br/pesquisa/dmdcc/volatil/Renato/scripts_CD-CT_datain.tgz"
   exit
fi


# Creating the x1.${RES}.static.nc file once, if does not exist yet:---------------
if [ ! -s ${DATAIN}/fixed/x1.${RES}.static.nc ]
then
   echo -e "${GREEN}==>${NC} Creating static.bash for submiting init_atmosphere to create x1.${RES}.static.nc...\n"
   time ./make_static.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST}
else
   echo -e "${GREEN}==>${NC} File x1.${RES}.static.nc already exist in ${DATAIN}/fixed.\n"
fi
#----------------------------------------------------------------------------------



# Degrib phase:---------------------------------------------------------------------
echo -e  "${GREEN}==>${NC} Submiting Degrib...\n"
time ./make_degrib.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST}
#----------------------------------------------------------------------------------

exit

# Init Atmosphere phase:------------------------------------------------------------
echo -e  "${GREEN}==>${NC} Submiting Init Atmosphere...\n"
time ./make_initatmos.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST}
#----------------------------------------------------------------------------------




