#!/bin/sh

[ "$(whoami)" = "root" ] || sudo=sudo
osType=$(uname -s)

Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b\n" "$1"
}

info() {
    msg "${Color_Purple}[❉]${Color_Off} $1$2"
}

installOrUpdateHomeBrew() {
    if command -v brew > /dev/null ; then
        info "Updating HomeBrew..."
        brew update
    else
        info "Installing HomeBrew..."
        printf "\n\n" | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
}

checkDependencies() {
    info "Checking Dependencies..."
    command -v curl > /dev/null || pkgNames="curl"
    command -v bash > /dev/null || pkgNames="$pkgNames bash"
}

installDependencies() {
    info "Installing Dependencies $pkgNames"

    if [ "$osType" = "Darwin" ] ; then
        installOrUpdateHomeBrew && 
        brew install $@
    elif [ "$osType" = "Linux" ] ; then
        if [ "$(uname -o 2> /dev/null)" = "Android" ] ; then
            pkg install -y $@
        else
            # ArchLinux、ManjaroLinux
            command -v pacman > /dev/null && {
                $sudo pacman -Syyuu --noconfirm &&
                $sudo pacman -S     --noconfirm $@
                return $?
            }
            
            # AlpineLinux
            command -v apk > /dev/null && {
                $sudo apk update && 
                $sudo apk add $@
                return $?
            }
            
            # Debian GNU/LInux系
            command -v apt-get > /dev/null && {
                $sudo apt-get -y update &&
                $sudo apt-get -y install $@
                return $?
            }
            
            # Fedora、CentOS8
            command -v dnf > /dev/null && {
                $sudo dnf -y update &&
                $sudo dnf -y install $@
                return $?
            }
            
            # RHEL CentOS 7、6
            command -v yum > /dev/null && {
                $sudo yum -y update &&
                $sudo yum -y install $@
                return $?
            }
            
            # OpenSUSE
            command -v zypper > /dev/null && {
                $sudo zypper update  -y &&
                $sudo zypper install -y $@
                return $?
            }
        fi
    fi
}

installNVM() {
    info "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
}

changeNPMRegistryToChineseMirrorIfPossible() {
    command -v npm > /dev/null || return 0
    if [ "$(npm config get registry)" = "https://registry.npmjs.org/" ] ; then
        npm config set registry "https://registry.npm.taobao.org/" &&
        info "change npm registry to https://registry.npm.taobao.org/"
    fi
}

configEnv() {
    str="export NVM_DIR=~/.nvm && source \"\$NVM_DIR/nvm.sh\""
    printf "%s\n" "$str" >> ~/.bashrc
    printf "%s\n" "$str" >> ~/.bash_profile
    printf "%s\n" "$str" >> ~/.zshrc
}

main() {
    command -v nvm > /dev/null && {
        changeNPMRegistryToChineseMirrorIfPossible
        info "nvm already installed!"
        exit
    }
    
    checkDependencies
    ([ -z "$pkgNames" ] || installDependencies "$pkgNames") && installNVM && configEnv
}

main
