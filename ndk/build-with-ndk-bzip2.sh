#!/bin/sh

build() {
    source ndk-helper.sh make-env-var TOOLCHAIN=llvm TARGET=armv7a-linux-androideabi API=21

    SHARED=1

    make clean

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
