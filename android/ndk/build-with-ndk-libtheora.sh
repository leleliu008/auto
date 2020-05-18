#!/bin/sh

###################################################################
#注意：请将此脚本放置于源码根目录下
#参考：http://blog.fpliu.com/it/software/development/language/C/library/libtheora/build-for-android
###################################################################

#将下面3个变量的值修改为符合你的实际
#LIB_OGG_NDK_BUILD_DIR是必须的，其他2个不需要的话，设置为空字符串
LIB_OGG_NDK_BUILD_DIR="$HOME/libogg-1.3.4/ndk-build"
LIB_VORBIS_NDK_BUILD_DIR="$HOME/vorbis-1.3.6/ndk-build"
SDL_NDK_BUILD_DIR="$HOME/SDL2-2.0.12/ndk-build"

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

change_autogen_h() {
    sed -i    '$d' autogen.sh 2> /dev/null || \
    sed -i "" '$d' autogen.sh
}

build() {
    [ -f configure ] || (change_autogen_h && ./autogen.sh)

    CONFIGURE_CMD="./configure --host='$TARGET_HOST' --prefix='$INSTALL_DIR' --with-sysroot='$ANDROID_NDK_HOME/sysroot' --disable-examples"
    
    [ -z "$LIB_OGG_NDK_BUILD_DIR" ] && error_exit "$LIB_OGG_NDK_BUILD_DIR is not exsit\n"
    [ -d "$LIB_OGG_NDK_BUILD_DIR" ] || error_exit "$LIB_OGG_NDK_BUILD_DIR is not a directory\n"
    OGG_PREFIX="$LIB_OGG_NDK_BUILD_DIR/$TARGET_ABI"
    [ -d "$OGG_PREFIX" ] || error_exit "$OGG_PREFIX is not a directory\n"
    CONFIGURE_CMD="$CONFIGURE_CMD --with-ogg='$OGG_PREFIX'"

    [ -z "$LIB_VORBIS_NDK_BUILD_DIR" ] || {
        [ -d "$LIB_VORBIS_NDK_BUILD_DIR" ] || error_exit "$LIB_VORBIS_NDK_BUILD_DIR is not a directory\n"
        VORBIS_PREFIX="$LIB_VORBIS_NDK_BUILD_DIR/$TARGET_ABI"
        [ -d "$VORBIS_PREFIX" ] || error_exit "$VORBIS_PREFIX is not a directory\n"
        CONFIGURE_CMD="$CONFIGURE_CMD --with-vorbis='$VORBIS_PREFIX'"
    }
    
    [ -z "$SDL_NDK_BUILD_DIR" ] || {
        [ -d "$SDL_NDK_BUILD_DIR" ] || error_exit "$SDL_NDK_BUILD_DIR is not a directory\n"
        SDL_PREFIX="$SDL_NDK_BUILD_DIR/$TARGET_ABI"
        [ -d "$SDL_PREFIX" ] || error_exit "$SDL_PREFIX is not a directory\n"
        CONFIGURE_CMD="$CONFIGURE_CMD --with-sdl-prefix='$SDL_PREFIX'"
    }
    
    CONFIGURE_CMD="$CONFIGURE_CMD CC='$CC' CFLAGS='$CFLAGS' CPPFLAGS='' LDFLAGS='' AR='$AR' RANLIB='$RANLIB' PKG_CONFIG=''"

    eval "$CONFIGURE_CMD" &&
    make clean &&
    make install
}

download_ndk_helper_if_needed && build_all TARGET_API=21
