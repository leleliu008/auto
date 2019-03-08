#!/bin/bash

function installOhMyZsh() {
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)";
    
    if [ -f "~/.oh-my-zsh/plugins" ] ; then
        git -C ~/.oh-my-zsh/plugins clone https://github.com/zsh-users/zsh-syntax-highlighting.git && \
        git -C ~/.oh-my-zsh/plugins clone https://github.com/zsh-users/zsh-autosuggestions.git && \
        git -C ~/.oh-my-zsh/plugins clone https://github.com/zsh-users/zsh-completions.git
    fi
}

function main() {
    if [ -f "~/.oh-my-zsh" ] ; then
        echo "Oh-My-Zsh has already installed!"
        exit 1
    fi

    local sudo=`which sudo`;
    local osType=`uname -s`;

    if [ "$osType" == "Linux" ] ; then
        # 如果是Ubuntu系统
        if [ -f "/etc/lsb-release" ] ; then
            $sudo apt-get update && \
            $sudo apt-get install -y curl git zsh && \
            $installOhMyZsh
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
