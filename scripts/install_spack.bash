#!/bin/bash

export SPACK_GIT=$(pwd)/spack
export SPACK_ENV=${HOME}/.spack/spack

GREEN='\033[1;32m'       # Green
NC='\033[0m' # No Color

cd $(pwd)
echo -e  "${GREEN}==>${NC} git clone  https://github.com/spack/spack.git $SPACK_GIT\n"
git clone https://github.com/spack/spack.git $SPACK_GIT
cd $SPACK_GIT
echo -e "${GREEN}==>${NC} git checkout tags/v0.22.1 -b branch_v0.22.1"
git checkout tags/v0.22.1 -b branch_v0.22.1

echo -e "${GREEN}==>${NC} creating env.sh"
mkdir -p $SPACK_ENV/tmp

cat << EOF > $SPACK_GIT/env.sh
#!/bin/bash

. $SPACK_GIT/share/spack/setup-env.sh

export SPACK_USER_CONFIG_PATH=$SPACK_ENV
export SPACK_USER_CACHE_PATH=$SPACK_ENV/tmp
export TMP=$SPACK_ENV/tmp
export TMPDIR=$SPACK_ENV/tmp
mkdir -p $SPACK_ENV/tmp
EOF

chmod a+x $SPACK_GIT/env.sh

echo -e "${GREEN}==>${NC} Spack sucessfully installed at $SPACK_GIT"


