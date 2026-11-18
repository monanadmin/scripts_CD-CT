#!/bin/bash
umask 022

# Choose the simulation mode:
export MODERUN=G     # R=Regional simulation and G=Global simulation.
export LBCINT=10800  # Interval (seconds) for updating lateral boundary conditions (when regional mode).

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

# Identifying several names of the egeon:
case ${THOSTNAME} in
   egeon-login|headnode|n[0-9]|n[1-2][0-9]|n3[0-3])
      export HOSTNAME="egeon"
      export MAKE_TARG=gfortran
      export MAKE_TARG2=gfortran
      COMPILER=gnu
      ;;
   ian[0-9]*|cn-0[0-9][0-9][0-9])
      export HOSTNAME="ian"
      if [ "$COMPILER" == "intel" ]; then
         export MAKE_TARG=intel-xd2000
         export MAKE_TARG2=intel2-xd2000
      elif [ "$COMPILER" == "gnu" ]; then
         export MAKE_TARG=gfortran-xd2000
         export MAKE_TARG2=gfortran-xd2000
      elif [ "$COMPILER" == "cray" ]; then
         export MAKE_TARG=cray-xd2000
         export MAKE_TARG2=cray-xd2000
      elif [ "$COMPILER" == "nvidia" ]; then
         export MAKE_TARG=nvhpc-xd2000
         export MAKE_TARG2=nvhpc-xd2000
      fi
      ;;
esac
# Make the same for other machines/systems...
echo "Host detected: $HOSTNAME"
echo "Compiler to be used: ${COMPILER}"

# Set unique key: scheduler + host:
export SYSTEM_KEY="${SCHEDULER_SYSTEM}_${HOSTNAME}"
export SYSTEM_KEYC="${SCHEDULER_SYSTEM}_${HOSTNAME}_${COMPILER}"


# Set environment variables and importants directories-------------------------------------------------- 


# MONAN-suite install root directories:
# Put your directories:
export DIR_SCRIPTS=$(dirname $(dirname $(pwd)))
export DIR_DADOS=${DIR_SCRIPTS}
export MONANDIR=/p/projetos/monan_adm/carlos.souza/issues/179-GTA-MPASSIT-into-CDCT/scripts_CD-CT/sources/MONAN-Model_2.0.0-rc
export CONVERT_MPAS_DIR=/p/projetos/monan_adm/carlos.souza/issues/179-GTA-MPASSIT-into-CDCT/scripts_CD-CT/sources/convert_mpas_1.2.0
export MPASSIT_DIR=/p/projetos/monan_adm/carlos.souza/issues/179-GTA-MPASSIT-into-CDCT/scripts_CD-CT/sources/MPASSIT_develop
export myDIR=$(basename $(dirname $(pwd)))

# Workaround for 'module purge' failing with 'set -e' when Conda aliases are undefined.
alias start_conda=: stop_conda=:

# Load your system setenv:
. ${DIR_SCRIPTS}/${myDIR}/scripts/stools/setenv_${SYSTEM_KEYC}.bash

#-----------------------------------------------------------------------
# We discourage changing the variables below:



# Others variables:
if [ -f ${MONANDIR}/VERSION.txt ]
then
   export MONANVERSION=$(cat ${MONANDIR}/VERSION.txt)
fi
if [ -f ${CONVERT_MPAS_DIR}/VERSION.txt ]
then
   export CONVERTVERSION=CONV.$(head -n 1 ${CONVERT_MPAS_DIR}/VERSION.txt)
fi
if [ -f ${MPASSIT_DIR}/VERSION.txt ]
then
   export MPASSITVERSION=MPASSIT.$(head -n 1 ${MPASSIT_DIR}/VERSION.txt)
fi

# Colors:
#
export GREEN='\033[1;32m'  # Green
export RED='\033[1;31m'    # Red
export NC='\033[0m'        # No Color
export BLUE='\033[01;34m'  # Blue
export YELLOW='\033[1;33m' # Yellow

# Functions: ======================================================================================================

how_many_nodes () { 
   nume=${1}   
   deno=${2}
   num=$(echo "${nume}/${deno}" | bc -l)  
   how_many_nodes_int=$(echo "${num}/1" | bc)
   dif=$(echo "scale=0; (${num}-${how_many_nodes_int})*100/1" | bc)
   rest=$(echo "scale=0; (((${num}-${how_many_nodes_int})*${deno})+0.5)/1" | bc -l)
   if [ ${dif} -eq 0 ]; then how_many_nodes_left=0; else how_many_nodes_left=1; fi
   if [ ${how_many_nodes_int} -eq 0 ]; then how_many_nodes_int=1; how_many_nodes_left=0; rest=0; fi
   how_many_nodes=$(echo "${how_many_nodes_int}+${how_many_nodes_left}" | bc )
   #echo "INT number of nodes needed: \${how_many_nodes_int}  = ${how_many_nodes_int}"
   #echo "number of nodes left:       \${how_many_nodes_left} = ${how_many_nodes_left}"
   echo "The number of nodes needed: \${how_many_nodes}  = ${how_many_nodes}"
   echo ""
}
#----------------------------------------------------------------------------------------------




core_distribution() {
   # Gera a distribuicao de cores por execucao
   # $1 = total de cores do no
   # $2 = numero de cores por execucao
   
   local total_cores=$1
   local cores_per_exec=$2

   if (( total_cores % cores_per_exec != 0 )); then
      echo "ERRO: total_cores (${total_cores}) nao eh divisivel por cores_per_exec (${cores_per_exec})" >&2
      return 1
   fi

   local nexec=$(( total_cores / cores_per_exec ))

   for (( slot=0; slot<nexec; slot++ )); do
      start=$(( slot * cores_per_exec ))
      end=$(( start + cores_per_exec - 1 ))
      echo "${start} ${end}"
   done
}



#----------------------------------------------------------------------------------------------


