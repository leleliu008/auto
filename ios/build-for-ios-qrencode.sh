#!/bin/sh

##########################################################
#注意：请将此脚本放置于源码根目录下
#参考：http://blog.fpliu.com/it/software/qrencode
##########################################################

download_build_for_ios_helper_if_needed() {
    HELPER='build-for-ios-helper.sh'
    URL="https://raw.githubusercontent.com/leleliu008/auto/master/ios/$HELPER"
    [ -f "$HELPER" ] || {
        if command -v curl > /dev/null ; then
            info "Downloading $URL...\n" &&
            curl -LO "$URL" &&
            success "Downloaded->$PWD/$HELPER\n"
        elif command -v wget > /dev/null ; then
            info "Downloading $URL...\n" &&
            wget "$URL" &&
            success "Downloaded->$PWD/$HELPER\n"
        else
            error_exit "please install curl or wget.\n"
        fi
    }
}

build_success() {
    success "build success. in $OUTPUT directory.\n"

    if command -v tree > /dev/null ; then
        tree "$OUTPUT" -L 4
    fi
}

build() {
    source "$HELPER" make-env-var $@
    ./configure \
        --host="$HOST" \
        --prefix="$PREFIX" \
        --with-sysroot="$SYSROOT" \
        --without-tools \
        --without-png \
        --enable-static=yes \
        --enable-shared=no \
        CC="$CC" \
        CFLAGS="$CFLAGS" \
        CPPFLAGS="$CPPFLAGS" \
        LDFLAGS="$LDFLAGS" \
        AR="$AR" \
        RANLIB="$RANLIB" && \
    make clean && \
    make install
}

build_for_real_device() {
    build PLATFORM=iPhoneOS PLATFORM_MIN_V=8.0 ARCH=armv7 &&
    build PLATFORM=iPhoneOS PLATFORM_MIN_V=8.0 ARCH=armv7s &&
    build PLATFORM=iPhoneOS PLATFORM_MIN_V=8.0 ARCH=arm64
}

build_for_simulator() {
    build PLATFORM=iPhoneSimulator PLATFORM_MIN_V=8.0 ARCH=i386 &&
    build PLATFORM=iPhoneSimulator PLATFORM_MIN_V=8.0 ARCH=x86_64
}

#$1是静态库的前缀
create_static_library_universal_file() {
    lipo -create -output "$OUTPUT/$1.a" "$OUTPUT/iPhoneOS/armv7/lib/$1.a" "$OUTPUT/iPhoneOS/armv7s/lib/$1.a" "$OUTPUT/iPhoneOS/arm64/lib/$1.a" "$OUTPUT/iPhoneSimulator/x86_64/lib/$1.a" "$OUTPUT/iPhoneSimulator/i386/lib/$1.a"
}

main() {
    download_build_for_ios_helper_if_needed &&
    build_for_real_device &&
    build_for_simulator &&
    create_static_library_universal_file libqrencode &&
    build_success
}

main "$@"
