#!/bin/sh

osType=$(uname -s)
[ "$(whoami)" = "root" ] || sudo=sudo

# 在Mac OSX上安装HomeBrew
installHomeBrewIfNeeded() {
    if command -v brew > /dev/null ; then
        brew update
    else
        printf "\n\n" | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
}

# 安装额外的一些扩展支持
installBashCompletionExt() {
    if [ "$osType" = "Darwin" ] ; then
        str=/usr/local/etc/bash_completion.d
    else
        str=/etc/bash_completion.d
    fi
    cd "$str" || exit 1
    $sudo curl -LO https://raw.github.com/git/git/master/contrib/completion/git-completion.bash
}

writeEnv() {
    if [ "$osType" = "Darwin" ] ; then
        str=/usr/local/etc/bash_completion
    else
        str=/usr/share/bash-completion/bash_completion
    fi
    $sudo printf "%s\n" "[ -f $str ] && . $str" >> /etc/profile
}

main() {
    if [ "$osType" = "Darwin" ] ; then
        installHomeBrewIfNeeded &&
        brew install curl bash-completion &&
        writeEnv &&
        installBashCompletionExt
    elif [ "$osType" = "Linux" ] ; then
        command -v apt-get > /dev/null && {
            $sudo apt-get -y update &&
            $sudo apt-get -y install curl bash-completion &&
            writeEnv &&
            installBashCompletionExt
            exit $?
        }
        
        command -v dnf > /dev/null && {
            $sudo dnf -y update &&
            $sudo dnf -y install curl bash-completion &&
            writeEnv &&
            installBashCompletionExt
            exit $?
        }
        
        command -v yum > /dev/null && {
            $sudo yum -y update &&
            $sudo yum -y install curl bash-completion &&
            writeEnv &&
            installBashCompletionExt
            exit $?
        }
        
        command -v zypper > /dev/null && {
            $sudo zypper update  -y &&
            $sudo zypper install -y curl bash-completion &&
            writeEnv &&
            installBashCompletionExt
            exit $?
        }
        
        command -v pacman > /dev/null && {
            $sudo pacman -Syyuu --noconfirm &&
            $sudo zypper -S     --noconfirm  curl bash-completion &&
            writeEnv &&
            installBashCompletionExt
            exit $?
        }
        
        command -v apk > /dev/null && {
            $sudo apk update &&
            $sudo apk add curl bash-completion &&
            writeEnv &&
            installBashCompletionExt
            exit $?
        }
    fi
}

main
