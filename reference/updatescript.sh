#!/bin/bash
set -e
#
# About: This little Shell-Script checks, if a newer version of your TeamSpeak 3 server is available and if yes, it will update the server, if you want to.
# Author: Sebastian Kraetzig <ts3webapp@kraetzig.org>
#
# This is a little sub-project of the 'TS3 WebApp' (http://www.ts3webapp.kraetzig.org/) and can just be found on http://addons.teamspeak.com/.
#
# License: GNU GPLv3
#
# Donations: https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=9A2GVABEUWS92
#

echo -e "\nAbout: This little Shell-Script checks, if a newer version of your TeamSpeak 3 server is available and if yes, it will update the server, if you want to.";
echo -e "Author: Sebastian Kraetzig <ts3webapp@kraetzig.org>";
echo -e "License: GNU GPLv3\n";
echo -e "Version: 2.0 (2013-11-21)\n";
echo -e "---------------------------------\n";

# Make sure, that the user has root permissions
if [[ "$(whoami)" != "root" ]]; then
	# Get absolute path of script
	cd "$(dirname $0)"
	SCRIPT="$(pwd)/$(basename $0)"
	cd - > /dev/null

	# Start script with root permissions - after correct password input
	echo -e "This script needs root permissions. Please enter your root password...\n";
	su -c "$SCRIPT $1 $2"

	exit 0
fi

SCRIPT_NAME="$(basename $0)"

# If no option is set, show the usage message
if [ "$1" = "" ]; then
	echo "$SCRIPT_NAME: missing option";
	echo "Usage: ./$SCRIPT_NAME OPTION [--delete-old-logs] [--inform-online-clients password-file]";
	echo
	echo "Try './$SCRIPT_NAME --help' for more options.";

	exit 0;
fi

# If an unregonized option is set, show the usage message
if [ "$1" != "" ] && [ "$1" != "-h" ] && [ "$1" != "--help" ] && [ "$1" != "--check" ] && [ "$2" != "--delete-old-logs" ] && [ "$1" != "--autoupdate=yes" ] && [ "$1" != "--autoupdate=no" ] && [ "$1" != "--cronjob-auto-update" ] && [ "$3" != "--inform-online-clients" ] && [ "$2" != "--inform-online-clients" ]; then
	if [ "$1" = "--delete-old-logs" ]; then
		echo "$SCRIPT_NAME: This parameter must be set as second! Choose an option for the first parameter!";
	else
		echo "$SCRIPT_NAME: unregonized option '$1'";
	fi
	if [ "$1" = "--inform-online-clients" ]; then
		echo "$SCRIPT_NAME: This parameter must be set as second or third! Choose an option for the first parameter!";
	else
		echo "$SCRIPT_NAME: unregonized option '$1'";
	fi
	echo "Usage: ./$SCRIPT_NAME OPTION [--delete-old-logs] [--inform-online-clients password-file]";
	echo
	echo "Try './$SCRIPT_NAME --help' for more options.";

	exit 0;
fi

# If option '-h' or '--help' is set, show the usage message
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	echo "Usage: ./$SCRIPT_NAME OPTION [--delete-old-logs] [--inform-online-clients password-file]";
	echo
	echo -e "Option\t\t\t	Description";
	echo    "---------------------------------";
	echo -e "-h	\t\t	Shows this usage message\n";
	echo -e "--help	\t\t	Shows this usage message\n";
	echo -e "--check	\t\t	Checks for newer version; If a newer version is available, the user will be asked, if he want to update his TeamSpeak 3 server\n";
	echo -e "--delete-old-logs\t	Deletes old logs while update process (set it as second parameter)\n";
	echo -e "--inform-online-clients\t	Sends a global text message to all virtual servers, that the server will be updated (if you enter 'Yes, update!')
				The following parameter 'password-file' contents your 'serveradmin' password. You have to write it in a file, that it will not be saved in history.\n";
	echo -e "--autoupdate=yes\t	Installs weekly cronjob for monday at 3 AM (= 03:00 O'clock)
				Checks for newer version and installs the latest TeamSpeak 3 server automatically without asking\n";
	echo -e "--autoupdate=no\t\t	Deinstalls weekly cronjob of monday at 3 AM (= 03:00 O'clock)\n";

	exit 0;
fi

# If the users should be informed is a password required - is it missing?
if [ "$3" != "" ]; then
	if [ "$3" = "--inform-online-clients" ] && [ "$4" != "" ] || [ "$2" = "--inform-online-clients" ] && [ "$3" != "" ]; then
		echo -e "All online clients will be informed about perhaps TeamSpeak server updates, if your password is correct.\n";
	else
		echo "The option '--inform-online-clients' needs a further parameter, which is the 'serveradmin' password!";
		exit 1;
	fi
fi

echo -e "Please wait... Script is working...\n";

# At first check, if all needed softwares are installed
declare -a NEEDED_SOFTWARE_LIST=(bash rsync wget grep telnet)

# Debian
if [ -f /etc/debian_version ]; then
	for SOFTWARE in ${NEEDED_SOFTWARE_LIST[@]}; do
        	dpkg -l | grep -i $SOFTWARE | head -1 | if [[ "$(cut -d ' ' -f 1)" != "ii" ]]; then
               	        echo -e "$SOFTWARE is NOT installed completely! Please install it...\n";
                       	exit 1;
                fi
	done
# RedHat / CentOS
elif [ -f /etc/redhat-release ]; then
	if [[ "$(rpm -q $SOFTWARE)" == "package $SOFTWARE is not installed" ]]; then
		echo -e "$SOFTWARE is NOT installed completely! Please install it...\n";
		exit 1;
	fi
else
	echo "Your system is currently not supported by this script. If you want to be able to use it, please make a suggestion in the following forum. I will need some specific informations about your system. http://ts3webapp-forum.kraetzig.org/forum";
	exit 1;
fi

# If option '--autoupdate=yes' is set, install the cronjob for monday at 3 AM
if [ "$1" = "--autoupdate=yes" ]; then
	if [ "$2" = "--inform-online-clients" ]; then
		( crontab -l 2>/dev/null | grep -Ev "(TS3UpdateScript|$(pwd)/$(basename $0))" ; printf -- "# TS3UpdateScript: Cronjob for auto updates\n0 3 * * 1  /bin/bash $(pwd)/$(basename $0) --cronjob-auto-update $2 $(pwd)/$(basename $3)\n" ) | crontab
	fi
	if [  "$3" = "--inform-online-clients" ]; then
		( crontab -l 2>/dev/null | grep -Ev "(TS3UpdateScript|$(pwd)/$(basename $0))" ; printf -- "# TS3UpdateScript: Cronjob for auto updates\n0 3 * * 1  /bin/bash $(pwd)/$(basename $0) --cronjob-auto-update $2 $3 $(pwd)/$(basename $4)\n" ) | crontab
	else
		( crontab -l 2>/dev/null | grep -Ev "(TS3UpdateScript|$(pwd)/$(basename $0))" ; printf -- "# TS3UpdateScript: Cronjob for auto updates\n0 3 * * 1  /bin/bash $(pwd)/$(basename $0) --cronjob-auto-update $2\n" ) | crontab
	fi

	if [[ $? -eq 0 ]]; then
		echo "The new cronjob was installed successfull.";
	else
		echo "The new cronjob could NOT be installed!";
	fi

	exit 0;
fi

# If option '--autoupdate=no' is set, deinstall the cronjob of monday at 3 AM
if [ "$1" = "--autoupdate=no" ]; then
	( crontab -l 2>/dev/null | grep -Ev "(TS3UpdateScript|$(pwd)/$(basename $0))" ) | crontab

	if [[ $? -eq 0 ]]; then
		echo "The cronjob was deinstalled successfull!";
	else
		echo "The cronjob could NOT be deinstalled!";
	fi

	exit 0;
fi



#################################################################
#								#
#	G E T/F E T C H  N E E D E D  I N F O R M A T I O N S	#
#								#
#################################################################



# Get current root directory of installed TeamSpeak 3 server
TEAMSPEAK_DIRECTORY=$(dirname $(find / -name 'ts3server_startscript.sh' 2> /dev/null | grep -v '/tmp/ts3server_backup' | sort | tail -1))

if [[ "$TEAMSPEAK_DIRECTORY" == "" ]]; then
        echo -e "Could not find your root directory of your installed TeamSpeak 3 server. Maybe you have deleted the 'ts3server_startscript.sh' file? Please update your TeamSpeak 3 server manually or check for updates of this script!";
       	exit 1;
fi

# Get owner and group of TeamSpeak 3 server files
USER="$(stat --format='%U' $(find $TEAMSPEAK_DIRECTORY -name 'ts3server_startscript.sh' 2> /dev/null | grep -v '/tmp/ts3server_backup' | sort | tail -1))"
GROUP="$(stat --format='%G' $(find $TEAMSPEAK_DIRECTORY -name 'ts3server_startscript.sh' 2> /dev/null | grep -v '/tmp/ts3server_backup' | sort | tail -1))"

# Fetch latest version from www.teamspeak.com
echo -e "Searching for latest version, installed version and architecture and installation directory as well as owner...\n";

# Debian
if [ -f /etc/debian_version ]; then
	TEMPFILE_1=$(tempfile -m 0600 -p "ts3_download_page-" -s ".tmp")
	TEMPFILE_2=$(tempfile -m 0600 -p "ts3_download_page-" -s ".tmp")
	TEMPFILE_3=$(tempfile -m 0600 -p "ts3_download_page-" -s ".tmp")
# RedHat / CentOs
elif [ -f /etc/redhat-release ]; then
	TEMPFILE_1=$(mktemp "/tmp/ts3_download_page-XXXXX.tmp")
	TEMPFILE_2=$(mktemp "/tmp/ts3_download_page-XXXXX.tmp")
	TEMPFILE_3=$(mktemp "/tmp/ts3_download_page-XXXXX.tmp")
fi

# Download 'TeamSpeak 3 Download page'
wget http://www.teamspeak.com/?page=downloads -q -O - > $TEMPFILE_1

# Get the latest Linux server version of the downloaded 'TeamSpeak Download page'
grep -A 120 'Linux' $TEMPFILE_1 > $TEMPFILE_2
grep -A 1 'Server' $TEMPFILE_2 > $TEMPFILE_3
LATEST_VERSION="$(cat $TEMPFILE_3 | egrep -o  '((\.)?[0-9]{1,3}){1,3}\.[0-9]{1,3}' | tail -1)"

if [[ "$LATEST_VERSION" == "" ]]; then
	LATEST_VERSION="Unknown"
fi

# Get installed TeamSpeak 3 server version
INSTALLED_VERSION="$(cat $(find $TEAMSPEAK_DIRECTORY -name 'ts3server*_0.log' 2> /dev/null | sort | egrep -E -v '/tmp/ts3server_backup/logs' | tail -1) | egrep -o 'TeamSpeak 3 Server ((\.)?[0-9]{1,3}){1,3}\.[0-9]{1,3}' | egrep -o '((\.)?[0-9]{1,3}){1,3}\.[0-9]{1,3}')"

if [[ "$INSTALLED_VERSION" == "" ]]; then
        INSTALLED_VERSION="Unknown"
fi

# Get installed TeamSpeak architecture
ARCHITECTURE="$(ls $(find $TEAMSPEAK_DIRECTORY -name 'ts3server_*_*' 2> /dev/null | grep -v 'ts3server_minimal_runscript.sh' | sort | tail -1) | egrep -o  '(amd64|x86)' | tail -1)"

if [[ "$ARCHITECTURE" == "" ]]; then
	ARCHITECTURE="Unknown"
fi

# Check, if "Linux" or "FreeBSD" is installed
if [ -e "$TEAMSPEAK_DIRECTORY/ts3server_linux_$ARCHITECTURE" ]; then
	LINUX_OR_FREEBSD="linux"
	LINUX_OR_FREEBSD_UPPER_CASE="Linux"
elif [ -e "$TEAMSPEAK_DIRECTORY/ts3server_freebsd_$ARCHITECTURE" ]; then
	LINUX_OR_FREEBSD="freebsd"
	LINUX_OR_FREEBSD_UPPER_CASE="FreeBSD"
fi

# Check, if MySQL-Database exists
TEAMSPEAK_DATABASE_TYPE=$(find $TEAMSPEAK_DIRECTORY -name 'ts3db_mysql.ini' 2> /dev/null | sort | tail -1)

if [[ "$TEAMSPEAK_DATABASE_TYPE" == "" ]]; then
	TEAMSPEAK_DATABASE_TYPE="SQLite"
else
	TEAMSPEAK_DATABASE_TYPE="MySQL"
fi

# Does the INI-File 'ts3server.ini' exist?
if [[ "$TEAMSPEAK_DATABASE_TYPE" == "MySQL" ]]; then
	INI_FILE_NAME=$(basename $(find $TEAMSPEAK_DIRECTORY -name 'ts3server.ini' 2> /dev/null | sort | tail -1))
else
	INI_FILE_NAME="Unknown"
fi

# Get ServerQuery Port, if MySQL-Datebase is used
if [[ "$TEAMSPEAK_DATABASE_TYPE" == "MySQL" ]]; then
	TEAMSPEAK_SERVER_QUERY_PORT=$(cat $TEAMSPEAK_DIRECTORY/ts3server.ini | grep query_port | cut -d "=" -f 2)

	if [[ "$TEAMSPEAK_SERVER_QUERY_PORT" == "" ]]; then
		TEAMSPEAK_SERVER_QUERY_PORT="Unknown"
	fi
else
	TEAMSPEAK_SERVER_QUERY_PORT="10011"
fi

# Get TSDNS PID, if it is running/in use
if [ $(ps opid= -C "tsdnsserver_"$LINUX_OR_FREEBSD"_"$ARCHITECTURE) ]; then
	TSDNS_PID=$(ps opid= -C "tsdnsserver_"$LINUX_OR_FREEBSD"_"$ARCHITECTURE)

	TSDNS_STATUS="Running"
else
	TSDNS_STATUS="Not running"
fi



#########################################
#					#
#	M A I N  P R O G R A M		#
#					#
#########################################

echo "#############################################################";
echo "	Latest version        	: $LATEST_VERSION";
echo "	Installed version     	: $INSTALLED_VERSION";
echo "	Installed architecture	: $ARCHITECTURE";
echo "	Installed binary	: $LINUX_OR_FREEBSD_UPPER_CASE";
echo
echo "	Installation Directory	: $TEAMSPEAK_DIRECTORY";
echo "	Files Owner		: $USER";
echo "	Files Group		: $GROUP";
echo
echo "	Database-Type		: $TEAMSPEAK_DATABASE_TYPE";
if [[ "$TEAMSPEAK_DATABASE_TYPE" == "MySQL" ]]; then
	echo -e "	INI-File		: $INI_FILE_NAME";
fi
echo "	ServerQuery Port	: $TEAMSPEAK_SERVER_QUERY_PORT";
if [[ "$TSDNS_STATUS" == "Running" ]]; then
	echo "	TSDNS			: $TSDNS_STATUS (PID $TSDNS_PID)";
else
	echo "	TSDNS			: $TSDNS_STATUS";
fi
echo -e "#############################################################\n";

if [[ "$LATEST_VERSION" == "Unknown" ]]; then
	echo -e "Could not fetch the latest TeamSpeak 3 server version. Please check for updates of this script!";
	exit 1;
fi

if [[ "$INSTALLED_VERSION" == "Unknown" ]]; then
	echo -e "Could not identify your installed TeamSpeak 3 server version. Please check this manually!\n";
fi

if [[ "$ARCHITECTURE" == "Unknown" ]]; then
	echo -e "Could not identify your installed TeamSpeak 3 server architecture. Please check for updates of this script!";
	exit 1;
fi

if [[ "$TEAMSPEAK_DATABASE_TYPE" == "MySQL" ]]; then
	if [[ "$INI_FILE_NAME" == "Unknown" ]]; then
		echo -e "Could not find INI-File 'ts3server.ini'. It's needed for starting the TeamSpeak 3 server with MySQL database. Please provide this file!";
		exit 1;
	fi
fi

# Check installed version against latest version
# If latest version is not equal installed version ask the user for the update
if [ "$INSTALLED_VERSION" == "$LATEST_VERSION" ] || [ "$INSTALLED_VERSION" == "Unknown" ]; then
	echo -e "Latest version is already installed. Nothing to do..."
else
	# Cronjob function for auto update, if new version is available
	if [ "$1" = "--cronjob-auto-update" ]; then
		ANSWER="yes"
	else
		ANSWER=""
		while [[ "$ANSWER" == "" ]]; do
			read -p "Do you want to update your TeamSpeak 3 server? Please answer: ([y]es/[n]o) " ANSWER;
			if [[ "$ANSWER" != "" ]] && [[ "$ANSWER" != "y" ]] && [[ "$ANSWER" != "yes" ]] && [[ "$ANSWER" != "n" ]] && [[ "$ANSWER" != "no" ]]; then
				echo "Illegal characters, please retry.";
				ANSWER="";
			fi
		done
	fi
fi

# Run the update process, if the user want to
if [[ "$ANSWER" == "y" ]] || [[ "$ANSWER" == "yes" ]]; then
	# Inform online clients, that the server will be updated
	if [ "$3" = "--inform-online-clients" ] && [ "$4" != "" ] || [ "$2" = "--inform-online-clients" ] && [ "$3" != "" ]; then
		if [ "$3" = "--inform-online-clients" ]; then
			SERVERADMIN_PASSWORD=$(cat $4)
		else
			SERVERADMIN_PASSWORD=$(cat $3)
		fi
		(
			echo open localhost $TEAMSPEAK_SERVER_QUERY_PORT
			sleep 2
			echo "login serveradmin $SERVERADMIN_PASSWORD"
			sleep 1
			# Cronjob: Update will wait 5 minutes - inform users with that information
			if [ "$1" = "--cronjob-auto-update" ]; then
				echo "gm msg=The\sserver\swill\sbe\supdated\sin\s5\sminutes.\sYou\swill\sbe\sunable\sto\sconnect\sto\sthe\sserver\sat\sthis\stime.\sPlease\stry\sto\sreconnect\safter\s2-5\sMinutes."
			else
				echo "gm msg=The\sserver\swill\sbe\supdated\sright\snow.\sYou\swill\sbe\sunable\sto\sconnect\sto\sthe\sserver\sat\sthis\stime.\sPlease\stry\sto\sreconnect\safter\s2-5\sMinutes."
			fi
			sleep 1
			echo "logout"
			sleep 1
			echo "quit"
			sleep 1
		) | telnet 2> /dev/zero > /dev/zero || true
	fi

	# Wait 5 minutes, if it is a cronjob
	if [ "$1" = "--cronjob-auto-update" ]; then
		sleep 5m
	fi

	# Build download link for the TeamSpeak 3 server download
	TS3_SERVER_DOWNLOAD_LINK="http://files.teamspeak-services.com/releases/$LATEST_VERSION/teamspeak3-server_$LINUX_OR_FREEBSD-$ARCHITECTURE-$LATEST_VERSION.tar.gz"

	# Stop running TSDNS server, if it is running
	if [[ "$TSDNS_STATUS" == "Running" ]]; then
		echo -e "\nStopping running TSDNS server...\n";

		kill -9 $TSDNS_PID
	fi

	# Stop running TeamSpeak 3 server
	echo
	$TEAMSPEAK_DIRECTORY/ts3server_startscript.sh stop || true
	echo

	# Create Backup of currently installed TeamSpeak 3 server in '/tmp/ts3server_backup'
	echo -e "\nCreating backup of your existing TeamSpeak 3 server (including licensekey and sqlite database)...\n";

	if [ ! -d /tmp/ts3server_backup ]; then
		mkdir /tmp/ts3server_backup
	fi

	if [ "$2" = "--delete-old-logs" ]; then
		rm $TEAMSPEAK_DIRECTORY/logs/ts3server*.log
	fi

	rsync -a --no-inc-recursive --exclude 'files' $TEAMSPEAK_DIRECTORY/ /tmp/ts3server_backup 2> /dev/null

	cd $TEAMSPEAK_DIRECTORY

	# Download latest TS3 Server files
	wget $TS3_SERVER_DOWNLOAD_LINK -q -O teamspeak3-server_$LINUX_OR_FREEBSD-$ARCHITECTURE-$LATEST_VERSION.tar.gz

	echo -e "Your server will be updated right now...\n";
	tar xf teamspeak3-server_$LINUX_OR_FREEBSD-$ARCHITECTURE-$LATEST_VERSION.tar.gz && cp -R teamspeak3-server_$LINUX_OR_FREEBSD-$ARCHITECTURE/* . && rm -rf teamspeak3-server_$LINUX_OR_FREEBSD-$ARCHITECTURE/

	if [ -f /tmp/ts3server_backup/licensekey.dat ]; then
		echo -e "Your licensekey and database will be imported...\n"
		mv /tmp/ts3server_backup/licensekey.dat $TEAMSPEAK_DIRECTORY
	else
		echo -e "Your database will be imported...\n"
	fi

	if [ -f /tmp/ts3server_backup/ts3server.sqlitedb ]; then
		cp -f /tmp/ts3server_backup/ts3server.sqlitedb $TEAMSPEAK_DIRECTORY
	fi

	cp -f /tmp/ts3server_backup/query_ip_*.txt $TEAMSPEAK_DIRECTORY

	# If Database-Type is "MySQL", import MySQL-Database and associated files
	if [[ "$TEAMSPEAK_DATABASE_TYPE" == "MySQL" ]]; then
		cp -f /tmp/ts3server_backup/libts3db_mysql.so $TEAMSPEAK_DIRECTORY
		cp -f /tmp/ts3server_backup/serverkey.dat $TEAMSPEAK_DIRECTORY
		cp -f /tmp/ts3server_backup/ts3db_mysql.ini $TEAMSPEAK_DIRECTORY
		cp -f /tmp/ts3server_backup/ts3server.ini $TEAMSPEAK_DIRECTORY
	fi

	# If TSDNS server was running, import 'tsdns_settings.ini' file
	if [[ "$TSDNS_STATUS" == "Running" ]]; then
		echo -e "Your 'tsdns_settings.ini' will be imported...\n"

		cp -f /tmp/ts3server_backup/tsdns/tsdns_settings.ini $TEAMSPEAK_DIRECTORY/tsdns/
	fi

	if  [ -f ts3server.pid ]; then
		rm ts3server.pid
	fi

	# Delete downloaded TeamSpeak 3 server archive
	rm teamspeak3-server_$LINUX_OR_FREEBSD-$ARCHITECTURE-$LATEST_VERSION.tar.gz 2> /dev/null

	# Change owner and group of files
	chown $USER:$GROUP -R .

	# Start TSDNS, if it was started
	if [[ "$TSDNS_STATUS" == "Running" ]]; then
		echo -e "Starting TSDNS server...\n";

		# Change into TSDNS directory
		cd tsdns/

		su -c "./tsdnsserver_"$LINUX_OR_FREEBSD"_"$ARCHITECTURE" &" $USER

		# Change to root directory of TeamSpeak 3 server
		cd - > /dev/null

		# Sleep for a few seconds
		sleep 5s

		# Check, if the TSDNS server is still running
		if [ $(ps opid= -C "tsdnsserver_"$LINUX_OR_FREEBSD"_"$ARCHITECTURE) ]; then
			TSDNS_PID=$(ps opid= -C "tsdnsserver_"$LINUX_OR_FREEBSD"_"$ARCHITECTURE)

			echo -e "\nYour TSDNS server was started successfull! (PID $TSDNS_PID)\n";
		else
			echo -e "\nYour TSDNS server could NOT be started!\n";
		fi
	fi

	# Start TeamSpeak 3 server
	if [[ "$TEAMSPEAK_DATABASE_TYPE" == "MySQL" ]]; then
		su -c "$TEAMSPEAK_DIRECTORY/ts3server_startscript.sh start inifile=ts3server.ini" $USER
	else
		su -c "$TEAMSPEAK_DIRECTORY/ts3server_startscript.sh start" $USER
	fi

	# Check, if the './ts3server_startscript.sh start' command was successfull
	if [[ $? -eq 0 ]]; then
		echo -e "\nScript is checking TeamSpeak server status...\n";
		# Sleep for a few seconds...
		sleep 5s

		# Check, if TS3 server is still runing
		TS_SERVER_STATUS=$(su -c "$TEAMSPEAK_DIRECTORY/ts3server_startscript.sh status" $USER)

		if [[ "$TS_SERVER_STATUS" == "Server is running" ]]; then
			echo -e "Your server was updated successfull!\n";

			# Delete backup after successfull job
			rm -rf /tmp/ts3server_backup 2> /dev/null
		fi
	else
		echo -e "\nRollback to the version '$INSTALLED_VERSION', because the server could not start.\n";

		# Rollback to old installed version from backup
		rsync -a /tmp/ts3server_backup/ $TEAMSPEAK_DIRECTORY 2> /dev/null && rm -rf /tmp/ts3server_backup 2> /dev/null

		# Start TeamSpeak 3 server
		if [[ "$TEAMSPEAK_DATABASE_TYPE" == "MySQL" ]]; then
			su -c "rm teamspeak3-server_$LINUX_OR_FREEBSD-$ARCHITECTURE-$LATEST_VERSION.tar.gz && $TEAMSPEAK_DIRECTORY/ts3server_startscript.sh start inifile=ts3server.ini" $USER
		else
			su -c "rm teamspeak3-server_$LINUX_OR_FREEBSD-$ARCHITECTURE-$LATEST_VERSION.tar.gz && $TEAMSPEAK_DIRECTORY/ts3server_startscript.sh start" $USER
		fi

		echo -e "\nYour new server version could not started. Deployed backup of version '$INSTALLED_VERSION'.\n";
	fi

	cd - > /dev/null
else
	echo -e "\nYour server was NOT updated.\n";
fi



#########################
#			#
#	Clean up	#
#			#
#########################



echo -e "Cleaning up system...\n";
rm $TEMPFILE_1 $TEMPFILE_2 $TEMPFILE_3 2> /dev/null

echo -e "Finish!\n";

echo "Donations: https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=9A2GVABEUWS92";

exit 0;

