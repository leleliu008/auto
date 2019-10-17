#!/bin/sh

Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b\n" "$1"
}

info() {
    msg "${Color_Purple}[❉]${Color_Off} $1$2"
}

# 配置LinuxBrew的环境变量
writeLinuxBrewEnv() {
    printf "%s\n" "eval \$($(brew --prefix)/bin/brew shellenv)" >> "$1"
}

configLinuxBrewEnv() {
    info "ConfigLinuxBrewEnv..."

    [ -d ~/.linuxbrew ] && eval "$(~/.linuxbrew/bin/brew shellenv)"
    [ -d /home/linuxbrew/.linuxbrew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

    writeLinuxBrewEnv "$HOME/.bashrc"
    writeLinuxBrewEnv "$HOME/.zshrc"
}

installLinuxBrew() {
    info "Installing LinuxBrew..."
    printf "\n\n" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)" && configLinuxBrewEnv
}

installHomeBrew() {
    info "Installing HomeBrew..."
    printf "\n\n" | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

# 安装HomeBrew或者LinuxBrew
installBrew() {
    if [ "$(uname -s)" = "Darwin" ] ; then
        installHomeBrew
    else
        command -v apt-get > /dev/null && {
            sudo apt-get -y update &&
            sudo apt-get -y install build-essential curl file git &&
            installLinuxBrew
            exit
        }
        
        command -v yum > /dev/null && {
            [ -f /etc/os-release ] &&
            grep "fedora" /etc/os-release > /dev/null && 
            [ "$(rpm -E %fedora)" -gt 29 ] && 
            libxcryptCompat='libxcrypt-compat'
            
            sudo yum -y update &&
            sudo yum -y groupinstall 'Development Tools' &&
            sudo yum -y install curl file git "$libxcryptCompat" &&
            installLinuxBrew
            exit
        }
        
        printf "%s\n" "who are you ?"
        exit 1
    fi
}

main() {
    command -v brew > /dev/null && {
        brew update
        info "brew is already installed!"
        exit 0
    }
    
    [ "$(whoami)" = "root" ] && {
        info "don't run as root!"
        exit 1
    }
    
    installBrew
}

main
