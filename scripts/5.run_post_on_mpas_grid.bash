#!/bin/bash
#-----------------------------------------------------------------------------#
# !SCRIPT: run_post_on_mpas_grid
#
# !DESCRIPTION:
#     Script to run the postprocessing of MONAN model using the original MPAS grid.
#
#-----------------------------------------------------------------------------#


# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash



# Standart directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT; mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_CD-CT;   mkdir -p ${DIRHOMED}  
export SCRIPTS=${DIRHOMES}/scripts;    mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;             mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;           mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;           mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;               mkdir -p ${EXECS}
#----------------------------------------------------------------------

# Local variables------------------------------------------------------
## Variable to plot
VAR=vorticity
# Minimum and maximum values of variable for colorbar
V_MIN=-0.000125
V_MAX=0.000125
# Input file from which variable should be extracted
FILENAME=MONAN_HIST_G_MOD_IDEALIZED2_2025111800_2025120100.00.00.lat_50_lon_-30_oradius_2800_iradius_2000_margin_800_hres_48_lres_240.globalL55
FILEPATH=${DATAOUT}/2025111800/Model/${FILENAME}.nc
# File from which grid characteristics should be extracted
GFILEPATH=${DATAOUT}/2025111800/Pre/lat_50_lon_-30_oradius_2800_iradius_2000_margin_800_hres_48_lres_240.global.init.nc
# Output directory and filename to save plot
POSTFILEDIR=${DATAOUT}/2025111800/Post
POSTFILEPATH=${POSTFILEDIR}/${VAR}_${FILENAME}.png
#---------------------------------------------------------------------

if [ ! -d "${POSTFILEDIR}" ]; then
  mkdir "${POSTFILEDIR}"
fi

source ~/.bashrc
conda activate vtx_env

if [[ $LAT_MIN == "" ]]; then
   if [[ $V_MIN == "" ]]; then
      python3 ${SOURCES}/CGFD-USP-Post-Proc/mpas_plot.py -f $FILEPATH -gf $GFILEPATH -v $VAR -o $POSTFILEPATH
   else
      python3 ${SOURCES}/CGFD-USP-Post-Proc/mpas_plot.py -f $FILEPATH -gf $GFILEPATH -vmin $V_MIN -vmax $V_MAX -v $VAR -o $POSTFILEPATH
   fi
else
   python3 ${SOURCES}/CGFD-USP-Post-Proc/mpas_plot.py -f $FILEPATH -gf $GFILEPATH -vmin $V_MIN -vmax $V_MAX -v $VAR -lat_min $LAT_MIN -lat_max $LAT_MAX -lon_min $LON_MIN -lon_max $LON_MAX -o $POSTFILEPATH
fi
