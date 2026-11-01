#!/bin/sh

set -ex

curl -L -o d2.json https://api.github.com/repos/d2lang/d2/releases/latest

VERSION="$(jq -r .tag_name d2.json)"
VERSION="${VERSION#v}"

JSON="$PWD/d2.json"

for OSNAME in linux macos
do
    for OSARCH in x86_64 arm64
    do
        case $OSNAME in
            macos)
                DIRS="$(find ~/github.com -maxdepth 1 -mindepth 1 -type d -name "uppm-package-repository-macos-*-$OSARCH" -printf '%P\n')"
                ;;
            linux)
                if [ "$OSARCH" = arm64 ] ; then
                    DIRS="uppm-package-repository-linux-aarch64"
                else
                    DIRS="uppm-package-repository-linux-$OSARCH"
                fi
                ;;
        esac

        if [ "$OSARCH" = x86_64 ] ; then
            OSARCH=amd64
        fi

        for d in $DIRS
        do
            printf '\n\n'

            cd "$HOME/github.com/$d/formula"

            git checkout d2.yml
            git pull

            XX="$(jq -r ".assets[] | select(.name == \"d2-v$VERSION-$OSNAME-$OSARCH.tar.gz\") | \"\(.browser_download_url) \(.digest)\"" "$JSON")"

            BIN_URL="${XX%' '*}"
            BIN_SHA="${XX#*' '}"
            BIN_SHA="${BIN_SHA#*:}"

            tee d2.yml <<EOF
summary: A modern diagram scripting language that turns text to diagrams
webpage: https://github.com/d2lang/d2
bin-url: $BIN_URL
bin-sha: $BIN_SHA
version: $VERSION
EOF

            S="$(git status -s -- d2.yml)"

            if [ -z "$S" ] ; then
                cd -
                continue
            fi

            case "${S#' '}" in
                M*)
                    VOLD="$(git diff -U0 d2.yml | grep '^-version: ' | cut -c11-)"

                    if [ -z "$VOLD" ] ; then
                        XXXX=
                    else
                        XXXX=" $VOLD -> $VERSION"
                    fi

                    git add d2.yml
                    git commit -m "update package d2$XXXX"
                    git push
                    ;;
                A*)
                    git add d2.yml
                    git commit -m "addnew package d2 $VERSION"
                    git push
                    ;;
                \?\?*)
                    git add d2.yml
                    git commit -m "addnew package d2 $VERSION"
                    git push
                    ;;
            esac

            cd -
        done
    done
done
