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
    wpa_supplicant -B -c/etc/wpa_supplicant.conf -lwan0
}

#step13
downloadStage3TarballAndUncompress() {
    stage3Tarball=$(curl $stage3TarballDownloadUrl/ | grep "href=\"stage3-amd64-[0-9]\{8\}T[0-9]\{6\}Z.tar.xz\"" | sed 's/.*href="\([^"]*\)".*/\1/')
    curl -LO "$stage3TarballDownloadUrl/$stage3Tarball" &&
    tar Jvxf "$stage3Tarball" -C /mnt/gentoo
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
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}

#step23
genLocales() {
    sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen &&
    locale-gen &&
    eselect locale set en_US.UTF-8 &&
    env-update && . /etc/profile
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
    cd /usr/src/linux || exit
    genkernel all
}

#step26
configHostname() {
    prompt "please set hostname:"
    read -r hostname
    sed -i "s/127.0.0.1\slocalhost/127.0.0.1\\tlocalhost ${hostname}/g" etc/hosts
    sed -i "s@hostname=\"localhost\"@hostname=\"${hostname}\"@g" etc/conf.d/hostname 
}

#step27
setRootPassword() {
    passwd
}

#step28
newUserAndSetPassword() {
    prompt "please set none-root username:"
    read -r username
    useradd -m -G wheel -s /bin/bash "$username"
    passwd "$username"
}

#step29
installAndConfigGrub2() {
    emerge sys-boot/grub:2
    grub-install /dev/sda
    grub-mkconfig -o /boot/grub/grub.cfg
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
    exitChroot
    unmountAll
    restart
}

main "$@"
