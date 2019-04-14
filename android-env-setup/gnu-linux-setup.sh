#!/bin/bash

#------------------------------------------------------------------------------#
# Android开发环境搭建脚本
# 目前只支持Debian GNU/Linux、Ubuntu、CentOS、Fedora等系统
#------------------------------------------------------------------------------#

JDK_URL=https://download.oracle.com/otn-pub/java/jdk/8u201-b09/42970487e3af4f5aa5bca3f542482c60/jdk-8u201-linux-x64.tar.gz

# https://developer.android.google.cn/studio/index.html
ANDROID_SDK_URL=https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip

# http://tools.android.com/download/studio/canary
# https://developer.android.google.cn/studio/index.html
ANDROID_STUDIO_URL=https://dl.google.com/dl/android/studio/ide-zips/3.3.2.0/android-studio-ide-182.5314842-linux.zip

# Android SDK Framework API Level
ANDROID_SDK_FRAMEWORK_VERSION=28

# 构建工具的版本
ANDROID_SDK_BUILD_TOOLS_VERSION=28.0.3

#安装目录，要修改的话，注意权限问题
WORK_DIR=/usr/local/share

#------------------------------------------------------------------------------#

# 安装依赖库和工具
function installDependency() {
    # 如果是Debian GNU/Linux、Ubuntu系统
    if [ -f "/etc/lsb-release" ] || [ -f "/etc/debian_version" ] ; then
        sudo apt-get -y update
        sudo apt-get -y install gcc-multilib lib32z1 lib32stdc++6
        sudo apt-get -y install git subversion vim curl wget zip unzip
    # 如果是CentOS、Fedora系统
    elif [ -f "/etc/redhat-release" ] || [ -f "/etc/fedora-release" ] ; then
        sudo yum -y update
        sudo yum -y install glibc.i686 zlib.i686 libstdc++.i686
        sudo yum -y install git subversion vim curl wget
    fi
}

# 下载JDK
function downloadJDKIfNeeded() {
    fileName=`basename "$JDK_URL"`

    if [ -f "${fileName}" ] ; then
        tar -tf ${fileName} &> /dev/null || {
            rm ${fileName}
            downloadingJDK
      }
    else
        downloadingJDK
    fi
}

function downloadingJDK() {
    echo "downloadingJDK..."
    wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "$JDK_URL"
}

function untarJDK() {
    tar zxf `basename "$JDK_URL"` -C ${WORK_DIR}
}

# 配置JDK环境变量
function configJDKEnv() {
    local fileName=`basename "$JDK_URL"`
    local dirName=`tar -tf ${fileName} | awk -F/ '{print $1}' | sort | uniq`
    local javaHome=${WORK_DIR}/${dirName}
    
    if [ -f "~/.bashrc" ] ; then
        echo "export JAVA_HOME=${javaHome}" >> ~/.bashrc
        echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
        echo "export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> ~/.bashrc
        source ~/.bashrc
    elif [ -f "~/.zshrc" ] ; then
        echo "export JAVA_HOME=${javaHome}" >> ~/.zshrc
        echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.zshrc
        echo "export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> ~/.zshrc
        source ~/.zshrc
    fi
}

# 下载文件
function downloadFile() {
    local fileName=`basename "$1"`

    if [ -f "${fileName}" ] ; then
        unzip -t ${fileName} &> /dev/null || {
            rm ${fileName}
            wget "$1"
        }
    else
        wget "$1"
    fi
}

function unzipAndroidSDK() {
    [ -d "android-sdk" ] || mkdir android-sdk
    unzip `basename "$ANDROID_SDK_URL"` -d android-sdk
}

# 更新Android SDK
function updateAndroidSDK() {
    local sdkmanager="android-sdk/tools/bin/sdkmanager"
    echo y | $sdkmanager "platforms;android-${ANDROID_SDK_FRAMEWORK_VERSION}" && \
    echo y | $sdkmanager "platform-tools" && \
    echo y | $sdkmanager "build-tools;${ANDROID_SDK_BUILD_TOOLS_VERSION}"
}

# 配置Android SDK的环境变量
function configAndroidSDKEnv() {
    local androidHome=${WORK_DIR}/android-sdk
    
    if [ -f "~/.bashrc" ] ; then
        echo "export ANDROID_HOME=${androidHome}" >> ~/.bashrc
        echo "export PATH=\$ANDROID_HOME/tools:\$ANDROID_HOME/tools/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/build-tools/${ANDROID_SDK_BUILD_TOOLS_VERSION}:\$PATH" >> ~/.bashrc
        source ~/.bashrc
    elif [ -f "~/.zshrc" ] ; then
        echo "export ANDROID_HOME=${androidHome}" >> ~/.zshrc
        echo "export PATH=\$ANDROID_HOME/tools:\$ANDROID_HOME/tools/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/build-tools/${ANDROID_SDK_BUILD_TOOLS_VERSION}:\$PATH" >> ~/.zshrc
        source ~/.zshrc
    fi
}

function unzipAndroidStudio() {
    unzip `basename "$ANDROID_STUDIO_URL"`
}

function main() {
    # 如果不存在此文件夹，就创建
    ([ -d "${WORK_DIR}" ] || mkdir -p ${WORK_DIR}) && cd $WORK_DIR

    installDependency

    downloadJDKIfNeeded && untarJDK && configJDKEnv

    dowloadFile "$ANDROID_SDK_URL" && unzipAndroidSDK && configAndroidSDKEnv && updateAndroidSDK

    downloadFile "$ANDROID_STUDIO_URL" unzipAndroidStudio
    
    cd - &> /dev/null
}

main
