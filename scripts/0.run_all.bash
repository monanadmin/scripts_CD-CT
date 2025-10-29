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
monan_branch=release/1.4.1-rc
convertmpas_branch=release/1.2.0
EXP=ERA5
YYYYMMDDHHi=2007062200
FCST=72
MESH=lat_-35_lon_-55_oradius_2600_iradius_2000_margin_600_hres_50_lres_250.region
RES=50 #3
#----------------------------------------------------------------------


# STEP 1: Installing and compiling the A-MONAN model and utility programs:
#time ${SCRIPTS}/1.install_monan.bash ${github_link} ${monan_branch} ${convertmpas_branch}
#exit

# STEP 2: Generating mesh. Preparing all CI/CC files needed:
time ${SCRIPTS}/2.create_mesh.bash
#exit

# STEP 3: Executing the pre-processing fase. Preparing all CI/CC files needed:time ${SCRIPTS}/3.pre_processing.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} ${MESH} 
#time ${SCRIPTS}/3.pre_processing.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} 
#exit

# STEP 4: Executing the Model run:
#time ${SCRIPTS}/4.run_model.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${RES} 
#exit

# STEP 5: Executing the Post of Model run:
#time ${SCRIPTS}/5.run_post.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${RES}
#$exit

#time ${SCRIPTS}/make_template.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST}
