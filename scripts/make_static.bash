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
export DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT;    mkdir -p ${DIRHOMES}  
export DIRDADOSIN=${DIR_DADOS}/scripts_CD-CT;    mkdir -p ${DIRHOMED}  
export DIRDADOSOUT=${DIR_DADOS}/scripts_CD-CT;   mkdir -p ${DIRHOMED}  
export SCRIPTS=${DIRHOMES}/scripts;              mkdir -p ${SCRIPTS}
export DATAIN=${DIRHOMED}/datain;                mkdir -p ${DATAIN}
export DATAOUT=${DIRHOMED}/dataout;              mkdir -p ${DATAOUT}
export SOURCES=${DIRHOMES}/sources;              mkdir -p ${SOURCES}
export EXECS=${DIRHOMED}/execs;                  mkdir -p ${EXECS}
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



files_needed=("${EXECS}/init_atmosphere_model" "${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores}" "${DATAIN}/fixed/x1.${RES}.grid.nc" "${DATAIN}/namelists/namelist.init_atmosphere.STATIC" "${DATAIN}/namelists/streams.init_atmosphere.STATIC")
for file in "${files_needed[@]}"
do
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done

ln -sf ${DATAIN}/fixed/*.TBL ${SCRIPTS}
ln -sf ${DATAIN}/fixed/*.GFS ${SCRIPTS}
ln -sf ${EXECS}/init_atmosphere_model ${SCRIPTS}
ln -sf ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ${SCRIPTS}
ln -sf ${DATAIN}/fixed/x1.${RES}.grid.nc ${SCRIPTS}

sed -e "s,#GEODAT#,${GEODATA},g;s,#RES#,${RES},g" \
   ${DATAIN}/namelists/namelist.init_atmosphere.STATIC \
   > ${SCRIPTS}/namelist.init_atmosphere

sed -e "s,#RES#,${RES},g" \
   ${DATAIN}/namelists/streams.init_atmosphere.STATIC \
   > ${SCRIPTS}/streams.init_atmosphere



mkdir -p ${DATAOUT}/logs
rm -f ${SCRIPTS}/static.bash 
cat << EOF0 > ${SCRIPTS}/static.bash 
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

cd ${SCRIPTS}

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

#
# clean up and remove links
#

mv log.init_atmosphere.0000.out ${DATAOUT}/logs/log.init_atmosphere.0000.x1.${RES}.static.nc.out


EOF0
chmod a+x ${SCRIPTS}/static.bash


echo -e  "${GREEN}==>${NC} Executing sbatch static.bash...\n"
cd ${SCRIPTS}
sbatch --wait ${SCRIPTS}/static.bash
mv ${SCRIPTS}/static.bash ${DATAOUT}/logs/

if [ -s ${SCRIPTS}/x1.${RES}.static.nc ]
then
   mv ${SCRIPTS}/x1.${RES}.static.nc ${DATAIN}/fixed
else
   echo -e  "${RED}==>${NC} File ${SCRIPTS}/x1.${RES}.static.nc was not created. \n"
   exit -1
fi

find ${SCRIPTS} -maxdepth 1 -type l -exec rm -f {} \;
rm -f ${SCRIPTS}/log.init_atmosphere.* 
rm -f ${SCRIPTS}/streams.init_atmosphere
rm -f ${SCRIPTS}/namelist.init_atmosphere

