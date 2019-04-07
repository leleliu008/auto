#!/bin/bash

role=""
if [ `whoami` != "root" ] ; then
    role=sudo
fi

function installCommandLineDeveloperToolsOnMacOSX() {
    command -v git 2&> /dev/null || xcode-select --install
}

# 配置Brew的环境变量
function configBrewEnv() {
    echo "# -----------------------------------------------" >> ~/.bashrc
    echo "export PATH=${HOME}/.linuxbrew/bin:\$PATH" >> ~/.bashrc
    echo "export MANPATH=${HOME}/.linuxbrew/share/man:\$MANPATH" >> ~/.bashrc
    echo "export INFOPATH=${HOME}/.linuxbrew/share/info:\$INFOPATH" >> ~/.bashrc
    source ~/.bashrc
}

function installBrewOnMacOSX() {
    command -v brew 2&> /dev/null || echo -e "\n" | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" && configBrewEnv && brew update
}

function installVimOnMacOSX() {
    command -v vim  2&> /dev/null || brew install vim
}

function installCurlOnMacOSX() {
    command -v curl 2&> /dev/null || brew install curl
}

function installOnUbuntu() {
    command -v "$1" 2&> /dev/null || $role apt-get install -y "$2"
}

function installOnCentOS() {
    command -v "$1" 2&> /dev/null || $role yum install -y "$2"
}

function installVundle() {
    vundleDir="${HOME}/.vim/bundle/Vundle.vim"
    if [ -d "$vundleDir" ] ; then
        cd $vundleDir
        git pull > /dev/null || git clone http://github.com/VundleVim/Vundle.vim.git
        cd - 2&> /dev/null
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
        installBrewOnMacOSX
        installVimOnMacOSX
        installCurlOnMacOSX
    elif [ "$osType" = "Linux" ] ; then
        if [ -f '/etc/lsb-release' ] || [ -f '/etc/os-release' ] ; then
            installOnUbuntu git git
            installOnUbuntu curl curl
            installOnUbuntu vim vim
            installOnUbuntu ctags exuberant-ctags
        elif [ -f '/etc/redhat-release' ] ; then
            installOnCentOS git git
            installOnCentOS curl curl
            installOnCentOS vim vim
            installOnCentOS ctags ctags-etags
        fi
    fi
    
    installVundle

    if [ -f 'vimrc-user' ] ; then
        updateVimrcOfCurrentUser
    else
        curl -O https://raw.githubusercontent.com/leleliu008/auto/master/vim-setup/vimrc-user && updateVimrcOfCurrentUser
    fi
}

main
