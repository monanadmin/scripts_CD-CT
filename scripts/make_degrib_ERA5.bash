#!/bin/bash 

if [ $# -ne 6 ]
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
   echo "24 hour forecast example:"
   echo "${0} GFS 1024002 2024010100 24"
   echo "${0} GFS   40962 2024010100 48"
   echo ""

   exit
fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash


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
EXP=${1};         #EXP=GFS
MESH=${2};         #MESH
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2024012000
FCST=${4};        #FCST=24
REGIONAL=${5};    #REGIONAL=Y
LBCINT=${6};
#-------------------------------------------------------

source utils.bash

# Local variables--------------------------------------
start_date=${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}:00:00
YYYYMMDDHHf=$(add_hours "$YYYYMMDDHHi" "$FCST")
final_date=${YYYYMMDDHHf:0:4}-${YYYYMMDDHHf:4:2}-${YYYYMMDDHHf:6:2}_${YYYYMMDDHHf:8:2}:00:00
## !!!!!!!!!!! ATENCAO: AQUI ESTA SENDO ASSUMIDO QUE TODOS OS DADOS DO ERA5 NECESSARIOS PARA O !!!!!!!!!!!
## !!!!!!!!!!!          EXPERIMENTO ESTAO NO SEGUINTE DIRETORIO:                               !!!!!!!!!!!
ERA5_DATA=/pesq/share/monan/curso_OMM_INPE_2025/CGFD-USP_Cases/MPAS-BR/met_data/ERA5/DATA
## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
BNDDIR=${ERA5_DATA}
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#-------------------------------------------------------
mkdir -p ${DATAIN}/${YYYYMMDDHHi}
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs

mkdir -p ${HOME}/local/lib64
cp -f /usr/lib64/libjasper.so* ${HOME}/local/lib64
cp -f /usr/lib64/libjpeg.so* ${HOME}/local/lib64


# Se nao existir CI no diretorio ERA5_data, aborta!
if [ ! -s ${BNDDIR}/era5.pl.${YYYYMMDDHHi}.grib ] || [ ! -s ${BNDDIR}/era5.sl.${YYYYMMDDHHi}.grib ]
then
   echo -e "${RED}==>${NC}Condicao de contorno inexistente !"
   echo -e "${RED}==>${NC}Check ${BNDDIR} or."
   echo -e "${RED}==>${NC}Check ${GCCCIS}"
   exit 1
fi

# Copiar Vtable do ERA5
cp /pesq/share/monan/curso_OMM_INPE_2025/CGFD-USP_Cases/WPS/ungrib/Variable_Tables/Vtable.ECMWF ${DATAIN}/fixed

files_needed=("${DATAIN}/fixed/${MESH}.static.nc" "${DATAIN}/fixed/Vtable.ECMWF" "${EXECS}/ungrib.exe" "${BNDDIR}/era5.pl.${YYYYMMDDHHi}.grib" "${BNDDIR}/era5.sl.${YYYYMMDDHHi}.grib")
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
cp -f ${DATAIN}/fixed/${MESH}.static.nc ${DIRRUN}
cp -f ${DATAIN}/fixed/Vtable.ECMWF ${DIRRUN}/Vtable
cp -f ${EXECS}/ungrib.exe ${DIRRUN}
cp -f ${SCRIPTS}/namelists/namelist.wps.TEMPLATE ${DIRRUN}/namelist.wps.TEMPLATE

cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}
cp -f ${SCRIPTS}/link_grib.csh ${DIRRUN}
rm -f ${DIRRUN}/degrib.bash 

if [[ $REGIONAL == "Y" ]]; then
   echo "REGIONAL=Y. Degribbing ERA5 data for both initial and lateral boundary conditions..."
   cp -f ${BNDDIR}/era5.pl.*.grib ${DATAIN}/${YYYYMMDDHHi}
   cp -f ${BNDDIR}/era5.sl.*.grib ${DATAIN}/${YYYYMMDDHHi}
   cat << EOF0 > ${DIRRUN}/degrib.bash 
#!/bin/bash -x
#SBATCH --job-name=${DEGRIB_jobname}
#SBATCH --nodes=${DEGRIB_nnodes}
#SBATCH --partition=${DEGRIB_QUEUE}
#SBATCH --ntasks=${DEGRIB_ncores}             
#SBATCH --tasks-per-node=${DEGRIB_ncpn}                     # ic for benchmark
#SBATCH --time=${STATIC_walltime}
#SBATCH --output=${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/degrib.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/degrib.e%j     # File name for standard error output
#

ulimit -s unlimited
ulimit -c unlimited
ulimit -v unlimited

export PMIX_MCA_gds=hash


export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${HOME}/local/lib64

cd ${DIRRUN}
. setenv.bash

ldd ungrib.exe

rm -f GRIBFILE.* namelist.wps


sed -e "s,#LABELI#,${start_date},g;s,#LABELF#,${final_date},g;s,#LBCINT#,${LBCINT},g;s,#PREFIX#,ERA5,g" \
	${DIRRUN}/namelist.wps.TEMPLATE > ${DIRRUN}/namelist.wps

./link_grib.csh ${DATAIN}/${YYYYMMDDHHi}/era5.*.grib

date
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
   mv ERA5* ${DATAOUT}/${YYYYMMDDHHi}/Pre

   rm -fr ${DATAIN}/${YYYYMMDDHHi}

echo "End of degrib Job"


EOF0


elif [[ $REGIONAL == "N" ]]; then
   echo "REGIONAL=N. Degribbing ERA5 data only for initial conditions..."
   cp -f ${BNDDIR}/era5.pl.${YYYYMMDDHHi}.grib ${DATAIN}/${YYYYMMDDHHi}
   cp -f ${BNDDIR}/era5.sl.${YYYYMMDDHHi}.grib ${DATAIN}/${YYYYMMDDHHi}   
   cat << EOF0 > ${DIRRUN}/degrib.bash 
#!/bin/bash -x
#SBATCH --job-name=${DEGRIB_jobname}
#SBATCH --nodes=${DEGRIB_nnodes}
#SBATCH --partition=${DEGRIB_QUEUE}
#SBATCH --ntasks=${DEGRIB_ncores}             
#SBATCH --tasks-per-node=${DEGRIB_ncpn}                     # ic for benchmark
#SBATCH --time=${STATIC_walltime}
#SBATCH --output=${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/degrib.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/degrib.e%j     # File name for standard error output
#

ulimit -s unlimited
ulimit -c unlimited
ulimit -v unlimited

export PMIX_MCA_gds=hash


export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${HOME}/local/lib64

cd ${DIRRUN}
. setenv.bash

ldd ungrib.exe

rm -f GRIBFILE.* namelist.wps


sed -e "s,#LABELI#,${start_date},g;s,#LABELF#,${start_date},g;s,#LBCINT#,${LBCINT},g;s,#PREFIX#,ERA5,g" \
	${DIRRUN}/namelist.wps.TEMPLATE > ${DIRRUN}/namelist.wps

./link_grib.csh ${DATAIN}/${YYYYMMDDHHi}/era5.*.${YYYYMMDDHHi}.grib

date
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
   mv ERA5\:${start_date:0:13} ${DATAOUT}/${YYYYMMDDHHi}/Pre

   rm -fr ${DATAIN}/${YYYYMMDDHHi}

echo "End of degrib Job"


EOF0

else
   echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
   echo -e  "${RED}==>${NC} LBCs phase fails during degrib! Please select REGIONAL=Y or REGIONAL=N so that degrib can be done appropriately.\n"
   echo -e  "${RED}==>${NC} Exiting script. \n"
   exit -1
fi


chmod a+x ${DIRRUN}/degrib.bash

echo -e  "${GREEN}==>${NC} Executing sbatch degrib.bash...\n"
cd ${DIRRUN}
sbatch --wait ${DIRRUN}/degrib.bash



files_ungrib=("${EXP}:${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}")
for file in "${files_ungrib[@]}"
do
  if [ ! -s ${DATAOUT}/${YYYYMMDDHHi}/Pre/${file} ] 
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} Degrib fails! At least the file ${file} was not generated at ${DATAIN}/${YYYYMMDDHHi}. \n"
    echo -e  "${RED}==>${NC} Check logs at ${DATAOUT}/logs/degrib.* .\n"
    echo -e  "${RED}==>${NC} Exiting script. \n"
    exit -1
  fi
done

mv ${DIRRUN}/degrib.bash ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs
rm -fr ${DIRRUN}
