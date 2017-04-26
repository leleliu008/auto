#!/bin/bash

#------------------------------------------------------------------------------#
# 开发环境搭建脚本，只支持Mac OSX系统
# 搭建的环境包括Java、Android、iOS、Node.js、Web前端
# 
# 特殊说明：
# 1、npm的源使用的是淘宝的
# 2、对于vim，安装了Vundle插件管理工具和一些常用插件，并修改了当前用户的配置
#------------------------------------------------------------------------------#

#-------------------------------- 要安装的软件 --------------------------------#

installByHomeBrew=(curl wget zip unzip tree vim node npm httpie tomcat jenkins maven gradle apktool);
installByHomeBrewCask=(iterm2 firefox google-chrome sublime webstorm eclipse-jee docker android-sdk android-ndk android-studioi genymotion skitch);

#------------------------------------------------------------------------------#

function installCommandLineDeveloperTools() {
    which git > /dev/null
    if [ $? -eq 0 ] ; then
        which svn > /dev/null
        if [ $? -eq 0 ] ; then
            echo "CommandLineDeveloperTools already installed!"
        else
            xcode-select --install
        fi
    else
        xcode-select --install
    fi
}

# 安装HomeBrew
function installHomeBrew() {
    which brew > /dev/null
    if [ $? -eq 0 ] ; then
        echo "brew is already installed!"
    else
        echo -e "\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)" && brew update
    fi
}

# 用HomeBrew安装软件
# $1是要安装的包
# $2是安装的包里面的命令
function installByHomeBrew() {
    which $2 > /dev/null
    if [ $? -eq 0 ] ; then
        echo "$1 is already installed!"
        return 1
    else
        brew install $1
    fi
}

function main() {
    installCommandLineDeveloperTools

    installHomeBrew
    if [ $? -ne 0 ] ; then
        echo "installBrew occur error!"
        exit 1
    fi

    echo "----------------------------------------------------------------"

    for name in ${installByHomeBrew[*]}
    do
        brew install $name
        echo "----------------------------------------------------------------"
    done

    npm config set registry https://registry.npm.taobao.org

    for name in ${installByHomeBrewCask[*]}
    do
        brew cask install $name
        echo "----------------------------------------------------------------"
    done

}

main
