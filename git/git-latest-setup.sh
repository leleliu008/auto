#!/bin/bash

osKernelName=`uname -s`
if [ "$osKernelName" == "Linux" ] ; then
    sudo=`which sudo 2> /dev/null`;
    if [ -f "/etc/lsb-release" ] ; then
        $sudo apt-get update;
        $sudo apt-get install -y curl gawk sed tar xz-utils make gcc libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev;
    elif [ -f "/etc/redhat-release" ] ; then
        $sudo yum update -y;
        $sudo yum install -y curl gawk sed tar xz make gcc curl-devel expat-devel gettext-devel openssl-devel zlib-devel perl-ExtUtils-MakeMaker;
    else
        echo "\e[37;31;1mplease install curl, then rerun this script!!\e[39;49;0m";
        exit 1;
    fi
elif [ "$osKernelName" == "Drawin" ] ; then
    brew update;
    brew install git;
    exit 0;
else
    echo -e "\e[37;31;1mwe don't recognize your os~~\e[39;49;0m";
    exit 1
fi

echo -e "\e[37;31;1mfetching the latest git version info...\e[39;49;0m";

URL=https://mirrors.edge.kernel.org/pub/software/scm/git
latestFileName=`curl -sSL# "$URL" | grep "git-[0-9]\{1,2\}.[0-9]\{1,2\}.[0-9]\{1,2\}.tar.xz" | awk -F\" '{print $2}' | sort -V | awk 'END{print}'`;
fileExtension=`echo "$latestFileName" | awk -F "." '{print $NF}'`;

[ -f "$latestFileName" ] && rm -rf "$latestFileName";

echo -e "\e[37;31;1mthe latest git version is $latestFileName\e[39;49;0m";
echo -e "\e[37;31;1mdownloading $URL/$latestFileName\e[39;49;0m";

curl -LO "$URL/$latestFileName";

if [ $? -eq 0 ] ; then
    if [ "$fileExtension" == "gz" ] ; then
        tar zvxf "$latestFileName"
    elif [ "$fileExtension" == "xz" ] ; then
        tar Jvxf "$latestFileName"
    fi

    cd `tar -tf $latestFileName | sed -n "1p"` && \
    make prefix=/usr/local/git all && \
    make prefix=/usr/local/git install || {
        exit 1
    }

    SHELL=`echo $SHELL`
    if [ "$SHELL" == "" ] ; then
        SHELL=`awk -F: '{print $7}' /etc/passwd`
    fi
    SHELL=`basename $SHELL`
     
    if [ "$SHELL" == "bash" ] ; then
        echo "export PATH=/usr/local/git/bin:\$PATH" >> ~/.bashrc
        source ~/.bashrc
    elif [ "$SHELL" == "zsh" ] ; then
        echo -e "\e[37;32;1mgit has been installed into /usr/local/git, please execute command as follow in your terminal:\e[39;49;0m"
        echo -e "\e[37;32;1mecho \"export PATH=/usr/local/git/bin:\$PATH\" >> ~/.zshrc\e[39;49;0m"
    fi
fi
