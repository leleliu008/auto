#!/bin/sh

Color_Red='\033[0;31m'          # Red
Color_Green='\033[0;32m'        # Green
Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b\n" "$@"
}

info() {
    msg "${Color_Purple}[❉] $@${Color_Off}"
}

success() {
    msg "${Color_Green}[✔] $@${Color_Off}"
}

error_exit() {
    msg "${Color_Red}[✘] $@${Color_Off}"
    exit 1
}

download() {
    URL='https://raw.githubusercontent.com/leleliu008/auto/master/android/ndk/ndk-pkg'
    
    INSTALL_DIR=/usr/local/bin
    [ -d "$INSTALL_DIR" ] || mkdir -p /usr/local/bin
    output="$INSTALL_DIR/ndk-pkg"
    cd "$INSTALL_DIR"

    if command -v curl > /dev/null ; then
        info "Downloading $URL..." &&
        curl -LO "$URL" &&
        success "Downloaded->$output"
    elif command -v wget > /dev/null ; then
        info "Downloading $URL..." &&
        wget "$URL" &&
        success "Downloaded->$output"
    else
        error_exit "please install curl or wget."
    fi
}

download && success "Done."
