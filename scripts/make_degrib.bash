#!/bin/bash 
umask 022


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


#--- Set environment variables exports:
. setenv.bash
#---~---




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

echo ""
echo "---- Make Degrib ----"
echo ""

#--- Set and create standard directories
DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT;  mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_CD-CT;    mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;            mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;              mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;            mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;            mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;                mkdir -p ${EXECS}
#---~---




# Local variables--------------------------------------
start_date=${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}:00:00
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#-------------------------------------------------------
mkdir -p ${DATAIN}/${YYYYMMDDHHi}
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs

#---~---
#   Machine-specific configurations.
#---~---
case "${HOSTNAME}" in
egeon)
   mkdir -p ${HOME}/local/lib64
   cp -f /usr/lib64/libjasper.so* ${HOME}/local/lib64
   cp -f /usr/lib64/libjpeg.so* ${HOME}/local/lib64
   ;;
esac
#---~---

#--- Set path for potential location of boundary conditions.
OPERDIREXP=${OPERDIR}/${EXP}
BNDDIR=${OPERDIREXP}/0p25/brutos/${YYYYMMDDHHi:0:4}/${YYYYMMDDHHi:4:2}/${YYYYMMDDHHi:6:2}/${YYYYMMDDHHi:8:2}
#---~---


#---~---
#   Retrieve boundary conditions, starting with the I/O path. If not found, look for them
# at default paths, /beegfs/monan/CIs (Egeon), /p/monan/CIs (Jaci).
# If files are not found at these locations, abort the run.
#---~---
if [[ ! -s ${BNDDIR}/gfs.t${YYYYMMDDHHi:8:2}z.pgrb2.0p25.f000.${YYYYMMDDHHi}.grib2 ]]
then
   if [[ ! -s ${GCCCIS}/${EXP}/${YYYYMMDDHHi:0:4}/${YYYYMMDDHHi}/gfs.t${YYYYMMDDHHi:8:2}z.pgrb2.0p25.f000.${YYYYMMDDHHi}.grib2 ]]
   then
      echo -e "${RED}==>${NC}Failed to find boundary conditions!"
      echo -e "${RED}==>${NC}Check ${BNDDIR} or" 
      echo -e "${RED}==>${NC}Check ${GCCCIS}/${EXP}"
      exit 1            
   else
      BNDDIR=${GCCCIS}/${EXP}/${YYYYMMDDHHi:0:4}/${YYYYMMDDHHi}
   fi    
fi


#files_needed=("${DATAIN}/fixed/x1.${RES}.static.nc" "${DATAIN}/fixed/Vtable.${EXP}" "${EXECS}/ungrib.exe" "${DATAIN}/${YYYYMMDDHHi}/gfs.t${YYYYMMDDHHi:8:2}z.pgrb2.0p25.f000.${YYYYMMDDHHi}.grib2")

files_needed=("${DATAIN}/fixed/x1.${RES}.static.nc" "${DATAIN}/fixed/Vtable.${EXP}" "${EXECS}/ungrib.exe" "${BNDDIR}/gfs.t${YYYYMMDDHHi:8:2}z.pgrb2.0p25.f000.${YYYYMMDDHHi}.grib2")

for file in "${files_needed[@]}"
do
  if [[ ! -s "${file}" ]]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done

cp -f ${DATAIN}/fixed/x1.${RES}.static.nc ${DIRRUN}
cp -f ${DATAIN}/fixed/Vtable.${EXP} ${DIRRUN}/Vtable
cp -f ${EXECS}/ungrib.exe ${DIRRUN}
cp -f ${SCRIPTS}/namelists/namelist.wps.TEMPLATE ${DIRRUN}/namelist.wps.TEMPLATE
cp -f ${BNDDIR}/gfs.t${YYYYMMDDHHi:8:2}z.pgrb2.0p25.f000.${YYYYMMDDHHi}.grib2 ${DATAIN}/${YYYYMMDDHHi}
cp -f ${DATAIN}/${YYYYMMDDHHi}/gfs.t${YYYYMMDDHHi:8:2}z.pgrb2.0p25.f000.${YYYYMMDDHHi}.grib2 ${DIRRUN}
cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}
cp -f ${SCRIPTS}/link_grib.csh ${DIRRUN}
rm -f ${DIRRUN}/degrib.bash 


if [[ ${SCHEDULER_SYSTEM} != "GENERIC" ]]
then
   sed -e "s,#JOBNAME#,${DEGRIB_jobname},g;
   s,#NNODES#,${DEGRIB_nnodes},g;
   s,#NCPUS#,${DEGRIB_ncpus},g;
   s,#NTASKS#,${DEGRIB_ncores},g;
   s,#NTASKSPNODE#,${DEGRIB_ncpn},g;
   s,#NTHREADS#,${DEGRIB_nthreads},g;
   s,#PARTITION#,${DEGRIB_QUEUE},g;
   s,#WALLTIME#,${DEGRIB_walltime},g;
   s,#OUTPUTJOB#,${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/degrib.o,g;
   s,#ERRORJOB#,${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/degrib.e,g" \
   ${SCRIPTS}/stools/submit_${SYSTEM_KEY}.bash_TEMPLATE > ${DIRRUN}/degrib.bash 
else
   echo "#!/bin/bash " > ${DIRRUN}/degrib.bash 
fi

cat << EOF0 >> ${DIRRUN}/degrib.bash 

ulimit -s unlimited
ulimit -c unlimited
ulimit -v unlimited

export PMIX_MCA_gds=hash

export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${HOME}/local/lib64

cd ${DIRRUN}

. ${SCRIPTS}/setenv.bash

ldd ungrib.exe

rm -f GRIBFILE.* namelist.wps


sed -e "s,#LABELI#,${start_date},g;s,#PREFIX#,GFS,g" \
	${DIRRUN}/namelist.wps.TEMPLATE > ${DIRRUN}/namelist.wps

echo ""
./link_grib.csh ${DATAIN}/${YYYYMMDDHHi}/gfs.t${YYYYMMDDHHi:8:2}z.pgrb2.0p25.f000.${YYYYMMDDHHi}.grib2

chmod 755 *
echo ""
date
echo "submetendo jobs ungrib"

time mpirun -np 1 ./ungrib.exe


date


grep "Successful completion of program ungrib.exe" ${DIRRUN}/ungrib.log >& /dev/null

if [[ \$? -ne 0 ]]; then
   echo "  BUMMER: Ungrib generation failed for some yet unknown reason."
   echo " "
   tail -10 ${DIRRUN}/ungrib.log
   echo " "
   exit 21
fi

#
# clean up and remove links
#
   mv ungrib.log ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/ungrib.${start_date}.log
   mv namelist.wps ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/namelist.${start_date}.wps
   mv GFS\:${start_date:0:13} ${DATAOUT}/${YYYYMMDDHHi}/Pre

   rm -fr ${DATAIN}/${YYYYMMDDHHi}

echo "End of degrib Job"


EOF0
chmod a+x ${DIRRUN}/degrib.bash


case "${SCHEDULER_SYSTEM}" in
   SLURM)
      echo -e  "${GREEN}==>${NC} Sbatch degrib.bash...\n"
      cd ${DIRRUN}
      sbatch --wait ${DIRRUN}/degrib.bash
        ;;
   PBS)
      echo -e  "${GREEN}==>${NC} qsub degrib.bash...\n"
      cd ${DIRRUN}
      qsub -W block=true ${DIRRUN}/degrib.bash
       ;;
#    GENERIC)
#      echo "Nenhum gerenciador detectado"
#      ${DIRRUN}/degrib.bash
#      ;;
esac


files_ungrib=("${EXP}:${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}")
for file in "${files_ungrib[@]}"
do
  if [[ ! -s ${DATAOUT}/${YYYYMMDDHHi}/Pre/${file} ]]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"  
    echo -e  "${RED}==>${NC} Degrib fails! At least the file ${file} was not generated at ${DATAIN}/${YYYYMMDDHHi}. \n"
    echo -e  "${RED}==>${NC} Check logs at ${DATAOUT}/logs/degrib.* .\n"
    echo -e  "${RED}==>${NC} Exiting script. \n"
    exit -1
  fi
done

mv ${DIRRUN}/degrib.bash ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs
chmod 755 ${DATAOUT}/${YYYYMMDDHHi}/Pre/*
rm -fr ${DIRRUN}
