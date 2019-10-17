#!/bin/sh

#--------------------------- 说明 -----------------------------#
# 在Ubuntu和CentOS上安装XWiki
#
# 下载地址：http://www.xwiki.org/xwiki/bin/view/Download
# 参考：http://platform.xwiki.org/xwiki/bin/view/Features/DistributionWizard

#------------------下面的变量可以根据需要修改------------------#

WORK_DIR=~/bin

TOMCAT_URL=https://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-9/v9.0.27/bin/apache-tomcat-9.0.27.tar.gz

XWIKI_URL=http://download.forge.ow2.org/xwiki/xwiki-enterprise-web-8.4.4.war

MYSQL_URL=https://downloads.mysql.com/archives/get/file/mysql-5.7.27-linux-glibc2.12-x86_64.tar.gz

MYSQL_JDBC_DRIVER_URL=http://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.34/mysql-connector-java-5.1.34.jar

# MySQL的端口
MYSQL_PORT=3306

# MySQL root用户的密码
MYSQL_ROOT_PASSWORD=123456

#--------------------------------------------------------------#

[ "$(whoami)" = "root" ] || sudo=sudo

Color_Red='\033[0;31m'          # Red
Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b\n" "$1"
}

info() {
    msg "${Color_Purple}[❉]${Color_Off} $1$2"
}

error() {
    msg "${Color_Red}[✘]${Color_Off} $1$2"
    exit 1
}

# 设置MySQL的root用户密码
configMySQL() {
    if [ -f /usr/local/mysql ] ; then
        printf "%s\n" "/usr/local/mysql already exsit, override it? y/n"
        read -r var
        if [ "$var" = 'y' ] || [ "$var" = 'Y' ] ; then
            $sudo mv "$WORK_DIR/$(basename "$MYSQL_URL" .tar.gz)" /usr/local/mysql
        else
            exit
        fi
    else
        $sudo mv "$WORK_DIR/$(basename "$MYSQL_URL" .tar.gz)" /usr/local/mysql
    fi

    info "configMySQL..."
   
    export PATH=/usr/local/mysql/bin:$PATH
    
    groupadd -f mysql
    useradd  -r -s /bin/false -g mysql mysql 2> /dev/null

    $sudo chown -R mysql:mysql /usr/local/mysql

    #创建mysql数据库
    mysqld --port=$MYSQL_PORT --initialize

    $sudo chown -R root  /usr/local/mysql
    $sudo chown -R mysql /usr/local/mysql/data

    mysqld --user=mysql --port=$MYSQL_PORT --skip-grant-tables &
    sleep 5

    #修改root账户的密码
    printf "%s\n" "UPDATE mysql.user SET authentication_string=Password(${MYSQL_ROOT_PASSWORD}) WHERE User='root'" | mysql
    
    $sudo pkill mysql
    sleep 5
        
    mysqld_safe --user=mysql --port=$MYSQL_PORT &
    sleep 5

    #创建xwiki数据库，并授权    
    mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "create database if not exists xwiki default character set utf8 collate utf8_bin;\
                                             grant all privileges on xwiki.* to xwiki identified by 'xwiki';\
                                             flush privileges;"
}

checkDependencies() {
    info "Checking Dependencies..."

    command -v curl  > /dev/null || pkgNames="curl"
    command -v zip   > /dev/null || pkgNames="$pkgNames zip"
    command -v unzip > /dev/null || pkgNames="$pkgNames unzip"
    command -v tar   > /dev/null || pkgNames="$pkgNames tar"
    command -v gzip  > /dev/null || pkgNames="$pkgNames gzip"
    
    command -v java  > /dev/null || {
        if command -v apt-get > /dev/null ; then
            pkgNames="$pkgNames openjdk-8-jdk"
        elif command -v dnf > /dev/null ; then
            pkgNames="$pkgNames java-1.8.0-openjdk"
        elif command -v yum > /dev/null ; then
            pkgNames="$pkgNames java-1.8.0-openjdk"
        elif command -v zypper > /dev/null ; then
            pkgNames="$pkgNames java-1_8_0-openjdk"
        elif command -v pacman > /dev/null ; then
            pkgNames="$pkgNames jdk8-openjdk"
        elif command -v apk > /dev/null ; then
            pkgNames="$pkgNames openjdk8"
        fi
    }
    
    ldconfig -p | grep libnuma > /dev/null || pkgNames="$pkgNames numactl"

    ldconfig -p | grep libaio > /dev/null || {
        if command -v apt-get > /dev/null ; then
            pkgNames="$pkgNames libaio-dev"
        elif command -v dnf > /dev/null ; then
            pkgNames="$pkgNames libaio"
        elif command -v yum > /dev/null ; then
            pkgNames="$pkgNames libaio"
        elif command -v zypper > /dev/null ; then
            pkgNames="$pkgNames libaio"
        elif command -v pacman > /dev/null ; then
            pkgNames="$pkgNames libaio"
        elif command -v apk > /dev/null ; then
            pkgNames="$pkgNames libaio"
        fi
    }
}

# 安装依赖
installDependencies() {
    info "Installing Dependencies $pkgNames"

    if command -v apt-get > /dev/null ; then
        $sudo apt-get -y update &&
        $sudo apt-get -y install $@
    elif command -v dnf > /dev/null ; then
        $sudo dnf -y update &&
        $sudo dnf -y install $@
    elif command -v yum > /dev/null ; then
        $sudo yum -y update &&
        $sudo yum -y install $@
    elif command -v zypper > /dev/null ; then
        $sudo zypper update -y &&
        $sudo zypper install -y $@
    elif command -v apk > /dev/null ; then
        $sudo apk update &&
        $sudo apk add $@
    elif command -v pacman > /dev/null ; then
        $sudo pacman -Syyuu --noconfirm &&
        $sudo pacman -S     --noconfirm $@
    fi
}

# 下载
# $1是要下载文件的URL
download() {
    fileName=$(basename "$1")
    [ -f "$fileName" ] && checkCompleteness "$fileName" && return 0
    info "Downloading $1"
    curl -C - -LO "$1"
}

# 下载并解压
# $1是要下载文件的URL
# $2是要解压到的目录
downloadAndUncompress() {
    fileName=$(basename "$1")
    if [ -f "$fileName" ] ; then
        if checkCompleteness "$fileName" ; then
            uncompress "$fileName" "$2"
            return $?
        fi
    fi
    info "Downloading $1"
    curl -C - -LO "$1" || exit 1
    uncompress "$fileName" "$2"
}

# 检测文件的完整性
# $1是文件路径
checkCompleteness() {
    fileName=$1
    extension="${fileName##*.}"
    
    info "checkCompleteness $fileName"
    
    case $extension in
        "tgz")
            tar -tf "$fileName" > /dev/null
            ;;
        "gz")
            tar -tf "$fileName" > /dev/null
            ;;
        "zip")
            unzip -t "$fileName" > /dev/null
            ;;
        "war")
            unzip -t "$fileName" > /dev/null
            ;;
        "jar")
            unzip -t "$fileName" > /dev/null
            ;;
    esac
}

# 解压文件
# $1是要解压的文件路径
# $2是要解压到的目录
uncompress() {
    info "Uncompressing $1"
    fileName=$1
    extension="${fileName##*.}"
    
    if [ -z "$2" ] ; then
        destDir="$WORK_DIR"
    else
        destDir="$2"
    fi

    info "uncompress $fileName extension=$extension"
    
    case $extension in
        "tgz")
            tar zvxf "$fileName" -C "$destDir"
            ;;
        "gz")
            tar zvxf "$fileName" -C "$destDir"
            ;;
        "zip")
            unzip "$fileName" -d "$destDir"
            ;;
        "war")
            unzip "$fileName" -d "$destDir"
            ;;
        "jar")
            unzip "$fileName" -d "$destDir"
            ;;
    esac
}

writeJDKEnv() {
    cat >> "$1" <<EOF
export JAVA_HOME=/usr/lib/jvm/java-8-oracle
export PATH=\$JAVA_HOME/bin:\$PATH
export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar
EOF
}

# 配置JDK的环境变量
configJDKEnv() {
    writeJDKEnv ~/.bashrc
    writeJDKEnv ~/.zshrc
}

# 正文
main() {
    [ -d "$WORK_DIR" ] || mkdir -p "$WORK_DIR"
    cd "$WORK_DIR" || exit 1

    checkDependencies
    [ -z "$pkgNames" ] || installDependencies "$pkgNames"
    
    configJDKEnv

    downloadAndUncompress "$TOMCAT_URL"
    
    tomcatFileName=$(basename "$TOMCAT_URL")
    tomcatHomeDir=${WORK_DIR}/$(basename "$tomcatFileName" .tar.gz)

    downloadAndUncompress "$XWIKI_URL" "${tomcatHomeDir}/webapps/xwiki"
    
    downloadAndUncompress "$MYSQL_URL" && configMySQL 
    
    download "$MYSQL_JDBC_DRIVER_URL" && {
        mysqlJdbcDriverFileName=$(basename "$MYSQL_JDBC_DRIVER_URL")
        cp "$mysqlJdbcDriverFileName" "${tomcatHomeDir}/webapps/xwiki/WEB-INF/lib/"
    }
    
    # 启动Tomcat服务
    sh "${tomcatHomeDir}/bin/startup.sh"
}

main
