#!/bin/bash 
umask 022




#--- Function that shows usage.
function show_usage() {
   echo " Usage: "
   echo ""
   echo " ${0} [-h] [-m12] [-e EXP ] [-f FCST] [-r RES] [-t YYYYMMDDHH]"
   echo ""
   echo " List of optional flags: "
   echo " -h              -- Shows this message."
   echo " -m12            -- Is this a MONAN run based on 1.2.0-rc and branches derived"
   echo "                    from this version (e.g., feature/monan-757-NF)? This is a"
   echo "                    temporary flag that will be removed once the versions"
   echo "                    containing Noah-MP are merged into the new release. This"
   echo "                    allows the script to manage older code and still run on jaci."
   echo ""
   echo " List of **required** flags: "
   echo ""
   echo " -e EXP          -- meteorological drivers. For example, GFS"
   echo " -f FCST         -- Simulation length in hours, e.g., 24 or 48."
   echo " -r RES          -- grid resolution. Supported options are:"
   echo "                    65536002 (~ 3 km)"
   echo "                    5898242  (~ 10 km)"
   echo "                    2621442  (~ 15 km)"
   echo "                    1024002  (~ 24 km)"
   echo "                    655362   (~ 30 km)"
   echo "                    163842   (~ 60 km)"
   echo "                    40962    (~ 120 km)"
   echo " -t YYYYMMDDHH   -- Initial time. For example if 22 Sept 2025 00 UTC, set it to:"
   echo "                    2025092200"
   echo ""
}
#---~---



#--- Default input variables:
MONAN_ONETWO=""
EXP=""
RES=""
YYYYMMDDHHi=""
FCST=""
#---~---


#--- Parse arguments.
while [[ ${#} > 0 ]]
do
   key="${1}"
   case ${key} in
   -e)
      EXP="${2}"
      shift 2 # past flag and argument
      ;;
   -f)
      FCST="${2}"
      shift 2 # past flag and argument
      ;;
   -h)
      show_usage
      exit 0
      ;;
   -m12)
      MONAN_ONETWO="${key}"
      shift 1 # past flag
      ;;
   -r)
      RES="${2}"
      shift 2 # past flag and argument
      ;;
   -t)
      YYYYMMDDHHi="${2}"
      shift 2 # past flag and argument
      ;;
   *)
      echo ""
      echo " Option \"${key}\" is not valid."
      echo ""
      show_usage
      echo ""
      echo " *** FATAL ERROR! ***"
      echo " Unknown key or key-value argument pair."
      echo ""
      exit 2
      ;;
   esac
done
#---~---



#---~---
#   Make sure all required settings were provided.
#---~---
if [[ "${EXP}"         == "" ]] || [[ "${RES}"         == "" ]] ||
   [[ "${YYYYMMDDHHi}" == "" ]] || [[ "${FCST}"        == "" ]]
then
   echo " This script requires some arguments to be set through flags."
   show_usage
   exit 2
fi
#---~---


#--- Set environment variables exports:
. setenv.bash ${MONAN_ONETWO}
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


# Local variables--------------------------------------
start_date=${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}:00:00
GEODATA=${DATAIN}/WPS_GEOG
cores=${INITATMOS_ncores}
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#-------------------------------------------------------
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs




if [[ ! -s ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ]]
then
   if [[ ! -s ${DATAIN}/fixed/x1.${RES}.graph.info ]]
   then
      cd ${DATAIN}/fixed
      echo -e "${GREEN}==>${NC} downloading meshes tgz files ... \n"
      cd ${DATAIN}/fixed
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


files_needed=("${SCRIPTS}/namelists/namelist.init_atmosphere.TEMPLATE" "${SCRIPTS}/namelists/streams.init_atmosphere.TEMPLATE" "${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores}" "${DATAIN}/fixed/x1.${RES}.static.nc" "${DATAOUT}/${YYYYMMDDHHi}/Pre/${EXP}:${start_date:0:13}" "${EXECS}/init_atmosphere_model")
for file in "${files_needed[@]}"
do
  if [[ ! -s "${file}" ]]
  then
    echo -e  "\n${RED}==>${NC} ***** FATAL ERROR *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done


sed -e "s,#LABELI#,${start_date},g;s,#GEODAT#,${GEODATA},g;s,#RES#,${RES},g" \
	 ${SCRIPTS}/namelists/namelist.init_atmosphere.TEMPLATE > ${DIRRUN}/namelist.init_atmosphere

sed -e "s,#RES#,${RES},g" \
    ${SCRIPTS}/namelists/streams.init_atmosphere.TEMPLATE > ${DIRRUN}/streams.init_atmosphere


cp -f ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ${DIRRUN}
cp -f ${DATAIN}/fixed/x1.${RES}.static.nc ${DIRRUN}
cp -f ${DATAOUT}/${YYYYMMDDHHi}/Pre/${EXP}\:${start_date:0:13} ${DIRRUN}
cp -f ${EXECS}/init_atmosphere_model ${DIRRUN}
cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}

chmod 755 ${DIRRUN}/*
chmod 755 ${DATAOUT}/${YYYYMMDDHHi}/Pre/*

rm -f ${DIRRUN}/initatmos.bash 


if [[ ${SCHEDULER_SYSTEM} != "GENERIC" ]]
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
. ${SCRIPTS}/setenv.bash ${MONAN_ONETWO}


date
beg_secs=\`date +"%s"\`

#ML: Replace HOSTNAME with SCHEDULER_SYSTEM so this can be expanded to other HPC environments more easily.
case "${SCHEDULER_SYSTEM}" in
SLURM)
   echo "-- SLURM_JOB_ID: \$SLURM_JOB_ID"
   time mpirun -np ${INITATMOS_ncores} ./\${executable}
   ;;
PBS)
   echo "-- PBS_JOBID: \$PBS_JOBID"
   time mpirun --ppn ${INITATMOS_ncpn} -np ${INITATMOS_ncores} --depth=${INITATMOS_nthreads} --cpu-bind depth ./\${executable}
   ;;
#*)
#   echo "-- GENERIC:"
#   time mpirun -np ${INITATMOS_ncores} ./\${executable}
#   ;;
esac

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
   echo -e  "${GREEN}==>${NC} Sbatch initatmos.bash...\n"
   cd ${DIRRUN}
   sbatch --wait ${DIRRUN}/initatmos.bash
   ;;
PBS)
   echo -e  "${GREEN}==>${NC} qsub initatmos.bash...\n"
   cd ${DIRRUN}
   qsub -W block=true ${DIRRUN}/initatmos.bash
   ;;
#GENERIC)
#   echo -e "${ORANGE}==>${NC} No scheduler system detected...\n"
#   cd ${DIRRUN}
#   ${DIRRUN}/initatmos.bash
#   ;;
esac
mv ${DIRRUN}/initatmos.bash ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs



if [[ ! -s ${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc ]]
then
  echo -e  "\n${RED}==>${NC} ***** FATAL ERROR *****\n"	
  echo -e  "${RED}==>${NC} Init Atmosphere phase fails! Check logs at ${DATAOUT}/logs/initatmos.* .\n"
  echo -e  "${RED}==>${NC} Exiting script. \n"
  exit -1
fi
chmod 775 ${DATAOUT}/${YYYYMMDDHHi}/Pre/*
rm -fr ${DIRRUN}
