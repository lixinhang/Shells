#!/bin/bash
#created by lixinhang

EMAIL_LIST="lixinhang@cyou-inc.com"

IPLIST="xc_allserver"
SHELL_OUT_FILE="Analyze_result"
DETAIL_OUT_FILE="Detail"

DATE=`date +%Y-%m-%d`
NGINX_LOGPATH="/home/tlxc/logs/nginx/Audit/"
NGINX_LOG_NAME="audit_success_rate.log"

LOG_404_NUM="audit_404_num.log"
LOG_404_DETAIL="audit_404_error.log"

GENERAL_LOGPATH="/home/tlxc/logs/resin/Audit/"
GENERAL_LOG_NAME="audit_cxg.log"
LOCK_LOGPATH="/home/tlxc/logs/remotelock/Audit/"
LOCK_LOG_NAME="Audit_${DATE}.log"

TARGET_SERVER_TYPE="front trade datachannel chat dispatcher datachannelscheduler redis chatscheduler sensitive_word upload lockServer livemonitor"
TARGET_ERROR_TYPE="Null_Cookie CookieValue UnknownHostException respond pool abort"

function NginxLogInit()
{
   cat $IPLIST | grep "nginx" | grep -v "#" | grep -v "bak" | awk '{print $3}' >> nginx_ip_temp
   total_ng_num=`cat nginx_ip_temp | wc -l`
   cat nginx_ip_temp | while read line
   do
      scp $line:${NGINX_LOGPATH}${NGINX_LOG_NAME} nginx_log_temp
      info=`tail -n 3 nginx_log_temp`
      login=`echo $info | awk 'BEGIN{FS=":"} {print $2}'`
      enter_room=`echo $info | awk 'BEGIN{FS=":"}{print $4}'`
      echo "$line:      $login" >> LoginRate
      echo "$line:      $enter_room" >> EnterRate
      rm -f nginx_log_temp
   done
}

function Get404ErrorLogs()
{
   cat nginx_ip_temp | while read line
   do
      scp $line:${NGINX_LOGPATH}${LOG_404_NUM} temp_404_num
      if [ -f temp_404_num ]
      then
          err_404_sum=`cat temp_404_num`
          #if [ $err_404_sum -lt 10 ] && [ $err_404_sum -gt 0 ]
          #then
              #scp $line:${NGINX_LOGPATH}${LOG_404_DETAI} temp_404_detail
              #cat temp_404_detail >> sum_404_detail
              #rm -f temp_404_detail
          #fi
          echo "$line   $err_404_sum" >> total_404_sum
          rm -f temp_404_num
      fi
   done
}

function Sum404ErrorNum()
{
   local total=0
   if [ -f total_404_sum ]
   then
       cat total_404_sum | while read line
       do
          err_num=`echo $line | awk '{print $2}'`
          total=`echo "$total + $err_num" | bc`
          echo $total > bc_total_temp
       done
   fi

   total=`cat bc_total_temp`
   echo "Total 404 Error num in all server: $total" >> $SHELL_OUT_FILE
   rm -f bc_total_temp

   if [ $total -gt 0 ]
   then
       echo " "
       echo ">>>>>>>>>>>>>>>>>>>> 404 error detail >>>>>>>>>>>>>>>>>>>>>" >> $SHELL_OUT_FILE
       cat total_404_sum >> $SHELL_OUT_FILE
   fi
   rm -f total_404_sum
}

function GeneralLogInit()
{
  for log in $TARGET_SERVER_TYPE
  do
     cat $IPLIST | grep "$log" | grep -v "#" | grep -v "bak" | awk '{print $3}' >> logs_ip_temp
  done
  
  cat logs_ip_temp | while read line
  do
     scp $line:${GENERAL_LOGPATH}${GENERAL_LOG_NAME} log_temp
     if [ -f log_temp ]
     then
        echo ">>>>>>>>>>>>>>>>>>> $line >>>>>>>>>>>>>>>>>>>" >> target_log
        cat log_temp | grep "$1" | grep -v ">>>" >> target_log
     else
        continue
     fi
     rm -f log_temp
  done
  rm -f logs_ip_temp
}

function SumLockLog()
{ 
   echo "enter function SumLockLog"
   cat $IPLIST | grep "lockServer" | grep -v "#" | grep -v "bak" | awk '{print $3}' >> lock_ip_temp
   cat lock_ip_temp | while read line
   do
      scp $line:${LOCK_LOGPATH}${LOCK_LOG_NAME} lock_log_temp
      if [ -f lock_log_temp ]
      then
         echo ">>>>>>>>>>>>>>>>>>> LockServer num today sum >>>>>>>>>>>>>>>>>>>" >> $SHELL_OUT_FILE
         tail -n 10 lock_log_temp >> $SHELL_OUT_FILE
      else
         continue
      fi
      rm -f lock_log_temp
   done
   rm -f lock_ip_temp
}


function DetailGeneralLogs()
{
  cat target_log | while read line
  do
     tar=`echo $line | grep ">>"`
     if [ -n "$tar" ]
     then
        echo $line >> $DETAIL_OUT_FILE
     else
        local num=`echo $line | awk 'BEGIN{FS="is: "}{print $2}'`
        if [ "$num" != "0" ]
        then
           echo "$line" >> $DETAIL_OUT_FILE
        fi
     fi
  done
  rm -f target_log
}

function SumGeneralLogs()
{
  for key in $TARGET_ERROR_TYPE
  do
    cat $DETAIL_OUT_FILE | grep "$key" >> $key
  done
  
  for key in $TARGET_ERROR_TYPE
  do
    local sum=0
    str=`cat $key`
    if [ -z "$str" ]
    then
       echo "0" >> key_num
    else 
       cat $key | while read line
       do
          local num=`echo $line | awk 'BEGIN{FS="is: "}{print $2}'`
          sum=`echo "$sum + $num" | bc`
          echo "$sum" >> key_num
       done
    fi
    rm -f "$key"

    nTemp=`tail -n 1 key_num`
    case "$key" in
    "Null_Cookie")
       echo -e "Total unknow user error with Null_Cookie num in all server: $nTemp \n" >> $SHELL_OUT_FILE
    ;;
    "CookieValue")
       echo -e "Total unknow user error with CookieValue num in all server: $nTemp \n" >> $SHELL_OUT_FILE
    ;;
    "UnknownHostException")
       echo -e "Total UnknownHostException num in all server: $nTemp \n" >> $SHELL_OUT_FILE
    ;;
    "respond")
       echo -e "Total target server failed to respond num in all server: $nTemp \n" >> $SHELL_OUT_FILE
    ;;
    "pool")
       echo -e "Total Could not get a resource from the pool num in all server: $nTemp \n" >> $SHELL_OUT_FILE
    ;;
    "abort")
       echo -e "Total HttpGet abort Read timed out num in all server: $nTemp \n" >> $SHELL_OUT_FILE
    ;;
    esac
    rm -f key_num
  done
}

function SumLoginRate()
{
   sum1=0
   sum2=0
   cat LoginRate | while read line
   do
      num1=`echo $line | awk '{print $2}'`
      num2=`echo $line | awk '{print $4}'`
      sum1=`echo "$sum1 + $num1" | bc`
      sum2=`echo "$sum2 + $num2" | bc`
      echo $sum1 > temp1
      echo $sum2 > temp2
   done
   sum1=`cat temp1`
   sum2=`cat temp2`
   login_rate_ave=`echo "scale=2; ( $sum1 * 100 ) / $sum2" | bc`
   echo ">>>>>>>>>>>>>>>>>>>  Login success rate audit >>>>>>>>>>>>>>>>>>" >> $SHELL_OUT_FILE
   cat LoginRate >> $SHELL_OUT_FILE
   echo "Sum: $sum1 / $sum2 = $login_rate_ave %" >> $SHELL_OUT_FILE
   echo " " >> $SHELL_OUT_FILE
   
   rm -f temp1
   rm -f temp2
}

function SumEnterRoomRate()
{
   sum1=0
   sum2=0
   cat EnterRate | while read line
   do  
      num1=`echo $line | awk '{print $2}'`
      num2=`echo $line | awk '{print $4}'`
      sum1=`echo "$sum1 + $num1" | bc`
      sum2=`echo "$sum2 + $num2" | bc`
      echo $sum1 > temp1
      echo $sum2 > temp2
   done
   sum1=`cat temp1`
   sum2=`cat temp2`
   enter_rate_ave=`echo "scale=2; ( $sum1 * 100 ) / $sum2" | bc`
   echo ">>>>>>>>>>>>>>>>>>>  Enter room success rate audit >>>>>>>>>>>>>>>>>>" >> $SHELL_OUT_FILE
   cat EnterRate >> $SHELL_OUT_FILE
   echo "Sum: $sum1 / $sum2 =  $enter_rate_ave %" >> $SHELL_OUT_FILE
   echo " " >> $SHELL_OUT_FILE
   
   rm -f temp1
   rm -f temp2
}

function DeleteTempFile()
{
   rm -f LoginRate
   rm -f EnterRate
   rm -f nginx_ip_temp
   rm -f logs_ip_temp
   rm -f detail_temp
   rm -f $DETAIL_OUT_FILE
}

function GetMoreErrorDetail()
{
   echo " " >> $SHELL_OUT_FILE
   echo "GET MORE INFORMATION IN DETAILS" >> $SHELL_OUT_FILE
   echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" >> $SHELL_OUT_FILE
   echo " " >> $SHELL_OUT_FILE

   cat $DETAIL_OUT_FILE | grep -v "Cookie" >> $SHELL_OUT_FILE
}


###############################################################

if [ -f $IPLIST ]
then
   echo " "
else
   echo "IP List not exist!"
   exit 0
fi

sleep 50

NginxLogInit
SumLoginRate
SumEnterRoomRate

SumLockLog

GeneralLogInit "$DATE"
DetailGeneralLogs
SumGeneralLogs

Get404ErrorLogs
Sum404ErrorNum

GetMoreErrorDetail   
DeleteTempFile

mail -s "CXG_LOG_AUDIT Daily Push" $EMAIL_LIST <$SHELL_OUT_FILE
rm -f $SHELL_OUT_FILE

################################################################