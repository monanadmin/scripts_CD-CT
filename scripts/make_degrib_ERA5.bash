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
   echo "${0} ERA 655362 2026080100 24"
   echo ""
   exit
fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash

echo ""
echo "---- Make Degrib ${EXP} ----"
echo ""

# Standart directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT;  mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_CD-CT;    mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;            mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;              mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;            mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;            mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;                mkdir -p ${EXECS}
#----------------------------------------------------------------------


# Input variables:--------------------------------------
EXP=${1};         #EXP=ERA
RES=${2};         #RES=1024002
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2024012000
FCST=${4};        #FCST=24
#-------------------------------------------------------

# Local variables--------------------------------------
start_date=${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}:00:00
yyyymmddi=${YYYYMMDDHHi:0:8}
hhi=${YYYYMMDDHHi:8:2}
yyyymmddhhf=$(date +"%Y%m%d%H" -d "${yyyymmddi} ${hhi}:00 ${FCST} hours" )
final_date=${yyyymmddhhf:0:4}-${yyyymmddhhf:4:2}-${yyyymmddhhf:6:2}_${yyyymmddhhf:8:2}:00:00
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#-------------------------------------------------------
mkdir -p ${DATAIN}/${YYYYMMDDHHi}
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs

if [ "$HOSTNAME" = "egeon" ]; then
    mkdir -p ${HOME}/local/lib64
    cp -f /usr/lib64/libjasper.so* ${HOME}/local/lib64
    cp -f /usr/lib64/libjpeg.so* ${HOME}/local/lib64
fi

BNDDIR=${GCCCIS}/${EXP}/${YYYYMMDDHHi:0:4}/${YYYYMMDDHHi}
# If boundary condition files do not exist in DATAIN directories, search for them
# in the BNDDIR (GCC MONAN) directories. Abort if they cannot be found.
if [ -s "${DATAIN}/${EXP}/era5.pl.${YYYYMMDDHHi}.grib" ] && [ -s "${DATAIN}/${EXP}/era5.sl.${YYYYMMDDHHi}.grib" ]
then
    BNDDIR="${DATAIN}/${EXP}"
elif [ -s "${DATAIN}/${EXP}/${YYYYMMDDHHi}/era5.pl.${YYYYMMDDHHi}.grib" ] && [ -s "${DATAIN}/${EXP}/${YYYYMMDDHHi}/era5.sl.${YYYYMMDDHHi}.grib" ]
then
    BNDDIR="${DATAIN}/${EXP}/${YYYYMMDDHHi}"
elif [ -s "${DATAIN}/ERA5/era5.pl.${YYYYMMDDHHi}.grib" ] && [ -s "${DATAIN}/ERA5/era5.sl.${YYYYMMDDHHi}.grib" ]
then
    BNDDIR="${DATAIN}/ERA5"
elif [ -s "${DATAIN}/ERA5/${YYYYMMDDHHi}/era5.pl.${YYYYMMDDHHi}.grib" ] && [ -s "${DATAIN}/ERA5/${YYYYMMDDHHi}/era5.sl.${YYYYMMDDHHi}.grib" ]
then
    BNDDIR="${DATAIN}/ERA5/${YYYYMMDDHHi}"
elif [ -s "${BNDDIR}/era5.pl.${YYYYMMDDHHi}.grib" ] && [ -s "${BNDDIR}/era5.sl.${YYYYMMDDHHi}.grib" ]
then
   : # File already exists in BNDDIR; keep the current directory.
else
    echo -e "${RED}==>${NC} Boundary condition files not found! - ${EXP}"
    echo -e "${RED}==>${NC} Check ${BNDDIR}"
    echo -e "${RED}==>${NC} Check ${DATAIN}/${EXP}"
    exit 1
fi

echo -e "\n${EXP} folder located at ${BNDDIR}\n"

files_needed=("${DATAIN}/fixed/x1.${RES}.static.nc" "${DATAIN}/fixed/Vtable.${EXP}" "${EXECS}/ungrib.exe" "${BNDDIR}/era5.pl.${YYYYMMDDHHi}.grib" "${BNDDIR}/era5.sl.${YYYYMMDDHHi}.grib")
for file in "${files_needed[@]}"
do
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done

# Copia arquivos necessarios para diretorio DIRRUN
cp -f ${DATAIN}/fixed/x1.${RES}.static.nc ${DIRRUN}
cp -f ${DATAIN}/fixed/Vtable.${EXP} ${DIRRUN}/Vtable
cp -f ${EXECS}/ungrib.exe ${DIRRUN}
cp -f ${SCRIPTS}/namelists/namelist.wps.TEMPLATE ${DIRRUN}/namelist.wps.TEMPLATE
cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}
cp -f ${SCRIPTS}/link_grib.csh ${DIRRUN}
rm -f ${DIRRUN}/degrib_${EXP}.bash

if [[ $MODERUN == "R" ]]; then
   echo -e "Degribbing ERA5 data for Regional (limited-area) mode – lateral boundary conditions.\n"
   dt=$((LBCINT / 3600))
   for ((hour=0; hour<=FCST; hour+=dt)); do
      valid_date=$(date -u -d "${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2} ${YYYYMMDDHHi:8:2}:00:00 UTC ${hour} hour" +"%Y%m%d%H")
      echo "Temporarily copying ERA5 data: era5.pl|sl.${valid_date}.grib"
      if [ ! -s "${BNDDIR}/era5.pl.${valid_date}.grib" ] || [ ! -s "${BNDDIR}/era5.sl.${valid_date}.grib" ]
      then
         echo -e "${RED}==>${NC} ERA5 data not found for ${valid_date}."
         exit 1
      fi
      cp -f "${BNDDIR}/era5.pl.${valid_date}.grib" "${DATAIN}/${YYYYMMDDHHi}/"
      cp -f "${BNDDIR}/era5.sl.${valid_date}.grib" "${DATAIN}/${YYYYMMDDHHi}/"
   done

   if [ ${SCHEDULER_SYSTEM} != "GENERIC" ]
   then
      sed -e "s,#JOBNAME#,${DEGRIB_jobname},g;
      s,#NNODES#,${DEGRIB_nnodes},g;
      s,#NCPUS#,${DEGRIB_ncpus},g;
      s,#NTASKS#,${DEGRIB_ncores},g;
      s,#NTASKSPNODE#,${DEGRIB_ncpn},g;
      s,#NTHREADS#,${DEGRIB_nthreads},g;
      s,#PARTITION#,${DEGRIB_QUEUE},g;
      s,#WALLTIME#,${DEGRIB_walltime},g;
      s,#OUTPUTJOB#,${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/degrib_${EXP}.o,g;
      s,#ERRORJOB#,${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/degrib_${EXP}.e,g" \
      ${SCRIPTS}/stools/submit_${SYSTEM_KEY}.bash_TEMPLATE > ${DIRRUN}/degrib_${EXP}.bash
   else
      echo "#!/bin/bash " > ${DIRRUN}/degrib_${EXP}.bash
   fi

   cat << EOF0 >> ${DIRRUN}/degrib_${EXP}.bash 

ulimit -s unlimited
ulimit -c unlimited
ulimit -v unlimited

export PMIX_MCA_gds=hash

export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${HOME}/local/lib64

cd ${DIRRUN}
. ${SCRIPTS}/setenv.bash

if [ ${SCHEDULER_SYSTEM} == "SLURM" ]; then
   echo "-- SLURM_JOB_ID: \$SLURM_JOB_ID"
elif [ ${SCHEDULER_SYSTEM} == "PBS" ]; then
   echo "-- PBS_JOBID: \$PBS_JOBID"
fi

ldd ungrib.exe

rm -f GRIBFILE.* namelist.wps

sed -e "s,#LABELI#,${start_date},g;s,#LABELF#,${final_date},g;s,#LBCINT#,${LBCINT},g;s,#PREFIX#,${EXP},g" \
	${DIRRUN}/namelist.wps.TEMPLATE > ${DIRRUN}/namelist.wps

./link_grib.csh ${DATAIN}/${YYYYMMDDHHi}/era5.*.grib

chmod 755 *
echo ""
date
echo "submetendo jobs ungrib"

time mpirun -np 1 ./ungrib.exe

date

grep "Successful completion of program ungrib.exe" ${DIRRUN}/ungrib.log >& /dev/null

if [ \$? -ne 0 ]; then
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
   mv ${EXP}* ${DATAOUT}/${YYYYMMDDHHi}/Pre
   rm -fr ${DATAIN}/${YYYYMMDDHHi}

echo "End of degrib Job"


EOF0

elif [[ ${MODERUN} == "G" ]]; then 
   echo -e "Degribbing ERA5 data for Global mode – only initial conditions.\n"
   cp -f ${BNDDIR}/era5.pl.${YYYYMMDDHHi}.grib ${DATAIN}/${YYYYMMDDHHi}
   cp -f ${BNDDIR}/era5.sl.${YYYYMMDDHHi}.grib ${DATAIN}/${YYYYMMDDHHi}   

   if [ ${SCHEDULER_SYSTEM} != "GENERIC" ]
   then
      sed -e "s,#JOBNAME#,${DEGRIB_jobname},g;
      s,#NNODES#,${DEGRIB_nnodes},g;
      s,#NCPUS#,${DEGRIB_ncpus},g;
      s,#NTASKS#,${DEGRIB_ncores},g;
      s,#NTASKSPNODE#,${DEGRIB_ncpn},g;
      s,#NTHREADS#,${DEGRIB_nthreads},g;
      s,#PARTITION#,${DEGRIB_QUEUE},g;
      s,#WALLTIME#,${DEGRIB_walltime},g;
      s,#OUTPUTJOB#,${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/degrib_${EXP}.o,g;
      s,#ERRORJOB#,${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/degrib_${EXP}.e,g" \
      ${SCRIPTS}/stools/submit_${SYSTEM_KEY}.bash_TEMPLATE > ${DIRRUN}/degrib_${EXP}.bash
   else
      echo "#!/bin/bash " > ${DIRRUN}/degrib_${EXP}.bash
   fi

   cat << EOF0 >> ${DIRRUN}/degrib_${EXP}.bash

ulimit -s unlimited
ulimit -c unlimited
ulimit -v unlimited

export PMIX_MCA_gds=hash

export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${HOME}/local/lib64

cd ${DIRRUN}
. setenv.bash

if [ ${SCHEDULER_SYSTEM} == "SLURM" ]; then
   echo "-- SLURM_JOB_ID: \$SLURM_JOB_ID"
elif [ ${SCHEDULER_SYSTEM} == "PBS" ]; then
   echo "-- PBS_JOBID: \$PBS_JOBID"
fi

ldd ungrib.exe

rm -f GRIBFILE.* namelist.wps

sed -e "s,#LABELI#,${start_date},g;s,#LABELF#,${start_date},g;s,#LBCINT#,${LBCINT},g;s,#PREFIX#,${EXP},g" \
	${DIRRUN}/namelist.wps.TEMPLATE > ${DIRRUN}/namelist.wps

./link_grib.csh ${DATAIN}/${YYYYMMDDHHi}/era5.*.${YYYYMMDDHHi}.grib

chmod 755 *
echo ""
date
echo "submetendo jobs ungrib"

time mpirun -np 1 ./ungrib.exe

date

grep "Successful completion of program ungrib.exe" ${DIRRUN}/ungrib.log >& /dev/null

if [ \$? -ne 0 ]; then
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
   mv ${EXP}\:${start_date:0:13} ${DATAOUT}/${YYYYMMDDHHi}/Pre
   rm -fr ${DATAIN}/${YYYYMMDDHHi}

echo "End of degrib Job"

EOF0

else
   echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
   echo -e  "${RED}==>${NC} Make degrib phase fails during degrib! Please select REGIONAL=Y or REGIONAL=N so that degrib can be done appropriately.\n"
   echo -e  "${RED}==>${NC} Exiting script. \n"
   exit -1
fi

chmod a+x ${DIRRUN}/degrib_${EXP}.bash

case "${SCHEDULER_SYSTEM}" in
   SLURM)
      echo -e  "\n${GREEN}==>${NC} sbatch degrib_${EXP}.bash...\n"
      cd ${DIRRUN}
      sbatch --wait ${DIRRUN}/degrib_${EXP}.bash
      ;;
   PBS)
      echo -e  "\n${GREEN}==>${NC} qsub degrib_${EXP}.bash...\n"
      cd ${DIRRUN}
      JOBID=$(qsub -W block=true ${DIRRUN}/degrib_${EXP}.bash)
      JOBID=${JOBID%%.*}
      mv ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/degrib_${EXP}.o ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/degrib_${EXP}.o.${JOBID}
      mv ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/degrib_${EXP}.e ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/degrib_${EXP}.e.${JOBID}
      ;;
#    GENERIC)
#      echo "Nenhum gerenciador detectado"
#      ${DIRRUN}/degrib_${EXP}.bash
#      ;;
esac
mv ${DIRRUN}/degrib_${EXP}.bash ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs

files_ungrib=("${EXP}:${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}")
for file in "${files_ungrib[@]}"
do
  if [ ! -s ${DATAOUT}/${YYYYMMDDHHi}/Pre/${file} ] 
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} Degrib fails! At least the file ${file} was not generated at ${DATAIN}/${YYYYMMDDHHi}. \n"
    echo -e  "${RED}==>${NC} Check logs at ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/degrib.* .\n"
    echo -e  "${RED}==>${NC} Exiting script. \n"
    exit -1
  fi
done

chmod -R 755 ${DATAOUT}/${YYYYMMDDHHi}/Pre/*
rm -fr ${DIRRUN}
