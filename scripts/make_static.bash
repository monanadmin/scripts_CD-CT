#!/bin/bash 

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

executable=init_atmosphere_model


cd ${SCRIPTS}

echo -e "${GREEN}==>${NC} Running static program ... \n"
date
time mpirun -np ${STATIC_ncores}  ./${executable}
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

