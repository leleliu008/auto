#!/bin/bash

if [ "`which curl 2> /dev/null`" == "" ] ; then
    osKernelName=`uname -s`
    if [ "$osKernelName" == "Linux" ] ; then
        sudo=`which sudo 2> /dev/null`;
        if [ -f "/etc/lsb-release" ] ; then
            $sudo apt-get update;
            $sudo apt-get install -y curl;
        elif [ -f "/etc/redhat-release" ] ; then
            $sudo yum update;
            $sudo yum install -y curl;
        else
            echo "please install curl, then rerun this script!!";
            exit 1;
        fi
    elif [ "$osKernelName" == "Drawin" ] ; then
        if [ "" == "" ] ; then
            echo "please install curl, then rerun this script!!";
            exit 1;
        else
            brew install curl;
        fi
    else
        echo "we don't recognize your os~~";
        exit 1
    fi
fi

SHELL=`echo $SHELL`
if [ "$SHELL" == "" ] ; then
    SHELL=`awk -F: '{print $7}' /etc/passwd`
fi
SHELL=`basename $SHELL`
echo "currentShell=$SHELL"

URL=https://mirrors.edge.kernel.org/pub/software/scm/git
latestFileName=`curl -L "$URL" | grep "git-[0-9].[0-9].[0-9].tar.[x|g]z" | awk -F\" '{print $2}' | awk 'END{print}'`
curl -LO "$URL/$latestFileName" && \
cd git-2.9.2 && \
make prefix=/usr/local/git all && \
make prefix=/usr/local/git install

if [ "$SHELL" == "bash" ] ; then
    echo "export PATH=$PATH:/usr/local/git/bin" >> ~/.bashrc
    source ~/.bashrc
elif [ "$SHELL" == "zsh" ] ; then
    echo "export PATH=$PATH:/usr/local/git/bin" >> ~/.zshrc
    source ~/.zshrc
fi
