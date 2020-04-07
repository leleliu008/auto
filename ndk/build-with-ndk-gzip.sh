#!/bin/sh

#注意：请将此脚本放置于源码根目录下
#参考：http://blog.fpliu.com/it/software/GNU/gzip#build-with-ndk

build() {
    source ndk-helper.sh make-env-var TOOLCHAIN=llvm TARGET=armv7a-linux-androideabi API=21

    make clean > /dev/null 2>&1
    
    ./configure \
        --host="$TARGET" \
        --prefix="$PWD/output/$TARGET/$API" \
        CC="$CC" \
        AR="$AR" \
        RANLIB="$RANLIB"

    make install install-data CFLAGS='-O3 -v'
}

main() {
    download_ndk_helper_if_needed && build "$@"
}

main "$@"
