#!/bin/sh

MMCPATH="/mnt/mmc"
SSL_PATH="/opt/bcloud"
FILEPATH="/boot/bcloud.tar.gz"
MMC_BLOCK1="/dev/mmcblk1p2"
MMC_BLOCK2="/dev/mmcblk0p2"
MMC_BLOCK3="/dev/mmcblk0"


BXC_SSL_KEY="$MMCPATH$SSL_PATH/client.key"
BXC_SSL_CRT="$MMCPATH$SSL_PATH/client.crt"
BXC_SSL_CA="$MMCPATH$SSL_PATH/ca.crt"


mkdir -p $MMCPATH

if [ -b $MMC_BLOCK1 ]; then
	mount $MMC_BLOCK1 $MMCPATH
elif [ -b $MMC_BLOCK2 ]; then
	echo "found $MMC_BLOCK2"
	mount $MMC_BLOCK2 $MMCPATH
elif [ -b $MMC_BLOCK3 ]; then
	echo "Found $MMC_BLOCK3 and not found $MMC_BLOCK1 or $MMC_BLOCK2"
	mount -o loop,offset=$((512*1619968)) $MMC_BLOCK3 $MMCPATH
else
	echo "emmc  not found"
	exit 1
fi

if [ -d "$MMCPATH"/opt ]; then
	echo "mount emmc success!"
    echo "挂载成功"
else
	echo "mount emmc failed!"
    echo "挂载失败"
fi


func_verif(){
    if [ -e $BXC_SSL_KEY ]; then
        echo "Certificate $BXC_SSL_KEY exist"
    else
        echo -e "\033[31mCertificate $BXC_SSL_KEY not found!\033[0m"
        return 1
    fi
    if [ -e $BXC_SSL_CRT ]; then
        echo "Certificate $BXC_SSL_CRT exist"
    else
        echo -e "\033[31mCertificate $BXC_SSL_CRT not found!\033[0m"
        return 1
    fi
    if [ -e $BXC_SSL_CA ]; then
        echo "Certificate $BXC_SSL_CA exist"
    else
        echo "\033[31mCertificate $BXC_SSL_CA not found!\033[0m"
        return 1
    fi
    return 0
}

backup(){
    cd $MMCPATH/opt
    func_verif 
    res0=`echo $?`
    if [ $res0 -eq 1 ]; then
        echo "\033[31mCertificate not found,end of the installation\033[0m"
        echo "\033[31m 证书文件未找到，结束备份\033[0m"
        exit 1
    fi
    tar -cvzp -f $FILEPATH bcloud 
    res=`echo $?`
    if [ "$res" != 0 ] ;then
        echo "$res"
        echo "$1 failed "
        echo "备份失败"
    else
        echo "$1 success!"
        echo "备份成功"
        echo "backup file save to $FILEPATH"
        echo "备份文件已保存至 $FILEPATH"
    fi
    cd ~
}
restore(){
    tar -xvz -f $FILEPATH -C $MMCPATH/opt 
    func_verif
    res=`echo $?`
    if [ "$res" != 0 ] ;then
        echo "$1 failed "
        echo "\033[31m 证书文件未找到，还原失败\033[0m"
    else
        echo "$1 success!"
        echo "还原成功"
    fi
}

help(){
    echo "Input 'sh $0 backup' or 'sh $0 restore'"
    echo "输入'sh $0 backup' 备份 或者 'sh $0 restore' 还原"
}

case $1 in
    backup )
        backup $1
        ;;
    restore )
        restore $1
        ;;
    * )
        help
        ;;
esac
umount $MMCPATH
