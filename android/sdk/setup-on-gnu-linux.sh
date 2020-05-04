#!/bin/sh

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

export ANDROID_HOME="${DEST_DIR}/android-sdk"

#------------------------------------------------------------------------------#

JDK_FILE_NAME=$(basename "$JDK_URL")
ANDROID_SDK_FILE_NAME=$(basename "$ANDROID_SDK_URL")
ANDROID_STUDIO_FILE_NAME=$(basename "$ANDROID_STUDIO_URL")

Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b\n" "$1"
}

info() {
    msg "${Color_Purple}[❉]${Color_Off} $1$2"
}

writeJDKEnv() {
    cat > "$1" << EOF
export JAVA_HOME=$JAVA_HOME
export PATH=\$JAVA_HOME/bin:\$PATH
export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar
EOF
}

# 配置JDK环境变量
configJDKEnv() {
    dirName=$(tar -tf "$JDK_FILE_NAME" | awk -F/ '{print $2}' | sort | uniq)
    
    export JAVA_HOME=${DEST_DIR}/${dirName}
    export PATH=$JAVA_HOME/bin:$PATH
    export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
    
    writeJDKEnv "$HOME/.bashrc"
    writeJDKEnv "$HOME/.zshrc"
}

# 下载文件
downloadFile() {
    info "Downloading $1"
    fileName=$(basename "$1")
    extension=$(echo "$fileName" | awk -F. '{print $NF}')
    if [ -f "$fileName" ] ; then
        if [ "$extension" = "zip" ] ; then
            unzip -t "$fileName" > /dev/null || curl -C - -LO "$1"
        elif [ "$extension" = "gz" ] ; then 
            tar -tf "$fileName" > /dev/null || curl -C - -LO "$1"
        fi
    else
        curl -C - -LO "$1"
    fi
}

# 更新Android SDK
updateAndroidSDK() {
    info "Updating AndroidSDK..."
    sdkmanager="$ANDROID_HOME/tools/bin/sdkmanager"
    echo y | $sdkmanager "platforms;android-${ANDROID_SDK_FRAMEWORK_VERSION}" && \
    echo y | $sdkmanager "platform-tools" && \
    echo y | $sdkmanager "build-tools;${ANDROID_SDK_BUILD_TOOLS_VERSION}"
    echo y | $sdkmanager "ndk-bundle"
}

writeAndroidSDKEnv() {
    cat > "$1" << EOF
export ANDROID_HOME=$ANDROID_HOME
export PATH=\$ANDROID_HOME/tools:\$ANDROID_HOME/tools/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/build-tools/${ANDROID_SDK_BUILD_TOOLS_VERSION}:\$PATH
export ANDROID_NDK_HOME=\$ANDROID_HOME/ndk-bundle
export PATH=\$PATH:\$ANDROID_NDK_HOME
EOF
}

# 配置Android SDK的环境变量
configAndroidSDKEnv() {
    export PATH=$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/${ANDROID_SDK_BUILD_TOOLS_VERSION}:$PATH
    export ANDROID_NDK_HOME=$ANDROID_HOME/ndk-bundle
    export PATH=$PATH:$ANDROID_NDK_HOME
    
    writeAndroidSDKEnv "$HOME/.bashrc"
    writeAndroidSDKEnv "$HOME/.zshrc"
}

checkDependencies() {
    info "Checking Dependencies"
    command -v git    > /dev/null || pkgNames="git"
    command -v curl   > /dev/null || pkgNames="$pkgNames curl"
    command -v zip    > /dev/null || pkgNames="$pkgNames zip"
    command -v unzip  > /dev/null || pkgNames="$pkgNames unzip"
    command -v grep   > /dev/null || pkgNames="$pkgNames grep"
}

installDependencies() {
    info "Installing Dependencies $pkgNames"

    command -v apt-get > /dev/null && {
        $sudo apt-get -y update &&
        $sudo apt-get -y install $@
        return 0
    }
     
    command -v dnf > /dev/null && {
        $sudo dnf -y update &&
        $sudo dnf -y install $@
        return 0
    }
    
    command -v yum > /dev/null && {
        $sudo yum -y update &&
        $sudo yum -y install $@
        return 0
    }
    
    command -v zypper > /dev/null && {
        $sudo zypper update -y &&
        $sudo zypper install -y $@
        return 0
    }
    
    command -v apk > /dev/null && {
        $sudo apk update &&
        $sudo apk add $@
        return 0
    }
    
    command -v pacman > /dev/null && {
        $sudo pacman -Syyuu --noconfirm &&
        $sudo pacman -S     --noconfirm $@
        return 0
    }
}

main() {
    [ "$(uname -s)" = "Linux" ] || {
        printf "%s\n" "your os is not GNU/Linux!!"
        exit 1
    }

    [ "$(whoami)" = "root" ] || sudo=sudo
    
    checkDependencies

    [ -z "$pkgNames" ] || installDependencies "$pkgNames"

    [ -d "$DEST_DIR" ]     || $sudo install -d -o "$(whoami)" "$DEST_DIR"
    [ -d "$ANDROID_HOME" ] || $sudo install -d -o "$(whoami)" "$ANDROID_HOME"
    
    cd "$DEST_DIR" || exit 1

    downloadFile "$JDK_URL" &&
    tar zvxf "$JDK_FILE_NAME" &&
    configJDKEnv

    downloadFile "$ANDROID_SDK_URL" &&
    unzip -o "$ANDROID_SDK_FILE_NAME" -d "$ANDROID_HOME" &&
    configAndroidSDKEnv &&
    updateAndroidSDK

    downloadFile "$ANDROID_STUDIO_URL" &&
    unzip -o "$ANDROID_STUDIO_FILE_NAME"
}

main
