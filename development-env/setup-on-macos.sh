#!/bin/sh

#------------------------------------------------------------------------------#
# 开发环境搭建脚本，只支持Mac OSX系统
# 搭建的环境包括Java、Android、iOS、Node.js、Web前端
# 
# 特殊说明：
# 1、npm的源使用的是淘宝的
# 2、对于vim，安装了Vundle插件管理工具和一些常用插件，并修改了当前用户的配置
#------------------------------------------------------------------------------#

# 安装HomeBrew
installOrUpdateHomeBrew() {
    if command -v brew > /dev/null ; then
        brew update
    else
        printf "\n\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)"
    fi
}

installViaHomeBrew() {
    for name in $@
    do
        brew install $name
    done
}

installViaHomeBrewCask() {
    for name in $@
    do
        brew cask install $name
    done
}

main() {
    installOrUpdateHomeBrew || {
        printf "%s\n" "installBrew occur error!"
        exit 1
    }
    
    installViaHomeBrew "curl wget zip unzip tree vim node npm httpie tomcat jenkins maven gradle apktool"

    npm config set registry https://registry.npm.taobao.org
    
    installViaHomeBrewCask "iterm2 firefox google-chrome sublime webstorm eclipse-jee docker android-sdk android-ndk android-studioi genymotion skitch"
}

main
