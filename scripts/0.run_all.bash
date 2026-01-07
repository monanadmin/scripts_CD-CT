#!/bin/bash 




#--- Function that shows usage.
function show_usage() {
   echo " Usage: "
   echo ""
   echo " ${0} [-c] [-o] [-bc TAG_CONVERT_MPAS] [ -bm TAG_MONAN ] [-d OUTPUT_DIAG_INT] \\"
   echo "    [-e EXP ] [-f FCST] [-gc GIT_CONVERT_MPAS] [-gm GIT_MONAN ] [-i INPUT_PATH] \\"
   echo "    [-l NLEV] [-r RES] [-s STEP] [-t YYYYMMDDHH] [-v VARTABLE]"
   echo ""
   echo " List of optional flags: "
   echo ""
   echo " -bc TAG_CONVERT     -- branch or tag name of the MONAN repository. For example:"
   echo "                        \"develop\". This is used only by step 1."
   echo " -bm TAG_MONAN       -- branch or tag name of the MONAN repository. For example:"
   echo "                        \"develop\". This is used only by step 1."
   echo " -c                  -- Clean files from previous runs. This is used by steps" 
   echo "                        2 and 3."
   echo " -d OUTPUT_DIAG_INT  -- Output interval for diagnostic. The format must be"
   echo "                        \"HH:MM:SS\". This is used by steps 3 and 4."
   echo " -e EXP              -- Meteorological drivers. For example, GFS"
   echo " -f FCST             -- Simulation length in hours, e.g., 24 or 48."
   echo " -gc GIT_CONVERT     -- GitHub handle for MONAN. For example:"
   echo "                        https://github.com/monanadmin/MONAN-Model.git"
   echo "                        This is used only by step 1."
   echo " -gm GIT_MONAN       -- GitHub handle for MONAN. For example:"
   echo "                        https://github.com/monanadmin/MONAN-Model.git"
   echo "                        This is used only by step 1."
   echo " -i INPUT_PATH       -- Path containing input data for MONAN. If left empty, the"
   echo "                        default path defined in setenv.bash will be used"
   echo " -l NLEV             -- Number of vertical levels for the output. This is used"
   echo "                        by steps 3 and 4."
   echo " -o                  -- Overwrite static files. This is used only by step 2."
   echo " -r RES              -- grid resolution. Supported options are:"
   echo "                        5898242 (~ 10 km)"
   echo "                        2621442 (~ 15 km)"
   echo "                        1024002 (~ 24 km)"
   echo "                        40962   (~ 120 km)"
   echo " -s STEP             -- Step to run. Options are:"
   echo "                        1 - Compile MONAN executables."
   echo "                        2 - Run pre-processing."
   echo "                        3 - Run atmospheric model."
   echo "                        4 - Run post-processing."
   echo "                        0 - Run all steps 1-4."
   echo " -t YYYYMMDDHH       -- Initial time. For example if 22 Sept 2025 00 UTC, the"
   echo "                        argument should be 2025092200. This is used by steps"
   echo "                        2, 3 and 4."
   echo " -v VARTABLE         -- Suffix for defining which version of the"
   echo "                        stream_list_atmosphere.diagnostics template to use."
   echo "                        The default is to not use any suffix. This is used only"
   echo "                        by steps 3 and 4."
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
YYYYMMDDHHi=2024010100
FCST=24
NLEV=55
OUTPUT_DIAG_INTERVAL="03:00:00"
VARTABLE=""
#---~---


#--- Parse arguments.
while [[ ${#} > 0 ]]
do
   key="${1}"
   case ${key} in
   -bc)
      tag_or_branch_name_CONVERT_MPAS="${2}"
      shift 2 # past flag and argument
      ;;
   -bm)
      tag_or_branch_name_MONAN="${2}"
      shift 2 # past flag and argument
      ;;
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
   -f)
      FCST="${2}"
      shift 2 # past flag and argument
      ;;
   -gc)
      github_link_CONVERT_MPAS="${2}"
      shift 2 # past flag and argument
      ;;
   -gm)
      github_link_MONAN="${2}"
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
      echo "Unknown key-value argument pair."
      show_usage
      exit 2
      ;;
   esac
done
#---~---


#---~---
#   Make sure the grid resolution settings are valid.
#---~---
case "${RES}" in
5898242)
   echo -e "${GREEN}==>${NC} Grid resolution ${RES} (~ 10 km).\n"
   ;;
2621442)
   echo -e "${GREEN}==>${NC} Grid resolution ${RES} (~ 15 km).\n"
   ;;
1024002)
   echo -e "${GREEN}==>${NC} Grid resolution ${RES} (~ 24 km).\n"
   ;;
40962)
   echo -e "${GREEN}==>${NC} Grid resolution ${RES} (~ 120 km).\n"
   ;;
*)
   echo -e "${ORANGE}****** WARNING ******${NC} \n"
   echo -e "${ORANGE}==>${NC} Provided grid resolution (${RES}) is not recognised.\n"
   echo -e "${ORANGE}==>${NC} We cannot guarantee that MONAN will run fine.\n"
   ;;
esac
#---~---


#--- Set and create standard directories
DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT; mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_CD-CT;   mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;           mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;             mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;           mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;           mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;               mkdir -p ${EXECS}
#---~---


#--- Make sure VARTABLE has the leading "-v" if not empty.
if [[ "${VARTABLE}" == "" ]]
then
   dv_VARTABLE=""
else
   dv_VARTABLE="-v ${VARTABLE}"
fi
#---~---


#--- If INPUT_PATH is provided, replace the path in setenv.bash
if [[ "${INPUT_PATH}" != "" ]] && [[ -d "${INPUT_PATH}" ]]
then
   sed -i.bck "s,^export DIRDADOS=.*,export DIRDADOS=${INPUT_PATH},g" ${SCRIPTS}/setenv.bash
   /bin/rm -f ${SCRIPTS}/setenv.bash.bck
fi
#---~---


#---~---
#   Select step.
#---~---
case ${STEP} in
0)
   #---~---
   #   Call the script itself four times, passing all the configuration.
   #---~---
   step_now=0
   while [[ ${step_now} -lt 4 ]]
   do
      #--- Update step
      let step_now=${step_now}+1
      #---~---


      #--- Run step
      time ${0} ${CLEAN} ${OVERWRITE} ${dv_VARTABLE}                                       \
         -bc ${tag_or_branch_name_CONVERT_MPAS} -bm ${tag_or_branch_name_MONAN}            \
         -d ${OUTPUT_DIAG_INTERVAL} -e ${EXP} -f ${FCST} -gc ${github_link_CONVERT_MPAS}   \
         -gm ${github_link_MONAN} -l ${NLEV} -r ${RES} -s ${step_now} -t ${YYYYMMDDHHi}
      #---~---
   done
   #---~---
   ;;
1)
   #---~---
   #   STEP 1: Install and compile MONAN and its utility programs.
   #---~---
   time 1.install_monan.bash -bc ${tag_or_branch_name_CONVERT_MPAS}                        \
      -bm ${tag_or_branch_name_MONAN} -gc ${github_link_CONVERT_MPAS}                      \
      -gm ${github_link_MONAN}
   #---~---
   ;;
2)
   #---~---
   #   STEP 2: Run the pre-processing step, and make initial/boundary conditions if needed.
   #---~---
   time 2.pre_processing.bash ${CLEAN} ${OVERWRITE} -e ${EXP} -f ${FCST} -r ${RES}         \
      -t ${YYYYMMDDHHi}
   #---~---
   ;;
3)
   #---~---
   #   STEP 3: Run the model.
   #---~---
   time 3.run_model.bash ${CLEAN} ${dv_VARTABLE} -d ${OUTPUT_DIAG_INTERVAL} -e ${EXP}      \
      -f ${FCST} -l ${NLEV} -r ${RES} -t ${YYYYMMDDHHi}
   #---~---
   ;;
4)
   #---~---
   # STEP 4: Run the post-processing step.
   #---~---
   time 4.run_post.bash ${dv_VARTABLE} -d ${OUTPUT_DIAG_INTERVAL} -e ${EXP} -f ${FCST}     \
      -l ${NLEV} -r ${RES} -t ${YYYYMMDDHHi}
   #---~---
   ;;
esac
#---~---
