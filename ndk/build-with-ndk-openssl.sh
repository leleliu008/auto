#!/bin/sh

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
        android-arm

    make install
}

main() {
    URL='https://raw.githubusercontent.com/leleliu008/auto/master/ndk/ndk-helper.sh'
    if [ -f ndk-helper.sh ] ; then
        if command -v curl > /dev/null ; then
            curl -LO "$URL"
        elif command -v wget > /dev/null ; then
            wget "$URL"
        else
           printf "please install curl or wget.\n"
        fi
    else
        build "$@"
    fi
}

main "$@"
