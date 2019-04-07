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
    command -v git &> /dev/null || xcode-select --install
}

function installBrew() {
    command -v brew &> /dev/null || echo -e '\n' | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

function installByBrew() {
    command -v "$1" &> /dev/null || brew install "$1"
}

function main() {
    [ "`uname -s`" == "Darwin" ] || {
        echo "your system os is not MacOSX"
        exit 1;
    }

    installCommandLineDeveloperTools

    installBrew && brew update

    installByBrew curl
    installByBrew wget
    installByBrew vim
    
    brew cask install java8
    brew cask install android-sdk
    brew cask install android-ndk
    brew cask install android-studio
    brew cask install genymotion
    brew cask install iterm2
}

main
