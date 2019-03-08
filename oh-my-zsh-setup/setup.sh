#!/bin/bash

function installOhMyZsh() {
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" && \
    git -C ~/.oh-my-zsh/plugins https://github.com/zsh-users/zsh-syntax-highlighting.git && \
    git -C ~/.oh-my-zsh/plugins https://github.com/zsh-users/zsh-autosuggestions.git && \
    git -C ~/.oh-my-zsh/plugins https://github.com/zsh-users/zsh-completions.git && \

}

function main() {
    if [ -f "$HOME/.oh-my-zsh" ] ; then
        echo "OhMyZsh has installed!"
        exit 1
    fi

    #Docker容器的默认是用户是root，且没有安装sudo命令
    sudo=`which sudo`
    osType=`uname -s`

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
