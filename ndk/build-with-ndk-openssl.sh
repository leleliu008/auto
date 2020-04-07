#!/bin/sh

#注意：请将此脚本放置于源码根目录下
#参考：http://blog.fpliu.com/it/software/OpenSSL#build-with-ndk

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
    download_ndk_helper_if_needed && build "$@"
}

main "$@"
