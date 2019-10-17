#!/bin/sh

url=https://github.com/Microsoft/vcpkg.git
destDir=/usr/local/opt/vcpkg
sudo=$(command -v sudo 2> /dev/null)
osType=$(uname -s)

Color_Red='\033[0;31m'          # Red
Color_Green='\033[0;32m'        # Green
Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b\n" "$1"
}

info() {
    msg "${Color_Purple}[❉]${Color_Off} $1$2"
}

success() {
    msg "${Color_Green}[✔]${Color_Off} $1$2"
}

error() {
    msg "${Color_Red}[✘]${Color_Off} $1$2"
    exit 1
}

install_macOS_SDK_headers_IfNeeded() {
    [ -d /usr/include ] || $sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /
}

checkDependencies() {
    info "checkDependencies..."

    command -v curl  > /dev/null || pkgNames="$pkgNames curl"
    command -v git   > /dev/null || pkgNames="$pkgNames git"
    command -v unzip > /dev/null || pkgNames="$pkgNames unzip"
    command -v gzip  > /dev/null || pkgNames="$pkgNames gzip"

    if [ "$osType" = "Drawin" ] ; then
        install_macOS_SDK_headers_IfNeeded
        command -v sed   > /dev/null || pkgNames="$pkgNames gnu-sed"
        command -v tar   > /dev/null || pkgNames="$pkgNames gnu-tar"
        command -v g++-9 > /dev/null || pkgNames="$pkgNames gcc"
    else
        command -v sed   > /dev/null || pkgNames="$pkgNames sed"
        command -v tar   > /dev/null || pkgNames="$pkgNames tar"

        if ( command -v dnf     > /dev/null ||
             command -v yum     > /dev/null ||
             command -v zypper  > /dev/null ) ; then
             command -v g++     > /dev/null || pkgNames="$pkgNames gcc gcc-c++"
        elif command -v apt-get > /dev/null ; then
             command -v g++     > /dev/null || pkgNames="$pkgNames gcc g++"
        else
             command -v g++     > /dev/null || pkgNames="$pkgNames gcc"
        fi
    fi
}

installDependencies() {
    info "installDependencies $pkgNames"

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
            printf "\n\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        fi

        brew install $@
        
        return 0
    fi
}


link() {
    linkedDir=/usr/local/bin
    if [ -d "$linkedDir" ] ; then
        if [ -w "$linkedDir" ] ; then
            ln -sf "$destDir/vcpkg" "$linkedDir/vcpkg"
        else
            sudo ln -sf "$destDir/vcpkg" "$linkedDir/vcpkg" &&
            sudo chown "$(whoami)" "$linkedDir/vcpkg"
        fi
    else
        $sudo install -d -o "$(whoami)" "$linkedDir" &&
        ln -sf "$destDir/vcpkg" "$linkedDir/vcpkg"
    fi
}

main() {
    if [ -d "$destDir" ] ; then
        if [ -d "$destDir/.git" ] ; then
            checkDependencies &&
            ([ -z "$pkgNames" ] || installDependencies "$pkgNames") &&
            cd "$destDir" &&
            info "Updateing vcpk..." &&
            git pull &&
            info "Reinstalling vcpkg..." &&
            ./bootstrap-vcpkg.sh &&
            link &&
            success "Done!"
        else
            error "$destDir already exsit, but not a git repo."
        fi
    else
        checkDependencies &&
        ([ -z "$pkgNames" ] || installDependencies "$pkgNames") &&
        $sudo install -d -o "$(whoami)" "$destDir" &&
        info "Downloading vcpk..." &&
        git clone "$url" "$destDir" &&
        cd "$destDir" &&
        info "Installing vcpkg..." &&
        ./bootstrap-vcpkg.sh &&
        link &&
        success "Done!"
    fi
}

main
