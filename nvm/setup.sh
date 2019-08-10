#!/bin/bash

[ `whoami` == "root" ] || role=sudo

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

function installViaZypper() {
    command -v "$1" &> /dev/null || $role zypper install -y "$2"
}

function installViaApk() {
    command -v "$1" &> /dev/null || $role apk add "$2"
}

function installViaPacman() {
    command -v "$1" &> /dev/null || $role pacman -S --noconfirm "$2"
}

function installNVM() {
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
}

function configEnv() {
    echo "export NVM_DIR=~/.nvm" >> ~/.bashrc
    echo "source \"\$NVM_DIR/nvm.sh\"" >> ~/.bashrc

    echo "export NVM_DIR=~/.nvm" >> ~/.bash_profile
    echo "source \"\$NVM_DIR/nvm.sh\"" >> ~/.bash_profile
    
    echo "export NVM_DIR=~/.nvm" >> ~/.zshrc
    echo "source \"\$NVM_DIR/nvm.sh\"" >> ~/.zshrc
}

function main() {
    local osType=`uname -s`
    echo "osType=$osType"

    if [ "$osType" = "Darwin" ] ; then
        command -v curl &> /dev/null || {
            installCommandLineDeveloperToolsOnMacOSX
            installHomeBrewIfNeeded
            installViaHomeBrew curl curl
            installNVM && configEnv
        }
    elif [ "$osType" = "Linux" ] ; then
        if [ "`uname -o 2> /dev/null`" == "Android" ] ; then
            command -v curl &> /dev/null || pkg install -y curl
            installNVM && configEnv
        else
            #ArchLinux ManjaroLinux
            command -v pacman &> /dev/null && {
                $role pacman -Syyuu --noconfirm && installViaPacman curl curl
                installNVM && configEnv
                exit
            }
            
            #AlpineLinux
            command -v apk &> /dev/null && {
                $role apk update && installViaApk curl curl
                installNVM && configEnv
                exit
            }
            
            #Debian系
            command -v apt-get &> /dev/null && {
                $role apt-get -y update && installViaApt curl curl
                installNVM && configEnv
                exit
            }
            
            #Fedora CentOS8
            command -v dnf &> /dev/null && {
                $role dnf -y update && installViaDnf curl curl
                installNVM && configEnv
                exit
            }
            
            #RHEL CentOS8以下
            command -v yum &> /dev/null && {
                $role yum -y update && installViaYum curl curl
                installNVM && configEnv
                exit
            }

            #OpenSUSE
            command -v zypper &> /dev/null && {
                $role zypper update -y && installViaZypper curl curl
                installNVM && configEnv
                exit
            }
        fi
    fi
}

main
