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

function installVundle() {
    local pluginDir="${HOME}/.vim/bundle"
    local vundleDir="${pluginDir}/Vundle.vim"
    if [ -d "$vundleDir" ] ; then
        cd $vundleDir
        git pull > /dev/null || (cd .. && git clone http://github.com/VundleVim/Vundle.vim.git)
        cd - &> /dev/null
    else
        mkdir -p $vundleDir
        git clone http://github.com/VundleVim/Vundle.vim.git $vundleDir
    fi
}

function updateVimrcOfCurrentUser() {
    if [ -f "${HOME}/.vimrc" ] ; then
        mv ~/.vimrc ~/.vimrc.bak
    fi
    cp vimrc-user ~/.vimrc

    echo "---------------------------------------------------"
    echo "~/.vimrc config file is updated! "
    echo "your ~/.vimrc config file is bak to ~/.vimrc.bak"
    echo "open vim and use :BundleInstall to install plugins!"
    echo "---------------------------------------------------"
}

function main() {
    osType=`uname -s`
    echo "osType=$osType"

    if [ "$osType" = "Darwin" ] ; then
        installCommandLineDeveloperToolsOnMacOSX
        installHomeBrewIfNeeded
        installViaHomeBrew vim vim
        installViaHomeBrew curl curl
        installViaHomeBrew ctags ctags
    elif [ "$osType" = "Linux" ] ; then
        #ArchLinux ManjaroLinux
        if [ -f '/etc/archlinux-release' ] || [ -f '/etc/manjaro-release' ] ; then
            $role pacman -Syyu --noconfirm &&
            installViaPacman git git &&
            installViaPacman curl curl &&
            installViaPacman vim vim &&
            installViaPacman ctags ctags
        #AlpineLinux
        elif [ -f '/etc/alpine-release' ] ; then
            $role apk update &&
            installViaApk git git &&
            installViaApk curl curl &&
            installViaApk vim vim &&
            installViaApk ctags ctags
        #Debian Ubuntu
        elif [ -f '/etc/lsb-release' ] || [ -f '/etc/debian_version' ] ; then
            $role apt-get -y update &&
            installViaApt git git &&
            installViaApt curl curl &&
            installViaApt vim vim &&
            installViaApt ctags exuberant-ctags
        #Fedora
        elif [ -f '/etc/fedora-release' ] ; then
            $role dnf -y update &&
            installViaDnf git git &&
            installViaDnf curl curl &&
            installViaDnf vim vim &&
            installViaDnf ctags ctags-etags
        #RHEL CentOS
        elif [ -f '/etc/redhat-release' ] ; then
            $role yum -y update &&
            installViaYum git git &&
            installViaYum curl curl &&
            installViaYum vim vim &&
            installViaYum ctags ctags-etags
        fi
    fi
    
    installVundle

    updateVimrcOfCurrentUser
}

main
