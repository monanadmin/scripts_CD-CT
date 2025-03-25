echo "loading module python ..."
#module load python-3.9.13-gcc-9.4.0-moxjnc6 

echo "scripts folder setted=${SCRIPTS}"

echo "creating python environment at ${SCRIPTS}/../.venv"
python3 -m venv ${SCRIPTS}/../.venv

echo "activating python environment"
source ${SCRIPTS}/../.venv/bin/activate

echo "Installing python libraries"
pip install --upgrade pip
pip install -r ${SCRIPTS}/requirements.txt

export PYTHONPATH=${PYTHONPATH}:${SCRIPTS}
echo "exporting PYTHONPATH=${PYTHONPATH}"
