#!/bin/bash 
umask 022


if [ $# -ne 4 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} EXP_NAME RESOLUTION LABELI FCST"
   echo ""
   echo "EXP_NAME    :: Forcing: GFS"
   echo "            :: Others options to be added later..."
   echo "RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)"
   echo "LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100"
   echo "FCST        :: Forecast hours, e.g.: 24 or 36, etc."
   echo ""
   echo "24 hour forcast example:"
   echo "${0} GFS 1024002 2024010100 24"
   echo ""

   exit
fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash

echo ""
echo "---- Make Static ----"
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
GEODATA=${DATAIN}/WPS_GEOG
cores=${STATIC_ncores}
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#-------------------------------------------------------




if [ ! -s ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ]
then
   if [ ! -s ${DATAIN}/fixed/x1.${RES}.graph.info ]
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
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
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

if [ ${SCHEDULER_SYSTEM} != "GENERIC" ]
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

#. ${SCRIPTS}/setenv.bash

cd ${DIRRUN}
chmod 755 *

date
beg_secs=\`date +"%s"\`

if [ "$HOSTNAME" = "egeon" ]; then
   echo "-- SLURM_JOB_ID: \$SLURM_JOB_ID"
   time mpirun -np ${STATIC_ncores} ./\${executable}
else
   echo "-- PBS_JOBID: \$PBS_JOBID"
   time mpirun --ppn ${STATIC_ncpn} -np ${STATIC_ncores} --depth=${STATIC_nthreads} --cpu-bind depth ./\${executable}
fi

date
end_secs=\`date +"%s"\`

let wallsecs=\$end_secs-\$beg_secs
echo "STATIC time taken by run in seconds is " \$wallsecs


grep "Finished running" log.init_atmosphere.0000.out >& /dev/null
if [ \$? -ne 0 ]; then
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
rm -fr ${DATAIN}/fixed/x1.${RES}.ugwp_oro_data.nc


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
#    GENERIC)
#      echo "Nenhum gerenciador detectado"
#      cd ${DIRRUN}
#      ${DIRRUN}/model.bash
#      ;;
esac

mv ${DIRRUN}/static.bash ${DATAOUT}/logs/
mv ${DIRRUN}/streams.init_atmosphere ${DATAOUT}/logs/
mv ${DIRRUN}/namelist.init_atmosphere ${DATAOUT}/logs/
mv log.init_atmosphere.* ${DATAOUT}/logs/

if [ -s ${DIRRUN}/x1.${RES}.static.nc ]
then
   mv ${DIRRUN}/x1.${RES}.static.nc ${DATAIN}/fixed
   chmod 755 ${DATAIN}/fixed/*
else
   echo -e  "${RED}==>${NC} File ${DIRRUN}/x1.${RES}.static.nc was not created. \n"
   exit -1
fi

if [ -s ${DIRRUN}/x1.${RES}.ugwp_oro_data.nc ]
then
   mv ${DIRRUN}/x1.${RES}.ugwp_oro_data.nc ${DATAIN}/fixed
   chmod 755 ${DATAIN}/fixed/*
else
   echo -e  "${RED}==>${NC} File ${DIRRUN}/x1.${RES}.ugwp_oro_data.nc was not created. \n"
   exit -1
fi

JOBID=$(sed -n '2p' ${DATAOUT}/logs/static.bash.o | awk '{print $3}' | sed "s/.pbs-ha//g")
mv ${DATAOUT}/logs/static.bash.o ${DATAOUT}/logs/static.bash.o.${JOBID}
mv ${DATAOUT}/logs/static.bash.e ${DATAOUT}/logs/static.bash.e.${JOBID}
chmod a+r ${DATAOUT}/logs/static.bash.o.${JOBID}
chmod a+r ${DATAOUT}/logs/static.bash.e.${JOBID}
chmod a+r ${DATAOUT}/logs/log.init_atmosphere.*
rm -fr ${DIRRUN}

