#!/bin/sh

Color_Red='\033[0;31m'          # Red
Color_Green='\033[0;32m'        # Green
Color_Yellow='\033[0;33m'       # Yellow
Color_Blue='\033[0;34m'         # Blue
Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b" "$@"
}

info() {
    msg "${Color_Purple}[❉] $@${Color_Off}"
}

success() {
    msg "${Color_Green}[✔] $@${Color_Off}"
}

warn() {
    msg "${Color_Yellow}[⌘] $@${Color_Off}"
}

error() {
    msg "${Color_Red}[✘] $@${Color_Off}"
}

error_exit() {
    msg "${Color_Red}[✘] $@${Color_Off}"
    exit 1
}

print_list() {
    for item in $@
    do
        msg "    ${Color_Blue}$item${Color_Off}\n"
    done
}

check_DEVELOPER_DIR() {
    DEVELOPER_DIR="$(xcode-select -p)"
    if [ -z "$DEVELOPER_DIR" ] ; then
        error_exit "please set DEVELOPER_DIR environment variable, then try again!\n"
    elif [ ! -d "$DEVELOPER_DIR" ] ; then
        error_exit "$DEVELOPER_DIR is not a valid directory!\n"
    fi
}

make_ENV() {
    [ -z "$PLATFORM_MIN_V" ] && PLATFORM_MIN_V='8.0'
    
    platformLower="$(printf "%b" "$PLATFORM" | awk '{print(tolower($0))}')" 

    export DEVELOPER_DIR="$DEVELOPER_DIR"
    export TOOLCHAIN_DIR="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin"
    export SYSROOT="$DEVELOPER_DIR/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}.sdk"
    export PLATFORM="$PLATFORM"
    export PLATFORM_MIN_V="$PLATFORM_MIN_V"
    export ARCH="$ARCH"
    export HOST="$HOST"
    export OUTPUT="$PWD/output"
    export PREFIX="$PWD/output/$PLATFORM/$ARCH"
    export CC="$TOOLCHAIN_DIR/clang"
    export CXX="$TOOLCHAIN_DIR/clang++"
    export AR="$TOOLCHAIN_DIR/ar"
    export AS="$TOOLCHAIN_DIR/as"
    export LD="$TOOLCHAIN_DIR/ld"
    export NM="$TOOLCHAIN_DIR/nm"
    export STRIP="$TOOLCHAIN_DIR/strip"
    export RANLIB="$TOOLCHAIN_DIR/ranlib"
    export PATH=$TOOLCHAIN_DIR:$PATH
    export CFLAGS="-arch $ARCH -isysroot $SYSROOT -m${platformLower}-version-min=$PLATFORM_MIN_V -pipe -Os -v"
    export CXXFLAGS="$CFLAGS"
    export LDFLAGS="-arch $ARCH -isysroot $SYSROOT"
    export CPPFLAGS=""

    info "-------------------------------------------------------\n"
    info "DEVELOPER_DIR = $DEVELOPER_DIR\n"
    info "TOOLCHAIN_DIR = $TOOLCHAIN_DIR\n"
    info "     PLATFORM = $PLATFORM\n"
    info "PLATFORM_MIN_V = $PLATFORM_MIN_V\n"
    info "      SYSROOT = $SYSROOT\n"
    info "         ARCH = $ARCH\n"
    info "         HOST = $HOST\n"
    info "       OUTPUT = $OUTPUT\n"
    info "       PREFIX = $PREFIX\n"
    info "           CC = $CC\n"
    info "          CXX = $CXX\n"
    info "           AR = $AR\n"
    info "           AS = $AS\n"
    info "           LD = $LD\n"
    info "           NM = $NM\n"
    info "       RANLIB = $RANLIB\n"
    info "        STRIP = $STRIP\n"
    info "         PATH = $PATH\n"
    info "       CFLAGS = $CFLAGS\n"
    info "     CXXFLAGS = $CXXFLAGS\n"
    info "     CPPFLAGS = $CPPFLAGS\n"
    info "      LDFLAGS = $LDFLAGS\n"
    info "-------------------------------------------------------\n"
}

list_platforms() {
    ls "$DEVELOPER_DIR/Platforms" | awk '{gsub(".platform","");print}'
}

list_ARCHs() {
    msg "armv7 armv7s arm64 i386 x86_64\n"
}

select_Platform_if_needed() {
    if [ -z "$PLATFORM" ] ; then
        info "below is supported platforms:\n"
        print_list $(list_platforms)
        info "please input your select platform:"
        read PLATFORM
        select_Platform_if_needed
    fi
}

select_ARCH_if_needed() {
    if [ -z "$ARCH" ] ; then
        info "below is supported ARCHs:\n"
        print_list $(list_ARCHs)
        info "please input your select ARCH:"
        read ARCH
        select_ARCH_if_needed
    fi

    if [ 'arm64' = "$ARCH" ] ; then
        HOST='arm-apple-darwin'
    else
        HOST="${ARCH}-apple-darwin"
    fi
}

parse_params() {
    while [ -n "$1" ]
    do
        eval "$1"
        shift
    done
}

help() {
    cat << EOF
Usage: xcode-for-ios-helper [COMMAND [ARGUMENT...]]
COMMAND:
    help     打印出帮助信息
    list platforms  列出支持的平台
    list ARCHs      列出支持的CPU架构
    make-env-var PLATFORM=iPhoneOS PLATFORM_MIN_V=8.0 ARCH=armv7 组装环境变量
EOF
    if [ -z "$1" ] ; then
        exit
    else
        exit "$1"
    fi
}

main() {
    case $1 in
        'help') help;;
        'list')
            shift
            case $1 in
                'platforms')
                    check_DEVELOPER_DIR
                    list_platforms
                    ;;
                'ARCHs')
                    list_ARCHs
                    ;;
                *) help 1
            esac
            ;;
        'make-env-var') 
            shift
            check_DEVELOPER_DIR
            parse_params "$@"
            select_Platform_if_needed
            select_ARCH_if_needed
            make_ENV
            ;;
        *) help 1
    esac
}

main "$@"
