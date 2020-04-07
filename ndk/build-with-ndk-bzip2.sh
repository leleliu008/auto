#!/bin/sh

#注意：请将此脚本放置于源码根目录下
#参考：http://blog.fpliu.com/it/software/bzip2#build-with-ndk

build() {
    source ndk-helper.sh make-env-var TOOLCHAIN=llvm TARGET=armv7a-linux-androideabi API=21

    SHARED=1

    make clean > /dev/null 2>&1

    if [ $SHARED -eq 1 ] ; then
        MAKE='make -f Makefile-libbz2_so'
    else
        MAKE='make'
    fi

    eval "$MAKE CC=$CC CFLAGS='-v' AR=$AR RANLIB=$RANLIB" &&
    DESDIR=output/$TARGET/$API &&
    BINDIR="$DESDIR/bin" &&
    LIBDIR="$DESDIR/lib" &&
    mkdir -p "$DESDIR"/{bin,lib} &&
    cp libbz2.so.*.*.* "$LIBDIR" &&
    cp bzip2-shared "$BINDIR/bzip2"
}

main() {
    download_ndk_helper_if_needed && build "$@"
}

main "$@"
