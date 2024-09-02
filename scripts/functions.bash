#!/bin/bash 
#-----------------------------------------------------------------------------#
# !SCRIPT: functions
#
# !DESCRIPTION:
#     Creates functions used in other scripts
#     

how_many_nodes () { 
   nume=${1}   
   deno=${2}
   num=$(echo "${nume}/${deno}" | bc -l)  
   how_many_nodes_int=$(echo "${num}/1" | bc)
   dif=$(echo "scale=0; (${num}-${how_many_nodes_int})*100/1" | bc)
   rest=$(echo "scale=0; (((${num}-${how_many_nodes_int})*${deno})+0.5)/1" | bc -l)
   if [ ${dif} -eq 0 ]; then how_many_nodes_left=0; else how_many_nodes_left=1; fi
   if [ ${how_many_nodes_int} -eq 0 ]; then how_many_nodes_int=1; how_many_nodes_left=0; rest=0; fi
   
   echo "INT number of nodes needed: \${how_many_nodes_int}  = ${how_many_nodes_int}"
   echo "number of nodes left:       \${how_many_nodes_left} = ${how_many_nodes_left}"
   echo ""
}
#----------------------------------------------------------------------------------------------



clean_model_tmp_files () {

   echo "Removed all temporary files from scripts executions"

   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/atmosphere_model
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/*TBL
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/*DBL
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/*DATA
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/x1.*.nc
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/x1.*.graph.info.part.*
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/Vtable.GFS
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/streams.atmosphere
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/stream_list.atmosphere.surface
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/stream_list.atmosphere.output
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/stream_list.atmosphere.diagnostics
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/namelist.atmosphere
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/MONAN_DIAG_*
   rm -f ${DIR_SCRIPTS}/scripts_CD-CT/scripts/log.atmosphere.*
   echo ""
   
}
#----------------------------------------------------------------------------------------------


print_instructions() {
    local script_name=$1
    echo ""
    echo "Instructions: execute the command below"
    echo ""
    echo "${script_name} EXP_NAME RESOLUTION LABELI FCST"
    echo ""
    echo "EXP_NAME    :: GFS: use GFS"
    echo "            :: clean: remove all temporary files createed in the last run."
    echo "RESOLUTION  :: Number of points in resolution model grid"
    echo ""
    echo "LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100"
    echo "FCST        :: Forecast hours, e.g.: 24 or 36, etc."
    echo ""
    echo "24 hour forecasts examples:"
    echo "${script_name} GFS    2562 2024080800 24  # example for 480Km"
    echo "${script_name} GFS    4002 2024080800 24  # example for 384Km"
    echo "${script_name} GFS   10242 2024080800 24  # example for 240Km"
    echo "${script_name} GFS   40962 2024010100 24  # example for 120Km"
    echo ""
    echo "Clean temporary files example:"
    echo "${script_name} clean"
    echo ""
}


clean_if_requested() {
   local script_name=$1
   op=$(echo "${2}" | tr '[A-Z]' '[a-z]')
   if [ "${op}" = "clean" ]; then
      clean_model_tmp_files
      exit 0
   else
      print_instructions $script_name
      exit -1
   fi
}
