module load python-3.9.13-gcc-9.4.0-moxjnc6 
echo "scripts=${SCRIPTS}"
python3 -m venv ${SCRIPTS}/../.venv
source ${SCRIPTS}/../.venv/bin/activate
pip install --upgrade pip
pip install netCDF4
export PYTHONPATH=${PYTHONPATH}:${SCRIPTS}
