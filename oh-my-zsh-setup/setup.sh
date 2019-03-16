#!/bin/bash

function installOhMyZsh() {
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)";
    pluginsDir=~/.oh-my-zsh/plugins;    
    if [ -d "$pluginsDir" ] ; then
        #这里不使用-C参数的因为是，CentOS里的git命令的版本比较低，没有此参数
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $pluginsDir/zsh-syntax-highlighting && \
        git clone https://github.com/zsh-users/zsh-autosuggestions.git $pluginsDir/zsh-autosuggestions  && \
        git clone https://github.com/zsh-users/zsh-completions.git $pluginsDir/zsh-completions
    fi
}

function main() {
    local sudo=`which sudo 2> /dev/null`;
    local osType=`uname -s`;

    if [ "$osType" == "Linux" ] ; then
        # 如果是Ubuntu系统
        if [ -f "/etc/lsb-release" ] ; then
            $sudo apt-get update && \
            $sudo apt-get install -y curl git zsh && \
            installOhMyZsh
        # 如果是CentOS系统
        elif [ -f "/etc/redhat-release" ] ; then
            $sudo yum update && \
            $sudo yum install -y curl git zsh && \
            installOhMyZsh
        else
            echo "your system os is not ubuntu or centos"!
            exit 1
        fi
    elif [ "$osType" == "Darwin" ] ; then
        installOhMyZsh
    else
        echo "your system os is unrecognized"
        exit 1
    fi
}

main
