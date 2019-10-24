#!/bin/sh

[ "$(whoami)" = "root" ] || sudo=$(command -v sudo)

osType=$(uname -s)

Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b\n" "$1"
}

info() {
    msg "${Color_Purple}[❉]${Color_Off} $1$2"
}

compatibleSed() {
    [ -z "$sed" ] && sed=$(command -v gsed)
    [ -z "$sed" ] && sed=$(command -v sed)
    "$sed" -i "$1" "$2"
}

installOhMyZsh() {
    info "installOhMyZsh..."

    scriptFileName="$(date +%Y%m%d%H%M%S).sh"
    [ -f "$scriptFileName" ] && rm "$scriptFileName"

    curl -fsSL -o "$scriptFileName" https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh || exit 1
    
    lineNumber=$(grep "exec zsh -l" -n "$scriptFileName" | awk -F: '{print $1}')
    
    compatibleSed "${lineNumber}d" "$scriptFileName"

    (sh "$scriptFileName" && rm "$scriptFileName") || exit 1
    
    pluginsDir=~/.oh-my-zsh/plugins
    
    if [ -d "$pluginsDir" ] ; then
        #这里不使用-C参数的因为是，CentOS里的git命令的版本比较低，没有此参数
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $pluginsDir/zsh-syntax-highlighting && \
        git clone https://github.com/zsh-users/zsh-autosuggestions.git $pluginsDir/zsh-autosuggestions  && \
        git clone https://github.com/zsh-users/zsh-completions.git $pluginsDir/zsh-completions && {
            #更新插件列表
            lineNumber=$(grep "^plugins=(" -n ~/.zshrc | awk -F: '{print $1}')
            plugins=$(grep "^plugins=(" -n ~/.zshrc | sed 's/.*plugins=(\(.*\)).*/\1/')
            plugins="plugins=(${plugins} zsh-syntax-highlighting zsh-autosuggestions zsh-completions)"
            
            compatibleSed "${lineNumber}c ${plugins}" ~/.zshrc

            lineNumbers=$(grep "compinit" -n ~/.zshrc | awk -F: '{print $1}')
            for lineNumber in $lineNumbers
            do
                compatibleSed "${lineNumber}d" ~/.zshrc
            done
            printf "autoload -U compinit && compinit\n" >> ~/.zshrc
            env zsh -l
        }
    fi
}

checkDependencies() {
    info "checkDependencies..."

    command -v curl > /dev/null || pkgNames="$pkgNames curl"
    command -v git  > /dev/null || pkgNames="$pkgNames git"
    command -v zsh  > /dev/null || pkgNames="$pkgNames zsh"
    command -v awk  > /dev/null || pkgNames="$pkgNames gawk"
    
    case "$osType" in
        Darwin) command -v gsed > /dev/null || pkgNames="$pkgNames gnu-sed" ;;
        *BSD)   command -v gsed > /dev/null || pkgNames="$pkgNames gsed" ;;
        *)      command -v sed  > /dev/null || pkgNames="$pkgNames sed"
    esac
}

installDependencies() {
    info "installDependencies $pkgNames"

    if [ "$osType" = "Linux" ] ; then
        # 如果是ArchLinux或ManjaroLinux系统
        command -v pacman > /dev/null && {
            $sudo pacman -Syyuu --noconfirm &&
            $sudo pacman -S     --noconfirm $@
            return 0
        }
        
        # 如果是Ubuntu或Debian GNU/Linux系统
        command -v apt-get > /dev/null && {
            $sudo apt-get -y update &&
            $sudo apt-get -y install $@
            return 0
        }
        
        # 如果是Fedora或CentOS8系统
        command -v dnf > /dev/null && {
            $sudo dnf -y update &&
            $sudo dnf -y install $@
            return 0
        }
        
        # 如果是CentOS8以下的系统
        command -v yum > /dev/null && { 
            $sudo yum -y update &&
            $sudo yum -y install $@
            return 0
        }

        # 如果是OpenSUSE系统
        command -v zypper > /dev/null && { 
            $sudo zypper update -y &&
            $sudo zypper install -y $@
            return 0
        }
        
        # 如果是AlpineLinux系统
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
    
    # FreeBSD
    command -v pkg > /dev/null && {
        $sudo pkg update &&
        $sudo pkg install -y $@
        return $?
    }
    
    # NetBSD、MirBSD
    command -v pkgin > /dev/null && {
        $sudo pkgin -y update &&
        $sudo pkgin -y install $@
        return $?
    }
    
    # OpenBSD
    command -v pkg_add > /dev/null && {
        $sudo pkg_add $@
        return $?
    }
}

main() {
    checkDependencies
    
    [ -z "$pkgNames" ] || installDependencies "$pkgNames"
    
    installOhMyZsh
}

main
