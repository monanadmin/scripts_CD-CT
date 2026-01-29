#!/bin/bash
umask 022

#---~----
#   Colors. Please refrain from changing these variables.
#---~----
export GREEN='\033[1;32m'   # Green
export RED='\033[1;31m'     # Red
export NC='\033[0m'         # No Color
export BLUE='\033[01;34m'   # Blue
export ORANGE='\033[01;91m' # Orange
#---~----


#---~----
#   Notify users that this script is being called.
# Please refrain from changing these commands.
#---~----
echo ""
echo -e "${GREEN}==>${NC} Load MONAN settings (setenv.bash).\n"
#---~----


#--- Parse arguments.
USE_ONETWO=false
while [[ ${#} > 0 ]]
do
   key="${1}"
   case ${key} in
   -m12)
      USE_ONETWO=true
      shift 1 # past flag
      ;;
   *)
      echo ""
      echo " Unknown key-value argument pair."
      echo " Usage: "
      echo ""
      echo " . ${BASH_SOURCE[0]} [-m12]"
      echo ""
      echo " List of optional flags: "
      echo ""
      echo " -m12             -- Is this a MONAN run based on 1.2.0-rc and branches"
      echo "                     derived from this version (e.g., feature/monan-757-NF)?"
      echo "                     This is a temporary flag that will be removed once the"
      echo "                     versions containing Noah-MP are merged into the new"
      echo "                     release. This allows the script to manage older code and"
      echo "                     still run on jaci."
      echo ""
      return
      ;;
   esac
done
#---~---


# Choose your compiler here (only on Jaci; on Egeon the compiler is fixed to ‘gnu’):
export COMPILER=intel
#export COMPILER=gnu
#export COMPILER=cray
#export COMPILER=nvidia

# Squeduler detect:
if command -v sbatch &> /dev/null
then
   export SCHEDULER_SYSTEM="SLURM"
   echo "SLURM detected." 
elif command -v qsub &> /dev/null
then
   export SCHEDULER_SYSTEM="PBS"
   echo "PBS detected."
else
   export SCHEDULER_SYSTEM="GENERIC"
   echo "No SCHEDULER detected."
fi

# Detect hostname
THOSTNAME=$(hostname -s)

#---~---
#   Identify which machine is being used based on the host name. Most HPC systems have
# multiple login nodes, but they share a common configuration system. 
#---~---
case ${THOSTNAME} in
egeon-login|headnode|n[0-9]|n[1-2][0-9]|n3[0-3])
   #---~---
   #   Egeon. Use gnu
   #---~---
   export HOSTNAME="egeon"
   export MAKE_TARG=gfortran
   export MAKE_TARG2=gfortran
   COMPILER=gnu
   #---~---
   ;;
ian[0-9]*|cn-0[0-9][0-9][0-9])
   #---~---
   #   Jaci. Decide which compiler to use based on variable COMPILER and the MONAN
   # version we are running.
   #---~---
   export HOSTNAME="ian"
   case "${COMPILER}" in
   intel)
      export MAKE_TARG=intel-xd2000
      export MAKE_TARG2=intel2-xd2000
      ;;
   gnu)
      export MAKE_TARG=gfortran-xd2000
      export MAKE_TARG2=gfortran-xd2000
      ;;
   esac
   #---~---
   ;;
*)
   #---~---
   #   Generic variable, use the hostname and hope for the best.
   #---~---
   export HOSTNAME="${THOSTNAME}"
   ;;
   #---~---
esac
# Make the same for other machines/systems...
echo "Host detected: ${HOSTNAME}"
echo "Compiler to be used: ${COMPILER}"

# Set unique key: scheduler + host:
export SYSTEM_KEY="${SCHEDULER_SYSTEM}_${HOSTNAME}"
export SYSTEM_KEYC="${SCHEDULER_SYSTEM}_${HOSTNAME}_${COMPILER}"


# Set environment variables and importants directories-------------------------------------------------- 


# MONAN-suite install root directories:
# Put your directories:
#ML slightly edited the logic in here, somehow using pwd was leading to errors on Jaci.
export THIS_PATH=`(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)`
export DIR_SCRIPTS=$(dirname $(dirname ${THIS_PATH}))
export DIR_DADOS=${DIR_SCRIPTS}
export MONANDIR=$MONANDIR


# Load your system setenv:
. ${DIR_SCRIPTS}/scripts_CD-CT/scripts/stools/setenv_${SYSTEM_KEYC}.bash

#module list
#echo ""
#read -p "Mostrando modulos carregados - Pressione Enter para continuar.... "
#echo ""


#-----------------------------------------------------------------------
# We discourage changing the variables below:

# Others variables:


#--- Set and create standard directories
export DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT;  mkdir -p ${DIRHOMES}  
export DIRHOMED=${DIR_DADOS}/scripts_CD-CT;    mkdir -p ${DIRHOMED}  
export SCRIPTS=${DIRHOMES}/scripts;            mkdir -p ${SCRIPTS}
export DATAIN=${DIRHOMED}/datain;              mkdir -p ${DATAIN}
export DATAOUT=${DIRHOMED}/dataout;            mkdir -p ${DATAOUT}
export SOURCES=${DIRHOMES}/sources;            mkdir -p ${SOURCES}
export EXECS=${DIRHOMED}/execs;                mkdir -p ${EXECS}

echo -e ""
echo -e "${GREEN}==>${NC}*** List of paths: ***"
echo -e ""
echo -e "${GREEN}==>${NC} DIRHOMES = \"${DIRHOMES}\""
echo -e "${GREEN}==>${NC} DIRHOMED = \"${DIRHOMED}\""
echo -e "${GREEN}==>${NC} SCRIPTS  = \"${SCRIPTS}\""
echo -e "${GREEN}==>${NC} DATAIN   = \"${DATAIN}\""
echo -e "${GREEN}==>${NC} DATAOUT  = \"${DATAOUT}\""
echo -e "${GREEN}==>${NC} SOURCES  = \"${SOURCES}\""
echo -e "${GREEN}==>${NC} EXECS    = \"${EXECS}\""
echo -e ""
#---~---




# Functions: ======================================================================================================

how_many_nodes () { 
   nume=${1}   
   deno=${2}
   num=$(echo "${nume}/${deno}" | bc -l)  
   how_many_nodes_int=$(echo "${num}/1" | bc)
   dif=`echo "scale=0; (${num}-${how_many_nodes_int})*100/1" | bc`
   rest=`echo "scale=0; (((${num}-${how_many_nodes_int})*${deno})+0.5)/1" | bc -l`
   if [[ ${dif} -eq 0 ]]; then how_many_nodes_left=0; else how_many_nodes_left=1; fi
   if [[ ${how_many_nodes_int} -eq 0 ]]; then how_many_nodes_int=1; how_many_nodes_left=0; rest=0; fi
   how_many_nodes=`echo "${how_many_nodes_int}+${how_many_nodes_left}" | bc `
   #echo "INT number of nodes needed: \${how_many_nodes_int}  = ${how_many_nodes_int}"
   #echo "number of nodes left:       \${how_many_nodes_left} = ${how_many_nodes_left}"
   echo "The number of nodes needed: \${how_many_nodes}  = ${how_many_nodes}"
   echo ""
}
#----------------------------------------------------------------------------------------------


