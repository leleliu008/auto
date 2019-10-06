#!/bin/bash

[ `whoami` == "root" ] || role=sudo

function installOrUpdateHomeBrew() {
    if command -v brew &> /dev/null ; then
        brew update
    else
        echo -e "\n" | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
}

function installCurlIfNeeded() {
    command -v curl &> /dev/null || {
        local osType=`uname -s`
        echo "osType=$osType"
        
        if [ "$osType" == "Darwin" ] ; then
            installOrUpdateHomeBrew && brew install curl
        elif [ "$osType" = "Linux" ] ; then
            if [ "`uname -o 2> /dev/null`" == "Android" ] ; then
                pkg install -y curl
            else
                #ArchLinux ManjaroLinux
                command -v pacman &> /dev/null && {
                    $role pacman -Syyuu --noconfirm && \
                    $role pacman -S curl
                    return $?
                }
                
                #AlpineLinux
                command -v apk &> /dev/null && {
                    $role apk update && apk add curl
                    return $?
                }
                
                #Debian系
                command -v apt-get &> /dev/null && {
                    $role apt-get -y update && \
                    $role apt-get -y install curl
                    return $?
                }
                
                #Fedora CentOS8
                command -v dnf &> /dev/null && {
                    $role dnf -y update && \
                    $role dnf -y install curl
                    return $?
                }
                
                #RHEL CentOS8以下
                command -v yum &> /dev/null && {
                    $role yum -y update && \
                    $role yum -y install curl
                    return $?
                }
                
                #OpenSUSE
                command -v zypper &> /dev/null && {
                    $role zypper update -y && \
                    $role zypper install -y curl
                    return $?
                }

                echo "who are you?"
                exit 1
            fi
        fi
    }
}

function installNVM() {
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
}

function changeNPMRegistryToChineseMirrorIfPossible() {
    command -v npm &> /dev/null || return 0
    if [ "$(npm config get registry)" == "https://registry.npmjs.org/" ] ; then
        npm config set registry "https://registry.npm.taobao.org/"
    fi
}

function configEnv() {
    local str="export NVM_DIR=~/.nvm && source \"\$NVM_DIR/nvm.sh\""
    echo "$str" >> ~/.bashrc
    echo "$str" >> ~/.bash_profile
    echo "$str" >> ~/.zshrc
}

function main() {
    command -v nvm &> /dev/null && {
        changeNPMRegistryToChineseMirrorIfPossible
        echo "nvm already installed!"
        exit
    }
    installCurlIfNeeded && installNVM && configEnv
}

main
