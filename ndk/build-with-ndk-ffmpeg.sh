#!/bin/sh

#注意：请将此脚本放置于源码根目录下
#参考：http://blog.fpliu.com/it/software/FFmpeg#build-with-ndk

Color_Red='\033[0;31m'          # Red
Color_Green='\033[0;32m'        # Green
Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b" "$1"
}

info() {
    msg "${Color_Purple}[❉] $1$2${Color_Off}"
}

success() {
    msg "${Color_Green}[✔] $1$2${Color_Off}"
}

error_exit() {
    msg "${Color_Red}[✘] $1$2${Color_Off}"
    exit 1
}

download_ndk_helper_if_needed() {
    URL='https://raw.githubusercontent.com/leleliu008/auto/master/ndk/ndk-helper.sh'
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

sed_in_place() {
    command -v gsed > /dev/null && {
        gsed -i "$1" "$2"
        return 0
    }
    command -v sed > /dev/null && {
        sed -i    "$1" "$2" 2> /dev/null ||
        sed -i "" "$1" "$2"
        return 0
    }
    error_exit "please install sed utility.\n"
}

build() {
    source ndk-helper.sh make-env-var TOOLCHAIN=llvm TARGET=armv7a-linux-androideabi API=21

    make clean > /dev/null 2>&1
    
    sed_in_place 's/Wl,-soname,/o /g' configure

    ./configure \
        --prefix="$PWD/output/$TARGET/$API" \
        --ar="$AR" \
        --as="$AS" \
        --ld="$LD" \
        --cc="$CC" \
        --cxx="$CXX" \
        --nm="$NM" \
        --ranlib="$RANLIB" \
        --strip="$STRIP" \
        --arch="$ARCH" \
        --target-os=android \
        --enable-cross-compile \
        --enable-shared \
        --enable-pic \
        --disable-static \
        --disable-debug \
        --disable-asm \
        --disable-doc \
        --sysroot="$ANDROID_NDK_HOME/sysroot" \
        --extra-cflags='-DANDROID' 
    
    sed_in_place 's/LDEXEFLAGS= -fPIE -pie/LDEXEFLAGS= -shared/g' ffbuild/config.mak

    #注释掉#define getenv(x) NULL，没有用，会报错
    sed_in_place "s/#define getenv(x) NULL/\\/\\/ #define getenv(x) NULL/" config.h
    sed_in_place "s/#define HAVE_TRUNC 0/#define HAVE_TRUNC 1/" config.h
    sed_in_place "s/#define HAVE_TRUNCF 0/#define HAVE_TRUNCF 1/" config.h
    sed_in_place "s/#define HAVE_RINT 0/#define HAVE_RINT 1/" config.h
    sed_in_place "s/#define HAVE_LRINT 0/#define HAVE_LRINT 1/" config.h
    sed_in_place "s/#define HAVE_LRINTF 0/#define HAVE_LRINTF 1/" config.h
    sed_in_place "s/#define HAVE_ROUND 0/#define HAVE_ROUND 1/" config.h
    sed_in_place "s/#define HAVE_ROUNDF 0/#define HAVE_ROUNDF 1/" config.h
    sed_in_place "s/#define HAVE_CBRT 0/#define HAVE_CBRT 1/" config.h
    sed_in_place "s/#define HAVE_CBRTF 0/#define HAVE_CBRTF 1/" config.h
    sed_in_place "s/#define HAVE_COPYSIGN 0/#define HAVE_COPYSIGN 1/" config.h
    sed_in_place "s/#define HAVE_ERF 0/#define HAVE_ERF 1/" config.h
    sed_in_place "s/#define HAVE_HYPOT 0/#define HAVE_HYPOT 1/" config.h
    sed_in_place "s/#define HAVE_ISNAN 0/#define HAVE_ISNAN 1/" config.h
    sed_in_place "s/#define HAVE_ISFINITE 0/#define HAVE_ISFINITE 1/" config.h
    sed_in_place "s/#define HAVE_INET_ATON 0/#define HAVE_INET_ATON 1/" config.h

    make install
}

main() {
    download_ndk_helper_if_needed &&
    build "$@" &&
    build_success
}

main "$@"
