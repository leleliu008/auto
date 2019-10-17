#!/bin/sh

Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b\n" "$1"
}

info() {
    msg "${Color_Purple}[❉]${Color_Off} $1$2"
}

installOhMyFish() {
    info "Installing oh-my-fish..."
    curl -L https://get.oh-my.fish | fish
}

checkDependencies() {
    info "CheckDependencies"
    command -v curl  > /dev/null || pkgNames="curl"
    command -v git   > /dev/null || pkgNames="$pkgNames git"
    command -v fish  > /dev/null || pkgNames="$pkgNames fish"
    command -v which > /dev/null || pkgNames="$pkgNames which"
}

installDependencies() {
    info "InstallDependencies $pkgNames"

    sudo=$(command -v sudo 2> /dev/null)
    osType=$(uname -s)

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
            (command -v fish > /dev/null || $sudo yum -y install epel-release) &&
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
        if command -v brew > /dev/null; then
            brew update
        else
            printf "\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        fi

        brew install $@
        return 0
    fi
}

main() {
    checkDependencies

    [ -z "$pkgNames" ] || installDependencies "$pkgNames"

    installOhMyFish
}

main
