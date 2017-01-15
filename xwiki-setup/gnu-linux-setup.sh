#!/bin/bash

#--------------------------- 说明 -----------------------------#
# 在Ubuntu和CentOS上安装XWiki
#
# 下载地址：http://www.xwiki.org/xwiki/bin/view/Download
# 参考：http://platform.xwiki.org/xwiki/bin/view/Features/DistributionWizard

#------------------下面的变量可以根据需要修改------------------#

WORK_DIR=~/bin

JAVA_HOME=${WORK_DIR}/jdk1.8.0_65
JDK_FILE_NAME=jdk-8u65-linux-x64.tar.gz
JDK_URL=http://download.oracle.com/otn-pub/java/jdk/8u65-b17/${JDK_FILE_NAME}

TOMCAT_FILE_NAME=apache-tomcat-8.5.9.tar.gz
TOMCAT_URL=http://mirror.bit.edu.cn/apache/tomcat/tomcat-8/v8.5.9/bin/${TOMCAT_FILE_NAME}

XWIKI_FILE_NAME=xwiki-enterprise-web-8.4.4.war
XWIKI_URL=http://download.forge.ow2.org/xwiki/${XWIKI_FILE_NAME}

MYSQL_JDBC_DRIVER_FILE_NAME=mysql-connector-java-5.1.34.jar
MYSQL_JDBC_DRIVER_URL=http://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.34/${MYSQL_JDBC_DRIVER_FILE_NAME}

# MySQL的端口
MYSQL_PORT=3306

# MySQL root用户的密码
MYSQL_ROOT_PASSWORD=123456

#--------------------------------------------------------------#

tomcatHomeDir=${WORK_DIR}/`basename ${TOMCAT_FILE_NAME} .tar.gz`

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

# 下载JDK
function downloadJDKAndConfig() {
    which java
    if [ $? -eq 0 ] ; then
        echo "JDK is already installed! so, not need to download and config"
    else
        url=${JDK_URL}
        fileName=${JDK_FILE_NAME}
        
        # 如果安装包已经存在了
        if [ -f "${fileName}" ] ; then
            tar -tf ${fileName} > /dev/null
            # 如果安装包是完好无损的
            if [ $? -eq 0 ] ; then
                echo "${fileName} is exsit, don't download"
                tar zvxf ${fileName} -C ${WORK_DIR}
            else
                rm ${fileName}
                wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" ${url} && \
                tar zvxf ${fileName} -C ${WORK_DIR}
            fi
        fi

        #配置环境变量
        echo "export JAVA_HOME=${JAVA_HOME}" >> ~/.bashrc
        echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
        echo "export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> ~/.bashrc
    fi
}

# 下载Tomcat
function downloadTomcat() {
    url=${TOMCAT_URL}
    fileName=${TOMCAT_FILE_NAME}
    
    # 如果安装包已经存在了
    if [ -f "${fileName}" ] ; then
        tar -tf ${fileName} > /dev/null
        # 如果安装包是完好无损的
        if [ $? -eq 0 ] ; then
            echo "${fileName} is exsit, don't download"
            tar zxf ${fileName} -C ${WORK_DIR}
        else
            rm ${fileName}
            wget ${fileName} && \
            tar zxf ${fileName} -C ${WORK_DIR}
        fi
    else
        wget ${url} && \
        tar zxf ${fileName} -C ${WORK_DIR}
    fi
}

# 下载XWiki
function downloadXWiki() {
    url=${XWIKI_URL}
    fileName=${XWIKI_FILE_NAME}
    
    # 如果安装包已经存在了
    if [ -f "${fileName}" ] ; then
        unzip -t ${fileName} > /dev/null
        # 如果安装包是完好无损的
        if [ $? -eq 0 ] ; then
            echo "${fileName} is exsit, don't download"
            unzip -o ${fileName} -d ${tomcatHomeDir}/webapps/xwiki
        else
            rm ${fileName}
            wget ${url} && \
            unzip -o ${fileName} -d ${tomcatHomeDir}/webapps/xwiki
        fi
    else
        wget ${url} && \
        unzip -o ${fileName} -d ${tomcatHomeDir}/webapps/xwiki
    fi
}

# 下载MySQL JDBC驱动
function downloadMySQLJDBCDriver() {
    url=${MYSQL_JDBC_DRIVER_URL}
    fileName=${MYSQL_JDBC_DRIVER_FILE_NAME}

    # 如果安装包已经存在了
    if [ -f "${fileName}" ] ; then
        unzip -t ${fileName} > /dev/null
        # 如果安装包是完好无损的
        if [ $? -eq 0 ] ; then
            echo "${fileName} is exsit, don't download"
            cp ${fileName} ${tomcatHomeDir}/webapps/xwiki/WEB-INF/lib/
        else
            rm ${fileName}
            wget ${url} && \
            cp ${fileName} ${tomcatHomeDir}/webapps/xwiki/WEB-INF/lib/
        fi
    else
        wget ${url} && \
        cp ${fileName} ${tomcatHomeDir}/webapps/xwiki/WEB-INF/lib/
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

    downloadTomcat

    downloadXWiki
    
    downloadMySQLJDBCDriver
    
    # 启动Tomcat服务
    sh ${tomcatHomeDir}/bin/startup.sh
    
    cd -
}

main
