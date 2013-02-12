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
declare -r BACKTITLE="TAG: CDN Log Parser"
declare -r CDN_folder="/home/andy/CDN_logs"
declare log_file="/home/andy/test_deployment/CDN-total_$_now"   #       save LOG FILE and append current timestamp
declare TMP_FILE="$(mktemp /tmp/cdn_parser.XXXXX)"  # always use `mktemp`
declare TMP_START_DATE="$(mktemp /tmp/start_date.XXXXX)"
declare TMP_END_DATE="$(mktemp /tmp/end_date.XXXXX)"

######################################################################################################
# Show a progress bar
######################################################################################################
global_log(){
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
#       We have the GLOBAL_LOG_FILE generated.
#       Start to parse the content

#       get the total number of line in file; this = total visits
total_visits=`wc -l < $log_file`

#       get the IP - grouped and sorted; first output the IP with the most visits
cat $log_file | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -n | uniq -c | sort -n -r

# we will use this. For debug purpuse, take 5 seconds break for now....
sleep 5		
}
######################################################################################################
interval_log(){

#       we need to gibe the option of selecting 2 dates
#       1st date - begin LOG
#       2nd date - end LOG

#       Just jump to functions
pick_start
pick_stop

}
##############################################################################
#       Display calendar to allow user to pick the start date
#       Once the date is picked, jump to set_start()
#       If CANCEL is pressed...bad luck... ABORT
pick_start(){
start_date=$(dialog --stdout --calendar "Start date:" 0 0 > $TMP_START_DATE)
return_start_date=$?
start_from=`cat $TMP_START_DATE`
case $return_start_date in
        0) set_start ;;
        1) clear; clean_up; echo "Cancel pressed. Aborting..."; exit 0  ;;
esac
}
##############################################################################
#       Display calendar to allow user to pick the end date
#       Once the date is picked, jump to set_end()
#       If CANCEL is pressed...bad luck... ABORT
pick_stop(){
end_date=$(dialog --stdout --calendar "End date:" 0 0 > $TMP_END_DATE)
return_end_date=$?
end_at=`cat $TMP_END_DATE`

case $return_end_date in
        0) set_end ;;
        1) clear; clean_up; echo "Cancel pressed. Aborting..."; exit 0  ;;
esac
}
##############################################################################
set_start(){
values=( ${start_from//[:\/]/ } )
echo "${values[0]}" >> day
echo "${values[1]}" >> day
echo "${values[2]}" >> day
}
##############################################################################
main() {
while :
do
        dialog --clear --backtitle "$BACKTITLE" --title "Main Menu" \
--menu "Use [UP/DOWN] key to move.Please choose an option:" 15 55 10 \
1 "Generate GLOBAL LOG file" \
2 "Specify a interval for LOG file" \
3 "README" \
4 "Exit" 2> $TMP_FILE

    returned_opt=$?
    choice=`cat $TMP_FILE`

    case $returned_opt in
           0) case $choice in
                  1)  global_log ;;
                  2)  interval_log ;;
                  3)  show_readme  ;;
                  4)  clear; rm -f $TMP_FILE; exit 0;;
              esac ;;
          *)clear ; rm -f $TMP_FILE; exit ;;
    esac
done
}
main "$@"
