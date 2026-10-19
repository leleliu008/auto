#!/bin/sh

set -ex

#URL='https://go.dev/dl/?mode=json'
URL='https://golang.google.cn/dl/?mode=json'

curl -L -o golang.json "$URL"

JSON="$PWD/golang.json"


for VERSION in '1.27.2' '1.26.9'
do
    PKGNAME="golang@${VERSION%.*}"
    FILENAME="$PKGNAME.yml"

    for TUPLE in darwin-amd64 darwin-arm64 dragonfly-amd64 freebsd-amd64 netbsd-amd64 openbsd-amd64 linux-amd64 linux-arm64 linux-loong64 linux-riscv64 linux-ppc64le linux-s390x
    do
        OSNAME="${TUPLE%-*}"
        OSARCH="${TUPLE#*-}"

        case $OSNAME in
            *bsd)
                DIRS="$(find -maxdepth 1 -mindepth 1 -type d -name "uppm-package-repository-$OSNAME-*-$OSARCH" -printf '%P\n')"
                ;;
            darwin)
                if [ "$OSARCH" = amd64 ] ; then
                    OSARCH=x86_64
                fi

                DIRS="$(find -maxdepth 1 -mindepth 1 -type d -name "uppm-package-repository-macos-*-$OSARCH" -printf '%P\n')"
                ;;
            linux)
                case $OSARCH in
                    amd64)   OSARCH=x86_64      ;;
                    arm64)   OSARCH=aarch64     ;;
                    loong64) OSARCH=loongarch64 ;;
                esac

                DIRS="uppm-package-repository-linux-$OSARCH"
                ;;
            dragonfly)
                DIRS="uppm-package-repository-dragonflybsd-6.4-x86_64"
                ;;
        esac

        OSNAME="${TUPLE%-*}"
        OSARCH="${TUPLE#*-}"

        XX="$(jq -r ".[] | select(.version == \"go$VERSION\") | .files[] | select(.os == \"$OSNAME\" and .arch == \"$OSARCH\" and (.filename | endswith(\".tar.gz\"))) | \"\(.sha256) \(.filename)\"" "$JSON")"

        BIN_SHA="${XX%' '*}"
        BIN_FILENAME="${XX#*' '}"

        for d in $DIRS
        do
            cd "$HOME/github.com/$d/formula"

            git pull

            tee "$FILENAME" <<EOF
summary: Open source programming language to build simple/reliable/efficient software
webpage: https://go.dev/
bin-url: https://go.dev/dl/$BIN_FILENAME
bin-sha: $BIN_SHA
version: $VERSION
EOF

            S="$(git status -s -- "$FILENAME")"

            if [ -z "$S" ] ; then
                cd -
                continue
            fi

            case "${S#' '}" in
                M*)
                    VOLD="$(git diff -U0 "$FILENAME" | grep '^-version: ' | cut -c11-)"

                    if [ -z "$VOID" ] ; then
                        XXXX=
                    else
                        XXXX=" $VOLD -> $VERSION"
                    fi

                    git add "$FILENAME"
                    git commit -m "update package ${PKGNAME}${XXXX}"
                    git push
                    ;;
                A*)
                    git add "$FILENAME"
                    git commit -m "addnew package ${PKGNAME} ${VERSION}"
                    git push
                    ;;
                \?\?*)
                    git add "$FILENAME"
                    git commit -m "addnew package ${PKGNAME} ${VERSION}"
                    git push
                    ;;
            esac

            cd -
        done
    done
done
