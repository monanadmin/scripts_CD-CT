#!/bin/bash

case "${HOSTNAME}" in
egeon)
   echo "Load python ..."
   module load python-3.9.13-gcc-9.4.0-moxjnc6
   export PYTHON_EXEC=python3
   export PIP_EXEC=pip3
   ;;
ian)
   echo "Using the system's python ..."
   export PYTHON_EXEC=python3.12
   export PIP_EXEC=pip3.12
   ;;
esac


echo "Define path for python environment"
export PYTHON_ENV_PATH="${DIRHOMES}/.venv"

echo "Define cache for PIP"
export PIP_CACHE_DIR="${DIRHOMES}/.pip-cache"
export PIP_CACHE_CONFIG="${DIRHOMES}/.pip-config"

if [[ ! -s ${PYTHON_ENV_PATH} ]]
then
   echo "Create python environment at ${PYTHON_ENV_PATH}"
   ${PYTHON_EXEC} -m venv ${PYTHON_ENV_PATH}

   echo "Activate python environment"
   source ${PYTHON_ENV_PATH}/bin/activate

   echo "Install python libraries"
   ${PIP_EXEC} install --upgrade pip
   ${PIP_EXEC} install -r ${SCRIPTS}/requirements.txt
else
   echo "Activate python environment"
   source ${PYTHON_ENV_PATH}/bin/activate
fi

export PYTHONPATH=${PYTHONPATH}:${SCRIPTS}
echo "export PYTHONPATH=${PYTHONPATH}"
