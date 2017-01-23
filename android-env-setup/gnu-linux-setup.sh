#!/bin/bash

#------------------------------------------------------------------------------#
# Android开发环境搭建脚本
# 目前只支持Ubuntu和CentOS系统
#------------------------------------------------------------------------------#

#解压后的文件存放目录，要修改的话，最好还是在~目录或者其子目录下，涉及到权限问题
WORK_DIR=~/bin

JDK_URL=http://download.oracle.com/otn-pub/java/jdk/8u65-b17/jdk-8u65-linux-x64.tar.gz

# Google专门为中国的开发者提供了中国版本的服务，但是下载地址仍然是国外的
# https://developer.android.google.cn/studio/index.html
ANDROID_SDK_URL=http://dl.google.com/android/android-sdk_r24.4.1-linux.tgz

# SDK framework API level
ANDROID_SDK_FRAMEWORK_VERSION=23

# 构建工具的版本
ANDROID_SDK_BUILD_TOOLS_VERSION=23.0.2

# 此开关控制是否要安装Android Studio
# 如果您用于桌面环境，通常是用于开发的，开启的可能行很大
# 如果您用于持续构建服务器，通常是不需要安装的，把此开发改为false即可
ANDROID_STUDIO_NEED=true

# 查看要安装的版本：
# http://tools.android.com/download/studio/canary
# https://developer.android.google.cn/studio/index.html
ANDROID_STUDIO_URL=https://dl.google.com/dl/android/studio/ide-zips/2.2.3.0/android-studio-ide-145.3537739-linux.zip

#------------------------------------------------------------------------------#

# 安装依赖库和工具
function installDependency() {
    # 如果是Ubuntu系统
    if [ -f "/etc/lsb-release" ] ; then
        sudo apt-get update
        sudo apt-get install -y gcc-multilib lib32z1 lib32stdc++6
        sudo apt-get install -y git subversion vim curl wget zip unzip
    # 如果是CentOS系统
    elif [ -f "/etc/redhat-release" ] ; then
        sudo yum update
        sudo yum install -y glibc.i686 zlib.i686 libstdc++.i686
        sudo yum install -y git subversion vim curl wget
    fi
}

# 下载并解压.tar.gz或者.tgz文件
# $1是要下载文件的URL
function downloadTGZFile() {
    fileName=`basename "$1"`

    if [ -f "${fileName}" ] ; then
        tar -tf ${fileName} > /dev/null
        if [ $? -eq 0 ] ; then
            tar zxf ${fileName} -C ${WORK_DIR}
        else
            rm ${fileName}
            
            wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "$1" && \
            tar zxf ${fileName} -C ${WORK_DIR}
        fi
    else
        wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "$1" && \
        tar zxf ${fileName} -C ${WORK_DIR}
    fi
}

# 下载并解压.zip
# $1是要下载文件的URL
function downloadZipFile() {
    fileName=`basename "$1"`

    if [ -f "${fileName}" ] ; then
        unzip -t ${fileName} > /dev/null
        if [ $? -eq 0 ] ; then
            unzip ${fileName} -d ${WORK_DIR}
        else
            rm ${fileName}
            
            wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "$1" && \
            unzip ${fileName} -d ${WORK_DIR}
        fi
    else
        wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "$1" && \
        unzip ${fileName} -d ${WORK_DIR}
    fi
}

# 下载文件
# $1是要下载文件的URL
function downloadFile() {
    fileName=`basename "$1"`
    extension=`echo "${fileName##*.}"`
    
    echo "downloadFile() url=$1 | fileName=$fileName | extension=$extension"
    
    if [ "$extension" = "tgz" ] ; then
        downloadTGZFile $1
    elif [ "$extension" = "gz" ] ; then
        downloadTGZFile $1
    elif [ "$extension" = "zip" ] ; then
        downloadZipFile $1
    elif [ "$extension" = "war" ] ; then
        downloadZipFile $1
    fi
}

# 配置JDK环境变量
function configJDKEnv() {
    fileName=`basename "$JDK_URL"`
    dirName=`tar -tf ${fileName} | awk -F "/" '{print $1}' | sort | uniq`
    javaHome=${WORK_DIR}/${dirName}
    
    echo "export JAVA_HOME=${javaHome}" >> ~/.bashrc
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
    echo "export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> ~/.bashrc

    source ~/.bashrc
}

# 配置Android SDK的环境变量
function configAndroidSDKEnv() {
    fileName=`basename "$ANDROID_SDK_URL"`
    dirName=`tar -tf ${fileName} | awk -F "/" '{print $1}' | sort | uniq`
    androidHome=${WORK_DIR}/${dirName}

    echo "export ANDROID_HOME=${androidHome}" >> ~/.bashrc
    echo "export PATH=\$ANDROID_HOME/tools:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/build-tools/${ANDROID_SDK_BUILD_TOOLS_VERSION}:\$PATH" >> ~/.bashrc

    source ~/.bashrc
}

# 更新Android SDK
function updateAndroidSDK() {
    echo y | android update sdk --no-ui --all --filter android-${ANDROID_SDK_FRAMEWORK_VERSION},platform-tools,build-tools-${ANDROID_SDK_BUILD_TOOLS_VERSION},extra-android-m2repository
}

function main() {
    # 如果不存在此文件夹，就创建
    if [ ! -d "${WORK_DIR}" ]; then
        mkdir -p ${WORK_DIR}
    fi

    cd ~

    installDependency

    downloadFile $JDK_URL

    configJDKEnv

    downloadFile $ANDROID_SDK_URL

    configAndroidSDKEnv

    updateAndroidSDK

    downloadFile $ANDROID_STUDIO_URL
    
    cd - > /dev/null
}

main
