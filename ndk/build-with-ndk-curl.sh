#!/bin/sh

##########################################################
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
