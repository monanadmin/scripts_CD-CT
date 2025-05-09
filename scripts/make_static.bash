#!/bin/bash 


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
DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#-------------------------------------------------------


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

ln -sf ${DATAIN}/fixed/*.TBL ${DIRRUN}
ln -sf ${DATAIN}/fixed/*.GFS ${DIRRUN}
ln -sf ${EXECS}/init_atmosphere_model ${DIRRUN}
ln -sf ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ${DIRRUN}
ln -sf ${DATAIN}/fixed/x1.${RES}.grid.nc ${DIRRUN}

sed -e "s,#GEODAT#,${GEODATA},g;s,#RES#,${RES},g" \
   ${SCRIPTS}/namelists/namelist.init_atmosphere.STATIC \
   > ${DIRRUN}/namelist.init_atmosphere

sed -e "s,#RES#,${RES},g" \
   ${SCRIPTS}/namelists/streams.init_atmosphere.STATIC \
   > ${DIRRUN}/streams.init_atmosphere


cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}
mkdir -p ${DATAOUT}/logs
rm -f ${DIRRUN}/static.bash 
cat << EOF0 > ${DIRRUN}/static.bash 
#!/bin/bash
#SBATCH --job-name=${STATIC_jobname}
#SBATCH --nodes=${STATIC_nnodes} 
#SBATCH --ntasks=${STATIC_ncores}             
#SBATCH --tasks-per-node=${STATIC_ncpn}  
#SBATCH --partition=${STATIC_QUEUE}
#SBATCH --time=${STATIC_walltime}        
#SBATCH --output=${DATAOUT}/logs/static.bash.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/logs/static.bash.e%j     # File name for standard error output
#SBATCH --exclusive
##SBATCH --mem=500000


executable=init_atmosphere_model

ulimit -s unlimited
ulimit -c unlimited
ulimit -v unlimited

. $(pwd)/setenv.bash

cd ${DIRRUN}

date
time mpirun -np \${SLURM_NTASKS} ./\${executable}
date

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


mv log.init_atmosphere.0000.out ${DATAOUT}/logs/log.init_atmosphere.0000.x1.${RES}.static.nc.out


EOF0
chmod a+x ${DIRRUN}/static.bash


echo -e  "${GREEN}==>${NC} Executing sbatch static.bash...\n"
cd ${DIRRUN}
sbatch --wait ${DIRRUN}/static.bash
mv ${DIRRUN}/static.bash ${DATAOUT}/logs/


if [ -s ${DIRRUN}/x1.${RES}.static.nc ]
then
   mv ${DIRRUN}/x1.${RES}.static.nc ${DATAIN}/fixed
else
   echo -e  "${RED}==>${NC} File ${DIRRUN}/x1.${RES}.static.nc was not created. \n"
   exit -1
fi

rm -fr ${DIRRUN}

