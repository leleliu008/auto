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
    msg "${Color_Purple}[❉]${Color_Off} $1$2"
}

success() {
    msg "${Color_Green}[✔]${Color_Off} $1$2"
}

warn() {
    msg "${Color_Yellow}[⌘]${Color_Off} $1$2"
}

error() {
    msg "${Color_Red}[✘]${Color_Off} $1$2"
}

error_exit() {
    msg "${Color_Red}[✘]${Color_Off} $1$2"
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

list_toolchains() {
    toolchainsDir="$ANDROID_NDK_HOME/toolchains"
    if [ -d "$toolchainsDir" ] ; then
        print_list "$(ls "$toolchainsDir")"
    else
        error_exit "$toolchainsDir is not a valid directory. please update your ndk, then try again."
    fi
}

list_targets() {
    print_list aarch64-linux-android armv7a-linux-androideabi i686-linux-android x86_64-linux-android
}

#$1是某个工具链名称，比如llvm，可以通过ndk-helper list toolchains命令列出支持的工具链名称
select_TOOLCHAIN() {
    if [ -z "$1" ] ; then
        info "below is supported toolchains:\n"
        list_toolchains
        info "please input your select toolchain:"
        read -r toolchainName
        if [ -z "$toolchainName" ] ; then
            select_TOOLCHAIN
        else
            toolchainDir="$ANDROID_NDK_HOME/toolchains/$toolchainName"
        fi
    else
        toolchainDir="$ANDROID_NDK_HOME/toolchains/$1"
    fi

    if [ -d "$toolchainDir" ] ; then
        hostName="$(uname -s)-$(uname -m)"
        hostDir="$toolchainDir/prebuilt/$hostName"
        if [ -d "$hostDir" ] ; then
            export TOOLCHAIN="$hostDir"
            export PATH=$TOOLCHAIN/bin:$PATH
        else
            error_exit "$hostDir is not exsit."
        fi
    else
        error_exit "$1 is not a valid toolchain. please use ndk-helper list toolchains to list support toolchains."
    fi
}

#$1是某个目标，比如armv7a-linux-androideabi，可以通过ndk-helper list targets命令列出支持的目标的名称
select_TARGET() {
    if [ -z "$1" ] ; then
        info "below is supported targets:\n"
        list_targets
        info "please input your select target:"
        read -r target
        TARGET="$target"
    else
        TARGET="$1"
    fi
    export TARGET="$TARGET"
}

check_tools() {
    [ -f "$1" ] || error_exit "$1 is not exsit."
    [ -x "$1" ] || error_exit "$1 is not executable."
}

make_ENV() {
    info "-------------------------------------------------------\n"
    info "ANDROID_NDK_HOME = $ANDROID_NDK_HOME\n"
    info "ANDROID_NDK_VER  = $ANDROID_NDK_VERSION\n"
    info "       TOOLCHAIN = $TOOLCHAIN\n"
    info "          TARGET = $TARGET\n"
    info "             API = $API\n"

    CC="$TOOLCHAIN/bin/$TARGET$API-clang"
    check_tools "$CC" && export CC="$CC"
    info "    CC = $CC\n"

    CXX="$TOOLCHAIN/bin/$TARGET$API-clang++"
    check_tools "$CXX" && export CXX="$CXX"
    info "   CXX = $CXX\n"
    
    if [ "$TARGET" = 'armv7a-linux-androideabi' ] ; then
        TARGET2='arm-linux-androideabi'
    else
        TARGET2=TARGET
    fi

    AR="$TOOLCHAIN/bin/$TARGET2-ar"
    check_tools "$AR" && export AR="$AR"
    info "    AR = $AR\n"

    AS="$TOOLCHAIN/bin/$TARGET2-as"
    check_tools "$AS" && export AS="$AS"
    info "    AS = $AS\n"

    LD="$TOOLCHAIN/bin/$TARGET2-ld"
    check_tools "$LD" && export LD="$LD"
    info "    LD = $LD\n"

    NM="$TOOLCHAIN/bin/$TARGET2-nm"
    check_tools "$NM" && export NM="$NM"
    info "    NM = $NM\n"
    
    RANLIB="$TOOLCHAIN/bin/$TARGET2-ranlib"
    check_tools "$RANLIB" && export RANLIB="$RANLIB"
    info "RANLIB = $RANLIB\n"

    STRIP="$TOOLCHAIN/bin/$TARGET2-strip"
    check_tools "$STRIP" && export STRIP="$STRIP"
    info " STRIP = $STRIP\n"
   
    export ARCH="$(printf "%s" "$TARGET" | cut -d- -f1)"
    info "  ARCH = $ARCH\n"
    
    export CPPFLAGS=''
    export LDFLAGS=''
    export CFLAGS='-Os -v -fpic'
    
    info "CPPFLAGS=$CPPFLAGS\n"
    info "LDFLAGS =$LDFLAGS\n"
    info "CFLAGS  =$CFLAGS\n"

    info "-------------------------------------------------------\n"
}

list_APIs() {
    print_list 21 22 23 34 25 26 27 28 29
}

#$1是某个目标，比如21、22、23、34、25、26、27、28、29，，可以通过ndk-helper list APIs命令列出支持的API level
select_API() {
    if [ -z "$1" ] ; then
        info "below is supported APIs:\n"
        list_APIs
        info "please input your select API:"
        read -r api
        API="$api"
    else
        API="$1"
    fi
    export API="$API"
}

make_env_var() {
    while test -n "$1"
    do
        eval "$1" || exit 1
        shift
    done

    check_ANDROID_NDK_HOME

    check_ANDROID_NDK_VERSION

    select_TOOLCHAIN "$TOOLCHAIN"

    select_TARGET "$TARGET"

    select_API "$API"
    
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

download_ndk_helper_if_needed() {
    URL='https://raw.githubusercontent.com/leleliu008/auto/master/ndk/ndk-helper.sh'
    [ -f ndk-helper.sh ] || {
        if command -v curl > /dev/null ; then
            curl -LO "$URL"
        elif command -v wget > /dev/null ; then
            wget "$URL"
        else
            error_exit "please install curl or wget.\n"
        fi
    }
}

help() {
    cat << EOF
Usage: ndk-helper [COMMAND [ARGUMENT...]]
COMMAND:
    help     打印出帮助信息
    list toolchains 列出支持的工具链
    list targets    列出支持的Android目标设备
    list APIs       列出支持的Android API level
    ndk-version     打印出当前NDK的版本号
    make-env-var API=xx TARGET=yy TOOLCHAIN=zz 组装环境变量
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
        'ndk-version')
            check_ANDROID_NDK_HOME
            show_ndk_version
            ;;
        'list')
            shift
            case $1 in
                'toolchains')
                    check_ANDROID_NDK_HOME
                    list_toolchains
                    ;;
                'targets') list_targets;;
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
