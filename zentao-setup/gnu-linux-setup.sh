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

# 32位还是64位
X=32
if [ `uname -m` == "x86_64" ] ; then
    X=64
fi

FILE_NAME=ZenTaoPMS.${VERSION}.zbox_${X}.tar.gz
URL=http://dl.cnezsoft.com/zentao/${VERSION}/${FILE_NAME}

function doWork() {
    cd ~ 
    
    if [ -f "${FILE_NAME}" ] ; then
        rm ${FILE_NAME}
    fi

    curl -O ${URL} && \
    sudo tar zvxf ${FILE_NAME} -C /opt && \
    rm ${FILE_NAME} && \
    sudo /opt/zbox/zbox start -ap ${APACHE_PORT} -mp ${MYSQL_PORT}

    cd -
}

# 如果是Ubuntu系统
if [ -f "/etc/lsb-release" ] ; then
    sudo apt-get undate
    sudo apt-get install -y curl
    
    doWork
# 如果是CentOS系统
elif [ -f "/etc/redhat-release" ] ; then
    sudo yum undate
    sudo yum install -y curl
    
    doWork
else
   echo "your system os is not ubuntu or centos"! 
fi
