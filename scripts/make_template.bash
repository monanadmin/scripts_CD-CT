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
#        o VCheck all input files before
#        o Creates the submition script
#        o Submit the post
#        o Veriffy all files generated
#        
#
#-----------------------------------------------------------------------------#

#--- Function that shows usage.
function show_usage() {
   echo " Usage: "
   echo ""
   echo " ${0} [-h] [-m12] [-v VARTABLE] [-d OUTPUT_DIAG_INT] [-e EXP ] [-f FCST] \\"
   echo "    [-r RES] [-t YYYYMMDDHH]"
   echo ""
   echo " List of optional flags: "
   echo ""
   echo " -h                  -- Shows this message."
   echo " -m12                -- Is this a MONAN run based on 1.2.0-rc and branches"
   echo "                        derived from this version (e.g., feature/monan-757-NF)?"
   echo "                        This is a temporary flag that will be removed once the"
   echo "                        versions containing Noah-MP are merged into the new"
   echo "                        release. This allows the script to manage older code and"
   echo "                        still run on jaci."
   echo " -v VARTABLE         -- Suffix for defining which version of the"
   echo "                        stream_list_atmosphere.diagnostics template to use."
   echo "                        The default is to not use any suffix."
   echo ""
   echo " List of **required** flags: "
   echo ""
   echo " -d OUTPUT_DIAG_INT  -- Output interval for diagnostic. The format must be"
   echo "                        \"HH:MM:SS\""
   echo " -e EXP              -- meteorological drivers. For example, GFS"
   echo " -f FCST             -- Simulation length in hours, e.g., 24 or 48."
   echo " -r RES              -- grid resolution. Supported options are:"
   echo "                        65536002 (~ 3 km)"
   echo "                        5898242  (~ 10 km)"
   echo "                        2621442  (~ 15 km)"
   echo "                        1024002  (~ 24 km)"
   echo "                        655362   (~ 30 km)"
   echo "                        163842   (~ 60 km)"
   echo "                        40962    (~ 120 km)"
   echo " -t YYYYMMDDHH       -- Initial time. For example if 22 Sept 2025 00 UTC,"
   echo "                        set it to: 2025092200"
   echo ""
}
#---~---




#--- Default input variables:
MONAN_ONETWO=""
EXP=""
RES=""
YYYYMMDDHHi=""
FCST=""
OUTPUT_DIAG_INTERVAL=""
VARTABLE=""
#---~---


#--- Parse arguments.
while [[ ${#} > 0 ]]
do
   key="${1}"
   case ${key} in
   -d)
      OUTPUT_DIAG_INTERVAL="${2}"
      shift 2 # Past flag and argument
      ;;
   -e)
      EXP="${2}"
      shift 2 # past flag and argument
      ;;
   -f)
      FCST="${2}"
      shift 2 # past flag and argument
      ;;
   -h)
      show_usage
      exit 0
      ;;
   -m12)
      MONAN_ONETWO="${key}"
      shift 1 # past flag
      ;;
   -r)
      RES="${2}"
      shift 2 # past flag and argument
      ;;
   -t)
      YYYYMMDDHHi="${2}"
      shift 2 # past flag and argument
      ;;
   -v)
      VFIRST=$(echo ${2} | cut -c 1-1)
      case "${VFIRST}" in
         .) VARTABLE="${2}"  ;;
         *) VARTABLE=".${2}" ;;
      esac      
      shift 2 # past flag and argument
      ;;
   *)
      echo ""
      echo " Option \"${key}\" is not valid."
      echo ""
      show_usage
      echo ""
      echo " *** FATAL ERROR! ***"
      echo " Unknown key or key-value argument pair."
      echo ""
      exit 2
      ;;
   esac
done
#---~---



#---~---
#   Make sure all required settings were provided.
#---~---
if [[ "${EXP}"                  == "" ]] || [[ "${RES}"                  == "" ]] ||
   [[ "${YYYYMMDDHHi}"          == "" ]] || [[ "${FCST}"                 == "" ]] ||
   [[ "${OUTPUT_DIAG_INTERVAL}" == "" ]]
then
   echo " This script requires some arguments to be set through flags."
   show_usage
   exit 2
fi
#---~---


#--- Set environment variables exports:
. setenv.bash ${MONAN_ONETWO}
#---~---

echo ""
echo "---- Make Template ----"
echo ""


#--- Set and create standard directories
DIRHOMES=`dirname "$(pwd)"`;           mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_CD-CT;   mkdir -p ${DIRHOMED}  
export SCRIPTS=${DIRHOMES}/scripts;    mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;             mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;           mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;           mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;               mkdir -p ${EXECS}
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
#---~---


# Local variables--------------------------------------
START_DATE_YYYYMMDD="${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}"
START_HH="${YYYYMMDDHHi:8:2}"
maxpostpernode=20    # <------ qtde max de convert_mpas por no!
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#-------------------------------------------------------

#--- Variables for flexible output intervals.
t_strout=${OUTPUT_DIAG_INTERVAL}
t_stroutsec=`echo ${t_strout} | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}'`
t_strouthor=`echo "scale=4; (${t_stroutsec}/60)/60" | bc`
t_stroutmin=`echo "${t_stroutsec}/60" | bc`
#------------------------------------------------------------------------------------

cd ${DIRRUN}


# Format to HH:MM:SS t_strout (output_interval)
IFS=":" read -r h m s <<< "${t_strout}"
printf -v t_strout "%02d:%02d:%02d" "$h" "$m" "$s"

#---~---
# Calculate default parameters for different resolutions.
# ML: The original numbers assumed 1 degree ~ 100 km. Across latitude and near the 
#     Equator, 1 degree ~ 111.2 km, so the regridded data ended up being slightly coarser 
#     than it needed to be. To ensure an average grid mesh in regular lon/lat that is 
#     close to the original resolution, we determine the average resolution based on 
#     the number of points in a full sphere (4*pi steradians), and pick the nearest 
#     integer number of points per degree.
#     delta_xy = sqrt( 4*pi * (180/pi)^2 / NumberOfPoints)
#     PointsPerDegree = round(1/delta_xy)
#     NLON = 360 * PointsPerDegree + 1
#     NLAT = 180 * PointsPerDegree + 1
#---~---
case ${RES} in
5898242)
   #---~---
   #   10 km, use 12 points per degree
   #---~---
   NLAT=2161
   NLON=4321
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
   #---~---
   ;;
2621442)
   #---~---
   #   15 km, use 8 points per degree
   #---~---
   NLAT=1441
   NLON=2881
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
   #---~---
   ;;
1024002)
   #---~---
   #   24 km, use 5 points per degree
   #---~---
   NLAT=901
   NLON=1801
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
   #---~---
   ;;
40962)
   #---~---
   #   120 km, use 1 points per degree
   #---~---
   NLAT=181
   NLON=361
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
   #---~---
   ;;
*)
   #---~---
   #   Unrecognised resolution.
   #---~---
   echo -e "${RED}****** FATAL ERROR ******${NC} \n"
   echo -e "${RED}==>${NC} Provided grid resolution (${RES}) is not recognised.\n"
   echo -e "${RED}==>${NC} ${0} cannot post-process this MONAN simulation.\n"
   exit -1
   #---~---
   ;;
esac
#---~---

# Retrieve N_ISOBARIC_LEV from t_iso_levels in Registry_isobaric.xml:
if [ -s ${MONANDIR}/src/core_atmosphere/diagnostics/Registry_isobaric.xml ]
then
   N_ISOBARIC_LEV=$(grep "t_iso_levels" ${MONANDIR}/src/core_atmosphere/diagnostics/Registry_isobaric.xml | grep definition | cut -d\" -f4)
else
   N_ISOBARIC_LEV=18
fi

output_interval=${t_strouthor}
nfiles=$(echo "$FCST/$output_interval + 1" | bc)

diag_name_post=MONAN_DIAG_G_POS_${EXP}_${YYYYMMDDHHi}_${YYYYMMDDHHi}.00.00.x${RES}L${N_ISOBARIC_LEV}.nc
diag_name_templ=MONAN_DIAG_G_POS_${EXP}_${YYYYMMDDHHi}_%y4%m2%d2%h2.%n2.00.x${RES}L${N_ISOBARIC_LEV}.nc



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

. ${SCRIPTS}/setenv.bash ${MONAN_ONETWO}
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
