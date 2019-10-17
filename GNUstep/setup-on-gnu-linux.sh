#!/bin/sh

[ "$(whoami)" = "root" ] || sudo=sudo

Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b\n" "$1"
}

info() {
    msg "${Color_Purple}[❉]${Color_Off} $1$2"
}

# GNUstep的v1版（不支持Objectie-C 2.0）
installViaApt() {
    $sudo apt-get -y update &&
    $sudo apt-get -y install bash make gobjc gnustep gnustep-devel &&
    $sudo sh /usr/share/GNUstep/Makefiles/GNUstep.sh
}

URL=http://ftpmain.gnustep.org/pub/gnustep/core/gnustep-startup-0.32.0.tar.gz
FILENAME=$(basename "$URL")

downloadIfNeed() {
    [ -f "$FILENAME" ] && tar -tf "$FILENAME" > /dev/null 2>&1 && return 0
    info "Downloading $URL"
    curl -C - -LO "$URL"
}

setEnv() {
    str=". /usr/GNUstep/System/Library/Makefiles/GNUstep.sh"
    [ -f "$1" ] && grep "$str" "$1" || return 0
    printf "%s\n" "$str" "$1"
}

# GNUstep的v1版（不支持Objectie-C 2.0）
installViaYum() {
    $sudo yum -y update &&
    $sudo yum -y install bash which make gcc gcc-objc libobjc libjpeg libjpeg-devel libpng libpng-devel libtiff libtiff-devel libxml2 libxml2-devel libX11-devel libXt-devel libxslt libxslt-devel libicu libicu-devel gnutls gnutls-devel libffi-devel
    downloadIfNeed &&
    tar zvxf "$FILENAME" &&
    cd "$(basename "$FILENAME" .tar.gz)" &&
    info "Installing ..." &&
    ./configure &&
    printf "\n\n" | make &&
    $sudo sh /usr/GNUstep/System/Library/Makefiles/GNUstep.sh
    setEnv "$HOME/.bashrc"
    setEnv "$HOME/.zshrc"
}

main() {
    command -v apt-get > /dev/null && {
        installViaApt
        exit
    }
    
    command -v yum > /dev/null && {
        installViaYum
        exit
    }
        
    info "not support your os.";
    exit 1
}

main
