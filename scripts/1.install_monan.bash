#!/bin/bash 
umask 022

#-----------------------------------------------------------------------------#
# !SCRIPT: install_monan
#
# !DESCRIPTION:
#     Script to install the MONAN model and convert_MPAS.
#     
#     Performs the following tasks:
# 
#        o Clone the Monan model github repository in a local directory
#        o Make the script make-all.sh that compiles the Atmosphere Model and the Init Atmosphere Model
#        o As alternative for advanced users, this script creates a simple compile script that just compile the Atmosphere Model
#        o Clone the Convert_mpas tool from the monanadmin repository for convert the output model files in lat-lon grid.
#        o Compile the convert_mpas
#
#-----------------------------------------------------------------------------#


#--- Function that shows usage.
function show_usage() {
   echo " Usage: "
   echo ""
   echo " ${0} [-h] [-m12] [-bc TAG_CONVERT_MPAS] [-bm TAG_MONAN] [-gm GIT_MONAN] \\"
   echo "    [-gc GIT_CONVERT_MPAS]"
   echo ""
   echo " List of optional flags: "
   echo ""
   echo " -h              -- Shows this message."
   echo " -m12            -- Is this a MONAN run based on 1.2.0-rc and branches derived"
   echo "                    from this version (e.g., feature/monan-757-NF)? This is a"
   echo "                    temporary flag that will be removed once the versions"
   echo "                    containing Noah-MP are merged into the new release. This"
   echo "                    allows the script to manage older code and still run on jaci."
   echo ""
   echo " List of **required** flags: "
   echo ""
   echo " -bc TAG_CONVERT -- branch or tag name of the MONAN repository. For example:"
   echo "                    \"develop\"."
   echo " -bm TAG_MONAN   -- branch or tag name of the MONAN repository. For example:"
   echo "                    \"develop\"."
   echo " -gc GIT_CONVERT -- GitHub handle for MONAN. For example:"
   echo "                    https://github.com/monanadmin/MONAN-Model.git"
   echo " -gm GIT_MONAN   -- GitHub handle for MONAN. For example:"
   echo "                    https://github.com/monanadmin/MONAN-Model.git"
   echo ""
}
#---~---




#Functions -------------------------------------------------------------------#
function checkout_system() {
  local source_dir=$1
  local github_link=$2
  local tag_or_branch_name=$3
  if [[ -d "${source_dir}" ]]; then
      echo -e  "${GREEN}==>${NC} Source dir already exists, updating it ...\n"
  else
      echo -e  "${GREEN}==>${NC} Cloning your fork repository...\n"
      git clone ${github_link} ${source_dir}
      if [[ ! -d "${source_dir}" ]]; then
          echo -e "${RED}==>${NC} An error occurred while cloning your fork. Possible causes:  wrong URL, user or password.\n"
          exit -1
      fi
  fi

  cd ${source_dir}
  if git checkout "${tag_or_branch_name}" 2>/dev/null; then
      git pull
      echo -e "${GREEN}==>${NC} Successfully checked out and updated: ${BLUE}${tag_or_branch_name}"
  else
      echo -e "${RED}==>${NC} Failed to check out branch: ${BLUE}${tag_or_branch_name}"
      echo -e "${RED}==>${NC} Please check if you have this branch. Exiting ..."
      exit -1
  fi
  git log | head -1
}
#-----------------------------------------------------------------------------#


#---~---
#   Retrieve configuration.
#---~---
#--- Default settings (all empty)
MONAN_ONETWO=""
github_link_MONAN=""
tag_or_branch_name_MONAN=""
github_link_CONVERT_MPAS=""
tag_or_branch_name_CONVERT_MPAS=""
#---~---


#---~---
#   Parse arguments
#---~---
while [[ ${#} > 0 ]]
do
   key="${1}"
   case ${key} in
   -bc)
      tag_or_branch_name_CONVERT_MPAS="${2}"
      shift 2 # past flag and argument
      ;;
   -bm)
      tag_or_branch_name_MONAN="${2}"
      shift 2 # past flag and argument
      ;;
   -gc)
      github_link_CONVERT_MPAS="${2}"
      shift 2 # past flag and argument
      ;;
   -gm)
      github_link_MONAN="${2}"
      shift 2 # past flag and argument
      ;;
   -h)
      show_usage
      exit 0
      ;;
   -m12)
      MONAN_ONETWO="${key}"
      shift 1 # past flag
      ;;
   *)
      echo ""
      echo " Option \"${key}\" is not valid."
      echo ""
      show_usage
      echo ""
      echo " *** FATAL ERROR! ***"
      echo " Unknown key or key-value argument pair."
      echo ""
      exit 2
      ;;
   esac
done
#---~---

#---~---
#   Make sure all required settings were provided.
#---~---
if [[ "${tag_or_branch_name_CONVERT_MPAS}" == "" ]] ||
   [[ "${tag_or_branch_name_MONAN}"        == "" ]] ||
   [[ "${github_link_CONVERT_MPAS}"        == "" ]] ||
   [[ "${github_link_MONAN}"               == "" ]]
then
   echo " This script requires arguments to be set through flags."
   show_usage
   exit 2
fi
#---~---


#--- Set environment variables exports:
. setenv.bash ${MONAN_ONETWO}
#---~---

echo ""
echo "---- Installing the Model ----"
echo ""


#--- Set and create standard directories
DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT;  mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_CD-CT;    mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;            mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;              mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;            mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;            mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;                mkdir -p ${EXECS}
#----------------------------------------------------------------------


# Input variables:-----------------------------------------------------
tag_or_branch_name_MONAN=${tag_or_branch_name_MONAN:="release/1.4.3-rc"}
tag_or_branch_name_CONVERT_MPAS=${tag_or_branch_name_CONVERT_MPAS:="release/1.2.0"}
echo "convert_mpas branch name in use: ${tag_or_branch_name_CONVERT_MPAS}"
#----------------------------------------------------------------------


# Local variables:-----------------------------------------------------
MONANDIR=${SOURCES}/MONAN-Model_${tag_or_branch_name_MONAN}
CONVERT_MPAS_DIR=${SOURCES}/convert_mpas_${tag_or_branch_name_CONVERT_MPAS}

#$(sed -i "s;DIR_SCRIPTS=.*$;DIR_SCRIPTS=$(dirname $(dirname $(pwd)));" setenv.bash)
#$(sed -i "s;DIR_DADOS=.*$;DIR_DADOS=$(dirname $(dirname $(pwd)));" setenv.bash)
$(sed -i "s;MONANDIR=.*$;MONANDIR=$MONANDIR;" setenv.bash)
chmod 755 ${SCRIPTS}/setenv.bash
. ${SCRIPTS}/setenv.bash ${MONAN_ONETWO}

#----------------------------------------------------------------------

#=====================================================================================
#
# ATTENTION, please:
# 
# scripts_CD-CT versions up to 1.1.0 run MONAN-Model versions up to 1.3.0
#
# scripts_CD-CT versions 1.2.0 onwards run MONAN-Model versions 1.3.1 onwards
#
#=====================================================================================

# Just making sure you will install the correct MONAN-model version,
#  for this version of scripts-CD-CT version:

echo ""
echo "********************************************************************************"
echo "*"
echo "* ATTENTION, please:"
echo "*"
echo "* scripts_CD-CT versions up to 1.1.0 run MONAN-Model only versions up to 1.3.0"
echo "*"
echo "* scripts_CD-CT versions 1.2.0 onwards run MONAN-Model only versions 1.3.1 onwards"
echo "*"
echo "********************************************************************************"

echo ""
echo -e "${GREEN}==>${NC} github_link_MONAN        = ${github_link_MONAN}"
echo -e "${GREEN}==>${NC} tag_or_branch_name_MONAN = ${tag_or_branch_name_MONAN}"
echo ""
read -p "Are you sure you are installing the right versions scripts x MONAN-Model ? [Y/n]" confirma
confirma=$(echo ${confirma:-Y} | tr [:upper:] [:lower:])
case "${confirma}" in
y|yes)
   echo ""
   echo -e "${GREEN}==>${NC} OK, proceeding to installation."
   echo ""
   ;;
*)
   echo ""
   echo -e "    ${RED}==>${NC} Please, make the right versions and try again."
   exit
   echo ""
esac


checkout_system ${MONANDIR} ${github_link_MONAN} ${tag_or_branch_name_MONAN}
checkout_system ${CONVERT_MPAS_DIR} ${github_link_CONVERT_MPAS} ${tag_or_branch_name_CONVERT_MPAS}

rm -rf $MONANDIR/default_inputs/ $MONANDIR/src/core_atmosphere/physics/physics_wrf/files
rm -f  $MONANDIR/stream_list.* $MONANDIR/streams.* $MONANDIR/namelist.* 
rm -f  $MONANDIR/make*.output.atmosphere $MONANDIR/make*.output.init_atmosphere $MONANDIR/make-all.sh
rm -fr $MONANDIR/src/core_atmosphere/inc $MONANDIR/src/core_init_atmosphere/inc


#CR: TODO: maybe later move this make script to main scripts directory.
echo ""
echo -e  "${GREEN}==>${NC} Making compile script...\n"

cd $MONANDIR
cat << EOF > make-all.sh
#!/bin/bash
#Usage: make target CORE=[core] [options]
#Example targets:
#    ifort
#    gfortran
#    xlf
#    pgi
#    intel-xd2000 :: cptec/inpe ian xd2000
#Availabe Cores:
#    atmosphere
#    init_atmosphere
#    landice
#    ocean
#    seaice
#    sw
#    test
#Available Options:
#    DEBUG=true    - builds debug version. Default is optimized version.
#    USE_PAPI=true - builds version using PAPI for timers. Default is off.
#    TAU=true      - builds version using TAU hooks for profiling. Default is off.
#    AUTOCLEAN=true    - forces a clean of infrastructure prior to build new core.
#    GEN_F90=true  - Generates intermediate .f90 files through CPP, and builds with them.
#    TIMER_LIB=opt - Selects the timer library interface to be used for profiling the model. Options are:
#                    TIMER_LIB=native - Uses native built-in timers in MPAS
#                    TIMER_LIB=gptl - Uses gptl for the timer interface instead of the native interface
#                    TIMER_LIB=tau - Uses TAU for the timer interface instead of the native interface
#    OPENMP=true   - builds and links with OpenMP flags. Default is to not use OpenMP.
#    OPENACC=true  - builds and links with OpenACC flags. Default is to not use OpenACC.
#    USE_PIO2=true - links with the PIO 2 library. Default is to use the PIO 1.x library.
#    PRECISION=single - builds with default single-precision real kind. Default is to use double-precision.
#    SHAREDLIB=true - generate position-independent code suitable for use in a shared library. Default is false.

cd ${SCRIPTS}
. ${SCRIPTS}/setenv.bash ${MONAN_ONETWO}
cd $MONANDIR

rm -rf $MONANDIR/default_inputs/ $MONANDIR/src/core_atmosphere/physics/physics_wrf/files
rm -f  $MONANDIR/stream_list.* $MONANDIR/streams.* $MONANDIR/namelist.* 
rm -f  $MONANDIR/make*.output.atmosphere $MONANDIR/make*.output.init_atmosphere 
rm -fr $MONANDIR/src/core_atmosphere/inc $MONANDIR/src/core_init_atmosphere/inc
DATE_TIME_NOW=\$(date +"%Y%m%d%H%M%S")

export NETCDF=\${NETCDFDIR}
export PNETCDF=\${PNETCDFDIR}
# PIO is not necessary for version 8.* If PIO is empty, MPAS Will use SMIOL
#export PIO=\${PIODIR}
export PIO=

MAKE_OUT_FILE="make_\${DATE_TIME_NOW}_.output.atmosphere"

make clean CORE=atmosphere
make -j 8 ${MAKE_TARG} CORE=atmosphere OPENMP=true USE_PIO2=false PRECISION=single 2>&1 | tee \${MAKE_OUT_FILE}
#make -j 8 ${MAKE_TARG} CORE=atmosphere OPENMP=true USE_PIO2=true PRECISION=single 2>&1 | tee \${MAKE_OUT_FILE}

#make -j 8 intel-xd2000 CORE=atmosphere OPENMP=true USE_PIO2=false PRECISION=single OPTIMIZATION_LEVEL=O1 FFLAGS_OPT=-O1 CFLAGS_OPT=-O1 CXXFLAGS_OPT=-O1 2>&1 | tee \${MAKE_OUT_FILE}


#CR: TODO: put verify here if executable was created ok
mv ${MONANDIR}/atmosphere_model ${EXECS}
mv ${MONANDIR}/build_tables ${EXECS}
cp ${MONANDIR}/VERSION.txt ${EXECS}/MONAN-VERSION.txt
cp ${MONANDIR}/GF_ConvPar_nml ${SCRIPTS}
make clean CORE=atmosphere

MAKE_OUT_FILE="make_\${DATE_TIME_NOW}_.output.init_atmosphere"

make clean CORE=init_atmosphere
make -j 8 ${MAKE_TARG2} CORE=init_atmosphere OPENMP=true USE_PIO2=false PRECISION=single 2>&1 | tee \${MAKE_OUT_FILE}
#make -j 8 ${MAKE_TARG2} CORE=init_atmosphere OPENMP=true USE_PIO2=true PRECISION=single 2>&1 | tee \${MAKE_OUT_FILE}

#make -j 8 intel-xd2000 CORE=init_atmosphere OPENMP=true USE_PIO2=false PRECISION=single OPTIMIZATION_LEVEL=O1 FFLAGS_OPT=-O1 CFLAGS_OPT=-O1 CXXFLAGS_OPT=-O1 2>&1 | tee \${MAKE_OUT_FILE}


mv ${MONANDIR}/init_atmosphere_model ${EXECS}
make clean CORE=init_atmosphere


if [[ -s "${EXECS}/init_atmosphere_model" ]] && [[ -e "${EXECS}/atmosphere_model" ]]; then
    echo ""
    echo -e "${GREEN}==>${NC} Files init_atmosphere_model and atmosphere_model generated Successfully in ${EXECS} !"
    echo
else
    echo -e "${RED}==>${NC} !!! An error occurred during build. Check output"
    exit -1
fi

EOF
chmod a+x make-all.sh

echo ""
echo -e  "${GREEN}==>${NC} Installing init_atmosphere_model and atmosphere_model...\n"
echo ""
. ${MONANDIR}/make-all.sh

if [[ "$HOSTNAME" == "ian" ]]; then
#   echo "hostname=$HOSTNAME"
   export PATH=$NETCDF/bin:$PATH
fi

# install convert_mpas
echo ""
echo -e  "${GREEN}==>${NC} Loading modules needed by convert_mpas...\n"

cd ${CONVERT_MPAS_DIR}
make clean
make  2>&1 | tee make.convert.output

#CR: TODO: put verify here if executable was created ok
mv ${CONVERT_MPAS_DIR}/convert_mpas ${EXECS}/
cp ${CONVERT_MPAS_DIR}/VERSION.txt ${EXECS}/CONVMPAS-VERSION.txt


if [[ -s "${EXECS}/convert_mpas" ]] ; then
    echo ""
    echo -e "${GREEN}==>${NC} File convert_mpas generated Sucessfully in ${CONVERT_MPAS_DIR} and copied to ${EXECS} !"
    echo
else
    echo -e "${RED}==>${NC} !!! An error occurred during convert_mpas build. Check output"
    exit -1
fi

