#!/bin/sh

osType=`uname -s`
echo "osType=$osType"

if [ $osType == "Darwin" ] ; then
        which brew
        if [ $? -eq 0 ] ; then
                echo "brew already installed!"
        else
                /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        fi

        which vim
        if[ $? -eq 0 ] ; then
                echo "vim already installed!"
        else
                brew install vim
        fi

        which curl
        if [ $? -eq 0 ] ; then
                echo "curl already installed!"
        else
                brew install curl
        fi
elif [ $osType == "Linux" ] ; then
        if [ -f '/etc/debain-release' ] ; then
                sudo apt-get install curl
                sudo apt-get install vim
                sudo apt-get install exuberant-ctags
        elif [ -f '/etc/redhat-release' ] ; then
                sudo yum install curl
                sudo yum install vim
                sudo yum install ctags-etags
        fi
fi

if [ -f 'vimrc-user'] ; then
        if [ -f '~/.vimrc' ] ; then
                mv ~/.vimrc ~/.vimrc.bak
        fi
        cp vimrc-user ~/.vimrc
else
        curl -O https://raw.githubusercontent.com/leleliu008/auto/master/vim-setup/vimrc-user
        if [ $? -eq 0 ] ; then
                if [ -f '~/.vimrc' ] ; then
                    mv ~/.vimrc ~/.vimrc.bak
                fi
                cp vimrc-user ~/.vimrc
        fi
fi
