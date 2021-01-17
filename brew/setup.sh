#!/bin/sh

Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b\n" "$1"
}

info() {
    msg "${Color_Purple}[❉]${Color_Off} $1$2"
}

sudo() {
    if [ "$(whoami)" = 'root' ] ; then
        $@
    else
        command sudo $@
    fi
}

install_dependencies_if_needed() {
    for item in $@
    do
        command -v "$item" > /dev/null && continue
        install_dependencies "$item"
    done
}

install_dependencies() {
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

    info "not find a package manager to install $@"
    return 1
}

install_homebrew_on_macos() {
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_homebrew_on_linux() {
    install_dependencies_if_needed git curl &&
    install -d /home/linuxbrew/.linuxbrew/bin &&
    git clone https://github.com/Homebrew/brew /home/linuxbrew/.linuxbrew/Homebrew &&
    ln -sf /home/linuxbrew/.linuxbrew/Homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin &&
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv) && {        
        for item in .profile .bashrc .zshrc
        do
            printf "%s\n" "eval \$($(brew --prefix)/bin/brew shellenv)" >> "$HOME/$item" || return 1
        done
    } && {
        if [ -z "$SHELL" ] ; then
            if command -v zsh > /dev/null ; then
                SHELL=zsh
            elif command -v bash > /dev/null ; then
                SHELL=bash
            else
                SHELL=sh
            fi
        fi
        exec "$SHELL"
    }
}

install_homebrew() {
    case "$(uname -s)" in
        Darwin) install_homebrew_on_macos ;;
        Linux)  install_homebrew_on_linux ;;
        *)      info "HomeBrew only support macOS and Linux."
    esac
}

main() {
    if command -v brew > /dev/null ; then
        echo "Homebrew already installed."
    else
        echo "installing Homebrew."
        install_homebrew || return 1
    fi

    if [ "$(git -C "$(brew --repo)" remote get-url origin)" = "https://github.com/Homebrew/brew" ] ; then
            git -C "$(brew --repo)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
    fi
}

main
