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

#	GLOBALS

SCRIPT_SOURCE="${BASH_SOURCE[0]}"
SCRIPT_DIR="$( cd -P "$( dirname "$SCRIPT_SOURCE" )" && pwd )"
SCRIPT_NAME="${0##*/}"
shopt -s globstar
_now=$(date +"%Y_%m_%d_%T")     													# display DATE -> year-month-day-hour-minute-seconds

declare log_file="/home/andy/Documents/testing-grounds/logs/CDN-sync_$_now" 		# change this
declare log_removed="/home/andy/Documents/testing-grounds/logs/CDN-removed_$_now"	# change this

# Some default values
CDN_ID=""																			# add your ID
CDN_KEY=""																			# add your API KEY
CDN_REGION=""																		# region (dfw, ord, lon, iad, syd)
CDN_CONTAINER=""
SFTP_CONTAINER="/home/andy/Documents/testing-grounds/turbolift-test"				# change this
SFTP_FILES="/home/andy/Documents/testing-grounds/logs/sftp-files"					# change this


#	UPLOAD new files first
turbolift -u $CDN_ID -a $CDN_KEY --os-rax-auth $CDN_REGION --verbose --colorized upload --sync -s $SFTP_CONTAINER -c $CDN_CONTAINER

# LIST the files on CDN and save them 
turbolift -u $CDN_ID -a $CDN_KEY --os-rax-auth $CDN_REGION list -c $CDN_CONTAINER > $log_file

# LIST the current files present on SFTP
ls $SFTP_CONTAINER > $SFTP_FILES

# format CDN file list
tail -n +6 $log_file | head -n -3 > log_file-new && mv log_file-new $log_file
sed -e 's/|\(.*\)|/\1/' $log_file > CDN-new && mv CDN-new $log_file
awk -F'|' '{print $2}' $log_file > CDN-new && mv CDN-new $log_file

# keep the files that are ONLY on CDN and NOT on SFTP in a separate list.
# this files will be REMOVED
fgrep -vf $SFTP_FILES $log_file > $log_removed















