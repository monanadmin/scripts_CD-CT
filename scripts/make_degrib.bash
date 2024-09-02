#!/bin/bash 

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
RES=${2};         #RES=1024002
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2024012000
FCST=${4};        #FCST=24
#-------------------------------------------------------


# Local variables--------------------------------------
start_date=${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}:00:00
OPERDIREXP=${OPERDIR}/${EXP}
#-------------------------------------------------------
mkdir -p ${DATAIN}/${YYYYMMDDHHi}
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs

#mkdir -p ${HOME}/local/lib64
#cp -f /usr/lib64/libjasper.so* ${HOME}/local/lib64
#cp -f /usr/lib64/libjpeg.so* ${HOME}/local/lib64
which ungrib.exe | xargs -I {} cp {} ${EXECS}

if [ ! ${DATAIN}/${YYYYMMDDHHi}/gfs.t00z.pgrb2.0p25.f000.${YYYYMMDDHHi}.grib2 ]
then
   echo -e "${RED}==>${NC}Condicao de contorno inexistente !"
   echo -e "${RED}==>${NC}Check ${DATAIN}/${YYYYMMDDHHi} ." 
   exit 1                     
fi

files_needed=("${DATAIN}/fixed/x1.${RES}.static.nc" "${DATAIN}/fixed/Vtable.${EXP}" "${EXECS}/ungrib.exe" "${DATAIN}/${YYYYMMDDHHi}/gfs.t00z.pgrb2.0p25.f000.${YYYYMMDDHHi}.grib2")
for file in "${files_needed[@]}"
do
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done

ln -sf ${DATAIN}/fixed/x1.${RES}.static.nc ${SCRIPTS}
ln -sf ${DATAIN}/fixed/Vtable.${EXP} ${SCRIPTS}/Vtable


#export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${HOME}/local/lib64
#ldd ungrib.exe

cd ${SCRIPTS}
rm -f GRIBFILE.* namelist.wps

sed -e "s,#LABELI#,${start_date},g;s,#PREFIX#,GFS,g" \
	${DATAIN}/namelists/namelist.wps.TEMPLATE > ./namelist.wps

./link_grib.csh ${DATAIN}/${YYYYMMDDHHi}/gfs.t00z.pgrb2.0p25.f000.${YYYYMMDDHHi}.grib2

echo -e  "${GREEN}==>${NC} Executing ungrib ...\n"
date
time mpirun -np 1 ungrib.exe

grep "Successful completion of program ungrib.exe" ${SCRIPTS}/ungrib.log >& /dev/null

if [ $? -ne 0 ]; then
   echo "  BUMMER: Ungrib generation failed for some yet unknown reason."
   echo " "
   tail -10 ${SCRIPTS}/ungrib.log
   echo " "
   exit 21
fi
date

#
# clean up and remove links
#
mv ungrib.log ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/ungrib.${start_date}.log
mv namelist.wps ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/namelist.${start_date}.wps
mv GFS\:${start_date:0:13} ${DATAOUT}/${YYYYMMDDHHi}/Pre

rm -f ${SCRIPTS}/ungrib.exe 
rm -f ${SCRIPTS}/Vtable 
rm -f ${SCRIPTS}/x1.${RES}.static.nc
rm -f ${SCRIPTS}/GRIBFILE.AAA

echo "End of degrib Job"


# EOF0
# chmod a+x ${SCRIPTS}/degrib.bash



files_ungrib=("${EXP}:${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}")
for file in "${files_ungrib[@]}"
do
  if [ ! -s ${DATAOUT}/${YYYYMMDDHHi}/Pre/${file} ] 
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} Degrib fails! At least the file ${file} was not generated at ${DATAIN}/${YYYYMMDDHHi}. \n"
    echo -e  "${RED}==>${NC} Check logs at ${DATAOUT}/logs/debrib.* .\n"
    echo -e  "${RED}==>${NC} Exiting script. \n"
    exit -1
  fi
done

