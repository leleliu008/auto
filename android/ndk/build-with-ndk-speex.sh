#!/bin/sh

###################################################################
#注意：请将此脚本放置于源码根目录下
#参考：http://blog.fpliu.com/it/software/Speex/build-for-android
###################################################################

LIB_OGG_NDK_BUILD_DIR="$HOME/libogg-1.3.4/ndk-build"
SPEEXDSP_NDK_BUILD_DIR="$HOME/speexdsp-SpeexDSP-1.2.0/ndk-build"


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
    ./configure \
        --host="$TARGET_HOST" \
        --prefix="$INSTALL_DIR" \
        CC="$CC" \
        CFLAGS="$CFLAGS" \
        CPPFLAGS="" \
        LDFLAGS="" \
        AR="$AR" \
        RANLIB="$RANLIB" \
        OGG_CFLAGS="-I$LIB_OGG_NDK_BUILD_DIR/$TARGET_ABI/include" \
        OGG_LIBS="-L$LIB_OGG_NDK_BUILD_DIR/$TARGET_ABI/lib -logg" \
        SPEEXDSP_CFLAGS="-I$SPEEXDSP_NDK_BUILD_DIR/$TARGET_ABI/include" \
        SPEEXDSP_LIBS="-L$SPEEXDSP_NDK_BUILD_DIR/$TARGET_ABI/lib -lspeexdsp" &&
    make clean &&
    make install
}

download_ndk_helper_if_needed && build_all TARGET_API=21
