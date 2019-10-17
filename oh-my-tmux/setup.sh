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

installOhMyTmux() {
    [ -f ~/.tmux.conf ] && mv ~/.tmux.conf ~/.tmux.conf.bak
    curl -L -o ~/.tmux.conf https://raw.githubusercontent.com/gpakosz/.tmux/master/.tmux.conf
    curl -L -o ~/.tmux.conf.local https://raw.githubusercontent.com/gpakosz/.tmux/master/.tmux.conf.local
}

checkDependencies() {
    info "checkDependencies..."
    command -v curl > /dev/null || pkgNames="curl"
    command -v tmux > /dev/null || pkgNames="$pkgNames tmux"
}

installDependencies() {
    info "installDependencies $pkgNames"

    if [ "$osType" = "Linux" ] ; then
        # ArchLinux、ManjaroLinux
        command -v pacman > /dev/null && {
            $sudo pacman -Syyuu --noconfirm &&
            $sudo pacman -S     --noconfirm $@
            return 0
        }
        
        # Debian GNU/Linux系
        command -v apt-get > /dev/null && {
            $sudo apt-get -y update &&
            $sudo apt-get -y install $@
            return 0
        }
        
        # Fedora、CentOS8
        command -v dnf > /dev/null && {
            $sudo dnf -y update &&
            $sudo dnf -y install $@
            return 0
        }
        
        # CentOS7、6
        command -v yum > /dev/null && { 
            $sudo yum -y update &&
            $sudo yum -y install $@
            return 0
        }

        # OpenSUSE
        command -v zypper > /dev/null && { 
            $sudo zypper update -y &&
            $sudo zypper install -y $@
            return 0
        }
        
        # AlpineLinux
        command -v apk > /dev/null && {
            $sudo apk update &&
            $sudo apk add $@
            return 0
        }
    elif [ "$osType" = "Darwin" ] ; then
        if command -v brew > /dev/null ; then
            brew update
        else
            printf "\n\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        fi
        brew install $@
    fi
}

main() {
    checkDependencies
    [ -z "$pkgNames" ] || installDependencies "$pkgNames"
    installOhMyTmux
}

main
