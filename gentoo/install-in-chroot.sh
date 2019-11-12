#!/bin/sh

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

main() {
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
}

main "$@"
