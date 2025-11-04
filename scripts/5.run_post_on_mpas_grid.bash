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
VAR=surface_pressure
## Latitude and longitude min/max values to plot
LAT_MIN=-60
LAT_MAX=-15
LON_MIN=-65
LON_MAX=-20
# Minimum and maximum values of variable for colorbar
V_MIN=90000
V_MAX=103000
# Input file from which variable should be extracted
FILENAME=MONAN_DIAG_G_MOD_ERA5_2007062200_2007062400.00.00.lat_-35_lon_-55_oradius_2600_iradius_2000_margin_600_hres_50_lres_250.regionL55
FILEPATH=${DATAOUT}/2007062200/Model/${FILENAME}.nc
# File from which grid characteristics should be extracted
GFILEPATH=${DATAOUT}/2007062200/Pre/lat_-35_lon_-55_oradius_2600_iradius_2000_margin_600_hres_50_lres_250.region.init.nc
# Output directory and filename to save plot
POSTFILEDIR=${DATAOUT}/2007062200/Post
POSTFILEPATH=${POSTFILEDIR}/${VAR}_${FILENAME}.png
#---------------------------------------------------------------------

if [ ! -d "${POSTFILEDIR}" ]; then
  mkdir "${POSTFILEDIR}"
fi

CONDA_PATH="$(conda info --root)"
source "$CONDA_PATH/etc/profile.d/conda.sh"
conda activate vtx_env
python3 ${SOURCES}/CGFD-USP-Post-Proc/mpas_plot.py -f $FILEPATH -gf $GFILEPATH -vmin $V_MIN -vmax $V_MAX -v $VAR -lat_min $LAT_MIN -lat_max $LAT_MAX -lon_min $LON_MIN -lon_max $LON_MAX -o $POSTFILEPATH
