#!/bin/bash
#created by lixinhang

IPLIST="xc_allserver"

TARGET_FILE="/home/tlxc/logs/resin/Audit/errors_temp"
SHELL_OUT_FILE="ERROR_INFO"
SEND_FILE="CXG_WARNING_MSG"
SEND_MASSAGE_FLAG=1

WARING_KEY_1="miss datachannelIp zoneWorldId"
WARING_KEY_2="Duplicate entry"
WARING_KEY_3="ServerDecoder decode bodyLen"

function GetErrorLog()
{
    #echo "enter function GetErrorLog"
    cat $IPLIST | grep "front" | grep -v "#" | grep -v "bak" >> monitor_ip_temp
    cat $IPLIST | grep "trade" | grep -v "#" | grep -v "bak" >> monitor_ip_temp
    cat $IPLIST | grep "datachannel" | grep -v "#" | grep -v "bak" >> monitor_ip_temp

    cat monitor_ip_temp | while read line
    do
        ip=`echo $line | awk '{print $3}'`
        scp $ip:${TARGET_FILE} monitor_error_logs
        if [ -f monitor_error_logs ]
        then
            error_info=`cat monitor_error_logs`
            echo "[$ip] $error_info"  >> $SHELL_OUT_FILE
            rm -f monitor_error_logs
        fi
    done
    
    if [ -f $SHELL_OUT_FILE ]
    then
        datestamp=`date +%Y-%m-%d`
        hourstamp=`date +%H`
        timestamp="$datestamp $hourstamp"
        echo "$timestamp" >> $SHELL_OUT_FILE
    fi

    rm -f monitor_ip_temp
}

function IsNeedCheck()
{
    #echo "enterfunction isNeedCheck"
    if [ -f $SHELL_OUT_FILE ]
    then
        last_date=`tail -n 1 $SHELL_OUT_FILE`
        last_day=`echo $last_date | awk '{print $1}' | awk 'BEGIN{FS="-"}{print $3}'`
        last_hour=`echo $last_date | awk '{print $2}'`
        cur_day=`date +%d`
        cur_hour=`date +%H`
        if [ $cur_day -gt $last_day ]
        then
            rm -f $SHELL_OUT_FILE
            SEND_MASSAGE_FLAG=1
        else
            if [ $cur_hour -gt $last_hour ]
            then
                rm -f $SHELL_OUT_FILE
                SEND_MASSAGE_FLAG=1
            else
                SEND_MASSAGE_FLAG=0
            fi
        fi
    fi           
}

function sumErrorNum()
{
    cat $SHELL_OUT_FILE | grep "$WARING_KEY_1" >> err1
    err1_num=`cat err1 | wc -l`
    if [ $err1_num -gt 0 ]
    then
        echo "$WARING_KEY_1 error occurd $err1_num times." >> $SEND_FILE
        detail=`head -n 1 err1`
        echo "$detail" >> $SEND_FILE
        rm -f err1
    fi

    cat $SHELL_OUT_FILE | grep "$WARING_KEY_2" >> err2
    err2_num=`cat err2 | wc -l`
    if [ $err2_num -gt 0 ]
    then
        echo "$WARING_KEY_2 error occurd $err2_num times." >> $SEND_FILE
        detail=`head -n 1 err2`
        echo "$detail" >> $SEND_FILE
        rm -f err2
    fi

    cat $SHELL_OUT_FILE | grep "$WARING_KEY_3" >> err3
    err3_num=`cat err3 | wc -l`
    if [ $err3_num -gt 0 ]
    then
        #echo "$WARING_KEY_3 error occurd $err3_num times." >> $SEND_FILE
        detail=`head -n 1 err3`
        #echo "$detail" >> $SEND_FILE
        rm -f err3
    fi
}


#####################################################

sleep 70

IsNeedCheck

#echo "SEND_MASSAGE_FLAG $SEND_MASSAGE_FLAG"
if [ $SEND_MASSAGE_FLAG -eq 0 ]
then
    exit
fi

GetErrorLog
sumErrorNum

if [ -f $SEND_FILE ]
then
   msg=`cat $SEND_FILE`
   Group="cxg" 
   #echo "$msg"
   /usr/bin/curl -d "group=$Group&msg=$msg" http://appmon.changyou-inc.com:8080/msgserver/sendinfo.jsp
fi

rm -f $SEND_FILE

#####################################################