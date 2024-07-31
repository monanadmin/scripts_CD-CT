#!/bin/bash -l
set -m

echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"

. setenv.bash

# Input variables:-----------------------------------------------------
github_link=https://github.com/monanadmin/MONAN-Model.git
EXP=GFS
RES=1024002
YYYYMMDDHHi=$(date "+%Y%m%d")"00"
FCST=240
#----------------------------------------------------------------------

# Standart directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT;
DIRHOMED=${DIR_DADOS}/scripts_CD-CT;
SCRIPTS=${DIRHOMES}/scripts;
DATAIN=${DIRHOMED}/datain;
DATAOUT=${DIRHOMED}/dataout;
SOURCES=${DIRHOMES}/sources;
EXECS=${DIRHOMED}/execs;
datereg=$(date "+%Y%m%d-%H%M")
logfile=${DATAOUT}/cron/cron-${datereg}.log
ftpdir=/pesq/share/monan/testes_continuos_CD-CT
ftpdircron=${ftpdir}/cron/${YYYYMMDDHHi}
#----------------------------------------------------------------------

# Start CRON
echo "========== Start Cron -" $(date "+%d%m%Y-%H%M%S") "==========" > ${logfile}
echo "" >> ${logfile}

# Coleting GitHub Status and Logs
cd ${MONANDIR}
echo "MONAN-Model Git Status e Git Log:" >> ${logfile}
git status | head -1 >> ${logfile}
git log | head -1 >> ${logfile}
echo "" >> ${logfile}

cd ${SCRIPTS}
echo "Scripts_CD-CT Git Status e Git Log:" >> ${logfile}
git status | head -1 >> ${logfile}
git log | head -1 >> ${logfile}
echo "" >> ${logfile}

# Parameters
echo "EXP = " ${EXP} >> ${logfile}
echo "RES = " ${RES} >> ${logfile}
echo "YYYYMMDDHHi = " ${YYYYMMDDHHi} >> ${logfile}
echo "FCST = " ${FCST} >> ${logfile}
echo "" >> ${logfile}

# STEP 1: Installing and compiling the A-MONAN model and utility programs:
# Don't used for CRON

# STEP 2: Executing the pre-processing fase. Preparing all CI/CC files needed:
# JMAS-PAIVA (12jun24): Turned off, this script is running called by ecflow suite at /mnt/beegfs/monan/MONAN-WorkFlow
#time ./2.pre_processing.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} >> ${logfile} 2>&1
#wait

# STEP 3: Executing the Model run:
# CR (25jun24): Model step turned off in this cron, this script is running called by ecflow suite at /mnt/beegfs/monan/MONAN-WorkFlow
#time ./3.run_model.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} >> ${logfile} 2>&1
#wait

# STEP 4: Executing the Post of Model run:
# CR (18jun24): Model step turned off in this cron, this script is running called by ecflow suite at /mnt/beegfs/monan/MONAN-WorkFlow
#time ./4.run_post.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} >> ${logfile} 2>&1
#wait

# Cron finished
echo "========== Finished Cron -" $(date "+%d%m%Y-%H%M%S") "==========" >> ${logfile}

# Copy log cron to FTP
mkdir -p ${ftpdircron}
cp ${logfile} ${ftpdircron}
