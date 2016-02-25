#!/bin/bash 
#Name: nginx_qps
#Version Number:1.0.0
#Type: calculate qps
#Language: bash shell 
#Date:2016-02-25
#Author: maxpayne
function qps
{
	qps1=`curl -s  http://127.0.0.1/status | awk 'NR == 3{print $NF}'`
	sleep 1
	qps2=`curl -s  http://127.0.0.1/status | awk 'NR == 3{print $NF}'`
	average=`echo $(( $[qps2-qps1]/1 ))`
	echo $average
}
qps
