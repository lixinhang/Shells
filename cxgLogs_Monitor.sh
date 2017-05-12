#!/bin/bash
#created by lixinhang

#IPLIST="xc_allserver"

DATE=`date +%Y-%m-%d`
TARGET_LOG_PATH_RESIN="/home/tlxc/logs/resin/"
TARGET_LOG_PATH_TOMCAT="/home/tlxc/logs/tomcat/"

TARGET_LOGS="trade_stdout_${DATE}.log front_stdout_${DATE}.log"
MESSY_CODE_LOG="datachannel-catalina.out"

WARING_KEY_1="miss datachannelIp zoneWorldId"
WARING_KEY_2="Duplicate entry"
WARING_KEY_3="ServerDecoder decode bodyLen"

#TEMP_LOG_1="messy_log_temp"
TEMP_LOG_2="temps_monitor"
TEMP_LOG_3="duplicate_entry_temp"
TEMP_LOG_4="miss_worldid_temp"
TEMP_LOG_ERRORS="${TARGET_LOG_PATH_RESIN}Audit/errors_temp"

function CheckMessyCode()
{
    cat $TEMP_LOG_2 | while read line
    do
        packetLen=`echo $line | awk 'BEGIN {FS=","}{print $7}' | awk 'BEGIN {FS=":"}{print $2}'`
        bodyLen=`echo $line | awk 'BEGIN {FS=","}{print $8}' | awk 'BEGIN {FS=":"}{print $2}'`
        if [ "$packetLen" == "$bodyLen" ]
        then
            continue
        else
            error_time=`echo $line | awk 'BEGIN {FS=","}{PRINT $1}'`
            echo "$error_time TCP package error! packetLen=$packetLen, bodyLen=$bodyLen" >> $TEMP_LOG_ERRORS
            break;
        fi
    done
}

function SelectLogSegment()
{
    if [ -n "$3" ]
    then
        cat $1 | grep "$2" | grep "$3" >> $TEMP_LOG_2
    else
        cat $1 | grep "$2" >> $TEMP_LOG_2
    fi
}

function CheckDuplicateEntry()
{
    cat $TEMP_LOG_2 | grep "$WARING_KEY_2" >> $TEMP_LOG_3
    local flag=`head -n 1 $TEMP_LOG_3`
    if [ -n "$flag" ]
    then
        info=`echo $flag | awk '{print $1}{print " "}{print $2}{print " "}{print $7}'`
        echo $info >> $TEMP_LOG_ERRORS
    fi

    rm -f $TEMP_LOG_3
}

function CheckMissWorldID()
{
    cat $TEMP_LOG_2 | grep "$WARING_KEY_1" >> $TEMP_LOG_4
    local flag=`head -n 1 $TEMP_LOG_4`
    if [ -n "$flag" ]
    then
        log_date=`echo $flag | awk '{print $2}{print " "}{print $3}'`
        info=`echo $flag | awk 'BEGIN {FS="-"}{print $6} '`
        #echo "log_date=$log_date info=$info"
        echo "$log_date $info" >> $TEMP_LOG_ERRORS
    fi

    rm -f $TEMP_LOG_4
}

function GetDateParam()
{
    cur_day=`date +%Y-%m-%d`
    cur_hour=`date +%H`
    cur_min=`date +%M`
    target_min=`echo "sacle=0; $cur_min / 10" | bc`

    #if [ $target_min -lt 10 ]
    #then
    #    target_min="0$target_min"
    #fi
 
    KEY_DATE="${cur_day} ${cur_hour}:${target_min}"
    #echo $KEY_DATE
}


#############################################################

if [ -f $TEMP_LOG_ERRORS ]
then
   rm -f $TEMP_LOG_ERRORS
fi

if [ -d $TARGET_LOG_PATH_RESIN ]
then
    cd $TARGET_LOG_PATH_RESIN
else
    exit
fi

if [ -d "Audit" ]
then
   echo " "
else
   mkdir Audit
fi

GetDateParam

sleep 61

for key in $TARGET_LOGS
do
   if [ -f $key ]
   then
       #echo "start select LogSegment key=$key key_date=$KEY_DATE"
       SelectLogSegment "$key" "$KEY_DATE"
       CheckDuplicateEntry
       CheckMissWorldID
      
       rm -f $TEMP_LOG_2
   fi
done

if [ -d $TARGET_LOG_PATH_TOMCAT ]
then
    cd $TARGET_LOG_PATH_TOMCAT
fi

if [ -f $MESSY_CODE_LOG ]
then
   #echo "start SelectLogSegment $MESSY_CODE_LOG $KEY_DATE"
   SelectLogSegment "$MESSY_CODE_LOG" "$KEY_DATE" "$WARING_KEY_3"
   CheckMessyCode

   rm -f $TEMP_LOG_2
fi

#############################################################
