#!/bin/bash

#------------------------------------------------------------------------------#
# Android开发环境搭建脚本
# 该脚本只支持Mac OS X 系统
# 需要注意的是：支持GNU/Linux的JDK和Android Studio的tar.gz包是同时也支持MacOSX的
# 但是我们选择使用dmg包，这样可能会更好的利用系统特性
#------------------------------------------------------------------------------#

WORK_DIR=~/bin

JDK_URL=http://download.oracle.com/otn-pub/java/jdk/8u111-b14/jdk-8u111-macosx-x64.dmg

# Google专门为中国的开发者提供了中国版本的服务，但是下载地址仍然是国外的
# https://developer.android.google.cn/studio/index.html
ANDROID_SDK_URL=https://dl.google.com/android/repository/tools_r25.2.3-macosx.zip

# SDK framework API level
ANDROID_SDK_FRAMEWORK_VERSION=23

# 构建工具的版本
ANDROID_SDK_BUILD_TOOLS_VERSION=23.0.2

# http://tools.android.com/download/studio/canary
# https://developer.android.google.cn/studio/index.html
ANDROID_STUDIO_URL=https://dl.google.com/dl/android/studio/install/2.2.3.0/android-studio-ide-145.3537739-mac.dmg

#------------------------------------------------------------------------------#

function installCommandLineDeveloperTools() {
    which git > /dev/null
    if [ $? -eq 0 ] ; then
        echo "CommandLineDeveloperTools already installed!"
    else
        xcode-select --install
    fi
}

function installBrew() {
    which brew > /dev/null
    if [ $? -eq 0 ] ; then
        echo "brew already installed!"
    else
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi                                                                         
}

function installByBrew() {
    which "$1"  > /dev/null
    if [ $? -eq 0 ] ; then
        echo "$1 already installed!"
    else
        brew install "$2"
    fi
}

function _downloadJDK() {
    wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" ${JDK_URL}
}

function _installJDK() {
    cd /Volumes
    dir="`ls -d JDK* | sed 's/\ /\\ /g'`"
    cd $dir
    sudo installer -pkg "`ls *.pkg | sed 's/\ /\\ /g'`" -target /Applications
    cd ~
    hdiutil detach /Volumes/$dir
}

function _downloadAndInstallJDK() {
    url=$ANDROID_STUDIO_URL
    fileName=`basename "$url"`

    _downloadJDK
    hdiutil attach ${fileName}
    if [ $? -eq 0 ] ; then
        _installJDK
    else
        echo "not recognized dmg file!"
        exit 1;
    fi
}

function downloadAndInstallJDK() {
    url=$JDK_URL
    fileName=`basename "$url"`

    if [ -f "${fileName}" ] ; then
        hdiutil attach ${fileName}
        if [ $? -eq 0 ] ; then
            installJDK
        else
            rm ${fileName}
            _downloadAndInstallJDK
        fi
    else
        _downloadAndInstallJDK
    fi
}

function _installAndroidStudio() {
    cd /Volumes
    dir="`ls -d Android\ Studio* | sed 's/\ /\\ /g'`"
    cd $dir
    sudo cp -r Android\ Studio.app /Applications/
    cd ~
    hdiutil detach /Volumes/$dir
}

function _downloadAndInstallAndroidStudio() {
    url=$ANDROID_STUDIO_URL
    fileName=`basename "$url"`

    # 下载并安装Android Studio
    curl -O ${url}
    hdiutil attach ${fileName}
    if [ $? -eq 0 ] ; then
        _installAndroidStudio
    else
        echo "not recognized dmg file!"
        exit 1;
    fi
}

function downloadAndInstallAndroidStudio() {
    url=$ANDROID_STUDIO_URL
    fileName=`basename "$url"`

    if [ -f "${fileName}" ] ; then
        hdiutil attach ${fileName}
        if [ $? -eq 0 ] ; then
            _installAndroidStudio
        else
            rm ${fileName}
            _downloadAndInstallAndroidStudio
        fi
    else
        _downloadAndInstallAndroidStudio
    fi       
}

function downloadAndInstallAndroidSDK() {
    url=$ANDROID_SDK_URL
    fileName=`basename "$url"`

    if [ -f "${fileName}" ] ; then
        unzip -t ${fileName} > /dev/null
        if [ $? -eq 0 ] ; then
            unzip ${fileName} -d ${WORK_DIR}
        else
            rm ${fileName}

            curl -O ${url} && \
            unzip ${fileName} -d ${WORK_DIR}
        fi
    else
        curl -O ${url} && \
        unzip ${fileName} -d ${WORK_DIR}
    fi
}


#配置环境变量
function configEnv() {
    androidHome=${WORK_DIR}/android-sdk-macosx
    echo "export ANDROID_HOME=${androidHome}" >> ~/.bashrc
    echo "export PATH=$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/${ANDROID_SDK_BUILD_TOOLS_VERSION}:'$PATH'" >> ~/.bashrc

    source ~/.bashrc
}

# 更新Android SDK
function updateAndroidSDK() {
    echo y | android update sdk --no-ui --all --filter android-${ANDROID_SDK_FRAMEWORK_VERSION},platform-tools,build-tools-${ANDROID_SDK_BUILD_TOOLS_VERSION},extra-android-m2repository
}

function main() {
    # 如果不是MacOSX系统就退出
    if [ "uname -s" != "Darwin" ] ; then
        echo "your system os is not mac os"
        exit 1;
    fi

    # 如果不存在此文件夹，就创建
    if [ ! -d "${WORK_DIR}" ]; then
        mkdir -p ${WORK_DIR}
    fi

    cd ~
    
    installCommandLineDeveloperTools

    installBrew

    installByBrew curl curl
    installByBrew wget wget
    installByBrew vim vim
    
    downloadAndInstallJDK

    downloadAndInstallAndroidSDK

    downloadAndInstallAndroidStudio

    configEnv

    updateAndroidSDK
    
    cd - > /dev/null
}

main
