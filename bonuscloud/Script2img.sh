#!/bin/sh

BCLOUD="bcloud"
BXC_bcode=$(cat $BCLOUD/bcode)
BXC_email=$(cat $BCLOUD/email)
MACADDR=`cat /sys/class/net/eth0/address`

mkdir -p /tmp/opt
mkdir -p /tmp/etc/network

cp -r $BCLOUD /tmp/opt
cp /etc/network/interfaces /tmp/etc/network/interfaces

cd /tmp/opt
echo -n "{\"bcode\":\"$BXC_bcode\",\"email\":\"$BXC_email\"}" >$BCLOUD/node.db

SET_MAC=`cat /etc/network/interfaces|grep ^hwaddr|grep -o '\(\w\{2\}:\)\{5\}\w\w'`
if [ -z "$SET_MAC"  -a "$MACADDR" != "$SET_MAC" ]; then
    echo -e "\033[31meth0 mac address Is $MACADDR not equal to set mac $SET_MAC \033[0m"
fi
cd /tmp
MAC_N=`echo "$MACADDR"|sed 's/://g'`
tar -zcvf bcloud-"$MAC_N".tar.gz opt/bcloud etc/network/interfaces

cp bcloud-"$MAC_N".tar.gz /boot/bcloud-"$MAC_N".tar.gz
