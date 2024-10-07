#!/bin/bash 
#-----------------------------------------------------------------------------#
# !SCRIPT: run_model
#
# !DESCRIPTION:
#     Script to run the MONAN model over the forecast horizon.
#     
#     Performs the following tasks:
# 
#        o VCheck all input files before 
#        o Creates the submition script
#        o Submit the model
#        o Veriffy all files generated
#        
#
#-----------------------------------------------------------------------------#

if [ $# -ne 4 -a $# -ne 1 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} [EXP_NAME/OP] RESOLUTION LABELI FCST"
   echo ""
   echo "EXP_NAME    :: Forcing: GFS"
   echo "OP          :: clean: remove all temporary files createed in the last run."
   echo "RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)"
   echo "LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100"
   echo "FCST        :: Forecast hours, e.g.: 24 or 36, etc."
   echo ""
   echo "24 hour forecast example for 24km:"
   echo "${0} GFS 1024002 2024010100 24"
   echo "48 hour forecast example for 120km:"
   echo "${0} GFS   40962 2024010100 48"
   echo "Cleannig temp files example:"
   echo "${0} clean"
   echo ""

   exit
fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash

if [ $# -eq 1 ]
then
   op=$(echo "${1}" | tr '[A-Z]' '[a-z]')
   if [ ${op} = "clean" ]
   then
      clean_model_tmp_files
      exit
   else
      echo "Should type just \"clean\" for cleanning."
      echo "${0} clean"
      echo ""
      exit
   fi   
fi


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
FCST=${4};        #FCST=6
#-------------------------------------------------------
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Model/logs


# Local variables--------------------------------------
start_date=${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}:00:00
cores=${MODEL_ncores}
hhi=${YYYYMMDDHHi:8:2}
NLEV=55
CONFIG_CONV_INTERVAL="00:30:00"

# Calculating default parameters for different resolutions
if [ $RES -eq 1024002 ]; then  #24Km
   CONFIG_DT=180.0
   CONFIG_LEN_DISP=24000.0
   CONFIG_CONV_INTERVAL="00:15:00"
elif [ $RES -eq 40962 ]; then  #120Km
   CONFIG_DT=600.0
   CONFIG_LEN_DISP=120000.0
fi
#-------------------------------------------------------


# Calculating final forecast dates in model namelist format: DD_HH:MM:SS 
# using: start_date(yyyymmdd) + FCST(hh) :
ind=$(printf "%02d\n" $(echo "${FCST}/24" | bc))
inh=$(printf "%02.0f\n" $(echo "((${FCST}/24)-${ind})*24" | bc -l))
DD_HHMMSS_forecast=$(echo "${ind}_${inh}:00:00")


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

clean_model_tmp_files

files_needed=("${DATAIN}/namelists/stream_list.atmosphere.output" ""${DATAIN}/namelists/stream_list.atmosphere.diagnostics "${DATAIN}/namelists/stream_list.atmosphere.surface" "${EXECS}/atmosphere_model" "${DATAIN}/fixed/x1.${RES}.static.nc" "${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores}" "${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc" "${DATAIN}/fixed/Vtable.GFS")
for file in "${files_needed[@]}"
do
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"   
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done

ln -sf ${EXECS}/atmosphere_model ${SCRIPTS}
ln -sf ${DATAIN}/fixed/*TBL ${SCRIPTS}
ln -sf ${DATAIN}/fixed/*DBL ${SCRIPTS}
ln -sf ${DATAIN}/fixed/*DATA ${SCRIPTS}
ln -sf ${DATAIN}/fixed/x1.${RES}.static.nc ${SCRIPTS}
ln -sf ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ${SCRIPTS}
ln -sf ${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc ${SCRIPTS}
ln -sf ${DATAIN}/fixed/Vtable.GFS ${SCRIPTS}


if [ ${EXP} = "GFS" ]
then
   sed -e "s,#LABELI#,${start_date},g;s,#FCSTS#,${DD_HHMMSS_forecast},g;s,#RES#,${RES},g;
s,#CONFIG_DT#,${CONFIG_DT},g;s,#CONFIG_LEN_DISP#,${CONFIG_LEN_DISP},g;s,#CONFIG_CONV_INTERVAL#,${CONFIG_CONV_INTERVAL},g" \
   ${DATAIN}/namelists/namelist.atmosphere.TEMPLATE > ${SCRIPTS}/namelist.atmosphere
   
   sed -e "s,#RES#,${RES},g;s,#CIORIG#,${EXP},g;s,#LABELI#,${YYYYMMDDHHi},g;s,#NLEV#,${NLEV},g" \
   ${DATAIN}/namelists/streams.atmosphere.TEMPLATE > ${SCRIPTS}/streams.atmosphere
fi
cp -f ${DATAIN}/namelists/stream_list.atmosphere.output ${SCRIPTS}
cp -f ${DATAIN}/namelists/stream_list.atmosphere.diagnostics ${SCRIPTS}
cp -f ${DATAIN}/namelists/stream_list.atmosphere.surface ${SCRIPTS}



rm -f ${SCRIPTS}/model.bash 
cat << EOF0 > ${SCRIPTS}/model.bash 
#!/bin/bash
#SBATCH --job-name=${MODEL_jobname}
#SBATCH --nodes=${MODEL_nnodes}
#SBATCH --ntasks=${MODEL_ncores}
#SBATCH --tasks-per-node=${MODEL_ncpn}
#SBATCH --partition=${MODEL_QUEUE}
#SBATCH --time=${MODEL_walltime}
#SBATCH --output=${DATAOUT}/${YYYYMMDDHHi}/Model/logs/model.bash.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/${YYYYMMDDHHi}/Model/logs/model.bash.e%j     # File name for standard error output
#SBATCH --exclusive
##SBATCH --mem=500000


export executable=atmosphere_model

ulimit -c unlimited
ulimit -v unlimited
ulimit -s unlimited

. $(pwd)/setenv.bash

cd ${SCRIPTS}


date
time mpirun -np \${SLURM_NTASKS} -env UCX_NET_DEVICES=mlx5_0:1 -genvall ./\${executable}
date

#
# move dataout, clean up and remove files/links
#

mv MONAN_DIAG_* ${DATAOUT}/${YYYYMMDDHHi}/Model
mv MONAN_HIST_* ${DATAOUT}/${YYYYMMDDHHi}/Model
cp ${EXECS}/VERSION.txt ${DATAOUT}/${YYYYMMDDHHi}/Model

mv log.atmosphere.*.out ${DATAOUT}/${YYYYMMDDHHi}/Model/logs
mv log.atmosphere.*.err ${DATAOUT}/${YYYYMMDDHHi}/Model/logs
mv namelist.atmosphere ${DATAOUT}/${YYYYMMDDHHi}/Model/logs
mv stream* ${DATAOUT}/${YYYYMMDDHHi}/Model/logs

rm -f ${SCRIPTS}/atmosphere_model
rm -f ${SCRIPTS}/*TBL 
rm -f ${SCRIPTS}/*.DBL
rm -f ${SCRIPTS}/*DATA
rm -f ${SCRIPTS}/x1.${RES}.static.nc
rm -f ${SCRIPTS}/x1.${RES}.graph.info.part.${cores}
rm -f ${SCRIPTS}/Vtable.GFS
rm -f ${SCRIPTS}/x1.${RES}.init.nc



EOF0
chmod a+x ${SCRIPTS}/model.bash


echo -e  "${GREEN}==>${NC} Submitting MONAN atmosphere model and waiting for finish before exit... \n"
echo -e  "${GREEN}==>${NC} Logs being generated at ${DATAOUT}/logs... \n"
echo -e  "sbatch ${SCRIPTS}/model.bash"
sbatch --wait ${SCRIPTS}/model.bash
mv ${SCRIPTS}/model.bash ${DATAOUT}/${YYYYMMDDHHi}/Model/logs


output_interval=3
for i in $(seq 0 ${output_interval} ${FCST})
do
   hh=${YYYYMMDDHHi:8:2}
   currentdate=$(date -u +"%Y%m%d%H" -d "${YYYYMMDDHHi:0:8} ${hh}:00 ${i} hours")
   file=MONAN_DIAG_G_MOD_GFS_${YYYYMMDDHHi}_${currentdate}.00.00.x${RES}L55.nc
   
   if [ ! -s ${DATAOUT}/${YYYYMMDDHHi}/Model/${file} ]
   then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${DATAOUT}/${YYYYMMDDHHi}/Model/${file} was not generated. \n"
    exit -1
  fi
      
done

   
