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

URL=https://mirrors.edge.kernel.org/pub/software/scm/git
latestFileName=`curl -L "$URL" | grep "git-[0-9].[0-9].[0-9].tar.[x|g]z" | awk -F\" '{print $2}' | awk 'END{print}'`
fileExtension=`echo "$latestFileName" | awk -F "." '{print $NF}'`

curl -LO "$URL/$latestFileName";

if [ $? -eq 0 ] ; then
    if [ "$fileExtension" == "gz" ] ; then
        tar zvxf "$latestFileName"
    elif [ "$fileExtension" == "xz" ] ; then
        tar Jvxf "$latestFileName"
    fi

    cd `tar -tf $latestFileName | sed -n "1p"` && \
    make prefix=/usr/local/git all && \
    make prefix=/usr/local/git install

    SHELL=`echo $SHELL`
    if [ "$SHELL" == "" ] ; then
        SHELL=`awk -F: '{print $7}' /etc/passwd`
    fi
    SHELL=`basename $SHELL`
    echo "current shell is $SHELL";
    
    if [ "$SHELL" == "bash" ] ; then
        echo "export PATH=$PATH:/usr/local/git/bin" >> ~/.bashrc
        source ~/.bashrc
    elif [ "$SHELL" == "zsh" ] ; then
        echo "export PATH=$PATH:/usr/local/git/bin" >> ~/.zshrc
        source ~/.zshrc
    fi
fi
