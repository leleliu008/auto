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

# 在CentOS中安装GNUstep的v1版（不支持Objectie-C 2.0）
function installGNUstepV1OnCentOS() {
    $role yum -y install make gcc gcc-objc
    $role yum -y install libobjc libjpeg libjpeg-devel libpng libpng-devel libtiff libtiff-devel libxml2 libxml2-devel libX11-devel libXt-devel libxslt libxslt-devel libicu libicu-devel gnutls gnutls-devel
    curl -C - -L -O http://ftpmain.gnustep.org/pub/gnustep/core/gnustep-startup-0.32.0.tar.gz && \
    tar zvxf gnustep-startup-0.32.0.tar.gz && \
    cd gnustep-startup-0.32.0 && \
    ./configure && \
    echo -e "\n" | make && \
    $role bash /usr/GNUstep/System/Library/Makefiles/GNUstep.sh
}

function main() {
    if [ "`uname -s`" == "Darwin" ] ; then
        echo "your os is not GNU/Linux";
        exit 1
    else
        if [ -f "/etc/lsb-release" ] || [ -f "/etc/debian_version" ] ; then
            installGNUstepV1OnUbuntu
        elif [ -f "/etc/redhat-release" ] ; then
            installGNUstepV1OnCentOS
        fi
    fi
}

main
