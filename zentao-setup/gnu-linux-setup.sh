#!/bin/bash

#--------------------------- 说明 -----------------------------#
# 在Ubuntu和CentOS上安装禅道
#
# 禅道的一键安装包下载地址：http://www.zentao.net/download.html
# 参考：http://www.zentao.net/book/zentaopmshelp/90.html

#------------------下面的变量可以根据需要修改------------------#

# 您要安装的版本，只需要修改此处即可
VERSION=9.0.beta

# Apache的端口，可以修改成你自己想要的
APACHE_PORT=8080

# MySQL的端口，可以修改成你自己想要的
MYSQL_PORT=3306

#--------------------------------------------------------------#

function downloadAndUnzip() {
    # 32位还是64位
    x=32
    if [ "`uname -m`" == "x86_64" ] ; then
        x=64
    fi
    
    fileName=ZenTaoPMS.${VERSION}.zbox_${x}.tar.gz
    url=http://dl.cnezsoft.com/zentao/${VERSION}/${fileName}
    
    cd ~ 
    
    if [ -f "${fileName}" ] ; then
        tar -tf ${fileName}
        if [ $? -eq 0 ] ; then
            sudo tar zvxf ${fileName} -C /opt && \
            sudo /opt/zbox/zbox start -ap ${APACHE_PORT} -mp ${MYSQL_PORT}
        else
            rm ${fileName}

            curl -O ${url} && \
            sudo tar zvxf ${fileName} -C /opt && \
            sudo /opt/zbox/zbox start -ap ${APACHE_PORT} -mp ${MYSQL_PORT}
        fi
    else
        curl -O ${url} && \
        sudo tar zvxf ${fileName} -C /opt && \
        sudo /opt/zbox/zbox start -ap ${APACHE_PORT} -mp ${MYSQL_PORT}
    fi

    cd - > /dev/null
}

function main() {
    # 如果是Ubuntu系统
    if [ -f "/etc/lsb-release" ] || [ -f "/etc/debian_version" ] ; then
        sudo apt-get update
        sudo apt-get -y install curl
    
        downloadAndUnzip
    # 如果是CentOS系统
    elif [ -f "/etc/redhat-release" ] ; then
        sudo yum update
        sudo yum -y install curl
    
        downloadAndUnzip
    else
        echo "your system os is not ubuntu or centos"! 
    fi
}

main
