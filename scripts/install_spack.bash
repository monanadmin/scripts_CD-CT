#!/bin/bash

if [ $# -ne 1 ]
then
   echo ""
   echo "${0} dir_spack_name"
   echo ""
   exit
fi


export SPACK_NAME=${1}
export SPACK_GIT=$(pwd)
export SPACK_ENV=${HOME}/.spack/${SPACK_NAME}

GREEN='\033[1;32m'       # Green
NC='\033[0m' # No Color

cd $SPACK_GIT
echo -e  "${GREEN}==>${NC} git clone  https://github.com/spack/spack.git $SPACK_NAME\n"
git clone https://github.com/spack/spack.git $SPACK_NAME
cd $SPACK_NAME
echo -e "${GREEN}==>${NC} git checkout tags/v0.18.1 -b branch_v0.18.1"
git checkout tags/v0.18.1 -b branch_v0.18.1

echo -e "${GREEN}==>${NC} criando env.sh"
mkdir -p $SPACK_ENV/tmp

cat << EOF > $SPACK_GIT/${SPACK_NAME}/env.sh
#!/bin/bash

. $SPACK_GIT/${SPACK_NAME}/share/spack/setup-env.sh

export SPACK_USER_CONFIG_PATH=$SPACK_ENV
export SPACK_USER_CACHE_PATH=$SPACK_ENV/tmp
export TMP=$SPACK_ENV/tmp
export TMPDIR=$SPACK_ENV/tmp
mkdir -p $SPACK_ENV/tmp
EOF

chmod a+x $SPACK_GIT/${SPACK_NAME}/env.sh
