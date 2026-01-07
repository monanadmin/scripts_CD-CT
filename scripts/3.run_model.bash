#!/bin/bash 
#-----------------------------------------------------------------------------#
# !SCRIPT: run_model
#
# !DESCRIPTION:
#     Script to run the MONAN model over the forecast horizon.
#     
#     Performs the following tasks:
# 
#        o VCheck all input files before 
#        o Creates the submition script
#        o Submit the model
#        o Veriffy all files generated
#        
#
#-----------------------------------------------------------------------------#

#--- Function that shows usage.
function show_usage() {
   echo " Usage: "
   echo ""
   echo " ${0} [-c] [-v VARTABLE] [-d OUTPUT_DIAG_INT] [-e EXP ] [-f FCST] [-l NLEV] \\"
   echo "    [-r RES] [-t YYYYMMDDHH]"
   echo ""
   echo " List of optional flags: "
   echo ""
   echo " -c                  -- Clean files from previous runs."
   echo " -v VARTABLE         -- Suffix for defining which version of the"
   echo "                        stream_list_atmosphere.diagnostics template to use."
   echo "                        The default is to not use any suffix."
   echo ""
   echo " List of **required** flags when -c is not set: "
   echo ""
   echo " -d OUTPUT_DIAG_INT  -- Output interval for diagnostic. The format must be"
   echo "                        \"HH:MM:SS\""
   echo " -e EXP              -- meteorological drivers. For example, GFS"
   echo " -f FCST             -- Simulation length in hours, e.g., 24 or 48."
   echo " -l NLEV             -- Number of vertical levels for the output."
   echo " -r RES              -- grid resolution. Options are:"
   echo "                        5898242 (~ 10 km)"
   echo "                        2621442 (~ 15 km)"
   echo "                        1024002 (~ 24 km)"
   echo "                        40962   (~ 120 km)"
   echo " -t YYYYMMDDHH       -- Initial time. For example if 22 Sept 2025 00 UTC,"
   echo "                        set it to: 2025092200"
   echo ""
}
#---~---


#--- Set environment variables exports:
. setenv.bash
#---~---




#--- Default input variables:
CLEAN=false
EXP=""
RES=""
YYYYMMDDHHi=""
FCST=""
NLEV=""
OUTPUT_DIAG_INTERVAL=""
VARTABLE=""
#---~---


#--- Parse arguments.
while [[ ${#} > 0 ]]
do
   key="${1}"
   case ${key} in
   -c)
      CLEAN=true
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
   -l)
      NLEV="${2}"
      shift 2 # Past flag and argument
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
      echo "Unknown key-value argument pair."
      show_usage
      exit 2
      ;;
   esac
done
#---~---



#---~---
#   Make sure all settings were provided (unless this will be to clean up runs).
#---~---
if ${CLEAN}
then
   clean_pre_tmp_files
   exit
elif [[ "${EXP}"                  == "" ]] || [[ "${RES}"                  == "" ]] ||
     [[ "${YYYYMMDDHHi}"          == "" ]] || [[ "${FCST}"                 == "" ]] ||
     [[ "${NLEV}"                 == "" ]] || [[ "${OUTPUT_DIAG_INTERVAL}" == "" ]]
then
   echo " This script requires some arguments to be set through flags."
   show_usage
   exit 2
fi
#---~---



#--- Set and create standard directories
DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT; mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_CD-CT;   mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;           mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;             mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;           mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;           mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;               mkdir -p ${EXECS}
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Model/logs
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#---~---



# Local variables--------------------------------------
start_date=${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}:00:00
cores=${MODEL_ncores}
hhi=${YYYYMMDDHHi:8:2}
CONFIG_CONV_INTERVAL="00:30:00"
#------------------------------------------------------------------------------------

# Variables for flex outpout interval ------------------------
t_strout=${OUTPUT_DIAG_INTERVAL}
t_stroutsec=$(echo ${t_strout} | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}')
t_strouthor=`echo "scale=4; (${t_stroutsec}/60)/60" | bc`
#------------------------------------------------------------------------------------

# Format to HH:MM:SS t_strout (output_interval)
IFS=":" read -r h m s <<< "${t_strout}"
printf -v t_strout "%02d:%02d:%02d" "$h" "$m" "$s"
# From now on, CONFI_LEN_DISP becames cte = 0.0, pickin up this value from static file.

# Calculating default parameters for different resolutions
case ${RES} in
5898242)  #10km
   CONFIG_DT=60.0
   CONFIG_LEN_DISP=10000.0
   CONFIG_CONV_INTERVAL="00:15:00"
   ;;
2621442)  #15Km
   CONFIG_DT=90.0
   CONFIG_LEN_DISP=15000.0
   CONFIG_CONV_INTERVAL="00:15:00"
   ;;
1024002)  #24Km
   CONFIG_DT=150.0
   CONFIG_LEN_DISP=24000.0
   CONFIG_CONV_INTERVAL="00:15:00"
   ;;
40962)  #120Km
   CONFIG_DT=600.0
   CONFIG_LEN_DISP=120000.0
   ;;
*)
   echo -e "${ORANGE}****** WARNING ******${NC} \n"
   echo -e "${ORANGE}==>${NC} Provided grid resolution (${RES}) is not recognised.\n"
   echo -e "${ORANGE}==>${NC} We cannot guarantee that MONAN will run fine.\n"
   ;;
esac
#-------------------------------------------------------


# Calculating final forecast dates in model namelist format: DD_HH:MM:SS 
# using: start_date(yyyymmdd) + FCST(hh) :
ind=`printf "%02d\n" $(echo "${FCST}/24" | bc)`
inh=`printf "%02.0f\n" $(echo "((${FCST}/24)-${ind})*24" | bc -l)`
DD_HHMMSS_forecast=$(echo "${ind}_${inh}:00:00")


if [ ! -s ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ]
then
   if [ ! -s ${DATAIN}/fixed/x1.${RES}.graph.info ]
   then
      cd ${DATAIN}/fixed
      echo -e "${GREEN}==>${NC} downloading meshes tgz files ... \n"
      wget https://www2.mmm.ucar.edu/projects/mpas/atmosphere_meshes/x1.${RES}.tar.gz
      wget https://www2.mmm.ucar.edu/projects/mpas/atmosphere_meshes/x1.${RES}_static.tar.gz
      tar -xzvf x1.${RES}.tar.gz
      tar -xzvf x1.${RES}_static.tar.gz
   fi
   echo -e "${GREEN}==>${NC} Creating x1.${RES}.graph.info.part.${cores} ... \n"
   cd ${DATAIN}/fixed
   gpmetis -minconn -contig -niter=200 x1.${RES}.graph.info ${cores}
   rm -fr x1.${RES}.tar.gz x1.${RES}_static.tar.gz
fi


files_needed=("${SCRIPTS}/namelists/stream_list.atmosphere.output" ""${SCRIPTS}/namelists/stream_list.atmosphere.diagnostics${VARTABLE} "${SCRIPTS}/namelists/stream_list.atmosphere.surface" "${EXECS}/atmosphere_model" "${DATAIN}/fixed/x1.${RES}.static.nc" "${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores}" "${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc" "${DATAIN}/fixed/Vtable.GFS")
for file in "${files_needed[@]}"
do
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** FATAL ERROR *****\n"   
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done

cp -f ${EXECS}/atmosphere_model ${DIRRUN}
cp -f ${DATAIN}/fixed/*TBL ${DIRRUN}
cp -f ${DATAIN}/fixed/*DBL ${DIRRUN}
cp -f ${DATAIN}/fixed/*DATA ${DIRRUN}
cp -f ${DATAIN}/fixed/x1.${RES}.static.nc ${DIRRUN}
cp -f ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ${DIRRUN}
cp -f ${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc ${DIRRUN}
cp -f ${DATAIN}/fixed/Vtable.GFS ${DIRRUN}


if [ ${EXP} = "GFS" ]
then
   sed -e "s,#LABELI#,${start_date},g;s,#FCSTS#,${DD_HHMMSS_forecast},g;s,#RES#,${RES},g;
s,#CONFIG_DT#,${CONFIG_DT},g;s,#CONFIG_LEN_DISP#,${CONFIG_LEN_DISP},g;s,#CONFIG_CONV_INTERVAL#,${CONFIG_CONV_INTERVAL},g" \
   ${SCRIPTS}/namelists/namelist.atmosphere.TEMPLATE > ${DIRRUN}/namelist.atmosphere
   
   sed -e "s,#RES#,${RES},g;s,#CIORIG#,${EXP},g;s,#LABELI#,${YYYYMMDDHHi},g;s,#NLEV#,${NLEV},g;
s,#OUTPUT_DIAG_INTERVAL#,${OUTPUT_DIAG_INTERVAL},g" \
   ${SCRIPTS}/namelists/streams.atmosphere.TEMPLATE > ${DIRRUN}/streams.atmosphere
fi
cp -f ${SCRIPTS}/namelists/stream_list.atmosphere.output ${DIRRUN}
cp -f ${SCRIPTS}/namelists/stream_list.atmosphere.diagnostics${VARTABLE} ${DIRRUN}/stream_list.atmosphere.diagnostics
cp -f ${SCRIPTS}/namelists/stream_list.atmosphere.surface ${DIRRUN}



cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}
rm -f ${DIRRUN}/model.bash 
cat << EOF0 > ${DIRRUN}/model.bash 
#!/bin/bash -x
#SBATCH --job-name=${MODEL_jobname}
#SBATCH --nodes=${MODEL_nnodes}
#SBATCH --ntasks=${MODEL_ncores}
#SBATCH --tasks-per-node=${MODEL_ncpn}
#SBATCH --partition=${MODEL_QUEUE}
#SBATCH --time=${MODEL_walltime}
#SBATCH --output=${DATAOUT}/${YYYYMMDDHHi}/Model/logs/model.bash.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/${YYYYMMDDHHi}/Model/logs/model.bash.e%j     # File name for standard error output
#SBATCH --exclusive
##SBATCH --mem=500000


export executable=atmosphere_model

ulimit -c unlimited
ulimit -v unlimited
ulimit -s unlimited

. $(pwd)/setenv.bash

cd ${DIRRUN}


date
time mpirun -np \${SLURM_NTASKS} ./\${executable}
date

#
# move dataout, clean up and remove files/links
#

mv MONAN_DIAG_* ${DATAOUT}/${YYYYMMDDHHi}/Model
mv MONAN_HIST_* ${DATAOUT}/${YYYYMMDDHHi}/Model
cp -f ${EXECS}/MONAN-VERSION.txt ${DATAOUT}/${YYYYMMDDHHi}/Model
cp -f ${EXECS}/MONAN-VERSION.txt ${DATAOUT}/${YYYYMMDDHHi}/Model/logs/
cp -f ${DIRHOMES}/VERSION.txt ${DATAOUT}/${YYYYMMDDHHi}/Model/logs/SCRIPTSCDCT-VERSION.txt
cp -f ${MONANDIR}/README.md ${DATAOUT}/${YYYYMMDDHHi}/Model/logs/

mv log.atmosphere.*.out ${DATAOUT}/${YYYYMMDDHHi}/Model/logs
mv log.atmosphere.*.err ${DATAOUT}/${YYYYMMDDHHi}/Model/logs
mv namelist.atmosphere ${DATAOUT}/${YYYYMMDDHHi}/Model/logs
mv stream* ${DATAOUT}/${YYYYMMDDHHi}/Model/logs


EOF0
chmod a+x ${DIRRUN}/model.bash


echo -e  "${GREEN}==>${NC} Submitting MONAN atmosphere model and waiting for finish before exit... \n"
echo -e  "${GREEN}==>${NC} Logs being generated at ${DATAOUT}/logs... \n"
echo -e  "sbatch ${SCRIPTS}/model.bash"
sbatch --wait ${DIRRUN}/model.bash
mv ${DIRRUN}/model.bash ${DATAOUT}/${YYYYMMDDHHi}/Model/logs


#-----Loop que verifica se os arquivos foram gerados corretamente (>0)-----
output_interval=${t_strouthor}
nfiles=$(echo "$FCST/$output_interval + 1" | bc)
for ii in $(seq 1 ${nfiles})
do
   i=$(printf "%04d" ${ii})
   hh=${YYYYMMDDHHi:8:2}
   currentdate=$(date -d "${YYYYMMDDHHi:0:8} ${hh}:00:00 $(echo "(${i}-1)*${t_strout:0:2}" | bc) hours $(echo "(${i}-1)*${t_strout:3:2}" | bc) minutes $(echo "(${i}-1)*${t_strout:6:2}" | bc) seconds" +"%Y%m%d%H.%M.%S")
   file=MONAN_DIAG_G_MOD_${EXP}_${YYYYMMDDHHi}_${currentdate}.x${RES}L55.nc

   if [ ! -s ${DATAOUT}/${YYYYMMDDHHi}/Model/${file} ]
   then
    echo -e  "\n${RED}==>${NC} ***** FATAL ERROR *****\n"   
    echo -e  "${RED}==>${NC} [${0}] At least the file ${DATAOUT}/${YYYYMMDDHHi}/Model/${file} was not generated. \n"
    exit -1
   fi

done

rm -fr ${DIRRUN}
