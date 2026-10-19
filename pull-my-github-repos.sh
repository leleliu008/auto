#!/bin/sh

set -ex

I=0

cd ~/github.com

while true
do
    I=$(($I + 1))
    f="my-github-repo-$I.json"

    curl -L -o "$f" "https://api.github.com/users/leleliu008/repos?page=$I"

    X="$(jq -r '.[].name' "$f")"

    [ -z "$X" ] && break

    printf '%s\n' "$X" | while read -r repoName
    do
        case $repoName in
            uppm-package-repository-*)
                [ -d "$repoName" ] || git clone "git@github.com:leleliu008/$repoName.git"
        esac
    done
done
