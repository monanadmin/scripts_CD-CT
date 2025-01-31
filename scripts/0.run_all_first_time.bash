#!/bin/bash 


#if [ $# -ne 5 ]
#then
#   echo ""
#   echo "Instructions: execute the command below"
#   echo ""
#   echo "${0} GitHubUserRepo EXP_NAME RESOLUTION LABELI FCST"
#   echo ""
#   echo "GitHubUserRepo :: GitHub link for your personal fork, eg: https://github.com/MYUSER/MONAN-Model.git"
#   echo "EXP_NAME       :: Forcing: GFS"
#   echo "RESOLUTION     :: number of points in resolution model grid, e.g: 1024002  (24 km)"
#   echo "LABELI         :: Initial date YYYYMMDDHH, e.g.: 2024010100"
#   echo "FCST           :: Forecast hours, e.g.: 24 or 36, etc."
#   echo ""
#   echo "24 hour forcast example:"
#   echo "${0} https://github.com/MYUSER/MONAN-Model.git GFS 1024002 2024010100 24"
#   echo ""
#   exit
#fi

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



# Input variables:-----------------------------------------------------
github_link="https://github.com/monanadmin/MONAN-Model.git"
monan_branch=release/1.1.0
convertmpas_branch=
EXP=GFS
RES=1024002
YYYYMMDDHHi=2024042000
FCST=240
#----------------------------------------------------------------------


# STEP 1: Installing and compiling the A-MONAN model and utility programs:
time 1.install_monan.bash ${github_link} ${monan_branch}

# STEP 2: Executing the pre-processing fase. Preparing all CI/CC files needed:
time 2.pre_processing.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 

# STEP 3: Executing the Model run:
time 3.run_model.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 

# STEP 4: Executing the Post of Model run:
time 4.run_post.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 

exit
