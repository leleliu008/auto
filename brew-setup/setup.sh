#!/bin/bash

# 配置Brew的环境变量
function configBrewEnv() {
    echo "# -----------------------------------------------" >> ~/.bashrc
    echo "export PATH=${HOME}/.linuxbrew/bin:\$PATH" >> ~/.bashrc
    echo "export MANPATH=${HOME}/.linuxbrew/share/man:\$MANPATH" >> ~/.bashrc
    echo "export INFOPATH=${HOME}/.linuxbrew/share/info:\$INFOPATH" >> ~/.bashrc
    source ~/.bashrc
}

# 安装LinuxBrew
function installBrew() {
    command -v brew &> /dev/null && {
        echo "brew is already installed!"
        exit 0
  }

    if [ "`uname -s`" = "Darwin" ] ; then
        echo -e "\n" | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" && configBrewEnv && brew update
    elif [ -f "/etc/lsb-release" ] || [ -f "/etc/os-release" ] ; then
        sudo apt-get install -y build-essential curl git m4 python-setuptools ruby texinfo libbz2-dev libcurl4-openssl-dev libexpat-dev libncurses-dev zlib1g-dev
        echo -e "\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)" && configBrewEnv && brew update
    elif [ -f "/etc/redhat-release" ] ; then
        sudo yum groupinstall -y 'Development Tools' && \
        sudo yum install -y irb python-setuptools

        echo -e "\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)" && configBrewEnv && brew update
    else
        echo "who are you ?"
    fi
}

function main() {
    if [ "`whoami`" != "root" ] ; then
        echo "don't run as root!"
    else
        installBrew
    fi
}

main
