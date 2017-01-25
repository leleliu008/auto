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

mysql=true
docker=true
nginx=true

androidSDK=true    #Android开发环境
androidNDK=true    #Android开发环境
androidStudio=true #Android开发工具
apktool=true       #Android反编译工具

#------------------------下面的变量可以根据自己的需要修改----------------------#

# 以tar.gz、tgz、zip包安装的时候，解压到的目录
# 不要修改到需要root权限的目录下，修改到~的任意子目录都可以
WORK_DIR=~/bin

# SDK framework API level
ANDROID_SDK_FRAMEWORK_VERSION=23

# 构建工具的版本
ANDROID_SDK_BUILD_TOOLS_VERSION=23.0.2

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
        sudo apt-get install -y git subversion curl wget zip unzip tree vim ruby
    # 如果是CentOS系统
    elif [ -f "/etc/redhat-release" ] ; then
        sudo yum update
        echo "----------------------------------------------------------------"
        sudo yum install -y glibc.i686 zlib.i686 libstdc++.i686
        echo "----------------------------------------------------------------"
        sudo yum install -y git subversion curl wget zip unzip tree vim ruby
    fi
}

# 配置Brew的环境变量
function configBrewEnv() {
    echo "# -----------------------------------------------" >> ~/.bashrc
    echo "export PATH=${HOME}/.linuxbrew/bin:\$PATH" >> ~/.bashrc
    echo "export MANPATH=${HOME}/.linuxbrew/share/man:\$MANPATH" >> ~/.bashrc
    echo "export INFOPATH=${HOME}/.linuxbrew/share/info:\$INFOPATH" >> ~/.bashrc
    source ~/.bashrc
}

# 安装LinuxBrew
function installBrew() {
    which brew > /dev/null
    if [ $? -eq 0 ] ; then
        echo "brew is already installed!"
        return 0
    fi

    if [ -f "/etc/lsb-release" ] ; then
        sudo apt-get install -y build-essential m4 python-setuptools texinfo libbz2-dev \
                                libcurl4-openssl-dev libexpat-dev libncurses-dev zlib1g-dev

        echo -e "\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)" && \
        configBrewEnv
    elif [ -f "/etc/redhat-release" ] ; then
        sudo yum groupinstall -y 'Development Tools' && \
        sudo yum install -y irb python-setuptools

        echo -e "\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)" && \
        configBrewEnv
    fi
}

# 用LinuxBrew安装软件
# $1是要安装的包
# $2是安装的包里面的命令
function installByBrew() {
    which $2 > /dev/null
    if [ $? -eq 0 ] ; then
        echo "$1 is already installed!"
        return 1
    else
        brew install $1
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

# 配置JDK环境变量
function configJDKEnv() {
    echo "# -----------------------------------------------" >> ~/.bashrc
    echo "export JAVA_HOME=`brew --prefix jdk`" >> ~/.bashrc
    echo "export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> ~/.bashrc
    source ~/.bashrc
}

# 配置AndroidSDK环境变量
function configAndroidSDKEnv() {
    echo "# -----------------------------------------------" >> ~/.bashrc
    echo "export ANDROID_HOME=`brew --prefix android-sdk`" >> ~/.bashrc

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
    if [ $? -ne 0 ] ; then
        echo "installDependency occur error!"
        exit 1
    fi

    installBrew
    if [ $? -ne 0 ] ; then
        echo "installBrew occur error!"
        exit 1
    fi

    echo "----------------------------------------------------------------"

    echo "update brew ..."
    brew update

    echo "----------------------------------------------------------------"

    installByBrew node node

    echo "----------------------------------------------------------------"

    installByBrew npm npm && \
    npm config set registry https://registry.npm.taobao.org

    echo "----------------------------------------------------------------"

    installByBrew jdk java && \
    configJDKEnv

    if [ $docker ] ; then
        installByBrew docker docker
        echo "----------------------------------------------------------------"
    fi

    if [ $nginx ] ; then
        installByBrew nginx nginx
        echo "----------------------------------------------------------------"
    fi

    if [ $httpie ] ; then
        installByBrew httpie http
        echo "----------------------------------------------------------------"
    fi

    if [ $maven ] ; then
        installByBrew maven mvn
        echo "----------------------------------------------------------------"
    fi

    if [ $gradle ] ; then
        installByBrew gradle gradle
        echo "----------------------------------------------------------------"
    fi

    if [ $jenkins ] ; then
        installByBrew jenkins jenkins
        echo "----------------------------------------------------------------"
    fi

    if [ $tomcat ] ; then
        installByBrew tomcat catalina
        echo "----------------------------------------------------------------"
    fi

    if [ $androidSDK ] ; then
        installByBrew android-sdk android && \
        configAndroidSDKEnv && \
        updateAndroidSDK
        echo "----------------------------------------------------------------"
    fi

    if [ $androidNDK ] ; then
        installByBrew android-ndk ndk-build
        echo "----------------------------------------------------------------"
    fi

    if [ $apktool ]; then
        installByBrew apktool apktool
        echo "----------------------------------------------------------------"
    fi

    if [ $androidStudio ] ; then
        downloadFileAndExtractTo "$ANDROID_STUDIO_URL" "$WORK_DIR"
        echo "----------------------------------------------------------------"
    fi
    
    cd - > /dev/null
}

main
