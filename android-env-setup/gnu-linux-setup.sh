#!/bin/bash

#------------------------------------------------------------------------------#
# Android开发环境搭建脚本
# 目前只支持Ubuntu和CentOS系统
#------------------------------------------------------------------------------#

WORK_DIR=~/bin

JAVA_HOME=${WORK_DIR}/jdk1.8.0_65
JDK_FILENAME=jdk-8u65-linux-x64.tar.gz
JDK_URL=http://download.oracle.com/otn-pub/java/jdk/8u65-b17/${JDK_FILENAME}

ANDROID_HOME=${WORK_DIR}/android-sdk-linux
ANDROID_SDK_FILENAME=android-sdk_r24.4.1-linux.tgz

# Google专门为中国的开发者提供了中国版本的服务，但是下载地址仍然是国外的
ANDROID_SDK_URL=http://dl.google.com/android/${ANDROID_SDK_FILENAME}

# SDK framework API level
ANDROID_SDK_FRAMEWORK_VERSION=23

# 构建工具的版本
ANDROID_SDK_BUILD_TOOLS_VERSION=23.0.2

# 此开关控制是否要安装Android Studio
# 如果您用于桌面环境，通常是用于开发的，开启的可能行很大
# 如果您用于持续构建服务器，通常是不需要安装的，把此开发改为false即可
ANDROID_STUDIO_NEED=true

ANDROID_STUDIO_FILENAME=android-studio-ide-145.3537739-linux.zip

# 查看要安装的版本：http://tools.android.com/download/studio/canary
ANDROID_STUDIO_URL=https://dl.google.com/dl/android/studio/ide-zips/2.2.3.0/${ANDROID_STUDIO_FILENAME}
#------------------------------------------------------------------------------#

# 安装依赖库和工具
# 如果是Ubuntu系统
if [ -f "/etc/lsb-release" ] ; then
    sudo apt-get update
    sudo apt-get install -y gcc-multilib lib32z1 lib32stdc++6
    sudo apt-get install -y git subversion vim curl wget zip unzip
    sudo apt-get clean
    sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# 如果是CentOS系统
elif [ -f "/etc/redhat-release" ] ; then
    sudo yum update
    sudo yum install -y glibc.i686 zlib.i686 libstdc++.i686
    sudo yum install -y git subversion vim curl wget
    sudo yum clean
fi

# 如果不存在此文件夹，就创建
if [ ! -d "${WORK_DIR}" ]; then
    mkdir -p ${WORK_DIR}
fi
cd ${WORK_DIR}

if [ -f "${JDK_FILENAME}" ] ; then
    rm ${JDK_FILENAME}
fi

# 下载JDK
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" ${JDK_URL} && \
    tar xf ${JDK_FILENAME} && \
    rm -rf ${JDK_FILENAME}

if [ -f "${ANDROID_SDK_FILENAME}" ] ; then
    rm ${ANDROID_SDK_FILENAME}
fi

# 下载Android SDK
wget ${ANDROID_SDK_URL} && \
    tar xf ${ANDROID_SDK_FILENAME} && \
    rm -rf ${ANDROID_SDK_FILENAME}

#配置环境变量
echo "export JAVA_HOME=${JAVA_HOME}" >> ~/.bashrc
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
echo "export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> ~/.bashrc

echo "export ANDROID_HOME=${ANDROID_HOME}" >> ~/.bashrc
echo "export PATH=\$ANDROID_HOME/tools:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/build-tools/${ANDROID_SDK_BUILD_TOOLS_VERSION}:\$PATH" >> ~/.bashrc

source ~/.bashrc

# 更新Android SDK
echo y | android update sdk --no-ui --all --filter android-${ANDROID_SDK_FRAMEWORK_VERSION},platform-tools,build-tools-${ANDROID_SDK_BUILD_TOOLS_VERSION},extra-android-m2repository

if [ -f "${ANDROID_STUDIO_FILENAME}" ] ; then
    rm ${ANDROID_STUDIO_FILENAME}
fi

if [ $ANDROID_STUDIO_NEED ] ; then
    # 下载Android Studio
    wget ${ANDROID_STUDIO_URL} && \
    unzip ${ANDROID_STUDIO_FILENAME} && \
    rm -rf ${ANDROID_STUDIO_FILENAME}
fi
