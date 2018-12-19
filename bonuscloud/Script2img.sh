#!/bin/sh


MACADDR=`cat /sys/class/net/eth0/address|sed 's/://g'`

begain(){
    mkdir -p /tmp/opt
    mkdir -p /tmp/etc/network

    cp -r $BCLOUD /tmp/opt
    cp /etc/network/interfaces /tmp/etc/network/interfaces
    BXC_bcode=$(cat $BCLOUD/bcode)
    BXC_email=$(cat $BCLOUD/email)
    echo -n "{\"bcode\":\"$BXC_bcode\",\"email\":\"$BXC_email\"}" >$BCLOUD/node.db

    #SET_MAC=`cat /etc/network/interfaces|grep ^hwaddr|grep -o '\(\w\{2\}:\)\{5\}\w\w'`
    #if [ -z "$SET_MAC"  -a "$MACADDR" != "$SET_MAC" ]; then
    #    echo -e "\033[31meth0 mac address Is $MACADDR not equal to set mac $SET_MAC \033[0m"
    #fi
    cd /tmp
    tar -zcvf bcloud-"$MACADDR".tar.gz opt/bcloud etc/network/interfaces
    cp bcloud-"$MACADDR".tar.gz /boot/bcloud-"$MACADDR".tar.gz
}
clean(){
    rm -r /tmp/opt /tmp/etc
}

if [ -n "$1" ]; then
    echo "输入证书路径为 $1"
    BCLOUD=$1
    begain
    clean
else
    BCLOUD=$(find / -name 'bcloud'|grep -v '/opt')
    #BXC_PATH=$(dirname "$BCLOUD")
    if [ -n "$BCLOUD" ]; then
        echo "找到证书路径为 $BCLOUD"
        begain
        clean
    else
        echo "bcloud path not found"
        echo "未找到证书路径"
    fi
fi
