#!/bin/sh

################################################################
#注意：请将此脚本放置于源码根目录下
#参考：http://blog.fpliu.com/it/software/bzip2/build-for-android
################################################################

Color_Red='\033[0;31m'          # Red
Color_Green='\033[0;32m'        # Green
Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b" "$1"
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

download_ndk_helper_if_needed() {
    URL='https://raw.githubusercontent.com/leleliu008/auto/master/android/ndk/ndk-helper.sh'
    [ -f ndk-helper.sh ] || {
        if command -v curl > /dev/null ; then
            info "Downloading $URL...\n" &&
            curl -LO "$URL" &&
            success "Downloaded->$PWD/ndk-helper.sh\n"
        elif command -v wget > /dev/null ; then
            info "Downloading $URL...\n" &&
            wget "$URL" &&
            success "Downloaded->$PWD/ndk-helper.sh\n"
        else
            error_exit "please install curl or wget.\n"
        fi
    }
    source ndk-helper.sh source
}

build() {
    SHARED=1

    make clean > /dev/null 2>&1

    if [ $SHARED -eq 1 ] ; then
        MAKE='make -f Makefile-libbz2_so'
    else
        MAKE='make'
    fi

    eval "$MAKE CC=$CC CFLAGS='-v' AR=$AR RANLIB=$RANLIB" &&
    BINDIR="$INSTALL_DIR/bin" &&
    LIBDIR="$INSTALL_DIR/lib" &&
    mkdir -p "$INSTALL_DIR"/{bin,lib} &&
    cp libbz2.so.*.*.* "$LIBDIR" &&
    cp bzip2-shared "$BINDIR/bzip2"
}

download_ndk_helper_if_needed && build_all TARGET_API=21
