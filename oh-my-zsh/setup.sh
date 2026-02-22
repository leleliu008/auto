#!/bin/sh

set -ex

SESSION_DIR="$(mktemp -d)"

cd "$SESSION_DIR"

curl -L -o oh-my-zsh-installer.sh https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh

gsed -i '/exec zsh -l/d' oh-my-zsh-installer.sh

sh oh-my-zsh-installer.sh

# https://draculatheme.com/zsh
git clone --depth=1 https://github.com/dracula/zsh dracula-zsh-theme

mv dracula-zsh-theme/dracula.zsh-theme ~/.oh-my-zsh/themes/dracula.zsh-theme
mv dracula-zsh-theme/lib               ~/.oh-my-zsh/themes/

git -C ~/.oh-my-zsh/plugins clone https://github.com/zsh-users/zsh-syntax-highlighting
git -C ~/.oh-my-zsh/plugins clone https://github.com/zsh-users/zsh-autosuggestions
git -C ~/.oh-my-zsh/plugins clone https://github.com/zsh-users/zsh-completions

gsed -i '/plugins=(/s|)| zsh-syntax-highlighting zsh-autosuggestions zsh-completions)|' ~/.zshrc
gsed -i '/compinit/d'  ~/.zshrc
gsed -i '/ZSH_THEME=/c ZSH_THEME="dracula"' ~/.zshrc
printf "autoload -U compinit && compinit\n" >> ~/.zshrc

env zsh -l
