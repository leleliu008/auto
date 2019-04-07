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

# 安装HomeBrew
function installHomeBrew() {
    command -v brew &> /dev/null || (echo -e "\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)" && brew update)
}

function main() {
    command -v git &> /dev/null || command -v svn &> /dev/null || xcode-select --install

    installHomeBrew || (
        echo "installBrew occur error!"
        exit 1
    )

    for name in ${installByHomeBrew[*]}
    do
        brew install $name
    done

    npm config set registry https://registry.npm.taobao.org

    for name in ${installByHomeBrewCask[*]}
    do
        brew cask install $name
    done

}

main
