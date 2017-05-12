#!/bin/bash
#created by lixnhang

LOG_KEY_WORDS="show_update_level trade save_fans_value lock_in_combo_pre live shutUpUser show_index_put_map show_index_get_map save_charm_value"

cur_date=`date +%Y-%m-%d`
TIMESTAMP=`date +%Y-%m-%d_%H:%M:%S`

SHELL_OUT_FILE="Audit/Audit_${cur_date}.log"
TEMP_FILE_NAME="temp_lxh"
TEMP_COUNT_FILE="temp"

TARGET_PATH="/home/tlxc/logs/remotelock"
TARGET_FILE_NAME="remotelock.log"

function OpenOldLog()
{
   #echo "enter function openOldfile()"
   if [ -a $TEMP_FILE_NAME ]
   then
       rm -f $TEMP_FILE_NAME
   fi
   local filename=`ls -lnt | grep ".log" | head -n 1`
   local key_word=`echo $filename | awk 'BEGIN{FS="."}{print $3}'`
   echo "filename= $filename and key_word= $key_word"
   cat $TARGET_FILE_NAME | grep "${key_word} 23:" >> $TEMP_FILE_NAME
}

function Count()
{
   #echo "enter function of Count()"
   for key in $LOG_KEY_WORDS
   do
     count=`cat $TEMP_FILE_NAME | grep "$key" | wc -l`
     echo "$key                 $count" >> $SHELL_OUT_FILE
     rm -f $TEMP_COUNT_FILE
   done
}

function SumCount()
{
  for key in $LOG_KEY_WORDS
  do
    num=`cat $TARGET_FILE_NAME | grep "$key" | wc -l `
    echo "$key  $num" >> $SHELL_OUT_FILE
  done
}

#================================================================

if [ -d $TARGET_PATH ]
then
   cd $TARGET_PATH
else
   echo "ERROR: target path not exist."
   exit 0
fi

#cur_hour=`date +%Y-%m-%d`
cur_hour_num=`date +%H`
if [ $cur_hour_num -eq 0 ]
then
   OpenOldLog
else
   temp_hour=$[$cur_hour_num-1]
   if [ $temp_hour -lt 10 ]
   then
       curhour="$cur_date 0${temp_hour}:"
   else
       curhour="$cur_date ${temp_hour}:"
   fi
   rm -f $TEMP_FILE_NAME
   cat $TARGET_FILE_NAME | grep "$curhour" >> $TEMP_FILE_NAME
fi

if [ -a $TEMP_COUNT_FILE ]
then
   rm -f $TEMP_COUNT_FILE
fi

echo ">>>>>>>>>>>>> remotelock.log audit $TIMESTAMP >>>>>>>>>>>>>" >> $SHELL_OUT_FILE
Count
echo ">>>>>>>>>>>>> Today Total sum >>>>>>>>>>>>>" >> $SHELL_OUT_FILE
SumCount
echo " " >> $SHELL_OUT_FILE

rm -f $TEMP_COUNT_FILE
rm -f $TEMP_FILE_NAME

#================================================================