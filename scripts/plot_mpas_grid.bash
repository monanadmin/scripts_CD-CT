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
## Grid file
GFILEPATH=${DATAIN}/fixed/lat_50_lon_-30_oradius_2800_iradius_2000_margin_800_hres_48_lres_240.region.grid.nc
## Output directory and filename to save plot
POSTFILEPATH=${DATAIN}/fixed/lat_50_lon_-30_oradius_2800_iradius_2000_margin_800_hres_48_lres_240.region.grid.png
#---------------------------------------------------------------------

source ~/.bashrc
conda activate vtx_env
python3 ${SOURCES}/CGFD-USP-Post-Proc/mpas_plot_grid.py -g $GFILEPATH -o $POSTFILEPATH
