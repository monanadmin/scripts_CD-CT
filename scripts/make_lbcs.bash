#!/bin/bash 


if [ $# -ne 5 ]
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
MESH=${2};         #RES=1024002
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2024012000
FCST=${4};        #FCST=24
LBCINT=${5}       #LBCINT=3600
#-------------------------------------------------------

source utils.bash

# Local variables--------------------------------------
start_date=${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}:00:00
YYYYMMDDHHf=$(add_hours "$YYYYMMDDHHi" "$FCST")
final_date=${YYYYMMDDHHf:0:4}-${YYYYMMDDHHf:4:2}-${YYYYMMDDHHf:6:2}_${YYYYMMDDHHf:8:2}:00:00
GEODATA=${DATAIN}/WPS_GEOG
cores=${INITATMOS_ncores}
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#-------------------------------------------------------
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs

if [ ! -s ${DATAIN}/fixed/${MESH}.graph.info.part.${cores} ]
then
   if [[ ${MESH} == x1.* ]]
   then
      if [ ! -s ${DATAIN}/fixed/${MESH}.graph.info ]
      then
         cd ${DATAIN}/fixed
         echo -e "${GREEN}==>${NC} downloading meshes tgz files ... \n"
         wget https://www2.mmm.ucar.edu/projects/mpas/atmosphere_meshes/${MESH}.tar.gz
         wget https://www2.mmm.ucar.edu/projects/mpas/atmosphere_meshes/${MESH}_static.tar.gz
         tar -xzvf ${MESH}.tar.gz
         tar -xzvf ${MESH}_static.tar.gz
      fi
      echo -e "${GREEN}==>${NC} Creating ${MESH}.graph.info.part.${cores} ... \n"
      cd ${DATAIN}/fixed
      gpmetis -minconn -contig -niter=200 ${MESH}.graph.info ${cores}
      rm -fr ${MESH}.tar.gz ${MESH}_static.tar.gz
   else
      echo -e "${GREEN}==>${NC} Creating ${MESH}.graph.info.part.${cores} ... \n"
      cd ${DATAIN}/fixed
      gpmetis -minconn -contig -niter=200 ${MESH}.graph.info ${cores}
   fi
fi

files_needed=("${SCRIPTS}/namelists/namelist.init_atmosphere.LBCS" "${SCRIPTS}/namelists/streams.init_atmosphere.LBCS" "${DATAIN}/fixed/${MESH}.graph.info.part.${cores}" "${DATAOUT}/${YYYYMMDDHHi}/Pre/${MESH}.init.nc" "${EXECS}/init_atmosphere_model")
for file in "${files_needed[@]}"
do
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done


sed -e "s,#LABELI#,${start_date},g;s,#LABELF#,${final_date},g;s,#GEODAT#,${GEODATA},g;s,#LBCINT#,${LBCINT},g;s,#MESH#,${MESH},g;s,#EXP#,${EXP},g" \
	 ${SCRIPTS}/namelists/namelist.init_atmosphere.LBCS > ${DIRRUN}/namelist.init_atmosphere

sed -e "s,#MESH#,${MESH},g;s,#LBCINT#,${LBCINT},g" \
    ${SCRIPTS}/namelists/streams.init_atmosphere.LBCS > ${DIRRUN}/streams.init_atmosphere


cp -f ${DATAIN}/fixed/${MESH}.graph.info.part.${cores} ${DIRRUN}
cp -f ${DATAOUT}/${YYYYMMDDHHi}/Pre/${MESH}.init.nc ${DIRRUN}
cp -f ${DATAOUT}/${YYYYMMDDHHi}/Pre/${EXP}\:* ${DIRRUN}
cp -f ${EXECS}/init_atmosphere_model ${DIRRUN}


cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}
rm -f ${DIRRUN}/lbcs.bash 
cat << EOF0 > ${DIRRUN}/lbcs.bash 
#!/bin/bash -x
#SBATCH --job-name=${LBCS_jobname}
#SBATCH --nodes=${LBCS_nnodes}                         # depends on how many boundary files are available
#SBATCH --partition=${LBCS_QUEUE} 
#SBATCH --tasks-per-node=${LBCS_ncores}               # only for benchmark
#SBATCH --time=${STATIC_walltime}
#SBATCH --output=${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/lbcs.bash.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/lbcs.bash.e%j     # File name for standard error output
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


mv ${DIRRUN}/log.init_atmosphere.0000.out ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/log.init_atmosphere.0000.${MESH}.lbcs.nc.${YYYYMMDDHHi}.out
mv ${DIRRUN}/namelist.init_atmosphere ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/namelist.init_atmosphere.lbcs
mv ${DIRRUN}/streams.init_atmosphere ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/streams.init_atmosphere.lbcs
mv ${DIRRUN}/${MESH}.init.nc ${DATAOUT}/${YYYYMMDDHHi}/Pre
mv ${DIRRUN}/lbc*.nc ${DATAOUT}/${YYYYMMDDHHi}/Pre

EOF0
chmod a+x ${DIRRUN}/lbcs.bash

echo -e  "${GREEN}==>${NC} Executing sbatch lbcs.bash...\n"
cd ${DIRRUN}
sbatch --wait ${DIRRUN}/lbcs.bash
mv ${DIRRUN}/lbcs.bash ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs

if [ -z "$(ls ${DATAOUT}/${YYYYMMDDHHi}/Pre/lbc* 2>/dev/null)" ]
then
  echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	
  echo -e  "${RED}==>${NC} LBC phase fails! Check logs at ${DATAOUT}/logs/lbcs.* .\n"
  echo -e  "${RED}==>${NC} Exiting script. \n"
  exit -1
fi

rm -fr ${DIRRUN}
