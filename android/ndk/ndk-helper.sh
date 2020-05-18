#!/bin/sh

#------------------------------------------------------------------------------
# Reference: https://developer.android.google.cn/ndk/guides/other_build_systems
# requirement: Android NDK version must be r19 or newer.
#------------------------------------------------------------------------------

Color_Red='\033[0;31m'          # Red
Color_Green='\033[0;32m'        # Green
Color_Yellow='\033[0;33m'       # Yellow
Color_Blue='\033[0;34m'         # Blue
Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b" "$1"
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

check_ANDROID_NDK_HOME() {
    if [ -z "$ANDROID_NDK_HOME" ] ; then
        error_exit "please set ANDROID_NDK_HOME environment variable, then try again!"
    elif [ ! -d "$ANDROID_NDK_HOME" ] ; then
        error_exit "$ANDROID_NDK_HOME is not a valid directory!"
    fi
}

check_ANDROID_NDK_VERSION() {
    ANDROID_NDK_VERSION=$(show_ndk_version)
    if command -v cut > /dev/null ; then
        [ "$(printf "%s" "$ANDROID_NDK_VERSION" | cut -d. -f1)" -lt 19 ] && error_exit "your ndk version is $ANDROID_NDK_VERSION, please update to r19 or newer."
    elif command -v awk > /dev/null ; then
        [ "$(printf "%s" "$ANDROID_NDK_VERSION" | awk -F. '{print $1}')" -lt 19 ] && error_exit "your ndk version is $ANDROID_NDK_VERSION, please update to r19 or newer."
    else
        export ANDROID_NDK_VERSION=$ANDROID_NDK_VERSION
    fi
}

list_TARGET_ABIs() {
    print_list armeabi-v7a arm64-v8a x86 x86_64
}

#$1是某个目标，比如armeabi-v7a，可以通过ndk-helper list targets命令列出支持的目标的名称
select_TARGET_ABI() {
    if [ -z "$1" ] ; then
        info "below is supported TARGET_ABIs:\n"
        list_TARGET_ABIs
        info "please input your select TARGET_ABI:"
        read -r target
        TARGET_ABI="$target"
    else
        TARGET_ABI="$1"
    fi
    export TARGET_ABI="$TARGET_ABI"
}

check_tools() {
    [ -f "$1" ] || error_exit "$1 is not exsit."
    [ -x "$1" ] || error_exit "$1 is not executable."
}

make_ENV() {
    export TOOLCHAIN_DIR="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$(uname -s)-$(uname -m)/bin"
    export PATH="$TOOLCHAIN_DIR:$PATH"

    case "$TARGET_ABI" in
        armeabi-v7a) 
            export TARGET_HOST='armv7a-linux-androideabi'
            export TARGET_ARCH='arm'
            ;;
        arm64-v8a)
            export TARGET_HOST='aarch64-linux-android'
            export TARGET_ARCH='arm64'
            ;;
        x86)
            export TARGET_HOST='i686-linux-android'
            export TARGET_ARCH='x86'
            ;;
        x86_64)
            export TARGET_HOST='x86_64-linux-android'
            export TARGET_ARCH='x86_64'
            ;;
        *)  export TARGET_HOST='unkown'
            export TARGET_ARCH='unkown'
    esac
    
    #export TARGET_ARCH="$(printf "$TARGET_HOST" | cut -d- -f1)"

    export INSTALL_DIR="$PWD/ndk-build/$TARGET_ABI"

    info "-------------------------------------------------------\n"
    info "ANDROID_NDK_HOME = $ANDROID_NDK_HOME\n"
    info "ANDROID_NDK_VER  = $ANDROID_NDK_VERSION\n"
    info "   TOOLCHAIN_DIR = $TOOLCHAIN_DIR\n"
    info "     TARGET_HOST = $TARGET_HOST\n"
    info "     TARGET_ARCH = $TARGET_ARCH\n"
    info "      TARGET_ABI = $TARGET_ABI\n"
    info "      TARGET_API = $TARGET_API\n"
    info "     INSTALL_DIR = $INSTALL_DIR\n"

    TOOLCHAIN_PREFIX="$TOOLCHAIN_DIR/$TARGET_HOST$TARGET_API"

    CC="$TOOLCHAIN_PREFIX-clang"
    check_tools "$CC" && export CC="$CC"
    info "    CC = $CC\n"

    CXX="$TOOLCHAIN_PREFIX-clang++"
    check_tools "$CXX" && export CXX="$CXX"
    info "   CXX = $CXX\n"
     
    if [ "$TARGET_HOST" = 'armv7a-linux-androideabi' ] ; then
        TOOLCHAIN_PREFIX="$TOOLCHAIN_DIR/arm-linux-androideabi"
    else
        TOOLCHAIN_PREFIX="$TOOLCHAIN_DIR/$TARGET_HOST"
    fi

    AR="$TOOLCHAIN_PREFIX-ar"
    check_tools "$AR" && export AR="$AR"
    info "    AR = $AR\n"

    AS="$TOOLCHAIN_PREFIX-as"
    check_tools "$AS" && export AS="$AS"
    info "    AS = $AS\n"

    LD="$TOOLCHAIN_PREFIX-ld"
    check_tools "$LD" && export LD="$LD"
    info "    LD = $LD\n"

    NM="$TOOLCHAIN_PREFIX-nm"
    check_tools "$NM" && export NM="$NM"
    info "    NM = $NM\n"
    
    RANLIB="$TOOLCHAIN_PREFIX-ranlib"
    check_tools "$RANLIB" && export RANLIB="$RANLIB"
    info "RANLIB = $RANLIB\n"

    STRIP="$TOOLCHAIN_PREFIX-strip"
    check_tools "$STRIP" && export STRIP="$STRIP"
    info " STRIP = $STRIP\n"
   
    export CFLAGS='-Os -v -fpic'
    export CPPFLAGS=''
    export LDFLAGS=''
    
    info "CFLAGS  =$CFLAGS\n"
    info "CPPFLAGS=$CPPFLAGS\n"
    info "LDFLAGS =$LDFLAGS\n"

    info "-------------------------------------------------------\n"
}

list_TARGET_APIs() {
    print_list 21 22 23 34 25 26 27 28 29
}

#$1是某个目标，比如21、22、23、34、25、26、27、28、29，，可以通过ndk-helper list APIs命令列出支持的API level
select_TARGET_API() {
    if [ -z "$1" ] ; then
        info "below is supported TARGET_APIs:\n"
        list_TARGET_APIs
        info "please input your select TARGET_API:"
        read -r api
        TARGET_API="$api"
    else
        TARGET_API="$1"
    fi
    export TARGET_API="$TARGET_API"
}

make_env_var() {
    while test -n "$1"
    do
        eval "$1" || exit 1
        shift
    done

    check_ANDROID_NDK_HOME

    check_ANDROID_NDK_VERSION

    select_TARGET_ABI "$TARGET_ABI"

    select_TARGET_API "$TARGET_API"
    
    make_ENV
}

runPythonScript() {
    "$1" << EOF
import re;
file = open("$ANDROID_NDK_HOME/source.properties");
lines = file.readlines();
for line in lines:
    if -1 != line.find("Pkg.Revision"):
        print(re.findall("[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,7}", line)[0]);
EOF
}

runPerlScript() {
    perl << EOF
open(DATA, "<$ANDROID_NDK_HOME/source.properties") or die "$ANDROID_NDK_HOME/source.properties文件无法打开, $!";
while(<DATA>) {
    if ("\$_" =~ m/Pkg.Revision/) {
        print substr("\$_", 15);
    }
}
EOF
}

runNodeJSScript() {
    node << EOF
const fs = require('fs');

const buffer = fs.readFileSync("$ANDROID_NDK_HOME/source.properties");
if (buffer instanceof Error) {
    console.log(buffer);
    process.exit(1);
}

const text = buffer.toString();
const lines = text.split('\n');
lines.forEach((line, index, lines) => {
    const matched = line.match(/\d+\.\d+\.\d+/);
    if (matched) {
        console.log(matched[0]);
    }
});
EOF
}

show_ndk_version() {
    command -v awk > /dev/null && {
        awk -F= '/Pkg.Revision/{print(substr($2, 2))}' "$ANDROID_NDK_HOME/source.properties";
        return 0;
    }

    command -v cut > /dev/null && {
        grep "Pkg.Revision" "$ANDROID_NDK_HOME/source.properties" | cut -d " " -f3
        return 0;
    }
    
    SED=$(command -v gsed)
    [ -z "$SED" ] && SED=$(command -v gsed)
    [ -z "$SED" ] || info "$SED" && grep "Pkg.Revision" "$ANDROID_NDK_HOME/source.properties" |  sed 's/Pkg\.Revision = \(.*\).*/\1/' && return 0
    
    PYTHON=$(command -v python3)
    [ -z "$PYTHON" ] && PYTHON=$(command -v python)
    [ -z "$PYTHON" ] || runPythonScript "$PYTHON"  && return 0
    
    command -v perl > /dev/null && runPerlScript   && return 0
    
    command -v node > /dev/null && runNodeJSScript && return 0
}

#$1是TARGET_API
build_all() {
    for abi in armeabi-v7a arm64-v8a x86 x86_64
    do
        make_env_var TARGET_ABI=$abi $1 && build || exit 1
    done

    build_success
}

build_success() {
    success "build success. in $PWD/ndk-build directory.\n"

    if command -v tree > /dev/null ; then
        tree -L 3 "$PWD/ndk-build"
    fi
}

help() {
    cat << EOF
Usage: ndk-helper [COMMAND [ARGUMENT...]]
COMMAND:
    help     打印出帮助信息
    list targets    列出支持的Android目标设备
    list APIs       列出支持的Android API level
    ndk-version     打印出当前NDK的版本号
    make-env-var TARGET_API=21 TARGET_ABI=armeabi-v7a 组装环境变量
EOF
    if [ -z "$1" ] ; then
        exit
    else
        exit "$1"
    fi
}

main() {
    case $1 in
        'source') ;;
        'help') help;;
        'ndk-version')
            check_ANDROID_NDK_HOME
            show_ndk_version
            ;;
        'list')
            shift
            case $1 in
                'targets') list_TARGET_ABIs;;
                'APIs') list_APIs;;
                *) help 1
            esac
            ;;
        'make-env-var') 
            shift
            check_ANDROID_NDK_HOME
            check_ANDROID_NDK_VERSION
            make_env_var "$@"
            ;;
        *) help 1
    esac
}

main "$@"
