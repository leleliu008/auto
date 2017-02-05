#!/bin/bash

role=
if [ `whoami` != "root" ] ; then
    role=sudo
fi

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
    which brew >& /dev/null
    if [ $? -eq 0 ] ; then
        echo "brew is already installed!"
        return 0
    fi

    if [ `uname -s` = "Darwin" ] ; then
        echo -e "\n" | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" && configBrewEnv && brew update
    elif [ -f "/etc/lsb-release" ] ; then
        $role apt-get install -y build-essential curl git m4 python-setuptools ruby texinfo libbz2-dev libcurl4-openssl-dev libexpat-dev libncurses-dev zlib1g-dev
        echo -e "\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)" && configBrewEnv && brew update
    elif [ -f "/etc/redhat-release" ] ; then
        $role yum groupinstall -y 'Development Tools' && \
        $role yum install -y irb python-setuptools

        echo -e "\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)" && configBrewEnv && brew update
    else
        echo "who are you ?"
    fi
}

installBrew
