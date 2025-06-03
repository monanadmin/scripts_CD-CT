#!/bin/bash


yyyymmddi=20241001
yyyymmddf=20241005
yyyymmdd=${yyyymmddi}


# Input variables:-----------------------------------------------------
DIR_DADOS=/mnt/beegfs/monan/users/renato/issues/ecflow-PREOPER/SCRATCHOUT; mkdir -p ${DIR_DADOS}
DIRFLUSHOUT=/mnt/beegfs/monan/users/renato/issues/trashout; mkdir -p ${DIRFLUSHOUT}
EXP=GFS
RES=1024002
FCST=240
#----------------------------------------------------------------------


while [ ${yyyymmdd} -le ${yyyymmddf} ]
do

   echo "${SCRIPTS}/2.pre_processing.bash ${EXP} ${RES} ${yyyymmdd}00 240"
   ${SCRIPTS}/2.pre_processing.bash ${EXP} ${RES} ${yyyymmdd}00 240
   echo "${SCRIPTS}/3.run_model.bash      ${EXP} ${RES} ${yyyymmdd}00 240"
   ${SCRIPTS}/3.run_model.bash      ${EXP} ${RES} ${yyyymmdd}00 240
   echo "${SCRIPTS}/4.run_post.bash       ${EXP} ${RES} ${yyyymmdd}00 240"
   ${SCRIPTS}/4.run_post.bash       ${EXP} ${RES} ${yyyymmdd}00 240

   # Final data output directory:
   mkdir -p ${DIRFLUSHOUT}/${yyyymmdd}00/
   # Copy post:
   cp -fr ${DIRSCRIPTDADOS}/dataout/${yyyymmdd}00/Post/* ${DIRFLUSHOUT}/${yyyymmdd}00/
   # Remove all output files from the original output diretory dataout:
   rm -fr ${DIRSCRIPTDADOS}/dataout/${yyyymmdd}00
   rm -fr ${DIRSCRIPTDADOS}/datain/${yyyymmdd}00  
   
   
   
   echo "${SCRIPTS}/2.pre_processing.bash ${EXP} ${RES} ${yyyymmdd}12 120"
   ${SCRIPTS}/2.pre_processing.bash ${EXP} ${RES} ${yyyymmdd}12 120
   echo "${SCRIPTS}/3.run_model.bash      ${EXP} ${RES} ${yyyymmdd}12 120"
   ${SCRIPTS}/3.run_model.bash      ${EXP} ${RES} ${yyyymmdd}12 120
   echo "${SCRIPTS}/4.run_post.bash       ${EXP} ${RES} ${yyyymmdd}12 120"
   ${SCRIPTS}/4.run_post.bash       ${EXP} ${RES} ${yyyymmdd}12 120
    
   # Final data output directory:
   mkdir -p ${DIRFLUSHOUT}/${yyyymmdd}12/
   # Copy post:
   cp -fr ${DIRSCRIPTDADOS}/dataout/${yyyymmdd}12/Post/* ${DIRFLUSHOUT}/${yyyymmdd}12/
   # Remove all output files from the original output diretory dataout:
   rm -fr ${DIRSCRIPTDADOS}/dataout/${yyyymmdd}12
   rm -fr ${DIRSCRIPTDADOS}/datain/${yyyymmdd}12  
   
   yyyymmdd=$(date -u +%Y%m%d -d "${yyyymmdd} 1 day") 
done
