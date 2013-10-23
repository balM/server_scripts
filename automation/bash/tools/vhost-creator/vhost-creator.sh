#!/usr/bin/env bash
#    Copyright (C) 2013 Alexandru Iacob
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
######################################################################################################
#	IMPORTANT: working on DEBIAN based system only (so far)
#	The script will create the vhost file and enable(if user allows) the vhost based on user input.
#	
######################################################################################################
#                 Checking availability of dialog                  


which dialog &> /dev/null

[ $? -ne 0 ]  && echo "Dialog utility is not available ... Install it" && exit 1

######################################################################################################
#	GLOBALS

SCRIPT_SOURCE="${BASH_SOURCE[0]}"
SCRIPT_DIR="$( cd -P "$( dirname "$SCRIPT_SOURCE" )" && pwd )"
SCRIPT_NAME="${0##*/}"
shopt -s globstar
SEQ=/usr/bin/seq
_now=$(date +"%Y_%m_%d_%T")     										# display DATE -> year-month-day-hour-minute-seconds
declare -r BACKTITLE="Simple VHOST Creator"
declare -r VHOST_fd="/etc/apache2/sites-available"						# Default Apache -> DEBIAN based distros
declare -r VHOST_folder="/home/andy/Documents/testing-grounds"			# change this for your environment
declare log_file="/home/andy/Documents/testing-grounds/VHOST_$_now"   	# save LOG FILE and append current timestamp
declare TMP_FILE="$(mktemp /tmp/vhost-creator.XXXXX)"  					# always use `mktemp`

# Some default values
VHOST_PORT=80
APACHE_LOG_DIR="/var/log/apache2"
LOG_LEVEL="warn"
LOG_TYPE="combined"
FOLLOW_SYMLINKS="yes"
ALLOW_DIRECTORY_BROWSING="no"
MULTIVIEWS="yes"
ALLOWOVERRIDE="all"
VHOST_ENABLED="no"


######################################################################################################
ROOT_UID=0             # Root has $UID 0.
E_NOTROOT=101          # Not root user error. 

function check_if_root ()       # is root running the script?
{                      
  if [ "$UID" -ne "$ROOT_UID" ]
  then
	#echo ""
    #echo "Must be root to run this script."
    #echo ""
    dialog --title "Error" --msgbox 'Must be root to run this script.' 6 50
    clear
    exit $E_NOTROOT
  fi
} 
######################################################################################################
function clean_up(){
rm -f $TMP_FILE
}

######################################################################################################
function create_vhost(){
dialog --clear --backtitle "$BACKTITLE" --title "VHOST Creator - OPTIONS" \
	--mixedform "Vhost options : \n(use UP/DOWN to navigate. Use TAB when done)
	\n\nBased on Apache 2.2
	\nCheck http://httpd.apache.org/docs/2.2/ for details
	\n\nNOTE:field limit is restricted to 100 characters" 40 70 0 \
	"Name: " 1 1 "$vhost_name" 1 40 100 0 0 \
	"Port (default 80): " 2 1 "$VHOST_PORT" 2 40 100 0 0 \
	"Server Name:" 3 1 "" 3 40 100 0 0 \
	"Server Alias:" 4 1 "" 4 40 100 0 0 \
	"Document Root:" 5 1 "" 5 40 100 0 0 \
	"Allow directory browsing:" 7 1 "$ALLOW_DIRECTORY_BROWSING" 7 40 100 20 0 \
	"Follow symbolic links:" 8 1 "$FOLLOW_SYMLINKS" 8 40 100 0 0 \
	"Enable content negotiation:" 9 1 "$MULTIVIEWS" 9 40 100 0 0 \
	"AllowOverride (parse .htaccess):" 10 1 "$ALLOWOVERRIDE" 10 40 100 0 0 \
	"ErrorLog ({APACHE_LOG_DIR}/):" 12 1 "$APACHE_LOG_DIR" 12 40 100 0 0 \
	"LogLevel (default warn):" 13 1 "$LOG_LEVEL" 13 40 100 0 0 \
	"CustomLog ({APACHE_LOG_DIR}/):" 14 1 "$APACHE_LOG_DIR" 14 40 100 0 0 \
	"CostomLog type (combined/forwarded):" 15 1 "$LOG_TYPE" 15 40 100 0 0 \
	"ENABLE VHOST? (yes/no):" 17 1 "$VHOST_ENABLED" 17 40 100 0 0 2> $log_file
config_message
#write_vhost
}
######################################################################################################
function config_message(){
#write_vhost

	cd $VHOST_folder

	vhostname=`sed -n '1p' < $log_file`
	vhostport=`sed -n '2p' < $log_file`
	vhostsrvname=`sed -n '3p' < $log_file`
	vhostsrvalias=`sed -n '4p' < $log_file`
	vhostsrvdocroot=`sed -n '5p' < $log_file`
	
	# test if we are going to allow directory traversal
	vhostsrvindexes=`sed -n '6p' < $log_file`
		if [ $vhostsrvindexes = "yes" ]; then 
			vhostsrvindexes="Indexes"
		else
			vhostsrvindexes="-Indexes"
		fi
		
	# test symbolic links
	vhostsrvsymlinks=`sed -n '7p' < $log_file`
		if [ $vhostsrvsymlinks = "yes" ]; then 
			vhostsrvsymlinks="FollowSymLinks"
		else
			vhostsrvsymlinks="-FollowSymLinks"
		fi
		
	# test content negotiation
	vhostsrvmultiviews=`sed -n '8p' < $log_file`
		if [ $vhostsrvmultiviews = "yes" ]; then 
			vhostsrvmultiviews="MultiViews"
		else
			vhostsrvmultiviews="-MultiViews"
		fi
		
	# test allow override
	vhostsrvallowoverride=`sed -n '9p' < $log_file`
		if [ $vhostsrvallowoverride = "all" ]; then 
			vhostsrvallowoverride="All"
		else
			vhostsrvallowoverride="None"
		fi
		
	vhosterrorlog=`sed -n '10p' < $log_file`
	vhostloglevel=`sed -n '11p' < $log_file`
	vhostcustomlog=`sed -n '12p' < $log_file`
	vhostlogtype=`sed -n '13p' < $log_file`
	
	touch $VHOST_folder/$vhostname

#       start to write
cat > $vhostname <<EOF
<VirtualHost *:$vhostport>

#File generated by $BACKTITLE

	ServerName $vhostsrvname
	ServerAlias $vhostsrvalias

        DocumentRoot $vhostsrvdocroot
        <Directory $vhostsrvdocroot>
                Options $vhostsrvindexes $vhostsrvsymlinks $vhostsrvmultiviews
                AllowOverride $vhostsrvallowoverride
                Order allow,deny
                allow from all
        </Directory>

        ErrorLog $vhosterrorlog

        # Possible values include: debug, info, notice, warn, error, crit,
        # alert, emerg.
        LogLevel $vhostloglevel

        CustomLog $vhostcustomlog $vhostlogtype
</VirtualHost>
EOF

# copy the new created VHOST file to the correct location
cp $vhostname $VHOST_fd

# enable VHOST?
vhostenable=`sed -n '14p' < $log_file`
		if [ $vhostenable = "yes" ]; then
			#	enable VHOST
			a2ensite $vhostname
			#	graceful restart
			apache2ctl graceful
		else
			:
		fi

dialog --clear --title "CONFIG MESSAGE" --textbox "$vhostname" 40 100
case $? in
   0)
      :;;
   255)
      :;;
esac	
}
######################################################################################################
main() {
#check_if_root

while :
do

    dialog --clear --backtitle "$BACKTITLE" --title "VHOST Creator - MAIN MENU" \
    --menu "Use [UP/DOWN] key to move" 12 60 6 \
    "NEW" "Create a new VHOSt file" \
    "EXIT"      "Exit program" 2> $TMP_FILE

    retopt=$?
    choice=`cat $TMP_FILE`

    case $retopt in

           0) case $choice in

                  NEW)  create_vhost ;;
                  EXIT) clear; clean_up; exit 0;;
              esac ;;
          *)clear ; clean_up; exit ;;
    esac
done 
}
main "$@"























