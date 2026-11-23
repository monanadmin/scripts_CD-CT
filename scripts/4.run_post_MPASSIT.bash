#!/bin/bash 

#-----------------------------------------------------------------------------#
# !SCRIPT: run_mpassit
#
# !DESCRIPTION:
#     Script to run the MPASSIT pos-processing of MONAN model over the forecast 
#     horizon.
#     
#     Performs the following tasks:
# 
#        o Check all input files before
#        o Creates the submition script
#        o Submit the post
#        o Veriffy all files generated
#        
#  Author: Carlos Renato
#
#-----------------------------------------------------------------------------#
# TODO List:
#
# 1. 

if [ $# -ne 4 -a $# -ne 1 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} [EXP_NAME/OP] RESOLUTION LABELI FCST"
   echo ""
   echo "EXP_NAME    :: Forcing: GFS"
   echo "RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)"
   echo "LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100"
   echo "FCST        :: Forecast hours, e.g.: 24 or 36, etc."
   echo ""
   echo "24 hour forcast example:"
   echo "${0} GFS 1024002 2024010100 24"
   echo "${0} GFS   40962 2024010100 48"
   echo ""

   exit
fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash

echo ""
echo "---- Run Post: MPASSIT ----"
echo ""

# Standart directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/${myDIR};  mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/${myDIR};    mkdir -p ${DIRHOMED}  
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
VARTABLE=".OPER"
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
N_MODEL_LEV=55
NLEV=18
export maxpostpernode=10     # <------ qtde max de pos por no, nao PODE ALTERAR!
cores=${MPASSIT_ncpexec}
MODELOUTPUTDIR=${DATAOUT}/${YYYYMMDDHHi}/Model  # if you want pos-processing MONAN files that are
                                                # in other place, put your MONAN dataout dir here!
#-------------------------------------------------------

# Variables for flex outpout interval from streams.atmosphere------------------------
t_strout=$(cat ${SCRIPTS}/namelists/${MONANVERSION}/streams.atmosphere.TEMPLATE | sed -n '/<stream name="diagnostics"/,/<\/stream>/s/.*output_interval="\([^"]*\)".*/\1/p')
t_stroutsec=$(echo ${t_strout} | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}')
t_strouthor=$(echo "scale=4; (${t_stroutsec}/60)/60" | bc)
t_stroutmin=$(echo "${t_stroutsec}/60" | bc)
#------------------------------------------------------------------------------------

# Format to HH:MM:SS t_strout (output_interval)
IFS=":" read -r h m s <<< "${t_strout}"
printf -v t_strout "%02d:%02d:%02d" "$h" "$m" "$s"

# Calculating default parameters for different resolutions
# global mesh
if [[ "$RES" == "40962" ]]; then  #120Km
   NLAT=151 #180/1.2
   NLON=301 #360/1.2
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "163842" ]]; then  #60Km
   NLAT=301 #180/0.6
   NLON=601 #360/0.6
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "655362" ]]; then  #30Km
   NLAT=601 #180/0.3
   NLON=1201 #360/0.3
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "1024002" ]]; then  #24Km
   NLAT=721  #180/0.25
   NLON=1441 #360/0.25
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "2621442" ]]; then  #15Km
   NLAT=1201 #180/0.15
   NLON=2401 #360/0.15
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "5898242" ]]; then  #10Km
   NLAT=1801 #180/0.10
   NLON=3601 #360/0.10
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "23592962" ]]; then  #5Km
   NLAT=3601 #180/0.05
   NLON=7201 #360/0.05
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "65536002" ]]; then  #3Km
   NLAT=6001 #180/0.03 
   NLON=12001 #360/0.03 
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
# regional mesh
elif [[ "$RES" == "30km_LAC" ]]; then #30 km (AMS + Caribe)
   NLAT=354     #106/0.3 +1
   NLON=301     #90/0.3 +1
   STARTLAT=-64.0
   ENDLAT=42
   STARTLON=254.0
   ENDLON=344.0
   DLAT=0.3
   DLON=0.3
   MPASSIT_NX=$((NLON + 1))     # MPASSIT: nx-1 pontos de saida -> 302
   MPASSIT_NY=$((NLAT + 1))     # MPASSIT: ny-1 pontos de saida -> 355
   # centro do bloco de pontos (a ultima lat e 41.9, nao 42) -> -11.05
   MPASSIT_REF_LAT=$(awk -v s=$STARTLAT -v n=$NLAT -v d=$DLAT 'BEGIN{printf "%.4f", s+(n-1)*d/2}')
   # centro em lon convertido para [-180,180] -> -61.0
   MPASSIT_REF_LON=$(awk -v s=$STARTLON -v n=$NLON -v d=$DLON 'BEGIN{c=s+(n-1)*d/2; if(c>180)c-=360; printf "%.4f", c}')
elif [[ "$RES" == "10km_LAC" ]]; then #10 km (AMS + Caribe)
   NLAT=1061   #106/0.1 +1
   NLON=901   #90/0.1 +1
   STARTLAT=-64.0
   ENDLAT=42.0
   STARTLON=254.0
   ENDLON=344.0
   DLAT=0.1
   DLON=0.1
   MPASSIT_NX=$((NLON + 1))     # MPASSIT: nx-1 pontos de saida -> 902
   MPASSIT_NY=$((NLAT + 1))     # MPASSIT: ny-1 pontos de saida -> 1062
   # centro do bloco de pontos (ultima lat = 42.0) -> -11.0
   MPASSIT_REF_LAT=$(awk -v s=$STARTLAT -v n=$NLAT -v d=$DLAT 'BEGIN{printf "%.4f", s+(n-1)*d/2}')
   # centro em lon convertido para [-180,180] -> -61.0
   MPASSIT_REF_LON=$(awk -v s=$STARTLON -v n=$NLON -v d=$DLON 'BEGIN{c=s+(n-1)*d/2; if(c>180)c-=360; printf "%.4f", c}')
elif [[ "$RES" == "05km_LAC" ]]; then #5 km (AMS + Caribe)
   NLAT=2121    #106/0.05 +1
   NLON=1801    #90/0.05 +1
   STARTLAT=-64.0
   ENDLAT=42.0
   STARTLON=254.0
   ENDLON=344.0
   DLAT=0.05
   DLON=0.05
   MPASSIT_NX=$((NLON + 1))     # MPASSIT: nx-1 pontos de saida -> 1802
   MPASSIT_NY=$((NLAT + 1))     # MPASSIT: ny-1 pontos de saida -> 2122
   # centro do bloco de pontos (ultima lat = 42.0) -> -11.0
   MPASSIT_REF_LAT=$(awk -v s=$STARTLAT -v n=$NLAT -v d=$DLAT 'BEGIN{printf "%.4f", s+(n-1)*d/2}')
   # centro em lon convertido para [-180,180] -> -61.0
   MPASSIT_REF_LON=$(awk -v s=$STARTLON -v n=$NLON -v d=$DLON 'BEGIN{c=s+(n-1)*d/2; if(c>180)c-=360; printf "%.4f", c}')
else
   # Define convert_mpas target domain automatically from the grid file
   echo -e "Calculating convert_mpas target domain of personalized mesh...\n"
   GRIDFILE="${DATAIN}/fixed/x1.${RES}.grid.nc"
   MESH_RES_RAD=$(ncdump -v nominalMinDc "${GRIDFILE}" 2>/dev/null | awk '/nominalMinDc =/ {print $3; exit}')
   MESH_RES_KM=$(awk -v res="${MESH_RES_RAD}" 'BEGIN {printf "%.0f", res * 6371.0}')
   # Domain margin ("gordura")
   DOMAIN_MARGIN=2
   # %.3f: evita espacamento 0.0 para malhas finas (ex.: 3 km -> 0.03)
   GRID_SPACING=$(awk -v res="${MESH_RES_KM}" 'BEGIN {printf "%.3f", res / 100.0}')
   # Get minimum and maximum cell-center coordinates
   LAT_MIN_RAD=$(cdo -s infon -selname,latCell "${GRIDFILE}" 2>/dev/null | awk '/latCell/ {print $9; exit}')
   LAT_MAX_RAD=$(cdo -s infon -selname,latCell "${GRIDFILE}" 2>/dev/null | awk '/latCell/ {print $11; exit}')
   LON_MIN_RAD=$(cdo -s infon -selname,lonCell "${GRIDFILE}" 2>/dev/null | awk '/lonCell/ {print $9; exit}')
   LON_MAX_RAD=$(cdo -s infon -selname,lonCell "${GRIDFILE}" 2>/dev/null | awk '/lonCell/ {print $11; exit}')
   # Convert radians to degrees
   RAD2DEG=57.29577951308232
   LAT_MIN=$(awk -v x="${LAT_MIN_RAD}" -v c="${RAD2DEG}" 'BEGIN {printf "%.1f", x*c}')
   LAT_MAX=$(awk -v x="${LAT_MAX_RAD}" -v c="${RAD2DEG}" 'BEGIN {printf "%.1f", x*c}')
   LON_MIN=$(awk -v x="${LON_MIN_RAD}" -v c="${RAD2DEG}" 'BEGIN {printf "%.1f", x*c}')
   LON_MAX=$(awk -v x="${LON_MAX_RAD}" -v c="${RAD2DEG}" 'BEGIN {printf "%.1f", x*c}')
   # Add domain margin ("gordura")
   STARTLAT=$(awk -v x="${LAT_MIN}" -v m="${DOMAIN_MARGIN}" 'BEGIN {printf "%.1f", x-m}')
   ENDLAT=$(awk -v x="${LAT_MAX}" -v m="${DOMAIN_MARGIN}" 'BEGIN {printf "%.1f", x+m}')
   STARTLON=$(awk -v x="${LON_MIN}" -v m="${DOMAIN_MARGIN}" 'BEGIN {printf "%.1f", x-m}')
   ENDLON=$(awk -v x="${LON_MAX}" -v m="${DOMAIN_MARGIN}" 'BEGIN {printf "%.1f", x+m}')
   # Number of intervals in the regular lat-lon grid.
   NLAT=$(awk -v start="${STARTLAT}" -v end="${ENDLAT}" -v d="${GRID_SPACING}" 'BEGIN {printf "%.0f", (end-start)/d}')
   NLON=$(awk -v start="${STARTLON}" -v end="${ENDLON}" -v d="${GRID_SPACING}" 'BEGIN {printf "%.0f", (end-start)/d}')
   DLAT=${GRID_SPACING}
   DLON=${GRID_SPACING}
   # --- MPASSIT ---
   # Aqui NLAT/NLON sao INTERVALOS -> pontos = N+1 -> nx/ny MPASSIT = pontos+1 = N+2
   MPASSIT_NX=$((NLON + 2))
   MPASSIT_NY=$((NLAT + 2))
   # centro do bloco de pontos: START + N*d/2
   MPASSIT_REF_LAT=$(awk -v s=$STARTLAT -v n=$NLAT -v d=$DLAT 'BEGIN{printf "%.4f", s+n*d/2}')
   # centro em lon convertido para [-180,180]
   MPASSIT_REF_LON=$(awk -v s=$STARTLON -v n=$NLON -v d=$DLON 'BEGIN{c=s+n*d/2; if(c>180)c-=360; printf "%.4f", c}')
   echo -e "  Resolution     : ${MESH_RES_KM} km"
   echo -e "  Grid spacing   : ${GRID_SPACING} deg"
   echo -e "  STARTLAT       : ${STARTLAT}"
   echo -e "  ENDLAT         : ${ENDLAT}"
   echo -e "  STARTLON       : ${STARTLON}"
   echo -e "  ENDLON         : ${ENDLON}"
   echo -e "  NLAT           : ${NLAT}"
   echo -e "  NLON           : ${NLON}"
   echo -e "  MPASSIT nx/ny  : ${MPASSIT_NX} / ${MPASSIT_NY}"
   echo -e "  MPASSIT ref    : ${MPASSIT_REF_LAT} / ${MPASSIT_REF_LON}\n"
fi
#-------------------------------------------------------


# Getting info part file:
#CR: Later this code should become a function in setenv.bash:

fixedDir=${DATAIN}/fixed
altFixedDir=${MODELOUTPUTDIR}/../../../datain/fixed
graphName=x1.${RES}.graph.info
partName=${graphName}.part.${cores}

if [ -s "${fixedDir}/${partName}" ]
then
   grafInfoPartFile=${fixedDir}/${partName}
   echo "Using ${grafInfoPartFile}"
elif [ -s "${altFixedDir}/${partName}" ]
then
   echo "Copying ${altFixedDir}/${partName} to ${fixedDir}"
   cp -f ${altFixedDir}/${partName} ${fixedDir}
   grafInfoPartFile=${fixedDir}/${partName}
else
   echo -e "${GREEN}==>${NC} Nao existe ${partName}, buscando ${graphName} ..."
   mkdir -p "${fixedDir}"

   if [ ! -s "${fixedDir}/${graphName}" ]
   then
      if [ -s "${altFixedDir}/${graphName}" ]
      then
         echo "Copying $${altFixedDir}/${graphName} to ${fixedDir}"
         cp -f ${altFixedDir}/${graphName} ${fixedDir}
         grafInfoFile=${fixedDir}/${graphName}
      else
         (
            if [[ $MODERUN == "G" ]]
            then
               echo -e "${GREEN}==>${NC} Nao existe ${graphName}, baixando do site oficial MPAS:"
               cd "${fixedDir}" &&
               wget "https://www2.mmm.ucar.edu/projects/mpas/atmosphere_meshes/x1.${RES}.tar.gz" &&
               tar -xzvf "x1.${RES}.tar.gz" &&
               rm -f "x1.${RES}.tar.gz"
            else
               echo -e  "${RED}----------------------------------"
               echo -e  "${RED}==>${NC} Post fails! Please make sure your REGIONAL files are in correct places:"
               echo -e  "  ${RED}==>${NC} ${fixedDir}/${graphName} or ${partName}"
               echo -e  "  ${RED}==>${NC} ${altFixedDir}/${graphName} or ${partName}"
               echo -e  "${RED}----------------------------------"
               exit 1
            fi
         ) || { echo "${RED}==>${NC} *****ERRO: falha ao baixar ou extrair x1.${RES}.tar.gz"; exit 1; }
      fi
   fi

   echo -e "${GREEN}==>${NC} Creating ${partName} ... \n"
   gpmetis -minconn -contig -niter=200 ${grafInfoFile} ${cores} ||
      { echo "ERRO: gpmetis falhou"; exit 1; }
   grafInfoPartFile=${fixedDir}/${partName}
fi

files_needed=("${SCRIPTS}/namelists/${MONANVERSION}/namelist.input.TEMPLATE" 
              "${SCRIPTS}/namelists/${MONANVERSION}/varlist_2d${VARTABLE}" 
              "${SCRIPTS}/namelists/${MONANVERSION}/varlist_3d${VARTABLE}" 
              "${EXECS}/${MPASSITVERSION}/mpassit" 
              "${grafInfoPartFile}")
              
for file in "${files_needed[@]}"
do
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done


# Searching for x1.${RES}.init.nc:
# First looking into default MPASSIT-PRE-dataout dir:
if [ -s "${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc" ]
then
   export INIT_FILE="${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc"
elif [ -s "${DATAIN}/fixed/x1.${RES}.init.nc" ] # Looking into MPASSIT-PRE-datain dir:
then 
   export INIT_FILE="${DATAIN}/fixed/x1.${RES}.init.nc"
elif [ -s "${MODELOUTPUTDIR}/../Pre/x1.${RES}.init.nc" ] # Looking into  MONAN-PRE-dataout dir:
then
   export INIT_FILE="${MODELOUTPUTDIR}/../Pre/x1.${RES}.init.nc"
elif [ -s "${MODELOUTPUTDIR}/../../../datain/fixed/x1.${RES}.init.nc" ] # Looking into  MONAN-PRE-datain dir:
then  
   export INIT_FILE="${MODELOUTPUTDIR}/../../../datain/fixed/x1.${RES}.init.nc"
elif [ -s  "${GCCCIS}/MONAN/${YYYYMMDDHHi:0:4}/${YYYYMMDDHHi}/x1.${RES}.init.nc" ] # Looking into  GCC-CIs dir:
then
   export INIT_FILE="${GCCCIS}/MONAN/${YYYYMMDDHHi:0:4}/${YYYYMMDDHHi}/x1.${RES}.init.nc"
else
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] File x1.${RES}.init.nc is not available. \n"
    exit 1
fi  
echo "Using ${INIT_FILE}." 


# Captura quantos arquivos do modelo tiverem para serem pos-processados e
# quando nos serao necessarios para executar ${maxpostpernode} convert_mpas por no:
#nfiles=$(ls -l ${DATAOUT}/${YYYYMMDDHHi}/Model/MONAN*nc | wc -l)
# from streams.atmosphere.TEMPLATE in diagnostics the output_interval is flexible
output_interval=${t_strouthor}
#nfiles=FCST/output_interval + 1(time zero file)
nfiles=$(echo "$FCST/$output_interval + 1" | bc)
echo "${nfiles} post to submit."
echo "Max ${maxpostpernode} submits per nodes."
echo "${cores} cores per post."
how_many_nodes ${nfiles} ${maxpostpernode}



# Cria os diretorios e arquivos/links para cada saida do MPASSIT:
cd ${DIRRUN}


if [[ $MODERUN == "R" ]]; then
   echo -e "Post is running in Regional (limited-area) mode.\n"
   RANSWER=.true.
elif [[ $MODERUN == "G" ]]; then
   echo -e "Post is running in Global mode.\n"
   RANSWER=.false.
else
   echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
   echo -e  "${RED}==>${NC} Post fails! Please select MODERUN=R (Regional) or MODERUN=G (Global) in 'setenv.bash'.\n"
   echo -e  "${RED}==>${NC} Exiting script. \n"
   exit 1
fi


for ii in $(seq 1 ${nfiles})
do
   i=$(printf "%04d" ${ii})
   mkdir -p ${DIRRUN}/dir.${i}
   cp -f ${SCRIPTS}/setenv.bash                                     ${DIRRUN}/dir.${i}
   cp -f ${SCRIPTS}/namelists/${MONANVERSION}/varlist_2d${VARTABLE} ${DIRRUN}/dir.${i}/varlist_2d
   cp -f ${SCRIPTS}/namelists/${MONANVERSION}/varlist_3d${VARTABLE} ${DIRRUN}/dir.${i}/varlist_3d
   cp -f ${EXECS}/${MPASSITVERSION}/mpassit                         ${DIRRUN}/dir.${i} 
   hh=${YYYYMMDDHHi:8:2}
   currentdate=$(date -d "${YYYYMMDDHHi:0:8} ${hh}:00:00 $(echo "(${i}-1)*${t_strout:0:2}" | bc) hours $(echo "(${i}-1)*${t_strout:3:2}" | bc) minutes $(echo "(${i}-1)*${t_strout:6:2}" | bc) seconds" +"%Y%m%d%H.%M.%S")
   diag_name=MONAN_DIAG_${MODERUN}_MOD_${EXP}_${YYYYMMDDHHi}_${currentdate}.x${RES}L${N_MODEL_LEV}.nc
   
   if [[ ${MODERUN} == "G" ]]
   then
      sed -e "
         s,#INITFILE#,${INIT_FILE},g;
         s,#MODELFILE#,${MODELOUTPUTDIR}/${diag_name},g;
         s,#GRAPHINFOFILE#,${grafInfoPartFile},g;
         s,#NLAT#,${NLAT},g;
         s,#NLON#,${NLON},g; 
         s,#REGANSWER#,${RANSWER},g;" \
         ${SCRIPTS}/namelists/${MONANVERSION}/namelist.input.TEMPLATE > ${DIRRUN}/dir.${i}/namelist.input
   else
      sed -e "
         s,#INITFILE#,${INIT_FILE},g;
         s,#MODELFILE#,${MODELOUTPUTDIR}/${diag_name},g;
         s,#GRAPHINFOFILE#,${grafInfoPartFile},g;
         s,#NLAT#,${MPASSIT_NY},g;
         s,#NLON#,${MPASSIT_NX},g; 
         s,#REGANSWER#,${RANSWER},g;
         /stand_lon/d;
         /ny/a\ dx                   = ${DLON}
         /ny/a\ dy                   = ${DLAT}
         /ny/a\ ref_lat              = ${MPASSIT_REF_LAT}
         /ny/a\ ref_lon              = ${MPASSIT_REF_LON}" \
         ${SCRIPTS}/namelists/${MONANVERSION}/namelist.input.TEMPLATE > ${DIRRUN}/dir.${i}/namelist.input
   fi     
done


cd ${DIRRUN}
chmod -R 755 ${DIRRUN}/*

# Laco para criar os arquivos de submissao com os blocos de mpassit para cada node:
node=1
inicio=1   
fim=$((maxpostpernode <= nfiles ? maxpostpernode : nfiles))




while [ ${inicio} -le ${nfiles} ]
do
   rm -f ${DIRRUN}/PostAtmos_node.${node}.sh
cat << EOSH >> ${DIRRUN}/PostAtmos_node.${node}.sh 
#!/bin/bash
#PBS -N MPASSIT.${node}
#PBS -q ${MPASSIT_QUEUE}
#PBS -l select=1:ncpus=${MPASSIT_ncpus}:mpiprocs=${MPASSIT_ncpn}:ompthreads=${MPASSIT_nthreads}
#PBS -l walltime=${MPASSIT_walltime}
#PBS -o ${DIRRUN/lustre/p}/
#PBS -e ${DIRRUN/lustre/p}/
#PBS -l place=scatter:excl
#PBS -V

cd ${DIRRUN}
. ${SCRIPTS}/setenv.bash
#----------------------------------------------------------------------
# Here some differences that must be loaded just for MPASSIT install/use, 
# in the future, we will put all togheter in one setenv.bash, 
# but for now need to load them here:
#
# Compiladores Cray
export CMAKE_C_COMPILER=cc
export CMAKE_Fortran_COMPILER=ftn
# Load modules
module purge
module load PrgEnv-gnu
module load craype-x86-turin
module load cray-hdf5-parallel/1.14.3.3
module load cray-netcdf-hdf5parallel/4.9.0.15
module load cray-parallel-netcdf/1.12.3.15
module load xpmem/0.2.119-1.3_gef379be13330
module load cray-pals
module load esmf/8.9.1-gcc13
module load METIS/5.1.0
module load grads

# NetCDF paralelo - NETCDF_DIR eh definido pelo modulo cray-netcdf-hdf5parallel
export NETCDF=${NETCDF_DIR}
export LD_LIBRARY_PATH=${NETCDF_DIR}/lib:${LD_LIBRARY_PATH}
# ESMF compilado com NetCDF paralelo NA JACI:
export ESMF_INCDIR=${ESMF_DIR}/include
export ESMF_LIBDIR=${ESMF_DIR}/lib/libO/Unicos.gfortran.64.mpi.default
export ESMF_MODDIR=${ESMF_DIR}/mod/modO/Unicos.gfortran.64.mpi.default
export LIBRARY_PATH=${LIBRARY_PATH}:${ESMF_LIBDIR}
export PATH=${PATH}:${ESMF_DIR}/bin/binO/Unicos.gfortran.64.mpi.default
export ESMF_FFLAGS="-I${ESMF_MODDIR} -I${ESMF_INCDIR}"
export ESMF_LDFLAGS="-L${ESMF_LIBDIR} -lesmf"
export ESMF_COMPILER="gfortran"
export ESMF_F90COMPILER=ftn
export ESMF_CXXCOMPILER=CC
export ESMF_CCCOMPILER=cc
export ESMF_F90LINKER=ftn
# Confirma que NETCDF_DIR aponta para o paralelo
echo "NETCDF_DIR = ${NETCDF_DIR}"
echo -n "NETCDF_DIR paralelo? "
nc-config --has-parallel4
#----------------------------------------------------------------------

chmod 755 ${DIRRUN}/*

echo "Executing posts ${inicio} to ${fim} in node Node ${node}."

cpulist1=\$(seq -s: 0 127)
cpulist2=\$(seq -s: 128 255)

for ii in \$(seq  ${inicio} ${fim})
do
   i=\$(printf "%04d" \${ii})
   echo "Executing post \${i}"
   cd ${DIRRUN}/dir.\${i}
   chmod 755 *
   chmod 755 ${DATAOUT}/${YYYYMMDDHHi}/Model/*

   if [ \$(( ii % 2 )) -eq 0 ]; then
      cpulist=\${cpulist1}
   else
      cpulist=\${cpulist2}
   fi 
     
   echo "time mpiexec -n 128 -cpu-bind=verbose,list:\${cpulist} ./mpassit namelist.input"
   time mpiexec -n 128 -cpu-bind=list:\${cpulist} ./mpassit namelist.input &
   
   
   (( ii % 2 == 0 )) && wait
   
   
   
done
# necessario aguardar as rodadas em background
wait
   
for ii in \$(seq  ${inicio} ${fim})
do
   i=\$(printf "%04d" \${ii})
   hh=${YYYYMMDDHHi:8:2}
   currentdate=\$(date -d "${YYYYMMDDHHi:0:8} \${hh}:00:00 \$(echo "(\${i}-1)*${t_strout:0:2}" | bc) hours \$(echo "(\${i}-1)*${t_strout:3:2}" | bc) minutes \$(echo "(\${i}-1)*${t_strout:6:2}" | bc) seconds" +"%Y%m%d%H.%M.%S")
   diag_name_post=MONAN_DIAG_${MODERUN}_POS_${EXP}_${YYYYMMDDHHi}_\${currentdate}.x${RES}L${N_MODEL_LEV}.nc

   cd ${DIRRUN}/dir.\${i}
   chmod 755 *
   cp -f monan-mpassit-output.nc  ${DATAOUT}/${YYYYMMDDHHi}/Post/\${diag_name_post} & 
   echo "monan-mpassit-output.nc  ${DATAOUT}/${YYYYMMDDHHi}/Post/\${diag_name_post}"  >> mpassit.output
   
done
 
wait




EOSH
   chmod a+x ${DIRRUN}/PostAtmos_node.${node}.sh 
   cd ${DIRRUN}
   echo -e  "${GREEN}==>${NC} qsub PostAtmos_node.${node}.sh ${inicio} ${fim} \n"
   
   jobid[${node}]=$(qsub ${DIRRUN}/PostAtmos_node.${node}.sh  | cut -d '.' -f1)
   cp -f ${DIRRUN}/PostAtmos_node.${node}.sh ${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.sh_${jobid[${node}]}

   inicio=$((fim + 1))
   temp=$((fim + maxpostpernode))
   fim=$(( temp < nfiles ? temp : nfiles ))
   node=$((node+1))
   sleep 5
done


# Dependencias JobId:
dependency="afterok"
for job_id in "${jobid[@]}"
do
   dependency="${dependency}:${job_id}"
done


# Script final , para conferir todos os arquivos, criar o template final  e apagar o diretorio DIRRUN
node=0
diag_name_post=MONAN_DIAG_${MODERUN}_POS_${EXP}_${YYYYMMDDHHi}_${YYYYMMDDHHi}.00.00.x${RES}L${N_MODEL_LEV}.nc
diag_name_templ=MONAN_DIAG_${MODERUN}_POS_${EXP}_${YYYYMMDDHHi}_%y4%m2%d2%h2.%n2.00.x${RES}L${N_MODEL_LEV}.nc

rm -f ${DIRRUN}/PostAtmos_node.${node}.sh
cat << EOSH >> ${DIRRUN}/PostAtmos_node.${node}.sh 
#!/bin/bash
#PBS -N MPASSIT.${node}
#PBS -q ${MPASSIT_QUEUE}
#PBS -l select=1:ncpus=${MPASSIT_ncpus}:mpiprocs=${MPASSIT_ncpn}:ompthreads=${MPASSIT_nthreads}
#PBS -l walltime=${MPASSIT_walltime}
#PBS -o ${DIRRUN/lustre/p}/
#PBS -e ${DIRRUN/lustre/p}/
#PBS -l place=scatter:excl
#PBS -V


cd ${DIRRUN}
. ${SCRIPTS}/setenv.bash
#----------------------------------------------------------------------
# Here some differences that must be loaded just for MPASSIT install/use, 
# in the future, we will put all togheter in one setenv.bash, 
# but for now need to load them here:
#
# Compiladores Cray
export CMAKE_C_COMPILER=cc
export CMAKE_Fortran_COMPILER=ftn
# Load modules
module purge
module load PrgEnv-gnu
module load craype-x86-turin
module load cray-hdf5-parallel/1.14.3.3
module load cray-netcdf-hdf5parallel/4.9.0.15
module load cray-parallel-netcdf/1.12.3.15
module load xpmem/0.2.119-1.3_gef379be13330
module load cray-pals
module load esmf/8.9.1-gcc13
module load METIS/5.1.0
module load grads

# NetCDF paralelo - NETCDF_DIR eh definido pelo modulo cray-netcdf-hdf5parallel
export NETCDF=${NETCDF_DIR}
export LD_LIBRARY_PATH=${NETCDF_DIR}/lib:${LD_LIBRARY_PATH}
# ESMF compilado com NetCDF paralelo NA JACI:
export ESMF_INCDIR=${ESMF_DIR}/include
export ESMF_LIBDIR=${ESMF_DIR}/lib/libO/Unicos.gfortran.64.mpi.default
export ESMF_MODDIR=${ESMF_DIR}/mod/modO/Unicos.gfortran.64.mpi.default
export LIBRARY_PATH=${LIBRARY_PATH}:${ESMF_LIBDIR}
export PATH=${PATH}:${ESMF_DIR}/bin/binO/Unicos.gfortran.64.mpi.default
export ESMF_FFLAGS="-I${ESMF_MODDIR} -I${ESMF_INCDIR}"
export ESMF_LDFLAGS="-L${ESMF_LIBDIR} -lesmf"
export ESMF_COMPILER="gfortran"
export ESMF_F90COMPILER=ftn
export ESMF_CXXCOMPILER=CC
export ESMF_CCCOMPILER=cc
export ESMF_F90LINKER=ftn
# Confirma que NETCDF_DIR aponta para o paralelo
echo "NETCDF_DIR = ${NETCDF_DIR}"
echo -n "NETCDF_DIR paralelo? "
nc-config --has-parallel4
#----------------------------------------------------------------------

chmod 755 ${DIRRUN}/*

# Making template:

cd ${DIRRUN}
chmod 755 ${DATAOUT}/${YYYYMMDDHHi}/Post/*




rm -fr ${DIRRUN}/qctlinfo.gs
cat > ${DIRRUN}/qctlinfo.gs <<EOGS
'reinit'
'sdfopen ${DATAOUT}/${YYYYMMDDHHi}/Post/${diag_name_post}' 
'q ctlinfo'
say result
'quit'
EOGS

grads -blc "run ${DIRRUN}/qctlinfo.gs" | awk '/dset/,/endvars/' > ${DIRRUN}/qctlinfo.ctl
chmod 755 ${DIRRUN}/qctlinfo.ctl
timectl=\$(grep tdef ${DIRRUN}/qctlinfo.ctl | cut -d" " -f4)
sed -i '3a\options template' ${DIRRUN}/qctlinfo.ctl
sed -i "/tdef/c\tdef ${nfiles} linear \${timectl} ${t_stroutmin}mn" ${DIRRUN}/qctlinfo.ctl
sed -i "/dset/c\dset ^${diag_name_templ}" ${DIRRUN}/qctlinfo.ctl

chmod 755 ${DIRRUN}/*
cp -f ${DIRRUN}/qctlinfo.ctl ${DATAOUT}/${YYYYMMDDHHi}/Post/${diag_name_post}.template.ctl

# Saving important files to the logs directory:
cp -f ${EXECS}/${MPASSITVERSION}/MPASSIT-VERSION.txt ${DATAOUT}/${YYYYMMDDHHi}/Post
cp -f ${EXECS}/${MPASSITVERSION}/MPASSIT-VERSION.txt ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${EXECS}/${MONANVERSION}/MONAN-VERSION.txt     ${DATAOUT}/${YYYYMMDDHHi}/Post/logs/
cp -f ${DIRRUN}/dir.0001/namelist.input              ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${DIRRUN}/dir.0001/varlist_2d                  ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${DIRRUN}/dir.0001/varlist_3d                  ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${DIRRUN}/dir.0001/setenv.bash                 ${DATAOUT}/${YYYYMMDDHHi}/Post/logs

cd ${DIRRUN}/..

EOSH
chmod a+x ${DIRRUN}/PostAtmos_node.${node}.sh
echo -e  "${GREEN}==>${NC} qsub PostAtmos_node.${node}.sh \n"


cd ${DIRRUN}
myjobid=$(qsub -W depend=${dependency} -W block=true ${DIRRUN}/PostAtmos_node.${node}.sh | cut -d '.' -f1)
cp -f ${DIRRUN}/PostAtmos_node.${node}.sh ${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.sh_${myjobid} 
cp -f ${DIRRUN}/${myjobid}.pbs-ha.OU ${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.o_${myjobid}
cp -f ${DIRRUN}/${myjobid}.pbs-ha.ER ${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.e_${myjobid}


node=1
for job_id in "${jobid[@]}"
do
   cp -f ${DIRRUN}/${job_id}.pbs-ha.OU ${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.o_${job_id}
   cp -f ${DIRRUN}/${job_id}.pbs-ha.ER ${DATAOUT}/${YYYYMMDDHHi}/Post/logs/PostAtmos_node.${node}.e_${job_id}
   
   node=$((node+1))
done
cd ${DIRRUN}/..
rm -fr ${DIRRUN}














