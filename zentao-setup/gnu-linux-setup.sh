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
    [ `whoami` == "root" ] || sudo=sudo

    command -v apt-get &> /dev/null && {
        $sudo apt-get -y update
        $sudo apt-get -y install curl
        downloadExtractStart
        exit $?
    }
    
    command -v yum &> /dev/null && {
        $sudo yum -y update
        $sudo yum -y install curl
        downloadExtractStart
        exit $?
    }
    
    echo "don't support your os!!"
}

main
