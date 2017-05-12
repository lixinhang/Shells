#!/bin/bash
#create by lixinhang

LOGIN_FRONTNUM="GET /gameLogin.action"
LOGIN_BACKNUM="POST /makeOpt.action"

ENTER_ROOM_FRONTNUM="GET /ft_decrypt.action"
ENTER_ROOM_KEY="GET /pd_getToken.action"
ENTER_ROOM_BACKNUM="GET /1200"

TARGET_LOG_PATH="/home/tlxc/logs/nginx/"
TARGET_LOG_NAME="front.access.log"

ERROR_FILE="Audit/errors"
TEMP_FILE="temp"
GAMELOGIN_FAILED="Audit/gameLogin_fail.log"
MAKEOPT_FAILED="Audit/makeOpt_fail.log"
FT_FAILED="Audit/ft_decrypt.log"
FL_FAILED="Audit/fl.action.log"
GET_TOKEN_FAILED="Audit/get_token.log"
AUDIT_FILE="Audit/audit_success_rate.log"

ERR_404_NUM="Audit/audit_404_num.log"
ERR_404_FILE="Audit/audit_404_error.log"

function SelectWithKeyWord()
{
   cat $TARGET_LOG_NAME | grep "$1" >> $TEMP_FILE
   case "$1" in
   "$LOGIN_FRONTNUM")
       DEFAULT_NAME="$GAMELOGIN_FAILED"
       gameLogin_num=`cat $TEMP_FILE | wc -l`
       #echo $gameLogin_num
       
   ;;
   "$LOGIN_BACKNUM")
       DEFAULT_NAME="$MAKEOPT_FAILED"
       makeOpt_num=`cat $TEMP_FILE | wc -l`
       #echo $DEFAULT_NAME
       #echo $makeOpt_num
   ;;
   "$ENTER_ROOM_FRONTNUM")
       DEFAULT_NAME="$FT_FAILED"
       ft_num=`cat $TEMP_FILE | wc -l`
       #echo $DEFAULT_NAME
       #echo $ft_num
   ;;
   "$ENTER_ROOM_KEY")
       DEFAULT_NAME="$GET_TOKEN_FAILED"
       token_num=`cat $TEMP_FILE | wc -l`
       #echo $DEFAULT_NAME
       #echo $token_num
   ;;
   "$ENTER_ROOM_BACKNUM")
       DEFAULT_NAME="$FL_FAILED"
       fl_num=`cat $TEMP_FILE | wc -l`
       #echo $DEFAULT_NAME
       #echo $fl_num
   ;;
   esac

   #cat $TEMP_FILE >> temp_logs
   rm -f $TEMP_FILE
}

function SumErrorLogs()
{
   if [ -f $ERROR_FILE ]
   then
      rm -f $ERROR_FILE
   fi

   cat temp_logs | while read line
   do
      recode=`echo $line | awk 'BEGIN{FS=" "}{print $10}'`
      if [ $recode -ge 400 ]
      then
          echo $line >> $ERROR_FILE
      fi
   done

  rm -f temp_logs
}

function Get404Errors()
{
   if [ -f $ERR_404_NUM ]
   then
        rm -f $ERR_404_NUM
   fi
   if [ -f $ERR_404_FILE ]
   then
        rm -f $ERR_404_FILE
   fi

   cat $TARGET_LOG_NAME | grep "HTTP/1.1\" 404 " | grep -v "/css/csshover.htc" >> $ERR_404_FILE
   err_num=`cat $ERR_404_FILE | wc -l`
   echo "$err_num" >> $ERR_404_NUM
   if [ $err_num -gt 10 ]||[ $err_num -eq 0 ]
   then
       rm -f $ERR_404_FILE
   fi
}

#######################################################
if [ -d $TARGET_LOG_PATH ]
then
   cd $TARGET_LOG_PATH
else
   echo "ERROR: target path not exist."
   exit 0
fi

if [ -a $TEMP_FILE ]
then
   rm -f $TEMP_FILE
fi

if [ -d "Audit" ]
then
    echo " "
else
    mkdir Audit
    chmod u+x Audit
fi

cur_date=`date +%Y-%m-%d_%H:%M:%S`
#echo ">>>>>>>>>>>>>>>>>> $cur_date >>>>>>>>>>>>>>>>>>>>" >> $GAMELOGIN_FAILED
#echo ">>>>>>>>>>>>>>>>>> $cur_date >>>>>>>>>>>>>>>>>>>>" >> $MAKEOPT_FAILED
#echo ">>>>>>>>>>>>>>>>>> $cur_date >>>>>>>>>>>>>>>>>>>>" >> $FT_FAILED
#echo ">>>>>>>>>>>>>>>>>> $cur_date >>>>>>>>>>>>>>>>>>>>" >> $FL_FAILED

SelectWithKeyWord "$LOGIN_FRONTNUM"
SelectWithKeyWord "$LOGIN_BACKNUM"
SelectWithKeyWord "$ENTER_ROOM_FRONTNUM"
SelectWithKeyWord "$ENTER_ROOM_KEY"
SelectWithKeyWord "$ENTER_ROOM_BACKNUM"

echo ">>>>>>>>>>>>>>>>>> $cur_date >>>>>>>>>>>>>>>>>>>>" >> $AUDIT_FILE
login_rate=`echo "scale=2; ($gameLogin_num * 100 ) / $makeOpt_num" | bc`
echo "Login success rate: $gameLogin_num / $makeOpt_num = $login_rate %" >> $AUDIT_FILE
temp_num=$[$ft_num-$token_num]
enter_rate=`echo "scale=2; ( $temp_num * 100 ) / $fl_num" | bc`
echo ":enter room success rate: $temp_num / $fl_num = $enter_rate %" >> $AUDIT_FILE
echo " " >> $AUDIT_FILE

Get404Errors
#SumErrorLogs

#######################################################