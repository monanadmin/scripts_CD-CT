#!/bin/bash


#--- Function that shows usage.
function show_usage() {
   echo " Usage: "
   echo ""
   echo " ${0} [-o] [-d OUTPUT_DIAG_INT] [-e EXP ] [-f00 FCST_ZERO] [-f12 FCST_TWELVE] \\"
   echo "    [-i INPUT_PATH] [-l NLEV] [-r RES] [-ti YYYYMMDDi] [-tf YYYYMMDDf] \\"
   echo "    [-v VARTABLE]"
   echo ""
   echo " List of optional flags: "
   echo " -d OUTPUT_DIAG_INT  -- Output interval for diagnostic. The format must be"
   echo "                        \"HH:MM:SS\"."
   echo " -e EXP              -- Meteorological drivers. For example, GFS"
   echo " -f00 FCST_ZERO      -- Simulation length in hours for runs starting at 00 UTC"
   echo "                        e.g., 24 or 48."
   echo " -f12 FCST_TWELVE    -- Simulation length in hours for runs starting at 12 UTC"
   echo "                        e.g., 24 or 48."
   echo " -i INPUT_PATH       -- Path containing input data for MONAN. If left empty, the"
   echo "                        default path defined in setenv.bash will be used"
   echo " -l NLEV             -- Number of vertical levels for the output."
   echo " -o                  -- Overwrite static files. If set, this will be done only"
   echo "                        once."
   echo " -r RES              -- grid resolution. Supported options are:"
   echo "                        5898242 (~ 10 km)"
   echo "                        2621442 (~ 15 km)"
   echo "                        1024002 (~ 24 km)"
   echo "                        40962   (~ 120 km)"
   echo " -ti YYYYMMDDi       -- First initial date to run the script. For example if the"
   echo "                        first run's initial time is on 22 Sept 2025, the"
   echo "                        argument should be 20250922."
   echo " -tf YYYYMMDDf       -- Last initial date to run the script. For example if the"
   echo "                        last run's initial time is on 31 Dec 2025, the"
   echo "                        argument should be 20251231."
   echo " -v VARTABLE         -- Suffix for defining which version of the"
   echo "                        stream_list_atmosphere.diagnostics template to use."
   echo "                        The default is to not use any suffix."
   echo ""
   echo " All settings can be defined directly in the script."
   echo ""
}
#---~---


#--- Set environment variables exports:
. setenv.bash
#---~---




#--- Default input variables:
STEP=1
CLEAN=""
OVERWRITE=""
github_link_MONAN="https://github.com/monanadmin/MONAN-Model.git"
tag_or_branch_name_MONAN="release/1.4.1-rc"
github_link_CONVERT_MPAS="https://github.com/monanadmin/convert_mpas.git"
tag_or_branch_name_CONVERT_MPAS="release/1.2.0"
EXP="GFS"
INPUT_PATH=""
RES=1024002
YYYYMMDDi=2024100100
YYYYMMDDf=2024100500
FCST_ZERO=240
FCST_TWELVE=120
NLEV=55
OUTPUT_DIAG_INTERVAL="03:00:00"
VARTABLE=""
#---~---


#--- Parse arguments.
while [[ ${#} > 0 ]]
do
   key="${1}"
   case ${key} in
   -c)
      CLEAN="-c"
      shift 1 # Past flag
      ;;
   -d)
      OUTPUT_DIAG_INTERVAL="${2}"
      shift 2 # Past flag and argument
      ;;
   -e)
      EXP="${2}"
      shift 2 # past flag and argument
      ;;
   -f00)
      FCST_ZERO="${2}"
      shift 2 # past flag and argument
      ;;
   -f12)
      FCST_TWELVE="${2}"
      shift 2 # past flag and argument
      ;;
   -i)
      INPUT_PATH="${2}"
      shift 2 # Past flag and argument
      ;;
   -l)
      NLEV="${2}"
      shift 2 # Past flag and argument
      ;;
   -o)
      OVERWRITE="-o"
      shift 1 # past flag
      ;;
   -r)
      RES="${2}"
      shift 2 # past flag and argument
      ;;
   -s)
      STEP="${2}"
      shift 2 # past flag and argument
      ;;
   -ti)
      YYYYMMDDHHi="${2}"
      shift 2 # past flag and argument
      ;;
   -tf)
      YYYYMMDDHHf="${2}"
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
      echo "Unknown key-value argument pair."
      show_usage
      exit 2
      ;;
   esac
done
#---~---



#--- If INPUT_PATH is provided, replace the path in setenv.bash
if [[ "${INPUT_PATH}" != "" ]] && [[ -d "${INPUT_PATH}" ]]
then
   sed -i.bck "s,^export DIRDADOS=.*,export DIRDADOS=${INPUT_PATH},g" ${SCRIPTS}/setenv.bash
   /bin/rm -f ${SCRIPTS}/setenv.bash.bck
fi
#---~---


# Input variables:-----------------------------------------------------
DIR_DADOS=/mnt/beegfs/monan/users/renato/issues/ecflow-PREOPER/SCRATCHOUT; mkdir -p ${DIR_DADOS}
DIRFLUSHOUT=/mnt/beegfs/monan/users/renato/issues/trashout; mkdir -p ${DIRFLUSHOUT}
#----------------------------------------------------------------------


#--- Make sure VARTABLE has the leading "-v" if not empty.
if [[ "${VARTABLE}" == "" ]]
then
   dv_VARTABLE=""
else
   dv_VARTABLE="-v ${VARTABLE}"
fi
#---~---


YYYYMMDD=${YYYYMMDDi}
while [ ${YYYYMMDD} -le ${YYYYMMDDf} ]
do
   HH_LIST="00 12"
   for HH in ${HH_LIST}
   do
      YYYYMMDDHHi="${YYYYMMDD}${HH}"
      case ${HH} in
         00) FCST=${FCST_ZERO}   ;;
         12) FCST=${FCST_TWELVE} ;;
      esac

      # Set arguments.
      ARGS_TWO="${OVERWRITE} -e ${EXP} -f ${FCST} -r ${RES} -t ${YYYYMMDDHHi}"
      ARGS_THREE="${dv_VARTABLE} -d ${OUTPUT_DIAG_INTERVAL} -e ${EXP}"
      ARGS_THREE="${ARGS_THREE} -f ${FCST} -l ${NLEV} -r ${RES} -t ${YYYYMMDDHHi}"
      ARGS_FOUR="${dv_VARTABLE} -d ${OUTPUT_DIAG_INTERVAL} -e ${EXP} -f ${FCST}"
      ARGS_FOUR="${ARGS_FOUR} -l ${NLEV} -r ${RES} -t ${YYYYMMDDHHi}"
   
      # Run scripts
      echo "${SCRIPTS}/2.pre_processing.bash ${ARGS_TWO}"
      ${SCRIPTS}/2.pre_processing.bash       ${ARGS_TWO}
      echo "${SCRIPTS}/3.run_model.bash      ${ARGS_THREE}"
      ${SCRIPTS}/3.run_model.bash            ${ARGS_THREE}
      echo "${SCRIPTS}/4.run_post.bash       ${ARGS_FOUR}"
      ${SCRIPTS}/4.run_post.bash             ${ARGS_FOUR}

      # Final data output directory:
      mkdir -p ${DIRFLUSHOUT}/${YYYYMMDDHHi}/
      # Copy post:
      cp -fr ${DIRSCRIPTDADOS}/dataout/${YYYYMMDDHHi}/Post/* ${DIRFLUSHOUT}/${YYYYMMDDHHi}/
      # Remove all output files from the original output diretory dataout:
      rm -fr ${DIRSCRIPTDADOS}/dataout/${YYYYMMDDHHi}
      rm -fr ${DIRSCRIPTDADOS}/datain/${YYYYMMDDHHi}  

      # No need to overwrite static fields after the first iteration
      OVERWRITE=""
   done

   # Update time
   YYYYMMDD=$(date -u +%Y%m%d -d "${YYYYMMDD} 1 day") 
done
