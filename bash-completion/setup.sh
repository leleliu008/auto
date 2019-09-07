#!/bin/bash

[ `whoami` == "root" ] || role=sudo

# 在Mac OSX上安装HomeBrew
function installHomeBrewIfNeeded() {
    command -v brew &> /dev/null
    if [ $? -eq 0 ] ; then
        brew update
    else
        echo -e "\n" | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
}

# 安装额外的一些扩展支持
function installBashCompletionExt() {
    $role curl -LO https://raw.github.com/git/git/master/contrib/completion/git-completion.bash
}

function main() {
    local osType=`uname -s`
    
    if [ "$osType" == "Darwin" ] ; then
        installHomeBrewIfNeeded && \
        command -v curl &> /dev/null || brew install curl
        brew install bash-completion 
        $role echo "[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion" >> /etc/profile
        cd /usr/local/etc/bash_completion.d
        installBashCompletionExt
    elif [ "$osType" == "Linux" ] ; then
        command -v apt-get &> /dev/null && {
            $role apt-get -y update
            $role apt-get -y install curl bash-completion
            $role echo "[ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion" >> /etc/profile
            cd /etc/bash_completion.d
            installBashCompletionExt
            exit $?
        }
        
        command -v dnf &> /dev/null && {
            $role dnf -y update
            $role dnf -y install curl bash-completion
            $role echo "[ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion" >> /etc/profile
            cd /etc/bash_completion.d
            installBashCompletionExt
            exit $?
        }
        
        command -v yum &> /dev/null && {
            $role yum -y update
            $role yum -y install curl bash-completion
            $role echo "[ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion" >> /etc/profile
            cd /etc/bash_completion.d
            installBashCompletionExt
            exit $?
        }
        
        command -v zypper &> /dev/null && {
            $role zypper update -y
            $role zypperinstall -y curl bash-completion
            $role echo "[ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion" >> /etc/profile
            cd /etc/bash_completion.d
            installBashCompletionExt
            exit $?
        }
    fi
}

main
