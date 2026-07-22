#!/bin/bash
umask 022
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

if [ $# -ne 4 -a $# -ne 1 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} [EXP_NAME/OP] RESOLUTION LABELI FCST"
   echo ""
   echo "EXP_NAME    :: Forcing: GFS"
   echo "RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)"
   echo "LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100"
   echo "FCST        :: Forecast hours, e.g.: 24 or 36, etc."
   echo ""
   echo "24 hour forecast example for 24km:"
   echo "${0} GFS 1024002 2024010100 24"
   echo "48 hour forecast example for 120km:"
   echo "${0} GFS   40962 2024010100 48"
   echo ""

   exit
fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash

echo ""
echo "---- Run Model ----"
echo ""


# Standart directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT; mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_CD-CT;   mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;           mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;             mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;           mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;           mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;               mkdir -p ${EXECS}
#----------------------------------------------------------------------


# Input variables:--------------------------------------
EXP=${1};         #EXP=GFS
RES=${2};         #RES=1024002
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2024012000
FCST=${4};        #FCST=6
#-------------------------------------------------------
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Model/logs


# Local variables--------------------------------------
start_date=${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}:00:00
cores=${MODEL_ncores}
hhi=${YYYYMMDDHHi:8:2}
NLEV=55
CONFIG_CONV_INTERVAL="00:30:00"
VARTABLE=".OPER"
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#------------------------------------------------------------------------------------

# Variables for flex outpout interval from streams.atmosphere------------------------
t_strout=$(cat ${SCRIPTS}/namelists/streams.atmosphere.TEMPLATE | sed -n '/<stream name="diagnostics"/,/<\/stream>/s/.*output_interval="\([^"]*\)".*/\1/p')
t_stroutsec=$(echo ${t_strout} | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}')
t_strouthor=$(echo "scale=4; (${t_stroutsec}/60)/60" | bc)
#------------------------------------------------------------------------------------

# Format to HH:MM:SS t_strout (output_interval)
IFS=":" read -r h m s <<< "${t_strout}"
printf -v t_strout "%02d:%02d:%02d" "$h" "$m" "$s"
# From now on, CONFI_LEN_DISP becames cte = 0.0, pickin up this value from static file.

# Calculating default parameters for different resolutions
if [ $RES -eq 1024002 ]; then  #24Km
   CONFIG_DT=150.0
   CONFIG_CONV_INTERVAL="00:15:00"
elif [ $RES -eq 2621442 ]; then  #15Km
   CONFIG_DT=90.0
   CONFIG_CONV_INTERVAL="00:15:00"
elif [ $RES -eq 40962 ]; then  #120Km
   CONFIG_DT=600.0
   CONFIG_CONV_INTERVAL="00:15:00"
elif [ $RES -eq 163842 ]; then  #60Km
   CONFIG_DT=300.0
   CONFIG_CONV_INTERVAL="00:15:00"
elif [ $RES -eq 655362 ]; then  #30Km
   CONFIG_DT=150.0
   CONFIG_CONV_INTERVAL="00:15:00"
elif [ $RES -eq 5898242 ]; then  #10Km
   CONFIG_DT=60.0
   CONFIG_CONV_INTERVAL="00:15:00"
elif [ $RES -eq 65536002 ]; then  #3Km
   CONFIG_DT=18.0
   CONFIG_CONV_INTERVAL="00:15:00"
fi
#-------------------------------------------------------


# Calculating final forecast dates in model namelist format: DD_HH:MM:SS 
# using: start_date(yyyymmdd) + FCST(hh) :
ind=$(printf "%02d\n" $(echo "${FCST}/24" | bc))
inh=$(printf "%02.0f\n" $(echo "((${FCST}/24)-${ind})*24" | bc -l))
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


files_needed=("${SCRIPTS}/namelists/stream_list.atmosphere.output" "${SCRIPTS}/namelists/stream_list.atmosphere.diagnostics${VARTABLE}" "${SCRIPTS}/namelists/stream_list.atmosphere.surface" "${EXECS}/atmosphere_model" "${DATAIN}/fixed/x1.${RES}.static.nc" "${DATAIN}/fixed/x1.${RES}.ugwp_oro_data.nc" "${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores}" "${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc" "${DATAIN}/fixed/Vtable.GFS" "${DATAIN}/fixed/ugwp_limb_tau.nc")
for file in "${files_needed[@]}"
do
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"   
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done

cp -f ${EXECS}/atmosphere_model ${DIRRUN}
cp -f ${DATAIN}/fixed/*TBL ${DIRRUN}
cp -f ${DATAIN}/fixed/*DBL ${DIRRUN}
cp -f ${DATAIN}/fixed/*DATA ${DIRRUN}
cp -f ${DATAIN}/fixed/x1.${RES}.static.nc ${DIRRUN}
cp -f ${DATAIN}/fixed/x1.${RES}.ugwp_oro_data.nc ${DIRRUN}
cp -f ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ${DIRRUN}
cp -f ${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc ${DIRRUN}
cp -f ${DATAIN}/fixed/Vtable.GFS ${DIRRUN}
cp -f ${DATAIN}/fixed/ugwp_limb_tau.nc ${DIRRUN}


if [ ${EXP} = "GFS" ]
then
   sed -e "s,#LABELI#,${start_date},g;s,#FCSTS#,${DD_HHMMSS_forecast},g;s,#RES#,${RES},g;
s,#CONFIG_DT#,${CONFIG_DT},g;s,#CONFIG_LEN_DISP#,${CONFIG_LEN_DISP},g;s,#CONFIG_CONV_INTERVAL#,${CONFIG_CONV_INTERVAL},g" \
   ${SCRIPTS}/namelists/namelist.atmosphere.TEMPLATE > ${DIRRUN}/namelist.atmosphere
   
   sed -e "s,#RES#,${RES},g;s,#CIORIG#,${EXP},g;s,#LABELI#,${YYYYMMDDHHi},g;s,#NLEV#,${NLEV},g" \
   ${SCRIPTS}/namelists/streams.atmosphere.TEMPLATE > ${DIRRUN}/streams.atmosphere
fi
cp -f ${SCRIPTS}/namelists/stream_list.atmosphere.output ${DIRRUN}
cp -f ${SCRIPTS}/namelists/stream_list.atmosphere.diagnostics${VARTABLE} ${DIRRUN}/stream_list.atmosphere.diagnostics
cp -f ${SCRIPTS}/namelists/stream_list.atmosphere.diag_ugwp${VARTABLE} ${DIRRUN}/stream_list.atmosphere.diag_ugwp
cp -f ${SCRIPTS}/namelists/stream_list.atmosphere.surface ${DIRRUN}
cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}


chmod 755 ${DIRRUN}

rm -f ${DIRRUN}/model.bash 

if [ ${SCHEDULER_SYSTEM} != "GENERIC" ]
then
   sed -e "s,#JOBNAME#,${MODEL_jobname},g;
   s,#NNODES#,${MODEL_nnodes},g;
   s,#NCPUS#,${MODEL_ncpus},g;
   s,#NTASKS#,${MODEL_ncores},g;
   s,#NTASKSPNODE#,${MODEL_ncpn},g;
   s,#NTHREADS#,${MODEL_nthreads},g;
   s,#PARTITION#,${MODEL_QUEUE},g;
   s,#WALLTIME#,${MODEL_walltime},g;
   s,#OUTPUTJOB#,${DATAOUT}/${YYYYMMDDHHi}/Model/logs/model.bash.o,g;
   s,#ERRORJOB#,${DATAOUT}/${YYYYMMDDHHi}/Model/logs/model.bash.e,g" \
   ${SCRIPTS}/stools/submit_${SYSTEM_KEY}.bash_TEMPLATE > ${DIRRUN}/model.bash 
else
   echo "#!/bin/bash " > ${DIRRUN}/model.bash 
fi

cat << EOF0 >> ${DIRRUN}/model.bash 

export executable=atmosphere_model

ulimit -c unlimited
ulimit -v unlimited
ulimit -s unlimited

cd ${DIRRUN}
. ${SCRIPTS}/setenv.bash

date
beg_secs=\`date +"%s"\`

if [ "$HOSTNAME" = "egeon" ]; then
   echo "-- SLURM_JOB_ID: \$SLURM_JOB_ID"
   time mpirun -np ${MODEL_ncores} ./\${executable}
else
   echo "-- PBS_JOBID: \$PBS_JOBID"
   time mpirun --ppn ${MODEL_ncpn} -np ${MODEL_ncores} --depth=${MODEL_nthreads} --cpu-bind depth ./\${executable}
fi

date
end_secs=\`date +"%s"\`

let wallsecs=\$end_secs-\$beg_secs
echo "MONAN time taken by run in seconds is " \$wallsecs

#
# move dataout, clean up and remove files/links
#
mv MONAN_DIAG_* ${DATAOUT}/${YYYYMMDDHHi}/Model
cp -f ${EXECS}/MONAN-VERSION.txt ${DATAOUT}/${YYYYMMDDHHi}/Model
cp -f ${EXECS}/MONAN-VERSION.txt ${DATAOUT}/${YYYYMMDDHHi}/Model/logs/
cp -f ${DIRHOMES}/VERSION.txt ${DATAOUT}/${YYYYMMDDHHi}/Model/logs/SCRIPTSCDCT-VERSION.txt
cp -f ${MONANDIR}/README.md ${DATAOUT}/${YYYYMMDDHHi}/Model/logs/
mv log.atmosphere.* ${DATAOUT}/${YYYYMMDDHHi}/Model/logs
mv namelist.atmosphere ${DATAOUT}/${YYYYMMDDHHi}/Model/logs
mv stream* ${DATAOUT}/${YYYYMMDDHHi}/Model/logs
EOF0
chmod a+x ${DIRRUN}/model.bash


case "${SCHEDULER_SYSTEM}" in
   SLURM)
      echo -e  "${GREEN}==>${NC} Submitting MONAN atmosphere model and waiting for finish before exit... \n"
      echo -e  "${GREEN}==>${NC} Logs being generated at ${DATAOUT}/logs... \n"
      echo -e  "sbatch ${SCRIPTS}/model.bash"
      cd ${DIRRUN}
      sbatch --wait ${DIRRUN}/model.bash
        ;;
    PBS)
      echo -e  "${GREEN}==>${NC} Submitting MONAN atmosphere model and waiting for finish before exit... \n"
      echo -e  "${GREEN}==>${NC} Logs being generated at ${DATAOUT}/logs... \n"
      echo -e  "${GREEN}==>${NC} qsub model.bash...\n"
      cd ${DIRRUN}
      qsub -W block=true ${DIRRUN}/model.bash
      ;;
#    GENERIC)
#      echo "Nenhum gerenciador detectado"
#      cd ${DIRRUN}
#      ${DIRRUN}/model.bash
#      ;;
esac
mv ${DIRRUN}/model.bash ${DATAOUT}/${YYYYMMDDHHi}/Model/logs


#-----Loop que verifica se os arquivos foram gerados corretamente (>0)-----
output_interval=${t_strouthor}
nfiles=$(echo "$FCST/$output_interval + 1" | bc)
for ii in $(seq 1 ${nfiles})
do
   i=$(printf "%04d" ${ii})
   hh=${YYYYMMDDHHi:8:2}
   currentdate=$(date -d "${YYYYMMDDHHi:0:8} ${hh}:00:00 $(echo "(${i}-1)*${t_strout:0:2}" | bc) hours $(echo "(${i}-1)*${t_strout:3:2}" | bc) minutes $(echo "(${i}-1)*${t_strout:6:2}" | bc) seconds" +"%Y%m%d%H.%M.%S")
   file=MONAN_DIAG_G_MOD_${EXP}_${YYYYMMDDHHi}_${currentdate}.x${RES}L${NLEV}.nc

   if [ ! -s ${DATAOUT}/${YYYYMMDDHHi}/Model/${file} ]
   then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"   
    echo -e  "${RED}==>${NC} [${0}] At least the file ${DATAOUT}/${YYYYMMDDHHi}/Model/${file} was not generated. \n"
    exit -1
   fi

done

JOBID=$(sed -n '5p' ${DATAOUT}/${YYYYMMDDHHi}/Model/logs/model.bash.o | awk '{print $3}' | sed "s/.pbs-ha//g")
mv ${DATAOUT}/${YYYYMMDDHHi}/Model/logs/model.bash.o ${DATAOUT}/${YYYYMMDDHHi}/Model/logs/model.bash.o.${JOBID}
mv ${DATAOUT}/${YYYYMMDDHHi}/Model/logs/model.bash.e ${DATAOUT}/${YYYYMMDDHHi}/Model/logs/model.bash.e.${JOBID}
chmod a+r ${DATAOUT}/${YYYYMMDDHHi}/Model/logs/model.bash.o.${JOBID}
chmod a+r ${DATAOUT}/${YYYYMMDDHHi}/Model/logs/model.bash.e.${JOBID}

rm -fr ${DIRRUN}
