#!/bin/bash 
umask 022
#-----------------------------------------------------------------------------#
# !SCRIPT: run_post
#
# !DESCRIPTION:
#     Script to run the pos-processing of MONAN model over the forecast horizon.
#     
#     Performs the following tasks:
# 
#        o Check all input files before
#        o Creates the submission script
#        o Submit the post
#        o Verify all files generated
#        
#
#-----------------------------------------------------------------------------#

if [ $# -ne 4 -a $# -ne 1 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} EXP RESOLUTION LABELI FCST"
   echo ""
   echo "EXP         :: Initial or lateral boundary condition dataset (GFS or ERA)"
   echo "RESOLUTION  :: Number of horizontal grid cells (global) or regional mesh identifier (e.g., 1024002 for the ~24 km mesh)"
   echo "LABELI      :: Forecast initialization date and time (YYYYMMDDHH), e.g., 2026080100"
   echo "FCST        :: Forecast length in hours (e.g., 24, 36, 48, etc.)"
   echo ""
   echo "Example of a 24-hour forecast:"
   echo "${0} GFS 1024002 2026080100 24"
   echo ""
   exit
fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash

echo ""
echo "---- Make Template ----"
echo ""


# Standart directories variables:---------------------------------------
DIRHOMES=$(dirname "$(pwd)");          mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_CD-CT;   mkdir -p ${DIRHOMED}  
export SCRIPTS=${DIRHOMES}/scripts;    mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;             mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;           mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;           mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;               mkdir -p ${EXECS}
#----------------------------------------------------------------------


# Input variables:--------------------------------------
EXP=${1};         #EXP=GFS
RES=${2};         #RES=1024002
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2024042000
FCST=${4};        #FCST=40
#-------------------------------------------------------
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Post/logs


# Local variables--------------------------------------
START_DATE_YYYYMMDD="${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}"
START_HH="${YYYYMMDDHHi:8:2}"
maxpostpernode=20    # <------ qtde max de convert_mpas por no!
VARTABLE=".OPER"
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
N_MODEL_LEV=55
#-------------------------------------------------------

# Variables for flex outpout interval from streams.atmosphere------------------------
t_strout=$(cat ${SCRIPTS}/namelists/streams.atmosphere.TEMPLATE | sed -n '/<stream name="diagnostics"/,/<\/stream>/s/.*output_interval="\([^"]*\)".*/\1/p')
t_stroutsec=$(echo ${t_strout} | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}')
t_strouthor=$(echo "scale=4; (${t_stroutsec}/60)/60" | bc)
t_stroutmin=$(echo "${t_stroutsec}/60" | bc)
#------------------------------------------------------------------------------------

cd ${DIRRUN}

# Format to HH:MM:SS t_strout (output_interval)
IFS=":" read -r h m s <<< "${t_strout}"
printf -v t_strout "%02d:%02d:%02d" "$h" "$m" "$s"

# NLEVS get from t_iso_levels in Registry_isobaric.xml:
if [ -s ${MONANDIR}/src/core_atmosphere/diagnostics/Registry_isobaric.xml ]
then
   NLEV=$(grep "t_iso_levels" ${MONANDIR}/src/core_atmosphere/diagnostics/Registry_isobaric.xml | grep definition | cut -d\" -f4)
else
   NLEV=18
fi

output_interval=${t_strouthor}
nfiles=$(echo "$FCST/$output_interval + 1" | bc)

# Definindo G ou R no MONAN_DIAG
if [[ $MODERUN == "R" ]]; then
   RORG=R
elif [[ $MODERUN == "G" ]]; then
   RORG=G
else
   echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
   echo -e  "${RED}==>${NC} Make post template phase fails! Please select MODERUN=R (Regional) or MODERUN=G (Global) in 'setenv.bash'.\n"
   echo -e  "${RED}==>${NC} Exiting script. \n"
   exit -1
fi

diag_name_post=MONAN_DIAG_${RORG}_POS_${EXP}_${YYYYMMDDHHi}_${YYYYMMDDHHi}.00.00.x${RES}L${N_MODEL_LEV}.nc
diag_name_templ=MONAN_DIAG_${RORG}_POS_${EXP}_${YYYYMMDDHHi}_%y4%m2%d2%h2.%n2.00.x${RES}L${N_MODEL_LEV}.nc


rm -fr ${DIRRUN}/qctlinfo.gs
cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}

chmod 755 ${DATAOUT}/${YYYYMMDDHHi}/Post/*
cat > ${DIRRUN}/qctlinfo.gs <<EOGS
'reinit'
'sdfopen ${DATAOUT}/${YYYYMMDDHHi}/Post/${diag_name_post}' 

'q ctlinfo'
say result

'quit'
EOGS


cd ${DIRRUN}

. ${SCRIPTS}/setenv.bash
chmod 755 *


grads -blc "run ${DIRRUN}/qctlinfo.gs" | awk '/dset/,/endvars/' > ${DIRRUN}/qctlinfo.ctl
chmod 755 ${DIRRUN}/qctlinfo.ctl


timectl=$(grep tdef ${DIRRUN}/qctlinfo.ctl | cut -d" " -f4)
sed -i '3a\options template' ${DIRRUN}/qctlinfo.ctl
sed -i "/tdef/c\tdef ${nfiles} linear ${timectl} ${t_stroutmin}mn" ${DIRRUN}/qctlinfo.ctl
sed -i "/dset/c\dset ^${diag_name_templ}" ${DIRRUN}/qctlinfo.ctl

chmod 755 ${DIRRUN}/*
mv ${DIRRUN}/qctlinfo.ctl ${DATAOUT}/${YYYYMMDDHHi}/Post/${diag_name_post}.template.ctl
rm -fr ${DIRRUN}
