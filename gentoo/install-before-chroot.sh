#!/bin/sh

#------------------------------------------

stage3TarballDownloadUrl=https://mirrors.tuna.tsinghua.edu.cn/gentoo/releases/amd64/autobuilds/current-stage3-amd64

#------------------------------------------

CPUCoreCount=$(grep -c processor /proc/cpuinfo)
jobCount=$((CPUCoreCount + 1))

Color_Red='\033[0;31m'          # Red
Color_Green='\033[0;32m'        # Green
Color_Yellow='\033[0;33m'       # Yellow
Color_Purple='\033[0;35m'       # Purple
Color_Cyan='\033[0;36m'         # Cyan
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b\n" "$1"
}

info() {
    msg "${Color_Purple}[🌺] $1$2${Color_Off}"
}

warn() {
    msg "${Color_Yellow}[🔥] $1$2${Color_Off}"
}

prompt() {
    msg "${Color_Cyan}[🍎] $1$2:${Color_Off}"
}

error() {
    msg "${Color_Red}[✘] $1$2${Color_Off}"
    exit 1
}

errorOnly() {
    msg "${Color_Red}[✘] $1$2${Color_Off}"
}

success() {
    msg "${Color_Green}[✔] $1$2${Color_Off}"
}


#step8
diskPartition() {
    cat > sudo fdisk -t dos /dev/sda <<EOF
d
1
d
2
d
3
d
4
n
p
1
2048
+2M
n
p
2

+4G
n
p
3

+10G
n
e
4

a
1
p
q
EOF
}

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
    mkdir /mnt/gentoo/boot
    mkdir /mnt/gentoo/home

    mount /dev/sda3 /mnt/gentoo
    mount /dev/sda1 /mnt/gentoo/boot
    mount /dev/sda4 /mnt/gentoo/home
}

#step12
checkAndConfigNetwork() {
    prompt "please input SSID"
    read -r ssid
    
    prompt "please input password of $ssid"
    read -r ssid_passwd

    wpa_passphrase "$ssid" "$ssid_passwd" >> /etc/wpa_supplicant.conf &&
    wpa_supplicant -B -c /etc/wpa_supplicant.conf -i lwan0
}

#step13
downloadStage3TarballAndUncompress() {
    stage3Tarball=$(curl $stage3TarballDownloadUrl/ | grep "href=\"stage3-amd64-[0-9]\{8\}T[0-9]\{6\}Z.tar.xz\"" | sed 's/.*href="\([^"]*\)".*/\1/')
    curl -LO "$stage3TarballDownloadUrl/$stage3Tarball" &&
    tar Jvxf "$stage3Tarball" -C /mnt/gentoo
}

#step14
configMakeConf() {
cat >> /mnt/gentoo/etc/portage/make.conf <<EOF
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
    [ -f /etc/wpa_supplicant.conf ] && 
    cp --dereference /etc/wpa_supplicant.conf /mnt/gentoo/etc/wpa_supplicant.conf
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

#step30
exitChroot() {
    exit
}

#step31
unmountAll() {
    umount -l /mnt/gentoo/dev{/shm,/pts,}
    umount -R /mnt/gentoo
}

#step32
restart() {
    reboot
}

main() {
    applyFileSystemToPartitions
    initAndActiveSwapPartition
    mountPartitions
    downloadStage3TarballAndUncompress
    configMakeConf
    configReposConf
    copyDNSInfo
    mountOnTheFly
    changeRoot
    exitChroot
    unmountAll
    restart
}

main "$@"
