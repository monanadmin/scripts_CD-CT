#!/bin/bash 




#--- Function that shows usage.
function show_usage() {
   echo " Usage: "
   echo ""
   echo " ${0} [-e EXP ] [-f FCST] [-r RES] [-t YYYYMMDDHH]"
   echo ""
   echo " List of **required** flags: "
   echo ""
   echo " -e EXP          -- meteorological drivers. For example, GFS"
   echo " -f FCST         -- Simulation length in hours, e.g., 24 or 48."
   echo " -r RES          -- grid resolution. Options are:"
   echo "                    5898242 (~ 10 km)"
   echo "                    2621442 (~ 15 km)"
   echo "                    1024002 (~ 24 km)"
   echo "                    40962   (~ 120 km)"
   echo " -t YYYYMMDDHH   -- Initial time. For example if 22 Sept 2025 00 UTC, set it to:"
   echo "                    2025092200"
   echo ""
}
#---~---

# Set environment variables exports:
. setenv.bash




#--- Default input variables:
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
#   Make sure all settings were provided (unless this will be to clean up runs).
#---~---
if [[ "${EXP}"         == "" ]] || [[ "${RES}"         == "" ]] ||
   [[ "${YYYYMMDDHHi}" == "" ]] || [[ "${FCST}"        == "" ]]
then
   echo " This script requires some arguments to be set through flags."
   show_usage
   exit 2
fi
#---~---


# Standart directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT; mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_CD-CT;   mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;           mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;             mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;           mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;           mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;               mkdir -p ${EXECS}
#----------------------------------------------------------------------


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
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
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
rm -f ${DIRRUN}/initatmos.bash 
cat << EOF0 > ${DIRRUN}/initatmos.bash 
#!/bin/bash -x
#SBATCH --job-name=${INITATMOS_jobname}
#SBATCH --nodes=${INITATMOS_nnodes}                         # depends on how many boundary files are available
#SBATCH --partition=${INITATMOS_QUEUE} 
#SBATCH --tasks-per-node=${INITATMOS_ncores}               # only for benchmark
#SBATCH --time=${STATIC_walltime}
#SBATCH --output=${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/initatmos.bash.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/initatmos.bash.e%j     # File name for standard error output
#SBATCH --exclusive
##SBATCH --mem=500000

export executable=init_atmosphere_model

ulimit -c unlimited
ulimit -v unlimited
ulimit -s unlimited


. $(pwd)/setenv.bash

cd ${DIRRUN}



date
time mpirun -np \${SLURM_NTASKS} ./\${executable}
date


mv ${DIRRUN}/log.init_atmosphere.0000.out ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/log.init_atmosphere.0000.x1.${RES}.init.nc.${YYYYMMDDHHi}.out
mv ${DIRRUN}/namelist.init_atmosphere ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs
mv ${DIRRUN}/streams.init_atmosphere ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs
mv ${DIRRUN}/x1.${RES}.init.nc ${DATAOUT}/${YYYYMMDDHHi}/Pre

EOF0
chmod a+x ${DIRRUN}/initatmos.bash

echo -e  "${GREEN}==>${NC} Executing sbatch initatmos.bash...\n"
cd ${DIRRUN}
sbatch --wait ${DIRRUN}/initatmos.bash
mv ${DIRRUN}/initatmos.bash ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs

if [ ! -s ${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc ]
then
  echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	
  echo -e  "${RED}==>${NC} Init Atmosphere phase fails! Check logs at ${DATAOUT}/logs/initatmos.* .\n"
  echo -e  "${RED}==>${NC} Exiting script. \n"
  exit -1
fi

rm -fr ${DIRRUN}
