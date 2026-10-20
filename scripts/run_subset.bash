#!/bin/bash 
umask 022
set -e
trap 'echo -e "\n${RED}==>${NC} $(basename "$0") failed.\n"' ERR
#-----------------------------------------------------------------------------#
# !SCRIPT: run_subset
#
# !DESCRIPTION:
#     Script to generate subset from Regional or Global MONAN simulation.
#     
#     subsets:
# 
#        ACC = MONAN output subset for Central America and Caribbean
#        AMS = MONAN output subset for South America
#        CUSTOM = lat1 lat2 lon1 lon2
#        
#
#-----------------------------------------------------------------------------#

if [ $# -ne 5 ] && [ $# -ne 9 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} EXP RES_MESH LABELI FCST SUBSET_CODE"
   echo ""
   echo "EXP           :: Initial or lateral boundary condition dataset (GFS or ERA)"
   echo "RES_MESH      :: Number of horizontal grid cells (global) or regional mesh identifier (e.g., 1024002 for the ~24 km mesh)"
   echo "LABELI        :: Forecast initialization date and time (YYYYMMDDHH), e.g., 2026080100"
   echo "FCST          :: Forecast length in hours (e.g., 24, 36, 48, etc.)"
   echo "SUBSET_CODE   :: Subsets from MONAN simulations, options: ACC=Central America and Caribbean; AMS=South America;"
   echo "              ::                                          CUSTOM=lon1 lon2 lat1 lat2"
   echo ""
   echo "Example of a 24-hour forecast:"
   echo "${0} GFS 655362 2026080100 24 ACC"
   echo "${0} GFS 655362 2026080100 24 CUSTOM 305.8 316.8 -26.3 -18.7"
   echo ""
   exit 1
fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash

# Avisa caso usuario passe valores lon1 lon2 lat1 e lat2 mas não escolhe CUSTOM
if [ $# -gt 5 ] && [ "${5}" != "CUSTOM" ]; then
   echo -e "\n${YELLOW}==>${NC} Subset '${5}' does not use extra arguments. Ignoring: ${6} ${7} ${8} ${9}"
fi

# Teste dos lats e lons para o CUSTOM, se são numeros, faixa 
if [ "${5}" = "CUSTOM" ]; then
   for val in "${6}" "${7}" "${8}" "${9}"; do
      # aceita inteiros, decimais, com sinal
      if ! [[ "${val}" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
         echo -e "\n${RED}==>${NC} ERROR: CUSTOM argument '${val}' is not a valid number."
	 echo -e "Expected: lon1 lon2 lat1 lat2 (e.g., 305.8 316.8 -26.3 -18.7)\n"
         exit 1
      fi
   done
fi

#------- Subset setup
case ${5} in
   ACC)
   cdolatbox=266,302,6,28
   ;;
   AMS)
   cdolatbox=274,329,-58,15
   ;;  
   CUSTOM)
   cdolatbox=${6},${7},${8},${9}
   ;;
   *)
   echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
   echo -e  "${RED}==>${NC} Subset phase failed! Invalid subset. Please select ACC; AMS or CUSTOM\n"
   echo -e  "${RED}==>${NC} Exiting script. \n"
   exit 1
   ;;
esac


echo ""
echo -e "---- Subset ----"
echo ""

# Standart directories variables:--------------------------------------
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
RES=${2};         #RES=655362
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2026080100
FCST=${4};        #FCST=24
SUBSET=${5};      #SUBSET=ACC
SUBSETDIR="Subset/${SUBSET}"
#-------------------------------------------------------
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/logs

# Local variables---------------------------------------
START_DATE_YYYYMMDD="${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}"
START_HH="${YYYYMMDDHHi:8:2}"
maxprodpernode=128
VARTABLE=".OPER"
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
NLEV=55
#-------------------------------------------------------

# Variables for flex outpout interval from streams.atmosphere------------------------
t_strout=$(cat ${SCRIPTS}/namelists/streams.atmosphere.TEMPLATE | sed -n '/<stream name="diagnostics"/,/<\/stream>/s/.*output_interval="\([^"]*\)".*/\1/p')
t_stroutsec=$(echo ${t_strout} | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}')
t_strouthor=$(echo "scale=4; (${t_stroutsec}/60)/60" | bc)
t_stroutmin=$(echo "${t_stroutsec}/60" | bc)
#------------------------------------------------------------------------------------

# Format to HH:MM:SS t_strout (output_interval)
IFS=":" read -r h m s <<< "${t_strout}"
printf -v t_strout "%02d:%02d:%02d" "$h" "$m" "$s"

output_interval=${t_strouthor}
nfiles=$(echo "$FCST/$output_interval + 1" | bc)

# Definindo G ou R no MONAN_DIAG
if [[ $MODERUN == "R" ]]; then
   RORG=R
   echo -e "\n${GREEN}==>${NC} Create subset ${SUBSET} from regional simulation.\n"
elif [[ $MODERUN == "G" ]]; then
   RORG=G
   echo -e "\n${GREEN}==>${NC} Create subset ${SUBSET} from global simulation.\n"
else
   echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
   echo -e  "${RED}==>${NC} Subset phase fails! Please select MODERUN=R (Regional) or MODERUN=G (Global) in 'setenv.bash'.\n"
   echo -e  "${RED}==>${NC} Exiting script. \n"
   exit 1
fi
#------------------


# Captura quantos arquivos do post tem e quando nos serao necessarios para executar ${maxpostpernode} o cdo
# from streams.atmosphere.TEMPLATE in diagnostics the output_interval is flexible
output_interval=${t_strouthor}
#nfiles=FCST/output_interval + 1(time zero file)
nfiles=$(echo "$FCST/$output_interval + 1" | bc)
echo "${nfiles} post to submit."
echo "Max ${maxprodpernode} submits files per nodes."
how_many_nodes ${nfiles} ${maxprodpernode}

# Laco para criar os arquivos de submissao com os blocos de convertmpas para cada node:
echo "scheduler system = " ${SCHEDULER_SYSTEM}
echo "system key = " ${SYSTEM_KEY}
echo ""

#testa existencia dos arquivos
for i in $(seq 1 ${nfiles})
do
   i=$(printf "%04d" ${i})
   hh=${YYYYMMDDHHi:8:2}
   currentdate=$(date -d "${YYYYMMDDHHi:0:8} ${hh}:00:00 $(echo "(${i}-1)*${t_strout:0:2}" | bc) hours $(echo "(${i}-1)*${t_strout:3:2}" | bc) minutes $(echo "(${i}-1)*${t_strout:6:2}" | bc) seconds" +"%Y%m%d%H.%M.%S")
   diag_name=MONAN_DIAG_${RORG}_POS_${EXP}_${YYYYMMDDHHi}_${currentdate}.x${RES}L${NLEV}.nc
   echo "Testing: ${diag_name}"
   if [ ! -e ${DATAOUT}/${YYYYMMDDHHi}/Post/${diag_name} ]; then
      echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n" >&2
      echo -e  "${RED}==>${NC} [${0}] File not found: ${DATAOUT}/${YYYYMMDDHHi}/Post/${diag_name} \n" >&2
      exit 1
   fi
done

echo -e "\nPost files found. Running CDO...\n"

# Laco para criar os arquivos de submissao com os blocos de convertmpas para cada node:
node=1
inicio=1
fim=$((maxprodpernode <= nfiles ? maxprodpernode : nfiles))
while [ ${inicio} -le ${nfiles} ]
do
   rm -f ${DIRRUN}/Subset_node.${node}.sh

   if [ ${SCHEDULER_SYSTEM} != "GENERIC" ]
   then
      sed -e "s,#JOBNAME#,MO.Subset${node},g;
      s,#NNODES#,${SUBSET_nnodes},g;
      s,#NCPUS#,${SUBSET_ncpus},g;
      s,#NTASKS#,${SUBSET_ncores},g;
      s,#NTASKSPNODE#,${SUBSET_ncpn},g;
      s,#NTHREADS#,${SUBSET_nthreads},g;
      s,#PARTITION#,${SUBSET_QUEUE},g;
      s,#WALLTIME#,${SUBSET_walltime},g;
      s,#OUTPUTJOB#,${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/logs/Subset_node.${node}.o,g;
      s,#ERRORJOB#,${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/logs/Subset_node.${node}.e,g" \
      ${SCRIPTS}/stools/submit_${SYSTEM_KEY}.bash_TEMPLATE > \
      ${DIRRUN}/Subset_node.${node}.sh
   else
      echo "#!/bin/bash " > ${DIRRUN}/Subset_node.${node}.sh
   fi

cat << EOSH >> ${DIRRUN}/Subset_node.${node}.sh

cd ${DIRRUN}
. ${SCRIPTS}/setenv.bash

if [ ${SCHEDULER_SYSTEM} == "SLURM" ]; then
   echo "-- SLURM_JOB_ID: \$SLURM_JOB_ID"
elif [ ${SCHEDULER_SYSTEM} == "PBS" ]; then
   echo "-- PBS_JOBID: \$PBS_JOBID"
fi

chmod 755 ${DIRRUN}/*

echo "Executing subset ${inicio} to ${fim} in Node ${node}."

for ii in \$(seq ${inicio} ${fim})
do
   i=\$(printf "%04d" \${ii})
   echo "Executing subset \${i}" >&2
   hh=${YYYYMMDDHHi:8:2}
   currentdate=\$(date -d "${YYYYMMDDHHi:0:8} \${hh}:00:00 \$(echo "(\${i}-1)*${t_strout:0:2}" | bc) hours \$(echo "(\${i}-1)*${t_strout:3:2}" | bc) minutes \$(echo "(\${i}-1)*${t_strout:6:2}" | bc) seconds" +"%Y%m%d%H.%M.%S")
   diag_name=MONAN_DIAG_${RORG}_POS_${EXP}_${YYYYMMDDHHi}_\${currentdate}.x${RES}L${NLEV}.nc
   outf=MONAN_DIAG_${RORG}_POS_${EXP}_${YYYYMMDDHHi}_\${currentdate}.x${RES}_S_${SUBSET}L${NLEV}.nc
   echo "Processing:  \${diag_name}  ->  CDO  -> \${outf}" >&2
   echo "time cdo -O -f nc4c -z zip_4 sellonlatbox,${cdolatbox} ${DATAOUT}/${YYYYMMDDHHi}/Post/\${diag_name} ${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/\${outf}"
done | parallel -j ${maxprodpernode} -v


EOSH

   chmod a+x ${DIRRUN}/Subset_node.${node}.sh
   chmod 755 ${DIRRUN}/*
   cp -f ${DIRRUN}/Subset_node.${node}.sh ${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/logs
   chmod 755 ${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/*

   case "${SCHEDULER_SYSTEM}" in
      SLURM)
         echo -e "${GREEN}===${NC} sbatch Subset_node.${node}.sh"
         jobid[${node}]=$(sbatch --parsable ${DIRRUN}/Subset_node.${node}.sh)
         echo "JobId node ${node} = ${jobid[${node}]} , Subset ${inicio} to ${fim}"
         echo ""
         ;;
       PBS)
         echo -e  "${GREEN}==>${NC} qsub Subset_node.${node}.sh...\n"
         cd ${DIRRUN}
	 jobid[${node}]=$(qsub ${DIRRUN}/Subset_node.${node}.sh | cut -d '.' -f1)
         jobid[${node}]=${jobid[${node}]%%.*}
         ;;
#      GENERIC)
#         echo "Nenhum gerenciador detectado"
#         ${DIRRUN}/Subset_node.${node}.sh
#         ;;
   esac
  
   inicio=$((fim + 1))
   temp=$((fim + maxprodpernode))
   fim=$(( temp < nfiles ? temp : nfiles ))
   node=$((node+1))
   sleep 3
done

total_nodes=${node}

# Dependencias JobId:
dependency="afterok"
for job_id in "${jobid[@]}"
do
   dependency="${dependency}:${job_id}"
done

# Script final, para conferir todos os arquivos, criar o template final  e apagar o diretorio DIRRUN
node=0
rm -f ${DIRRUN}/Subset_node.${node}.sh

if [ ${SCHEDULER_SYSTEM} != "GENERIC" ]   
then
   sed -e "s,#JOBNAME#,MO.Subset${node},g;
   s,#NNODES#,${SUBSET_nnodes},g;
   s,#NCPUS#,${SUBSET_ncpus},g;
   s,#NTASKS#,${SUBSET_ncores},g;
   s,#NTASKSPNODE#,${SUBSET_ncpn},g;
   s,#NTHREADS#,${SUBSET_nthreads},g;
   s,#PARTITION#,${SUBSET_QUEUE},g;
   s,#WALLTIME#,${SUBSET_walltime},g;
   s,#OUTPUTJOB#,${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/logs/Subset_node.${node}.o,g;
   s,#ERRORJOB#,${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/logs/Subset_node.${node}.e,g" \
   ${SCRIPTS}/stools/submit_${SYSTEM_KEY}.bash_TEMPLATE > \
   ${DIRRUN}/Subset_node.${node}.sh
   else
      echo "#!/bin/bash " > ${DIRRUN}/Subset_node.${node}.sh
fi

cat << EOSH >> ${DIRRUN}/Subset_node.${node}.sh 

cd ${DIRRUN}
. ${SCRIPTS}/setenv.bash

if [ ${SCHEDULER_SYSTEM} == "SLURM" ]; then
   echo "-- SLURM_JOB_ID: \$SLURM_JOB_ID"
elif [ ${SCHEDULER_SYSTEM} == "PBS" ]; then
   echo "-- PBS_JOBID: \$PBS_JOBID"
fi

# Apenas para aguuardar os jobs paralelos...
cp -f ${DIRRUN}/Subset_node.*.sh ${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/logs

EOSH
chmod a+x ${DIRRUN}/Subset_node.${node}.sh

case "${SCHEDULER_SYSTEM}" in
   SLURM)
      echo -e "${GREEN}==>${NC} sbatch Subset_node.${node}.sh...\n"
      cd ${DIRRUN}
      sbatch --wait --dependency=${dependency} ${DIRRUN}/Subset_node.${node}.sh 
      ;;
    PBS)
      echo -e "${GREEN}==>${NC} qsub Subset_node.${node}.sh...\n"
      cd ${DIRRUN}
      JOBID=$(qsub -W depend=${dependency} -W block=true ${DIRRUN}/Subset_node.${node}.sh)
      JOBID=${JOBID%%.*}
      mv ${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/logs/Subset_node.${node}.o ${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/logs/Subset_node.${node}.o.${JOBID}
      mv ${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/logs/Subset_node.${node}.e ${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/logs/Subset_node.${node}.e.${JOBID}
      ;;
#   GENERIC)
#      echo "Nenhum gerenciador detectado"
#      ${DIRRUN}/Subset_node.${node}.sh
#      ;;
esac

# -----Start: grads template generation-----
diag_name_templ=MONAN_DIAG_${RORG}_POS_${EXP}_${YYYYMMDDHHi}_%y4%m2%d2%h2.%n2.00.x${RES}_S_${SUBSET}L${NLEV}.nc
diag_name_subset=MONAN_DIAG_${RORG}_POS_${EXP}_${YYYYMMDDHHi}_${YYYYMMDDHHi}.00.00.x${RES}_S_${SUBSET}L${NLEV}.nc

# Remove old qctlinfo.gs
if [ -e "${DIRRUN}/qctlinfo.gs" ]; then
   rm -fr ${DIRRUN}/qctlinfo.gs
fi
cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}
chmod 755 ${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/*

# Creation grads script
cat > ${DIRRUN}/qctlinfo.gs <<EOGS
'reinit'
'sdfopen ${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/${diag_name_subset}' 
'q ctlinfo'
say result
'quit'
EOGS

# Run grads script
echo -e "${GREEN}==>${NC} Creating grads template file...\n"
grads -blc "run ${DIRRUN}/qctlinfo.gs" | awk '/dset/,/endvars/' > ${DIRRUN}/qctlinfo.ctl
chmod 755 ${DIRRUN}/qctlinfo.ctl
timectl=$(grep tdef ${DIRRUN}/qctlinfo.ctl | cut -d" " -f4)
sed -i '3a\options template' ${DIRRUN}/qctlinfo.ctl
sed -i "/tdef/c\tdef ${nfiles} linear ${timectl} ${t_stroutmin}mn" ${DIRRUN}/qctlinfo.ctl
sed -i "/dset/c\dset ^${diag_name_templ}" ${DIRRUN}/qctlinfo.ctl

chmod 755 ${DIRRUN}/*
mv ${DIRRUN}/qctlinfo.ctl ${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/${diag_name_subset}.template.ctl
rm -fr ${DIRRUN}
# -----End: grads template generation-----

# -----jobid-----
for ((n=1 ; n<total_nodes ; n++)) 
do
   if [ ${SCHEDULER_SYSTEM} = "SLURM" ]; then
      : # Slurm já gera JOBID na submissão.
   elif [ ${SCHEDULER_SYSTEM} = "PBS" ]; then
      mv ${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/logs/Subset_node.${n}.o ${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/logs/Subset_node.${n}.o.${jobid[${n}]}
      mv ${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/logs/Subset_node.${n}.e ${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/logs/Subset_node.${n}.e.${jobid[${n}]}
   fi
done

chmod -R 755 ${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}/*
echo -e "Subset generated in the folder ${DATAOUT}/${YYYYMMDDHHi}/${SUBSETDIR}\n"
echo -e "\n$(basename "$0") completed successfully.\n"
