#!/bin/sh

# Cross-compile environment for Android on ARMv7 and x86
#
# Contents licensed under the terms of the OpenSSL license
# http://www.openssl.org/source/license.html
#
# See http://wiki.openssl.org/index.php/FIPS_Library_and_Android
#   and http://wiki.openssl.org/index.php/Android

########################### 修改下面的变量 #############################

if [ -z "$ANDROID_NDK_HOME" ] ; then
    ANDROID_NDK_ROOT=/usr/local/share/android-ndk
else
    ANDROID_NDK_ROOT=$ANDROID_NDK_HOME
fi

# 设置工具链的名字。$ANDROID_NDK_ROOT/toolchains目录中那些文件夹名称
_ANDROID_EABI="arm-linux-androideabi-4.9"

# 设置生成的动态库的CPU平台:arch-x86、arch-arm
_ANDROID_ARCH=arch-arm

# 设置你要支持的Android API Level
_ANDROID_API="android-23"

#####################################################################

Color_Red='\033[0;31m'          # Red
Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b\n" "$1"
}

info() {
    msg "${Color_Purple}[❉]${Color_Off} $1$2"
}

error() {
    msg "${Color_Red}[✘]${Color_Off} $1$2"
    exit 1
}

[ -z "$ANDROID_NDK_ROOT" ] && error "please set ANDROID_NDK_ROOT"

[ -d "$ANDROID_NDK_ROOT" ] || error "ANDROID_NDK_ROOT=$ANDROID_NDK_ROOT is not a valid path!"
    
export ANDROID_NDK_ROOT="$ANDROID_NDK_ROOT"

[ -d "$ANDROID_NDK_ROOT/toolchains" ] || error "$ANDROID_NDK_ROOT/toolchains is not a valid path!"

[ -d "$ANDROID_NDK_ROOT/toolchains/$_ANDROID_EABI" ] || error "$ANDROID_NDK_ROOT/toolchains/$_ANDROID_EABI is not a valid path!"

HOST=$(uname -s)-$(uname -m)

ANDROID_TOOLCHAIN="$ANDROID_NDK_ROOT/toolchains/$_ANDROID_EABI/prebuilt/$HOST/bin"

[ -z "$ANDROID_TOOLCHAIN" ] && error "NDK may be not installed"
[ -d "$ANDROID_TOOLCHAIN" ] || error "ANDROID_TOOLCHAIN=$ANDROID_TOOLCHAIN is not directory. Please edit this script."

export ANDROID_TOOLCHAIN="$ANDROID_TOOLCHAIN"
export PATH="$ANDROID_TOOLCHAIN":"$PATH"

#####################################################################

# For the Android SYSROOT. Can be used on the command line with --sysroot
# https://android.googlesource.com/platform/ndk/+/ics-mr0/docs/STANDALONE-TOOLCHAIN.html
export ANDROID_SYSROOT="$ANDROID_NDK_ROOT/platforms/$_ANDROID_API/$_ANDROID_ARCH"
export CROSS_SYSROOT="$ANDROID_SYSROOT"
export NDK_SYSROOT="$ANDROID_SYSROOT"
export C_INCLUDE_PATH="$ANDROID_NDK_ROOT/sysroot/usr/include":"$ANDROID_NDK_ROOT/sysroot/usr/include/arm-linux-androideabi":"$ANDROID_NDK_ROOT/sysroot/usr/include/i686-linux-android"

[ -z "$ANDROID_SYSROOT" ] && error "ANDROID_SYSROOT is empty."
[ -d "$ANDROID_SYSROOT" ] || error "ANDROID_SYSROOT=$ANDROID_SYSROOT is not directory. Please edit this script."

#####################################################################

if [ -z "$FIPS_SIG" ] || [ ! -e "$FIPS_SIG" ]; then
     _FIPS_SIG=""
    if [ -d "/usr/local/ssl/$_ANDROID_API" ]; then
        _FIPS_SIG=$(find "/usr/local/ssl/$_ANDROID_API" -name incore)
    fi

    if [ ! -e "$_FIPS_SIG" ]; then
        #在当前目录的util/incore
        _FIPS_SIG=$(find "$PWD" -name incore)
    fi
    
    if [ -n "$_FIPS_SIG" ] && [ -e "$_FIPS_SIG" ]; then
        export FIPS_SIG="$_FIPS_SIG"
    fi
fi

if [ -z "$FIPS_SIG" ] || [ ! -e "$FIPS_SIG" ]; then
    echo "Error: FIPS_SIG does not specify incore module. Please edit this script."
    # exit 1
fi

#####################################################################

export RELEASE=2.6.37
export SYSTEM=android

if [ "$_ANDROID_ARCH" = "arch-x86" ] ; then
	export MACHINE=i686
	export ARCH=x86
	export CROSS_COMPILE="i686-linux-android-"
else
	export MACHINE=armv7
	export ARCH=arm
	export CROSS_COMPILE="arm-linux-androideabi-"
fi

# https://android.googlesource.com/platform/ndk/+/ics-mr0/docs/STANDALONE-TOOLCHAIN.html
export ANDROID_SYSROOT="$ANDROID_NDK_ROOT/platforms/$_ANDROID_API/$_ANDROID_ARCH"
export SYSROOT="$ANDROID_SYSROOT"
export NDK_SYSROOT="$ANDROID_SYSROOT"
export ANDROID_NDK_SYSROOT="$ANDROID_SYSROOT"
export ANDROID_API="$_ANDROID_API"
export ANDROID_DEV="$ANDROID_NDK_ROOT/platforms/$_ANDROID_API/$_ANDROID_ARCH/usr"
export HOSTCC=gcc

cat << EOF
------------------------------------------
ANDROID_NDK_ROOT: $ANDROID_NDK_ROOT
ANDROID_ARCH: $_ANDROID_ARCH
ANDROID_EABI: $_ANDROID_EABI
ANDROID_API: $ANDROID_API
ANDROID_SYSROOT: $ANDROID_SYSROOT
ANDROID_TOOLCHAIN: $ANDROID_TOOLCHAIN
FIPS_SIG: $FIPS_SIG
CROSS_COMPILE: $CROSS_COMPILE
ANDROID_DEV: $ANDROID_DEV
------------------------------------------"
build begain...
EOF

# 清除上次构建残留的信息
make clean > /dev/null 2>&1
# 替换文件中的内容
perl -pi -e 's/install: all install_docs install_sw/install: install_docs install_sw/g' Makefile.shared

./config shared no-ssl2 no-ssl3 no-comp no-hw no-engine
make depend
make all
#sudo -E make install CC=$ANDROID_TOOLCHAIN/arm-linux-androideabi-gcc RANLIB=$ANDROID_TOOLCHAIN/arm-linux-androideabi-ranlib
