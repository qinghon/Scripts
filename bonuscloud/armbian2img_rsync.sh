#!/bin/bash -e
set -e

DEV_EMMC="/dev/mmcblk1"
IMG_PATH="/mnt/armbian_rsync.img"
NOT_HAVE=0
echo "Create armbian images"
if [[ ! -f $IMG_PATH ]]; then
    NOT_HAVE=1
    dd if=/dev/zero of=$IMG_PATH bs=1M seek=2048 count=0

    echo "Start script create MBR and filesystem"

    
    DEV_IMG=$(losetup --find --show -P $IMG_PATH )
    sleep 1
    echo "Start backup u-boot default"

    dd if="${DEV_EMMC}" of=u-boot-default.img bs=1M count=4

    echo "Start create MBR and partittion"

    parted -s "${DEV_IMG}" mklabel msdos
    parted -s "${DEV_IMG}" mkpart primary fat32 4096KB 128M
    parted -s "${DEV_IMG}" mkpart primary ext4 128M 100%

    echo "Start restore u-boot"
    dd if=u-boot-default.img of="${DEV_IMG}" conv=fsync bs=1 count=442
    dd if=u-boot-default.img of="${DEV_IMG}" conv=fsync bs=512 skip=1 seek=1
    echo "Done"
    
    PART_BOOT="${DEV_IMG}p1"
    PART_ROOT="${DEV_IMG}p2"

    echo -n "Formatting BOOT partition..."
    mkfs.vfat -n "BOOT" "$PART_BOOT"
    echo "done."

    echo "Formatting ROOT partition..."
    mke2fs -F -q -t ext4 -L ROOTFS -m 0 "$PART_ROOT"
    e2fsck -n "$PART_ROOT"
    echo "done."
    
else
    NOT_HAVE=0
    DEV_IMG=$(losetup --find --show -P  $IMG_PATH  )
    PART_BOOT="${DEV_IMG}p1"
    PART_ROOT="${DEV_IMG}p2"
fi



sync


echo "Start copy system for eMMC."

mkdir -p /ddbr
chmod 777 /ddbr

DIR_INSTALL="/ddbr/install"

if [ -d $DIR_INSTALL ] ; then
    rm -rf $DIR_INSTALL
fi
mkdir -p $DIR_INSTALL

if grep -q "$PART_BOOT" /proc/mounts ; then
    echo "Unmounting BOOT partiton."
    umount -f "$PART_BOOT"
fi
mount -o rw "$PART_BOOT" $DIR_INSTALL

echo -n "Cppying BOOT..."
cp -r /boot/* $DIR_INSTALL && sync
echo "done."

#echo -n "Edit init config..."
#sed -e "s/ROOTFS/ROOT_EMMC/g" \
# -i "$DIR_INSTALL/uEnv.ini"
#echo "done."

#rm $DIR_INSTALL/s9*
#rm $DIR_INSTALL/aml*

umount $DIR_INSTALL

if grep -q "$PART_ROOT" /proc/mounts ; then
    echo "Unmounting ROOT partiton."
    umount -f "$PART_ROOT"
fi


echo "Copying ROOTFS."

copy_fun(){
    # $1 source path
    # $2 copy to path
    if [[ $NOT_HAVE -eq 1 ]]; then
        tar -cf - $1 | (cd $2; tar -xpf -)
    elif [[ $NOT_HAVE -eq 0 ]] ;then
        rsync -ar $1 $2
    fi
}

mount -o rw "$PART_ROOT" $DIR_INSTALL

cd /
echo "Copy BIN"
#tar -cf - bin | (cd $DIR_INSTALL; tar -xpf -)
copy_fun bin $DIR_INSTALL
#echo "Copy BOOT"
#mkdir -p $DIR_INSTALL/boot
#tar -cf - boot | (cd $DIR_INSTALL; tar -xpf -)
echo "Create DEV"
mkdir -p $DIR_INSTALL/dev
#tar -cf - dev | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy ETC"
copy_fun etc $DIR_INSTALL
echo "Copy HOME"
copy_fun home $DIR_INSTALL
echo "Copy LIB"
copy_fun lib $DIR_INSTALL
echo "Create MEDIA"
mkdir -p $DIR_INSTALL/media
#tar -cf - media | (cd $DIR_INSTALL; tar -xpf -)
echo "Create MNT"
mkdir -p $DIR_INSTALL/mnt
#tar -cf - mnt | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy OPT"
copy_fun opt $DIR_INSTALL
echo "Create PROC"
mkdir -p $DIR_INSTALL/proc
echo "Copy ROOT"
copy_fun root $DIR_INSTALL
echo "Create RUN"
mkdir -p $DIR_INSTALL/run
echo "Copy SBIN"
copy_fun sbin $DIR_INSTALL
echo "Copy SELINUX"
copy_fun selinux $DIR_INSTALL
echo "Copy SRV"
copy_fun srv $DIR_INSTALL
echo "Create SYS"
mkdir -p $DIR_INSTALL/sys
echo "Create TMP"
mkdir -p $DIR_INSTALL/tmp
echo "Copy USR"
copy_fun usr $DIR_INSTALL
echo "Copy VAR"
copy_fun var $DIR_INSTALL

echo "Reset root password"
sed -i '1croot:x:0:0:root:/root:/bin/bash' $DIR_INSTALL/etc/passwd 
sed -i '1croot:x:0:0:root:/root:/bin/bash' $DIR_INSTALL/etc/passwd-
sed -i '1croot:$6$omWEJV4E$LBBsOhiXGFZD2Z5Hdhrq2BxDXKfbKucrbm2jQzYgRbwfHBZbvN4fb/1IdI5HbZ9qRV5fzD4Kav1wy0mprDMvq1:0:0:99999:7:::' $DIR_INSTALL/etc/shadow
sed -i '1croot:$6$omWEJV4E$LBBsOhiXGFZD2Z5Hdhrq2BxDXKfbKucrbm2jQzYgRbwfHBZbvN4fb/1IdI5HbZ9qRV5fzD4Kav1wy0mprDMvq1:0:0:99999:7:::' $DIR_INSTALL/etc/shadow-
#echo "Copy fstab"

#rm $DIR_INSTALL/etc/fstab
#cp -a /root/fstab $DIR_INSTALL/etc/fstab

# rm $DIR_INSTALL/root/install.sh
# rm $DIR_INSTALL/root/fstab
# rm $DIR_INSTALL/usr/bin/ddbr
# rm $DIR_INSTALL/usr/bin/ddbr_backup_nand
# rm $DIR_INSTALL/usr/bin/ddbr_backup_nand_full
# rm $DIR_INSTALL/usr/bin/ddbr_restore_nand

echo "sync to disk"
cd $DIR_INSTALL/
sync
cd /
echo "umount $DIR_INSTALL"
umount $DIR_INSTALL

losetup -d $DEV_IMG
