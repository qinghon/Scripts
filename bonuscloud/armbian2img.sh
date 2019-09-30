#!/bin/bash -e
#!/bin/sh

DEV_IMG=""
IMAGE_PATH="/mnt/armbian.img"
while getopts "f:" opt; do
    case $opt in
        f ) DEV_IMG="$OPTARG"; _SET_DEVICE=1 ;;
        ? ) echo "Unknow arg. exiting";exit 1;;
    esac
done
if [[ -n $DEV_IMG && ! -b $DEV_IMG ]]; then
    exit 2
fi
if [[ -z $DEV_IMG ]]; then
    echo "Create armbian images"

    if [[ -f $IMAGE_PATH ]]; then
        rm $IMAGE_PATH
    fi

    dd if=/dev/zero of=$IMAGE_PATH bs=1M seek=2048 count=0

    echo "Start script create MBR and filesystem"

    #DEV_EMMC=/dev/mmcblk1
    DEV_IMG=$(losetup /dev/loop32 --show $IMAGE_PATH)    
fi

echo "Start backup u-boot default"

dd if=/dev/mmcblk1 of=u-boot-default.img bs=1M count=4

echo "Start create MBR and partittion"

parted -s "${DEV_IMG}" mklabel msdos
parted -s "${DEV_IMG}" mkpart primary fat32 4096kB 138M
parted -s "${DEV_IMG}" mkpart primary ext4 138M 100%

echo "Start restore u-boot"
dd if=u-boot-default.img of="${DEV_IMG}" conv=fsync bs=1 count=442
dd if=u-boot-default.img of="${DEV_IMG}" conv=fsync bs=512 skip=1 seek=1

sync

echo "Done"

echo "Start copy system for image."

mkdir -p /ddbr
chmod 777 /ddbr
PART_BOOT="${DEV_IMG}p1"
PART_ROOT="${DEV_IMG}p2"
if [[ $_SET_DEVICE -eq 1 ]]; then
    PART_BOOT="${DEV_IMG}1"
    PART_ROOT="${DEV_IMG}2"
fi
DIR_INSTALL="/ddbr/install"

if [ -d $DIR_INSTALL ] ; then
    rm -rf $DIR_INSTALL
fi
mkdir -p $DIR_INSTALL

if grep -q "$PART_BOOT" /proc/mounts ; then
    echo "Unmounting BOOT partiton."
    umount -f "$PART_BOOT"
fi
echo -n "Formatting BOOT partition..."
mkfs.vfat -n "BOOT" "$PART_BOOT"
echo "done."

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

echo "Formatting ROOT partition..."
mke2fs -F -q -t ext4 -L ROOTFS -m 0 "$PART_ROOT"
e2fsck -n "$PART_ROOT"
fsck -y $PART_ROOT 
echo "done."

echo "Copying ROOTFS."

mount -o rw "$PART_ROOT" $DIR_INSTALL

cd /
echo "Copy BIN"
tar -cf - bin | (cd $DIR_INSTALL; tar -xpf -)
#echo "Copy BOOT"
#mkdir -p $DIR_INSTALL/boot
#tar -cf - boot | (cd $DIR_INSTALL; tar -xpf -)
echo "Create DEV"
mkdir -p $DIR_INSTALL/dev
#tar -cf - dev | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy ETC"
tar -cf - etc | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy HOME"
tar -cf - home | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy LIB"
tar -cf - lib | (cd $DIR_INSTALL; tar -xpf -)
echo "Create MEDIA"
mkdir -p $DIR_INSTALL/media
#tar -cf - media | (cd $DIR_INSTALL; tar -xpf -)
echo "Create MNT"
mkdir -p $DIR_INSTALL/mnt
#tar -cf - mnt | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy OPT"
tar -cf - opt | (cd $DIR_INSTALL; tar -xpf -)
echo "Create PROC"
mkdir -p $DIR_INSTALL/proc
echo "Copy ROOT"
tar -cf - root | (cd $DIR_INSTALL; tar -xpf -)
echo "Create RUN"
mkdir -p $DIR_INSTALL/run
echo "Copy SBIN"
tar -cf - sbin | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy SELINUX"
tar -cf - selinux | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy SRV"
tar -cf - srv | (cd $DIR_INSTALL; tar -xpf -)
echo "Create SYS"
mkdir -p $DIR_INSTALL/sys
echo "Create TMP"
mkdir -p $DIR_INSTALL/tmp
echo "Copy USR"
tar -cf - usr | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy VAR"
tar -cf - var | (cd $DIR_INSTALL; tar -xpf -)

#echo "Copy fstab"

#rm $DIR_INSTALL/etc/fstab
#cp -a /root/fstab $DIR_INSTALL/etc/fstab

#rm $DIR_INSTALL/root/install.sh
#rm $DIR_INSTALL/root/fstab
#rm $DIR_INSTALL/usr/bin/ddbr
#rm $DIR_INSTALL/usr/bin/ddbr_backup_nand
#rm $DIR_INSTALL/usr/bin/ddbr_backup_nand_full
#rm $DIR_INSTALL/usr/bin/ddbr_restore_nand

echo "umount image"
cd /$DIR_INSTALL
sync
sleep 2
cd /
umount $DIR_INSTALL
losetup -d $DEV_IMG
