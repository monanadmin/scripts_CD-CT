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

. functions.bash

if [ $# -ne 4 -a $# -ne 1 ]
then
   print_instructions $0
   exit
fi

if [ $# -eq 1 ]; then
   clean_if_requested "$0" "$1"
   exit $?
fi

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
chmod 775 -R ${DATAIN}
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
   EXIT_CODE=$?
   if [ $EXIT_CODE -ne 0 ]; then
       echo -e "${RED}Error:${NC} make_static.bash failed with exit code $EXIT_CODE."
       exit $EXIT_CODE
   fi
   echo -e  "${GREEN}==>${NC} make_static.bash executed sucessfully!\n"
else
   echo -e "${GREEN}==>${NC} File x1.${RES}.static.nc already exist in ${DATAIN}/fixed.\n"
fi
#----------------------------------------------------------------------------------


# Degrib phase:---------------------------------------------------------------------
echo -e  "${GREEN}==>${NC} make_degrib...\n"
time ./make_degrib.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST}
#----------------------------------------------------------------------------------

EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
      echo -e "${RED}Error:${NC} make_degrib.bash failed with exit code $EXIT_CODE."
      exit $EXIT_CODE
fi
echo -e  "${GREEN}==>${NC} make_degrib.bash executed sucessfully!\n"


# Init Atmosphere phase:------------------------------------------------------------
echo -e  "${GREEN}==>${NC} Submiting Init Atmosphere...\n"
time ./make_initatmos.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST}
#----------------------------------------------------------------------------------

EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
      echo -e "${RED}Error:${NC} make_initatmos.bash failed with exit code $EXIT_CODE."
      exit $EXIT_CODE
fi
echo -e  "${GREEN}==>${NC} Initatmos.bash executed sucessfully!\n"


