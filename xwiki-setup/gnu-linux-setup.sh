#!/bin/bash

#--------------------------- 说明 -----------------------------#
# 在Ubuntu和CentOS上安装XWiki
#
# 下载地址：http://www.xwiki.org/xwiki/bin/view/Download
# 参考：http://platform.xwiki.org/xwiki/bin/view/Features/DistributionWizard

#------------------下面的变量可以根据需要修改------------------#

WORK_DIR=~/bin

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
    [ `whoami` == "root" ] || sudo=sudo

    if [ -n "`command -v apt-get &> /dev/null`" ] ; then
        $sudo apt-get -y update
        $sudo apt-get -y install curl unzip zip openjdk-8-jdk
        
        command -v mysqld &> /dev/null || {
            $sudo DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server
            setMySQLRootPassword
        }
    elif [ -n "`command -v dnf &> /dev/null`" ] ; then
        $sudo dnf -y update
        $sudo dnf -y install curl unzip zip java-1.8.0-openjdk
        
        command -v mysqld &> /dev/null || {
            $sudo dnf -y install mysql-server
            $setMySQLRootPassword
        }
    elif [ -n "`command -v yum &> /dev/null`" ] ; then
        $sudo yum -y update
        $sudo yum -y install curl wget unzip zip java-1.8.0-openjdk
        
        command -v mysqld &> /dev/null || {
            $sudo yum -y install mysql-server
            setMySQLRootPassword
        }
    else
        echo "We don't recognize your os!!"
    fi
}

# 下载并解压.tar.gz或者.tgz文件
# $1是要下载文件的URL
# $2是要解压到到目录，如果为空字符串，就表示不解压
function downloadTGZFileAndExtractTo() {
    local fileName=`basename "$1"`
    if [ -f "${fileName}" ] ; then
        tar -tf ${fileName} > /dev/null
        if [ $? -eq 0 ] ; then
            [ -z "$2" ] || tar zxf ${fileName} -C "$2"
        else
            curl -C - -LO "$1" && [ -n "$2" ] && tar zxf ${fileName} -C "$2"
        fi
    else
        curl -LO "$1" && [ -n "$2" ] && tar zxf ${fileName} -C "$2"
    fi
}
    
# 下载并解压.zip
# $1是要下载文件的URL
# $2是要解压到到目录，如果字符串为空，就表示不解压
function downloadZipFileAndExtractTo() {
    local fileName=`basename "$1"`
    if [ -f "${fileName}" ] ; then
        unzip -t ${fileName} &> /dev/null
        if [ $? -eq 0 ] ; then
            [ -z "$2" ] || unzip ${fileName} -d "$2" > /dev/null
        else
            curl -C - -LO "$1" && unzip ${fileName} -d "$2" > /dev/null
        fi
    else
        curl -C - -LO "$1" && unzip ${fileName} -d "$2" > /dev/null
    fi
}

# 下载文件并解压到指定目录
# $1是要下载文件的URL
# $2是要解压到到目录
function downloadFileAndExtractTo() {
    local fileName=`basename "$1"`
    local extension=`echo "${fileName##*.}"`
    
    echo "downloadFile() url=$1 | fileName=$fileName | extension=$extension"
    
    if [ "$extension" == "tgz" ] ; then
        downloadTGZFileAndExtractTo $1 $2
    elif [ "$extension" == "gz" ] ; then
        downloadTGZFileAndExtractTo $1 $2
    elif [ "$extension" == "zip" ] ; then
        downloadZipFileAndExtractTo $1 $2
    elif [ "$extension" == "war" ] ; then
        downloadZipFileAndExtractTo $1 $2
    elif [ "$extension" == "jar" ] ; then
        downloadZipFileAndExtractTo $1 $2
    fi
}

# 配置JDK的环境变量
function configJDKEnv() {
    echo "export JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> ~/.bashrc
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
    echo "export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> ~/.bashrc
    
    echo "export JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> ~/.zshrc
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.zshrc
    echo "export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> ~/.zshrc
}

# 正文
function main() {
    cd ~
    
    [ -d "${WORK_DIR}" ] || mkdir -p ${WORK_DIR}
    
    installMySQL
    
    createXWikiDB   
    
    configJDKEnv

    downloadFileAndExtractTo $TOMCAT_URL ${WORK_DIR}

    local tomcatFileName=`basename "$TOMCAT_URL"`
    local tomcatHomeDir=${WORK_DIR}/`basename ${tomcatFileName} .tar.gz`

    downloadFileAndExtractTo $XWIKI_URL ${tomcatHomeDir}/webapps/xwiki
    
    downloadFileAndExtractTo $MYSQL_JDBC_DRIVER_URL
    
    local mysqlJdbcDriverFileName=`basename "$MYSQL_JDBC_DRIVER_URL"`
    cp ${mysqlJdbcDriverFileName} ${tomcatHomeDir}/webapps/xwiki/WEB-INF/lib/
    
    # 启动Tomcat服务
    sh ${tomcatHomeDir}/bin/startup.sh
}

main
