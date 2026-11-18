#!/bin/bash
set -e
trap 'echo -e "\n${RED}==>${NC} $(basename "$0") failed.\n"' ERR

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash

# Standart directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/${myDIR}; mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/${myDIR};   mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;           mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;             mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;           mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;           mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;               mkdir -p ${EXECS}
#----------------------------------------------------------------------

# Input variables:-----------------------------------------------------
github_link_MONAN="https://github.com/monanadmin/MONAN-Model.git"   # Switch to your fork when you need to make changes or develop the model.
github_link_MPASSIT="https://github.com/monanadmin/MONAN-MPASSIT.git"
monan_branch=2.0.0-rc   #1.4.5
convertmpas_branch=1.2.0
mpassit_branch=1.0.0
EXP=GFS                    # (EXP) Options: GFS or ERA.
RES=655362                 # (RES_MESH) Options-Global:    40962 = 120km; 
                           #                              163842 =  60km;
			   #                              655362 =  30Km;
			   #                             1024002 =  24km;
			   #                             2621442 =  15Km;
			   #                             5898242 =  10Km.
			   #            Options-Regional (default): 30km_LAC = 30km Latin America and the Caribbean (excl. Mexico);
			   #                                        10km_LAC = 10km Latin America and the Caribbean (excl. Mexico);
			   #                                        05km_LAC = 05km Latin America and the Caribbean (excl. Mexico).
			   #                                        <your_mesh> saved in 'datain/fixed' (x1.<your_mesh>).
YYYYMMDDHHi=2026080200     # (LABELI) Check the available dates for the initial and boundary conditions (regional), especially for ERA5 data.
FCST=24                    # (FCST).
#----------------------------------------------------------------------

# STEP 1: Installing and compiling the A-MONAN model and utility programs:
#time ${SCRIPTS}/1.install_monan.bash ${github_link_MONAN} ${monan_branch} ${convertmpas_branch}
time ${SCRIPTS}/1.install_MPASSIT.bash ${github_link_MPASSIT} ${mpassit_branch} ${mpassit_branch}
#exit

# STEP 2: Executing the pre-processing fase. Preparing all CI/CC files needed:
time ${SCRIPTS}/2.pre_processing.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 
#exit

# STEP 3: Executing the Model run:
time ${SCRIPTS}/3.run_model.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 
#exit

# STEP 4: Executing the Post of Model run:
#time ${SCRIPTS}/4.run_post_ConvertMPAS.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 
time ${SCRIPTS}/4.run_post_MPASSIT.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 
