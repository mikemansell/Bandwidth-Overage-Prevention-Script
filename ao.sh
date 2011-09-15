#!/bin/bash

# This script will help you limit the amount of bandwidth that you consume so that you can predict/budget bandwidth fees
#       while using services such as the RackSpace Cloud which bill based on bandwidth utilization
# Requires "vnstat" and "screen"

# Maximum amount of bandwidth (megabytes) that you want to consume in a given month before anti-overage commands are run
MAX=10240

# Interface that you would like to monitor (typically "eth0")
INTERFACE="eth0"

function getusage {
        DATA=`vnstat --dumpdb -i $INTERFACE | grep 'm;0'`
        INCOMING=`echo $DATA | cut -d\; -f4`
        OUTGOING=`echo $DATA | cut -d\; -f5`
        TOTUSAGE=$(expr $INCOMING + $OUTGOING)
        if [ $TOTUSAGE -ge $MAX ]; then
                logevent "`echo $TOTUSAGE/$MAX`mb of monthly bandwidth has been used; bandwidth-saving precautions are being run"
                iptables-restore < /etc/firewall-lockdown.conf
        else
                logevent "`echo $TOTUSAGE/$MAX`mb of monthly bandwidth has been used; system is clear for the time being"
        fi
        sleep 300
        getusage
}

function logevent {
        STRINGBASE="`date +%d\ %B\ %Y\ @\ %H:%M:%S` -:-"
        MESSAGE="$@"
        echo "$STRINGBASE $MESSAGE" >> aolog.txt
}

if [ $MAX == "" ]; then
        logevent "The maximum monthly traffic level (\$MAX) has not been defined.  Please define this and restart."
        exit
elif [ $INTERFACE == "" ]; then
        logevent "You have not defined the interface network (\$INTERFACE) that you want to monitor.  Please define this and restart"
        exit
elif [ "`whereis vnstat`" == "vnstat:" ]; then
        logevent "It appears that you do not have \"vnstat\" installed.  Please install this package and restart."
        exit
elif [ "`whereis screen`" == "screen:" ]; then
        logevent "It appears that you do not have \"screen\" installed.  Please install this package and restart."
        exit
fi

if [ "$1" == "doscreen" ]; then
        getusage
else
        logevent "Starting vnstat interface logging on $INTERFACE"
        vnstat -u -i $INTERFACE
        logevent "Initiating screen session to run as a daemon process"
        screen -d -m $0 doscreen
fi