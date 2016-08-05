#!/bin/bash
# A basic service management script

# Get the PID of the requested service
get_pid() 
{
    ps fax | grep $SCREEN_NAME | grep SCREEN | awk '{ print $1 }'
}


usage() 
{
    echo "Usage: $0 {killingfloor|starbound} {start|stop|restart|status|update}"
    exit 0
}

start()
{
    echo "Attempting to start server..."
    PID=$(get_pid)
    if [[ $PID ]]; then
	echo "Server already running"
        RET=0
    else
	pushd $GAME_PATH  1>/dev/null
        screen -A -m -d -S $SCREEN_NAME $START_CMD
        RET=$?
	echo -e "\nServer running in detached screen"
	echo "Screen name: $SCREEN_NAME"
	popd 1>/dev/null
    fi
    return $RET
}

stop()
{
    PID=$(get_pid)
    if [[ $PID ]]; then  
	screen -X -S $SCREEN_NAME kill
        RET=$?
	echo "Server stopped successfully"
	sleep 0.2
    else
      echo "Server not running"
        RET=0
    fi
    return $RET
}

restart()
{
    PID=$(get_pid)
    echo "Stopping server..."
    stop
    echo -e "\nStarting server..."
    start
    return $?
}

status()
{
    PID=$(get_pid)
    if [[ $PID ]]; then  
	echo "Server running"
	echo "PID: $PID"
        RET=0
    else
        echo "Server not running"
        RET=1
    fi
    return $RET
}

update()
{
    echo "Running updater..."
    $STEAMCMD +login $STEAM_USERNAME +force_install_dir $GAME_DIR +app_update $GAME_ID validate +quit
    return $?
}


# Read in service
case "$1" in
    killingfloor | kf)
        source $SETTINGS_DIR/.killingfloorrc
    ;;
    starbound | sb)
        source $SETTINGS_DIR/.starboundrc
    ;;
    *)
        usage
    ;;
esac

# Read and perform action
case "$2" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    restart
    ;;
  status)
    status 
    ;;
  update)
    update
    ;;
  *)
    usage
    ;;
esac
exit $?
