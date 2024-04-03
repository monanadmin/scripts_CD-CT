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
DIRHOMES=${DIR_SCRIPTS}/MONAN;   mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/MONAN;     mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;     mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;       mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;     mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;     mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;         mkdir -p ${EXECS}
#----------------------------------------------------------------------


# Input variables:--------------------------------------
EXP=${1};         #EXP=GFS
RES=${2};         #RES=1024002
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2024012000
FCST=${4};        #FCST=6
#-------------------------------------------------------
cp -f setenv.bash ${SCRIPTS}
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Model/logs


# Local variables--------------------------------------
start_date=${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}:00:00
ncores=${MODEL_ncores}
hhi=${YYYYMMDDHHi:8:2}
#-------------------------------------------------------
mkdir -p ${DATAIN}/namelists
cp -f $(pwd)/../namelists/* ${DATAIN}/namelists

# Calculating final forecast dates in model namelist format: DD_HH:MM:SS 
# using: start_date(yyyymmdd) + FCST(hh) :
ind=$(printf "%02d\n" $(echo "${FCST}/24" | bc))
inh=$(printf "%02.0f\n" $(echo "((${FCST}/24)-${ind})*24" | bc -l))
DD_HHMMSS_forecast=$(echo "${ind}_${inh}:00:00")


if [ ! -s ${DATAIN}/fixed/x1.${RES}.graph.info.part.${ncores} ]
then
   echo -e "${RED}==>${NC} File x1.${RES}.graph.info.part.${ncores} does not exist in ${DATAIN}/fixed.\n"
   echo -e "${RED}==>${NC} Need to be created: module load metis/5.1.0, and follow the instructions:\n"
   echo -e "${RED}==>${NC} ...maybe create a script to do that in the future... \n"
   exit
fi


#CR: verify if input files exist before submit the model:
ln -sf ${EXECS}/atmosphere_model ${SCRIPTS}
ln -sf ${DATAIN}/fixed/*TBL ${SCRIPTS}
ln -sf ${DATAIN}/fixed/*DBL ${SCRIPTS}
ln -sf ${DATAIN}/fixed/*DATA ${SCRIPTS}
ln -sf ${DATAIN}/fixed/x1.${RES}.static.nc ${SCRIPTS}
ln -sf ${DATAIN}/fixed/x1.${RES}.graph.info.part.${ncores} ${SCRIPTS}
ln -sf ${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc ${SCRIPTS}
ln -sf ${DATAIN}/fixed/Vtable.GFS ${SCRIPTS}
ln -sf ${DATAIN}/fixed/Vtable.ERA-interim.pl ${SCRIPTS}


if [ ${EXP} = "GFS" ]
then
   sed -e "s,#LABELI#,${start_date},g" \
         ${DATAIN}/namelists/namelist.atmosphere.TEMPLATE > ${SCRIPTS}/namelist.atmosphere.1
   sed -e "s,#FCSTS#,${DD_HHMMSS_forecast},g" \
         ${SCRIPTS}/namelist.atmosphere.1 > ${SCRIPTS}/namelist.atmosphere
   rm -f ${SCRIPTS}/namelist.atmosphere.1
   cp -f ${DATAIN}/namelists/streams.atmosphere.TEMPLATE ${SCRIPTS}/streams.atmosphere
fi
cp -f ${DATAIN}/namelists/stream_list.atmosphere.* ${SCRIPTS}


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

mv diag* ${DATAOUT}/${YYYYMMDDHHi}/Model
mv histor* ${DATAOUT}/${YYYYMMDDHHi}/Model

mv log.atmosphere.*.out ${DATAOUT}/${YYYYMMDDHHi}/Model/logs
mv log.atmosphere.*.err ${DATAOUT}/${YYYYMMDDHHi}/Model/logs
mv namelist.atmosphere ${DATAOUT}/${YYYYMMDDHHi}/Model/logs
mv stream* ${DATAOUT}/${YYYYMMDDHHi}/Model/logs

rm -f ${SCRIPTS}/atmosphere_model
rm -f ${SCRIPTS}/*TBL 
rm -f ${SCRIPTS}/*.DBL
rm -f ${SCRIPTS}/*DATA
rm -f ${SCRIPTS}/x1.${RES}.static.nc
rm -f ${SCRIPTS}/x1.${RES}.graph.info.part.${ncores}
rm -f ${SCRIPTS}/Vtable.GFS
rm -f ${SCRIPTS}/Vtable.ERA-interim.pl
rm -f ${SCRIPTS}/x1.${RES}.init.nc



EOF0
chmod a+x ${SCRIPTS}/model.bash

echo -e  "${GREEN}==>${NC} Submitting MONAN atmosphere model and waiting for finish before exit... \n"
echo -e  "${GREEN}==>${NC} Logs being generated at ${DATAOUT}/logs... \n"
echo -e  "sbatch ${SCRIPTS}/model.bash"
sbatch --wait ${SCRIPTS}/model.bash


#CR: make a subroutine to check each output file gerated here! 
#CR: Very important make sure all files was created correctly before go foreward
#CR: Copy all model output files to his final name: e.g: 
#
# MONANGMODGFSYYYYMMDDHHyyyymmddhh.24kmL55.nc
# |---|||-||-||--------||--------|  |   |  |--file format
# |    ||  |  |         |           |   |--levels quant.
# |    ||  |  |         |           |--resolution, also could be 1024002, e.g.
# |    ||  |  |         |--Forecast final date
# |    ||  |  |--Initial condition date
# |    ||  |--Initial condition source type: GFS, ERA5, ERAI, etc
# |    ||--MOD for model, POS for post processed output files
# |    |-- Type fo horiontal domain: G for global, R for regional, etc.
# |--Name of the model: MONAN
