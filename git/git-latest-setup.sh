#!/bin/bash

function downloadLatestGitSourceTarballAndInstall() {
    echo -e "\e[37;31;1mfetching the latest git version info...\e[39;49;0m";
    local URL=https://mirrors.edge.kernel.org/pub/software/scm/git
    local latestFileName=`curl -sSL# "$URL" | grep "git-[0-9]\{1,2\}.[0-9]\{1,2\}.[0-9]\{1,2\}.tar.xz" | awk -F\" '{print $2}' | sort -V | awk 'END{print}'`;
    URL=$URL/$latestFileName

    [ -f "$latestFileName" ] && rm -rf "$latestFileName" 

    echo -e "\e[37;31;1mthe latest git version is $latestFileName\e[39;49;0m"
    echo -e "\e[37;31;1mdownloading $URL\e[39;49;0m"

    curl -LO "$URL" && {
        local fileExtension=`echo "$latestFileName" | awk -F "." '{print $NF}'`;
        if [ "$fileExtension" == "gz" ] ; then
            tar zvxf "$latestFileName"
        elif [ "$fileExtension" == "xz" ] ; then
            tar Jvxf "$latestFileName"
        fi
    
        cd `tar -tf $latestFileName | sed -n "1p"` && \
        make prefix=/usr/local/git all && \
        make prefix=/usr/local/git install && \
        $sudo ln -sfF /usr/local/git/bin/git /usr/local/bin/git && \
        echo -e "\e[37;32;1mgit has been installed into /usr/local/git\e[39;49;0m"
    }
}

function installViaApt() {
    command -v apt-get &> /dev/null && {
        $sudo apt-get -y update;
        $sudo apt-get -y install curl gawk sed tar xz-utils make gcc \
                                 libcurl4-gnutls-dev \
                                 libexpat1-dev \
                                 gettext \
                                 libz-dev \
                                 libssl-dev
        downloadLatestGitSourceTarballAndInstall
        exit
    }
}

function installViaYum() {
    command -v yum &> /dev/null && {
        $sudo yum -y update;
        $sudo yum -y install curl gawk sed tar xz make gcc \
                             curl-devel \
                             expat-devel \
                             gettext-devel \
                             openssl-devel \
                             zlib-devel \
                             perl-ExtUtils-MakeMaker
        downloadLatestGitSourceTarballAndInstall
        exit
    }
}

function installViaDnf() {
    command -v dnf &> /dev/null && {
        $sudo dnf -y update;
        $sudo dnf -y install curl gawk sed tar xz make gcc \
                             curl-devel \
                             expat-devel \
                             gettext-devel \
                             openssl-devel \
                             zlib-devel \
                             perl-ExtUtils-MakeMaker
        downloadLatestGitSourceTarballAndInstall
        exit
    }
}
function main() {
    local osType=`uname -s`

    [ "$osType" == "Drawin" ] && {
        brew update;
        brew install git;
        exit
    }

    [ "$osType" == "Linux" ] && {
    
        [ `whoami` == "root" ] || sudo=sudo;
        
        installViaApt 
        installViaDnf
        installViaYum
    }

    echo -e "\e[37;31;1mwe don't recognize your os~~\e[39;49;0m";
    exit 1
}

main
