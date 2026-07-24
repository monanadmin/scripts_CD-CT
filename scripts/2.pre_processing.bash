#!/bin/bash 
umask 022
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

if [ $# -ne 4 -a $# -ne 1 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} EXP_NAME/OP RESOLUTION LABELI FCST"
   echo ""
   echo "EXP_NAME    :: Forcing: GFS"
   echo "            :: Others options to be added later..."
   echo "RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)"
   echo "                                                                 40962  (120 km)"
   echo "LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100"
   echo "FCST        :: Forecast hours, e.g.: 24 or 36, etc."
   echo ""
   echo "24 hour forecast example for 24km:"
   echo "${0} GFS 1024002 2024010100 24"
   echo "48 hour forecast example for 120km:"
   echo "${0} GFS   40962 2024010100 48"
   echo ""

   exit
fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash


echo ""
echo "---- Pre Processing ----"
echo ""


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
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#-------------------------------------------------------



echo -e  "${GREEN}==>${NC} Scripts_CD-CT last commit: \n"
git log | head -1


if [ ! -d ${DATAIN}/fixed ]
then
	echo -e  "${GREEN}==>${NC} copying and linking fixed input data ${SYSTEM_KEYC}... \n"
	mkdir -p ${DATAIN}
	rsync -rv --chmod=ugo=rw ${DIRDADOS}/MONAN_datain/datain/fixed ${DATAIN}
	rsync -rv --chmod=ugo=rwx ${DIRDADOS}/MONAN_datain/execs ${DIRHOMED}
	ln -sf ${DIRDADOS}/MONAN_datain/datain/WPS_GEOG ${DATAIN}
fi


# Building MP_THOMPSON DBL tables
echo ""
echo -e  "${GREEN}==>${NC} Building MP_THOMPSON DBL tables ...\n"

files_needed=("${DATAIN}/fixed/MP_THOMPSON_QRacrQG_DATA.DBL" "${DATAIN}/fixed/MP_THOMPSON_QRacrQS_DATA.DBL" "${DATAIN}/fixed/MP_THOMPSON_freezeH2O_DATA.DBL" "${DATAIN}/fixed/MP_THOMPSON_QIautQS_DATA.DBL")

if [ ! -s ${DATAIN}/fixed/MP_THOMPSON_QRacrQG_DATA.DBL ]
then
   echo -e  "${GREEN}==>${NC} This calculation can take around 2 minutes on a supercomputer...\n"

   rm -f ${EXECS}/MP_THOMPSON_*_DATA.DBL
   rm -f ${DATAIN}/fixed/MP_THOMPSON_*_DATA.DBL

   cd ${EXECS}
   ${EXECS}/build_tables

   mv ${EXECS}/MP_THOMPSON_QRacrQG_DATA.DBL    ${DATAIN}/fixed
   mv ${EXECS}/MP_THOMPSON_QRacrQS_DATA.DBL    ${DATAIN}/fixed
   mv ${EXECS}/MP_THOMPSON_freezeH2O_DATA.DBL  ${DATAIN}/fixed
   mv ${EXECS}/MP_THOMPSON_QIautQS_DATA.DBL    ${DATAIN}/fixed

   chmod 755 ${DATAIN}/fixed/MP_THOMPSON_*_DATA.DBL
   chgrp $USER ${DATAIN}/fixed/MP_THOMPSON_*_DATA.DBL

   # verify here if the tables were created 
   for file in "${files_needed[@]}"
   do
     if [ -s "${file}" ] ; then
       echo ""
       echo -e "${GREEN}==>${NC} File ${file} generated sucessfully in ${EXECS} and moved to ${DATAIN}/fixed!"
       echo
     else
       echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"   
       echo -e  "${RED}==>${NC} [${0}] An error occurred during MP_THOMPSON build_tables. At least the file ${file} was not generated. \n"
       exit -1
     fi
   done
else
   echo -e "${GREEN}==>${NC} MP_THOMPSON DBL tables already exist in ${DATAIN}/fixed!"
fi


# Copying NoahmpTable.TBL from source to datain folder
echo ""
echo -e "${GREEN}==>${NC} Copying NoahmpTable.TBL from source code to datain fixed folder ...\n"

if [ ! -s ${DATAIN}/fixed/NoahmpTable.TBL ]
then
   if [ -s ${MONANDIR}/src/core_atmosphere/physics/physics_noahmp/parameters/NoahmpTable.TBL ]; then
      cp -f ${MONANDIR}/src/core_atmosphere/physics/physics_noahmp/parameters/NoahmpTable.TBL ${DATAIN}/fixed
      chmod 755 ${DATAIN}/fixed/NoahmpTable.TBL
   else
      echo -e "${RED}==>${NC} File NoahmpTable.TBL not found in ${MONANDIR}. Please run script 1.install_monan.bash first. \n"
      exit -1
   fi
else
   echo -e "${GREEN}==>${NC} File NoahmpTable.TBL already exist in ${DATAIN}/fixed.\n"
fi

#TODO: EGK - Verify if necessary data for NOAH-MP soil colour pre-processing is present in datain folder
echo -e "${GREEN}==>${NC} Verifying if clm_soilcolour_21class_30s exist in datain WPS_GEOG folder for running NOAH-MP model with MONAN soil colour table activated ...\n"

if [ ! -d ${DATAIN}/WPS_GEOG/clm_soilcolour_21class_30s/ ]
then
   mkdir -p ${DATAIN}/WPS_GEOG
   cd ${DATAIN}/WPS_GEOG
   echo -e "${GREEN}==>${NC} downloading clm_soilcolour_21class_30s/ folder...\n"
# needs to download data from MONAN dataserver or some mirror... 
#   rm -f ${DATAIN}/WPS_GEOG/wget-log*
#   wget https://...
#   ln -sf ${DIRDADOS}/MONAN_datain/datain/WPS_GEOG/clm_soilcolour_21class_30s ${DATAIN}/WPS_GEOG
else
   echo -e "${GREEN}==>${NC} Folder clm_soilcolour_21class_30s already exist in ${DATAIN}/WPS_GEOG.\n"
fi


# moving back to scripts folder
cd ${SCRIPTS}


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
echo -e  "${GREEN}==>${NC} Running Degrib:\n"
time ./make_degrib.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST}
#----------------------------------------------------------------------------------




# Init Atmosphere phase:------------------------------------------------------------
echo -e  "${GREEN}==>${NC} Running Init Atmosphere...\n"
time ./make_initatmos.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST}
#----------------------------------------------------------------------------------




