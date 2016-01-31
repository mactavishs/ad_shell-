#!/bin/bash
# Name:log_backup
# Version Number:1.00
# Type:backup
# Language: bash shell
# Date: 2016-02-01
# Author:maxpayne



time=`date --date="1 days ago" +%Y%m%d`

if [[ "$1" == "adserver" ]]
then
	ip_array=(10.100.2.4 10.100.2.5 10.100.2.7 10.100.2.83 10.100.2.84) #adserver机器
	src_dir="/data/ad/planb/log/"
	src_log_filename_prefix="adserver.log-"

elif [[ "$1" == "log.da" ]]
then
	ip_array=(10.100.2.121 10.100.2.122 10.100.2.123) #log.da机器
	src_dir="/data/logs/ad/nginx/log.da.hunantv.com/access/"
	src_log_filename_prefix="log.da.hunantv.com-access.log-"

elif [[ "$1" == "y.da" ]]
then
	ip_array=(10.100.2.51 10.100.2.53 10.100.2.54) #y.da机器
	src_dir="/data/logs/ad/nginx/y.da.hunantv.com/access/"
	src_log_filename_prefix="y.da.hunantv.com-access.log-"
fi

src_log_filename="${src_dir}${src_log_filename_prefix}${time}*"







##########同步数据方法##########
for ip in  ${ip_array[*]}
do
	local_dir="/data8/${ip}/${time}/"
	mkdir -p $local_dir
	rsync -av  ${ip}:${src_log_filename}  $local_dir
	[[ "$?" -ne 0 ]] &&   /opt/script/shell/log_backup/send_mail.sh "${ip}:数据传输失败" || /opt/script/shell/log_backup/send_mail.sh "${ip}:${1}日志数据传输成功" #若数据传输失败或成功,则发邮件
	md5sum ${local_dir}${1}* >> /opt/script/shell/log_backup/local${1}.txt
	ssh ${ip} "md5sum ${src_log_filename}"  >>/opt/script/shell/log_backup/${1}.txt
	[[ "`md5sum /opt/script/shell/log_backup/${1}.txt`" == "`md5sum  /opt/script/shell/log_backup/local${1}.txt`" ]] && /opt/script/shell/log_backup/send_mail.sh "${ip}:${1}md5校验成功" || /opt/script/shell/log_backup/send_mail.sh "${ip}:${1}md5校验失败" #校验数据
	echo '' > /opt/script/shell/log_backup/local${1}.txt
	echo '' > /opt/script/shell/log_backup/${1}.txt
done
