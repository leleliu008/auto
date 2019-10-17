#!/bin/sh

sudo=$(command -v sudo 2> /dev/null);
osType=$(uname -s);

Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b\n" "$1"
}

info() {
    msg "${Color_Purple}[❉]${Color_Off} $1$2"
}

downloadLatestGitSourceTarballAndInstall() {
    info "Fetching the latest git version info...";

    URL=https://mirrors.edge.kernel.org/pub/software/scm/git
    latestFileName=$(curl -sSL# "$URL" | grep "git-[0-9]\{1,2\}.[0-9]\{1,2\}.[0-9]\{1,2\}.tar.xz" | awk -F\" '{print $2}' | sort -V | awk 'END{print}');
    URL=$URL/$latestFileName

    [ -f "$latestFileName" ] && rm -rf "$latestFileName" 

    info "the latest git version is $latestFileName"
    info "Downloading $URL"

    curl -LO "$URL" && {
        fileExtension="$(printf "%s\n" "$latestFileName" | awk -F. '{print $NF}')";
        if [ "$fileExtension" = "gz" ] ; then
            tar zvxf "$latestFileName"
        elif [ "$fileExtension" = "xz" ] ; then
            tar Jvxf "$latestFileName"
        fi
    
        cd "$(tar -tf "$latestFileName" | sed -n "1p")" &&
        destDir=/usr/local/opt/git &&
        make prefix="$destDir" all &&
        $sudo make prefix="$destDir" install &&
        $sudo ln -sfF "$destDir/bin/git" /usr/local/bin/git &&
        info "git has been installed into $destDir"
    }
}

checkDependencies() {
    info "Checking Dependencies..."

    command -v curl > /dev/null || pkgNames="$pkgNames curl"
    command -v sed  > /dev/null || pkgNames="$pkgNames sed"
    command -v tar  > /dev/null || pkgNames="$pkgNames tar"
    command -v gzip > /dev/null || pkgNames="$pkgNames gzip"
    command -v awk  > /dev/null || pkgNames="$pkgNames gawk"
    command -v make > /dev/null || pkgNames="$pkgNames make"
    command -v gcc  > /dev/null || pkgNames="$pkgNames gcc"
}

installDependencies() {
    info "Installing Dependencies $pkgNames"

    command -v apt-get > /dev/null && {
        $sudo apt-get -y update
        $sudo apt-get -y install $@ xz-utils libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev
        return 0
    }
    
    command -v dnf > /dev/null && {
        $sudo dnf -y update
        $sudo dnf -y install $@ xz curl-devel expat-devel gettext-devel openssl-devel zlib-devel perl-ExtUtils-MakeMaker
        return 0
    }
    
    command -v yum > /dev/null && {
        $sudo yum -y update
        $sudo yum -y install $@ xz curl-devel expat-devel gettext-devel openssl-devel zlib-devel perl-ExtUtils-MakeMaker
        return 0
    }
}

installHomeBrewIfNeeded() {
    if command -v brew > /dev/null ; then
        brew update
    else
        printf "\n\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
}

main() {
    [ "$osType" = "Drawin" ] && {
        installHomeBrewIfNeeded
        if command -v git > /dev/null ; then
            brew upgrade git
        else
            brew install git
        fi
        exit
    }

    [ "$osType" = "Linux" ] && {
        checkDependencies
         
        [ -z "$pkgNames" ] || installDependencies "$pkgNames"
        
        downloadLatestGitSourceTarballAndInstall
    }
}

main
