#!/bin/bash

function installOhMyTmux() {
    [ -f ~/.tmux.conf ] && mv ~/.tmux.conf ~/.tmux.conf.bak
    curl -L -o ~/.tmux.conf https://raw.githubusercontent.com/gpakosz/.tmux/master/.tmux.conf
    curl -L -o ~/.tmux.conf.local https://raw.githubusercontent.com/gpakosz/.tmux/master/.tmux.conf.local
}

function main() {
    local sudo=`command -v sudo 2> /dev/null`;
    local osType=`uname -s`;

    if [ "$osType" == "Linux" ] ; then
        # 如果是ArchLinux或ManjaroLinux系统
        command -v pacman &> /dev/null && {
            $sudo pacman -Syyuu --noconfirm && \
            command -v curl &> /dev/null || $sudo pacman -S curl --noconfirm && \
            command -v tmux  &> /dev/null || $sudo pacman -S tmux  --noconfirm && \
            installOhMyTmux
            exit
        }
        
        # 如果是Ubuntu或Debian GNU/Linux系统
        command -v apt-get &> /dev/null && {
            $sudo apt-get -y update && \
            $sudo apt-get -y install curl tmux && \
            installOhMyTmux
            exit
        }
        
        # 如果是Fedora或CentOS8系统
        command -v dnf &> /dev/null && {
            $sudo dnf -y update && \
            $sudo dnf -y install curl tmux && \
            installOhMyTmux
            exit
        }
        
        # 如果是CentOS8以下的系统
        command -v yum &> /dev/null && { 
            $sudo yum -y update && \
            $sudo yum -y install curl tmux && \
            installOhMyTmux
            exit
        }

        # 如果是OpenSUSE系统
        command -v zypper &> /dev/null && { 
            $sudo zypper update -y && \
            $sudo zypper install -y curl tmux && \
            installOhMyTmux
            exit
        }
        
        # 如果是AlpineLinux系统
        command -v apk &> /dev/null && {
            $sudo apk update && \
            $sudo apk add curl tmux && \
            installOhMyTmux
            exit
        }
            
        echo "your os is unrecognized!!"
        exit 1
    elif [ "$osType" == "Darwin" ] ; then
        command -v brew &> /dev/null || (echo -e "\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" && brew update)
        command -v curl &> /dev/null || brew install curl
        command -v tmux  &> /dev/null || brew install tmux
        installOhMyTmux
    else
        echo "your os is unrecognized!!"
        exit 1
    fi
}

main
