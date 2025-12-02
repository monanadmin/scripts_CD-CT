#!/bin/bash 
#-----------------------------------------------------------------------------#
# !SCRIPT: pre_processing
#
# !DESCRIPTION:
#     Script to prepare boundary and initials conditions for MONAN model.
#     
#     Performs the following tasks:
# 
#        o Creates topography, land use and static variables
#        o Ungrib GFS data
#        o Interpolates to model the grid
#        o Creates initial and boundary conditions
#        o Creates scripts to run the model and post-processing (CR: to be modified to phase 3 and 4)
#        o Integrates the MONAN model ((CR: to be modified to phase 3)
#        o Post-processing (netcdf for grib2, latlon regrid, crop) (CR: to be modified to phase 4)
#
#-----------------------------------------------------------------------------#

if [ $# -ne 6 -a $# -ne 1 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} EXP_NAME/OP RESOLUTION LABELI FCST"
   echo ""
   echo "EXP_NAME       :: Forcing: GFS, ERA5, or IDEALIZED*, where * corresponds to the idealized test case number following MPAS user guide, section 7.1. Example: IDEALIZED2 ==> test case 2: Jablonowski and Williamson baroclinic wave, with initial perturbation"
   echo "            :: Others options to be added later..."
   echo "RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)"
   echo "                                                                 40962  (120 km)"
   echo "LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100"
   echo "FCST        :: Forecast hours, e.g.: 24 or 36, etc."
   echo ""
   echo "24 hour forecast example for 24km:"
   echo "${0} GFS 1024002 2024010100 24"
   echo "48 hour forecast example for 120km:"
   echo "${0} GFS   40962 2024010100 48"
   echo ""

   exit
fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash



# Standard directories variables:---------------------------------------
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
MESH=${2};         #MESH=lat_40_lon_-8_oradius_300_iradius_100_margin_200_hres_3_lres_30.region
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2024012000
FCST=${4};        #FCST=24
REGIONAL=${5}     #REGIONAL=Y
LBCINT=${6}       #LBCINT=3600
#-------------------------------------------------------


# Local variables--------------------------------------
# Calculating CIs and final forecast dates in model namelist format:
yyyymmddi=${YYYYMMDDHHi:0:8}
hhi=${YYYYMMDDHHi:8:2}
yyyymmddhhf=$(date +"%Y%m%d%H" -d "${yyyymmddi} ${hhi}:00 ${FCST} hours" )
final_date=${yyyymmddhhf:0:4}-${yyyymmddhhf:4:2}-${yyyymmddhhf:6:2}_${yyyymmddhhf:8:2}.00.00
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#-------------------------------------------------------


echo -e  "${GREEN}==>${NC} Scripts_CD-CT last commit: \n"
#git log -1 --name-only
git log | head -1


# Untar the fixed files:
# x1.${RES}.graph.info.part.<Ncores> files can be found in datain/fixed
# *.TBL files also can be found in datain/fixed
# x1.${RES}.grid.nc also can be found in datain/fixed

echo -e  "${GREEN}==>${NC} copying and linking fixed input data... \n"
mkdir -p ${DATAIN}
rsync -rv --chmod=ugo=rw ${DIRDADOS}/MONAN_datain/datain/fixed ${DATAIN}
rsync -rv --chmod=ugo=rwx ${DIRDADOS}/MONAN_datain/execs ${DIRHOMED}
ln -sf ${DIRDADOS}/MONAN_datain/datain/WPS_GEOG ${DATAIN}

if [[ $EXP == "GFS" || $EXP == "ERA5" ]]; then
# Creating the x1.${RES}.static.nc file once, if does not exist yet:---------------
   if [ ! -s ${DATAIN}/fixed/${MESH}.static.nc ]
   then
      echo -e "${GREEN}==>${NC} Creating static.bash for submiting init_atmosphere to create ${MESH}.static.nc...\n"
      time ./make_static.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST}
   else
      echo -e "${GREEN}==>${NC} File ${MESH}.static.nc already exist in ${DATAIN}/fixed.\n"
   fi
#----------------------------------------------------------------------------------
elif [[ $EXP == IDEALIZED* ]]; then
   echo -e "${GREEN}==>${NC} Idealized case selected. No need for creating a static file.\n"
else
   echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
   echo -e  "${RED}==>${NC} Static phase fails! Please select EXP=GFS, EXP=ERA5 or EXP=IDEALIZED*.\n"
   echo -e  "${RED}==>${NC} Exiting script. \n"
   exit -1
fi

# Degrib phase:---------------------------------------------------------------------
if [[ ${EXP} == "GFS" ]]
then
   echo -e  "${GREEN}==>${NC} Submitting Degrib for GFS data...\n"
   time ./make_degrib_GFS.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${REGIONAL}
elif [[ ${EXP} == "ERA5" ]]
then
   echo -e  "${GREEN}==>${NC} Submitting Degrib for ERA5 data...\n"
   time ./make_degrib_ERA5.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${REGIONAL}
elif [[ ${EXP} == IDEALIZED* ]]
then
   echo -e "${GREEN}==>${NC} Idealized case selected. No need for degrib.\n"
else
   echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
   echo -e  "${RED}==>${NC} Degrib phase fails! Please select EXP=GFS, EXP=ERA5 or EXP=IDEALIZED*.\n"
   echo -e  "${RED}==>${NC} Exiting script. \n"
   exit -1
fi
#----------------------------------------------------------------------------------


# Init Atmosphere phase:------------------------------------------------------------
if [[ $EXP == "GFS" || $EXP == "ERA5" ]]; then   
   echo -e  "${GREEN}==>${NC} Submitting Init Atmosphere for real case...\n"
   time ./make_initatmos.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${REGIONAL}
elif [[ $EXP == IDEALIZED* ]]; then
   echo -e  "${GREEN}==>${NC} Submitting Init Atmosphere for idealized case...\n"
   time ./make_initatmos_idealized.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST}
else
   echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
   echo -e  "${RED}==>${NC} Init Atmosphere phase fails! Please select EXP=GFS, EXP=ERA5 or EXP=IDEALIZED*.\n"
   echo -e  "${RED}==>${NC} Exiting script. \n"
   exit -1
fi
#----------------------------------------------------------------------------------

# LBCs phase:------------------------------------------------------------
if [[ $REGIONAL == "Y" ]]; then
   echo -e  "${GREEN}==>${NC} Regional simulation: submitting Init Atmosphere to generate lateral boundary conditions...\n"
   time ./make_lbcs.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${LBCINT}
elif [[ $REGIONAL == "N" ]]; then
   echo -e  "${GREEN}==>${NC} Global simulation: no need for lateral boundary conditions.\n"
else
   echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
   echo -e  "${RED}==>${NC} LBCs phase fails! Please select REGIONAL=Y or REGIONAL=N.\n"
   echo -e  "${RED}==>${NC} Exiting script. \n"
   exit -1
fi
#----------------------------------------------------------------------------------
