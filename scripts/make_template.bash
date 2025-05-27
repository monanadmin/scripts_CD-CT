#!/bin/bash
#-----------------------------------------------------------------------------#
# !SCRIPT: run_post
#
# !DESCRIPTION:
#     Script to run the pos-processing of MONAN model over the forecast horizon.
#     
#     Performs the following tasks:
# 
#        o VCheck all input files before
#        o Creates the submition script
#        o Submit the post
#        o Veriffy all files generated
#        
#
#-----------------------------------------------------------------------------#

if [ $# -ne 4 -a $# -ne 1 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} ]EXP_NAME/OP] RESOLUTION LABELI FCST"
   echo ""
   echo "EXP_NAME    :: Forcing: GFS"
   echo "RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)"
   echo "LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100"
   echo "FCST        :: Forecast hours, e.g.: 24 or 36, etc."
   echo ""
   echo "24 hour forcast example:"
   echo "${0} GFS 1024002 2024010100 24"
   echo "${0} GFS   40962 2024010100 48"
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



# Format to HH:MM:SS t_strout (output_interval)
IFS=":" read -r h m s <<< "${t_strout}"
printf -v t_strout "%02d:%02d:%02d" "$h" "$m" "$s"

# Calculating default parameters for different resolutions
if [ $RES -eq 1024002 ]; then  #24Km
   NLAT=721  #180/0.25
   NLON=1441 #360/0.25
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [ $RES -eq 2621442 ]; then  #15Km
   NLAT=1201 #180/0.15
   NLON=2401 #360/0.15
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [ $RES -eq 40962 ]; then  #120Km
   NLAT=150 #180/1.2
   NLON=300 #360/1.2
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
fi
#-------------------------------------------------------

# NLEVS get from t_iso_levels in Registry_isobaric.xml:
if [ -s ${MONANDIR}/src/core_atmosphere/diagnostics/Registry_isobaric.xml ]
then
   NLEV=$(grep "t_iso_levels" ${MONANDIR}/src/core_atmosphere/diagnostics/Registry_isobaric.xml | grep definition | cut -d\" -f4)
else
   NLEV=18
fi

output_interval=${t_strouthor}
nfiles=$(echo "$FCST/$output_interval + 1" | bc)

diag_name_post=MONAN_DIAG_G_POS_${EXP}_${YYYYMMDDHHi}_${YYYYMMDDHHi}.00.00.x${RES}L${NLEV}.nc
diag_name_templ=MONAN_DIAG_G_POS_${EXP}_${YYYYMMDDHHi}_%y4%m2%d2%h2.%n2.00.x${RES}L${NLEV}.nc

rm -fr ${DIRRUN}/qctlinfo.gs
cat > ${DIRRUN}/qctlinfo.gs <<EOGS
'reinit'
'sdfopen ${DATAOUT}/${YYYYMMDDHHi}/Post/${diag_name_post}' 

'q ctlinfo'
say result

'quit'
EOGS
cd ${DIRRUN}
grads -blc "run ${DIRRUN}/qctlinfo.gs" | awk '/dset/,/endvars/' > ${DIRRUN}/qctlinfo.ctl
timectl=$(grep tdef ${DIRRUN}/qctlinfo.ctl | cut -d" " -f4)
sed -i '3a\options template' ${DIRRUN}/qctlinfo.ctl
sed -i "/tdef/c\tdef ${nfiles} linear ${timectl} ${t_stroutmin}mn" ${DIRRUN}/qctlinfo.ctl
sed -i "/dset/c\dset ${DATAOUT}/${YYYYMMDDHHi}/Post/${diag_name_templ}" ${DIRRUN}/qctlinfo.ctl
mv ${DIRRUN}/qctlinfo.ctl ${DATAOUT}/${YYYYMMDDHHi}/Post/${diag_name_post}.template.ctl
rm -fr ${DIRRUN}
