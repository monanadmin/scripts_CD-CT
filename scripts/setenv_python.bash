#!/bin/bash

case "${HOSTNAME}" in
egeon)
   echo "Load python ..."
   module load python-3.9.13-gcc-9.4.0-moxjnc6 
   ;;
ian)
   echo "Load python ..."
   module load anaconda/24.1.2 
   ;;
esac


echo "Define path for python environment"
export PYTHON_ENV_PATH="${DIRHOMES}/.venv"


echo "Create python environment at ${PYTHON_ENV_PATH}"
python3 -m venv ${PYTHON_ENV_PATH}

echo "Activate python environment"
source ${PYTHON_ENV_PATH}/bin/activate

echo "Install python libraries"
pip install --upgrade pip
pip install -r ${SCRIPTS}/requirements.txt

export PYTHONPATH=${PYTHONPATH}:${SCRIPTS}
echo "export PYTHONPATH=${PYTHONPATH}"
