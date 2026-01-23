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
   echo " ${0} [-v VARTABLE] [-d OUTPUT_DIAG_INT] [-e EXP ] [-f FCST] \\"
   echo "    [-l N_MODEL_LEV] [-r RES] [-t YYYYMMDDHH]"
   echo ""
   echo " List of optional flags: "
   echo ""
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
   echo " -l N_MODEL_LEV      -- Number of vertical levels for the output."
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
EXP=""
RES=""
YYYYMMDDHHi=""
FCST=""
N_MODEL_LEV=""
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
   -l)
      N_MODEL_LEV="${2}"
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
#   Make sure all settings were provided.
#---~---
if [[ "${EXP}"                  == "" ]] || [[ "${RES}"                  == "" ]] ||
   [[ "${YYYYMMDDHHi}"          == "" ]] || [[ "${FCST}"                 == "" ]] ||
   [[ "${N_MODEL_LEV}"          == "" ]] || [[ "${OUTPUT_DIAG_INTERVAL}" == "" ]]
then
   echo " This script requires some arguments to be set through flags."
   show_usage
   exit 2
fi
#---~---

echo ""
echo "---- Run Post ----"
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
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#---~---



# Local variables--------------------------------------
START_DATE_YYYYMMDD="${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}"
START_HH="${YYYYMMDDHHi:8:2}"
maxpostpernode=30    # <------ qtde max de convert_mpas por no!
#-------------------------------------------------------

# Variables for flex output interval ------------------------
t_strout=${OUTPUT_DIAG_INTERVAL}
t_stroutsec=`echo ${t_strout} | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}'`
t_strouthor=`echo "scale=4; (${t_stroutsec}/60)/60" | bc`
#------------------------------------------------------------------------------------

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
65536002)
   #---~---
   #   3 km, use 40 points per degree
   #---~---
   NLAT=7201
   NLON=14401
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
   #---~---
   ;;
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
655362)
   #---~---
   #   30 km, use 4 points per degree
   #---~---
   NLAT=721
   NLON=1441
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
   #---~---
   ;;
163842)
   #---~---
   #   60 km, use 2 points per degree
   #---~---
   NLAT=361
   NLON=721
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
   #   Unrecognised resolution
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
if [[ -s ${MONANDIR}/src/core_atmosphere/diagnostics/Registry_isobaric.xml ]]
then
   N_ISOBARIC_LEV=$(grep "t_iso_levels" ${MONANDIR}/src/core_atmosphere/diagnostics/Registry_isobaric.xml | grep definition | cut -d\" -f4)
else
   N_ISOBARIC_LEV=18
fi


files_needed=("${SCRIPTS}/namelists/include_fields.diag${VARTABLE}" "${SCRIPTS}/namelists/convert_mpas.nml" "${SCRIPTS}/namelists/target_domain.TEMPLATE" "${EXECS}/convert_mpas" "${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc")
for file in "${files_needed[@]}"
do
  if [[ ! -s "${file}" ]]
  then
    echo -e  "\n${RED}==>${NC} ***** FATAL ERROR *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done

#---~---
# Tally the number of model output files to be postprocessed, and find out how
# many nodes are needed to process ${maxpostpernode} convert_mpas runs per node:
#nfiles=$(ls -l ${DATAOUT}/${YYYYMMDDHHi}/Model/MONAN*nc | wc -l)
# from streams.atmosphere.TEMPLATE in diagnostics the output_interval is flexible
#---~---
output_interval=${t_strouthor}
#nfiles=FCST/output_interval + 1(time zero file)
nfiles=$(echo "$FCST/$output_interval + 1" | bc)
echo "${nfiles} post to submit."
echo "Max ${maxpostpernode} submits per nodes."
how_many_nodes ${nfiles} ${maxpostpernode}
#---~---

#---~---
#   Make paths and create files/links for each convert_mpas output:
#---~---
cd ${DIRRUN}

for ii in $(seq 1 ${nfiles})
do
   i=$(printf "%04d" ${ii})
   mkdir -p ${DIRRUN}/dir.${i}
   cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}/dir.${i}
   cp -f ${SCRIPTS}/namelists/include_fields.diag${VARTABLE}  ${DIRRUN}/dir.${i}/include_fields.diag${VARTABLE}
   cp -f ${DIRRUN}/dir.${i}/include_fields.diag${VARTABLE} ${DIRRUN}/dir.${i}/include_fields
   sed -e "s,#NISOLEV#,${N_ISOBARIC_LEV},g;s,#NMODELLEV#,${N_MODEL_LEV},g" \
      ${SCRIPTS}/namelists/convert_mpas.nml > ${DIRRUN}/dir.${i}/convert_mpas.nml
   sed -e "s,#NLAT#,${NLAT},g;s,#NLON#,${NLON},g;s,#STARTLAT#,${STARTLAT},g;s,#ENDLAT#,${ENDLAT},g;s,#STARTLON#,${STARTLON},g;s,#ENDLON#,${ENDLON},g;" \
      ${SCRIPTS}/namelists/target_domain.TEMPLATE > ${DIRRUN}/dir.${i}/target_domain

done
#---~---

cd ${DIRRUN}
chmod -R 755 ${DIRRUN}/*

echo "scheduler system = " ${SCHEDULER_SYSTEM} 
echo "system key = " ${SYSTEM_KEY}
echo ""
#---~---
#   Loop that generates submission files that distributes chunks of convertmpas runs to
# each node:
#---~---
node=1
inicio=1   
fim=$((maxpostpernode <= nfiles ? maxpostpernode : nfiles))
while [[ ${inicio} -le ${nfiles} ]]
do
   rm -f ${DIRRUN}/PostAtmos_node.${node}.sh

   case "${SCHEDULER_SYSTEM}" in
   GENERIC)
      echo "#!/bin/bash " > ${DIRRUN}/PostAtmos_node.${node}.sh
      ;;
   *)
      sed -e "s,#JOBNAME#,MO.Pos${node},g;
      s,#NNODES#,${POST_nnodes},g;
      s,#NCPUS#,${POST_ncpus},g;
      s,#NTASKS#,${POST_ncores},g;
      s,#NTASKSPNODE#,${POST_ncpn},g;
      s,#NTHREADS#,${POST_nthreads},g;
      s,#PARTITION#,${POST_QUEUE},g;
      s,#WALLTIME#,${POST_walltime},g;
      s,#OUTPUTJOB#,${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.o,g;
      s,#ERRORJOB#,${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.e,g" \
      ${SCRIPTS}/stools/submit_${SYSTEM_KEY}.bash_TEMPLATE > \
      ${DIRRUN}/PostAtmos_node.${node}.sh
      ;;
   esac
   
cat << EOSH >> ${DIRRUN}/PostAtmos_node.${node}.sh 

cd ${DIRRUN}
. ${SCRIPTS}/setenv.bash
chmod 755 ${DIRRUN}/*

echo "Submitting posts ${inicio} to ${fim} to node Node ${node}."

for ii in \$(seq  ${inicio} ${fim})
do
   i=\$(printf "%04d" \${ii})
   echo "Preparing post files \${i}"
   cp -f ${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc ${DIRRUN}/dir.\${i} &
   cp -f ${EXECS}/convert_mpas ${DIRRUN}/dir.\${i} &
done

wait

for ii in \$(seq  ${inicio} ${fim})
do
   i=\$(printf "%04d" \${ii})
   echo "Executing post \${i}"
   cd ${DIRRUN}/dir.\${i}
   chmod 755 *
   hh=${YYYYMMDDHHi:8:2}
   currentdate=\$(date -d "${YYYYMMDDHHi:0:8} \${hh}:00:00 \$(echo "(\${i}-1)*${t_strout:0:2}" | bc) hours \$(echo "(\${i}-1)*${t_strout:3:2}" | bc) minutes \$(echo "(\${i}-1)*${t_strout:6:2}" | bc) seconds" +"%Y%m%d%H.%M.%S")
   diag_name=MONAN_DIAG_G_MOD_${EXP}_${YYYYMMDDHHi}_\${currentdate}.x${RES}L${N_MODEL_LEV}.nc
   echo ""
   echo "executando convert mpas"
   chmod 755 ${DATAOUT}/${YYYYMMDDHHi}/Model/*
   time  ./convert_mpas x1.${RES}.init.nc ${DATAOUT}/${YYYYMMDDHHi}/Model/\${diag_name}  > convert_mpas.output & 
   echo "./convert_mpas x1.${RES}.init.nc ${DATAOUT}/${YYYYMMDDHHi}/Model/\${diag_name} > convert_mpas.output"
done

# necessario aguardar as rodadas em background
wait

for ii in \$(seq  ${inicio} ${fim})
do
   i=\$(printf "%04d" \${ii})
   hh=${YYYYMMDDHHi:8:2}
   currentdate=\$(date -d "${YYYYMMDDHHi:0:8} \${hh}:00:00 \$(echo "(\${i}-1)*${t_strout:0:2}" | bc) hours \$(echo "(\${i}-1)*${t_strout:3:2}" | bc) minutes \$(echo "(\${i}-1)*${t_strout:6:2}" | bc) seconds" +"%Y%m%d%H.%M.%S")
   diag_name_post=MONAN_DIAG_G_POS_${EXP}_${YYYYMMDDHHi}_\${currentdate}.x${RES}L${N_ISOBARIC_LEV}.nc
   
   cd ${DIRRUN}/dir.\${i}
   chmod 755 *
   cp latlon.nc  ${DATAOUT}/${YYYYMMDDHHi}/Post/\${diag_name_post} >> convert_mpas.output & 
   echo "cp latlon.nc  ${DATAOUT}/${YYYYMMDDHHi}/Post/\${diag_name_post}"  >> convert_mpas.output
   
done
 
wait

EOSH
   
  
   chmod a+x ${DIRRUN}/PostAtmos_node.${node}.sh
   chmod 755 ${DIRRUN}/*
   cp -f ${DIRRUN}/PostAtmos_node.${node}.sh ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
   chmod 755 ${DATAOUT}/${YYYYMMDDHHi}/Post/*
   case "${SCHEDULER_SYSTEM}" in
   SLURM)
      echo "Sbatch PostAtmos_node.${node}.sh"
      jobid[${node}]=$(sbatch --parsable ${DIRRUN}/PostAtmos_node.${node}.sh)
      echo "JobId node ${node} = ${jobid[${node}]} , convert_mpas ${inicio} to ${fim}"
      echo ""
      ;;
   PBS)
      echo "Rodando em PBS"
      echo -e  "${GREEN}==>${NC} qsub PostAtmos_node.${node}.sh...\n"
      cd ${DIRRUN}
		jobid[${node}]=$(qsub ${DIRRUN}/PostAtmos_node.${node}.sh | cut -d '.' -f1)
       ;;
#  GENERIC)
#     echo "Nenhum gerenciador detectado"
#     ${DIRRUN}/PostAtmos_node.${node}.sh
#     ;;
   esac
  

   inicio=$((fim + 1))
   temp=$((fim + maxpostpernode))
   fim=$(( temp < nfiles ? temp : nfiles ))
   node=$((node+1))
   sleep 5
done



# Dependencias JobId:
dependency="afterok"
for job_id in "${jobid[@]}"
do
   dependency="${dependency}:${job_id}"
done


# Script final , para conferir todos os arquivos, criar o template final  e apagar o diretorio DIRRUN
node=0
rm -f ${DIRRUN}/PostAtmos_node.${node}.sh

case "${SCHEDULER_SYSTEM}" in
GENERIC)
   echo "#!/bin/bash " > ${DIRRUN}/PostAtmos_node.${node}.sh
   ;;
*)
   sed -e "s,#JOBNAME#,MO.Pos${node},g;
   s,#NNODES#,${POST_nnodes},g;
   s,#NCPUS#,${POST_ncpus},g;
   s,#NTASKS#,${POST_ncores},g;
   s,#NTASKSPNODE#,${POST_ncpn},g;
   s,#NTHREADS#,${POST_nthreads},g;
   s,#PARTITION#,${POST_QUEUE},g;
   s,#WALLTIME#,${POST_walltime},g;
   s,#OUTPUTJOB#,${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.o,g;
   s,#ERRORJOB#,${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.e,g" \
   ${SCRIPTS}/stools/submit_${SYSTEM_KEY}.bash_TEMPLATE > \
   ${DIRRUN}/PostAtmos_node.${node}.sh
   ;;
esac

cat << EOSH >> ${DIRRUN}/PostAtmos_node.${node}.sh 

cd ${DIRRUN}
. ${SCRIPTS}/setenv.bash

# Saving important files to the logs directory:
cp -f ${EXECS}/CONVMPAS-VERSION.txt ${DATAOUT}/${YYYYMMDDHHi}/Post
cp -f ${EXECS}/CONVMPAS-VERSION.txt ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${DIRRUN}/dir.0001/target_domain ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${DIRRUN}/dir.0001/convert_mpas.nml ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${DIRRUN}/dir.0001/include_fields ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${DIRRUN}/dir.0001/convert_mpas.output ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${DIRRUN}/PostAtmos_node.*.sh ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${DATAOUT}/${YYYYMMDDHHi}/Model/logs/* ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${DATAOUT}/${YYYYMMDDHHi}/Model/MONAN-VERSION.txt ${DATAOUT}/${YYYYMMDDHHi}/Post/logs


cd ${DIRRUN}/..
rm -fr ${DIRRUN}


EOSH
chmod a+x ${DIRRUN}/PostAtmos_node.${node}.sh


case "${SCHEDULER_SYSTEM}" in
SLURM)
   echo "Sbatch PostAtmos_node.${node}.sh"
   sbatch --wait --dependency=${dependency} ${DIRRUN}/PostAtmos_node.${node}.sh 
   ;;
PBS)
   echo "Rodando em PBS"
   echo -e  "${GREEN}==>${NC} qsub PostAtmos_node.${node}.sh...\n"
   cd ${DIRRUN}
   qsub -W depend=${dependency} -W block=true ${DIRRUN}/PostAtmos_node.${node}.sh
   ;;
#GENERIC)
#   echo "Nenhum gerenciador detectado"
#   ${DIRRUN}/PostAtmos_node.${node}.sh
#   ;;
esac


#--- Make sure VARTABLE has the leading "-v" if not empty.
if [[ "${VARTABLE}" == "" ]]
then
   dv_VARTABLE=""
else
   dv_VARTABLE="-v ${VARTABLE}"
fi
#---~---

#CR: Append this script to script PostAtmos_node.0.sh, which has been submitted.
cd ${SCRIPTS}
chmod 755 ${DATAOUT}/${YYYYMMDDHHi}/Post/*
time ${SCRIPTS}/make_template.bash ${dv_VARTABLE} -d ${OUTPUT_DIAG_INTERVAL} -e ${EXP}     \
   -f ${FCST} -r ${RES} -t ${YYYYMMDDHHi}
