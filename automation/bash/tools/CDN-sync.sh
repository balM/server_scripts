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
# 					Text color variables
bold=$(tput bold)             	# Bold
red=${txtbld}$(tput setaf 1) 	# Red
blue=${txtbld}$(tput setaf 4) 	# Blue
green=${txtbld}$(tput setaf 2) 	# Green
txtreset=$(tput sgr0)          	# Reset
######################################################################################################
#                 Checking availability of turbolift                  
which turbolift &> /dev/null

[ $? -ne 0 ]  && \
echo "" && \
echo "${red}Turbolift utility is not available ... Install it${txtreset}" &&  \
echo "" && \
echo "${green}Prerequisites :${txtreset}" && \
echo "For all the things to work right please make sure you have python-dev" && \
echo "All systems require the python-setuptools package." && \
echo "Python => 2.6 but < 3.0" && \
echo "A File or some Files you want uploaded" && \
echo "" && \
echo "${green}Installation :${txtreset}" && \
echo "git clone git://github.com/cloudnull/turbolift.git" && \
echo "cd turbolift" && \
echo "python setup.py install" && \
echo "" && \
echo "${red}Script terminated.${txtreset}" && \
exit 1
######################################################################################################
#	GLOBALS

SCRIPT_SOURCE="${BASH_SOURCE[0]}"
SCRIPT_DIR="$( cd -P "$( dirname "$SCRIPT_SOURCE" )" && pwd )"
SCRIPT_NAME="${0##*/}"
shopt -s globstar
_now=$(date +"%Y-%m-%d_%T")     													# display DATE -> year-month-day-hour-minute-seconds

declare LOG_DIR="/var/log/cdn-sync"
declare log_file="$LOG_DIR/CDN-sync_$_now"
declare CDN_log_file="$LOG_DIR/CDN-log"  		# change this
declare log_removed="$LOG_DIR/CDN-remove_$_now"	# change this

# Some default values
CDN_ID=""																			# add your ID
CDN_KEY=""																			# add your API KEY
CDN_REGION=""																		# region (dfw, ord, lon, iad, syd)
CDN_CONTAINER=""
SFTP_CONTAINER="/home/andy/Documents/testing-grounds/turbolift-test"				# change this
SFTP_FILES="$LOG_DIR/sftp-files"					# change this
######################################################################################################
#       Turbolift requires root privileges
ROOT_UID=0             # Root has $UID 0.
E_NOTROOT=101          # Not root user error. 

function check_if_root (){       # is root running the script?
                      
  if [ "$UID" -ne "$ROOT_UID" ]
  then
	echo ""
    echo "$(tput bold)${red}Ooops! Must be root to run this script.${txtreset}"
    echo ""
    #clear
    exit $E_NOTROOT
  fi
} 
######################################################################################################
#       Prepare LOG ENV
function make_log_env(){
	echo ""
	echo "Checking for LOG ENVIRONMENT IN $(tput bold)${green}$LOG_DIR${txtreset}"
		if [ ! -d "$LOG_DIR" ]; then
			echo "$(tput bold)${red}LOG environment not present...${txtreset}" && \
			echo "${green}Creating log environment..."
			if [ `mkdir -p $LOG_DIR` ]; then
				echo "ERROR: $* (status $?)" 1>&2
				exit 1
			else
				# success
				echo "$(tput bold)${green}Success.${txtreset} Log environment created in ${green}$LOG_DIR${txtreset}"
				echo ""
				echo "Moving on...."
				echo ""
			fi
		else
			# success
			echo "$(tput bold)${green}OK.${txtreset} Log environment present in $(tput bold)${green}$LOG_DIR${txtreset}"
			echo ""
			echo "Moving on...."
			echo ""
		fi
}
######################################################################################################
function cdn_sync(){

	#	UPLOAD new files first
	turbolift -u $CDN_ID -a $CDN_KEY --os-rax-auth $CDN_REGION --verbose --colorized upload --sync -s $SFTP_CONTAINER -c $CDN_CONTAINER

	# LIST the files on CDN and save them 
	turbolift -u $CDN_ID -a $CDN_KEY --os-rax-auth $CDN_REGION list -c $CDN_CONTAINER > $log_file
cat >> $CDN_log_file <<EOF
${green}***********************************************************
***	CDN Files - $_now
***********************************************************${txtreset}
EOF

	cat $log_file >> $CDN_log_file	# keep the original CDN-log

	# LIST the current files present on SFTP
	ls $SFTP_CONTAINER > $SFTP_FILES

	# format CDN file list
	tail -n +6 $log_file | head -n -3 > log_file-new && mv log_file-new $log_file
	sed -e 's/|\(.*\)|/\1/' $log_file > CDN-new && mv CDN-new $log_file
	awk -F'|' '{print $2}' $log_file > CDN-new && mv CDN-new $log_file

	# keep the files that are ONLY on CDN and NOT on SFTP in a separate list.
	# this files will be REMOVED
	fgrep -vf $SFTP_FILES $log_file > $log_removed
}
######################################################################################################
main() {
	
	check_if_root
	make_log_env
	cdn_sync

}
main "$@"














