#!/bin/bash

[ `whoami` == "root" ] || role=sudo

# GNUstep的v1版（不支持Objectie-C 2.0）
function installViaApt() {
    $role apt-get -y install make gobjc gnustep gnustep-devel && \
    $role bash /usr/share/GNUstep/Makefiles/GNUstep.sh
}

# GNUstep的v1版（不支持Objectie-C 2.0）
function installViaYum() {
    $role yum -y install make gcc gcc-objc libobjc libjpeg libjpeg-devel libpng libpng-devel libtiff libtiff-devel libxml2 libxml2-devel libX11-devel libXt-devel libxslt libxslt-devel libicu libicu-devel gnutls gnutls-devel
    curl -C - -L -O http://ftpmain.gnustep.org/pub/gnustep/core/gnustep-startup-0.32.0.tar.gz && \
    tar zvxf gnustep-startup-0.32.0.tar.gz && \
    cd gnustep-startup-0.32.0 && \
    ./configure && \
    echo -e "\n" | make && \
    $role bash /usr/GNUstep/System/Library/Makefiles/GNUstep.sh
}

function main() {
    [ "`uname -s`" == "Darwin" ] && {
        echo "your os is Darwin, not GNU/Linux";
        exit 1
    }
    
    command -v apt-get &> /dev/null && {
        installGNUstepV1OnUbuntu
        exit
    }
    
    command -v yum &> /dev/null && {
        installGNUstepV1OnCentOS
        exit
    }
}

main
