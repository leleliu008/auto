#!/bin/bash

#------------------------------------------------------------------------------#
# Android开发环境搭建脚本
# 该脚本只支持Mac OS X 系统
# 所有软件均通过HomeBrew进行安装
#------------------------------------------------------------------------------#

# SDK framework API level
ANDROID_SDK_FRAMEWORK_VERSION=23

# 构建工具的版本
ANDROID_SDK_BUILD_TOOLS_VERSION=23.0.2


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
        echo -e '\n' | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
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

function main() {
    # 如果不是MacOSX系统就退出
    if [ `uname -s` != "Darwin" ] ; then
        echo "your system os is not MacOSX"
        exit 1;
    fi

    installCommandLineDeveloperTools

    installBrew && brew update

    installByBrew curl curl
    installByBrew wget wget
    installByBrew vim vim
    
    brew cask install java
    brew cask install android-sdk
    brew cask install android-ndk
    brew cask install android-studio
    brew cask install genymotion
    brew cask install iterm2
}

main
