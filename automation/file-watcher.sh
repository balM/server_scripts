#!/bin/bash

#
#	We will use incron to watch over a specific folder for any changes
#
#	apt-get install incron
#	
#	by default nobody can run incron, We need to edit /etc/incron.allow and add our user
#
#	Don't forget to create the log file!
#
#	incrontab -e
#
#	/home/andy/test_watch IN_ALL_EVENTS /home/andy/watch_this/file-watcher.sh $@ $# $%
#

logfile=/var/log/file_watcher.log
path=$1
file=$2
event=$3
datetime=`date --rfc-3339=ns`
echo "${datetime} Change made in path: " ${path} >> ${logfile}
echo "${datetime} Change made to file: " ${file} >> ${logfile}
echo "${datetime} Change made due to event: " ${event} >> ${logfile}
echo "${datetime} End" >> ${logfile}
