#!/bin/bash

time=`date +%Y%m%d%H%M -d "-15minutes"`
latest_log_filename=$1
########将日志文件重命格式为 filename-`date +%Y%m%d%H%M`####################
function logcut()
{
	echo $latest_log_filename
	mv $latest_log_filename $latest_log_filename-$time

}


function  delete()
{
	cut_time=`ls $latest_log_filename-*  | grep -o '[0-9]\{8\}' | sort -rnu  | wc -l`
	if [ "$cut_time"   -eq 16 ]
	then
		oldest_log_time=`ls $latest_log_filename-*  | grep -o '[0-9]\{8\}' | sort -rnu  | tail -n 1`
		rm -rf  $latest_log_filename-$oldest_log_time*
	fi


}



function main()
{
	delete
	logcut
	pkill -USR1 -f /data/ad/planb/adserver


}

main
