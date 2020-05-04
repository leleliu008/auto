#!/bin/sh

#注意：请将此脚本放置于源码根目录下
#参考：http://blog.fpliu.com/it/software/OpenSSL#build-with-ndk

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
}

build_success() {
    success "build success. in $PWD/output/$TARGET/$API directory.\n"

    if command -v tree > /dev/null ; then
        tree "$PWD/output/$TARGET/$API"
    fi
}

build() {
    source ndk-helper.sh make-env-var TOOLCHAIN=llvm TARGET=armv7a-linux-androideabi API=21
   
    # 清除上次构建残留的信息
    make clean > /dev/null 2>&1
     
    ./Configure \
        shared \
        no-ssl2 \
        no-ssl3 \
        no-comp \
        no-hw \
        no-engine \
        no-asm \
        -D__ANDROID_API__="$API" \
        --prefix="$PWD/output/$TARGET/$API" \
        android-arm &&
    make install
}

main() {
    download_ndk_helper_if_needed &&
    build "$@" &&
    build_success
}

main "$@"
