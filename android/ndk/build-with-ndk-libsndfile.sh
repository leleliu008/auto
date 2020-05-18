#!/bin/sh

###################################################################
#注意：请将此脚本放置于源码根目录下
#参考：http://blog.fpliu.com/it/software/libsndfile/build-for-android
###################################################################

#将下面4个变量的值修改为符合你的实际
#不需要的话，设置为空字符串
LIB_OGG_NDK_BUILD_DIR="$HOME/libogg-1.3.4/ndk-build"
LIB_VORBIS_NDK_BUILD_DIR="$HOME/vorbis-1.3.6/ndk-build"
FLAC_NDK_BUILD_DIR="$HOME/flac-1.3.3/ndk-build"
SQLITE_NDK_BUILD_DIR="$HOME/sqlite/ndk-build"


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

check_and_set() {
    [ -z "$1" ] || {
        [ -d "$1" ] || error_exit "$1 is not a directory\n"
        PREFIX="$1/$TARGET_ABI"
        [ -d "$PREFIX" ] || error_exit "$PREFIX is not a directory\n"
        CFLAGS="$CFLAGS -I$PREFIX/include -L$PREFIX/lib $2"
    }
}

build() {
    CONFIGURE_CMD="./configure --host='$TARGET_HOST' --prefix='$INSTALL_DIR' --disable-test-coverage --disable-octave"

    if [ -n "$LIB_OGG_NDK_BUILD_DIR" ] || [ -n "$LIB_VORBIS_NDK_BUILD_DIR" ] || [ -n "$FLAC_NDK_BUILD_DIR" ] ; then
        CONFIGURE_CMD="$CONFIGURE_CMD --enable-external-libs"
    fi

    [ -z "$SQLITE_NDK_BUILD_DIR" ] || 
    CONFIGURE_CMD="$CONFIGURE_CMD --enable-sqlite"
    
    check_and_set "$LIB_OGG_NDK_BUILD_DIR" "-logg -lm"
    check_and_set "$LIB_VORBIS_NDK_BUILD_DIR" "-lvorbis -lvorbisenc"
    check_and_set "$FLAC_NDK_BUILD_DIR" "-lFLAC"
    check_and_set "$SQLITE_NDK_BUILD_DIR" "-lsqlite3"

    CONFIGURE_CMD="$CONFIGURE_CMD CC='$CC' CFLAGS='$CFLAGS' CXX='$CXX' CXXFLAGS='$CFLAGS' CPPFLAGS='' LDFLAGS='' AR='$AR' RANLIB='$RANLIB' PKG_CONFIG=''"
    #info "$CONFIGURE_CMD\n" && exit
    eval "$CONFIGURE_CMD" &&
    make clean &&
    make install
}

download_ndk_helper_if_needed && build_all TARGET_API=21
