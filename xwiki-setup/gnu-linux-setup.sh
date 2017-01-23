#!/bin/bash

#--------------------------- 说明 -----------------------------#
# 在Ubuntu和CentOS上安装XWiki
#
# 下载地址：http://www.xwiki.org/xwiki/bin/view/Download
# 参考：http://platform.xwiki.org/xwiki/bin/view/Features/DistributionWizard

#------------------下面的变量可以根据需要修改------------------#

WORK_DIR=~/bin

JDK_URL=http://download.oracle.com/otn-pub/java/jdk/8u65-b17/jdk-8u65-linux-x64.tar.gz

TOMCAT_URL=http://mirror.bit.edu.cn/apache/tomcat/tomcat-8/v8.5.9/bin/apache-tomcat-8.5.9.tar.gz

XWIKI_URL=http://download.forge.ow2.org/xwiki/xwiki-enterprise-web-8.4.4.war

MYSQL_JDBC_DRIVER_URL=http://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.34/mysql-connector-java-5.1.34.jar

# MySQL的端口
MYSQL_PORT=3306

# MySQL root用户的密码
MYSQL_ROOT_PASSWORD=123456

#--------------------------------------------------------------#

#创建xwiki数据库，并授权
function createXWikiDB() {
    mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "create database xwiki default character set utf8 collate utf8_bin;\
                                             grant all privileges on xwiki.* to xwiki identified by 'xwiki';\
                                             flush privileges;"
}

# 设置MySQL的root用户密码
function setMySQLRootPassword() {
    /etc/init.d/mysql stop
    /usr/bin/mysqld_safe --skip-grant-tables
    ehco "UPDATE User SET authentication_string=Password(${MYSQL_ROOT_PASSWORD}) WHERE User='root'" | mysql mysql
    /etc/init.d/mysql stop
    /etc/init.d/mysql start
}

# 安装MySQL
function installMySQL() {
    # 如果是Ubuntu系统
    if [ -f "/etc/lsb-release" ] ; then
        sudo apt-get undate
        sudo apt-get install -y curl wget unzip zip
        
        which mysqld
        if [ $? -eq 0 ] ; then
            echo "mysql already installed!"
        else
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
            setMySQLRootPassword
        fi
    # 如果是CentOS系统
    elif [ -f "/etc/redhat-release" ] ; then
        sudo yum undate
        sudo yum install -y curl wget unzip zip
        
        which mysqld
        if [ $? -eq 0 ] ; then
            echo "mysql already installed!"
        else
            sudo yum install -y mysql-server
            setMySQLRootPassword
        fi
    else
        echo "your system os is not ubuntu or centos"! 
    fi
}

# 下载并解压.tar.gz或者.tgz文件
# $1是要下载文件的URL
# $2是要解压到到目录，如果为空字符串，就表示不解压
function downloadTGZFileAndExtractTo() {
    fileName=`basename "$1"`
    if [ -f "${fileName}" ] ; then
        tar -tf ${fileName} > /dev/null
        if [ $? -eq 0 ] ; then
            if [ "$2" != "" ] ; then
                tar zxf ${fileName} -C "$2"
            fi
        else
            rm ${fileName}
            
            wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "$1"
            if [ $? -eq 0 ] && [ "$2" != "" ] ; then
                tar zxf ${fileName} -C "$2"
            fi
        fi
    else
        wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "$1"
        if [ $? -eq 0 ] && [ "$2" != "" ] ; then
            tar zxf ${fileName} -C "$2"
        fi
    fi
}
    
# 下载并解压.zip
# $1是要下载文件的URL
# $2是要解压到到目录，如果字符串为空，就表示不解压
function downloadZipFileAndExtractTo() {
    fileName=`basename "$1"`
    if [ -f "${fileName}" ] ; then
        unzip -t ${fileName} > /dev/null
        if [ $? -eq 0 ] ; then
            if [ "$2" != "" ] ; then
                unzip ${fileName} -d "$2" > /dev/null
            fi
        else
            rm ${fileName}
            wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "$1"
            if [ $? -eq 0 ] && [ "$2" != "" ] ; then
                unzip ${fileName} -d "$2" > /dev/null
            fi
        fi
    else
        wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "$1"
        if [ $? -eq 0 ] && [ "$2" != "" ] ; then
            unzip ${fileName} -d "$2" > /dev/null
        fi
    fi
}

# 下载文件并解压到指定目录
# $1是要下载文件的URL
# $2是要解压到到目录
function downloadFileAndExtractTo() {
    fileName=`basename "$1"`
    extension=`echo "${fileName##*.}"`
    
    echo "downloadFile() url=$1 | fileName=$fileName | extension=$extension"
    
    if [ "$extension" = "tgz" ] ; then
        downloadTGZFileAndExtractTo $1 $2
    elif [ "$extension" = "gz" ] ; then
        downloadTGZFileAndExtractTo $1 $2
    elif [ "$extension" = "zip" ] ; then
        downloadZipFileAndExtractTo $1 $2
    elif [ "$extension" = "war" ] ; then
        downloadZipFileAndExtractTo $1 $2
    elif [ "$extension" = "jar" ] ; then
        downloadZipFileAndExtractTo $1 $2
    fi
}

# 下载JDK
function downloadJDKAndConfig() {
    which java
    if [ $? -eq 0 ] ; then
        echo "JDK is already installed! so, not need to download and config"
    else
        downloadFileAndExtractTo $JDK_URL ${WORK_DIR}

        #配置环境变量
        echo "export JAVA_HOME=${JAVA_HOME}" >> ~/.bashrc
        echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
        echo "export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> ~/.bashrc
    fi
}

# 正文
function main() {
    cd ~
    
    if [ ! -d "${WORK_DIR}" ] ; then
        mkdir -p ${WORK_DIR}
    fi
    
    installMySQL
    
    createXWikiDB   
    
    downloadJDKAndConfig

    downloadFileAndExtractTo $TOMCAT_URL ${WORK_DIR}

    tomcatFileName=`basename "$TOMCAT_URL"`
    tomcatHomeDir=${WORK_DIR}/`basename ${tomcatFileName} .tar.gz`

    downloadFileAndExtractTo $XWIKI_URL ${tomcatHomeDir}/webapps/xwiki
    
    downloadFileAndExtractTo $MYSQL_JDBC_DRIVER_URL
    
    mysqlJdbcDriverFileName=`basename "$MYSQL_JDBC_DRIVER_URL"`
    cp ${mysqlJdbcDriverFileName} ${tomcatHomeDir}/webapps/xwiki/WEB-INF/lib/
    
    # 启动Tomcat服务
    sh ${tomcatHomeDir}/bin/startup.sh
    
    cd -
}

main
