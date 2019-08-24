#!/bin/bash

currentScriptDir="$(cd $(dirname $0); pwd)"

Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan

Color_off='\033[0m'       # Text Reset

function msg() {
    printf '%b\n' "$1" >&2
}

function success() {
    msg "${Green}[✔]${Color_off} ${1}${2}"
}

function info() {
    msg "${Purple}[➭]${Color_off} ${1}${2}"
}

function warn() {
    msg "${Yellow}[⚠]${Color_off} ${1}${2}"
}

function error() {
    msg "${Red}[✘]${Color_off} ${1}${2}"
}

[ `whoami` == "root" ] || role=sudo

function installHomeBrewIfNeeded() {
    command -v brew &> /dev/null
    if [ $? -eq 0 ] ; then
        brew update
    else
        echo -e "\n" | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
}

function installViaHomeBrew() {
    command -v "$1" &> /dev/null || brew install "$2"
}

function installViaApt() {
    command -v "$1" &> /dev/null || $role apt-get -y install "$2"
}

function installViaYum() {
    command -v "$1" &> /dev/null || $role yum -y install "$2"
}

function installViaDnf() {
    command -v "$1" &> /dev/null || $role dnf -y install "$2"
}

function installViaZypper() {
    command -v "$1" &> /dev/null || $role zypper install -y "$2"
}

function installViaApk() {
    command -v "$1" &> /dev/null || $role apk add "$2"
}

function installViaPacman() {
    command -v "$1" &> /dev/null || $role pacman -S --noconfirm "$2"
}

function installVundle() {
    local pluginDir="${HOME}/.vim/bundle"
    local vundleDir="${pluginDir}/Vundle.vim"
    
    [ -d "$pluginDir" ] || mkdir -p "$pluginDir"
    [ -d "$vundleDir" ] && rm -rf "$vundleDir"
    
    info "installing Vundle..." && \
    git clone http://github.com/VundleVim/Vundle.vim.git "$vundleDir" && \
    success "installed Vundle"
}

function installYouCompleteMe() {
    local pluginDir="${HOME}/.vim/bundle"
    local youCompleteMeDir="${pluginDir}/youcompleteme"
    
    [ -d "$pluginDir" ] || mkdir -p "$pluginDir"
    [ -d "$youCompleteMeDir" ] && rm -rf "$youCompleteMeDir"
    
    info "installing YouCompleteMe..."
    git clone https://gitee.com/mirrors/youcompleteme.git "$youCompleteMeDir" && \
    cd "$youCompleteMeDir" && \
    git submodule update --init && {
        if [ "$(uname -s)" == "Darwin" ] ; then
            sed -i ""  "s@go.googlesource.com@github.com/golang@g" ./third_party/ycmd/.gitmodules
        else
            sed -i "s@go.googlesource.com@github.com/golang@g" ./third_party/ycmd/.gitmodules
        fi
    } && {
        export GO111MODULE=on
        export GOPROXY=https://goproxy.io
    } && git submodule update --init --recursive && \
    success "installed YouCompleteMe"
}

function installNodeJSIfNeeded() {
    (command -v node &> /dev/null && command -v npm &> /dev/null) || {
        command -v nvm &> /dev/null || {
            info "installing nvm..." && \
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash && \
            export NVM_DIR="${HOME}/.nvm" && \
            source "$NVM_DIR/nvm.sh" && \
            success "installed nvm"
        }
        
        info "installing node.js v10.15.1" && \
        nvm install v10.15.1 && \
        success "installed node.js v10.15.1"
    }
    
    if [ "$(npm config get registry)" == "https://registry.npmjs.org" ] ; then
        npm config set registry "https://registry.npm.taobao.org/"
    fi
}

function updateVimrcOfCurrentUser() {
    [ -f ~/.vimrc ] && {
        mv ~/.vimrc ~/.vimrc.bak
        backup=true
    }
    
    cp "$currentScriptDir/vimrc-user" ~/.vimrc
    cp "$currentScriptDir/.tern-project" ~

    success "---------------------------------------------------"
    [ "$backup" == "true" ] && {
        success "~/.vimrc config file is updated! "
        success "your ~/.vimrc config file is bak to ~/.vimrc.bak"
    }
    success "cd ~/.vim/bundle/youcompleteme to go on install with command python install.py"
    success "open vim and use :BundleInstall to install plugins!"
    success "---------------------------------------------------"
}

function main() {
    local osType="$(uname -s)"
    echo "osType=$osType"

    if [ "$osType" = "Darwin" ] ; then
        installHomeBrewIfNeeded && \
        installViaHomeBrew vim vim && \
        installViaHomeBrew curl curl && \
        installViaHomeBrew go go && \
        installViaHomeBrew ctags ctags && \
        installVundle && \
        installYouCompleteMe && \
        installNodeJSIfNeeded && \
        updateVimrcOfCurrentUser
    elif [ "$osType" = "Linux" ] ; then
        #ArchLinux ManjaroLinux
        command -v pacman &> /dev/null && {
            $role pacman -Syyuu --noconfirm && \
            installViaPacman git git && \
            installViaPacman curl curl && \
            installViaPacman vim vim && \
            installViaPacman go go && \
            installViaPacman sed sed && \
            installViaPacman ctags ctags && \
            installVundle && \
            installYouCompleteMe && \
            installNodeJSIfNeeded && \
            updateVimrcOfCurrentUser
            exit
        }
        
        #AlpineLinux
        command -v apk &> /dev/null && {
            $role apk update && \
            installViaApk git git && \
            installViaApk curl curl && \
            installViaApk vim vim && \
            installViaApk go go && \
            installViaApk sed sed && \
            installViaApk ctags ctags && \
            installVundle && \
            installYouCompleteMe && \
            installNodeJSIfNeeded && \
            updateVimrcOfCurrentUser
            exit
        }
        
        #Debian GNU/Linux系
        command -v apt-get &> /dev/null && {
            $role apt-get -y update && \
            installViaApt git git && \
            installViaApt curl curl && \
            installViaApt vim vim && \
            installViaApt go golang && \
            installViaApt sed sed && \
            installViaApt ctags exuberant-ctags && \
            installVundle && \
            installYouCompleteMe && \
            installNodeJSIfNeeded && \
            updateVimrcOfCurrentUser
            exit
        }
        
        #Fedora CnetOS8
        command -v dnf &> /dev/null && {
            $role dnf -y update && \
            installViaDnf git git && \
            installViaDnf curl curl && \
            installViaDnf vim vim && \
            installViaDnf go golang && \
            installViaDnf sed sed && \
            installViaDnf ctags ctags-etags && \
            installVundle && \
            installYouCompleteMe && \
            installNodeJSIfNeeded && \
            updateVimrcOfCurrentUser
            exit
        }
        
        #RHEL CentOS8以下
        command -v yum &> /dev/null && {
            $role yum -y update && \
            installViaYum git git && \
            installViaYum curl curl && \
            installViaYum vim vim && \
            installViaYum go golang && \
            installViaYum sed sed && \
            installViaYum ctags ctags-etags && \
            installVundle && \
            installYouCompleteMe && \
            installNodeJSIfNeeded && \
            updateVimrcOfCurrentUser
            exit
        }
        
        #OpenSUSE
        command -v zypper &> /dev/null && \
        $role zypper update -y && \
        installViaZypper git git && \
        installViaZypper curl curl && \
        installViaZypper vim vim && \
        installViaZypper go golang && \
        installViaZypper sed sed && \
        installViaZypper ctags ctags && \
        installVundle && \
        installYouCompleteMe && \
        installNodeJSIfNeeded && \
        updateVimrcOfCurrentUser && \
        exit
    fi
}

main
