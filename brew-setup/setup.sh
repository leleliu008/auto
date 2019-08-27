#!/bin/bash

# 配置LinuxBrew的环境变量
function configLinuxBrewEnv() {
    cat >> ${HOME}/.linuxbrew/env <<EOF
export PATH=\${HOME}/.linuxbrew/bin:\$PATH
export MANPATH=\${HOME}/.linuxbrew/share/man:\$MANPATH
export INFOPATH=\${HOME}/.linuxbrew/share/info:\$INFOPATH
EOF
    source ${HOME}/.linuxbrew/env
    echo "source \${HOME}/.linuxbrew/env" >> ${HOME}/.bash_profile
    echo "source \${HOME}/.linuxbrew/env" >> ${HOME}/.bashrc
    echo "source \${HOME}/.linuxbrew/env" >> ${HOME}/.zshrc
}

function installLinuxBrew() {
    echo -e "\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)" && configLinuxBrewEnv
}

function installHomeBrew() {
    echo -e "\n" | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

# 安装HomeBrew或者LinuxBrew
function installBrew() {
    if [ "`uname -s`" == "Darwin" ] ; then
        installHomeBrew
    else
        command -v apt-get &> /dev/null && {
             sudo apt-get -y install build-essential \
                                     curl \
                                     git \
                                     m4 \
                                     python-setuptools \
                                     ruby \
                                     texinfo \
                                     libbz2-dev \
                                     libcurl4-openssl-dev \
                                     libexpat-dev \
                                     libncurses-dev \
                                     zlib1g-dev && \
            installLinuxBrew
            exit
        }
        
        command -v yum &> /dev/null && { 
            sudo yum -y groupinstall 'Development Tools' && \
            sudo yum -y install irb python-setuptools && \
            installLinuxBrew
            exit
        }
        
        echo "who are you ?"
        exit 1
    fi
}

function main() {
    command -v brew &> /dev/null && {
        brew update
        echo "brew is already installed!"
        exit 0
    }
    
    [ "`whoami`" == "root" ] && {
        echo "don't run as root!"
        exit 1
    }
    
    installBrew
}

main
