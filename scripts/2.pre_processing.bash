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



#--- Function that shows usage.
function show_usage() {
   echo " Usage: "
   echo ""
   echo " ${0} [-h] [-m12] [-o] [-e EXP ] [-f FCST] [-r RES] [-t YYYYMMDDHH]"
   echo ""
   echo " List of optional flags: "
   echo ""
   echo " -h              -- Shows this message."
   echo " -m12            -- Is this a MONAN run based on 1.2.0-rc and branches derived"
   echo "                    from this version (e.g., feature/monan-757-NF)? This is a"
   echo "                    temporary flag that will be removed once the versions"
   echo "                    containing Noah-MP are merged into the new release. This"
   echo "                    allows the script to manage older code and still run on jaci."
   echo " -o              -- Overwrite static files."
   echo ""
   echo " List of **required** flags when -c is not set: "
   echo ""
   echo " -e EXP          -- meteorological drivers. For example, GFS"
   echo " -f FCST         -- Simulation length in hours, e.g., 24 or 48."
   echo " -r RES          -- grid resolution. Supported options are:"
   echo "                    65536002 (~ 3 km)"
   echo "                    5898242  (~ 10 km)"
   echo "                    2621442  (~ 15 km)"
   echo "                    1024002  (~ 24 km)"
   echo "                    655362   (~ 30 km)"
   echo "                    163842   (~ 60 km)"
   echo "                    40962    (~ 120 km)"
   echo " -t YYYYMMDDHH   -- Initial time. For example if 22 Sept 2025 00 UTC, set it to:"
   echo "                    2025092200"
   echo ""
}
#---~---




#--- Default input variables:
OVERWRITE=false
MONAN_ONETWO=""
EXP=""
RES=""
YYYYMMDDHHi=""
FCST=""
#---~---


#--- Parse arguments.
while [[ ${#} > 0 ]]
do
   key="${1}"
   case ${key} in
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
   -o)
      OVERWRITE=true
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
if [[ "${EXP}"         == "" ]] || [[ "${RES}"         == "" ]] ||
   [[ "${YYYYMMDDHHi}" == "" ]] || [[ "${FCST}"        == "" ]]
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
echo "---- Pre Processing ----"
echo ""


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


if [[ ! -d ${DATAIN}/fixed ]]
then
	echo -e  "${GREEN}==>${NC} copying and linking fixed input data ${SYSTEM_KEYC}... \n"
	mkdir -p ${DATAIN}
	rsync -rv --chmod=ugo=rw ${DIRDADOS}/MONAN_datain/datain/fixed ${DATAIN}
	rsync -rv --chmod=ugo=rwx ${DIRDADOS}/MONAN_datain/execs ${DIRHOMED}
	ln -sf ${DIRDADOS}/MONAN_datain/datain/WPS_GEOG ${DATAIN}
fi


#---~---
#   Create the x1.${RES}.static.nc file. This is normally needed only once, when the file
# does not exist. However, if the files must be recreated for whichever reason, option 
# OVERWRITE forces creation.
#---~---
if ${OVERWRITE} || [[ ! -s ${DATAIN}/fixed/x1.${RES}.static.nc ]]
then
   echo -e "${GREEN}==>${NC} Creating static.bash for submitting init_atmosphere to create x1.${RES}.static.nc...\n"
   time ./make_static.bash ${MONAN_ONETWO} -e ${EXP} -f ${FCST} -r ${RES} -t ${YYYYMMDDHHi}
else
   echo -e "${GREEN}==>${NC} File x1.${RES}.static.nc already exist in ${DATAIN}/fixed.\n"
fi
#---~---


#--- Run the degrib step.
echo -e  "${GREEN}==>${NC} Submitting Degrib...\n"
time ./make_degrib.bash ${MONAN_ONETWO} -e ${EXP} -f ${FCST} -r ${RES} -t ${YYYYMMDDHHi}
#---~---


#--- Run the atmosphere initialisation step.
echo -e  "${GREEN}==>${NC} Submitting Init Atmosphere...\n"
time ./make_initatmos.bash ${MONAN_ONETWO} -e ${EXP} -f ${FCST} -r ${RES} -t ${YYYYMMDDHHi}
#---~---




