#!/bin/bash
#OTT id meta info sync script
#author zzh <hezhouzhou@e.hunantv.com
#date 20150918

# Ad Db config
local_host='10.200.8.147'
local_db='vic'
local_user='ad'
local_pw='ad'


# Asset Db config
remote_host='10.1.201.84'
remote_db='mgboss'
remote_user='ggmz'
remote_pw='ggmz!^*'
mysql_bin="mysql"

mysql_cmd_local="$mysql_bin -h${local_host} -u${local_user} -p${local_pw} ${local_db}"
#mysql_cmd_local="mysql -h${local_host} -u${local_user}  ${local_db}"
mysql_cmd_remote="$mysql_bin -h${remote_host} -u${remote_user}  -p${remote_pw} ${remote_db}"


OTT_PLATFORM_ID=$($mysql_cmd_local -N -e "select id from v_platform where name='OTT'")
[[ "$OTT_PLATFORM_ID" == "2" ]] || (ehco "ott platform id changed, please check"; exit 1)

OTT_KIND_ID=16 # get by select * from asset_tag_type;
OTT_AREA_TYPE=3 # get by select * from asset_tag_type;
SP_ID_OTT=7 #spid： get by 7代表ott  9代表pc

# get channels from remote
#return fstlvId fstlvName desp
function OTT_Channel() {
    results="$($mysql_cmd_remote -N -e "select fstlvlId, fstlvlName, \`desc\` from sp_fstlvl_types ")"
    echo "$results"
}

#ott second type channel->type
#param channel_id
function OTT_type() {
    id=$1
    results="$($mysql_cmd_remote -N -e "select fstlvlId, tagId,tagName from asset_tags where typeId=$OTT_KIND_ID and fstlvlId=$id")"
    echo "$results"
}

#return tagId tagName
function OTT_Areaa(){
    results="$($mysql_cmd_remote -N -e "select tagId, tagName from asset_tags where typeId=$OTT_AREA_TYPE")"
    echo "$results"
}

# insert data into v_category
#param id, parent_id, name
function Insert2Category() {
    id=$1
    parent_id=$2
    name=$3
    sql="INSERT INTO v_category(platform,id,parent_id,name) (SELECT $OTT_PLATFORM_ID,'$id', '$parent_id','$name' FROM v_category WHERE NOT EXISTS(SELECT id FROM v_category WHERE v_category.platform=$OTT_PLATFORM_ID AND v_category.id='$id' and v_category.parent_id='$parent_id') limit 1)"
    echo $sql
    $mysql_cmd_local -e "$sql"
}

#insert data into v_area
#param id,name
function Insert2Area(){
    id=$1
    name=$2
    echo "INSERT INTO v_area(platform,id,name)(select $OTT_PLATFORM_ID,'$id','$name' from v_area WHERE NOT EXISTS(SELECT id from v_area where v_area.platform=$OTT_PLATFORM_ID AND v_area.id='$id') limit 1)"| $mysql_cmd_local
}

#clean all data that can be insert by this script
function clean(){
    echo "clean all data"
    $mysql_cmd_local -e "delete from v_category where platform='$OTT_PLATFORM_ID'"
    $mysql_cmd_local -e "delete from v_area where platform='$OTT_PLATFORM_ID'"
}

#import channel type
function sync_channel()
{
    echo "start sync channel"
    OTT_Channel | while read  fstlvlId fstlvlName desc ; do\
        echo $fstlvlName;\
        Insert2Category $fstlvlId 0 $fstlvlName;\
    done 
}

#import area
function sync_area()
{
    echo "start sync area"
    OTT_Areaa  | while read tagId tagName ; do \
        echo $tagName ;\
        Insert2Area $tagId $tagName;\
    done
}


#import type
function sync_second_type(){
    echo "start sync types"
    OTT_Channel | while read id name desc ;do\
    OTT_type $id | while read pid tagId tagName; do\
    Insert2Category $tagId $pid $tagName;\
    done;\
    done
}

function usage() {
    echo "Usage sh ${DIR_NAME}/$0 {update|clean|sync_area|sync_channel|sync_type}"
    echo -n "sync OTT meta type info from asset DB to Ad Db,"
    echo "U can modify the related config at the script header"
    echo "param:"
    echo "      update: 同步频道、类型、地域信息"
    echo "      clean 删除ott 相关的此类信息"
    echo "      sync_area 同步地域id"
    echo "      sync_channel 同步频道id"
    echo "      sync_type 同步二级分类id"
    
}

#################
#   main
#################

case $1 in
    sync_area)
        sync_area
        ;;
    sync_channel)
        sync_channel
        ;;
    sync_type)
        sync_second_type
        ;;
    clean)
        clean
        ;;
    update)
        sync_channel
        sync_second_type
        sync_area
        ;;
    *)
        usage
        ;;
esac

