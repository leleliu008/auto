#!/bin/sh

url=https://github.com/Microsoft/vcpkg.git
destDir=/usr/local/opt/vcpkg
sudo=$(command -v sudo 2> /dev/null)
osType=$(uname -s)

install_macOS_SDK_headers_IfNeeded() {
    [ -d /usr/include ] || $sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /
}

installDependency() {
    if [ "$osType" = "Linux" ] ; then
        # 如果是ArchLinux或ManjaroLinux系统
        command -v pacman > /dev/null && {
            $sudo pacman -Syyuu --noconfirm &&
            command -v curl  > /dev/null || $sudo pacman -S curl  --noconfirm &&
            command -v git   > /dev/null || $sudo pacman -S git   --noconfirm &&
            command -v unzip > /dev/null || $sudo pacman -S unzip --noconfirm &&
            command -v gzip  > /dev/null || $sudo pacman -S gzip  --noconfirm &&
            command -v tar   > /dev/null || $sudo pacman -S tar   --noconfirm &&
            command -v gcc   > /dev/null || $sudo pacman -S gcc   --noconfirm &&
            return 0
        }
        
        # 如果是Debian GNU/Linux系
        command -v apt-get > /dev/null && {
            $sudo apt-get -y update &&
            $sudo apt-get -y install curl git unzip gzip tar gcc g++ &&
            return 0
        }
        
        # 如果是Fedora或CentOS8系统
        command -v dnf > /dev/null && {
            $sudo dnf -y update &&
            $sudo dnf -y install curl git unzip gzip tar gcc gcc-c++ &&
            return 0
        }
        
        # 如果是CentOS8以下的系统
        command -v yum > /dev/null && { 
            $sudo yum -y update &&
            $sudo yum -y install curl git unzip gzip tar gcc gcc-c++ &&
            return 0
        }

        # 如果是OpenSUSE系统
        command -v zypper > /dev/null && { 
            $sudo zypper update -y &&
            $sudo zypper install -y curl git unzip gzip tar gcc gcc-c++ &&
            return 0
        }
        
        # 如果是AlpineLinux系统
        command -v apk > /dev/null && {
            $sudo apk update &&
            $sudo apk add curl git unzip gzip tar gcc &&
            return 0
        }
    elif [ "$osType" = "Darwin" ] ; then
        if command -v brew > /dev/null; then
            brew update
        else
            printf "\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        fi

        command -v curl  > /dev/null || brew install curl
        command -v git   > /dev/null || brew install git
        command -v unzip > /dev/null || brew install unzip
        command -v gzip  > /dev/null || brew install gzip
        command -v tar   > /dev/null || brew install gnu-tar
        command -v gcc-9 > /dev/null || brew install gcc
        
        install_macOS_SDK_headers_IfNeeded
        return 0
    fi
}


link() {
    linkedDir=/usr/local/bin
    if [ -d "$linkedDir" ] ; then
        if [ -w "$linkedDir" ] ; then
            ln -sf "$destDir/vcpkg" "$linkedDir/vcpkg"
        else
            sudo ln -sf "$destDir/vcpkg" "$linkedDir/vcpkg" &&
            sudo chown "$(whoami)" "$linkedDir/vcpkg"
        fi
    else
        $sudo install -d -o "$(whoami)" "$linkedDir" &&
        ln -sf "$destDir/vcpkg" "$linkedDir/vcpkg"
    fi
}

main() {
    if [ -d "$destDir" ] ; then
        if [ -d "$destDir/.git" ] ; then
            installDependency &&
            cd "$destDir" &&
            git pull && 
            ./bootstrap-vcpkg.sh &&
            link
        else
            echo "$destDir already exsit, but not a git repo."
        fi
    else
        installDependency &&
        install -d -o "$(whoami)" "$destDir" &&
        git clone "$url" "$destDir" &&
        cd "$destDir" &&
        ./bootstrap-vcpkg.sh &&
        link
    fi
}

main
