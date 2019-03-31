#!/bin/bash
# bxc certificate backup script for Phicomm n1 
#https://github.com/qinghon/Scripts/issues

MMCPATH="/mnt/mmc"
SSL_PATH="opt/bcloud"
MAC_ADDR=$(cat /sys/class/net/eth0/address |sed -e s/://g)
FILEPATH="/boot/bcloud-$MAC_ADDR.tar.gz"
MMC_BLOCK1="/dev/mmcblk1p2"
MMC_BLOCK2="/dev/mmcblk0p2"
MMC_BLOCK3="/dev/mmcblk0"

mnt(){
    mkdir -p $MMCPATH
    if [ -b $MMC_BLOCK1 ]; then
    	mount -t ext4 $MMC_BLOCK1 $MMCPATH
    elif [ -b $MMC_BLOCK2 ]; then
    	echo "found $MMC_BLOCK2"
    	mount -t ext4 $MMC_BLOCK2 $MMCPATH
    elif [ -b $MMC_BLOCK3 ]; then
    	echo "Found $MMC_BLOCK3 and not found $MMC_BLOCK1 or $MMC_BLOCK2"
    	mount -t ext4 -o loop,offset=$((512*1619968)) $MMC_BLOCK3 $MMCPATH
    else
    	echo "emmc  not found"
    	exit 1
    fi
}

func_verif(){
    BXC_SSL_KEY="$MMCPATH/$SSL_PATH/client.key"
    BXC_SSL_CRT="$MMCPATH/$SSL_PATH/client.crt"
    BXC_SSL_CA="$MMCPATH/$SSL_PATH/ca.crt"
    NODE_INFO="$MMCPATH/$SSL_PATH/node.db"
    if [ -e $BXC_SSL_KEY ]; then
        echo "Certificate $BXC_SSL_KEY exist"
    else
        echo -e "\033[31mCertificate $BXC_SSL_KEY not found!\033[0m"
    fi
    if [ -e $BXC_SSL_CRT ]; then
        echo "Certificate $BXC_SSL_CRT exist"
    else
        echo -e "\033[31mCertificate $BXC_SSL_CRT not found!\033[0m"
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
    cd $MMCPATH/
    func_verif 
    res0=`echo $?`
    if [ $res0 -eq 1 ]; then
        echo "\033[31mCertificate not found,end of the installation\033[0m"
        echo "\033[31m 证书文件未找到，结束备份\033[0m"
        exit 1
    fi
    tar -cvzp -f $FILEPATH $SSL_PATH/client.key $SSL_PATH/client.crt $SSL_PATH/ca.crt $SSL_PATH/node.db etc/network/interfaces
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
    BCLOUD_FILE=$(ls /boot/bcloud* |head -n 1 )
    echo "本次还原的证书文件名为 $BCLOUD_FILE "
    fopt=`tar -tf ${BCLOUD_FILE}|grep -q opt;echo $?`
    if [[ ${fopt} -ne 0 ]]; then
        tar -C $MMCPATH/opt/ -xvz -f $BCLOUD_FILE  bcloud/{node.db,ca.crt,client.key,client.crt}
    else
        tar -C $MMCPATH/ -xvz -f $BCLOUD_FILE  opt/bcloud/{node.db,ca.crt,client.key,client.crt} etc/network/interfaces
    fi
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
changemac(){
    dialog --clear --title "Input MAC"  --inputbox "Please input  MAC,like 12:34:56:78:9A:BC" 15 40 2>/tmp/inputmac.txt
    input_mac=$(cat /tmp/inputmac.txt|egrep -o '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}')
    if [[ -n "$input_mac" ]]; then
        sed -i '/^hwaddress.*#script$/'d $MMCPATH/etc/network/interfaces
        sed -i "/^iface.*eth0/a\hwaddress ether $input_mac  #script" $MMCPATH/etc/network/interfaces
    else
        echo -e "input error. \n输入错误"
    fi
}

help(){
    if  which dialog>/dev/null ;then
        dialog --clear --title "Action choice" --menu "choose one" 12 35 5 1 "backup(备份)" 2 "restore(还原)" 3 "only mount" 4 "Change(修改) eth0 MAC" 2>/tmp/choose
        ret=$(cat /tmp/choose )
        case $ret in
            1 )
                backup
                ;;
            2 )
                restore
                ;;
            3 )
                echo "emmc mounted!!you can free operation"
                exit
                ;;
            4 )
                changemac
                ;;
            * )
                exit
                ;;
        esac
    else
        echo "Input 'sh $0 backup' or 'sh $0 restore'"
        echo "输入'sh $0 backup' 备份 或者 'sh $0 restore' 还原"
    fi
    
}
ret_m=`df |grep 'mmcblk'|head -n 1|awk '{print $6}'` 
if [ "$ret_m" = "/"  ]; then
    MMCPATH="/"
else
    mnt
fi
if [ -d "$MMCPATH"/opt/bcloud ]; then
    echo "mount emmc success!"
    echo "挂载成功"
else
    echo "mount emmc failed!"
    echo "挂载失败"
    exit 1
fi

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
if [ "$MMCPATH" != "/" ]; then
    umount $MMCPATH
fi
