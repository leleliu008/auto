#!/bin/bash

#------------------------------------------------------------------------------#
# Android开发环境搭建脚本
# 该脚本只支持Mac OS X 系统
# 需要注意的是：支持GNU/Linux的JDK和Android Studio的tar.gz包是同时也支持MacOSX的
# 但是我们选择使用dmg包，这样可能会更好的利用系统特性
#------------------------------------------------------------------------------#

WORK_DIR=~/bin

JDK_FILENAME=jdk-8u111-macosx-x64.dmg
JDK_URL=http://download.oracle.com/otn-pub/java/jdk/8u111-b14/${JDK_FILENAME}

ANDROID_HOME=${WORK_DIR}/android-sdk-macosx
ANDROID_SDK_FILENAME=tools_r25.2.3-macosx.zip

# Google专门为中国的开发者提供了中国版本的服务，但是下载地址仍然是国外的
# https://developer.android.google.cn/studio/index.html
ANDROID_SDK_URL=https://dl.google.com/android/repository/${ANDROID_SDK_FILENAME}

# SDK framework API level
ANDROID_SDK_FRAMEWORK_VERSION=23

# 构建工具的版本
ANDROID_SDK_BUILD_TOOLS_VERSION=23.0.2

ANDROID_STUDIO_FILENAME=android-studio-ide-145.3537739-mac.dmg

# 查看要安装的版本：
# http://tools.android.com/download/studio/canary
# https://developer.android.google.cn/studio/index.html
ANDROID_STUDIO_URL=https://dl.google.com/dl/android/studio/install/2.2.3.0/${ANDROID_STUDIO_FILENAME}
#------------------------------------------------------------------------------#

# 如果不是MacOSX系统就退出
if [ "uname -s" != "Darwin" ] ; then
    echo "your system os is not mac os"
    exit 1;
fi

#安装command line developer tools
which git
if [ $? -eq 0 ] ; then
    echo "command line developer tools already installed!"
else
    # 这里会弹出一个GUI界面
    xcode-select --install
fi

# 安装HomeBrew这个包管理工具
which brew
if [ $? -eq 0 ] ; then
    echo "brew already installed!"
else
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# 安装依赖库和工具
sudo brew update
sudo brew install -y vim wget

# 如果不存在此文件夹，就创建
if [ ! -d "${WORK_DIR}" ]; then
    mkdir -p ${WORK_DIR}
fi

if [ -f "${JDK_FILENAME}" ] ; then
    rm ${JDK_FILENAME}
fi

# 下载并安装JDK
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" ${JDK_URL}

if [ $? -eq 0 ] ; then
    hdiutil attach ${JDK_FILENAME}
    if [ $? -eq 0 ] ; then
        cd /Volumes
        cd  "`ls -d JDK* | sed 's/\ /\\ /g'`"
        sudo installer -pkg "`ls *.pkg | sed 's/\ /\\ /g'`" -target /Applications
        hdiutil detach .
        cd ~
    else
        echo "not recognized dmg file!"
        exit 1;
    fi
    rm -rf ${JDK_FILENAME}
else
    echo "JDK download error!"
    exit 1;
fi

if [ -f "${ANDROID_STUDIO_FILENAME}" ] ; then
    rm ${ANDROID_STUDIO_FILENAME}
fi

# 下载并安装Android Studio
wget ${ANDROID_STUDIO_URL}
if [ $? -eq 0 ] ; then
    hdiutil attach ${ANDROID_STUDIO_FILENAME}
    if [ $? -eq 0 ] ; then
        cd /Volumes
        cd  "`ls -d Android\ Studio* | sed 's/\ /\\ /g'`"
        sudo cp -r Android\ Studio.app /Applications/
        hdiutil detach .
        cd ~
    else
        echo "not recognized dmg file!"
        exit 1;
    fi
    rm -rf ${ANDROID_STUDIO_FILENAME}
else
    echo "Android Studio download error!"
    exit 1;
fi


if [ -f "${ANDROID_SDK_FILENAME}" ] ; then
    rm ${ANDROID_SDK_FILENAME}
fi

# 下载Android SDK
curl -O ${ANDROID_SDK_URL} && \
    unzip ${ANDROID_SDK_FILENAME} -d ${WORK_DIR} && \
    rm -rf ${ANDROID_SDK_FILENAME}

#配置环境变量
echo "export ANDROID_HOME=${ANDROID_HOME}" >> ~/.bashrc
echo "export PATH=$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/${ANDROID_SDK_BUILD_TOOLS_VERSION}:'$PATH'" >> ~/.bashrc

source ~/.bashrc

# 更新Android SDK
echo y | android update sdk --no-ui --all --filter android-${ANDROID_SDK_FRAMEWORK_VERSION},platform-tools,build-tools-${ANDROID_SDK_BUILD_TOOLS_VERSION},extra-android-m2repository
