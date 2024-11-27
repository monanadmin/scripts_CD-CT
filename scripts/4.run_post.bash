#!/bin/bash
#-----------------------------------------------------------------------------#
# !SCRIPT: run_post
#
# !DESCRIPTION:
#     Script to run the pos-processing of MONAN model over the forecast horizon.
#     
#     Performs the following tasks:
# 
#        o VCheck all input files before
#        o Creates the submition script
#        o Submit the post
#        o Veriffy all files generated
#        
#
#-----------------------------------------------------------------------------#

if [ $# -ne 4 -a $# -ne 1 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} ]EXP_NAME/OP] RESOLUTION LABELI FCST"
   echo ""
   echo "EXP_NAME    :: Forcing: GFS"
   echo "OP          :: clean: remove all temporary files createed in the last run."
   echo "            :: Others options to be added later..."
   echo "RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)"
   echo "LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100"
   echo "FCST        :: Forecast hours, e.g.: 24 or 36, etc."
   echo ""
   echo "24 hour forcast example:"
   echo "${0} GFS 1024002 2024010100 24"
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
      clean_post_tmp_files
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
export SCRIPTS=${DIRHOMES}/scripts;    mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;             mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;           mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;           mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;               mkdir -p ${EXECS}
#----------------------------------------------------------------------


# Input variables:--------------------------------------
EXP=${1};         #EXP=GFS
RES=${2};         #RES=1024002
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2024042000
FCST=${4};        #FCST=40
#-------------------------------------------------------
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Post/logs


# Local variables--------------------------------------
START_DATE_YYYYMMDD="${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}"
START_HH="${YYYYMMDDHHi:8:2}"
maxpostpernode=20    # <------ qtde max de convert_mpas por no!
#-------------------------------------------------------

# Calculating default parameters for different resolutions
if [ $RES -eq 1024002 ]; then  #24Km
   NLAT=720
   NLON=1440
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [ $RES -eq 40962 ]; then  #120Km
   #CR-TODO: verificar se precisa corrigir para esta resolucao tambem:
   NLAT=181
   NLON=361
   STARTLAT=-90.5
   STARTLON=-0.5
   ENDLAT=90.5
   ENDLON=360.5
fi
#-------------------------------------------------------

clean_post_tmp_files

files_needed=("${DATAIN}/namelists/include_fields.diag" "${DATAIN}/namelists/convert_mpas.nml" "${DATAIN}/namelists/target_domain.TEMPLATE" "${EXECS}/convert_mpas" "${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc")
for file in "${files_needed[@]}"
do
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done

# Captura quantos arquivos do modelo tiverem para serem pos-processados e
# quando nos serao necessarios para executar ${maxpostpernode} convert_mpas por no:
#nfiles=$(ls -l ${DATAOUT}/${YYYYMMDDHHi}/Model/MONAN*nc | wc -l)
# from streams.atmosphere.TEMPLATE in diagnostics the output_interval is 3 hours
output_interval=3
#nfiles=FCST/output_interval + 1(time zero file)
nfiles=$(echo "$FCST/$output_interval + 1" | bc)
echo "${nfiles} post to submit."
echo "Max ${maxpostpernode} submits per nodes."
how_many_nodes ${nfiles} ${maxpostpernode}

# Cria os diretorios e arquivos/links para cada saida do convert_mpas:
cd ${SCRIPTS}
for ii in $(seq 1 ${nfiles})
do
   i=$(printf "%03d" ${ii})
   mkdir -p ${SCRIPTS}/dir.${i}

   ln -sf ${DATAIN}/namelists/include_fields.diag  ${SCRIPTS}/dir.${i}/include_fields.diag
   ln -sf ${DATAIN}/namelists/convert_mpas.nml ${SCRIPTS}/dir.${i}/convert_mpas.nml
   sed -e "s,#NLAT#,${NLAT},g;s,#NLON#,${NLON},g;s,#STARTLAT#,${STARTLAT},g;s,#ENDLAT#,${ENDLAT},g;s,#STARTLON#,${STARTLON},g;s,#ENDLON#,${ENDLON},g;" \
      ${DATAIN}/namelists/target_domain.TEMPLATE > ${SCRIPTS}/dir.${i}/target_domain

   rm -rf ${SCRIPTS}/dir.${i}/convert_mpas
   ln -sf ${EXECS}/convert_mpas ${SCRIPTS}/dir.${i}
   ln -sf ${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc ${SCRIPTS}/dir.${i}
   
   hh=${YYYYMMDDHHi:8:2}
   currentdate=$(date -d "${YYYYMMDDHHi:0:8} ${hh}:00 $(echo "(${i}-1)*3" | bc) hours" +"%Y%m%d%H")
   diag_name=MONAN_DIAG_G_MOD_${EXP}_${YYYYMMDDHHi}_${currentdate}.00.00.x${RES}L55.nc
   #CR-TODO: verificar se o arq existe antes de fazer o link:
   ln -sf ${DATAOUT}/${YYYYMMDDHHi}/Model/${diag_name} ${SCRIPTS}/dir.${i}
done

cd ${SCRIPTS}
. ${SCRIPTS}/setenv_python.bash

# Laco para criar os arquivos de submissao com os blocos de convertmpas para cada node:
node=1
inicio=1   
fim=$((maxpostpernode <= nfiles ? maxpostpernode : nfiles))
while [ ${inicio} -le ${nfiles} ]
do
cat > ${SCRIPTS}/PostAtmos_node.${node}.sh <<EOSH
#!/bin/bash
#SBATCH --job-name=MO.Pos${node}
#SBATCH --nodes=1
#SBATCH --partition=${POST_QUEUE}
#SBATCH --time=${POST_walltime}
#SBATCH --output=${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.e%j     # File name for standard error output
#SBATCH --exclusive

. ${SCRIPTS}/setenv.bash
. ${SCRIPTS}/../.venv/bin/activate

echo "Submiting posts ${inicio} to ${fim} in node Node ${node}."

for ii in \$(seq  ${inicio} ${fim})
do
   i=\$(printf "%03d" \${ii})
   echo "Executing post \${i}"
   cd ${SCRIPTS}/dir.\${i}
   
   hh=${YYYYMMDDHHi:8:2}
   currentdate=\$(date -d "${YYYYMMDDHHi:0:8} ${hh}:00 \$(echo "(\${i}-1)*3" | bc) hours" +"%Y%m%d%H")
   diag_name=MONAN_DIAG_G_MOD_${EXP}_${YYYYMMDDHHi}_\${currentdate}.00.00.x${RES}L55.nc
   
   
   rm -f include_fields
   cp include_fields.diag include_fields
   rm -f latlon.nc
   
   time ./convert_mpas x1.${RES}.init.nc ${DATAOUT}/${YYYYMMDDHHi}/Model/\${diag_name}  > convert_mpas.output & 
   echo "./convert_mpas x1.${RES}.init.nc ${DATAOUT}/${YYYYMMDDHHi}/Model/\${diag_name} > convert_mpas.output"
   
done

# necessario aguardar as rodadas em background
wait

for ii in \$(seq  ${inicio} ${fim})
do
   i=\$(printf "%03d" \${ii})
   cd ${SCRIPTS}/dir.\${i}
   python ${SCRIPTS}/group_levels.py ${SCRIPTS}/dir.\${i} latlon.nc latlon_\${i}.nc > saida_python.txt &
done

wait

# unload the python's environment
deactivate

for ii in \$(seq  ${inicio} ${fim})
do
   i=\$(printf "%03d" \${ii})
   cd ${SCRIPTS}/dir.\${i}
   rm -f ${DATAOUT}/${YYYYMMDDHHi}/Post/latlon_\${i}.nc
   cp -f latlon_\${i}.nc ${DATAOUT}/${YYYYMMDDHHi}/Post/ &
done
wait 

EOSH

   chmod a+x ${SCRIPTS}/PostAtmos_node.${node}.sh
   jobid[${node}]=$(sbatch --parsable ${SCRIPTS}/PostAtmos_node.${node}.sh)
   echo "JobId node ${node} = ${jobid[${node}]} , convert_mpas ${inicio} to ${fim}"
  
   inicio=$((fim + 1))
   temp=$((fim + maxpostpernode))
   fim=$(( temp < nfiles ? temp : nfiles ))
   node=$((node+1))
done

# Dependencias JobId:
dependency="afterok"
for job_id in "${jobid[@]}"
do
   dependency="${dependency}:${job_id}"
done





# Script principal para juntar os arquivos finais em um unico:
node=0
cat > ${SCRIPTS}/PostAtmos_node.${node}.sh <<EOSH
#!/bin/bash
#SBATCH --job-name=MO.Pos${node}
#SBATCH --nodes=1
#SBATCH --partition=${POST_QUEUE}
#SBATCH --time=${POST_walltime}
#SBATCH --output=${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.e%j     # File name for standard error output
#SBATCH --exclusive

. ${SCRIPTS}/setenv.bash
. ${SCRIPTS}/../.venv/bin/activate


cd ${DATAOUT}/${YYYYMMDDHHi}/Post

cdo mergetime latlon_*.nc latlon.nc
sleep 5
cdo settunits,hours -settaxis,${START_DATE_YYYYMMDD},${START_HH}:00,3hour latlon.nc MONAN_DIAG_G_POS_${EXP}_${YYYYMMDDHHi}.00.00.x${RES}L55.nc
sleep 5

# Saving important files to the logs directory:
cp -f ${EXECS}/VERSION.txt ${DATAOUT}/${YYYYMMDDHHi}/Post
cp -f ${EXECS}/VERSION.txt ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${SCRIPTS}/dir.001/target_domain ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${SCRIPTS}/dir.001/include_fields.diag ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${SCRIPTS}/dir.001/convert_mpas.nml ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${SCRIPTS}/dir.001/include_fields ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${SCRIPTS}/dir.001/saida_python.txt ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${SCRIPTS}/dir.001/PostAtmos_*.sh  ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${SCRIPTS}/dir.001/convert_mpas.output ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${DATAOUT}/${YYYYMMDDHHi}/Model/logs/* ${DATAOUT}/${YYYYMMDDHHi}/Post/logs


# Removing all files created to run:
rm -rf ${SCRIPTS}/dir.* 
rm -rf ${DATAOUT}/${YYYYMMDDHHi}/Post/latlon*.nc
rm -rf ${SCRIPTS}/PostAtmos_*.sh






EOSH
chmod a+x ${SCRIPTS}/PostAtmos_node.${node}.sh
sbatch --dependency=${dependency} ${SCRIPTS}/PostAtmos_node.${node}.sh 




