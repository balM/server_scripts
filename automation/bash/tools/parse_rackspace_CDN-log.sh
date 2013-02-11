#!/bin/bash

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
#       The script will generate CDN stats based on the CDN logs from Rackspace containers.
#       The logs, once enabled, are structured as below:
#       Year |
#               Month |
#                       Day |
#                               Hour |
#                                       log - 9528a3f281064718bf248add5531469d.log.gz
#       94.11.50.16 - - [04/Nov/2012:17:59:26 +0000] "GET /CDN-URL.rackcdn.com/filename HTTP/1.1" 200
######################################################################################################
#                 Checking availability of dialog and pv                     #
######################################################################################################

which dialog &> /dev/null

[ $? -ne 0 ]  && echo "Dialog utility is not available, Install it" && exit 1

which pv &> /dev/null

[ $? -ne 0 ]  && echo "pv (pv utility is not available, Install it." && exit 1
######################################################################################################
#	GLOBALS
shopt -s globstar
_now=$(date +"%Y_%m_%d_%T")     #       display DATE -> year-month-day-hour-minute-seconds
declare -r CDN_folder="/home/andy/CDN_logs"
declare log_file="/home/andy/test_deployment/CDN-total_$_now"   #       save LOG FILE and append current timestamp

######################################################################################################
# Show a progress bar
######################################################################################################
dialog --title "Generating global LOG FILE" --gauge "Parsing file..." 10 100 < <(
   # Get total number of files in array
   count=`find $CDN_folder -name "*.gz" -print | wc -l`

   # set counter - it will increase every-time a file is parsed
   i=0

   #
   # Start the for loop
   #
   # read each file; $file has filename
   for file in $CDN_folder/**/*.gz
   do
      # calculate progress
      PCT=$(( 100*(++i)/count ))

      # update dialog box
cat <<EOF
XXX
$PCT
Parsing file "$file"...
XXX
EOF
  # zcat
   zcat $file >> $log_file
   done
)
