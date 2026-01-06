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

#--- Function that shows usage.
function show_usage() {
   echo " Usage: "
   echo ""
   echo " ${0} [-c] [-v VARTABLE] [-o] [-e EXP ] [-r RES] [-t YYYYMMDDHH] [-f FCST] \\"
   echo "    [-l NLEV]"
   echo ""
   echo " List of optional flags: "
   echo ""
   echo " -c              -- Clean files from previous runs."
   echo " -v VARTABLE     -- Suffix for defining which version of the"
   echo "                    stream_list_atmosphere.diagnostics template to use."
   echo "                    The default is to not use any suffix."
   echo ""
   echo " List of required flags when -c is not set: "
   echo ""
   echo " -d OUTPUT_DIAG_INT  -- Output interval for diagnostic. The format must be"
   echo "                        \"HH:MM:SS\""
   echo " -e EXP          -- meteorological drivers. For example, GFS"
   echo " -r RES          -- grid resolution. Options are:"
   echo "                    5898242 (~ 10 km)"
   echo "                    2621442 (~ 15 km)"
   echo "                    1024002 (~ 24 km)"
   echo "                    40962   (~ 120 km)"
   echo " -f FCST         -- Simulation length in hours, e.g., 24 or 48."
   echo " -l NLEV         -- Number of vertical levels for the output."
   echo " -t YYYYMMDDHH   -- Initial time. For example if 22 Sept 2025 00 UTC, set it to:"
   echo "                    2025092200"
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
VARTABLE=""
N_MODEL_LEV=""
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
#   Make sure all settings were provided (unless this will be to clean up runs).
#---~---
if ${CLEAN}
then
   clean_pre_tmp_files
   exit
elif [[ "${EXP}"         == "" ]] || [[ "${RES}"         == "" ]] ||
     [[ "${YYYYMMDDHHi}" == "" ]] || [[ "${FCST}"        == "" ]] ||
     [[ "${N_MODEL_LEV}" == "" ]]
then
   echo " This script requires some arguments to be set through flags."
   show_usage
   exit 2
fi
#---~---


#--- Set and create standard directories
DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT; mkdir -p ${DIRHOMES}  
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

# Variables for flex output interval from streams.atmosphere------------------------
t_strout=${OUTPUT_DIAG_INTERVAL}
t_stroutsec=`echo ${t_strout} | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}'`
t_strouthor=`echo "scale=4; (${t_stroutsec}/60)/60" | bc`
#------------------------------------------------------------------------------------

# Format to HH:MM:SS t_strout (output_interval)
IFS=":" read -r h m s <<< "${t_strout}"
printf -v t_strout "%02d:%02d:%02d" "$h" "$m" "$s"

# Calculating default parameters for different resolutions
case ${RES} in
5898242) #10km
   NLAT=1801 #180/0.10 (+1)
   NLON=3601 #360/0.10 (+1)
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
   ;;
2621442)  #15Km
   NLAT=1200 #180/0.15
   NLON=2400 #360/0.15
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
   ;;
1024002)  #24Km
   NLAT=720  #180/0.25
   NLON=1440 #360/0.25
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
   ;;
40962)  #120Km
   NLAT=150 #180/1.2
   NLON=300 #360/1.2
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
   ;;
*)
   echo -e "${ORANGE}****** WARNING ******${NC} \n"
   echo -e "${ORANGE}==>${NC} Provided grid resolution (${RES}) is not recognised.\n"
   echo -e "${ORANGE}==>${NC} We cannot guarantee that MONAN will run fine.\n"
   ;;
esac
#-------------------------------------------------------

# NLEVS get from t_iso_levels in Registry_isobaric.xml:
if [ -s ${MONANDIR}/src/core_atmosphere/diagnostics/Registry_isobaric.xml ]
then
   NLEV=$(grep "t_iso_levels" ${MONANDIR}/src/core_atmosphere/diagnostics/Registry_isobaric.xml | grep definition | cut -d\" -f4)
else
   NLEV=18
fi


files_needed=("${SCRIPTS}/namelists/include_fields.diag${VARTABLE}" "${SCRIPTS}/namelists/convert_mpas.nml" "${SCRIPTS}/namelists/target_domain.TEMPLATE" "${EXECS}/convert_mpas" "${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc")
for file in "${files_needed[@]}"
do
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** FATAL ERROR *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done

# Captura quantos arquivos do modelo tiverem para serem pos-processados e
# quando nos serao necessarios para executar ${maxpostpernode} convert_mpas por no:
#nfiles=$(ls -l ${DATAOUT}/${YYYYMMDDHHi}/Model/MONAN*nc | wc -l)
# from streams.atmosphere.TEMPLATE in diagnostics the output_interval is flexible
output_interval=${t_strouthor}
#nfiles=FCST/output_interval + 1(time zero file)
nfiles=$(echo "$FCST/$output_interval + 1" | bc)
echo "${nfiles} post to submit."
echo "Max ${maxpostpernode} submits per nodes."
how_many_nodes ${nfiles} ${maxpostpernode}

# Cria os diretorios e arquivos/links para cada saida do convert_mpas:
cd ${DIRRUN}
cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}
for ii in $(seq 1 ${nfiles})
do
   i=$(printf "%04d" ${ii})
   mkdir -p ${DIRRUN}/dir.${i}
   cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}/dir.${i}
   cp -f ${SCRIPTS}/namelists/include_fields.diag${VARTABLE}  ${DIRRUN}/dir.${i}/include_fields.diag${VARTABLE}
   cp -f ${DIRRUN}/dir.${i}/include_fields.diag${VARTABLE} ${DIRRUN}/dir.${i}/include_fields
   sed -e "s,#NISOLEV#,${NLEV},g;s,#NMODELLEV#,${N_MODEL_LEV},g" \
      ${SCRIPTS}/namelists/convert_mpas.nml > ${DIRRUN}/dir.${i}/convert_mpas.nml
   sed -e "s,#NLAT#,${NLAT},g;s,#NLON#,${NLON},g;s,#STARTLAT#,${STARTLAT},g;s,#ENDLAT#,${ENDLAT},g;s,#STARTLON#,${STARTLON},g;s,#ENDLON#,${ENDLON},g;" \
      ${SCRIPTS}/namelists/target_domain.TEMPLATE > ${DIRRUN}/dir.${i}/target_domain

done

cd ${DIRRUN}

# Laco para criar os arquivos de submissao com os blocos de convertmpas para cada node:
node=1
inicio=1   
fim=$((maxpostpernode <= nfiles ? maxpostpernode : nfiles))
while [ ${inicio} -le ${nfiles} ]
do
   rm -f ${DIRRUN}/PostAtmos_node.${node}.sh
cat > ${DIRRUN}/PostAtmos_node.${node}.sh <<EOSH
#!/bin/bash -x
#SBATCH --job-name=MO.Pos${node}
#SBATCH --nodes=1
#SBATCH --partition=${POST_QUEUE}
#SBATCH --time=${POST_walltime}
#SBATCH --output=${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.e%j     # File name for standard error output
#SBATCH --exclusive

. ${DIRRUN}/setenv.bash

echo "Submitting posts ${inicio} to ${fim} in node Node ${node}."

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
   
   hh=${YYYYMMDDHHi:8:2}
   currentdate=\$(date -d "${YYYYMMDDHHi:0:8} \${hh}:00:00 \$(echo "(\${i}-1)*${t_strout:0:2}" | bc) hours \$(echo "(\${i}-1)*${t_strout:3:2}" | bc) minutes \$(echo "(\${i}-1)*${t_strout:6:2}" | bc) seconds" +"%Y%m%d%H.%M.%S")
   diag_name=MONAN_DIAG_G_MOD_${EXP}_${YYYYMMDDHHi}_\${currentdate}.x${RES}L${N_MODEL_LEV}.nc

   time  ./convert_mpas x1.${RES}.init.nc ${DATAOUT}/${YYYYMMDDHHi}/Model/\${diag_name}  > convert_mpas.output & 
   echo "./convert_mpas x1.${RES}.init.nc ${DATAOUT}/${YYYYMMDDHHi}/Model/\${diag_name} > convert_mpas.output"
done

# necessario aguardar as rodadas em background
wait

for ii in \$(seq  ${inicio} ${fim})
do
   i=\$(printf "%04d" \${ii})
   hh=${YYYYMMDDHHi:8:2}
   currentdate=\$(date -d "${YYYYMMDDHHi:0:8} \${hh}:00 \$(echo "(\${i}-1)*3" | bc) hours" +"%Y%m%d%H")
   diag_name_post=MONAN_DIAG_G_POS_${EXP}_${YYYYMMDDHHi}_\${currentdate}.00.00.x${RES}L${NLEV}.nc
   
   cd ${DIRRUN}/dir.\${i}
   cp latlon.nc  ${DATAOUT}/${YYYYMMDDHHi}/Post/\${diag_name_post} >> convert_mpas.output & 
   echo "cp latlon.nc  ${DATAOUT}/${YYYYMMDDHHi}/Post/\${diag_name_post}"  >> convert_mpas.output
   
done
 
wait
 
EOSH

   chmod a+x ${DIRRUN}/PostAtmos_node.${node}.sh
   cp -f ${DIRRUN}/PostAtmos_node.${node}.sh ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
   jobid[${node}]=$(sbatch --parsable ${DIRRUN}/PostAtmos_node.${node}.sh)
   echo "JobId node ${node} = ${jobid[${node}]} , convert_mpas ${inicio} to ${fim}"
  
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
cat > ${DIRRUN}/PostAtmos_node.${node}.sh <<EOSH
#!/bin/bash
#SBATCH --job-name=MO.Pos${node}
#SBATCH --nodes=1
#SBATCH --partition=${POST_QUEUE}
#SBATCH --time=${POST_walltime}
#SBATCH --output=${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.e%j     # File name for standard error output

. ${DIRRUN}/setenv.bash


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
sbatch --wait --dependency=${dependency} ${DIRRUN}/PostAtmos_node.${node}.sh 

#CR: passar este scriptpara dentro do script PostAtmos_node.0.sh, submetido.
cd ${SCRIPTS}
time ${SCRIPTS}/make_template.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST}
