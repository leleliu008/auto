#!/bin/sh


currentScriptDir="$(cd "$(dirname "$0")" || exit; pwd)"

[ "$(whoami)" != "root" ] && command -v sudo > /dev/null && sudo=sudo

Color_Red='\033[0;31m'          # Red
Color_Green='\033[0;32m'        # Green
Color_Yellow='\033[0;33m'       # Yellow
Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b" "$*"
}

echo() {
    msg "$*\n"
}

info() {
    msg "${Color_Purple}$*\n${Color_Off}"
}

success() {
    msg "${Color_Green}[✔] $*\n${Color_Off}"
}

warn() {
    msg "${Color_Yellow}🔥 $*\n${Color_Off}"
}

error() {
    msg "${Color_Red}[✘] $*\n${Color_Off}"
}

die() {
    msg "${Color_Red}[✘] $*\n${Color_Off}"
    exit 1
}

sed_in_place() {
    if command -v gsed > /dev/null ; then
        gsed -i "$1" "$2"
    elif command -v sed  > /dev/null ; then
        sed -i    "$1" "$2" 2> /dev/null ||
        sed -i "" "$1" "$2"
    else
        die "please install sed utility."
    fi
}

check_dependency() {
    command -v "$1" > /dev/null || PKG_LIST="$PKG_LIST $2"
}

check_dependencies() {
    echo "$@" | while read -r item
    do
        check_dependency "$item"
    done
}

install_dependencies_if_needed() {
    # Gentoo Linux
    if command -v emerge > /dev/null ; then
        check_dependencies "bash app-shells/bash\ncurl net-misc/curl\ngit dev-vcs/git\nvim app-editors/vim\nsed sys-apps/sed\ntar app-arch/tar\ngawk sys-apps/gawk\ngzip app-arch/gzip\nmake sys-devel/make\ncmake dev-util/cmake\ngo dev-lang/go\nninja dev-util/ninja\nctags dev-util/ctags\npython dev-lang/python"
        PKG_LIST=$(echo "$PKG_LIST" | sed 's/^ //g')
        if [ -n "$PKG_LIST" ] ; then
            $sudo emerge $PKG_LIST
        fi
    # macOS GNU/Linux
    elif command -v brew > /dev/null ; then
        check_dependencies "bash bash\ncurl curl\ngit git\nvim vim\nsed sed\ngawk gawk\ngzip gzip\nmake make\ncmake cmake\ngo go\nninja ninja\nctags ctags\npython3 python3\ntar gnu-tar"
        PKG_LIST=$(echo "$PKG_LIST" | sed 's/^ //g')
        if [ -n "$PKG_LIST" ] ; then
            brew install $PKG_LIST
        fi
    # ArchLinux、ManjaroLinux
    elif command -v pacman > /dev/null ; then
        check_dependencies "bash bash\ncurl curl\ngit git\nvim vim\nsed sed\ngawk gawk\ngzip gzip\nmake make\ncmake cmake\ntar tar\ngo go\ng++ gcc\nninja ninja\nctags ctags\npython3 python" 
        PKG_LIST=$(echo "$PKG_LIST" | sed 's/^ //g')
        if [ -n "$PKG_LIST" ] ; then
            $sudo pacman -Syyuu --noconfirm &&
            $sudo pacman -S     --noconfirm $PKG_LIST
        fi
    # AlpineLinux
    elif command -v apk > /dev/null ; then
        check_dependencies "bash bash\ncurl curl\ngit git\nvim vim\nsed sed\ngawk gawk\ngzip gzip\nmake make\ncmake cmake\ngo go\ng++ gcc\nninja ninja\nctags ctags\npython3 python3"
        PKG_LIST="$PKG_LIST python3-dev"
        PKG_LIST=$(echo "$PKG_LIST" | sed 's/^ //g')
        if [ -n "$PKG_LIST" ] ; then
            $sudo apk update &&
            $sudo apk add $PKG_LIST
        fi
    # Debian GNU/Linux系
    elif command -v apt-get > /dev/null ; then
        check_dependencies "bash bash\ncurl curl\ngit git\nvim vim\nsed sed\ngawk gawk\ngzip gzip\nmake make\ncmake cmake\ngo golang\ng++ g++\nninja ninja-build\nctags exuberant-ctags\npython3 python3"
        PKG_LIST="$PKG_LIST python3-dev"
        PKG_LIST=$(echo "$PKG_LIST" | sed 's/^ //g')
        if [ -n "$PKG_LIST" ] ; then
            $sudo apt-get -y update &&
            $sudo apt-get -y install $PKG_LIST
        fi
    # Fedora、CentOS8
    elif command -v dnf > /dev/null ; then
        check_dependencies "bash bash\ncurl curl\ngit git\nvim vim\nsed sed\ngawk gawk\ngzip gzip\nmake make\ncmake cmake\ngo golang\ng++ gcc-c++\nninja ninja-build\nctags ctags-etags\npython3 python3"
        PKG_LIST="$PKG_LIST python3-devel"
        PKG_LIST=$(echo "$PKG_LIST" | sed 's/^ //g')
        if [ -n "$PKG_LIST" ] ; then
            $sudo dnf -y update &&
            $sudo dnf -y install $PKG_LIST
        fi
    # RHEL CentOS 7、6
    elif command -v yum > /dev/null ; then
        check_dependencies "bash bash\ncurl curl\ngit git\nvim vim\nsed sed\ngawk gawk\ngzip gzip\nmake make\ncmake cmake\ngo golang\ng++ gcc-c++\nninja ninja-build\nctags ctags-etags\npython3 python36"
        PKG_LIST="$PKG_LIST python36-devel"
        PKG_LIST=$(echo "$PKG_LIST" | sed 's/^ //g')
        if [ -n "$PKG_LIST" ] ; then
            $sudo yum -y update &&
            $sudo yum -y install epel-release
            $sudo yum -y install $PKG_LIST
        fi
    # OpenSUSE
    elif command -v zypper > /dev/null ; then
        check_dependencies "bash bash\ncurl curl\ngit git\nvim vim\nsed sed\ngawk gawk\ngzip gzip\nmake make\ncmake cmake\ngo go\ng++ gcc-c++\nninja ninja\nctags ctags\npython3 python3"
        PKG_LIST="$PKG_LIST python3-devel"
        PKG_LIST=$(echo "$PKG_LIST" | sed 's/^ //g')
        if [ -n "$PKG_LIST" ] ; then
            $sudo zypper update  -y &&
            $sudo zypper install -y $PKG_LIST
        fi
    fi
}

install_vim_plug() {
    info "Installing vim-plug..."

    curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    if [ $? -eq 0 ] ; then
        success "vim-plug installed success."
    else
        die "vim-plug installed fialed."
    fi
}

compile_YCM() {
    info "Compiling YouCompleteMe..."
    $PYTHON install.py $@ --ninja || {
        info "ReCompiling YouCompleteMe..."
        $PYTHON install.py $@
    }
}

install_YCM() {
    VIM_PLUGIN_DIR="$HOME/.vim/bundle"
    YCM_DIR="$VIM_PLUGIN_DIR/YouCompleteMe"
     
    [ -d "$VIM_PLUGIN_DIR" ] || mkdir -p "$VIM_PLUGIN_DIR"
    [ -d "$YCM_DIR" ] && rm -rf "$YCM_DIR"
    
    export GO111MODULE=on
    export GOPROXY=https://goproxy.io
    export GOPATH=$YCM_DIR/go
        
    info "Installing YouCompleteMe..."
    git clone --recursive https://gitee.com/YouCompleteMe/YouCompleteMe.git "$YCM_DIR" &&
    cd "$YCM_DIR" || exit 1
    
    PYTHON=$(command -v python3) ||
    PYTHON=$(command -v python)  ||
    PYTHON=$(command -v python2) ||
    die  "we can't find python, so don't compile YouCompleteMe, you can comiple it by hand"
    
    OPTION_LIST="--clang-completer --ts-completer --go-completer"
    
    command -v java > /dev/null && {
        OPTION_LIST="$OPTION_LIST --java-completer"
        sed_in_place "s@download.eclipse.org@mirrors.ustc.edu.cn/eclipse@g" ./third_party/ycmd/build.py
    }
    
    if compile_YCM "$OPTION_LIST" ; then
        success "YouCompleteMe installed success."
    else
        die "YouCompleteMe installed failed! you can comiple it by hand yourself."
    fi
}

install_nvm() {
    info "Installing nvm..."
    
    if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash ; then
        export NVM_DIR="${HOME}/.nvm" &&
        . ~/.nvm/nvm.sh &&
        success "nvm installed success."
    else
        die "nvm installed failed."
    fi
}

install_nodejs() {
    info "Installing node.js v10.15.1"
    
    if nvm install v10.15.1 ; then
        success "node.js v10.15.1 installed success."
    else
        die "node.js v10.15.1 installed failed."
    fi
}

install_nodejs_if_needed() {
    command -v npm  > /dev/null || {
        command -v nvm > /dev/null || install_nvm
        install_nodejs
    }
    
    if [ "$(npm config get registry)" = "https://registry.npmjs.org/" ] ; then
        npm config set registry "https://registry.npm.taobao.org/"
    fi
}

update_vimrc() {
    VIMRC="$HOME/.vimrc"

    [ -f "$VIMRC" ] && {
        VIMRC_BAK="$VIMRC.$(date +%s).bak"
        mv "$VIMRC" "$VIMRC_BAK"
        warn "$VIMRC has been backup to $VIMRC_BAK"
    }
    
    cp "$currentScriptDir/vimrc-user" "$VIMRC"
     
    sed_in_place "s@/usr/local/bin/python3@$PYTHON@g" "$VIMRC"
     
    success "All Done. open vim and use :PlugInstall command to install plugins!"
}

main() {
    install_dependencies_if_needed &&
    install_nodejs_if_needed &&
    install_vim_plug &&
    install_YCM &&
    update_vimrc
}

main
