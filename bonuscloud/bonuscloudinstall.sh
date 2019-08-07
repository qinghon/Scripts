#!/bin/sh

ARM="https://github.com/hikaruchang/BonusCloud-Node/raw/master/openwrt-ipk/bonuscloud_0.2.2-8o-1_arm_cortex-a9.ipk"
ARM_SNAPSHOT="https://raw.githubusercontent.com/hikaruchang/BonusCloud-Node/master/openwrt-ipk/bonuscloud_0.2.2-9o-snapshot_arm_cortex-a9.ipk"
MIPS="https://github.com/hikaruchang/BonusCloud-Node/raw/master/openwrt-ipk/bonuscloud_0.2.2-8o-1_mips_24kc.ipk"
MIPSEL="https://github.com/hikaruchang/BonusCloud-Node/raw/master/openwrt-ipk/bonuscloud_0.2.2-8o-1_mipsel_24kc.ipk"
MIPSEL_DSP="https://github.com/hikaruchang/BonusCloud-Node/raw/master/openwrt-ipk/bonuscloud_0.2.2-6o-1_mipsel_24kec_dsp.ipk"
opkg_init(){
    opkg update
    opkg install wget curl luci-lib-jsonc  liblzo libcurl libopenssl libstdcpp libltdl ca-certificates ca-bundle ip6tables kmod-ip6tables kmod-ip6tables-extra kmod-nf-ipt6 ip6tables-mod-nat ip6tables-extra ip6tables-mod-nat kmod-tun
}

arm_ins(){
    opkg_init
    rm /tmp/bonuscloud*
    cd /tmp&&curl -L -k $ARM -o bonuscloudarm.ipk
    opkg install /tmp/bonuscloudarm.ipk

    if [ $? -eq 0 ]; then 
        echo -e "\033[32m Install Success!\033[0m"
    else
        echo -e "\033[31m Install Failed!\033[0m"
    fi
}
arm_snapshot_ins(){
    opkg_init
    rm -v /tmp/bonuscloud* 2>/dev/null
    cd /tmp&&wget $ARM_SNAPSHOT -O bonuscloudarm.ipk
    opkg install /tmp/bonuscloudarm.ipk

    if [ $? -eq 0 ]; then 
        echo  "\033[32m Install Success!\033[0m"
    else
        echo  "\033[31m Install Failed!\033[0m"
    fi
}
mips_ins(){
    opkg_init
    rm /tmp/bonuscloud*
    cd /tmp&&curl -L -k $MIPS -o bonuscloudmips.ipk
    opkg install /tmp/bonuscloudmips.ipk
    if [ $? -eq 0 ]; then 
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
    if [ $? -eq 0 ]; then 
        echo -e "\033[32m Install Success!\033[0m"
    else
        echo -e "\033[31m Install Failed!\033[0m"
    fi
}
mipsel_dsp_ins(){
    opkg_init
    rm /tmp/bonuscloud*
    cd /tmp&&curl -L -k $MIPSEL_DSP -o bonuscloudmipsel_dsp.ipk
    opkg install /tmp/bonuscloudmipsel_dsp.ipk
    if [ $? -eq 0 ]; then 
        echo -e "\033[32m Install Success!\033[0m"
    else
        echo -e "\033[31m Install Failed!\033[0m"
    fi
}
language_ins(){
    
    read -r -p "Install language package? like fr , if n exit. default:[zh-cn]: " LANG
    if [ -z $LANG ]; then
        LANG="zh-cn"
    elif [ "$LANG" == "n" -o "$LANG" == "N" ]; then
        exit 0
    fi
    echo "language paskage :  luci-i18n-base-$LANG"
    opkg install  luci-i18n-base-"$LANG"
    exit 0
}
defult_ins(){
    link="https://bonuscloud.club/viewtopic.php?f=15&t=20"
    while :
    do
        clear
        echo "Do you want install what??"
        echo -e "1) \033[31m mips\033[0m  \t AR71xx -->> $link"
        echo -e "2) \033[31m mipsel\033[0m \t MTK -->> $link"
        echo -e "3) \033[31m mipsel_dsp\033[0m\t MTK -->> Pandorabox (\033[31mUnsupported\033[0m)"
        echo -e "4) \033[31m Arm\033[0m    \t BCM53xx -->> $link"
        echo -e "5) \033[31m Arm Snapshot\033[0m BCM53xx -->> $link"
        echo -e "6) Language package for luci"
        echo    "q) Exit"
        read  -r -p "Input you chiose [1-6q]:" chiose
        case $chiose in
            1 ) mips_ins  ;;
            2 ) mipsel_ins  ;;
            3 ) mipsel_dsp_ins ;break ;;
            4 ) arm_ins ; break ;;
            5 ) arm_snapshot_ins ; break ;;
            6 ) language_ins ;;
            q ) exit 0 ;;
        esac
    done
    
}

defult_ins
