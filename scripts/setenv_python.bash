#!/bin/bash

case "${HOSTNAME}" in
egeon)
   echo "Load python ..."
   module load python-3.9.13-gcc-9.4.0-moxjnc6 
   ;;
esac

echo "scripts folder is set to \"${SCRIPTS}\"."

echo "Create python environment at ${SCRIPTS}/../.venv"
python3 -m venv ${SCRIPTS}/../.venv

echo "Activate python environment"
source ${SCRIPTS}/../.venv/bin/activate

echo "Install python libraries"
pip install --upgrade pip
pip install -r ${SCRIPTS}/requirements.txt

export PYTHONPATH=${PYTHONPATH}:${SCRIPTS}
echo "export PYTHONPATH=${PYTHONPATH}"
