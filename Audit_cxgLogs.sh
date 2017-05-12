#!/bin/bash
#created by lixinhang


date_satmp=`date +%Y-%m-%d_%H:%M:%S`
date=`date +%Y-%m-%d`

TARGET_PATH_RESIN="/home/tlxc/logs/resin/"
TARGET_PATH_TOMCAT="/home/tlxc/logs/tomcat/"

UNKNOW_USER_KEY_1="LoginInterceptor==="
UNKNOW_USER_KEY_2="cookieValue==="
UNKNOW_HOST="UnknownHostException"

CHAT_DES_FAILED="The target server failed to respond"
REDIS_FAILED="Could not get a resource from the pool"
FRONT_TIME_OUT="HttpGet abort : Read timed out"

TARGET_LOGS="front_stdout_${date}.log front_access_${date}.log front_stderr_${date}.log sensitiveword_access_${date}.log sensitiveword_stdout_${date}.log chatscheduler_access_${date}.log chatscheduler_stdout_${date}.log dispatcher_access_${date}.log dispatcher_stderr_${date}.log dispatcher_stdout_${date}.log chat_access_${date}.log chat_stderr_${date}.log chat_stdout_${date}.log trade_access_${date}.log trade_stdout_${date}.log datachannel-catalina.${date}.log datachannel-host-manager.${date}.log datachannel-localhost.${date}.log datachannel-manager.${date}.log streamagent-catalina.out upload-catalina.out"

OUT_FILE_NAME="Audit/audit_cxg.log"

function CheckWithKey()
{
   for key in $TARGET_LOGS
   do
      if [ -a $key ]
      then
          local num=`cat $key | grep "$1" | wc -l`
          echo "$1 in $key 's number is: $num" >> $OUT_FILE_NAME
      fi
   done
}

function CheckUnknowUser()
{
   if [ -a "front_stdout_${date}.log" ]
   then
      cat front_stdout_${date}.log | grep "$UNKNOW_USER_KEY_1" >> temp
      local totalnum=`cat temp | wc -l`
      echo "${date} unknow user error with Null_Cookie number is: $totalnum" >> $OUT_FILE_NAME
      local num=`cat temp | grep -v "$UNKNOW_USER_KEY_2" | wc -l`
      echo "${date} unknow user error with CookieValue's number is: $num" >> $OUT_FILE_NAME
      rm -f temp
   fi
}

#####################################################
if [ -d $TARGET_PATH_RESIN ]
then
   cd $TARGET_PATH_RESIN
fi

if [ -d "Audit" ]
then
   echo " "
else
   mkdir Audit
   chmod u+x Audit
fi

echo ">>>>>>>>>>>>>>>>>>> $date_satmp >>>>>>>>>>>>>>>>>" >> $OUT_FILE_NAME
CheckUnknowUser

CheckWithKey "$UNKNOW_HOST"
CheckWithKey "$CHAT_DES_FAILED"
CheckWithKey "$REDIS_FAILED"
CheckWithKey "$FRONT_TIME_OUT"

if [ -d $TARGET_PATH_TOMCAT ]
then
   cd $TARGET_PATH_TOMCAT
fi

CheckWithKey "$UNKNOW_HOST"
CheckWithKey "$CHAT_DES_FAILED"
CheckWithKey "$REDIS_FAILED"

cd $TARGET_PATH_RESIN
echo " " >> $OUT_FILE_NAME

#chmod -R 755 Audit

#####################################################