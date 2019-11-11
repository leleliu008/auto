#!/bin/sh

#------------------------------------------

stage3Tarball=https://mirrors.tuna.tsinghua.edu.cn/gentoo/releases/amd64/autobuilds/current-stage3-amd64/stage3-amd64-20191106T214502Z.tar.xz
hostname=gentoo
username=fpliu

#------------------------------------------

CPUCoreCount=$(grep processor /proc/cpuinfo | wc -l)
let jobCount="$CPUCoreCount + 1"



#step9
applyFileSystemToPartitions() {
    mkfs.ext4 -T small /dev/sda1
    mkfs.ext4          /dev/sda3
    mkfs.ext4          /dev/sda4
}

#step10
initAndActiveSwapPartition() {
    mkswap /dev/sda2
    swapon /dev/sda2
}

#step11
mountPartitions() {
    mount /dev/sda1 /mnt/gentoo/boot
    mount /dev/sda3 /mnt/gentoo
    mount /dev/sda4 /mnt/gentoo/home
}

#step12
checkAndConfigNetwork() {

}

#step13
downloadStage3TarballAndUncompress() {
    curl -LO "$stage3Tarball" &&
    tar Jvxf "$(basename "$stage3Tarball")" -C /mnt/gentoo
}

#step14
configMakeConf() {
cat > /mnt/gentoo/etc/portage/make.conf <<EOF
GENTOO_MIRRORS="https://mirrors.tuna.tsinghua.edu.cn/gentoo"
MAKEOPTS="-j${jobCount}"
EOF
}

#step15
configReposConf() {
cat > /mnt/gentoo/etc/portage/repos.conf <<EOF
[DEFAULT]
main-repo = gentoo

[gentoo]
location = /usr/portage
sync-type = rsync
sync-uri = rsync://rsync.mirrors.ustc.edu.cn/gentoo-portage/
auto-sync = yes
EOF
}

#step16
copyDNSInfo() {
    cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
}

#step17
mountOnTheFly() {
    mount --types proc /proc /mnt/gentoo/proc

    mount --rbind  /sys /mnt/gentoo/sys
    mount --make-rslave /mnt/gentoo/sys

    mount --rbind  /dev /mnt/gentoo/dev
    mount --make-rslave /mnt/gentoo/dev
}

#step18
changeRoot() {
    chroot /mnt/gentoo /bin/bash
}

#step19
syncPortageTree() {
    emerge --sync
}

#step20
selectProfile() {
    eselect profile set default/linux/amd64/17.1/systemd
}

#step21
updateWorldSet() {
    emerge --ask --verbose --update --deep --newuse @world
}

#step22
setTimeZone() {
    echo "Asia/Shanghai" > /etc/timezone
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}

#step23
genLocales() {
    sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen &&
    locale-gen &&
    eselect locale set en_US.UTF-8 &&
    env-update && source /etc/profile
}

##step24
configfstab() {
    ./genfstab -U >> /mnt/etc/fstab
}

#step24
downloadLinuxKernelSources() {
    emerge sys-kernel/gentoo-sources sys-kernel/genkernel sys-kernel/linux-firmware sys-apps/pciutils
}

#step25
compileLinuxKernelSources() {
    cd /usr/src/linux
    genkernel all
}

#step26
configHostname() {
    gsed -i "s/127.0.0.1\slocalhost/127.0.0.1\\tlocalhost ${hostname}/g" etc/hosts
    gsed -i "s@hostname=\"localhost\"@hostname=\"${hostname}\"@g" etc/conf.d/hostname 
}

#step27
setRootPassword() {
    passwd
}

#step28
newUserAndSetPassword() {
    useradd -m -G wheel -s /bin/bash "$username"
    passwd "$username"
}

#step29
installAndConfigGrub2() {
    emerge sys-boot/grub:2
    grub-install /dev/sda
    grub-mkconfig -o /boot/grub/grub.cfg
}

main() {
    downloadStage3TarballAndUncompress
    configMakeConf
    configReposConf
    copyDNSInfo
    mountSome
    changeRoot
    syncPortageTree
    selectProfile
    updateWorldSet
    setTimeZone
    genLocales
    configfstab
    downloadLinuxKernelSources
    compileLinuxKernelSources
    configHostname
    setRootPassword
    newUserAndSetPassword
    installAndConfigGrub2
}

main "$@"
