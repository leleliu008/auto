#!/bin/sh

installOhMyFish() {
    curl -L https://get.oh-my.fish | fish
}

main() {
    sudo=$(command -v sudo 2> /dev/null)
    osType=$(uname -s)

    if [ "$osType" = "Linux" ] ; then
        # 如果是ArchLinux或ManjaroLinux系统
        command -v pacman > /dev/null && {
            $sudo pacman -Syyuu --noconfirm &&
            command -v curl > /dev/null || $sudo pacman -S curl --noconfirm &&
            command -v fish > /dev/null || $sudo pacman -S fish --noconfirm &&
            installOhMyFish
            exit
        }
        
        # 如果是Debian GNU/Linux系
        command -v apt-get > /dev/null && {
            $sudo apt-get -y update &&
            $sudo apt-get -y install curl fish &&
            installOhMyFish
            exit
        }
        
        # 如果是Fedora或CentOS8系统
        command -v dnf > /dev/null && {
            $sudo dnf -y update &&
            $sudo dnf -y install curl fish &&
            installOhMyFish
            exit
        }
        
        # 如果是CentOS8以下的系统
        command -v yum > /dev/null && { 
            $sudo yum -y update &&
            $sudo yum -y install curl fish &&
            installOhMyFish
            exit
        }

        # 如果是OpenSUSE系统
        command -v zypper > /dev/null && { 
            $sudo zypper update -y &&
            $sudo zypper install -y curl fish &&
            installOhMyFish
            exit
        }
        
        # 如果是AlpineLinux系统
        command -v apk > /dev/null && {
            $sudo apk update &&
            $sudo apk add curl fish &&
            installOhMyFish
            exit
        }
    elif [ "$osType" = "Darwin" ] ; then
        if command -v brew > /dev/null; then
            brew update
        else
            printf "\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        fi

        command -v curl > /dev/null || brew install curl
        command -v fish > /dev/null || brew install fish
        installOhMyFish
        exit
    fi
    
    //听天由命吧，试试看
    installOhMyFish
}

main
