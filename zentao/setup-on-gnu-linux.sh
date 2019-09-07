#!/bin/bash

#--------------------------- 说明 -----------------------------#
# 在Ubuntu和CentOS上安装禅道
#
# 禅道的一键安装包下载地址：http://www.zentao.net/download.html
# 参考：http://www.zentao.net/book/zentaopmshelp/90.html

#------------------下面的变量可以根据需要修改------------------#

# 您要安装的版本，只需要修改此处即可
VERSION=11.5.1

# Apache的端口，可以修改成你自己想要的
APACHE_PORT=8080

# MySQL的端口，可以修改成你自己想要的
MYSQL_PORT=3306

#--------------------------------------------------------------#

function installCurlIfPossible() {
    command -v curl &> /dev/null || {
        command -v apt-get &> /dev/null && {
            $sudo apt-get -y update && \
            $sudo apt-get -y install curl
            return $?
        }
        
        command -v dnf &> /dev/null && {
            $sudo dnf -y update && \
            $sudo dnf -y install curl
            return $?
        }
    
        command -v yum &> /dev/null && {
            $sudo yum -y update && \
            $sudo yum -y install curl
            return $?
        }
        
        command -v zypper &> /dev/null && {
            $sudo zypper update -y && \
            $sudo zypper install -y curl
            return $?
        }
        
        command -v pacman &> /dev/null && {
            $sudo pacman -Syyuu --noconfirm && \
            $sudo pacman -S     --noconfirm curl
            return $?
        }
        
        command -v zypper &> /dev/null && {
            $sudo apk update && \
            $sudo apk add curl
            return $?
        }

        echo "who are you?"
        exit 1
    }
}

function downloadExtractStart() {
    # 32位还是64位
    local x=32
    [ "`uname -m`" == "x86_64" ] && x=64
    
    local fileName=ZenTaoPMS.${VERSION}.zbox_${x}.tar.gz
    local url=http://dl.cnezsoft.com/zentao/${VERSION}/${fileName}
    
    cd ~ 
    
    [ -f "${fileName}" ] && tar -tf ${fileName} &> /dev/null && {
        extractAndStartService "$fileName"
        exit $?
    }
    curl -C - -LO ${url} && extractAndStartService "$fileName"
}

function extractAndStartService() {
    $sudo tar zvxf "$1" -C /opt && \
    $sudo /opt/zbox/zbox start -ap ${APACHE_PORT} -mp ${MYSQL_PORT}
}

function main() {
    [ "$(uname -s)" == "Darwin" ] && {
        echo "ZenTaoPMS not support macOS!"
        exit 1
    }
    
    [ -f "/opt/zbox/zbox" ] && {
        echo "ZenTaoPMS already installed!"
        exit 0
    }
    
    [ `whoami` == "root" ] || sudo=sudo

    installCurlIfPossible && downloadExtractStart
}

main
