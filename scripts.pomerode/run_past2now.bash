#!/bin/bash



yyyymmddi=20241001
yyyymmddf=20241007
yyyymmdd=${yyyymmddi}


while [ ${yyyymmdd} -le ${yyyymmddf} ]
do

   echo "2.pre_processing.bash GFS 1024002 ${yyyymmdd}00 24"
   
   2.pre_processing.bash GFS 1024002 ${yyyymmdd}00 24

   yyyymmdd=$(date -u +%Y%m%d -d "${yyyymmdd} 1 day") 
done
