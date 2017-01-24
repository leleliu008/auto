#!/bin/bash

#------------------------------------------------------------------------------#
# 开发环境搭建脚本
# 目前只支持Ubuntu、CentOS、MacOSX系统
# 搭建的环境包括Java、Android、iOS、Node.js
#
# 默认安装的软件：
# brew、git、subversion、curl、wget、zip、unzip、tree、ruby、vim、node.js、npm、jdk
# 
# 特殊说明：
# 1、npm的源使用的是淘宝的
# 2、对于vim，安装了Vundle插件管理工具和一些常用插件，并修改了当前用户的配置
#------------------------------------------------------------------------------#

#--------------------------------- 要安装的软件 ---------------------------------#

httpie=true   #接口调试工具

sublime=true  #前端开发工具
webstorm=true #前端开发工具
eclipse=true  #Java EE开发工具

tomcat=true   #Servlet容器
jenkins=true  #持续集成工具
maven=true    #Java EE开发必备
gradle=true   #Java EE开发备选

androidSDK=true    #Android开发环境
androidNDK=true    #Android开发环境
androidStudio=true #Android开发工具
apktool=true       #Android反编译工具

mysql=true

docker=true

#------------------------下面的变量可以根据自己的需要修改----------------------#

# 以tar.gz、tgz、zip包安装的时候，解压到的目录
# 不要修改到需要root权限的目录下，修改到~的任意子目录都可以
WORK_DIR=~/bin

JDK_URL=http://download.oracle.com/otn-pub/java/jdk/8u65-b17/jdk-8u65-linux-x64.tar.gz

TOMCAT_URL=http://mirror.bit.edu.cn/apache/tomcat/tomcat-8/v8.5.9/bin/apache-tomcat-8.5.9.tar.gz

# Google专门为中国的开发者提供了中国版本的服务，但是下载地址仍然是国外的
# https://developer.android.google.cn/studio/index.html
ANDROID_SDK_URL=http://dl.google.com/android/android-sdk_r24.4.1-linux.tgz

# SDK framework API level
ANDROID_SDK_FRAMEWORK_VERSION=23

# 构建工具的版本
ANDROID_SDK_BUILD_TOOLS_VERSION=23.0.2

# https://developer.android.google.cn/ndk/index.html
ANDROID_NDK_URL=http://dl.google.com/android/android-sdk_r24.4.1-linux.tgz

# http://tools.android.com/download/studio/canary
# https://developer.android.google.cn/studio/index.html
ANDROID_STUDIO_URL=https://dl.google.com/dl/android/studio/ide-zips/2.2.3.0/android-studio-ide-145.3537739-linux.zip

#------------------------------------------------------------------------------#

# 安装依赖库和工具
function installDependency() {
    # 如果是Ubuntu系统
    if [ -f "/etc/lsb-release" ] ; then
        sudo apt-get update
        echo "----------------------------------------------------------------"
        sudo apt-get install -y gcc-multilib lib32z1 lib32stdc++6
        echo "----------------------------------------------------------------"
        sudo apt-get install -y git
        echo "----------------------------------------------------------------"
        sudo apt-get install -y subversion
        echo "----------------------------------------------------------------"
        sudo apt-get install -y curl
        echo "----------------------------------------------------------------"
        sudo apt-get install -y wget
        echo "----------------------------------------------------------------"
        sudo apt-get install -y zip
        echo "----------------------------------------------------------------"
        sudo apt-get install -y unzip
        echo "----------------------------------------------------------------"
        sudo apt-get install -y tree
        echo "----------------------------------------------------------------"
        sudo apt-get install -y vim
        echo "----------------------------------------------------------------"
        sudo apt-get install -y ruby
        echo "----------------------------------------------------------------"
    # 如果是CentOS系统
    elif [ -f "/etc/redhat-release" ] ; then
        sudo yum update
        echo "----------------------------------------------------------------"
        sudo yum install -y glibc.i686 zlib.i686 libstdc++.i686
        echo "----------------------------------------------------------------"
        sudo yum install -y git
        echo "----------------------------------------------------------------"
        sudo yum install -y subversion
        echo "----------------------------------------------------------------"
        sudo yum install -y curl
        echo "----------------------------------------------------------------"
        sudo yum install -y wget
        echo "----------------------------------------------------------------"
        sudo yum install -y zip
        echo "----------------------------------------------------------------"
        sudo yum install -y unzip
        echo "----------------------------------------------------------------"
        sudo yum install -y tree
        echo "----------------------------------------------------------------"
        sudo yum install -y vim
        echo "----------------------------------------------------------------"
        sudo yum install -y ruby
        echo "----------------------------------------------------------------"
    fi
}

# 配置Brew的环境变量
function configBrewEnv() {
    echo "# -----------------------------------------------" >> ~/.bashrc
    echo "export PATH=~/.linuxbrew/bin:\$PATH" >> ~/.bashrc
    echo "export MANPATH=~/.linuxbrew/share/man:\$MANPATH" >> ~/.bashrc
    echo "export INFOPATH=~/.linuxbrew/share/info:\$INFOPATH" >> ~/.bashrc
    source ~/.bashrc
}

# 安装LinuxBrew
function installBrew() {
    which brew
    if [ $? -eq 0 ] ; then
        echo "brew is already installed!"
        return 0
    fi

    if [ -f "/etc/lsb-release" ] ; then
        sudo apt-get install -y build-essential m4 python-setuptools texinfo libbz2-dev \
                                libcurl4-openssl-dev libexpat-dev libncurses-dev zlib1g-dev && \
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)" && \
        configBrewEnv
    elif [ -f "/etc/redhat-release" ] ; then
        sudo yum groupinstall -y 'Development Tools' && \
        sudo yum install -y irb python-setuptools && \
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)" && \
        configBrewEnv
    fi
}

# 下载并解压.tar.gz或者.tgz文件
# $1是要下载文件的URL
# $2是要解压到到目录，如果为空字符串，表示不解压
function downloadTGZFileAndExtractTo() {
    fileName=`basename "$1"`
    if [ -f "${fileName}" ] ; then
        tar -tf ${fileName} > /dev/null
        if [ $? -eq 0 ] ; then
            echo "$fileName is exsit, not need to download"
            if [ "$2" != "" ] ; then
                tar zxf ${fileName} -C "$2"
            fi
        else
            rm ${fileName}
            
            wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "$1"
            if [ $? -eq 0 ] && [ "$2" != "" ] ; then
                tar zxf ${fileName} -C "$2"
            fi
        fi
    else
        wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "$1"
        if [ $? -eq 0 ] && [ "$2" != "" ] ; then
            tar zxf ${fileName} -C "$2"
        fi
    fi
}
    
# 下载并解压.zip
# $1是要下载文件的URL
# $2是要解压到的目录，如果字符串为空，表示不解压
function downloadZipFileAndExtractTo() {
    fileName=`basename "$1"`
    if [ -f "${fileName}" ] ; then
        unzip -t ${fileName} > /dev/null
        if [ $? -eq 0 ] ; then
            echo "$fileName is exsit, not need to download"
            if [ "$2" != "" ] ; then
                unzip ${fileName} -d "$2" > /dev/null
            fi
        else
            rm ${fileName}
            wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "$1"
            if [ $? -eq 0 ] && [ "$2" != "" ] ; then
                unzip ${fileName} -d "$2" > /dev/null
            fi
        fi
    else
        wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "$1"
        if [ $? -eq 0 ] && [ "$2" != "" ] ; then
            unzip ${fileName} -d "$2" > /dev/null
        fi
    fi
}

# 下载文件并解压到指定目录
# $1是要下载文件的URL
# $2是要解压到的目录，如果字符串为空，就表示不解压
function downloadFileAndExtractTo() {
    fileName=`basename "$1"`
    extension=`echo "${fileName##*.}"`
    
    if [ "$extension" = "tgz" ] ; then
        downloadTGZFileAndExtractTo "$1" "$2"
    elif [ "$extension" = "gz" ] ; then
        downloadTGZFileAndExtractTo "$1" "$2"
    elif [ "$extension" = "zip" ] ; then
        downloadZipFileAndExtractTo "$1" "$2"
    elif [ "$extension" = "war" ] ; then
        downloadZipFileAndExtractTo "$1" "$2"
    elif [ "$extension" = "jar" ] ; then
        downloadZipFileAndExtractTo "$1" "$2"
    fi
}

# 下载JDK
function downloadJDKAndConfig() {
    which java
    if [ $? -eq 0 ] ; then
        echo "JDK is already installed! so, not need to download and config"
    else
        downloadFileAndExtractTo $JDK_URL ${WORK_DIR}

        if [ $? -eq 0 ]; then
            fileName=`basename "$JDK_URL"`
            dirName=`tar -tf ${fileName} | awk -F "/" '{print $1}' | sort | uniq`
            javaHome=${WORK_DIR}/${dirName}

            #配置环境变量
            echo "# -----------------------------------------------" >> ~/.bashrc
            echo "export JAVA_HOME=${javaHome}" >> ~/.bashrc
            echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
            echo "export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> ~/.bashrc
            source ~/.bashrc
        fi
    fi
}

# 配置环境变量
function configAndroidSDKEnv() {
    androidHome=${WORK_DIR}/android-sdk-linux
    echo "# -----------------------------------------------" >> ~/.bashrc
    echo "export ANDROID_HOME=${androidHome}" >> ~/.bashrc
    echo "export PATH=\$ANDROID_HOME/tools:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/build-tools/${ANDROID_SDK_BUILD_TOOLS_VERSION}:\$PATH" >> ~/.bashrc

    source ~/.bashrc
}

# 更新Android SDK
function updateAndroidSDK() {
    echo "----------------------------------------------------------------"
    echo "updateAndroidSDK..."
    echo y | android update sdk --no-ui --all --filter android-${ANDROID_SDK_FRAMEWORK_VERSION},platform-tools,build-tools-${ANDROID_SDK_BUILD_TOOLS_VERSION},extra-android-m2repository
}


function main() {

    # 如果不存在此文件夹，就创建
    if [ ! -d "${WORK_DIR}" ] ; then
        mkdir -p ${WORK_DIR}
    fi

    cd ~

    installDependency

    installBrew

    echo "----------------------------------------------------------------"

    brew install node

    echo "----------------------------------------------------------------"

    brew install npm && \
    npm config set registry https://registry.npm.taobao.org

    echo "----------------------------------------------------------------"

    if [ -f "/etc/lsb-release" ] ; then
        if [ $docker ] ; then
            sudo apt-get install -y docker
            echo "----------------------------------------------------------------"
        fi

        if [ $httpie ] ; then
            sudo apt-get install -y httpie
            echo "----------------------------------------------------------------"
        fi
    elif [ -f "/etc/redhat-release" ] ; then
        if [ $docker ] ; then
            sudo yum install -y docker
            echo "----------------------------------------------------------------"
        fi

        if [ $httpie ] ; then
            sudo yum install -y httpie
            echo "----------------------------------------------------------------"
        fi
    fi

    downloadJDKAndConfig

    echo "----------------------------------------------------------------"

    if [ $maven ] ; then
        brew install maven
        echo "----------------------------------------------------------------"
    fi

    if [ $gradle ] ; then
        brew install gradle
        echo "----------------------------------------------------------------"
    fi

    if [ $jenkins ] ; then
        brew install jenkins
        echo "----------------------------------------------------------------"
    fi

    if [ $tomcat ] ; then
        downloadFileAndExtractTo "$TOMCAT_URL" "$WORK_DIR"
        echo "----------------------------------------------------------------"
    fi

    if [ $androidSDK ] ; then
        downloadFileAndExtractTo "$ANDROID_SDK_URL" "$WORK_DIR" && \
        configAndroidSDKEnv && \
        updateAndroidSDK
        echo "----------------------------------------------------------------"
    fi

    if [ $apktool ]; then
        brew install apktool
        echo "----------------------------------------------------------------"
    fi

    if [ $androidStudio ] ; then
        downloadFileAndExtractTo "$ANDROID_STUDIO_URL" "$WORK_DIR"
        echo "----------------------------------------------------------------"
    fi
    
    cd - > /dev/null
}

main
