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
    printf "\n\n" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
}

installHomeBrew() {
    info "Installing HomeBrew..."
    printf "\n\n" | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

checkDependencies() {
    info "checkDependencies..."

    command -v curl  > /dev/null || pkgNames="curl"
    command -v git   > /dev/null || pkgNames="$pkgNames git"
    command -v file  > /dev/null || pkgNames="$pkgNames file"
    command -v which > /dev/null || pkgNames="$pkgNames which"
    command -v tar   > /dev/null || pkgNames="$pkgNames tar"
    command -v gzip  > /dev/null || pkgNames="$pkgNames gzip"
    command -v gcc   > /dev/null || pkgNames="$pkgNames gcc"
}

installDependencies() {
    info "installDependencies $pkgNames"

    command -v apt-get > /dev/null && {
        sudo apt-get -y update &&
        sudo apt-get -y install $@ &&
        return $?
    }
    
    command -v dnf > /dev/null && {
        sudo dnf -y update &&
        sudo dnf -y install $@ &&
        return $?
    }
        
    command -v yum > /dev/null && {
        sudo yum -y update &&
        sudo yum -y install $@ &&
        return $?
    }
    
    command -v zypper > /dev/null && {
        sudo zypper update -y &&
        sudo zypper install -y $@ &&
        return $?
    }
    
    command -v pacman > /dev/null && {
        sudo pacman -Syyuu --noconfirm &&
        sudo pacman -S     --noconfirm $@ &&
        return $?
    }

    info "not find a package manager to install $pkgNames"
    return 1
}

# 安装HomeBrew或者LinuxBrew
installBrew() {
    if [ "$(uname -s)" = "Darwin" ] ; then
        installHomeBrew
    else
        checkDependencies
        [ -z "$pkgNames" ] || installDependencies "$pkgNames"
        installLinuxBrew &&
        configLinuxBrewEnv &&
        replaceMainSourceIfNeeded &&
        brew update
    fi
}

replaceMainSourceIfNeeded() {
    [ "$(git -C "$(brew --repo)" remote get-url origin)" = "https://github.com/Homebrew/brew" ] &&
    git -C "$(brew --repo)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
}

main() {
    command -v brew > /dev/null && {
        replaceMainSourceIfNeeded
        brew update
        info "brew is already installed!"
        exit 0
    }
    
    [ "$(whoami)" = "root" ] && {
        info "don't run as root!"
        exit 1
    }

    [ -z "$(command -v sudo)" ] && {
        info "sudo is not installed and config."
        exit 1
    }
    
    installBrew
}

main
