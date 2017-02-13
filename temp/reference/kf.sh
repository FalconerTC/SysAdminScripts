#!/bin/bash
#
# Init file for Killing Floor server
#
# chkconfig: 35 90 12
# description: Killing Floor
#
# source function library
. /etc/rc.d/init.d/functions
SCREEN_NAME=killing-floor
GAME_PATH=//srcds_l/killingfloor/system
　
start()
{
cd $GAME_PATH && /usr/bin/screen -A -m -d -S $SCREEN_NAME ./ucc-bin server KF-BioticsLab.rom?game=KFmod.KFGameType?VACSecure=true?MaxPlayers=6
}
stop()
{
PID=`ps fax | grep $SCREEN_NAME | grep SCREEN | awk '{ print $1 }'`
kill $PID
}
restart()
{
stop
start
}
case "$1" in
start)
start
;;
stop)
stop
;;
restart)
stop
start
;;
*)
echo $"Usage: $0 {start|stop|restart}"
exit 1
esac
exit 0
