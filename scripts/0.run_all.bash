#!/bin/bash

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
github_link="https://github.com/monanadmin/MONAN-Model.git"   # Switch to your fork when you need to make changes or develop the model.
monan_branch=2.0.0-rc
convertmpas_branch=1.2.0
EXP=GFS                    # Options: GFS or ERA
RES=655362                 # Options-Global: 40962=120km; 163842=60km; 655362=30Km; 1024002=24km; 2621442=15Km; 5898242=10Km
                           # Options-Regional: 655362.REG.AMS_CAR=30km; 5898242.REG.AMS_CAR=10km; 23592962.REG.AMS_CAR=5km
YYYYMMDDHHi=2026080100     # Check the available dates for the initial and boundary conditions (regional), especially for ERA5 data.
FCST=24
#----------------------------------------------------------------------

# STEP 1: Installing and compiling the A-MONAN model and utility programs:
time ${SCRIPTS}/1.install_monan.bash ${github_link} ${monan_branch} ${convertmpas_branch}
#exit

# STEP 2: Executing the pre-processing fase. Preparing all CI/CC files needed:
time ${SCRIPTS}/2.pre_processing.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 
#exit

# STEP 3: Executing the Model run:
time ${SCRIPTS}/3.run_model.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 
#exit

# STEP 4: Executing the Post of Model run:
time ${SCRIPTS}/4.run_post.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 
#exit
