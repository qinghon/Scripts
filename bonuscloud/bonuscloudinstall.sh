#!/bin/sh

ARM="https://github.com/hikaruchang/BonusCloud-Node/raw/master/openwrt-ipk/bonuscloud_0.2.2-8o-1_arm_cortex-a9.ipk"
MIPS="https://github.com/hikaruchang/BonusCloud-Node/raw/master/openwrt-ipk/bonuscloud_0.2.2-8o-1_mips_24kc.ipk"
MIPSEL="https://github.com/hikaruchang/BonusCloud-Node/raw/master/openwrt-ipk/bonuscloud_0.2.2-8o-1_mipsel_24kc.ipk"

opkg_init(){
    opkg update
    opkg install wget curl luci-lib-jsonc  liblzo libcurl libopenssl libstdcpp libltdl ca-certificates ca-bundle ip6tables kmod-ip6tables kmod-ip6tables-extra kmod-nf-ipt6 ip6tables-mod-nat ip6tables-extra ip6tables-mod-nat kmod-tun
}

arm_ins(){
    opkg_init
    rm /tmp/bonuscloud*
    cd /tmp&&curl -L -k $ARM -o bonuscloudarm.ipk
    opkg install /tmp/bonuscloudarm.ipk
    res=`echo $?`
    echo "$res"
    if [ "$res" == 0 ]; then 
        echo -e "\033[32m Install Success!\033[0m"
    else
        echo -e "\033[31m Install Failed!\033[0m"
    fi
}
mips_ins(){
    opkg_init
    rm /tmp/bonuscloud*
    cd /tmp&&curl -L -k $MIPS -o bonuscloudmips.ipk
    opkg install /tmp/bonuscloudmips.ipk
    res=`echo $?`
    echo "$res"
    if [ "$res" == 0 ]; then 
        echo -e "\033[32m Install Success!\033[0m"
    else
        echo -e "\033[31m Install Failed!\033[0m"
    fi
}
mipsel_ins(){
    opkg_init
    rm /tmp/bonuscloud*
    cd /tmp&&curl -L -k $MIPSEL -o bonuscloudmipsel.ipk
    opkg install /tmp/bonuscloudmipsel.ipk
    res=`echo $?`
    echo "$res"
    if [ "$res" == 0 ]; then 
        echo -e "\033[32m Install Success!\033[0m"
    else
        echo -e "\033[31m Install Failed!\033[0m"
    fi
}
language_ins(){
    
    read -p "Install language package? like fr , if n exit. default:[zh-cn]: " LANG
    if [ -z $LANG ]; then
        LANG="zh-cn"
    elif [ "$LANG" == "n" -o "$LANG" == "N" ]; then
        exit 0
    fi
    echo "language paskage :  luci-i18n-base-"$LANG""
    opkg install  luci-i18n-base-"$LANG"
    exit 0
}
defult_ins(){
    #echo -e "\033[31m 注意少部分路由器如K2P,新路由3会判断失败，请手动加上参数执行\033[0m "
    #echo -e "比如\n bonuscloudinstall.sh mipsel \n"
    #echo "装错了不要紧，卸载后重新来就好"
    ARM_INFO=`grep arm_ /etc/opkg/distfeeds.conf`
    MIPS_INFO=`grep mips_ /etc/opkg/distfeeds.conf`
    MIPSEL_INFO=`grep mipsel_ /etc/opkg/distfeeds.conf`
    if [ `echo $?` -eq 0 ]; then

        if [ -n "$ARM_INFO" ]; then
            echo -e " the cpu is\033[31m $ARM_INFO\033[0m ,install arm"
            arm_ins
        elif [ -n "$MIPS_INFO" ]; then
            echo -e " the cpu is\033[31m $MIPS_INFO\033[0m ,install mips"
            mips_ins
        elif [ -n "$MIPSEL_INFO" ]; then
            echo -e " the cpu is\033[31m $MIPSEL_INFO\033[0m ,install mipsel"
            mipsel_ins
        else
            echo "you device can not install the package"
        fi
    else
        echo "file not found"
        echo "Are you sure it's openwrt?"
        echo -e "\033[31m Install Failed!\033[0m"
        echo "$MIPSEL_INFO "
    fi
    
}

case $* in
    mips )
        mips_ins
        ;;
    mipsel )
        mipsel_ins
        ;;
    arm )
        arm_ins
        ;;
    lang )
        language_ins
        ;;
    * )
        defult_ins
        ;;
esac
language_ins
