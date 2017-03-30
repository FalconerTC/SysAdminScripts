#!/bin/bash
# Outputs current time
TIME=$(date --date="2 hours ago" +%H:%M)
if [ $1 = "time" ] ; then
	MSG="The current time is $TIME (MST)"
elif [ $1 = "restart" ]; then
	MSG="The Minecraft server will be restarting in 60 seconds to apply updates"
else
	MSG="Improper script usage. Just saying hi"
fi
screen -S Minecraft_Server -X stuff "say $MSG ^M"
