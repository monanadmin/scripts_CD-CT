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

if [ $# -ne 4 -a $# -ne 1 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} EXP RESOLUTION LABELI FCST"
   echo ""
   echo "EXP         :: Initial or lateral boundary condition dataset (GFS or ERA)"
   echo "RESOLUTION  :: Number of horizontal grid cells (global) or regional mesh identifier (e.g., 1024002 for the ~24 km mesh)"
   echo "LABELI      :: Forecast initialization date and time (YYYYMMDDHH), e.g., 2026080100"
   echo "FCST        :: Forecast length in hours (e.g., 24, 36, 48, etc.)"
   echo ""
   echo "Example of a 24-hour forecast:"
   echo "${0} GFS 655362 2026080100 24"
   echo ""
   exit
fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash

echo ""
echo "---- Run Post ----"
echo ""


# Standart directories variables:---------------------------------------
DIRHOMES=$(dirname "$(pwd)");          mkdir -p ${DIRHOMES}  
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
maxpostpernode=30    # <------ qtde max de convert_mpas por no!
VARTABLE=".OPER"
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
N_MODEL_LEV=55
NLEV=18
#-------------------------------------------------------

# Variables for flex outpout interval from streams.atmosphere------------------------
t_strout=$(cat ${SCRIPTS}/namelists/streams.atmosphere.TEMPLATE | sed -n '/<stream name="diagnostics"/,/<\/stream>/s/.*output_interval="\([^"]*\)".*/\1/p')
t_stroutsec=$(echo ${t_strout} | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}')
t_strouthor=$(echo "scale=4; (${t_stroutsec}/60)/60" | bc)
#------------------------------------------------------------------------------------

# Definindo G ou R no MONAN_DIAG
if [[ $MODERUN == "R" ]]; then
   RORG=R
   echo -e "Post is running in Regional (limited-area) mode.\n"
elif [[ $MODERUN == "G" ]]; then
   RORG=G
   echo -e "Post is running in Global mode.\n"
else
   echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
   echo -e  "${RED}==>${NC} Post fails! Please select MODERUN=R (Regional) or MODERUN=G (Global) in 'setenv.bash'.\n"
   echo -e  "${RED}==>${NC} Exiting script. \n"
   exit -1
fi
#------------------------------------------------------------------------------------


# Format to HH:MM:SS t_strout (output_interval)
IFS=":" read -r h m s <<< "${t_strout}"
printf -v t_strout "%02d:%02d:%02d" "$h" "$m" "$s"

# Calculating default parameters for different resolutions
# global mesh
if [[ "$RES" == "40962" ]]; then  #120Km
   NLAT=151 #180/1.2
   NLON=301 #360/1.2
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "163842" ]]; then  #60Km
   NLAT=301 #180/0.6
   NLON=601 #360/0.6
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "655362" ]]; then  #30Km
   NLAT=601 #180/0.3
   NLON=1201 #360/0.3
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "1024002" ]]; then  #24Km
   NLAT=721  #180/0.25
   NLON=1441 #360/0.25
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "2621442" ]]; then  #15Km
   NLAT=1201 #180/0.15
   NLON=2401 #360/0.15
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "5898242" ]]; then  #10Km
   NLAT=1801 #180/0.10
   NLON=3601 #360/0.10
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "23592962" ]]; then  #5Km
   NLAT=3601 #180/0.05
   NLON=7201 #360/0.05
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "65536002" ]]; then  #3Km
   NLAT=6001 #180/0.03 
   NLON=12001 #360/0.03 
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
# regional mesh
elif [[ "$RES" == "655362.REG.AMS_CAR" ]]; then #30 km (AMS + Caribe)
   NLAT=354     #106/0.3 +1
   NLON=301     #90/0.3 +1
   STARTLAT=-64.0
   ENDLAT=42
   STARTLON=254.0
   ENDLON=344.0
elif [[ "$RES" == "5898242.REG.AMS_CAR" ]]; then #10 km (AMS + Caribe)
   NLAT=1061   #106/0.1 +1
   NLON=901   #90/0.1 +1
   STARTLAT=-64.0
   ENDLAT=42.0
   STARTLON=254.0
   ENDLON=344.0
elif [[ "$RES" == "23592962.REG.AMS_CAR" ]]; then #5 km (AMS + Caribe)
   NLAT=2121    #106/0.05 +1
   NLON=1801    #90/0.05 +1
   STARTLAT=-64.0
   ENDLAT=42.0
   STARTLON=254.0
   ENDLON=344.0
else
   # Define convert_mpas target domain automatically from the grid file
   echo -e "Calculating convert_mpas target domain of personalized mesh...\n"
   GRIDFILE="${DATAIN}/fixed/x1.${RES}.grid.nc"
   MESH_RES_RAD=$(ncdump -v nominalMinDc "${GRIDFILE}" 2>/dev/null | awk '/nominalMinDc =/ {print $3; exit}')
   MESH_RES_KM=$(awk -v res="${MESH_RES_RAD}" 'BEGIN {printf "%.0f", res * 6371.0}')
   # Domain margin ("gordura")
   DOMAIN_MARGIN=3
   GRID_SPACING=$(awk -v res="${MESH_RES_KM}" 'BEGIN {printf "%.1f", res / 100.0}')
   # Get minimum and maximum cell-center coordinates
   LAT_MIN_RAD=$(cdo -s infon -selname,latCell "${GRIDFILE}" 2>/dev/null | awk '/latCell/ {print $9; exit}')
   LAT_MAX_RAD=$(cdo -s infon -selname,latCell "${GRIDFILE}" 2>/dev/null | awk '/latCell/ {print $11; exit}')
   LON_MIN_RAD=$(cdo -s infon -selname,lonCell "${GRIDFILE}" 2>/dev/null | awk '/lonCell/ {print $9; exit}')
   LON_MAX_RAD=$(cdo -s infon -selname,lonCell "${GRIDFILE}" 2>/dev/null | awk '/lonCell/ {print $11; exit}')
   # Convert radians to degrees
   RAD2DEG=57.29577951308232
   LAT_MIN=$(awk -v x="${LAT_MIN_RAD}" -v c="${RAD2DEG}" 'BEGIN {printf "%.1f", x*c}')
   LAT_MAX=$(awk -v x="${LAT_MAX_RAD}" -v c="${RAD2DEG}" 'BEGIN {printf "%.1f", x*c}')
   LON_MIN=$(awk -v x="${LON_MIN_RAD}" -v c="${RAD2DEG}" 'BEGIN {printf "%.1f", x*c}')
   LON_MAX=$(awk -v x="${LON_MAX_RAD}" -v c="${RAD2DEG}" 'BEGIN {printf "%.1f", x*c}')
   # Add domain margin ("gordura")
   STARTLAT=$(awk -v x="${LAT_MIN}" -v m="${DOMAIN_MARGIN}" 'BEGIN {printf "%.1f", x-m}')
   ENDLAT=$(awk -v x="${LAT_MAX}" -v m="${DOMAIN_MARGIN}" 'BEGIN {printf "%.1f", x+m}')
   STARTLON=$(awk -v x="${LON_MIN}" -v m="${DOMAIN_MARGIN}" 'BEGIN {printf "%.1f", x-m}')
   ENDLON=$(awk -v x="${LON_MAX}" -v m="${DOMAIN_MARGIN}" 'BEGIN {printf "%.1f", x+m}')
   # Number of intervals in the regular lat-lon grid.
   NLAT=$(awk -v start="${STARTLAT}" -v end="${ENDLAT}" -v d="${GRID_SPACING}" 'BEGIN {printf "%.0f", (end-start)/d}')
   NLON=$(awk -v start="${STARTLON}" -v end="${ENDLON}" -v d="${GRID_SPACING}" 'BEGIN {printf "%.0f", (end-start)/d}')
   echo -e "  Resolution     : ${MESH_RES_KM} km"
   echo -e "  STARTLAT       : ${STARTLAT}"
   echo -e "  ENDLAT         : ${ENDLAT}"
   echo -e "  STARTLON       : ${STARTLON}"
   echo -e "  ENDLON         : ${ENDLON}"
   echo -e "  NLAT           : ${NLAT}"
   echo -e "  NLON           : ${NLON}\n"
fi
#-------------------------------------------------------

files_needed=("${SCRIPTS}/namelists/include_fields.diag${VARTABLE}" "${SCRIPTS}/namelists/convert_mpas.nml" "${SCRIPTS}/namelists/target_domain.TEMPLATE" "${EXECS}/convert_mpas" "${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc")
for file in "${files_needed[@]}"
do
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
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
chmod -R 755 ${DIRRUN}/*

# Laco para criar os arquivos de submissao com os blocos de convertmpas para cada node:
echo "scheduler system = " ${SCHEDULER_SYSTEM} 
echo "system key = " ${SYSTEM_KEY}
echo ""
# Laco para criar os arquivos de submissao com os blocos de convertmpas para cada node:
node=1
inicio=1   
fim=$((maxpostpernode <= nfiles ? maxpostpernode : nfiles))
while [ ${inicio} -le ${nfiles} ]
do
   rm -f ${DIRRUN}/PostAtmos_node.${node}.sh

   if [ ${SCHEDULER_SYSTEM} != "GENERIC" ]   
   then
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
   else
      echo "#!/bin/bash " > ${DIRRUN}/PostAtmos_node.${node}.sh
   fi
   
cat << EOSH >> ${DIRRUN}/PostAtmos_node.${node}.sh 

cd ${DIRRUN}
. ${SCRIPTS}/setenv.bash

if [ ${SCHEDULER_SYSTEM} == "SLURM" ]; then
   echo "-- SLURM_JOB_ID: \$SLURM_JOB_ID"
elif [ ${SCHEDULER_SYSTEM} == "PBS" ]; then
   echo "-- PBS_JOBID: \$PBS_JOBID"
fi

chmod 755 ${DIRRUN}/*

echo "Executing posts ${inicio} to ${fim} in node Node ${node}."

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
   diag_name=MONAN_DIAG_${RORG}_MOD_${EXP}_${YYYYMMDDHHi}_\${currentdate}.x${RES}L${N_MODEL_LEV}.nc
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
   diag_name_post=MONAN_DIAG_${RORG}_POS_${EXP}_${YYYYMMDDHHi}_\${currentdate}.x${RES}L${N_MODEL_LEV}.nc

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
         echo -e "${GREEN}==>${NC} sbatch PostAtmos_node.${node}.sh"
         jobid[${node}]=$(sbatch --parsable ${DIRRUN}/PostAtmos_node.${node}.sh)
         echo "JobId node ${node} = ${jobid[${node}]} , convert_mpas ${inicio} to ${fim}"
         echo ""
         ;;
       PBS)         
         echo -e "${GREEN}==>${NC} qsub PostAtmos_node.${node}.sh...\n"
         cd ${DIRRUN}
 	 jobid[${node}]=$(qsub ${DIRRUN}/PostAtmos_node.${node}.sh | cut -d '.' -f1)
         jobid[${node}]=${jobid[${node}]%%.*}
         ;;
#      GENERIC)
#         echo "Nenhum gerenciador detectado"
#         ${DIRRUN}/PostAtmos_node.${node}.sh
#         ;;
   esac
  
   inicio=$((fim + 1))
   temp=$((fim + maxpostpernode))
   fim=$(( temp < nfiles ? temp : nfiles ))
   node=$((node+1))
   sleep 5
done

total_nodes=${node}

# Dependencias JobId:
dependency="afterok"
for job_id in "${jobid[@]}"
do
   dependency="${dependency}:${job_id}"
done


# Script final , para conferir todos os arquivos, criar o template final  e apagar o diretorio DIRRUN
node=0
rm -f ${DIRRUN}/PostAtmos_node.${node}.sh


if [ ${SCHEDULER_SYSTEM} != "GENERIC" ]   
then
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
else
   echo "#!/bin/bash " > ${DIRRUN}/PostAtmos_node.${node}.sh
fi

cat << EOSH >> ${DIRRUN}/PostAtmos_node.${node}.sh 

cd ${DIRRUN}
. ${SCRIPTS}/setenv.bash

if [ ${SCHEDULER_SYSTEM} == "SLURM" ]; then
   echo "-- SLURM_JOB_ID: \$SLURM_JOB_ID"
elif [ ${SCHEDULER_SYSTEM} == "PBS" ]; then
   echo "-- PBS_JOBID: \$PBS_JOBID"
fi

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
      echo -e "${GREEN}==>${NC} sbatch PostAtmos_node.${node}.sh...\n"
      cd ${DIRRUN}
      sbatch --wait --dependency=${dependency} ${DIRRUN}/PostAtmos_node.${node}.sh 
      ;;
    PBS)
      echo -e "${GREEN}==>${NC} qsub PostAtmos_node.${node}.sh...\n"
      cd ${DIRRUN}
      JOBID=$(qsub -W depend=${dependency} -W block=true ${DIRRUN}/PostAtmos_node.${node}.sh)
      JOBID=${JOBID%%.*}
      mv ${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.o ${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.o.${JOBID}
      mv ${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.e ${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.e.${JOBID}
      ;;
#   GENERIC)
#      echo "Nenhum gerenciador detectado"
#      ${DIRRUN}/PostAtmos_node.${node}.sh
#      ;;
esac


#CR: passar este scriptpara dentro do script PostAtmos_node.0.sh, submetido.
cd ${SCRIPTS}
chmod -R 755 ${DATAOUT}/${YYYYMMDDHHi}/Post/*
time ${SCRIPTS}/make_template.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST}

for ((n=1 ; n<total_nodes ; n++)) 
do
   if [ ${SCHEDULER_SYSTEM} = "SLURM" ]; then
      : # Slurm já gera JOBID na submissão.
   elif [ ${SCHEDULER_SYSTEM} = "PBS" ]; then
      mv ${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node."${n}".o ${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node."${n}".o.${jobid[${n}]}
      mv ${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node."${n}".e ${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node."${n}".e.${jobid[${n}]}
fi
done
echo -e "\n$(basename "$0") completed successfully.\n"
