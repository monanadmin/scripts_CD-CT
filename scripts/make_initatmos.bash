#!/bin/bash 
umask 022

if [ $# -ne 4 ]
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
echo "---- Make Init Atmosphere ----"
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
FCST=${4};        #FCST=24
#-------------------------------------------------------


# Local variables--------------------------------------
start_date=${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}:00:00
GEODATA=${DATAIN}/WPS_GEOG
cores=${INITATMOS_ncores}
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#-------------------------------------------------------
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs

if [ ! -s ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ]
then
   if [ ! -s ${DATAIN}/fixed/x1.${RES}.graph.info ]
   then
      cd ${DATAIN}/fixed
      echo -e "${GREEN}==>${NC} downloading meshes tgz files ... \n"
      cd ${DATAIN}/fixed
      wget https://www2.mmm.ucar.edu/projects/mpas/atmosphere_meshes/x1.${RES}.tar.gz
      tar -xzvf x1.${RES}.tar.gz
   fi
   echo -e "${GREEN}==>${NC} Creating x1.${RES}.graph.info.part.${cores} ... \n"
   cd ${DATAIN}/fixed
   gpmetis -minconn -contig -niter=200 x1.${RES}.graph.info ${cores}
   rm -fr x1.${RES}.tar.gz
fi


files_needed=("${SCRIPTS}/namelists/namelist.init_atmosphere.TEMPLATE" "${SCRIPTS}/namelists/streams.init_atmosphere.TEMPLATE" "${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores}" "${DATAIN}/fixed/x1.${RES}.static.nc" "${DATAIN}/fixed/x1.${RES}.ugwp_oro_data.nc" "${DATAOUT}/${YYYYMMDDHHi}/Pre/${EXP}:${start_date:0:13}" "${EXECS}/init_atmosphere_model")
for file in "${files_needed[@]}"
do
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done

if [[ $MODERUN == "R" ]]; then
   BLEND_BDY_TERRAIN=true
   echo -e "\nInit_atmos is running in Regional (limited-area) mode.\n"
elif [[ $MODERUN == "G" ]]; then
   BLEND_BDY_TERRAIN=false
   echo -e "\nInit_atmos is running in Global mode.\n"
else
   echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
   echo -e  "${RED}==>${NC} Init_atmos fails! Please select MODERUN=R (Regional) or MODERUN=G (Global) in 'setenv.bash'.\n"
   echo -e  "${RED}==>${NC} Exiting script. \n"
   exit -1
fi

sed -e "s,#LABELI#,${start_date},g;s,#GEODAT#,${GEODATA},g;s,#RES#,${RES},g;s,#EXP#,${EXP},g;s,#BLEND_BDY_TERRAIN#,${BLEND_BDY_TERRAIN},g" \
    ${SCRIPTS}/namelists/namelist.init_atmosphere.TEMPLATE > ${DIRRUN}/namelist.init_atmosphere

sed -e "s,#RES#,${RES},g" \
    ${SCRIPTS}/namelists/streams.init_atmosphere.TEMPLATE > ${DIRRUN}/streams.init_atmosphere

cp -f ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ${DIRRUN}
cp -f ${DATAIN}/fixed/x1.${RES}.static.nc ${DIRRUN}
cp -f ${DATAIN}/fixed/QNWFA_QNIFA_SIGMA_MONTHLY.dat ${DIRRUN}
cp -f ${DATAOUT}/${YYYYMMDDHHi}/Pre/${EXP}\:${start_date:0:13} ${DIRRUN}
cp -f ${EXECS}/init_atmosphere_model ${DIRRUN}
cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}

chmod 755 ${DIRRUN}/*
chmod 755 ${DATAOUT}/${YYYYMMDDHHi}/Pre/*

rm -f ${DIRRUN}/initatmos.bash 

if [ ${SCHEDULER_SYSTEM} != "GENERIC" ]
then
   sed -e "s,#JOBNAME#,${INITATMOS_jobname},g;
   s,#NNODES#,${INITATMOS_nnodes},g;
   s,#NCPUS#,${INITATMOS_ncpus},g;
   s,#NTASKS#,${INITATMOS_ncores},g;
   s,#NTASKSPNODE#,${INITATMOS_ncpn},g;
   s,#NTHREADS#,${INITATMOS_nthreads},g;
   s,#PARTITION#,${INITATMOS_QUEUE},g;
   s,#WALLTIME#,${INITATMOS_walltime},g;
   s,#OUTPUTJOB#,${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/initatmos.bash.o,g;
   s,#ERRORJOB#,${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/initatmos.bash.e,g" \
   ${SCRIPTS}/stools/submit_${SYSTEM_KEY}.bash_TEMPLATE > ${DIRRUN}/initatmos.bash 
else
   echo "#!/bin/bash " > ${DIRRUN}/initatmos.bash 
fi

cat << EOF0 >> ${DIRRUN}/initatmos.bash 

export executable=init_atmosphere_model

ulimit -c unlimited
ulimit -v unlimited
ulimit -s unlimited

cd ${DIRRUN}
. ${SCRIPTS}/setenv.bash

date
beg_secs=\`date +"%s"\`

if [ ${SCHEDULER_SYSTEM} == "SLURM" ]; then
   echo "-- SLURM_JOB_ID: \$SLURM_JOB_ID"
   time mpirun -np ${INITATMOS_ncores} ./\${executable}
elif [ ${SCHEDULER_SYSTEM} == "PBS" ]; then
   echo "-- PBS_JOBID: \$PBS_JOBID"
   time mpirun --ppn ${INITATMOS_ncpn} -np ${INITATMOS_ncores} --depth=${INITATMOS_nthreads} --cpu-bind depth ./\${executable}
fi

date
end_secs=\`date +"%s"\`

let wallsecs=\$end_secs-\$beg_secs
echo "INITATMOS time taken by run in seconds is " \$wallsecs

mv ${DIRRUN}/log.init_atmosphere.0000.out ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/log.init_atmosphere.0000.x1.${RES}.init.nc.${YYYYMMDDHHi}.out
mv ${DIRRUN}/namelist.init_atmosphere ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs
mv ${DIRRUN}/streams.init_atmosphere ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs
mv ${DIRRUN}/x1.${RES}.init.nc ${DATAOUT}/${YYYYMMDDHHi}/Pre

EOF0

chmod a+x ${DIRRUN}/initatmos.bash

case "${SCHEDULER_SYSTEM}" in
   SLURM)
      echo -e  "\n${GREEN}==>${NC} sbatch initatmos.bash...\n"
      cd ${DIRRUN}
      sbatch --wait ${DIRRUN}/initatmos.bash
      ;;
    PBS)
      echo -e  "\n${GREEN}==>${NC} qsub initatmos.bash...\n"
      cd ${DIRRUN}
      JOBID=$(qsub -W block=true ${DIRRUN}/initatmos.bash)
      JOBID=${JOBID%%.*}
      mv ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/initatmos.bash.o ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/initatmos.bash.o.${JOBID}
      mv ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/initatmos.bash.e ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/initatmos.bash.e.${JOBID}
      ;;
#    GENERIC)
#      echo "Nenhum gerenciador detectado"
#      cd ${DIRRUN}
#      ${DIRRUN}/initatmos.bash
#      ;;
esac
mv ${DIRRUN}/initatmos.bash ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs

if [ ! -s ${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc ]
then
  echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	
  echo -e  "${RED}==>${NC} Init Atmosphere phase fails! Check logs at ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/initatmos.* .\n"
  echo -e  "${RED}==>${NC} Exiting script. \n"
  exit -1
fi

chmod -R 755 ${DATAOUT}/${YYYYMMDDHHi}/Pre/*
rm -fr ${DIRRUN}
