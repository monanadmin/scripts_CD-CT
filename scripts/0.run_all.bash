#!/bin/bash 




#--- Function that shows usage.
function show_usage() {
   echo " Usage: "
   echo ""
   echo " ${0} [-s STEP] [-c] [-o] [-gm GIT_MONAN ] [ -bm TAG_MONAN ] \\"
   echo "    [-gc GIT_CONVERT_MPAS] [-bc TAG_CONVERT_MPAS] [-e EXP ] [-r RES] \\"
   echo "    [-i YYYYMMDDHH] [-f FCST]"
   echo ""
   echo " List of optional flags: "
   echo ""
   echo " -s STEP         -- Step to run. Options are:"
   echo "                    1 - Compile MONAN executables."
   echo "                    2 - Run pre-processing."
   echo "                    3 - Run atmospheric model."
   echo "                    4 - Run post-processing."
   echo "                    0 - Run all steps 1-4."
   echo " -c              -- Clean files from previous runs (used only if step is 2,3 or 4)."
   echo " -o              -- Overwrite static files (used only if step is 2)."
   echo " -gm GIT_MONAN   -- GitHub handle for MONAN. For example:"
   echo "                    https://github.com/monanadmin/MONAN-Model.git"
   echo " -bm TAG_MONAN   -- branch or tag name of the MONAN repository. For example:"
   echo "                    \"develop\"."
   echo " -gm GIT_CONVERT -- GitHub handle for MONAN. For example:"
   echo "                    https://github.com/monanadmin/MONAN-Model.git"
   echo " -bm TAG_CONVERT -- branch or tag name of the MONAN repository. For example:"
   echo "                    \"develop\"."
   echo " -e EXP          -- meteorological drivers. For example, GFS"
   echo " -r RES          -- grid resolution. Options are:"
   echo "                    5898242 (~ 10 km)"
   echo "                    2621442 (~ 15 km)"
   echo "                    1024002 (~ 24 km)"
   echo "                    40962   (~ 120 km)"
   echo " -i YYYYMMDDHH   -- Initial time. For example if 22 Sept 2025 00 UTC, set it to:"
   echo "                    2025092200"
   echo " -f FCST         -- Simulation length in hours, e.g., 24 or 48."
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
RES=1024002
YYYYMMDDHHi=2024010100
FCST=24
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
      YYYYMMDDHHi="${2}"
      shift 2 # past flag and argument
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
      time ${0} -s ${step_now} ${CLEAN} ${OVERWRITE} -gm ${github_link_MONAN}              \
         -bm ${tag_or_branch_name_MONAN} -gc ${github_link_CONVERT_MPAS}                   \
         -bc ${tag_or_branch_name_CONVERT_MPAS} -e ${EXP} -r ${RES} -i ${YYYYMMDDHHi}      \
         -f ${FCST}
      #---~---
   done
   #---~---
   ;;
1)
   #---~---
   #   STEP 1: Install and compile MONAN and its utility programs.
   #---~---
   time 1.install_monan.bash -gm ${github_link_MONAN} -bm ${tag_or_branch_name_MONAN}      \
      -gc ${github_link_CONVERT_MPAS} -bc ${tag_or_branch_name_CONVERT_MPAS}
   #---~---
   ;;
2)
   #---~---
   #   STEP 2: Run the pre-processing step, and make initial/boundary conditions if needed.
   #---~---
   time 2.pre_processing.bash ${CLEAN} ${OVERWRITE} -e ${EXP} -r ${RES} -i ${YYYYMMDDHHi}  \
      -f ${FCST}
   #---~---
   ;;
3)
   #---~---
   #   STEP 3: Run the model.
   #---~---
   time 3.run_model.bash ${CLEAN} -e ${EXP} -r ${RES} -i ${YYYYMMDDHHi} -f ${FCST}
   #---~---
   ;;
4)
   #---~---
   # STEP 4: Run the post-processing step.
   #---~---
   time 4.run_post.bash -e ${EXP} -r ${RES} -i ${YYYYMMDDHHi} -f ${FCST} 
   #---~---
   ;;
esac
#---~---
