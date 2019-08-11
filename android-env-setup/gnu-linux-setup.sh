#!/bin/bash

#------------------------------------------------------------------------------#
# Android开发环境搭建脚本
# 只支持GNU/Linux 64bit 系统
#------------------------------------------------------------------------------#

JDK_URL=https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u192-b12/OpenJDK8U-jdk_x64_linux_hotspot_8u192b12.tar.gz

# https://developer.android.google.cn/studio/index.html
ANDROID_SDK_URL=https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip

# http://tools.android.com/download/studio/canary
# https://developer.android.google.cn/studio/index.html
ANDROID_STUDIO_URL=https://dl.google.com/dl/android/studio/ide-zips/3.3.2.0/android-studio-ide-182.5314842-linux.zip

# Android SDK Framework API Level
ANDROID_SDK_FRAMEWORK_VERSION=28

# 构建工具的版本
ANDROID_SDK_BUILD_TOOLS_VERSION=28.0.3

# 安装目录
DEST_DIR=/usr/local/opt

#------------------------------------------------------------------------------#

# 配置JDK环境变量
function configJDKEnv() {
    local fileName=`basename "$JDK_URL"`
    local dirName=`tar -tf "$fileName" | awk -F/ '{print $2}' | sort | uniq`
    local javaHome=${DEST_DIR}/${dirName}
    
    [ -f "jdk-env" ] && rm jdk-env
    cat > jdk-env << EOF
export JAVA_HOME=${javaHome}
export PATH=\$JAVA_HOME/bin:\$PATH
export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar
EOF
    echo "source \"$DEST_DIR/jdk-env\"" >> ~/.bashrc
    echo "source \"$DEST_DIR/jdk-env\"" >> ~/.zshrc

    source "$DEST_DIR/jdk-env"
}

# 下载文件
function downloadFile() {
    local fileName=`basename "$1"`
    local extension=`echo "$fileName" | awk -F. '{print $NF}'`
    if [ -f "$fileName" ] ; then
        if [ "$extension" == "zip" ] ; then
            unzip -t "$fileName" &> /dev/null || curl -C - -LO "$1"
        elif [ "$extension" == "gz" ] ; then 
            tar -tf "$fileName" &> /dev/null || curl -C - -LO "$1"
        fi
    else
        curl -C - -LO "$1"
    fi
}

# 更新Android SDK
function updateAndroidSDK() {
    local sdkmanager="android-sdk/tools/bin/sdkmanager"
    echo y | $sdkmanager "platforms;android-${ANDROID_SDK_FRAMEWORK_VERSION}" && \
    echo y | $sdkmanager "platform-tools" && \
    echo y | $sdkmanager "build-tools;${ANDROID_SDK_BUILD_TOOLS_VERSION}"
    echo y | $sdkmanager "ndk-bundle"
}

# 配置Android SDK的环境变量
function configAndroidSDKEnv() {
    local androidHome="${DEST_DIR}/android-sdk"
    
    [ -f "android-env" ] && rm android-env
    cat > android-env << EOF
export ANDROID_HOME=${androidHome}
export PATH=\$ANDROID_HOME/tools:\$ANDROID_HOME/tools/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/build-tools/${ANDROID_SDK_BUILD_TOOLS_VERSION}:\$PATH
export ANDROID_NDK_HOME=\$ANDROID_HOME/ndk-bundle
export PATH=\$PATH:\$ANDROID_NDK_HOME
EOF
    
    echo "source \"$DEST_DIR/android-env\"" >> ~/.bashrc
    echo "source \"$DEST_DIR/android-env\"" >> ~/.zshrc

    source "$DEST_DIR/android-env"
}

function main() {
    [ `uname -s` == "Linux" ] || {
        echo "your os is not GNU/Linux!!"
        exit 1
    }

    [ `whoami` == "root" ] || sudo=sudo
    
    command -v apt-get &> /dev/null && {
        $sudo apt-get -y update
        $sudo apt-get -y install git vim curl httpie zip unzip
    }
     
    command -v dnf &> /dev/null && {
        $sudo dnf -y update
        $sudo dnf -y install git vim curl httpie zip unzip
        installed=true
    }
    
    [ "$installed" == "true" ] || command -v yum &> /dev/null && {
        $sudo yum -y update
        $sudo yum -y install git vim curl httpie zip unzip
    }
    
    command -v zypper &> /dev/null && {
        $sudo zypper update -y
        $sudo zypper install -y git vim curl httpie zip unzip
    }
    
    [ -d "$DEST_DIR" ] || $sudo mkdir -p "$DEST_DIR"
    $sudo chown -R `whoami` "$DEST_DIR"
    cd "$DEST_DIR"

    downloadFile "$JDK_URL" && \
    tar zvxf `basename "$JDK_URL"` && \
    configJDKEnv

    downloadFile "$ANDROID_SDK_URL" && \
    unzip -o `basename "$ANDROID_SDK_URL"` -d android-sdk && \
    updateAndroidSDK && \
    configAndroidSDKEnv

    downloadFile "$ANDROID_STUDIO_URL" && \
    unzip -o `basename "$ANDROID_STUDIO_URL"`
}

main
