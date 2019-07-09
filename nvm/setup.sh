#!/bin/bash

role=""
if [ `whoami` != "root" ] ; then
    role=sudo
fi

function installCommandLineDeveloperToolsOnMacOSX() {
    command -v git &> /dev/null || xcode-select --install
}

function installHomeBrewIfNeeded() {
    command -v brew &> /dev/null || (echo -e "\n" | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" && brew update)
}

function installViaHomeBrew() {
    command -v "$1" &> /dev/null || brew install "$2"
}

function installViaApt() {
    command -v "$1" &> /dev/null || $role apt-get -y install "$2"
}

function installViaYum() {
    command -v "$1" &> /dev/null || $role yum -y install "$2"
}

function installViaDnf() {
    command -v "$1" &> /dev/null || $role dnf -y install "$2"
}

function installViaApk() {
    command -v "$1" &> /dev/null || $role apk add "$2"
}

function installViaPacman() {
    command -v "$1" &> /dev/null || $role pacman -S --noconfirm "$2"
}

function main() {
    local osType=`uname -s`
    echo "osType=$osType"

    if [ "$osType" = "Darwin" ] ; then
        command -v curl &> /dev/null || {
            installCommandLineDeveloperToolsOnMacOSX
            installHomeBrewIfNeeded
            installViaHomeBrew curl curl
        }
    elif [ "$osType" = "Linux" ] ; then
        if [ "`uname -o 2> /dev/null`" == "Android" ] ; then
            pkg install curl
        else
            #ArchLinux ManjaroLinux
            if [ -f '/etc/archlinux-release' ] || [ -f '/etc/manjaro-release' ] ; then
                $role pacman -Syyu --noconfirm && installViaPacman curl curl
            #AlpineLinux
            elif [ -f '/etc/alpine-release' ] ; then
                $role apk update && installViaApk curl curl
            #Debian Ubuntu
            elif [ -f '/etc/lsb-release' ] || [ -f '/etc/debian_version' ] ; then
                $role apt-get -y update && installViaApt curl curl
            #Fedora
            elif [ -f '/etc/fedora-release' ] ; then
                $role dnf -y update && installViaDnf curl curl
            #RHEL CentOS
            elif [ -f '/etc/redhat-release' ] ; then
                $role yum -y update && installViaYum curl curl
            fi
        fi
    fi

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
    
    [ -f "~/.bashrc" ] && {
        echo "export NVM_DIR=~/.nvm" >> ~/.bashrc
        echo "source \"\$NVM_DIR/nvm.sh\"" >> ~/.bashrc
    }

    [ -f "~/.bash_profile" ] && {
        echo "export NVM_DIR=~/.nvm" >> ~/.bash_profile
        echo "source \"\$NVM_DIR/nvm.sh\"" >> ~/.bash_profile
    }
    
    [ -f "~/.zshrc" ] && {
        echo "export NVM_DIR=~/.nvm" >> ~/.zshrc
        echo "source \"\$NVM_DIR/nvm.sh\"" >> ~/.zshrc
    }
}

main
