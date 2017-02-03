#!/bin/bash

role=""
if [ `whoami` != "root" ]
    role=sudo
fi

function installCommandLineDeveloperToolsOnMacOSX() {
    which git > /dev/null
    if [ $? -eq 0 ] ; then
        echo "CommandLineDeveloperTools already installed!"
    else
        xcode-select --install
    fi
}

function installBrewOnMacOSX() {
    which brew > /dev/null
    if [ $? -eq 0 ] ; then
        echo "brew already installed!"
    else
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
}

function installVimOnMacOSX() {
    which vim  > /dev/null
    if [ $? -eq 0 ] ; then
        echo "vim already installed!"
    else
        brew install vim
    fi
}

function installCurlOnMacOSX() {
    which curl > /dev/null
    if [ $? -eq 0 ] ; then
        echo "curl already installed!"
    else
        brew install curl
    fi
}

function installOnUbuntu() {
    which "$1" > /dev/null
    if [ $? -eq 0 ] ; then
        echo "$1 already installed!"
    else
        $role apt-get install "$2"
    fi
}

function installOnCentOS() {
    which "$1" > /dev/null
    if [ $? -eq 0 ] ; then
        echo "$1 already installed!"
    else
        $role yum install "$2"
    fi
}

function installVundle() {
    vundleDir="${HOME}/.vim/bundle/vundle"
    if [ -d "$vundleDir" ] ; then
        cd $vundleDir
        
        git pull > /dev/null

        if [ $? -eq 0 ] ; then
            echo "Vundle already installed!"
        else
            git clone http://github.com/gmarik/vundle.git $vundleDir
        fi

        cd - > /dev/null
    else
        mkdir -p $vundleDir
        git clone http://github.com/gmarik/vundle.git $vundleDir
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

    if [ $osType = "Darwin" ] ; then
        installCommandLineDeveloperToolsOnMacOSX
        installBrewOnMacOSX
        installVimOnMacOSX
        installCurlOnMacOSX
    elif [ $osType = "Linux" ] ; then
        if [ -f '/etc/lsb-release' ] ; then
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
        curl -O https://raw.githubusercontent.com/leleliu008/auto/master/vim-setup/vimrc-user
        if [ $? -eq 0 ] ; then
            updateVimrcOfCurrentUser
        fi
    fi
}

main
