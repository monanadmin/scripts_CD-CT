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
      echo "Unknown key-value argument pair."
      show_usage
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

echo ""
echo "---- Make Static ----"
echo ""

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
GEODATA=${DATAIN}/WPS_GEOG
cores=${STATIC_ncores}
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#-------------------------------------------------------




if [[ ! -s ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ]]
then
   if [[ ! -s ${DATAIN}/fixed/x1.${RES}.graph.info ]]
   then
      mkdir -p ${DATAIN}/fixed   
      cd ${DATAIN}/fixed
      echo -e "${GREEN}==>${NC} downloading meshes tgz files ... \n"
      wget https://www2.mmm.ucar.edu/projects/mpas/atmosphere_meshes/x1.${RES}.tar.gz
      wget https://www2.mmm.ucar.edu/projects/mpas/atmosphere_meshes/x1.${RES}_static.tar.gz
      tar -xzvf x1.${RES}.tar.gz
      tar -xzvf x1.${RES}_static.tar.gz
      chmod 755 *
   fi
   echo -e "${GREEN}==>${NC} Creating x1.${RES}.graph.info.part.${cores} ... \n"
   cd ${DATAIN}/fixed
   gpmetis -minconn -contig -niter=200 x1.${RES}.graph.info ${cores}
   rm -fr x1.${RES}.tar.gz x1.${RES}_static.tar.gz
   chmod 755 *
fi

files_needed=("${EXECS}/init_atmosphere_model" "${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores}" "${DATAIN}/fixed/x1.${RES}.grid.nc" "${SCRIPTS}/namelists/namelist.init_atmosphere.STATIC" "${SCRIPTS}/namelists/streams.init_atmosphere.STATIC")
for file in "${files_needed[@]}"
do
  if [[ ! -s "${file}" ]]
  then
    echo -e  "\n${RED}==>${NC} ***** FATAL ERROR *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done


cp -f ${DATAIN}/fixed/*.TBL ${DIRRUN}
cp -f ${DATAIN}/fixed/*.GFS ${DIRRUN}
cp -f ${EXECS}/init_atmosphere_model ${DIRRUN}
cp -f ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ${DIRRUN}
cp -f ${DATAIN}/fixed/x1.${RES}.grid.nc ${DIRRUN}

sed -e "s,#GEODAT#,${GEODATA},g;s,#RES#,${RES},g" \
   ${SCRIPTS}/namelists/namelist.init_atmosphere.STATIC \
   > ${DIRRUN}/namelist.init_atmosphere

sed -e "s,#RES#,${RES},g" \
   ${SCRIPTS}/namelists/streams.init_atmosphere.STATIC \
   > ${DIRRUN}/streams.init_atmosphere

cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}
mkdir -p ${DATAOUT}/logs
rm -f ${DIRRUN}/static.bash 

if [[ ${SCHEDULER_SYSTEM} != "GENERIC" ]]
then
   sed -e "s,#JOBNAME#,${STATIC_jobname},g;
   s,#NNODES#,${STATIC_nnodes},g;
   s,#NCPUS#,${STATIC_ncpus},g;
   s,#NTASKS#,${STATIC_ncores},g;
   s,#NTASKSPNODE#,${STATIC_ncpn},g;
   s,#NTHREADS#,${STATIC_nthreads},g;
   s,#PARTITION#,${STATIC_QUEUE},g;
   s,#WALLTIME#,${STATIC_walltime},g;
   s,#OUTPUTJOB#,${DATAOUT}/logs/static.bash.o,g;
   s,#ERRORJOB#,${DATAOUT}/logs/static.bash.e,g" \
   ${SCRIPTS}/stools/submit_${SYSTEM_KEY}.bash_TEMPLATE > ${DIRRUN}/static.bash 
else
   echo "#!/bin/bash " > ${DIRRUN}/static.bash 
fi

chmod 755 ${DIRRUN}/*

cat << EOF0 >> ${DIRRUN}/static.bash 

export executable=init_atmosphere_model

ulimit -s unlimited
ulimit -c unlimited
ulimit -v unlimited


. ${SCRIPTS}/setenv.bash

cd ${DIRRUN}
chmod 755 *

date
beg_secs=\`date +"%s"\`

#ML: Replace HOSTNAME with SCHEDULER_SYSTEM so this can be expanded to other HPC environments more easily.
case "${SCHEDULER_SYSTEM}" in
SLURM)
   echo "-- SLURM_JOB_ID: \$SLURM_JOB_ID"
   time mpirun -np ${STATIC_ncores} ./\${executable}
   ;;
PBS)
   echo "-- PBS_JOBID: \$PBS_JOBID"
   time mpirun --ppn ${STATIC_ncpn} -np ${STATIC_ncores} --depth=${STATIC_nthreads} --cpu-bind depth ./\${executable}
   ;;
#*)
#   echo "-- GENERIC: "
#   time mpirun -np ${STATIC_ncores} ./\${executable}
#   ;;
esac

date
end_secs=\`date +"%s"\`

let wallsecs=\$end_secs-\$beg_secs
echo "STATIC time taken by run in seconds is " \$wallsecs


grep "Finished running" log.init_atmosphere.0000.out >& /dev/null
if [[ \$? -ne 0 ]]; then
   echo "  BUMMER: Static generation failed for some yet unknown reason."
   echo " "
   tail -10 ${STATICPATH}/log.init_atmosphere.0000.out
   echo " "
   exit 21
fi

echo "  ####################################"
echo "  ### Static completed - \$(date) ####"
echo "  ####################################"
echo " "


EOF0
chmod a+x ${DIRRUN}/static.bash
rm -fr ${DATAIN}/fixed/x1.${RES}.static.nc


case "${SCHEDULER_SYSTEM}" in
SLURM)
   echo -e  "${GREEN}==>${NC} Sbatch static.bash...\n"
   cd ${DIRRUN}
   sbatch --wait ${DIRRUN}/static.bash
   ;;
PBS)
   echo -e  "${GREEN}==>${NC} qsub static.bash...\n"
   cd ${DIRRUN}
   qsub -W block=true ${DIRRUN}/static.bash
   ;;
#GENERIC)
#  echo "No job manager found"
#  cd ${DIRRUN}
#  ${DIRRUN}/model.bash
#  ;;
esac

mv ${DIRRUN}/static.bash ${DATAOUT}/logs/
mv ${DIRRUN}/streams.init_atmosphere ${DATAOUT}/logs/
mv ${DIRRUN}/namelist.init_atmosphere ${DATAOUT}/logs/
mv log.init_atmosphere.* ${DATAOUT}/logs/


if [[ -s ${DIRRUN}/x1.${RES}.static.nc ]]
then
   mv ${DIRRUN}/x1.${RES}.static.nc ${DATAIN}/fixed
   chmod 755 ${DATAIN}/fixed/*
else
   echo -e  "${RED}==>${NC} File ${DIRRUN}/x1.${RES}.static.nc was not created. \n"
   exit -1
fi

rm -fr ${DIRRUN}

