#!/bin/bash
# Vars

USERADD=`which useradd` 
USERMOD=`which usermod` 
USERDEL=`which userdel` 
GROUPADD=`which groupadd` 
MACHINE=`uname -m`
ipaddress=`ip route get 8.8.8.8 | awk '{print $NF; exit}'`
changedir=`echo $PWD`

# Functions

function test {
	"$@"
    local status=$?
    if [ $status -ne 0 ]; then
	    redMessage "Password doesn't match. Try again, change user or exit?"
	    OPTIONS=("Try again" "Change User" "Exit")
			select OPTION in "${OPTIONS[@]}"; do
			case "$REPLY" in
				1|2 ) break;;
				3 ) errorQuit;;
				*) errorContinue;;
			esac
		done
		
		if [ "$OPTION" == "Try again" ]; then
			cyanMessage "Type new password."
			
			test passwd $SINUSBOTUSER
		
		elif [ "$OPTION" == "Change User" ]; then
			cyanMessage 'Please enter the name of the sinusbot user. Typically "sinusbot". If it does not exists, the installer will create it.'
			
		    read SINUSBOTUSER
			
			if [ "$SINUSBOTUSER" == "" ]; then
				errorExit "Fatal Error: No sinusbot user specified"
		
				fi
				
			if [ "`id $SINUSBOTUSER 2> /dev/null`" == "" ]; then
				if [ -d /home/$SINUSBOTUSER ]; then
					$GROUPADD $SINUSBOTUSER
					$USERADD -d /home/$SINUSBOTUSER -s /bin/bash -g $SINUSBOTUSER $SINUSBOTUSER
					else
					$GROUPADD $SINUSBOTUSER
					$USERADD -m -b /home -s /bin/bash -g $SINUSBOTUSER $SINUSBOTUSER
				
					fi
			else
			greenMessage "User \"$SINUSBOTUSER\" already exists."
		
			fi
			fi	
		
    fi
    return $status
}

function greenMessage {
    echo -e "\\033[32;1m${@}\033[0m"
}

function magentaMessage {
    echo -e "\\033[35;1m${@}\033[0m"
}

function cyanMessage {
    echo -e "\\033[36;1m${@}\033[0m"
}

function redMessage {
    echo -e "\\033[31;1m${@}\033[0m"
}

function yellowMessage {
	echo -e "\\033[33;1m${@}\033[0m"
}

function errorQuit {
    errorExit "Exit now!"
}

function errorExit {
    redMessage ${@}
    exit 0
}

function errorContinue {
    redMessage "Invalid option."
    return
}

function makeDir {
    if [ "$1" != "" -a ! -d $1 ]; then
        mkdir -p $1
    fi
}

function checkInstall {
    if [ "`dpkg-query -s $1 2>/dev/null`" == "" ]; then
        greenMessage "Installing package $1"
        apt-get install -y $1 2>/dev/null
    fi
}

# Must be root. Checking...

if [ "`id -u`" != "0" ]; then
    cyanMessage "Change to root account required"
    su root
	
	fi 
	
if [ "`id -u`" != "0" ]; then
    errorExit "Still not root, aborting" 
	
	fi

# Start installer
	
if [ -f /etc/debian_version -o -f /etc/centos-release ]; then
	
# What should be done?

	redMessage "What should the Installer do?"
	
	OPTIONS=("Install" "Update" "Remove" "Quit")
	select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1|2|3 ) break;;
            4 ) errorQuit;;
            *) errorContinue;;
        esac
    done
	
	if [ "$OPTION" == "Install" ]; then
		INSTALL="Inst"
	elif [ "$OPTION" == "Update" ]; then
		INSTALL="Updt"
	elif [ "$OPTION" == "Remove" ]; then
		INSTALL="Rem"

	fi

# Check if Sinusbot already installed and if update is possible

if [ "$INSTALL" == "Inst" ]; then
	if [ -f /opt/sinusbot/sinusbot ]; then
	redMessage "Sinusbot already installed!"
	errorQuit

	fi
	fi
	
if [ "$INSTALL" != "Inst" ]; then
	if [ ! -f /opt/sinusbot/sinusbot ]; then
	redMessage "Sinusbot isn't installed!"
	errorQuit
	
	fi
	fi
	
# Check which OS

if [ "$INSTALL" != "Rem" ]; then

	if [ -f /etc/centos-release ]; then
		greenMessage "Installing redhat-lsb! Please wait."
		yum -y -q install redhat-lsb
		greenMessage "Done!"
	
	fi
	
	if [ -f /etc/debian_version ]; then
		greenMessage "Check if lsb-release and debconf-utils is installed..."
		checkInstall debconf-utils
		checkInstall lsb-release
		greenMessage "Done!"
	
	fi
	
# Functions from lsb_release

    OS=`lsb_release -i 2> /dev/null | grep 'Distributor' | awk '{print tolower($3)}'`
    OSBRANCH=`lsb_release -c 2> /dev/null | grep 'Codename' | awk '{print $2}'`
	
# Go on

	if [ "$OS" == "" ]; then
		errorExit "Error: Could not detect OS. Currently only Debian, Ubuntu and CentOS are supported. Aborting!" 
		elif [ ! `cat /etc/debian_version | grep "7"` == "" ]; then
		errorExit "Debian 7 isn't supported anymore!"
		else
		greenMessage "Detected OS $OS"
		
		fi 
		
	if [ "$OSBRANCH" == "" -a ! -f /etc/centos-release ]; then
		errorExit "Error: Could not detect branch of OS. Aborting"
		else
		greenMessage "Detected branch $OSBRANCH" 
		
		fi 
		
	if [ "$MACHINE" == "x86_64" ]; then
		ARCH="amd64"
		else
		errorExit "$MACHINE is not supported!"
		
		fi	
fi
	
# Private usage only!
	
if [ "$INSTALL" != "Rem" ]; then

	redMessage "This Sinusbot version is only for private usage! Accept?"
	
	OPTIONS=("No" "Yes")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1 ) errorQuit;;
            2 ) break;;
            *) errorContinue;;
        esac
    done
	
# Update packages or not
	
	redMessage 'Update the system packages to the latest version? Recommended, as otherwise dependencies might brake! Option "No" = Exit'

    OPTIONS=("Yes" "Try without" "No")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1|2 ) break;;
            3 ) errorQuit;;
            *) errorContinue;;
        esac
    done
		
	greenMessage "Start installer now!"
	sleep 2
	
	if [ "$OPTION" == "Yes" ]; then
    greenMessage "Updating the system in a few seconds silently (no optical output)!"
	sleep 1
	redMessage "This could take a while. Please give it up to 10 minutes!"
	sleep 3
	
	if [ -f /etc/centos-release ]; then
	yum -y -q update && yum -y -q install curl
	else
    apt-get -qq update && apt-get -qq upgrade -y && apt-get -qq install curl -y
	fi
	
	elif [ "$OPTION" == "No" ]; then
	if [ -f /etc/centos-release ]; then
	yum -y -q install curl
	else
	apt-get -qq install curl -y
	
	fi
	fi	
	fi
	
fi

# Remove Sinusbot

if [ "$INSTALL" == "Rem" ]; then

	redMessage "Sinusbot will now be removed completely from your system!"
	yellowMessage "Please enter first the Sinusbotuser!"
	
	read SINUSBOTUSER
	if [ "$SINUSBOTUSER" == "" ]; then
        errorExit "Fatal Error: No sinusbot user specified"
		
		fi
		
	if [ "`id $SINUSBOTUSER 2> /dev/null`" == "" ]; then
		errorExit "User doesn't exist"
		else
		greenMessage "Your Sinusbotuser is \"$SINUSBOTUSER\"? After select Yes it could take a while."
		fi
		
	
	OPTIONS=("Yes" "No")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1 ) break;;
            2 ) errorQuit;;
            *) errorContinue;;
        esac
    done
	
	if [ "`ps ax | grep sinusbot | grep SCREEN`" ]; then
		ps ax | grep sinusbot | grep SCREEN | awk '{print $1}' | while read PID; do
		kill $PID
		done

		fi
		
	if [ "`ps ax | grep ts3bot | grep SCREEN`" ]; then
		ps ax | grep ts3bot | grep SCREEN | awk '{print $1}' | while read PID; do
		kill $PID
		done

		fi

	if [ -f /etc/init.d/sinusbot ]; then
		if [ "`/etc/init.d/sinusbot status | awk '{print $NF; exit}'`" == "UP" ]; then
			su -c "/etc/init.d/sinusbot stop" $SINUSBOTUSER
			su -c "screen -wipe" $SINUSBOTUSER
			update-rc.d -f sinusbot remove >/dev/null 2>&1

		fi
		fi

	grepsinusbotlocation=`find / -path /home -prune -o -name 'sinusbot' -print`
		
	if [ "$grepsinusbotlocation" ]; then
		rm -R $grepsinusbotlocation >/dev/null 2>&1
		greenMessage "Files removed successfully!"
		else
		redMessage "Error while removing files."
				
		fi
	
	redMessage "Remove user \"$SINUSBOTUSER\"?"
	
	OPTIONS=("Yes" "No")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1|2 ) break;;
            *) errorContinue;;
        esac
    done
	
	if [ "$OPTION" == "Yes" ]; then
	pkill -9 -u `id -u $SINUSBOTUSER`
	if [ -f /etc/centos-release ]; then
	userdel -f --remove $SINUSBOTUSER >/dev/null 2>&1
	else
	deluser -f --remove-home $SINUSBOTUSER >/dev/null 2>&1
	fi
	
	if [ "`id $SINUSBOTUSER 2> /dev/null`" == "" ]; then
		greenMessage "User removed successfully!"
		else
		redMessage "Error while removing user!"
		
		fi
	fi
	
	if [ -f /usr/local/bin/youtube-dl ]; then
	redMessage "Remove YoutubeDL?"
	
	OPTIONS=("Yes" "No")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1|2 ) break;;
            *) errorContinue;;
        esac
    done
	
	if [ "$OPTION" == "Yes" ]; then
	rm /usr/local/bin/youtube-dl
	greenMessage "Removed YT-DL successfully!"
	
		fi
	fi
			
	greenMessage "Sinusbot removed completely including all directories."

fi

# TeamSpeak3-Client latest check

if [ "$INSTALL" != "Rem" ]; then
	
	greenMessage "Searching latest TS3-Client build for hardware type $MACHINE with arch $ARCH."
	
	for VERSION in ` curl -s http://dl.4players.de/ts/releases/ | grep -Po '(?<=href=")[0-9]+(\.[0-9]+){2,3}(?=/")' | sort -Vr | head -1`; do
        DOWNLOAD_URL_VERSION="http://dl.4players.de/ts/releases/$VERSION/TeamSpeak3-Client-linux_$ARCH-$VERSION.run"
        STATUS=`curl -I $DOWNLOAD_URL_VERSION 2>&1 | grep "HTTP/" | awk '{print $2}'`
        if [ "$STATUS" == "200" ]; then
            DOWNLOAD_URL=$DOWNLOAD_URL_VERSION
            break
			
			fi
    done
	
	if [ "$STATUS" == "200" -a "$DOWNLOAD_URL" != "" ]; then
        greenMessage "Detected latest TS3-Client version as $VERSION with download URL $DOWNLOAD_URL"
		else
        errorExit "Could not detect latest TS3-Client version"
		
		fi

# Install necessary aptitudes for sinusbot.
	
	magentaMessage "Installing necessary packages! Please wait..."
	
	if [ -f /etc/centos-release ]; then
	yum -y -q install screen x11vnc xvfb libxcursor1 ca-certificates bzip2 psmisc libglib2.0-0
	else
	apt-get -qq install screen x11vnc xvfb libxcursor1 ca-certificates bzip2 psmisc libglib2.0-0 less -y 
	fi
	update-ca-certificates >/dev/null 2>&1

	
	greenMessage "Packages installed!"

# Create/check user for sinusbot.

    cyanMessage 'Please enter the name of the sinusbot user. Typically "sinusbot". If it does not exists, the installer will create it.'
	
    read SINUSBOTUSER
    if [ "$SINUSBOTUSER" == "" ]; then
        errorExit "Fatal Error: No sinusbot user specified"
		
		fi
		
    if [ "`id $SINUSBOTUSER 2> /dev/null`" == "" ]; then
            if [ -d /home/$SINUSBOTUSER ]; then
                $GROUPADD $SINUSBOTUSER
                $USERADD -d /home/$SINUSBOTUSER -s /bin/bash -g $SINUSBOTUSER $SINUSBOTUSER
				else
                $GROUPADD $SINUSBOTUSER
                $USERADD -m -b /home -s /bin/bash -g $SINUSBOTUSER $SINUSBOTUSER
				
				fi
		else
        greenMessage "User \"$SINUSBOTUSER\" already exists."
		
		fi

# Setting password. Recheck if success or not.
	
		if [ "$INSTALL" == "Updt" ]; then
			if [ ! "`getent shadow $SINUSBOTUSER | grep '^[^:]*:.\?:' | cut -d: -f1 2> /dev/null`" == "$SINUSBOTUSER" ]; then
			magentaMessage "Should we change the password of \"$SINUSBOTUSER\"?"
			OPTIONS=("Yes" "No")
			select OPTION in "${OPTIONS[@]}"; do
			case "$REPLY" in
				1|2 ) break;;
				*) errorContinue;;
			esac
			done
			
			if [ "$OPTION" == "Yes" ]; then	
			redMessage "Setting $SINUSBOTUSER password:"
			test passwd $SINUSBOTUSER
			
			fi
			
			if [ "$OPTION" == "No" ]; then
			yellowMessage "Doesn't change the password."
			
			fi
			fi
			fi
			
		if [ "$INSTALL" == "Inst" ]; then
			redMessage "Setting $SINUSBOTUSER password:"
			test passwd $SINUSBOTUSER
			
			fi
			
# Create dirs or remove them.
		
	    ps -u $SINUSBOTUSER | grep ts3client | awk '{print $1}' | while read PID; do
        kill $PID
		done
    if [ -f /opt/sinusbot/ts3client_startscript.run ]; then
        rm -rf /opt/sinusbot/*
		
		fi
	
    makeDir /opt/sinusbot/teamspeak3-client
	
    chmod 750 -R /opt/sinusbot
    chown -R $SINUSBOTUSER:$SINUSBOTUSER /opt/sinusbot
    cd /opt/sinusbot/teamspeak3-client

fi

# Downloading TS3-Client files.

if [ "$INSTALL" != "Rem" ]; then
	
	if [ ! -f ts3client_linux_amd64 ]; then
		greenMessage "Downloading TS3 client files."
		su -c "curl -O -s $DOWNLOAD_URL" $SINUSBOTUSER
		
		fi
	
    if [ ! -f TeamSpeak3-Client-linux_$ARCH-$VERSION.run -a ! -f ts3client_linux_$ARCH ]; then
        errorExit "Download failed! Exiting now!"
  
		fi

# Installing TS3-Client.
	
	if [ -f TeamSpeak3-Client-linux_$ARCH-$VERSION.run ]; then
		greenMessage "Installing the TS3 client."
		redMessage "Read the eula!"
		sleep 1
		yellowMessage 'Do following: Press "ENTER" then press "q" after that press "y" and accept it with another "ENTER".'
		sleep 2
	
		chmod 777 ./TeamSpeak3-Client-linux_$ARCH-$VERSION.run
	
		su -c "./TeamSpeak3-Client-linux_$ARCH-$VERSION.run" $SINUSBOTUSER
	
		cp -R ./TeamSpeak3-Client-linux_$ARCH/* ./
		sleep 2
		rm ./ts3client_runscript.sh
		rm ./TeamSpeak3-Client-linux_$ARCH-$VERSION.run
		rm -R ./TeamSpeak3-Client-linux_$ARCH
	
		greenMessage "TS3 client install done."
		else
		redMessage "TS3 already installed!"
	
		fi
	
fi

# Downloading latest Sinusbot.

if [ "$INSTALL" != "Rem" ]; then

	cd /opt/sinusbot
	
		greenMessage "Downloading latest Sinusbot."
		su -c "curl -O -s https://www.sinusbot.com/dl/sinusbot-beta.tar.bz2" $SINUSBOTUSER
	
	if [ ! -f sinusbot-beta.tar.bz2 -a ! -f sinusbot ]; then
		redMessage "Error while downloading with cURL. Trying it with wget."
		if  [ -f /etc/centos-release ]; then
		yum -y -q install wget
		fi
		su -c "wget -q https://www.sinusbot.com/dl/sinusbot-beta.tar.bz2" $SINUSBOTUSER
		
		fi

	if [ ! -f sinusbot-beta.tar.bz2 -a ! -f sinusbot ]; then
		errorExit "Download failed! Exiting now!"
		
		fi
		
# Installing latest Sinusbot.
		
		greenMessage "Extracting Sinusbot files."
		su -c "tar -xjf sinusbot-beta.tar.bz2" $SINUSBOTUSER
		rm -f sinusbot-beta.tar.bz2
	
		cp plugin/libsoundbot_plugin.so /opt/sinusbot/teamspeak3-client/plugins
	
		chmod 755 sinusbot
		
		if [ "$INSTALL" == "Inst" ]; then
		greenMessage "Sinusbot installation done."
		elif [ "$INSTALL" == "Updt" ]; then
		greenMessage "Sinusbot update done."
		fi

	if [ ! -f /etc/init.d/sinusbot ]; then
		cd /etc/init.d
		curl -O -s https://raw.githubusercontent.com/Xuxe/Sinusbot-Startscript/master/sinusbot
		sed -i 's/USER="mybotuser"/USER="'$SINUSBOTUSER'"/g' /etc/init.d/sinusbot
		sed -i 's/DIR_ROOT="\/opt\/ts3soundboard\/"/DIR_ROOT="\/opt\/sinusbot\/"/g' /etc/init.d/sinusbot
	
		chmod +x /etc/init.d/sinusbot
		update-rc.d sinusbot defaults >/dev/null 2>&1
		
		greenMessage 'Installed init.d file to start the Sinusbot with "/etc/init.d/sinusbot {start|stop|status|restart|console|update|backup}"'
		
		else
		redMessage "/etc/init.d/sinusbot already exists!"
		
		if [ `/etc/init.d/sinusbot status | awk '{print $NF; exit}'` == "UP" ]; then
		redMessage "Sinusbot stopping now!"
		/etc/init.d/sinusbot stop
		su -c "screen -wipe" $SINUSBOTUSER
		update-rc.d -f sinusbot remove >/dev/null 2>&1
		else
		greenMessage "Sinusbot already stopped."

		fi
		
		fi

if [ "$INSTALL" == "Inst" ]; then
	
	if [ ! -f /opt/sinusbot/config.ini ]; then
		echo 'ListenPort = 8087 
		ListenHost = "0.0.0.0" 
		TS3Path = "/opt/sinusbot/teamspeak3-client/ts3client_linux_amd64"
		YoutubeDLPath = ""'>>/opt/sinusbot/config.ini
		greenMessage "Config.ini created successfully."
		else
		redMessage "Config.ini already exists or creation error!"
		
		fi
	
fi
	
	if [ `grep -c 'youtube' /etc/crontab` -ge 1 ]; then
		sed -i '/\0 \0 \* \* \* youtube-dl -U >\/dev\/null 2>&1/d' /etc/crontab
		redMessage "Removed old YT-DL cronjob."
		
		fi
		
	if [ `grep -c 'sinusbot' /etc/crontab` -ge 1 ]; then
		sed -i '/\0 \0 \* \* \* su "$SINUSBOTUSER" sinusbot -update >\/dev\/null 2>&1/d' /etc/crontab
		redMessage "Removed old Sinusbot cronjob."
		
		fi
	
	if [ `grep -Pq 'sinusbot' /etc/cron.d/sinusbot &>/dev/null` ]; then
		redMessage "Cronjob already set for Sinusbot updater!"
		else
		greenMessage "Inject Cronjob for automatic Sinusbot update..."
		echo "0 0 * * * su $SINUSBOTUSER /opt/sinusbot/sinusbot -update >/dev/null 2>&1">/etc/cron.d/sinusbot
		greenMessage "Inject Sinusbot update cronjob successful."
		
		fi	
	
fi		

# Installing YT-DL.

if [ "$INSTALL" != "Rem" ]; then

	if [ ! -f /usr/local/bin/youtube-dl ]; then
	redMessage "Should YT-DL be installed?"
	OPTIONS=("Yes" "No")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1|2 ) break;;
            *) errorContinue;;
        esac
    done
	
	if [ "$OPTION" == "Yes" ]; then
	greenMessage "Installing YT-Downloader now!"
	
	if [ "`grep -c 'youtube' /etc/cron.d/sinusbot`" -ge 1 ]; then
		redMessage "Cronjob already set for YT-DL updater!"
		else
		greenMessage "Inject Cronjob for automatic YT-DL update..."
		echo "0 0 * * * youtube-dl -U >/dev/null 2>&1">>/etc/cron.d/sinusbot
		greenMessage "Inject successful."
		
		fi
		
	if [ "$INSTALL" != "Rem" ]; then
		sed -i 's/YoutubeDLPath = \"\"/YoutubeDLPath = \"\/usr\/local\/bin\/youtube-dl\"/g' /opt/sinusbot/config.ini
		
		fi
	
	curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl 2> /dev/null
	chmod a+rx /usr/local/bin/youtube-dl
		
	youtube-dl -U
	
	fi
	
	else
	redMessage "YouTube-DL already installed. Checking for updates."
	youtube-dl -U
	fi
		
# Creating Readme
	
	if [ ! -a "/opt/sinusbot/README_installer.txt" ]; then
	echo '##################################################################################
# #
# Usage: /etc/init.d/sinusbot {start|stop|status|restart|console|update|backup} #
# - start: start the bot #
# - stop: stop the bot #
# - status: display the status of the bot (down or up) #
# - restart: restart the bot #
# - console: display the bot console #
# - update: runs the bot updater (with start & stop)
# - backup: archives your bot root directory
# To exit the console without stopping the server, press CTRL + A then D. #
# #
##################################################################################'>>/opt/sinusbot/README_installer.txt
	fi

# Starting Sinusbot first time!
	
	greenMessage 'Starting the Sinusbot. For first time.'
	cd /opt/sinusbot

# Password variable
	
	password=`./sinusbot --initonly -RunningAsRootIsEvilAndIKnowThat | awk '/password/{ print $10 }' | tr -d "'"`
	chown -R $SINUSBOTUSER:$SINUSBOTUSER /opt/sinusbot
	rm /tmp/.X11-unix/X40
	greenMessage "Done"

# Starting bot	

	greenMessage "Starting Sinusbot again. Your admin password = '$password'"
	/etc/init.d/sinusbot start
	yellowMessage "Please wait... This will take some seconds!"
	sleep 5

# If startup failed, the script will start normal sinusbot without screen for looking about errors. If startup successed => installation done.
	
	if [ `/etc/init.d/sinusbot status | awk '{print $NF; exit}'` == "DOWN" ]; then
		redMessage "Sinusbot could not start! Starting it without screen. Look for errors!"
		su -c "/opt/sinusbot/sinusbot" $SINUSBOTUSER
		
		else

		if [ "$INSTALL" == "Inst" ]; then
		greenMessage "Install done!"
		elif [ "$INSTALL" == "Updt" ]; then
		greenMessage "Update done!"
		
		fi
		
		if [ ! -a "/opt/sinusbot/README_installer.txt" ]; then
		yellowMessage 'Generated a README_installer.txt in /opt/sinusbot with all commands for the sinusbot...'
		
		fi
		
		greenMessage 'All right. Everything is installed successfully. Sinusbot is UP on "'$ipaddress':8087" :) Your login is user = "admin" and password = "'$password'"'
		redMessage 'Stop it with "/etc/init.d/sinusbot stop".'
		cyanMessage 'Also you can enter "/etc/init.d/sinusbot help" for help ;)'
		magentaMessage "Don't forget to rate this script on: https://forum.sinusbot.com/resources/sinusbot-installer-script.58/"
		greenMessage "Thank you for using this script! :)"
		
		fi
	
fi

# remove installer
		
	cd $changedir
	rm $0
	
exit 0
