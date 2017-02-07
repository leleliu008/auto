#!/bin/bash

role=""
if [ `whoami` != "root" ] ; then
    role=sudo
fi

# 在Ubuntu中安装GNUstep的v1版（不支持Objectie-C 2.0）
function installGNUstepV1OnUbuntu() {
    $role apt-get -y install make
    $role apt-get -y install gobjc
    $role apt-get -y install gnustep
    $role apt-get -y install gnustep-devel
    $role bash /usr/share/GNUstep/Makefiles/GNUstep.sh
}

function main() {
    if [ `uname -s` = "Darwin" ] ; then
        echo "your os is not GNU/Linux";
        exit 1
    else
        if [ -f "/etc/lsb-release" ] ; then
            installGNUstepV1OnUbuntu
        elif [ -f "/etc/redhat-release" ] ; then
            echo "do nothing"
        fi
    fi
}

main
