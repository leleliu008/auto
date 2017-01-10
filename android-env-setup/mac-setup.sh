#!/bin/bash

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
cd ${WORK_DIR}

# 下载JDK
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" ${JDK_URL} && \
    sudo tar xf ${JDK_FILENAME} && \
    sudo rm -rf ${JDK_FILENAME}

# 下载Android SDK
curl -O ${ANDROID_SDK_URL} && \
    sudo tar xf ${ANDROID_SDK_FILENAME} && \
    sudo rm -rf ${ANDROID_SDK_FILENAME}

#配置环境变量
echo "export JAVA_HOME=${JAVA_HOME}" >> ~/.bashrc
echo "export PATH=${JAVA_HOME}/bin:'${PATH}'" >> ~/.bashrc
echo "export CLASSPATH=.:${JAVA_HOME}/lib/dt.jar:${JAVA_HOME}/lib/tools.jar" >> ~/.bashrc

echo "export ANDROID_HOME=${ANDROID_HOME}" >> ~/.bashrc
echo "export PATH=$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/${ANDROID_SDK_BUILD_TOOLS_VERSION}:'$PATH'" >> ~/.bashrc

source ~/.bashrc

# 更新Android SDK
echo y | android update sdk --no-ui --all --filter android-${ANDROID_SDK_FRAMEWORK_VERSION},platform-tools,build-tools-${ANDROID_SDK_BUILD_TOOLS_VERSION},extra-android-m2repository
