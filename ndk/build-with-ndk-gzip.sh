#!/bin/sh

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
