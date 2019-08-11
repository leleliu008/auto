#!/bin/bash

#------------------------------------------------------------------------------#
# Android开发环境搭建脚本
# 该脚本只支持Mac OS X 系统
# 所有软件均通过HomeBrew进行安装
#------------------------------------------------------------------------------#

function installCommandLineDeveloperToolsIfNeeded() {
    command -v git &> /dev/null || xcode-select --install
}

function installBrewIfNeeded() {
    command -v brew &> /dev/null || echo -e '\n' | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

function installByBrew() {
    command -v "$1" &> /dev/null || brew install "$1"
}

function main() {
    [ "`uname -s`" == "Darwin" ] || {
        echo "your os is not macOS!!"
        exit 1;
    }

    installCommandLineDeveloperToolsIfNeeded

    installBrewIfNeeded && brew update

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
