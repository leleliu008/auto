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
ANDROID_SDK_URL=http://dl.google.com/android/${ANDROID_SDK_FILENAME}
ANDROID_SDK_FRAMEWORK_VERSION=23
ANDROID_SDK_BUILD_TOOLS_VERSION=23.0.2

#------------------------------------------------------------------------------#

# 安装依赖库和工具
# 如果是Ubuntu系统
if [ -f "/etc/lsb-release" ] ; then
    sudo apt-get update
    sudo apt-get install -y gcc-multilib lib32z1 lib32stdc++6
    sudo apt-get install -y git subversion vim curl wget
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
