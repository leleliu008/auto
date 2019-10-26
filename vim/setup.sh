#!/bin/sh

export GO111MODULE=on
export GOPROXY=https://goproxy.io

currentScriptDir="$(cd "$(dirname "$0")" || exit; pwd)"
osType="$(uname -s)"
[ "$(whoami)" = "root" ] || sudo=sudo

Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Purple='\033[0;35m'       # Purple

Color_off='\033[0m'       # Text Reset

msg() {
    printf '%b\n' "$1" >&2
}

success() {
    msg "${Green}[✔]${Color_off} ${1}${2}"
}

info() {
    msg "${Purple}[❉]${Color_off} ${1}${2}"
}

warn() {
    msg "${Yellow}[⌘]${Color_off} ${1}${2}"
}

error() {
    msg "${Red}[✘]${Color_off} ${1}${2}"
}

installHomeBrewIfNeeded() {
    if command -v brew > /dev/null ; then
        brew update
    else
        printf "\n\n" | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
}

checkDependency() {
    command -v "$1" > /dev/null || pkgNames="$pkgNames $2"
}

checkDependencies() {
    checkDependency bash bash
    checkDependency curl curl
    checkDependency git git
    checkDependency vim vim
    checkDependency sed sed
    checkDependency gawk gawk
    checkDependency gzip gzip
    checkDependency make make
    checkDependency cmake cmake

    if [ "$osType" = "Darwin" ] ; then
        checkDependency go go
        checkDependency ninja ninja
        checkDependency ctags ctags
        checkDependency python3 python3
        checkDependency tar gnu-tar
    else
        checkDependency tar tar

        command -v pacman > /dev/null && {
            checkDependency go go
            checkDependency g++ gcc
            checkDependency ninja ninja
            checkDependency ctags ctags
            checkDependency python3 python
            return 0
        }
        
        command -v apk > /dev/null && {
            checkDependency go go
            checkDependency g++ gcc
            checkDependency ninja ninja
            checkDependency ctags ctags
            checkDependency python3 python3
            pkgNames="$pkgNames python3-dev"
            return 0
        }
        
        command -v apt-get > /dev/null && {
            checkDependency go golang
            checkDependency g++ g++
            checkDependency ninja ninja-build
            checkDependency ctags exuberant-ctags
            checkDependency python3 python3 
            pkgNames="$pkgNames python3-dev"
            return 0
        }
        
        command -v dnf > /dev/null && {
            checkDependency go golang
            checkDependency g++ gcc-c++
            checkDependency ninja ninja-build
            checkDependency ctags ctags-etags
            checkDependency python3 python3 
            pkgNames="$pkgNames python3-devel"
            return 0
        }
        
        command -v yum > /dev/null && {
            checkDependency go golang
            checkDependency g++ gcc-c++
            checkDependency ninja ninja-build
            checkDependency ctags ctags-etags
            checkDependency python3 python36 
            pkgNames="$pkgNames python36-devel"
            return 0
        }
        
        command -v zypper > /dev/null && {
            checkDependency go go
            checkDependency g++ gcc-c++
            checkDependency ninja ninja
            checkDependency ctags ctags
            checkDependency python3 python3
            pkgNames="$pkgNames python3-devel"
        }
    fi
}

installDependencies() {
    if [ "$osType" = "Darwin" ] ; then
        installHomeBrewIfNeeded &&
        brew install $@
        return $?
    elif [ "$osType" = "Linux" ] ; then
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
        
        # Debian GNU/Linux系
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
            $sudo yum -y install epel-release
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
}

installVimPlug() {
    info "Installing vim-plug..." &&
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim &&
    success "Installed vim-plug"
}

compileYouCompleteMe() {
    info "Compiling YouCompleteMe..."
    $python install.py $@ --ninja || {
        info "ReCompiling YouCompleteMe..."
        $python install.py $@
    }
}

installYouCompleteMe() {
    pluginDir="${HOME}/.vim/bundle"
    youCompleteMeDir="${pluginDir}/YouCompleteMe"
    
    [ -d "$pluginDir" ] || mkdir -p "$pluginDir"
    [ -d "$youCompleteMeDir" ] && rm -rf "$youCompleteMeDir"
    
    export GOPATH=$youCompleteMeDir/go
        
    info "Installing YouCompleteMe..."
    git clone --recursive https://gitee.com/YouCompleteMe/YouCompleteMe.git "$youCompleteMeDir" &&
    cd "$youCompleteMeDir" && {
        python="$(command -v python3)"
        [ -z "$python" ] && python="$(command -v python)"
        if [ -z "$python" ] ; then
            warn "we can't find python, so don't compile installYouCompleteMe, you can comiple it by hand"
        else
            options="--clang-completer --ts-completer --go-completer"
            command -v java > /dev/null && options="$options --java-completer"

            if compileYouCompleteMe "$options" ; then
                success "installed YouCompleteMe"
            else
                warn "compiled failed!you can comiple it by hand"
            fi
        fi
    }
}

installNodeJSIfNeeded() {
    (command -v node > /dev/null && command -v npm > /dev/null) || {
        command -v nvm > /dev/null || {
            info "Installing nvm..." &&
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash &&
            export NVM_DIR="${HOME}/.nvm" &&
            . ~/.nvm/nvm.sh &&
            success "Installed nvm"
        }
        
        info "Installing node.js v10.15.1" &&
        nvm install v10.15.1 &&
        success "Installed node.js v10.15.1"
    }
    
    if [ "$(npm config get registry)" = "https://registry.npmjs.org/" ] ; then
        npm config set registry "https://registry.npm.taobao.org/"
    fi
}

updateVimrcOfCurrentUser() {
    myVIMRC="${HOME}/.vimrc"
    [ -f "$myVIMRC" ] && {
        if [ -f "${myVIMRC}.bak" ] ; then
            for i in $(seq 1 1000)
            do
                if [ -f "${myVIMRC}${i}.bak" ] ; then
                    continue
                else
                    backup="${myVIMRC}${i}.bak"
                    break
                fi
            done
        fi
        [ -z "$backup" ] && backup="${myVIMRC}.bak"
        mv "$myVIMRC" "$backup"
    }
    
    cp "$currentScriptDir/vimrc-user" "$myVIMRC"
    cp "$currentScriptDir/.tern-project" "${HOME}"
    
    [ -z "$python" ] || {
        if [ "$(uname -s)" = "Darwin" ] ; then
            sed -i ""  "s@/usr/local/bin/python3@${python}@g" "$myVIMRC"
        else
            sed -i "s@/usr/local/bin/python3@${python}@g" "$myVIMRC"
        fi
    }
    
    success "---------------------------------------------------"
    [ -z "$backup" ] || {
        success "$HOME/.vimrc config file is updated!"
        success "your $HOME/.vimrc config file is bak to $backup"
    }
    success "open vim and use :BundleInstall to install plugins!"
    success "---------------------------------------------------"
}

main() {
    checkDependencies
    
    [ -z "$pkgNames" ] || installDependencies "$pkgNames"
    
    installVimPlug &&
    installNodeJSIfNeeded &&
    installYouCompleteMe &&
    updateVimrcOfCurrentUser
}

main
