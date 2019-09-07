#!/bin/bash

# Cross-compile environment for Android on ARMv7 and x86
#
# Contents licensed under the terms of the OpenSSL license
# http://www.openssl.org/source/license.html
#
# See http://wiki.openssl.org/index.php/FIPS_Library_and_Android
#   and http://wiki.openssl.org/index.php/Android

########################### 修改下面的变量 #############################

# 设置NDK的安装路径
ANDROID_NDK_ROOT=/usr/local/share/android-ndk

# 设置工具链的名字。$ANDROID_NDK_ROOT/toolchains目录中那些文件夹名称
_ANDROID_EABI="arm-linux-androideabi-4.9"

# 设置生成的动态库的CPU平台:arch-x86、arch-arm
_ANDROID_ARCH=arch-arm

# 设置你要支持的Android API Level
_ANDROID_API="android-23"

#####################################################################

if [ -z "$ANDROID_NDK_ROOT" ] ; then
    echo "Error: please set ANDROID_NDK_ROOT";
    exit 1;
fi

if [ -d "$ANDROID_NDK_ROOT" ] ; then
    export ANDROID_NDK_ROOT="$ANDROID_NDK_ROOT"
else
    echo "Error: $ANDROID_NDK_ROOT is not a valid path!"
    exit 1;
fi

if [ ! -d "$ANDROID_NDK_ROOT/toolchains" ] ; then
    echo "Error: $ANDROID_NDK_ROOT/toolchains is not a valid path!"
    exit 1
fi

if [ ! -d "$ANDROID_NDK_ROOT/toolchains/$_ANDROID_EABI" ] ; then
    echo "Error: $ANDROID_NDK_ROOT/toolchains/$_ANDROID_EABI is not a valid path!"
    exit 1;
fi

#####################################################################

# Based on ANDROID_NDK_ROOT, try and pick up the required toolchain. We expect something like:
# /opt/android-ndk-r83/toolchains/arm-linux-androideabi-4.7/prebuilt/linux-x86_64/bin
# Once we locate the toolchain, we add it to the PATH. Note: this is the 'hard way' of
# doing things according to the NDK documentation for Ice Cream Sandwich.
# https://android.googlesource.com/platform/ndk/+/ics-mr0/docs/STANDALONE-TOOLCHAIN.html

ANDROID_TOOLCHAIN=""
for host in "linux-x86_64" "linux-x86" "darwin-x86_64" "darwin-x86"
do
    dir="$ANDROID_NDK_ROOT/toolchains/$_ANDROID_EABI/prebuilt/$host/bin"
    if [ -d $dir ]; then
        ANDROID_TOOLCHAIN=$dir;
        break;
    fi
done

if [ -z "$ANDROID_TOOLCHAIN" ] || [ ! -d "$ANDROID_TOOLCHAIN" ]; then
    echo "Error: ANDROID_TOOLCHAIN is not valid. Please edit this script."
    exit 1
fi

if [ $_ANDROID_ARCH == "arch-arm" ] ; then
    ANDROID_TOOLS="arm-linux-androideabi-gcc arm-linux-androideabi-ranlib arm-linux-androideabi-ld"
elif [ $_ANDROID_ARCH == "arch-x86" ] ; then
    ANDROID_TOOLS="i686-linux-android-gcc i686-linux-android-ranlib i686-linux-android-ld"
else
	echo "$_ANDROID_ARCH is not support!"
	exit 1;
fi

for tool in $ANDROID_TOOLS
do
    toolPath="$ANDROID_TOOLCHAIN/$tool"
    if [ ! -e $toolPath ]; then
        echo "Error: $toolPath is not exsit. Please edit this script."
        exit 1
    fi
done

if [ ! -z "$ANDROID_TOOLCHAIN" ]; then
    export ANDROID_TOOLCHAIN="$ANDROID_TOOLCHAIN"
    export PATH="$ANDROID_TOOLCHAIN":"$PATH"
fi

#####################################################################

# For the Android SYSROOT. Can be used on the command line with --sysroot
# https://android.googlesource.com/platform/ndk/+/ics-mr0/docs/STANDALONE-TOOLCHAIN.html
export ANDROID_SYSROOT="$ANDROID_NDK_ROOT/platforms/$_ANDROID_API/$_ANDROID_ARCH"
export CROSS_SYSROOT="$ANDROID_SYSROOT"
export NDK_SYSROOT="$ANDROID_SYSROOT"
export C_INCLUDE_PATH="$ANDROID_NDK_ROOT/sysroot/usr/include":"$ANDROID_NDK_ROOT/sysroot/usr/include/arm-linux-androideabi":"$ANDROID_NDK_ROOT/sysroot/usr/include/i686-linux-android"



if [ -z "$ANDROID_SYSROOT" ] || [ ! -d "$ANDROID_SYSROOT" ]; then
    echo "Error: $ANDROID_SYSROOT is not valid. Please edit this script."
    exit 1
fi

#####################################################################

if [ -z "$FIPS_SIG" ] || [ ! -e "$FIPS_SIG" ]; then
     _FIPS_SIG=""
    if [ -d "/usr/local/ssl/$_ANDROID_API" ]; then
        _FIPS_SIG=`find "/usr/local/ssl/$_ANDROID_API" -name incore`
    fi

    if [ ! -e "$_FIPS_SIG" ]; then
        #在当前目录的util/incore
        _FIPS_SIG=`find $PWD -name incore`
    fi
    
    if [ ! -z "$_FIPS_SIG" ] && [ -e "$_FIPS_SIG" ]; then
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

if [ "$_ANDROID_ARCH" == "arch-x86" ] ; then
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

echo "------------------------------------------"
echo "ANDROID_NDK_ROOT: $ANDROID_NDK_ROOT"
echo "ANDROID_ARCH: $_ANDROID_ARCH"
echo "ANDROID_EABI: $_ANDROID_EABI"
echo "ANDROID_API: $ANDROID_API"
echo "ANDROID_SYSROOT: $ANDROID_SYSROOT"
echo "ANDROID_TOOLCHAIN: $ANDROID_TOOLCHAIN"
echo "FIPS_SIG: $FIPS_SIG"
echo "CROSS_COMPILE: $CROSS_COMPILE"
echo "ANDROID_DEV: $ANDROID_DEV"
echo "------------------------------------------"
echo "build begain..."

# 清除上次构建残留的信息
make clean >& /dev/null
# 替换文件中的内容
perl -pi -e 's/install: all install_docs install_sw/install: install_docs install_sw/g' Makefile.shared

./config shared no-ssl2 no-ssl3 no-comp no-hw no-engine
make depend
make all
#sudo -E make install CC=$ANDROID_TOOLCHAIN/arm-linux-androideabi-gcc RANLIB=$ANDROID_TOOLCHAIN/arm-linux-androideabi-ranlib
