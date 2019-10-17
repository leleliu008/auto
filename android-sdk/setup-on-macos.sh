#!/bin/sh

#------------------------------------------------------------------------------#
# Android开发环境搭建脚本
# 该脚本只支持Mac OS X 系统
# 所有软件均通过HomeBrew进行安装
#------------------------------------------------------------------------------#

installBrewIfNeeded() {
    if command -v brew > /dev/null ; then
       brew update
    else
        printf "\n\n" | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
}

installByBrew() {
    command -v "$1" > /dev/null || brew install "$1"
}

main() {
    [ "$(uname -s)" = "Darwin" ] || {
        printf "your os is not macOS!!\n"
        exit 1
    }

    installBrewIfNeeded

    installByBrew curl
    installByBrew httpie
    installByBrew vim
    
    brew cask reinstall adoptopenjdk8
    brew cask reinstall android-sdk
    brew cask reinstall android-ndk
    brew cask reinstall android-studio
    brew cask reinstall virtualbox
    brew cask reinstall virtualbox-extension-pack
    brew cask reinstall genymotion
    brew cask reinstall iterm2
}

main
