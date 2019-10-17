#!/bin/sh

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

[ "$(whoami)" = "root" ] || sudo=sudo

Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b\n" "$1"
}

info() {
    msg "${Color_Purple}[❉]${Color_Off} $1$2"
}

checkDependencies() {
    info "checkDependencies..."
    command -v curl > /dev/null || pkgNames="curl"
    command -v tar  > /dev/null || pkgNames="$pkgNames tar"
    command -v gzip > /dev/null || pkgNames="$pkgNames gzip"
    command -v grep > /dev/null || pkgNames="$pkgNames grep"
    command -v ps   > /dev/null || pkgNames="$pkgNames procps procps-ng"
}

installDependencies() {
    info "installDependencies $pkgNames"

    command -v apt-get > /dev/null && {
        $sudo apt-get -y update &&
        $sudo apt-get -y install $@
        return $?
    }
        
command -v dnf > /dev/null && {
    $sudo dnf -y update &&
        $sudo dnf -y install $@
        return $?
    }

    command -v yum > /dev/null && {
        $sudo yum -y update &&
        $sudo yum -y install $@
        return $?
    }
    
    command -v zypper > /dev/null && {
        $sudo zypper update -y &&
        $sudo zypper install -y $@
        return $?
    }
    
    command -v pacman > /dev/null && {
        $sudo pacman -Syyuu --noconfirm &&
        $sudo pacman -S     --noconfirm $@
        return $?
    }
    
    command -v apk > /dev/null && {
        $sudo apk update &&
        $sudo apk add $@
        return $?
    }
}

downloadExtractStart() {
    # 32位还是64位
    if [ "$(uname -m)" = "x86_64" ] ; then
        x=64
    else
        x=32
    fi

    fileName=ZenTaoPMS.${VERSION}.zbox_${x}.tar.gz
    url=http://dl.cnezsoft.com/zentao/${VERSION}/${fileName}
    
    cd "$HOME" || exit
    
    [ -f "${fileName}" ] && tar -tf ${fileName} > /dev/null 2>&1 && {
        extractAndStartService "$fileName"
        exit $?
    }
    curl -C - -LO ${url} && extractAndStartService "$fileName"
}

extractAndStartService() {
    $sudo tar zvxf "$1" -C /opt &&
    $sudo /opt/zbox/zbox start -ap ${APACHE_PORT} -mp ${MYSQL_PORT}
}

main() {
    [ "$(uname -s)" = "Darwin" ] && {
        info "ZenTaoPMS not support macOS!"
        exit 1
    }
    
    [ -f "/opt/zbox/zbox" ] && {
        info "ZenTaoPMS already installed! Location:/opt/zbox/"
        exit 0
    }
    
    checkDependencies
    
    ([ -z "$pkgNames" ] || installDependencies "$pkgNames") && downloadExtractStart
}

main
