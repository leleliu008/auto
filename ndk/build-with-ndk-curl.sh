#!/bin/sh

##########################################################
#注意：请将此脚本放置于源码根目录下
#参考：http://blog.fpliu.com/it/software/cURL#build-with-ndk
# 请先在\HOME下编译OpenSSL，然后指定--with-ssl=$HOME/openssl/output/$TARGET/$API
##########################################################

build() {
    source ndk-helper.sh make-env-var TOOLCHAIN=llvm TARGET=armv7a-linux-androideabi API=21

    make clean > /dev/null 2>&1
    
    ./configure \
        --host="$TARGET" \
        --prefix="$PWD/output/$TARGET/$API" \
        --with-ssl="$HOME/openssl/output/$TARGET/$API" \
        CC="$CC" \
        CFLAGS='-O3 -v -fPIC' \
        CPPFLAGS="" \
        LDFLAGS="" \
        AR="$AR" \
        RANLIB="$RANLIB"

    make install
}

main() {
    download_ndk_helper_if_needed && build "$@"
}

main "$@"
